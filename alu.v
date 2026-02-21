module ALU (
    input wire [5:0] opcode,
    input wire signed [15:0] D,
    input wire signed [15:0] M,
    output reg signed [15:0] result,
    output reg [3:0] flags,    // carry, negative, zero, overflow, 
);
    reg signed [16:0] temp;

always @(*) begin
    case (opcode)
        6'b000001: begin
            temp = D + M;          // ADD
            result = temp[15:0];
            flags[3] = temp[16];
            flags[2] = result[15];
        end
        6'b000010: begin
            temp = D - M;          // SUB
            result = temp[15:0];
            flags[3] = temp[16];
            flags[2] = result[15];
        end
        6'b000011: result = D & M;          // AND
        6'b000100: result = D | M;          // OR
        6'b000101: result = D ^ M;          // XOR
        6'b000110: result = ~D;             // NOT D
        6'b000111: result = D + 1;          // INC D
        6'b001000: result = D - 1;          // DEC D
        6'b001001: result = ~M;             // NOT M
        6'b001010: result = M + 1;          // INC M
        6'b001011: result = M - 1;          // DEC M
        6'b001100: result = D <<< 1;        // ARITHMETIC SHIFT LEFT D
        6'b001101: result = D >>> 1;        // ARITHMETIC SHIFT RIGHT D
        6'b001110: result = M <<< 1;        // ARITHMETIC SHIFT LEFT M
        6'b001111: result = M >>> 1;        // ARITHMETIC SHIFT RIGHT M
        6'b010000: result = -1;             // CONSTANT -1
        6'b010001: result = 1;              // CONSTANT 1
        6'b010010: result = ~D + 1;         // COMPLEMENT D
        6'b010011: result = ~M + 1;         // COMPLEMENT M
        // 6'b010100 - Multiplication
        // 6'b010101 - Division_Quotient
        // 6'b010110 - Division_Remainder
        6'b010111: result = D;              // PASS D
        6'b011000: result = M;              // PASS M
        default: result = 16'b0;            // DEFAULT
    endcase
    // Set zero flag
    flags[1] = (result == 16'b0) ? 1'b1 : 1'b0;
    // Set overflow flag for addition and subtraction
    if (opcode == 6'b000001) begin // ADD
        flags[0] = ((D[15] == M[15]) && (result[15] != D[15])) ? 1'b1 : 1'b0;
    end else if (opcode == 6'b000010) begin // SUB
        flags[0] = ((D[15] != M[15]) && (result[15] != D[15])) ? 1'b1 : 1'b0;
    end else begin
        flags[0] = 1'b0;
    end
end
    
endmodule