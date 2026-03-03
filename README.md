================================================================================
COMPLETE CPU WITH SHARED ALU SYSTEM
CODE DOCUMENTATION
================================================================================

This document explains the complete Verilog implementation of a CPU with:

- One shared ALU (Arithmetic Logic Unit)
- One multiply FSM (Finite State Machine)
- One divide FSM
- One arbiter (router) to control ALU access
- Main CPU processor with registers

================================================================================
FILE STRUCTURE
================================================================================

1. alu.v - Shared ALU (Baugh-Wooley operations)
2. multiply_shared.v - Multiply FSM (uses shared ALU)
3. divide_shared.v - Divide FSM (uses shared ALU)
4. cpu_arbiter.v - Arbiter/Router for ALU access
5. cpu.v - Main CPU processor
6. system_top.v - Top-level instantiation

================================================================================
MODULE DESCRIPTIONS
================================================================================

┌─────────────────────────────────────────────────────────────────────────────┐
│ 1. ALU (alu.v) │
├─────────────────────────────────────────────────────────────────────────────┤
│ │
│ Purpose: Performs arithmetic and logic operations │
│ │
│ INPUTS: │
│ • opcode[5:0] - Which operation to perform │
│ • X[15:0] - First operand (from Arbiter) │
│ • Y[15:0] - Second operand (from Arbiter) │
│ │
│ OUTPUTS: │
│ • result[15:0] - Computation result │
│ • flags[3:0] - Status flags: │
│ [3] = Carry/Borrow │
│ [2] = Negative (sign bit) │
│ [1] = Zero │
│ [0] = Overflow │
│ │
│ OPERATION CODES (opcode): │
│ 6'b000001 = ADD (X + Y) │
│ 6'b000010 = SUB (X - Y) │
│ 6'b000011 = AND (X & Y) │
│ 6'b000100 = OR (X | Y) │
│ 6'b000101 = XOR (X ^ Y) │
│ 6'b000110 = NOT X (~X) │
│ 6'b001100 = SHL X (X << 1) │
│ 6'b001101 = SAR X (X >> 1, arithmetic) │
│ ... and more (see alu.v for complete list) │
│ │
│ KEY CONCEPT: │
│ The ALU doesn't know WHERE data comes from or GO. │
│ It just receives X, Y, opcode → computes → returns result & flags │
│ │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ 2. MULTIPLY FSM (multiply_shared.v) │
├─────────────────────────────────────────────────────────────────────────────┤
│ │
│ Purpose: Implements Baugh-Wooley signed multiplication algorithm │
│ Uses shared ALU for arithmetic operations │
│ │
│ INPUTS: │
│ • clk - Clock signal │
│ • rst - Reset signal │
│ • start - From Arbiter: "Begin multiplication" │
│ • multiplier[15:0] - First number (from CPU D register) │
│ • multiplicand[15:0] - Second number (from CPU A register) │
│ • alu_result[15:0] - Result from shared ALU │
│ │
│ OUTPUTS: │
│ • product[31:0] - Final 32-bit result │
│ • done - Multiplication complete │
│ • req_alu - Request signal: "I need the ALU" │
│ • alu_op[5:0] - Which operation (ADD or SUB) │
│ • alu_x[15:0] - First operand for ALU │
│ • alu_y[15:0] - Second operand for ALU │
│ │
│ STATE MACHINE: │
│ IDLE → Wait for start signal │
│ INIT → Initialize registers (A=0, Q=multiplier, M=multiplicand) │
│ OPERATION → Request ALU: add or subtract based on Q[0] and Q_1 │
│ SHIFT → Capture ALU result, perform arithmetic right shift │
│ DONE → Product ready, signal complete │
│ │
│ ALGORITHM (Baugh-Wooley): │
│ For each of WIDTH iterations: │
│ 1. Check bits Q[0] and Q_1 │
│ 2. If 01: request ALU to do A = A + M │
│ 3. If 10: request ALU to do A = A - M (via A + M_BAR) │
│ 4. Wait for ALU result │
│ 5. Perform arithmetic right shift on {A, Q} │
│ 6. Repeat │
│ │
│ TIMELINE (4 clock cycles per iteration): │
│ Cycle 1: FSM sees Q[0], Q_1 → makes ALU request │
│ Cycle 2: Arbiter routes request to ALU │
│ Cycle 3: ALU computes, sends result to Arbiter │
│ Cycle 4: FSM receives result, shifts, prepares next request │
│ │
│ KEY INSIGHT: │
│ FSM doesn't do ADD/SUB itself! │
│ It REQUESTS the shared ALU: "Please add A and M, here they are" │
│ It WAITS for the Arbiter to route it and return the result │
│ It STORES the result and continues │
│ │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ 3. DIVIDE FSM (divide_shared.v) │
├─────────────────────────────────────────────────────────────────────────────┤
│ │
│ Purpose: Implements Restoring Division algorithm for signed integers │
│ Uses shared ALU for subtraction operations │
│ │
│ INPUTS: │
│ • clk - Clock signal │
│ • rst - Reset signal │
│ • start - From Arbiter: "Begin division" │
│ • dividend[15:0] - Number to divide (from CPU D register) │
│ • divisor[15:0] - Divide by this (from CPU A register) │
│ • alu_result[15:0] - Result from shared ALU │
│ • carry_flag - Borrow flag from ALU (tells if subtraction worked) │
│ │
│ OUTPUTS: │
│ • quotient[15:0] - Division result (how many times divisor fits) │
│ • remainder[15:0] - What's left over (modulo) │
│ • done - Division complete │
│ • req_alu - Request signal: "I need the ALU" │
│ • alu_op[5:0] - Which operation (SUB) │
│ • alu_x[15:0] - First operand for ALU │
│ • alu_y[15:0] - Second operand for ALU │
│ │
│ STATE MACHINE: │
│ IDLE → Wait for start signal │
│ INIT → Convert to absolute values, store signs │
│ ALIGN → Align divisor by shifting left │
│ SUB → Request ALU: subtract aligned divisor from remainder │
│ DECIDE → Check borrow flag from ALU │
│ If no borrow: subtraction worked, set quotient bit to 1 │
│ If borrow: restore, set quotient bit to 0 │
│ SHIFT → Shift divisor right by 1, decrement counter │
│ DONE → Apply sign corrections, done │
│ │
│ ALGORITHM (Restoring Division): │
│ 1. Take absolute values of dividend and divisor │
│ 2. Align divisor to the left as much as possible │
│ 3. For each bit position: │
│ a. Try to subtract aligned divisor from remainder (via ALU) │
│ b. Check carry_flag (borrow) from ALU │
│ c. If no borrow: subtraction worked, set quotient bit to 1 │
│ d. If borrow: restore (don't update remainder), set bit to 0 │
│ e. Shift divisor right by 1 │
│ 4. Apply sign corrections to quotient and remainder │
│ │
│ KEY INSIGHT: │
│ FSM doesn't do subtraction itself! │
│ It REQUESTS the ALU: "Please subtract these two values" │
│ It checks the carry_flag to know if subtraction worked │
│ It uses this information to decide on the quotient bit │
│ │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ 4. CPU ARBITER (cpu_arbiter.v) │
├─────────────────────────────────────────────────────────────────────────────┤
│ │
│ Purpose: Routes ALU access between CPU, Multiply FSM, and Divide FSM │
│ Acts as a "traffic controller" for the shared ALU │
│ │
│ INPUTS (Requests from CPU, Multiply, Divide): │
│ ┌─ CPU: │
│ │ • cpu_active - "I want to use ALU" │
│ │ • cpu_alu_op[5:0] - What operation I want │
│ │ • cpu_alu_x[15:0] - My first operand │
│ │ • cpu_alu_y[15:0] - My second operand │
│ │ │
│ ├─ Multiply FSM: │
│ │ • mul_req_alu - "I need the ALU" │
│ │ • mul_alu_op[5:0] - ADD or SUB │
│ │ • mul_alu_x[15:0] - My first number │
│ │ • mul_alu_y[15:0] - My second number │
│ │ • mul_done - "I'm finished" │
│ │ │
│ └─ Divide FSM: │
│ • div_req_alu - "I need the ALU" │
│ • div_alu_op[5:0] - SUB (only subtraction) │
│ • div_alu_x[15:0] - My remainder │
│ • div_alu_y[15:0] - My aligned divisor │
│ • div_done - "I'm finished" │
│ │
│ INPUT (from ALU): │
│ • alu_result[15:0] - The computed value │
│ • alu_flags[3:0] - Status (carry, negative, zero, overflow) │
│ │
│ OUTPUT (to ALU): │
│ • alu_opcode[5:0] - Which operation to perform (muxed) │
│ • alu_x_in[15:0] - First operand for ALU (muxed) │
│ • alu_y_in[15:0] - Second operand for ALU (muxed) │
│ │
│ OUTPUT (Control): │
│ • stall - To CPU: "Stop, FSM is using ALU" │
│ • start_mul - To Multiply FSM: "Your turn, begin!" │
│ • start_div - To Divide FSM: "Your turn, begin!" │
│ │
│ OUTPUT (Result Distribution): │
│ • mul_alu_result[15:0] - Result for Multiply FSM │
│ • mul_alu_result_valid - "Multiply, this is yours" │
│ • div_alu_result[15:0] - Result for Divide FSM │
│ • div_alu_result_valid - "Divide, this is yours" │
│ • cpu_alu_result[15:0] - Result for CPU │
│ • cpu_alu_result_valid - "CPU, this is yours" │
│ │
│ STATE MACHINE (FSM): │
│ IDLE: Waiting for instruction │
│ If CPU wants ALU → Route to ALU immediately │
│ If MUL instruction → Go to MUL state, start multiply FSM │
│ If DIV instruction → Go to DIV state, start divide FSM │
│ │
│ MUL: Multiply FSM is running │
│ Keep CPU stalled (stall = 1) │
│ Route Multiply's ALU requests to ALU │
│ Send ALU results back to Multiply │
│ When mul_done → Return to IDLE, release stall │
│ │
│ DIV: Divide FSM is running │
│ Keep CPU stalled (stall = 1) │
│ Route Divide's ALU requests to ALU │
│ Send ALU results back to Divide │
│ When div_done → Return to IDLE, release stall │
│ │
│ PRIORITY SYSTEM: │
│ When multiple modules want ALU: │
│ 1. CPU gets highest priority (normal operations) │
│ 2. Multiply FSM (if stalled) │
│ 3. Divide FSM (if stalled) │
│ │
│ ROUTING LOGIC (inside always @(\*)): │
│ The Arbiter uses multiplexers to select which inputs go to ALU: │
│ │
│ if (cpu_active) { │
│ alu_opcode ← cpu_alu_op │
│ alu_x_in ← cpu_alu_x │
│ alu_y_in ← cpu_alu_y │
│ } │
│ else if (mul_req_alu) { │
│ alu_opcode ← mul_alu_op │
│ alu_x_in ← mul_alu_x │
│ alu_y_in ← mul_alu_y │
│ mul_alu_result ← alu_result │
│ } │
│ else if (div_req_alu) { │
│ alu_opcode ← div_alu_op │
│ alu_x_in ← div_alu_x │
│ alu_y_in ← div_alu_y │
│ div_alu_result ← alu_result │
│ } │
│ │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ 5. CPU PROCESSOR (cpu.v) │
├─────────────────────────────────────────────────────────────────────────────┤
│ │
│ Purpose: Main processor - decodes instructions, manages registers │
│ Coordinates with Arbiter, Multiply FSM, Divide FSM │
│ │
│ REGISTERS: │
│ • D[15:0] - Data register (stores computed values) │
│ • A[15:0] - Address register (memory address or jump target) │
│ • M[15:0] - Memory register (cached memory value) │
│ • PC[15:0] - Program counter (instruction address) │
│ • flags[3:0]- Status flags │
│ │
│ INSTRUCTION TYPES: │
│ • A-Instruction: 0xxxxxxxxxxxxxxx │
│ Sets A register to constant value │
│ │
│ • C-Instruction: 1xxxxxxxxxx... │
│ Arithmetic/logic operation, conditional jump │
│ Format: 1 1 1 a c1 c2 c3 c4 c5 c6 d1 d2 d3 j1 j2 │
│ - a bit: 0=use A, 1=use M (for ALU input) │
│ - c1-c6: ALU operation code │
│ - d1-d3: Destination (which register to update) │
│ - j1-j2: Jump condition │
│ │
│ SPECIAL C-INSTRUCTIONS: │
│ • MUL: opcode = 6'b010100 → Trigger Multiply FSM │
│ • DIV: opcode = 6'b010101 or 6'b010110 → Trigger Divide FSM │
│ │
│ INTERFACE TO ARBITER: │
│ Outputs to Arbiter: │
│ • instruction[15:0] - Current instruction (for decode) │
│ • cpu_active - "I want to use ALU" (for C-instr, not MUL/DIV) │
│ • cpu_alu_x - Always D register │
│ • cpu_alu_y - A or M register (depends on 'a' bit) │
│ • cpu_alu_op - opcode[5:0] │
│ │
│ Inputs from Arbiter: │
│ • stall - "Don't continue, FSM is running" │
│ • alu_result - Result from shared ALU │
│ • alu_flags - Flags from ALU │
│ │
│ PROGRAM COUNTER LOGIC: │
│ Normal execution: PC ← PC + 1 (next instruction) │
│ Jump condition met: PC ← A (jump to address in A) │
│ When stalled: PC stays same (doesn't advance during MUL/DIV) │
│ │
│ REGISTER UPDATE LOGIC: │
│ After ALU computation, result can be stored in: │
│ • D register: if dest bit [2] = 1 │
│ • A register: if dest bit [1] = 1 │
│ • M register: if dest bit [0] = 1 (also triggers memory write) │
│ │
│ After Multiply completes: │
│ • mul_product[15:0] can be stored in D, A, or M │
│ • Lower 16 bits are used (upper 16 bits of 32-bit result discarded) │
│ │
│ After Divide completes: │
│ • Quotient can be stored in D, A, or M │
│ • Remainder available for next instruction │
│ │
│ MEMORY INTERFACE: │
│ • addressM[15:0] - Address for memory access (from A register) │
│ • outM[15:0] - Data to write to memory │
│ • writeM - Write enable signal │
│ • inM[15:0] - Data read from memory (used as ALU operand) │
│ │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│ 6. TOP-LEVEL SYSTEM (system_top.v) │
├─────────────────────────────────────────────────────────────────────────────┤
│ │
│ Purpose: Instantiates all modules and shows how they're connected │
│ │
│ INSTANTIATES: │
│ 1. u_alu - Single shared ALU │
│ 2. u_cpu - Main processor │
│ 3. u_arbiter - Router/Arbiter │
│ 4. u_multiply - Multiply FSM │
│ 5. u_divide - Divide FSM │
│ │
│ EXTERNAL INTERFACES: │
│ • clk, rst - Clock and reset │
│ • pc[15:0] - Program counter (to ROM address) │
│ • instruction[15:0] - Instruction from ROM │
│ • addressM[15:0] - Memory address (to RAM) │
│ • inM[15:0] - Data from RAM │
│ • outM[15:0] - Data to RAM │
│ • writeM - Memory write enable │
│ • flags[3:0] - Status flags output │
│ │
│ INTERNAL SIGNAL ROUTING: │
│ The system_top module declares all wires and connects them: │
│ - CPU outputs → Arbiter inputs │
│ - Arbiter outputs → ALU inputs │
│ - ALU outputs → Arbiter inputs │
│ - Arbiter outputs → CPU/FSM inputs │
│ - FSM outputs → Arbiter/CPU inputs │
│ │
└─────────────────────────────────────────────────────────────────────────────┘

================================================================================
EXAMPLE: MUL INSTRUCTION
================================================================================

Timeline: What happens when CPU executes a MUL (multiply) instruction

CLOCK CYCLE 1: CPU decodes MUL instruction
─────────────
• Arbiter sees: opcode = 6'b010100 (MUL)
• Arbiter state: IDLE → MUL
• Arbiter actions: - Set stall = 1 (freeze CPU) - Set start_mul = 1 (signal Multiply FSM to begin)
• CPU sees stall = 1, Program Counter doesn't increment
• Multiply FSM receives start = 1

CLOCK CYCLE 2-N: Multiply FSM executes
──────────────────
Multiply FSM performs Baugh-Wooley algorithm:

For each of 16 iterations:
Step 1: Check Q[0] and Q_1
Step 2: Request ALU (set mul_req_alu = 1)
alu_op = (ADD or SUB)
alu_x = A register value
alu_y = M or M_BAR value
Step 3: Arbiter routes to ALU
Step 4: ALU computes and returns result
Step 5: Multiply FSM captures result, shifts {A,Q}
Step 6: Repeat

During all this:
• CPU is stalled (doesn't execute)
• Arbiter routes Multiply's ALU requests
• ALU does the arithmetic

CLOCK CYCLE N+1: Multiply completes
──────────────
• Multiply FSM sets done = 1
• Produces 32-bit product
• Arbiter sees mul_done = 1, state: MUL → IDLE
• Arbiter sets stall = 0 (unfreeze CPU)
• CPU can continue to next instruction

CLOCK CYCLE N+2: Result stored
──────────────
• CPU executes writeback:
If destination bits say "store in D":
D ← mul_product[15:0]
If destination bits say "store in A":
A ← mul_product[15:0]
If destination bits say "store in M":
M ← mul_product[15:0]
writeM ← 1 (write to memory)

• Next instruction can now execute

================================================================================
KEY DESIGN PATTERNS
================================================================================

1. REQUEST-RESPONSE PATTERN
   ─────────────────────────

   FSM needs ALU operation:

   1. Set req_alu = 1
   2. Provide: alu_op, alu_x, alu_y
   3. Wait for Arbiter to route
   4. Arbiter sends to ALU
   5. ALU computes
   6. Arbiter routes result back
   7. FSM receives and captures alu_result

   This allows one ALU to serve multiple modules

2. MULTIPLEXING PATTERN
   ───────────────────

   Arbiter uses multiplexers:
   if (cpu_active)
   ALU inputs ← CPU inputs
   else if (mul_req_alu)
   ALU inputs ← Multiply inputs
   else if (div_req_alu)
   ALU inputs ← Divide inputs

   Only one set of inputs is active at a time

3. STALL PATTERN
   ──────────────

   When FSM is running:
   • CPU stall = 1
   • Program counter doesn't advance
   • Registers don't update
   • Instruction doesn't change

   When FSM finishes:
   • stall = 0
   • CPU resumes normal operation

4. FLAG PROPAGATION PATTERN
   ─────────────────────────

   ALU produces flags for every operation:
   • Carry flag (for arithmetic)
   • Negative flag (sign bit)
   • Zero flag (result is zero)
   • Overflow flag (result overflowed)

   For CPU operations:
   • Arbiter passes flags to CPU
   • CPU stores in flags register

   For FSM operations:
   • Arbiter passes specific flags to FSM
   • Divide FSM uses carry_flag for decision
   • Multiply FSM ignores flags

================================================================================
DATA WIDTHS & TYPES
================================================================================

16-bit Architecture:
• All registers: 16 bits (signed or unsigned)
• All ALU operands: 16 bits
• ALU results: 16 bits

Special Cases:
• Multiply product: 32 bits (16 × 16 → 32) - Upper 16 bits stored in A - Lower 16 bits stored in Q - Final product = {A, Q}

• Divide quotient: 16 bits
• Divide remainder: 16 bits - Remainder is positive (magnitude) - Must be adjusted based on dividend sign

Signed vs Unsigned:
• All registers use two's complement signed representation
• Multiply FSM: Baugh-Wooley handles signed multiplication
• Divide FSM: Restoring division with sign adjustment

================================================================================
COMPILATION & SYNTHESIS
================================================================================

To compile and simulate:

iverilog -o system_exe system_top.v alu.v cpu.v cpu_arbiter.v \
 multiply_shared.v divide_shared.v

vvp system_exe
gtkwave system.vcd

To use in synthesis:

All files use standard Verilog (no test benches)
Synthesis tools will automatically:
• Optimize multiplexers
• Infer registers from always @(posedge clk)
• Combine combinational logic
• Generate optimal hardware

================================================================================
DEBUGGING TIPS
================================================================================

1. Watch the stall signal

   - stall = 1 means CPU is frozen
   - Useful for seeing when MUL/DIV runs

2. Monitor ALU inputs/outputs

   - alu_opcode tells what operation is happening
   - alu_x_in, alu_y_in are the operands
   - alu_result is the answer

3. Track FSM states

   - Watch state variable in multiply_shared
   - Watch state variable in divide_shared
   - Watch state variable in arbiter

4. Check valid signals

   - mul_alu_result_valid, div_alu_result_valid
   - Tells when result is ready for FSM

5. Verify register updates
   - D, A, M change after ALU operations
   - Check if destination bits are set correctly

================================================================================
