module cpu (
    input clk, rst,
    input [15:0] instruction,
    input [15:0] inM,
    output [15:0] outM,
    
    output writeM,
    output [15:0] addressMH,
    output [15:0] addressML,

    output [15:0] pc,
    output [3:0] flags
);

    // Wires
    wire stall;
    wire start_mul, mul_done;
    wire start_div, div_done;
    wire [1:0] alu_owner; // 0=CPU, 1=MUL, 2=DIV
    wire [5:0] alu_op_override;
    
    // Data Wires
    reg  [15:0] alu_in_x, alu_in_y;
    wire [15:0] alu_out;
    wire [3:0]  alu_flags;
    wire [15:0] D_out, A_out;
    wire [15:0] mul_a_req, mul_b_req, mul_res;
    wire [15:0] div_a_req, div_b_req, div_res;

    // --- 1. Instantiate Arbiter ---
    cpu_arbiter u_arbiter (
        .clk(clk), .rst(rst),
        .instruction(instruction),
        .mul_done(mul_done), .div_done(div_done),
        .stall(stall),
        .start_mul(start_mul), .start_div(start_div),
        .alu_owner(alu_owner),
        .alu_op_override(alu_op_override)
    );

    // --- 2. ALU Input Muxes ---
    // Selects X Input (CPU D-Reg vs MUL vs DIV)
    always @(*) begin
        case (alu_owner)
            2'b00: alu_in_x = D_out;       // Normal CPU D-Reg
            2'b01: alu_in_x = mul_a_req;   // From Multiply FSM
            2'b10: alu_in_x = div_a_req;   // From Divide FSM
            default: alu_in_x = 0;
        endcase
    end

    // Selects Y Input (CPU A/M vs MUL vs DIV)
    // Assuming CPU Y input is selected between A and M using instruction[12] (the 'a' bit)
    wire [15:0] cpu_y_val = (instruction[12]) ? inM : A_out;

    always @(*) begin
        case (alu_owner)
            2'b00: alu_in_y = cpu_y_val;   // Normal CPU A/M selection
            2'b01: alu_in_y = mul_b_req;   // From Multiply FSM
            2'b10: alu_in_y = div_b_req;   // From Divide FSM
            default: alu_in_y = 0;
        endcase
    end

    // --- 3. Instantiate Shared ALU ---
    // Calculate final Opcode: CPU Instruction or Arbiter Override?
    wire [5:0] final_opcode = (stall) ? alu_op_override : instruction[11:6];

    ALU u_alu (
        .opcode(final_opcode),
        .D(alu_in_x), .M(alu_in_y),
        .result(alu_out),
        .flags(alu_flags)
    );

    // --- 4. Instantiate FSMs ---
    multiply_shared u_mul (
        .clk(clk), .rst(rst), .start(start_mul),
        .multiplier(D_out),       // Input directly from CPU D-Reg
        .multiplicand(cpu_y_val), // Input directly from CPU A/M Bus
        .product(mul_res),        // NOTE: Needs truncation to 16-bit or handling
        .done(mul_done),
        .alu_in_a(mul_a_req), .alu_in_b(mul_b_req),
        .alu_result(alu_out)
    );

    divide_shared u_div (
        .clk(clk), .rst(rst), .start(start_div),
        .dividend(D_out),
        .divisor(cpu_y_val),
        .quotient(div_res),
        .done(div_done),
        .alu_in_a(div_a_req), .alu_in_b(div_b_req),
        .alu_result(alu_out),
        .alu_borrow_flag(alu_flags[3]) // Assuming flag[3] is carry/borrow
    );

    // --- 6. Instantiate PC ---
    // PC logic goes here, with stall handling (PC should not update when stall is high)
    pc u_pc (
        .clk(clk), .rst(rst),
        .pc_in(alu_out), // Update to value A register
        .control((stall) ? 2'b01 : 2'b01), // Increment PC if not stalled
        .pc_out(pc)
    );

    // --- 5. Result Writeback Mux ---
    // The value written back to registers depends on who finished
    wire [15:0] final_result;
    assign final_result = (mul_done) ? mul_res[15:0] : // Take lower 16 bits
                          (div_done) ? div_res :
                          alu_out;

    // --- 6. Existing CPU Registers (With Stall Logic) ---
    
    // Example D-Register: Write only if dest bit set AND NOT STALLED
    wire load_d = instruction[4] & is_c_inst & !stall; 
    
    // (Existing Register Instantiations go here, connected to final_result)

endmodule