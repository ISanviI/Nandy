module divide16 (
    parameter WIDTH = 16;
    input wire clk, rst, start;
    input wire signed [(WIDTH-1):0] dividend,      // A
    input wire signed [(WIDTH-1):0] divisor,       // B
    output reg signed [(WIDTH-1):0] quotient,      // Q
    output reg signed [(WIDTH-1):0] remainder,     // R
    output reg done
);
     // FSM states
    typedef enum logic [2:0] {  // enum types - int, logic
        IDLE,
        INIT,
        ALIGN,
        SUB,
        DECIDE,
        SHIFT,
        DONE
    } state_t;
    state_t state, next_state;

    // Sign Registers
    reg dividend_sign, divisor_sign;

    // Temp Registers
    reg [WIDTH-1:0] A, B, SHIFT_B;
    reg [$clog2(WIDTH)-1:0] cnt;

    // MSB Detection
    wire [$clog2(WIDTH)-1:0] msb_pos;
    wire [$clog2(WIDTH)-1:0] shift_amt;
    assign msb_pos = priority_encode_164(B);
    assign shift_amt = (WIDTH-1) - msb_pos;

    // ALU for Subtraction
    reg [WIDTH-1:0] sub_out;
    reg borrow;

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
            INIT: begin
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
                SHIFT_B <= B << shift_amt;
                cnt <= shift_amt;
            end
            SUB: begin
                {borrow, sub_out} <= A - SHIFT_B;
            end
            DECIDE: begin
                if (!borrow) begin
                    A <= sub_out;
                    quotient[cnt] <= 1'b1;
                end else begin
                    quotient[cnt] <= 1'b0;
                end
            end
            SHIFT: begin
                SHIFT_B <= SHIFT_B >> 1;
                cnt <= cnt - 1;
            end
            DONE: begin
                if (dividend_sign ^ divisor_sign) begin
                    quotient <= (~quotient) + 1;
                end
                if (dividend_sign) begin
                    remainder <= (~A) + 1;
                end else begin
                    remainder <= A;
                end
                done <= 1'b1;
            end
        endcase
    end

endmodule