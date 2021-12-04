module fetch_tb;
    logic clk, reset;
    logic en;

    logic [63:0] new_addr;
    logic new_addr_valid;

    logic [15:0]       dram_valid;
    logic [15:0][7:0]  dram_data;
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
        .dram_valid(dram_valid[7:0]),
        .dram_data(dram_data[7:0]),
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
        .en({{8{1'b0}},dram_en}),
        .rdwr({1'b0,dram_rdwr}),
        .data_in({128{1'b0}}),
        .addr({{512{1'b0}},dram_addr}),
        .data_out(dram_data),
        .valid(dram_valid)
    );

    task ras_printer;
        $display("\t+-----------------------------------+");
        $display("\t|     Return Address Stack  @%g     |",$time);
        $display("\t|-----------------------------------|");
        $display("\t|   item#    |                      |");
        $display("\t+-----------------------------------+");
        for (int i = 0; i < 3; i=i+1)
        begin
            if (i == f.ret_addr_stack_ptr)
                $write("->\t|%d : 0x%h   |\n", i, f.ret_addr_stack[i]);
            else
                $write("\t|%d : 0x%h   |\n", i, f.ret_addr_stack[i]);
        end
        $display("\t+-----------------------------------+");
    endtask

    task draw_fetch_info;
        $display("\t+-----------------------------------+");
        $display("\t|        Current Fetch Info  @%g    |",$time);
        $display("\t|-----------------------------------|");
        $display("\t| en       |                      %b |",en);
        $display("\t+-----------------------------------+");
        $display("\t| state    |                      %d |",f.state);
        $display("\t+-----------------------------------+");
        $display("\t| ob valid |                      %h |",ob_valid);
        $display("\t| entry    |     0x%h |",entry[127:64]);
        $display("\t|          |     0x%h |",entry[63:0]);
        $display("\t+-----------------------------------+");
        $display("\t| address  |     0x%h |",fetch.addr);
        $display("\t+-----------------------------------+");
        $display("\t| DRAM en  |               %b |",dram_en);
        $display("\t+-----------------------------------+");
        $display("\t| DRAM addr|     0x%h |",dram_addr[0]);
        $display("\t|          |     0x%h |",dram_addr[7]);
        $display("\t+-----------------------------------+");

    endtask

    initial
    begin
        clk = 0;
    end

    always
        #1 clk = !clk;

    initial
    begin
        //$monitor("@%g state=%d, reset=%b, en=%b, dram_en=%b, dram_addr=%h, dram_valid=%b, dram_data=%h, ob_valid=%b, entry=%h, ras_ptr=%h, ras_val=%h", $time, f.state, reset, en, dram_en, dram_addr, dram_valid, dram_data, ob_valid, entry, f.ret_addr_stack_ptr, f.ret_addr_stack[f.ret_addr_stack_ptr]);
        reset = 1;
        en = 0;
        @(negedge clk);
        reset = 0;
        en = 0;
        new_addr_valid = 0;
        ob_full = 0;

     /*  
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

        // Tests 2 tables in memory
        reset = 1;
        en = 0;
        @(negedge clk);
        reset = 0;
        draw_fetch_info();
        ras_printer();
        @(negedge clk);

        $readmemh("testbench/table1.mem", dram.mem);
        $readmemh("testbench/table2.mem", dram.mem, 64'h100);
        $display("Loaded the following data into memory at address 0x0");
        for (int i = 0; i < 32; i=i+1)
        begin
            $write("@0x%h : %h\n", i, dram.mem[i]);
        end
        for (int i = 64'h100; i < 64'h110; i=i+1)
        begin
            $write("@0x%h : %h\n", i, dram.mem[i]);
        end

        @(negedge clk);
        en = 1;
        
        while(~ob_valid) @(negedge clk);
        draw_fetch_info();
        ras_printer();
        @(negedge clk);

        while(~ob_valid) @(negedge clk);
        draw_fetch_info();
        ras_printer();
        @(negedge clk);

        while(~ob_valid) @(negedge clk);
        ras_printer();
        draw_fetch_info();
        @(negedge clk);

        while(~ob_valid) @(negedge clk);
        ras_printer();
        draw_fetch_info();
        @(negedge clk);

        while(~ob_valid) @(negedge clk);
        ras_printer();
        draw_fetch_info();
        @(negedge clk);
        en = 0;
*/        

/*   
        $readmemh("simple_proto/sim.table", dram.mem);
        $display("Loaded the following data into memory at address 0x0");
        for (int i = 0; i < 16; i=i+1)
        begin
            $write("@0x%h : %h\n", i, dram.mem[i]);
        end

        en = 0;
        @(negedge clk);
        en = 1;
        
        while(~ob_valid) @(negedge clk);
        @(negedge clk);
        while(~ob_valid) @(negedge clk);
        @(negedge clk);
        en = 0;

        for (int i = 0; i < 3; i=i+1)
        begin
            $display("%d : %h", i, f.ret_addr_stack[i]);
        end
*/

        
        $readmemh("testbench/table3.mem", dram.mem);
        $readmemh("testbench/table4.mem", dram.mem, 64'h100);
        $readmemh("testbench/table5.mem", dram.mem, 64'h200);

        @(negedge clk);
        ob_full = 0;

        for (int i = 0; i < 9; i+=1)
        begin
            en = 1;
            @(negedge clk)
            en = 0;
            while(~ob_valid) @(negedge clk);
            ras_printer();
            draw_fetch_info();
            @(negedge clk);
        end

        $finish;
    end
endmodule
