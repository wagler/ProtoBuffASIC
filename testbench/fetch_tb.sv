module fetch_tb;
    logic clk, reset;
    logic en;

    logic [63:0] new_addr;
    logic new_addr_valid;

    logic [7:0]       dram_valid;
    logic [7:0][7:0]  dram_data;
    logic [7:0]       dram_en;
    logic             dram_rdwr;
    logic [7:0][63:0] dram_addr;

    logic       ob_full;
    logic       ob_valid;
    TABLE_ENTRY entry;

    fetch f(
        .clk(clk),
        .reset(reset),
        .en(en),
        .new_addr(new_addr),
        .new_addr_valid(new_addr_valid),
        .dram_valid(dram_valid),
        .dram_data(dram_data),
        .dram_en(dram_en),
        .dram_rdwr(dram_rdwr),
        .dram_addr(dram_addr),
        .entry(entry),
        .ob_full(ob_full),
        .ob_valid(ob_valid)
    );

    initial
    begin
        clk = 0;
    end

    always
        #1 clk = !clk;

    initial
    begin
        $monitor("@%g state=%d, reset=%b, en=%b, dram_en=%b, dram_addr=%h, ob_valid=%b, entry=%h", $time, f.state, reset, en, dram_en, dram_addr, ob_valid, entry);
        reset = 1;
        en = 0;
        @(negedge clk);
        reset = 0;
        en = 0;
        @(negedge clk);
        new_addr_valid = 0;
        dram_valid = 1;
        dram_data = 64'h0102030405060708;
        ob_full = 0;
        en = 1;

        for (int i=0; i < 21; i=i+1)
        begin
            @(negedge clk);
        end
    
        $finish;
    end
endmodule
