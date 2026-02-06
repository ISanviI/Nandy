module pc (
    input clk, rst,
    input wire [15:0] pc_in,
    input wire [1:0] control,
    output reg [15:0] pc_out
);

always @(posedge clk or posedge rst) begin
    if (rst) pc_out <= 0;                   // reset
    else begin
        case (control)
            2'b01: pc_out <= pc_out + 1;    // increment
            2'b10: pc_out <= pc_in;         // load
            default: ; 
        endcase
    end
end
    
endmodule