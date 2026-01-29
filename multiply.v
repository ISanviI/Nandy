module multiply (
    parameter WIDTH = 16,
    input wire clk, rst, start,
    input wire [WIDTH-1:0] multiplicand,    // M
    input wire [WIDTH-1:0] multiplier,      // Q
    output reg [WIDTH-1:0] product_h,       // A
    output reg [WIDTH-1:0] product_l,       // Q
);
    // Signs
    reg multiplicand_sign, multiplier_sign;

    // Temp Registers
    reg [WIDTH-1:0] A, Q, M, M_BAR;
    reg cnt, Q_1;

    // FSM States
    typedef enum logic [1:0] {
        IDLE,
        INIT,
        OPERATION,
        SHIFT,
        DONE
    } state_t;
    state_t state, next_state;

    // FSM Control Path
    always @(posedge clk or posedge rst) begin
        if (rst) state <= IDLE;
        else state <= next_state;
    end

    // FSM Next State Logic
    always @(*) begin
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
                cnt <= WIDTH;
                Q_1 <= 0;
                multiplicand_sign <= multiplicand[WIDTH-1];
                multiplier_sign <= multiplier[WIDTH-1];
            end
            OPERATION: begin
                case ({Q[0], Q_1})
                    2'b01: A <= A + M;       // A = A + M
                    2'b10: A <= A + M_BAR;   // A = A - M
                    default: ;                // No operation
                endcase
            end
            SHIFT: begin
                Q_1 = Q[0];
                {A, Q} <= {A, Q} >>> 1;     // Arithmetic right shift
                cnt <= cnt - 1;
            end
            DONE: begin
                product_h <= A;
                product_l <= Q;
            end
            default: ;
        endcase
    end
    
endmodule