module ser_aggregate_tb;

    logic clk, reset, en;
    logic [63:0] addr;
    TABLE_ENTRY entry;
    logic entry_valid;
    logic [15:0][7:0] dram_output;
    logic [15:0] dram_valid_full;
    logic [7:0][7:0] dram_data_in;
    logic [7:0] dram_valid;
    logic done, ready;
    logic [7:0][7:0] dram_data_out;
    logic [7:0][63:0] dram_addr;
    logic [7:0] dram_en;
    logic dram_rdwr;

    assign dram_data_in = dram_output[7:0];
    assign dram_valid = dram_valid_full[7:0];

    initial 
    begin
        clk = 0;
    end

    always
        #1 clk = !clk;

    ser_aggregate sa
    (
        .clk(clk), 
        .reset(reset), 
        .en(en), 
        .addr(addr), 
        .entry(entry), 
        .entry_valid(entry_valid), 
        .done(done), 
        .ready(ready), 
        .dram_en(dram_en), 
        .dram_rdwr(dram_rdwr), 
        .dram_data_in(dram_data_in), 
        .dram_addr(dram_addr), 
        .dram_data_out(dram_data_out), 
        .dram_valid(dram_valid)
    );

    DRAM dram(
        .clk(clk),
        .reset(reset),
        .en({{8{1'b0}},dram_en}),
        .rdwr({1'b0,dram_rdwr}),
        .data_in({{64{1'b0}}, dram_data_out}),
        .addr({{8{64'b0}}, dram_addr}),
        .data_out(dram_output),
        .valid(dram_valid_full)
    );

    initial
    begin

        $monitor("@%g state=%b, dram_en=%b, dram_valid=%b, dram_rdwr=%b, dram_addr=%h, data_from_dram=%h, data_to_dram=%h, vs_en=%b, mc_en=%b", $time, sa.state, dram_en, dram_valid, dram_rdwr, dram_addr, dram_data_in, dram_data_out, sa.vs_en, sa.memcpy_en);

        reset = 1;
        en = 0;
        @(negedge clk);
        reset = 0;
        @(negedge clk);
        @(negedge clk);
        $readmemh("testbench/table3.mem", dram.mem, 64'h10);
        $readmemh("testbench/table4.mem", dram.mem, 64'h100);
        $readmemh("testbench/table5.mem", dram.mem, 64'h200);

        dram.mem[4] = 8'hff;
        dram.mem[5] = 8'hff;
        dram.mem[6] = 8'hff;
        dram.mem[7] = 8'hff;
        for (int i = 64'h4; i <= 64'hF; i+=1)
            $display("mem[%h] = %h", i, dram.mem[i]);
        addr = 4;
        entry = {dram.mem['h17],dram.mem['h16],dram.mem['h15],dram.mem['h14],dram.mem['h13],dram.mem['h12],dram.mem['h11],dram.mem['h10], 64'hx};
        $display("entry=%h",entry);
        $display("field id=%d",entry.field_id);
        $display("nested=%b",entry.nested);
        $display("field type=%b",entry.field_type);

        entry_valid = 1;
        en = 1;
        @(negedge clk);
        while (~done) @(negedge clk);

        for (int i = 64'h300; i >= 64'h2E0; i-=1)
            $display("mem[%h] = %h", i, dram.mem[i]);
        $display("done");
        $finish;
    end

endmodule
