module multiply_tb();
    reg tb_clk, tb_rst, tb_start;
    reg signed [15:0] tb_multiplier;
    reg signed [15:0] tb_multiplicand;

    wire [31:0] tb_product;

    multiply u_multiply (
        .clk(tb_clk),
        .rst(tb_rst),
        .start(tb_start),
        .multiplier(tb_multiplier),
        .multiplicand(tb_multiplicand),
        .product(tb_product)
    );

    // Clock generation
    initial begin
        tb_clk = 0;
        forever #5 tb_clk = ~tb_clk; // 10 time units clock period
    end
    // Testbench procedure
    // 1. 12;  2. 0;  3. -1; 4. 0;  5. 882;  6. -108
    initial begin
        // Initialize inputs
        tb_rst = 1;
        tb_start = 0;
        tb_multiplier = 0;
        tb_multiplicand = 0;

        // Release reset
        #15;
        tb_rst = 0;

        // Time required for each testcase - 
        // 1. 1 cycle for INIT
        // 2. 16x2 cycles for OPERATION and SHIFT (each takes 1 cycle and is done 16 times)
        // 3. 1 cycle for DONE
        // 4. Total = 34 cycles = 340 time units

        // Test case 1
        #10;
        tb_multiplier = 16'sd3;     // sd - signed decimal
        tb_multiplicand = 16'sd4;
        tb_start = 1;
        #10;
        tb_start = 0;

        // Wait for operation to complete
        #400;

        // Test case 2
        #10;
        tb_multiplier = -16'sd0;
        tb_multiplicand = 16'sd0;
        tb_start = 1;
        #10;
        tb_start = 0;
        #400;

        // Test case 3
        #10;
        tb_multiplier = -16'sd1;
        tb_multiplicand = 16'sd1;
        tb_start = 1;
        #10;
        tb_start = 0;
        #400;

        // Test case 4
        #10;
        tb_multiplier = -16'sd1;
        tb_multiplicand = 16'sd0;
        tb_start = 1;
        #10;
        tb_start = 0;
        #400;

        // Test case 5
        #10;
        tb_multiplier = -16'sd42;
        tb_multiplicand = -16'sd21;
        tb_start = 1;
        #10;
        tb_start = 0;
        #400;

        // Test case 6
        #10;
        tb_multiplier = 16'sd9;
        tb_multiplicand = -16'sd12;
        tb_start = 1;
        #10;
        tb_start = 0;
        #400;

        // Finish simulation
        $finish;
    end

    initial begin
        $monitor("Time: %0t | Multiplier (Q): %d | Multiplicand (M): %d | Product: %d", 
                  $time, tb_multiplier, tb_multiplicand, tb_product);
    end

    initial begin
        $dumpfile("multiply_tb.vcd");
        $dumpvars(0, multiply_tb);
    end
endmodule