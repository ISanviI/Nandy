// Asynchronous ROM
module rom #(
    parameter ADDR_WIDTH = 16,
    parameter DATA_WIDTH = 32
)(
    input  wire [ADDR_WIDTH-1:0] addr,
    output reg  [DATA_WIDTH-1:0] data
);

    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    initial begin
        $readmemh("program.hex", mem);
    end

    always @(*) begin
        data = mem[addr];
    end
endmodule

// Synchronous ROM
always @(posedge clk) begin
    data <= mem[addr];
end