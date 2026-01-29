// Dual Port vs Single Port RAM
module ram #(
    parameter ADDR_WIDTH = 21,
    parameter DATA_WIDTH = 16
)(
    input  wire                  clk,
    input  wire                  we,
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire [DATA_WIDTH-1:0] wdata,
    output reg  [DATA_WIDTH-1:0] rdata
);

    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    // Read first in simultaneous Read-Write
    always @(posedge clk) begin
        if (we)
            mem[addr] <= wdata;
        rdata <= mem[addr];
    end
endmodule

// RAM initialization
initial begin
    $readmemh("data.hex", mem);
end