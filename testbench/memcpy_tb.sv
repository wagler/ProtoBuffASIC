module memcpy_tb;

    logic clk, reset, memcpy_en;

    logic [63:0] src, dst;
    logic [14:0] size;
    logic [15:0] dram_valid;
    logic [15:0][7:0] dram_data_in; // data coming out of dram going into memcpy

    logic done;
    logic [7:0] dram_en;
    logic dram_rdwr;
    logic [7:0][63:0] dram_addr;
    logic [7:0][7:0] dram_data_out; // data coming out of memcpy going into dram

    DRAM ram(
        .clk(clk),
        .reset(reset),
        .en({{8{1'b0}},dram_en}),
        .rdwr({1'b0,dram_rdwr}),
        .data_in({{8{8'd0}},dram_data_out}),
        .addr({{8{64'd0}},dram_addr}),
        .data_out(dram_data_in),
        .valid(dram_valid)
    );

    memcpy m(
        .clk(clk),
        .reset(reset),
        .en(memcpy_en),
        .src(src),
        .dst(dst),
        .size(size),
        .done(done),
        .dram_en(dram_en),
        .dram_rdwr(dram_rdwr),
        .dram_addr(dram_addr),
        .dram_data_in(dram_data_in[7:0]),
        .dram_data_out(dram_data_out),
        .dram_valid(dram_valid[7:0])
    );

    initial
    begin
        clk = 0;
    end

    always
        #1 clk = !clk;

    initial
    begin
    
        ram.mem[64'h100] = 8'hbe;

        $monitor("@%g reset=%b, memcpy_en=%b, state=%b, src=%h, dst=%h, done=%b, dram_en=%b, dram_valid=%b, dram_addr=%h, data_to_dram=%h, data_from_dram=%h, dram_rdwr=%b",$time, reset, memcpy_en, ram.state, src, dst, done, dram_en, dram_valid, ram.addr, ram.data_in, ram.data_out, dram_rdwr);

        reset = 1;
        memcpy_en = 0;
        @(negedge clk);
        reset = 0;
        @(negedge clk);
        src = 64'h100;
        dst = 64'h3FF;
        size = 15'd1;
        memcpy_en = 1;
        @(negedge clk);
        while(~done) @(negedge clk);

        ram.mem[64'h100] = 8'hbe;
        ram.mem[64'h101] = 8'hef;
        ram.mem[64'h102] = 8'hba;
        ram.mem[64'h103] = 8'had;

        @(negedge clk);
        reset = 1'b1;
        memcpy_en = 1'b0;
        @(negedge clk);
        reset = 1'b0;
        memcpy_en = 1'b0;
        src = 64'h100;
        dst = 64'h200;
        size = 15'd4;
        @(negedge clk);
        memcpy_en = 1'b1;
        @(negedge clk);
        while(~done) @(negedge clk);

        for (int i = 'h100; i < 'h104; i=i+1)
        begin
            $display("mem[%h] = %h",i,ram.mem[i]);
        end
        for (int i = 'h200; i < 'h204; i=i+1)
        begin
            $display("mem[%h] = %h",i,ram.mem[i]);
        end
        $finish;
    end

endmodule
