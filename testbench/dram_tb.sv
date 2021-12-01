module dram_tb;

    logic clk;
    logic reset;
    logic [7:0] en;
    logic rdwr;
    logic [7:0][7:0] data_in;
    logic [7:0][63:0] addr;
    logic [7:0][7:0] data_out;
    logic [7:0] valid;

    initial
    begin
        clk = 0;
    end

    always
        #1 clk = !clk;

    initial
    begin
        $dumpfile("dram.vcd");
        $dumpvars;
    end

    DRAM dram(
        .clk(clk),
        .reset(reset),
        .en(en),
        .rdwr(rdwr),
        .data_in(data_in),
        .addr(addr),
        .data_out(data_out),
        .valid(valid)
    );

    integer i;
    initial
    begin
        $monitor("@%g reset=%b, en=%b, data_in=%h, addr=%h, data_out=%h, valid=%b, state=%d, cnt=%d, rdwr=%b",$time, reset, dram.en_int, dram.data_in_int, dram.addr_int, data_out, valid, dram.state, dram.cnt, dram.rdwr);

        // Reset
        reset = 1'b1;
        @(negedge clk);
        @(negedge clk);
        @(negedge clk);
        reset = 1'b0;
        en    = 8'b0;
        @(negedge clk);
        @(negedge clk);

        // Simple write test
        data_in[0] = 64'd1;
        addr[0] = 64'd0;
        en[0] = 1'b1;
        rdwr = 1'd0;
        @(negedge clk);
        @(negedge clk);
        en[0] = 1'b0;
        for(i = 0; i <= 21; i=i+1)
        begin
            @(negedge clk);
        end

        // Simple read test
        addr[0] = 64'd0;
        en[0] = 1'b1;
        rdwr = 1'd1;
        @(negedge clk);
        @(negedge clk);
        en[0] = 1'b0;
        for(i = 0; i <= 21; i=i+1)
        begin
            @(negedge clk);
        end

        // Write to two addresses, simultaneously
        addr[0] = 64'd1;
        addr[1] = 64'd2;
        rdwr = 1'b0;
        en[0] = 1'b1;
        en[1] = 1'b1;
        @(negedge clk);
        @(negedge clk);
        en[0] = 1'b0;
        en[1] = 1'b0;
        for(i = 0; i <= 21; i=i+1)
        begin
            @(negedge clk);
        end

        // Read from two addresses, simultaneously
        addr[0] = 64'd1;
        addr[1] = 64'd2;
        rdwr = 1'b1;
        en[0] = 1'b1;
        en[1] = 1'b1;
        @(negedge clk);
        @(negedge clk);
        en[0] = 1'b0;
        en[1] = 1'b0;
        for(i = 0; i <= 22; i=i+1)
        begin
            @(negedge clk);
        end

        $finish;
    end

endmodule
