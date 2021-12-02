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

    DRAM dram(
        .clk(clk),
        .reset(reset),
        .en(dram_en),
        .rdwr(dram_rdwr),
        .data_in({64{1'b0}}),
        .addr(dram_addr),
        .data_out(dram_data),
        .valid(dram_valid)
    );

    initial
    begin
        clk = 0;
    end

    always
        #1 clk = !clk;

    initial
    begin
        $dumpfile("fetch.vcd");
        $dumpvars;
    end

    initial
    begin
        $monitor("@%g state=%d, reset=%b, en=%b, dram_en=%b, dram_addr=%h, dram_valid=%b, dram_data=%h, ob_valid=%b, entry=%h", $time, f.state, reset, en, dram_en, dram_addr, dram_valid, dram_data, ob_valid, entry);
        reset = 1;
        en = 0;
        @(negedge clk);
        reset = 0;
        en = 0;
        new_addr_valid = 0;

        // Realistically, we could do this before the dram gets reset, because dram doesn't actually
        // clear its values when it gets reset, but we'll just do it after reset.
        $readmemh("testbench/demo16.mem", dram.mem);
        $display("Loaded the following data into memory at address 0x0");
        for (int i = 0; i < 16; i=i+1)
        begin
            $write("%h ",dram.mem[i]);
        end
        $write("\n");

        @(negedge clk);
        ob_full = 0;
        en = 1;
        @(negedge clk)
        en = 0;
        while(~ob_valid) @(negedge clk);
        @(negedge clk);



        // Load a 64 byte program into memory filled with random data.
        // This should start at addresss 0, so it will overwrite the original file data
        $readmemh("testbench/demo64.mem", dram.mem);
        $display("Loaded the following data into memory at address 0x0");
        for (int i = 0; i < 64; i=i+1)
        begin
            $write("%h ",dram.mem[i]);
        end
        $write("\n");

        // Start the fetch state machine again, but the address it fetches from should still be 0x10
        @(negedge clk);
        ob_full = 0;
        en = 1;
        @(negedge clk)
        en = 0;
        while(~ob_valid) @(negedge clk); 
        @(negedge clk); 

        $display("Running again, but with address set to 0x8");
        $display("memory:");
        for (int i = 0; i < 64; i=i+1)
        begin
            $write("%h ",dram.mem[i]);
        end
        $write("\n");
        new_addr = 64'h8;
        new_addr_valid = 1'b1;
        @(negedge clk);
        new_addr_valid = 1'b0;
        @(negedge clk);
        ob_full = 0;
        en = 1;
        @(negedge clk)
        en = 0;
        while(~ob_valid) @(negedge clk);

        $finish;
    end
endmodule
