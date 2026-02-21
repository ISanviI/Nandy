module cpu_arbiter (
    input wire clk, rst,
    input wire [15:0] instruction,
    input wire cpu_active,

    // Status signals from Multiply FSM
    input wire mul_req_alu,
    input wire [5:0] mul_alu_op,
    input wire signed [15:0] mul_alu_x,
    input wire signed [15:0] mul_alu_y,
    input wire mul_done,            // Default to 0, set to 1 for one cycle when MUL result is ready. Similar for div_done

    // Status Signals from Divide FSM
    input wire div_req_alu,
    input wire [5:0] div_alu_op,
    input wire signed [15:0] div_alu_x,
    input wire signed [15:0] div_alu_y,
    input wire div_done,

    // OPERANDS (from CPU)
    input wire signed [15:0] cpu_alu_x,
    input wire signed [15:0] cpu_alu_y,
    input wire [5:0] cpu_alu_op,

    // Control Outputs (to CPU)
    output reg stall,               // Freeze PC during multi-cycle Multiplication and Division

    // Start Signals (to FSM)
    output reg mul_start,           // Default to 0, set to 1 for one cycle to trigger MUL operation. Similar for div_start
    output reg div_start,

    // Outputs To ALU (multiplexed)
    output reg [5:0] alu_opcode,
    output reg signed [15:0] alu_x_in,
    output reg signed [15:0] alu_y_in,

    // INPUTS FROM ALU
    input wire signed [15:0] alu_result,
    input wire [3:0] alu_flags,

    // Outputs (to FSMs and CPU)
    output reg signed [15:0] mul_alu_result,
    output reg signed [15:0] div_alu_result,
    output reg signed [15:0] cpu_alu_result,
    output reg [3:0] cpu_alu_flags
);

    // HACK Instruction Decoding
    // C-Instruction
    wire is_c_instr = (instruction[15] & ~instruction[14]); // C-instruction if MSB=1 and next bit=0
    wire [5:0] opcode = instruction[11:6];

    wire trig_mul = is_c_instr && (opcode == 6'b010100); // MUL opcode
    wire trig_div = is_c_instr && (opcode == 6'b010101 || opcode == 6'b010110); // DIV opcode

    // FSM states
    localparam [1:0]
        CPU = 2'b00,
        MUL = 2'b01,
        DIV = 2'b10;
        
    reg [1:0] state, next_state;

    always @(posedge clk or posedge rst) begin
        if (rst) state <= CPU;
        else state <= next_state; 
    end

    always @(*) begin
        // Defaults (Avoid Latches)
        next_state = state;
        stall = 1'b0;
        mul_start = 1'b0;
        div_start = 1'b0;
        alu_opcode = 6'b0;
        alu_x_in = 16'b0;
        alu_y_in = 16'b0;
        mul_alu_result = 16'b0;
        div_alu_result = 16'b0;
        cpu_alu_result = 16'b0;
        cpu_alu_flags = 4'b0;

        case (state)
            CPU: begin
                if (cpu_active) begin
                    stall = 1'b0;
                    alu_opcode = cpu_alu_op;
                    alu_x_in = cpu_alu_x;
                    alu_y_in = cpu_alu_y;
                    cpu_alu_result = alu_result;
                    cpu_alu_flags = alu_flags;
                end
                else if (trig_mul) begin
                    next_state = MUL;
                    stall = 1'b1;               // Freeze CPU immediately
                    mul_start = 1'b1;           // Start multiply operation
                end
                else if (trig_div) begin
                    next_state = DIV;
                    stall = 1'b1;
                    div_start = 1'b1;
                end
            end

            MUL: begin
                stall = 1'b1;                   // Keep CPU frozen
                if (mul_req_alu) begin
                    alu_opcode = mul_alu_op;
                    alu_x_in = mul_alu_x;
                    alu_y_in = mul_alu_y;
                    mul_alu_result = alu_result;
                end
                if (mul_done) begin
                    next_state = CPU;
                    stall = 1'b0;               // Release CPU
                end
            end

            DIV: begin
                stall = 1'b1;                   // Keep CPU frozen
                if (div_req_alu) begin
                    alu_opcode = div_alu_op;
                    alu_x_in = div_alu_x;
                    alu_y_in = div_alu_y;
                    div_alu_result = alu_result;
                end
                if (div_done) begin
                    next_state = CPU;
                    stall = 1'b0;               // Release CPU
                end
            end

            default: next_state = CPU;
        endcase
    end

endmodule