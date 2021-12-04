module dram_tb;

    logic clk;
    logic reset;
    logic [15:0] en;
    logic [1:0] rdwr;
    logic [15:0][7:0] data_in;
    logic [15:0][63:0] addr;
    logic [15:0][7:0] data_out;
    logic [15:0] valid;

    initial
    begin
        clk = 0;
    end

    always
        #1 clk = !clk;

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

    task write_mem;
        integer fp, j;
        fp = $fopen("dram.mem");
        for (j = 0; j < 1024; j=j+1)
        begin
            $fdisplay(fp, "%h", dram.mem[j]);
        end
        $fclose(fp);
    endtask

    integer i;
    initial
    begin
        $monitor("@%g reset=%b, en=%b, data_in=%h, addr=%h, data_out=%h, valid=%b, state=%d, cnt=%d, state2=%d, cnt2=%d, rdwr=%b",$time, reset, dram.en_int, dram.data_in_int, dram.addr_int, data_out, valid, dram.state, dram.cnt, dram.state2, dram.cnt2, dram.rdwr);

        // Reset
        reset = 1'b1;
        @(negedge clk);
        reset = 1'b0;
        en    = 16'b0;
        @(negedge clk);
/*
        // Simple write test
        data_in[0] = 8'd1;
        addr[0] = 64'd0;
        en[0] = 1'b1;
        rdwr[0] = 1'd0;
        @(negedge clk);
        en[0] = 1'b0;
        while(dram.state != 2'b11) @(negedge clk);
        $display("wrote: %h",data_in[0]);
        $display("mem[0x0]=%h",dram.mem[0]);

        // Simple read test
        addr[0] = 64'd0;
        en[0] = 1'b1;
        rdwr[0] = 1'd1;
        @(negedge clk);
        en[0] = 1'b0;
        while(~valid[0]) @(negedge clk);
        $display("mem[0x0]=%h",dram.mem[0]);
        $display("read: %h",data_out[0]);

        // Write to two addresses, simultaneously
        data_in[0] = 8'hbe;
        data_in[1] = 8'hef;
        addr[0] = 64'd1;
        addr[1] = 64'd2;
        rdwr[0] = 1'b0;
        en[0] = 1'b1;
        en[1] = 1'b1;
        @(negedge clk);
        en[0] = 1'b0;
        en[1] = 1'b0;
        while(dram.state != 2'b11) @(negedge clk);
        $display("wrote: %h",data_in[0]);
        $display("wrote: %h",data_in[1]);
        $display("mem[0x1]=%h",dram.mem[1]);
        $display("mem[0x2]=%h",dram.mem[2]);

        // Read from two addresses, simultaneously
        addr[0] = 64'd1;
        addr[1] = 64'd2;
        rdwr[0] = 1'b1;
        en[0] = 1'b1;
        en[1] = 1'b1;
        @(negedge clk);
        en[0] = 1'b0;
        en[1] = 1'b0;
        while(valid != 3) @(negedge clk);
        $display("mem[0x1]=%h",dram.mem[0]);
        $display("mem[0x2]=%h",dram.mem[1]);
        $display("read: %h",data_out[1]);
        $display("read: %h",data_out[2]);

*/
        // Write to 2 separate ports at the same time
        addr[0] = 64'h0;
        addr[1] = 64'h1;
        addr[8] = 64'h100;
        addr[9] = 64'h101;
        
        data_in[0] = 8'hde;
        data_in[1] = 8'had;
        data_in[8] = 8'hbe;
        data_in[9] = 8'hef;

        rdwr = 2'b00;

        en[0] = 1'b1;
        en[1] = 1'b1;
        en[8] = 1'b1;
        en[9] = 1'b1;

        @(negedge clk);

        en[0] = 1'b0;
        en[1] = 1'b0;
        en[8] = 1'b0;
        en[9] = 1'b0;


        for (int i = 0; i < 40; i=i+1)
        begin
            @(negedge clk);
        end


        @(negedge clk);
        rdwr = 2'b11;

        en[0] = 1'b1;
        en[1] = 1'b1;
        en[8] = 1'b1;
        en[9] = 1'b1;

        @(negedge clk);

        en[0] = 1'b0;
        en[1] = 1'b0;
        en[8] = 1'b0;
        en[9] = 1'b0;

        while(~(valid[0] & valid[1] & valid[8] & valid[9])) @(negedge clk);
        $display("mem[0]=%h",data_out[0]);
        $display("mem[1]=%h",data_out[1]);
        $display("mem[100]=%h",data_out[8]);
        $display("mem[101]=%h",data_out[9]);

        @(negedge clk);
        rdwr = 2'b10;

        data_in[0] = 8'hba;
        data_in[1] = 8'had;

        en[0] = 1'b1;
        en[1] = 1'b1;
        en[8] = 1'b1;
        en[9] = 1'b1;

        @(negedge clk);

        en[0] = 1'b0;
        en[1] = 1'b0;
        en[8] = 1'b0;
        en[9] = 1'b0;

        for (int i = 0; i < 40; i=i+1)
        begin
            @(negedge clk);
        end

        write_mem();
        $finish;
    end

endmodule
