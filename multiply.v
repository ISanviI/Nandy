module multiply #(
    parameter WIDTH = 16
)(
    input wire clk, rst, start,
    input wire signed [WIDTH-1:0] multiplier,      // Q
    input wire signed [WIDTH-1:0] multiplicand,    // M
    output reg [2*WIDTH-1:0] product,              // A
    output reg done
);

    // Temp Registers
    reg signed [WIDTH-1:0] A, Q, M, M_BAR;
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
        // No need to reset values for A, Q, M, M_BAR, cnt, Q_1 as they will be initialized in INIT state.
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
            INIT: begin
                A <= 0;
                Q <= multiplier;
                M <= multiplicand;
                M_BAR <= ~multiplicand + 1; // Two's complement
                cnt <= WIDTH-1;
                Q_1 <= 0;
            end
            OPERATION: begin
                case ({Q[0], Q_1})
                    2'b01: A <= A + M;       // A = A + M
                    2'b10: A <= A + M_BAR;   // A = A - M
                    default: ;                // No operation
                endcase
            end
            SHIFT: begin
                Q_1 <= Q[0];
                {A, Q} <= $signed({A, Q}) >>> 1;     // Arithmetic right shift
                cnt <= cnt - 1;
            end
            DONE: begin
                product <= {A, Q};
                done <= 1'b1;
            end
        endcase
    end
    
endmodule