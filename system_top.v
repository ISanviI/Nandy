// TODO - Connect addressMH/ML to ROM+RAM as well as outM, writeM (not to synthesized ROM but to RAM only) in System Top
// TODO - Set flags for MUL and DIV (just negative and zero based on product sign and value)
// TODO - Connect program counter to ROM and instruction input from ROM in System Top

// Instantiates all modules and connects them together
module system_top (
    input  wire clk,
    input  wire rst,

    // ROM (Instruction Memory)
    output wire [15:0] pc,
    input  wire [15:0] instruction,

    // RAM (Data Memory)
    input  wire [15:0] inM,
    output wire [15:0] outM,
    output wire writeM,
    output wire [15:0] addressMH,
    output wire [15:0] addressML,

    // Output flags
    output wire [3:0] flags
);

    // CPU to Arbiter signals
    wire cpu_active;
    wire signed [15:0] cpu_alu_x;
    wire signed [15:0] cpu_alu_y;
    wire [5:0] cpu_alu_op;

    // Arbiter to CPU Signals
    wire signed [15:0] cpu_alu_result;
    wire [3:0] cpu_alu_flags;

    // Arbiter status signals
    wire stall;
    wire mul_start;
    wire div_start;

    // ALU signals (shared)
    wire [5:0] alu_opcode;
    wire signed [15:0] alu_x_in;
    wire signed [15:0] alu_y_in;
    wire signed [15:0] alu_result;
    wire [3:0] alu_flags;

    // Multiply FSM signals
    wire mul_req_alu;
    wire [5:0] mul_alu_op;
    wire signed [15:0] mul_alu_x;
    wire signed [15:0] mul_alu_y;
    wire signed [15:0] mul_alu_result;
    wire [31:0] mul_product;
    wire mul_done;
    wire signed [15:0] mul_input_a;
    wire signed [15:0] mul_input_b;

    // Divide FSM signals
    wire div_req_alu;
    wire [5:0] div_alu_op;
    wire signed [15:0] div_alu_x;
    wire signed [15:0] div_alu_y;
    wire signed [15:0] div_alu_result;
    wire signed [15:0] div_quotient;
    wire signed [15:0] div_remainder;
    wire div_done;
    wire signed [15:0] div_dividend;
    wire signed [15:0] div_divisor;

    // Arbiter outputs for result distribution
    wire mul_alu_result_valid;
    wire div_alu_result_valid;
    wire cpu_alu_result_valid;
    
    // --- SHARED ALU (instantiated once) ---
    ALU u_alu (
        .opcode(alu_opcode),
        .D(alu_x_in),
        .M(alu_y_in),
        .result(alu_result),
        .flags(alu_flags)
    );

    // --- CPU (main processor) ---
    cpu u_cpu (
        .clk(clk),
        .rst(rst),
        .instruction(instruction),
        .inM(inM),
        .outM(outM),
        .writeM(writeM),
        .addressMH(addressMH),
        .addressML(addressML),
        .pc(pc),
        .flags(flags),
        .cpu_active(cpu_active),
        .cpu_alu_x(cpu_alu_x),
        .cpu_alu_y(cpu_alu_y),
        .cpu_alu_op(cpu_alu_op),
        .stall(stall),
        .alu_result(cpu_alu_result),
        .alu_flags(cpu_alu_flags),
        .mul_done(mul_done),
        .mul_product(mul_product),
        .mul_input_a(mul_input_a),
        .mul_input_b(mul_input_b),
        .div_done(div_done),
        .div_quotient(div_quotient),
        .div_remainder(div_remainder),
        .div_dividend(div_dividend),
        .div_divisor(div_divisor)
    );

    // --- ARBITER (routes ALU access) ---
    cpu_arbiter u_arbiter (
        .clk(clk),
        .rst(rst),
        .instruction(instruction),
        .cpu_active(cpu_active),
        .mul_req_alu(mul_req_alu),
        .mul_alu_op(mul_alu_op),
        .mul_alu_x(mul_alu_x),
        .mul_alu_y(mul_alu_y),
        .mul_done(mul_done),
        .div_req_alu(div_req_alu),
        .div_alu_op(div_alu_op),
        .div_alu_x(div_alu_x),
        .div_alu_y(div_alu_y),
        .div_done(div_done),
        .cpu_alu_x(cpu_alu_x),
        .cpu_alu_y(cpu_alu_y),
        .cpu_alu_op(cpu_alu_op),
        .stall(stall),
        .mul_start(mul_start),
        .div_start(div_start),
        .alu_opcode(alu_opcode),
        .alu_x_in(alu_x_in),
        .alu_y_in(alu_y_in),
        .alu_result(alu_result),
        .alu_flags(alu_flags),
        .mul_alu_result(mul_alu_result),
        .div_alu_result(div_alu_result),
        .cpu_alu_result(cpu_alu_result),
        .cpu_alu_flags(cpu_alu_flags)
    );

    // --- MULTIPLY FSM (Baugh-Wooley signed multiplication) ---
    multiply u_multiply (
        .clk(clk),
        .rst(rst),
        .start(mul_start),
        .multiplier(mul_input_a),
        .multiplicand(mul_input_b),
        .product(mul_product),
        .done(mul_done),
        .req_alu(mul_req_alu),
        .alu_op(mul_alu_op),
        .alu_x(mul_alu_x),
        .alu_y(mul_alu_y),
        .alu_result(mul_alu_result)
    );

    // --- DIVIDE FSM (Restoring division) ---
    divide u_divide (
        .clk(clk),
        .rst(rst),
        .start(div_start),
        .dividend(div_dividend),
        .divisor(div_divisor),
        .quotient(div_quotient),
        .remainder(div_remainder),
        .done(div_done),
        .req_alu(div_req_alu),
        .alu_op(div_alu_op),
        .alu_x(div_alu_x),
        .alu_y(div_alu_y),
        .alu_result(div_alu_result),
        .carry_flag(alu_flags[3])
    );

endmodule
