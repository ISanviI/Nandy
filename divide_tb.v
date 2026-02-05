module divide_tb();
    reg tb_clk, tb_rst, tb_start;
    reg signed [15:0] tb_dividend;
    reg signed [15:0] tb_divisor;

    wire [15:0] tb_quotient;
    wire [15:0] tb_remainder;
    wire done;
    
    divide16 u_divide (
        .clk(tb_clk),
        .rst(tb_rst),
        .start(tb_start),
        .dividend(tb_dividend),
        .divisor(tb_divisor),
        .quotient(tb_quotient),
        .remainder(tb_remainder),
        .done(done)
    );

    // Clock generation
    initial begin
        tb_clk = 0;
        forever #5 tb_clk = ~tb_clk; // 10 time units clock period
    end

    // Testbench procedure
    initial begin
        // Initialize inputs
        tb_rst = 1;
        tb_start = 0;
        tb_dividend = 0;
        tb_divisor = 0;

        // Release reset
        #15;
        tb_rst = 0;

        // Test case 1: 10 / 2
        #10;
        tb_dividend = 16'sd10;     
        tb_divisor = 16'sd2;
        tb_start = 1;
        #10;
        tb_start = 0;

        // Wait for operation to complete
        #400;

        // Test case 2: -15 / 3
        #10;
        tb_dividend = -16'sd15;     
        tb_divisor = 16'sd3;
        tb_start = 1;
        #10;
        tb_start = 0;

        // Wait for operation to complete
        #400;

        // Test case 3: -20 / -4
        #10;
        tb_dividend = -16'sd20;     
        tb_divisor = -16'sd4;
        tb_start = 1;
        #10;
        tb_start = 0;

        // Wait for operation to complete
        #400;

        // Test case 4: 90 / -7
        #10;
        tb_dividend = 16'sd90;     
        tb_divisor = -16'sd7;
        tb_start = 1;
        #10;
        tb_start = 0;

        // Wait for operation to complete
        #400;

        // Test case 5: 0 / 1
        #10;
        tb_dividend = 16'sd0;     
        tb_divisor = 16'sd1;
        tb_start = 1;
        #10;
        tb_start = 0;

        // Wait for operation to complete
        #400;

        // Test case 6: 1 / 0
        #10;
        tb_dividend = 16'sd1;     
        tb_divisor = 16'sd0;
        tb_start = 1;
        #10;
        tb_start = 0;

        // Wait for operation to complete
        #400;
        $finish;
    end

    initial begin
        $monitor("Time: %0t | Dividend: %d | Divisor: %d | Quotient: %d | Remainder: %d | Done: %b", 
                 $time, tb_dividend, tb_divisor, tb_quotient, tb_remainder, done);
    end

    initial begin
        $dumpfile("divide_tb.vcd");
        $dumpvars(0, divide_tb);
    end

endmodule