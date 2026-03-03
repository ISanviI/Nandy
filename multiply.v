// Implemented Booth Algorithm
// Another for signed is Baugh-Wooley Algorithm
module multiply #(
    parameter WIDTH = 16
)(
    input wire clk, rst, start,
    input wire signed [WIDTH-1:0] multiplier,      // Q
    input wire signed [WIDTH-1:0] multiplicand,    // M
    output reg [2*WIDTH-1:0] product,              // A
    output reg done

    // REQUEST SIGNALS to Arbiter
    output reg req_alu,
    output reg [5:0] alu_op,
    output reg signed [WIDTH-1:0] alu_x,
    output reg signed [WIDTH-1:0] alu_y,

    // RESPONSE SIGNALS from Arbiter
    input  wire signed [WIDTH-1:0] alu_result
);

    // Temp Registers
    reg signed [WIDTH-1:0] A, Q, M;
    reg [$clog2(WIDTH+1)-1:0] cnt;
    reg Q_1;

    // FSM States
    localparam [2:0]
        IDLE      = 3'b000,
        INIT      = 3'b001,
        OPERATION = 3'b010,
        SHIFT     = 3'b011,
        DONE      = 3'b100;

    reg [2:0] state;
    reg [2:0] next_state;

    // FSM Control Path
    always @(posedge clk or posedge rst) begin
        if (rst) state <= IDLE;
        // No need to reset values for A, Q, M, cnt, Q_1 as they will be initialized in INIT state.
        else state <= next_state;
    end

    // FSM Control Path - Next State Logic
    always @(*) begin
        // If next_state value is not provided, the synthesis tool assumes value needs to be remembered and hence creates a latch which could cause problems for timing analysis.
        // To avoid this, we assign a default value to next_state at the beginning of the always block.
        next_state = state; // default hold state
        case (state)
            IDLE: if (start) next_state = INIT;
            INIT: next_state = OPERATION;
            OPERATION: next_state = SHIFT;
            SHIFT: next_state = (cnt == 0) ? DONE : OPERATION;
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // FSM Data Path
    always @(posedge clk) begin
        case (state)
            IDLE: begin
                done <= 1'b0;
                req_alu <= 1'b0;
            end
            INIT: begin
                A <= 0;
                Q <= multiplier;
                M <= multiplicand;
                cnt <= WIDTH-1;
                Q_1 <= 1'b0;
                req_alu <= 1'b0;
            end
            OPERATION: begin
                case ({Q[0], Q_1})
                    2'b01: begin
                        // Need to do: A = A + M
                        req_alu <= 1'b1;
                        alu_op <= 6'b000001;        // ADD operation
                        alu_x <= A;
                        alu_y <= M;
                    end
                    2'b10: begin
                        // Need to do: A = A - M
                        req_alu <= 1'b1;
                        alu_op <= 6'b000010;        // SUB operation
                        alu_x <= A;
                        alu_y <= M;
                    end
                    default: begin
                        // No operation
                        req_alu <= 1'b0;
                    end
                    // ALU not shared code for testing..
                    // 2'b01: A <= A + M;           // A = A + M
                    // 2'b10: A <= A + M_BAR;       // A = A - M
                    // default: ;                   // No operation
                endcase
            end
            SHIFT: begin
                A <= req_alu ? alu_result : A;   // If we requested the ALU in the OPERATION state, we need to update A with the result before shifting. Otherwise, we just shift the current value of A.
                Q_1 <= Q[0];
                {A, Q} <= $signed({A, Q}) >>> 1;    // Arithmetic right shift
                cnt <= cnt - 1;
                req_alu <= 1'b0;                    // Ensure ALU is not requested after operation completion.
            end
            DONE: begin
                product <= {A, Q};
                done <= 1'b1;
                req_alu <= 1'b0;                    // Ensure ALU is not requested in DONE state
            end
        endcase
    end
    
endmodule