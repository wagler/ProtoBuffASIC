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
        #1 clk = !clk

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
        .addr({{8{8'b0}}, dram_addr}),
        .data_out(dram_output),
        .valid(dram_valid_full)
    );

    initial
    begin
        reset = 1;
        en = 0;
        @(negedge clk);
        reset = 0;
        @(negedge clk);
        $readmemh("testbench/table3.mem", dram.mem);
        $readmemh("testbench/table4.mem", dram.mem, 64'h100);
        $readmemh("testbench/table5.mem", dram.mem, 64'h200);

    end

endmodule
