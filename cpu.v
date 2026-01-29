module cpu (
    input  logic        clk,
    input  logic        rst,

    // instruction interface (simplified)
    input  logic [15:0] instr,

    // register file interface (abstracted)
    input  logic [15:0] reg_a,
    input  logic [15:0] reg_b,
    output logic [15:0] writeback_data,
    output logic        writeback_en
);

    logic [15:0] alu_a, alu_b;
    logic [3:0]  alu_op;
    logic [15:0] alu_result;

    alu u_alu (
        .a      (alu_a),
        .b      (alu_b),
        .op     (alu_op),
        .result (alu_result)
    );


    logic        mul_start;
    logic        mul_done;
    logic [15:0] mul_a, mul_b;
    logic [15:0] mul_result;

    multiply u_mul (
        .clk        (clk),
        .rst        (rst),
        .start      (mul_start),

        .alu_result (alu_result),   // consumes ALU output

        .a_out      (mul_a),         // drives ALU inputs
        .b_out      (mul_b),
        .done       (mul_done),
        .result     (mul_result)
    );


    logic        div_start;
    logic        div_done;
    logic [15:0] div_a, div_b;
    logic [15:0] div_result;

    divide u_div (
        .clk        (clk),
        .rst        (rst),
        .start      (div_start),

        .alu_result (alu_result),

        .a_out      (div_a),
        .b_out      (div_b),
        .done       (div_done),
        .result     (div_result)
    );

    typedef enum logic [1:0] {
        IDLE,
        EXEC_MUL,
        EXEC_DIV
    } cpu_state_t;

    cpu_state_t state;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state        <= IDLE;
            alu_owner    <= ALU_CPU;
            mul_start    <= 1'b0;
            div_start    <= 1'b0;
            writeback_en <= 1'b0;
        end else begin
            mul_start    <= 1'b0;
            div_start    <= 1'b0;
            writeback_en <= 1'b0;

            case (state)
                IDLE: begin
                    alu_owner <= ALU_CPU;

                    if (instr == 16'hMUL) begin
                        mul_start <= 1'b1;
                        alu_owner <= ALU_MUL;
                        state     <= EXEC_MUL;
                    end
                    else if (instr == 16'hDIV) begin
                        div_start <= 1'b1;
                        alu_owner <= ALU_DIV;
                        state     <= EXEC_DIV;
                    end
                end

                EXEC_MUL: begin
                    alu_owner <= ALU_MUL;
                    if (mul_done) begin
                        writeback_data <= mul_result;
                        writeback_en   <= 1'b1;
                        state          <= IDLE;
                    end
                end

                EXEC_DIV: begin
                    alu_owner <= ALU_DIV;
                    if (div_done) begin
                        writeback_data <= div_result;
                        writeback_en   <= 1'b1;
                        state          <= IDLE;
                    end
                end
            endcase
        end
    end

    typedef enum logic [1:0] {
        ALU_CPU,
        ALU_MUL,
        ALU_DIV
    } alu_owner_t;
    alu_owner_t alu_owner;

    always_comb begin
        alu_a  = 16'd0;
        alu_b  = 16'd0;
        alu_op = 4'd0;

        case (alu_owner)
            ALU_CPU: begin
                alu_a  = reg_a;
                alu_b  = reg_b;
                alu_op = instr[3:0];   // example
            end

            ALU_MUL: begin
                alu_a  = mul_a;
                alu_b  = mul_b;
                alu_op = 4'd0;         // ADD
            end

            ALU_DIV: begin
                alu_a  = div_a;
                alu_b  = div_b;
                alu_op = 4'd1;         // SUB
            end
        endcase
    end
endmodule