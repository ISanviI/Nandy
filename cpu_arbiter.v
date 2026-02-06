module cpu (
    input  logic        clk,
    input  logic        rst,
    input  logic [15:0] instruction,

    // Status signals from Coprocessors
    input wire mul_done,
    input wire div_done,

    // Control Outputs to CPU Core
    output reg stall, // Freeze PC during multi-cycle Multiplication and Division
    // output reg reg_write_en, // Global Write Enable for A, D, M registers

    // Control Outputs to Coprocessors
    output reg start_mul,
    output reg start_div,

    // ALU Control
    output reg [1:0] alu_owner, // 00: CPU, 01: MUL, 10: DIV
    output reg [5:0] alu_op_override,    // ALU operation select
);

    // HACK Instruction Decoding
    // C-Instruction
    wire is_c_instr = (instruction[15] & ~instruction[14]); // C-instruction if MSB=1 and next bit=0
    wire [5:0] opcode = instruction[11:6];

    wire trig_mul = is_c_instr && (opcode == 6'b010100); // MUL opcode
    wire trig_div = is_c_instr && (opcode == 6'b010101 || opcode == 6'b010110); // DIV opcode

    // FSM states
    localparam [1:0]
        IDLE = 2'b00,
        ALU  = 2'b01
        MUL  = 2'b10,
        DIV  = 2'b11;

    localparam [5:0]
        MUL_OP = 6'b010100,
        DIV_Q_OP = 6'b010101;
        DIV_R_OP = 6'b010110;
    
    reg [1:0] state, next_state;

    always @(posedge clk or posedge rst) begin
        if (rst) state <= IDLE;
        else state <= next_state; 
    end

    always @(*) begin
        // Defaults (Avoid Latches)
        next_state = state;
        stall = 1'b0;
        mul_start = 1'b0;
        div_start = 1'b0;
        alu_owner = 2'b00; // Default to CPU
        alu_opcode = 6'b000000;

        case (state)
            IDLE: begin
                if (trig_mul) begin
                    next_state = MUL;
                    stall      = 1'b1;  // Freeze CPU immediately
                    start_mul  = 1'b1;  // Pulse start
                end 
                else if (trig_div) begin
                    next_state = DIV;
                    stall      = 1'b1;
                    start_div  = 1'b1;
                end
            end

            MUL: begin
                stall           = 1'b1;      // Keep CPU frozen
                alu_owner       = 2'b01;     // Give ALU to Multiplier
                alu_op_override = ALU_ADD;   // Force ALU to ADD
                
                if (mul_done) begin
                    stall      = 1'b0;      // Unfreeze for Writeback
                    next_state = IDLE;
                end
            end

            DIV: begin
                stall           = 1'b1;
                alu_owner   = 2'b10;     // Give ALU to Divider
                alu_op_override = ALU_SUB;   // Force ALU to SUB
                
                if (div_done) begin
                    stall      = 1'b0;
                    next_state = IDLE;
                end
            end
        endcase
    end

endmodule