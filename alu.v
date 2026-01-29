module ALU (
    input wire [7:0] opcode,
    input wire signed [15:0] A,
    input wire signed [15:0] B,
    output reg signed [15:0] result,
    output reg [15:0] flags,    // carry, negative, zero, overflow, 
);
    reg signed [16:0] temp;

always @(*) begin
    case (opcode)
        8'b00000001: begin
            temp = A + B;          // ADD
            result = temp[15:0];
            flags[0] = temp[16];
            flags[1] = result[15];
        end
        8'b00000010: begin
            temp = A - B;          // SUB
            result = temp[15:0];
            flags[0] = temp[16];
            flags[1] = result[15];
        end
        8'b00000011: result = A & B;          // AND
        8'b00000100: result = A | B;          // OR
        8'b00000101: result = A ^ B;          // XOR
        8'b00000110: result = ~A;             // NOT A
        8'b00000111: result = A << 1;         // SHIFT LEFT
        8'b00001000: result = A >> 1;         // SHIFT RIGHT
        8'b00001001: result = ~B;             // NOT B
        8'b00001010: result = B << 1;         // SHIFT LEFT B
        8'b00001011: result = B >> 1;         // SHIFT RIGHT B
        8'b00001100: result = A <<< 1;        // ARITHMETIC SHIFT LEFT A
        8'b00001101: result = A >>> 1;        // ARITHMETIC SHIFT RIGHT A
        8'b00001110: result = B <<< 1;        // ARITHMETIC SHIFT LEFT B
        8'b00001111: result = B >>> 1;        // ARITHMETIC SHIFT RIGHT B
        8'b00010000: result = 1;              // CONSTANT 1
        8'b00010001: result = -1;             // CONSTANT -1
        default: result = 16'b0;              // DEFAULT
    endcase
    // Set zero flag
    flags[2] = (result == 16'b0) ? 1'b1 : 1'b0;
    // Set overflow flag for addition and subtraction
    if (opcode == 8'b00000001) begin // ADD
        flags[3] = ((A[15] == B[15]) && (result[15] != A[15])) ? 1'b1 : 1'b0;
    end else if (opcode == 8'b00000010) begin // SUB
        flags[3] = ((A[15] != B[15]) && (result[15] != A[15])) ? 1'b1 : 1'b0;
    end else begin
        flags[3] = 1'b0;
    end
end
    
endmodule