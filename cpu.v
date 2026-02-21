module cpu (
    input wire clk, rst,
    input wire [15:0] instruction,
    input wire [15:0] inM,          // Data read from RAM
    output reg [15:0] outM,         // Data to write to RAM
    
    output reg writeM,              // RAM write enable
    output reg [15:0] addressMH,
    output reg [15:0] addressML,

    output wire [15:0] pc,          // Not 'reg' (pc need not be stored but continuosly driven by PC module)
    output reg [3:0] flags,         // carry, negative, zero, overflow, 

    // CONTROL SIGNALS TO ARBITER
    output wire cpu_active,         // Include in all conditions (means - not stalled)
    output wire signed [15:0] cpu_alu_x,
    output wire signed [15:0] cpu_alu_y,
    output wire [5:0] cpu_alu_op,

    // STATUS SIGNALS FROM ARBITER
    input  wire stall,              // Include in all conditions (means PC = constant)
    input  wire signed [15:0] alu_result,
    input  wire [3:0] alu_flags,

    // MULTIPLY FSM INTERFACE
    input  wire mul_done,   // Default to 0, set to 1 for one cycle when MUL result is ready. Similar for div_done
    input  wire [31:0] mul_product,
    output wire signed [15:0] mul_input_a,
    output wire signed [15:0] mul_input_b,

    // DIVIDE FSM INTERFACE
    input  wire div_done,
    input  wire signed [15:0] div_quotient,
    input  wire signed [15:0] div_remainder,
    output wire signed [15:0] div_dividend,
    output wire signed [15:0] div_divisor,
);

    // 1. CPU Registers
    reg signed [15:0] D, A, M; 
    reg [15:0] PC;

    assign pc = PC;
    assign mul_input_a = D;
    assign mul_input_b = A;
    assign div_dividend = D;
    assign div_divisor = A;

    // 2. INSTRUCTION DECODING - Similar to Prefix free Codes in Digital Comm's variable length encoding
    // TODO - Connect addressMH/ML to ROM+RAM as well as outM, writeM (not to synthesized ROM but to RAM only) in System Top
    // A-instruction if MSB=0
    wire is_a_inst = ~instruction[15];
    // C-instruction if MSB=10
    wire is_c_inst = (instruction[15] && ~instruction[14]);
    wire [5:0] opcode = instruction[11:6];
    wire [2:0] dest = instruction[5:3];     // A, D, M destination bits
    wire [2:0] jump = instruction[2:0];     // Jump bits
    wire is_mul = is_c_inst && (opcode == 6'b010100);
    wire is_div = is_c_inst && (opcode == 6'b010101 || opcode == 6'b010110);
    // Page instruction if MSB=11
    wire is_p_inst = (instruction[15] && instruction[14]);

    // 3. ALU INPUT/OUTPUT
    assign cpu_alu_x = D;
    assign cpu_alu_y = instruction[12] ? inM : A;
    assign cpu_alu_op = opcode;
    assign cpu_active = is_c_inst && !is_mul && !is_div && !stall; 

    // 4. PROGRAM COUNTER
    // Flags is a register inside this module, hence can be used for logic inside this module as well.
    // It is also driven out through the module port
    wire positive = ~flags[1] & ~flags[2];
    assign should_jump = is_c_inst && (
        (jump[2] & flags[2]) |   // JLT
        (jump[1] & flags[1]) |   // JEQ
        (jump[0] & positive)     // JGT
    );
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            PC <= 16'b0;
        end else if (!stall) begin
            if (should_jump) begin
                PC <= A;                     // Jump to A register address
            end else begin
                PC <= PC + 1;                // Normal increment
            end
        end
        // If stalled, PC doesn't change
    end

    // 5. REGISTER UPDATES
    wire should_load_a = is_c_inst && dest[2] && !is_mul && !is_div && !stall;
    wire should_load_d = is_c_inst && dest[1] && !is_mul && !is_div && !stall;
    wire should_load_m = is_c_inst && dest[0] && !is_mul && !is_div && !stall;

    // Division result can be either quotient or remainder based on opcode
    wire [15:0] div_result =
    (opcode == 6'b010101) ? div_quotient :
    (opcode == 6'b010110) ? div_remainder :
    16'b0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            D <= 16'b0;
            A <= 16'b0;
            M <= 16'b0;
            flags <= 4'b0;
            writeM <= 1'b0;
            outM <= 16'b0;
        end else if (!stall) begin
            // Handle A-instruction (load constant)
            if (is_a_inst) begin
                A <= instruction[14:0];      // 15-bit constant into A
            end
            // Handle C-instruction (normal ALU or mul/div)
            if (is_c_inst && !is_mul && !is_div) begin
                // Update flags from ALU
                flags <= alu_flags;
                // Load D register if dest bit set
                if (should_load_d) begin
                    D <= alu_result;
                end
                // Load A register if dest bit set
                if (should_load_a) begin
                    A <= alu_result;
                end
                // Load M register and set write signal if dest bit set
                if (should_load_m) begin
                    M <= alu_result;
                    outM <= alu_result;
                    addressML <= A;
                    writeM <= 1'b1;
                end else begin
                    writeM <= 1'b0;
                end
                // Set address for memory read
                addressML <= A;
            end
            if (is_p_inst) begin
                addressMH <= instruction[13:0];
            end

            // Store multiply FSM result
            // TODO - Set flags for MUL as well (just negative and zero based on product sign and value)
            if (is_mul && mul_done) begin
                if (dest[2]) D <= mul_product[15:0];
                if (dest[1]) A <= mul_product[15:0];
                if (dest[0]) begin
                    M <= mul_product[15:0];
                    outM <= mul_product[15:0];
                    addressML <= A;
                    writeM <= 1'b1;
                end
            end

            // Store divide FSM result (quotient or remainder depends on opcode)
            if (is_div && div_done) begin
                if (dest[2]) D <= div_result;
                if (dest[1]) A <= div_result;
                if (dest[0]) begin
                    M <= div_result;
                    outM <= div_result;
                    addressML <= A;
                    writeM <= 1'b1;
                end
            end
        end else begin
            // If stalled
            writeM <= 1'b0;         // Ensure writeM is low to avoid unintended writes during mul/div
        end
    end

endmodule