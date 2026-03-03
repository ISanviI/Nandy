//  Based on opcode 6'b010101 for Quotient and 6'b010110 for Remainder, the Divider FSM should handle which result to output.
module divide16 #(
    parameter WIDTH = 16
)(
    input wire clk, rst, start,
    input wire signed [(WIDTH-1):0] dividend,      // A
    input wire signed [(WIDTH-1):0] divisor,       // B
    output reg signed [(WIDTH-1):0] quotient,      // Q
    output reg signed [(WIDTH-1):0] remainder,     // R
    output reg done

    // REQUEST SIGNALS to Arbiter
    output reg req_alu,
    output reg [5:0] alu_op,
    output reg signed [WIDTH-1:0] alu_x,
    output reg signed [WIDTH-1:0] alu_y,

    // RESPONSE SIGNALS from Arbiter
    input  wire signed [WIDTH-1:0] alu_result,
    input  wire carry_flag                          // Borrow flag from ALU
);
    
    // Internal Registers
    reg signed [WIDTH-1:0] A, B;
    reg [WIDTH-1:0] SHIFT_B;
    reg [$clog2(WIDTH)-1:0] cnt;
    reg dividend_sign, divisor_sign;
    
    // FSM states
    localparam [2:0]
        IDLE     = 3'b000,
        INIT     = 3'b001,
        ALIGN    = 3'b010,
        SUB      = 3'b011,
        DECIDE   = 3'b100,
        SHIFT    = 3'b101,
        DONE     = 3'b110;

    reg[2:0] state, next_state;

    // Temp Registers
    reg [WIDTH-1:0] A, B, SHIFT_B;
    reg [$clog2(WIDTH)-1:0] cnt;

    // MSB Detection
    wire [$clog2(WIDTH)-1:0] msb_pos;
    wire [$clog2(WIDTH)-1:0] shift_amt;

    priority_encode_164 priority_encoder(
        .in(B),
        .out(msb_pos),
        .valid()
    );
    assign shift_amt = (WIDTH-1) - msb_pos;

    // FSM Sequential
    always @(posedge clk or posedge rst) begin
        if (rst) state <= IDLE;
        else state <= next_state;
    end

    // FSM Combinational - Control Path
    always @(*) begin
        next_state = state; // default to hold state
        case (state)
            IDLE: if (start) next_state = INIT;
            INIT: next_state = ALIGN;
            ALIGN: next_state = SUB;
            SUB: next_state = DECIDE;
            DECIDE: next_state = SHIFT;
            SHIFT: next_state = (cnt==0) ? DONE : SUB;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // Data Path
    always @(posedge clk) begin
        case (state)
            IDLE: begin
                done <= 1'b0;
                req_alu <= 1'b0;
            end

            INIT: begin
                // Handle sign and convert to positive if necessary
                if (dividend[WIDTH-1] == 1'b1) begin
                    dividend_sign <= 1'b1;
                    A <= (~dividend) + 1;
                end else begin
                    dividend_sign <= 1'b0;
                    A <= dividend;
                end

                if (divisor[WIDTH-1] == 1'b1) begin
                    divisor_sign <= 1'b1;
                    B <= (~divisor) + 1;
                end else begin
                    divisor_sign <= 1'b0;
                    B <= divisor;
                end
                quotient <= 0;
                done <= 0;
            end

            ALIGN: begin
                // Align divisor by shifting left until its MSB is in the same position as the dividend's MSB
                SHIFT_B <= B << shift_amt;
                cnt <= shift_amt;
            end

            SUB: begin
                // Request ALU to do subtraction: A - SHIFT_B
                req_alu <= 1'b1;
                alu_op <= 6'b000010;                // SUB operation
                alu_x <= A;
                alu_y <= SHIFT_B;
            end

            DECIDE: begin
                // Check if subtraction was successful (no borrow)
                if (!carry_flag) begin
                    // Subtraction successful, quotient bit = 1
                    A <= alu_result;                // Store result
                    quotient[cnt] <= 1'b1;
                end else begin
                    // Subtraction failed (borrow), quotient bit = 0
                    // Don't update A (restore)
                    quotient[cnt] <= 1'b0;
                end
                req_alu <= 1'b0;                    // Clear ALU request after decision
            end

            SHIFT: begin
                SHIFT_B <= SHIFT_B >> 1;
                cnt <= cnt - 1;
            end

            DONE: begin
                // Handle sign of results
                if (dividend_sign ^ divisor_sign) begin
                    quotient <= (~quotient) + 1;
                end
                
                if (dividend_sign) begin
                    remainder <= (~A) + 1;
                end else begin
                    remainder <= A;
                end

                done <= 1'b1;
                req_alu <= 1'b0;
            end
        endcase
    end

endmodule