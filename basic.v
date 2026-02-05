// Signed - The most significant bit contains info about the sign of the number. 1 means negative, 0 means positive. If negative, the actual number is negative in magnitude equal to the two's complement of itself.
// So negative numbers are stored in two's complement form of its absolute value/magnitude.

module mux_21 #(
    parameter WIDTH = 16
)(
    input wire sel,
    input wire [WIDTH-1:0] in0,
    input wire [WIDTH-1:0] in1,
    output wire [WIDTH-1:0] out
);
    assign out = sel ? in1 : in0;
endmodule

module mux_81 #(
    parameter WIDTH = 8
)(
    input wire [2:0] sel,
    input wire [WIDTH-1:0] in,
    output wire [WIDTH-1:0] out
);
    assign out = in[sel];
endmodule

module priority_encode_83 (
    input wire [7:0] in,
    output reg [2:0] out,
    output reg valid
);
    always @(*) begin
        valid = 1'b1;
        casez (in)
            8'b1???????: out = 3'd7;
            8'b01??????: out = 3'd6;
            8'b001?????: out = 3'd5;
            8'b0001????: out = 3'd4;
            8'b00001???: out = 3'd3;
            8'b000001??: out = 3'd2;
            8'b0000001?: out = 3'd1;
            8'b00000001: out = 3'd0;
            default: begin
                valid = 1'b0;
                out = 3'd0; // No bits set
            end  
        endcase
    end
endmodule

module priority_encode_164 (
    input wire [15:0] in,
    output reg [3:0] out,
    output reg valid
);
    always @(*) begin
        valid = 1'b1;
        casez (in)
            16'b1???????????????: out = 4'd15;
            16'b01??????????????: out = 4'd14;
            16'b001?????????????: out = 4'd13;
            16'b0001????????????: out = 4'd12;
            16'b00001???????????: out = 4'd11;
            16'b000001??????????: out = 4'd10;
            16'b0000001?????????: out = 4'd9;
            16'b00000001????????: out = 4'd8;
            16'b000000001???????: out = 4'd7;
            16'b0000000001??????: out = 4'd6;
            16'b00000000001?????: out = 4'd5;
            16'b000000000001????: out = 4'd4;
            16'b0000000000001???: out = 4'd3;
            16'b00000000000001??: out = 4'd2;
            16'b000000000000001?: out = 4'd1;
            16'b0000000000000001: out = 4'd0;
            default: begin
                valid = 1'b0;
                out = 4'd0; // No bits set
            end
        endcase
    end
endmodule