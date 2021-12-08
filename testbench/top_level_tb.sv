`timescale 10ns/1ns
module top_level_tb;

   	logic clk;
	logic reset;
    logic en;

    logic [15:0]       dram_valid;
    logic  [15:0][7:0]  data_from_dram;
    logic [15:0]       dram_en;
    logic [1:0]			dram_rdwr;
    logic [15:0][63:0] dram_addr;
    logic  [15:0][7:0]  data_to_dram;
	logic 				done;

	top_level tl1(
		.clk(clk),
		.reset(reset),
		.en(en),
		.dram_valid(dram_valid),
		.data_from_dram(data_from_dram),
		.dram_en(dram_en),
		.dram_rdwr(dram_rdwr),
		.dram_addr(dram_addr),
		.data_to_dram(data_to_dram),
		.done(done)
	);

    DRAM dram(
        .clk(clk),
        .reset(reset),
        .en(dram_en),
        .rdwr(dram_rdwr),
        .data_in(data_to_dram),
        .addr(dram_addr),
        .data_out(data_from_dram),
        .valid(dram_valid)
    );


    initial
    begin
        clk = 0;
    end

    always
        #1 clk = !clk;


    task print_ob;
        $display("\t  +-------------------------------------------------------------------------------------+");
        $display("\t  |                                 Object Buffer        @%g                            |",$time);
        $display("\t  +-------------------------------------------------------------------------------------+");
        $display("\t  |    entry    | valid | Field ID  | Type | Offset | Size  | Nested | Nested Table Addr|");
        $display("\t  +-------------------------------------------------------------------------------------+");
        for (int i = 0; i < 9; i=i+1)
        begin

            //if (ob.entries[i].valid)
            //begin
                if (tl1.ob.curr == i)
                begin
                    $display("\t->| %d |   %b   | %d |  %d  | %d  | %d |   %b    | %h |", 
                        i, tl1.ob.entries[i].valid, tl1.ob.entries[i].entry.field_id, tl1.ob.entries[i].entry.field_type, 
                        tl1.ob.entries[i].entry.offset, tl1.ob.entries[i].entry.size, tl1.ob.entries[i].entry.nested, tl1.ob.entries[i].entry.nested_type_table
                    );            
                end
                else
                begin
                    $display("\t  | %d |   %b   | %d |  %d  | %d  | %d |   %b    | %h |", 
                        i, tl1.ob.entries[i].valid, tl1.ob.entries[i].entry.field_id, tl1.ob.entries[i].entry.field_type, 
                        tl1.ob.entries[i].entry.offset, tl1.ob.entries[i].entry.size, tl1.ob.entries[i].entry.nested, tl1.ob.entries[i].entry.nested_type_table
                    );
                end
                $display("\t  +-------------------------------------------------------------------------------------+");
            //end
        end
    endtask

    task print_ob_stack;
        $display("\t  +--------------------------------------------------+");
        $display("\t  |                 OB Stack @%g                    |",$time);
        $display("\t  +--------------------------------------------------+");
        $display("\t  |     Stack Item        |     C++ Object Ptr       |");
        $display("\t  +--------------------------------------------------+");
        for (int i = 0; i < 16; i=i+1)
        begin
            if (tl1.ob.cpp_obj_ptr_stack_ptr == i)
                $display("\t->|%d            |        %h  |",i, tl1.ob.cpp_obj_ptr_stack[i]);
            else
                $display("\t  |%d            |        %h  |",i, tl1.ob.cpp_obj_ptr_stack[i]);
        $display("\t  +--------------------------------------------------+");
        end
    endtask
	initial
	begin

	$monitor("@%g dram_en: %b, done: %b, tl1.ob_out_entry_valid = %b, tl1.ser_done = %b, dram_addr = %h, tl1.ob_cpp_base_addr = %h, ob_out_entry = %h, data_to_dram = %h, tl1.sa.state = %b, tl1.sa.vs_en = %b, draw_rdwr = %b, dram.state2 = %b, dram_en_int = %b, data_from_dram=%h, fetch_out_entry=%h, fetch_out_valid=%b, dram_valid=%b", $time, dram_en, done, tl1.ob_out_entry_valid, tl1.ser_done, dram_addr, tl1.ob_cpp_base_addr, tl1.ob_out_entry, data_to_dram, tl1.sa.state, tl1.sa.vs_en, dram_rdwr, dram.state2, dram.en_int, data_from_dram, tl1.fetch_out_entry, tl1.fetch_out_valid, dram_valid);
/*
	reset = 1;
	@(negedge clk);
	reset = 0;

	$readmemh("simple_proto/simple_obj.mem", dram.mem, 64'h100);
	$readmemh("simple_proto/sim.table", dram.mem);

	for (int i = 64'h100; i <= 64'h130; i = i + 1)
		$display("mem[%h] = %h", i, dram.mem[i]);

	for (int i = 64'h0; i <= 64'h30; i = i + 1)
		$display("mem[%h] = %h", i, dram.mem[i]);

	@(negedge clk);

	en = 1;

	@(negedge clk);
	@(negedge clk);
	@(negedge clk);
	@(negedge clk);
	while (~done) @(negedge clk);
	@(negedge clk);


	for (int i = 64'h300; i >= 64'h2f0; i = i - 1)
		$display("mem[%h] = %h", i, dram.mem[i]);


	reset = 1;
    en = 0;
	@(negedge clk);
	reset = 0;
	@(negedge clk);
	@(negedge clk);

	$readmemh("tests/test1/cpp_obj.mem", dram.mem, 64'h100);
	$readmemh("tests/test1/table1.mem", dram.mem);

    dram.mem[64'h200] = 8'hdd;
    dram.mem[64'h201] = 8'hdd;
    dram.mem[64'h202] = 8'hdd;
    dram.mem[64'h203] = 8'hdd;
    dram.mem[64'h204] = 8'hdd;
    dram.mem[64'h205] = 8'hdd;
    dram.mem[64'h206] = 8'hdd;
    dram.mem[64'h207] = 8'hdd;
    dram.mem[64'h208] = 8'h52;
    dram.mem[64'h209] = 8'h6f;
    dram.mem[64'h20A] = 8'h68;
    dram.mem[64'h20B] = 8'h61;
    dram.mem[64'h20C] = 8'h6e;

	for (int i = 64'h200; i <= 64'h20C; i = i + 1)
		$display("mem[%h] = %h", i, dram.mem[i]);

	for (int i = 64'h100; i <= 64'h130; i = i + 1)
		$display("mem[%h] = %h", i, dram.mem[i]);

	for (int i = 64'h0; i <= 64'h30; i = i + 1)
		$display("mem[%h] = %h", i, dram.mem[i]);

	@(negedge clk);
    en = 1;
	@(negedge clk);
	@(negedge clk);
	@(negedge clk);
	@(negedge clk);
	while (~done) @(negedge clk);
	@(negedge clk);

	for (int i = 64'h300; i >= 64'h2f0; i = i - 1)
		$display("mem[%h] = %h", i, dram.mem[i]);
*/

	reset = 1;
    en = 0;
	@(negedge clk);
	reset = 0;
	@(negedge clk);
	@(negedge clk);

	$readmemh("tests/test2/cpp_obj.mem", dram.mem, 64'h100);
	$readmemh("tests/test2/table1.mem", dram.mem);
	$readmemh("tests/test2/table2.mem", dram.mem,64'h80);

    dram.mem[64'h200] = 8'hdd;
    dram.mem[64'h201] = 8'hdd;
    dram.mem[64'h202] = 8'hdd;
    dram.mem[64'h203] = 8'hdd;
    dram.mem[64'h204] = 8'hdd;
    dram.mem[64'h205] = 8'hdd;
    dram.mem[64'h206] = 8'hdd;
    dram.mem[64'h207] = 8'hdd;
    dram.mem[64'h208] = 8'h52;
    dram.mem[64'h209] = 8'h6f;
    dram.mem[64'h20A] = 8'h68;
    dram.mem[64'h20B] = 8'h61;
    dram.mem[64'h20C] = 8'h6e;


	for (int i = 64'h0; i <= 64'h30; i = i + 1)
		$display("mem[%h] = %h", i, dram.mem[i]);
    $display("=======================");
	for (int i = 64'h80; i <= 64'h100; i = i + 1)
		$display("mem[%h] = %h", i, dram.mem[i]);
    $display("=======================");
	for (int i = 64'h100; i <= 64'h130; i = i + 1)
		$display("mem[%h] = %h", i, dram.mem[i]);
    $display("=======================");
	for (int i = 64'h200; i <= 64'h20C; i = i + 1)
		$display("mem[%h] = %h", i, dram.mem[i]);
    $display("=======================");

	@(negedge clk);
    en = 1;
	@(negedge clk);
	@(negedge clk);
	@(negedge clk);
	@(negedge clk);

    for (int i = 0; i<200; i+=1)
    begin
        if (i > 100 && i < 120)
        begin
            print_ob();
            print_ob_stack();
        end
        @(negedge clk);
    end
	while (~done) 
    begin
        @(negedge clk);
    end
	@(negedge clk);
    print_ob();
    print_ob_stack();
	for (int i = 64'h300; i >= 64'h2e0; i = i - 1)
		$display("mem[%h] = %h", i, dram.mem[i]);
	$finish;
	end

endmodule
