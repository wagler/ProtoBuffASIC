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

        $monitor("@%g en =%b, state=%b, dram_state=%b, dram_en=%b, dram_valid=%b, dram_rdwr=%b, dram_addr=%h, data_from_dram=%h, data_to_dram=%h, vs_en=%b, mc_en=%b, vs_done=%b, entry_valid=%b, ready=%b, entry_intrnl=%h", $time, en, sa.state, dram.state, dram_en, dram_valid, dram_rdwr, dram_addr, dram_data_in, dram_data_out, sa.vs_en, sa.memcpy_en, sa.vs_done, entry_valid, ready,sa.entry_intrnl);

        reset = 1;
        en = 0;
		entry_valid = 0;
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
            //$display("mem[%h] = %h", i, dram.mem[i]);
        addr = 4;
        entry = {dram.mem['h17],dram.mem['h16],dram.mem['h15],dram.mem['h14],dram.mem['h13],dram.mem['h12],dram.mem['h11],dram.mem['h10], 64'hx};

        entry_valid = 1;
        en = 1;
        @(negedge clk);
        while (~done) @(negedge clk);
        entry_valid = 0;
        en = 0;
        @(negedge clk);
        @(negedge clk);

        for (int i = 64'h300; i >= 64'h2E0; i-=1)
            //$display("mem[%h] = %h", i, dram.mem[i]);


        // String test case
        // C++ char buffer that string points to
        for (int i = 23; i < 31; i+=1)
        begin
            dram.mem[i] = 8'd0;
        end
        dram.mem[31] = 8'hde;
        dram.mem[32] = 8'had;
        dram.mem[33] = 8'hbe;
        dram.mem[34] = 8'hef;

        // c++ string object starts at 0
        // but the pointer is 8 bytes inside
        dram.mem[8] = 8'b00010111;
        dram.mem[9] = 8'd0;
        dram.mem[10] = 8'd0;
        dram.mem[11] = 8'd0;
        dram.mem[12] = 8'd0;
        dram.mem[13] = 8'd0;
        dram.mem[14] = 8'd0;
        dram.mem[15] = 8'd0;

        $display("mem after setting 8");
        for (int i = 64'h0; i <= 64'hf; i+=1)
            $display("mem[%h] = %h", i, dram.mem[i]);
        addr = 8;

        dram.mem[36] = 8'h08;
        dram.mem[37] = 8'h00;
        dram.mem[38] = 8'h00;
        dram.mem[39] = 8'h40;
        dram.mem[40] = 8'h12;
        dram.mem[41] = 8'h00;
        dram.mem[42] = 8'h00;
        dram.mem[43] = 8'h00;

        entry_valid = 0;

        entry_valid = 1;
        entry = {dram.mem['d43],dram.mem['d42],dram.mem['d41],dram.mem['d40],dram.mem['d39],dram.mem['d38],dram.mem['d37],dram.mem['d36], 64'hx};

        for (int i = 64'd0; i <= 64'd43; i+=1)
            $display("mem[%h] = %h", i, dram.mem[i]);

        $display("Next write location: %h", sa.write_point);
        @(negedge clk);
        en = 1;
        @(negedge clk);
        while (~done) @(negedge clk);

        for (int i = 64'h300; i >= 64'h2E0; i-=1)
            $display("mem[%h] = %h", i, dram.mem[i]);

		// Nested test
		//

		$display("======== STARTING NESTED CASE ========");

        for (int i = 64'h10; i >= 64'h1; i-=1)
            $display("mem[%h] = %h", i, dram.mem[i]);
	    $display("mem[%h] = %h", 0, dram.mem[0]);

		for (int j = 0; j < 10; j++)
		begin
			@(negedge clk);
			reset = 1;
			en = 0;
			entry_valid = 0;
		end

		@(negedge clk);

		reset = 0;

		entry = {64'h0000001340080101, 64'h0000000000000100};
		entry_valid = 1;
		en = 1;

        while (~done) @(negedge clk);
		$display("entry_stack_ptr: %h", sa.entry_stack_ptr);
		$display("Entry_stack[entry_stack_ptr].valid: %h", sa.entry_stack[sa.entry_stack_ptr].valid);
		$display("Entry_stack[entry_stack_ptr]: %h", sa.entry_stack[sa.entry_stack_ptr]);
		en = 0;
		@(negedge clk);


		entry = {64'h0000000940080008, 64'hxxxxxxxxxxxxxxxx};

		en = 1;

        while (~done) @(negedge clk);
		$display("entry_stack_ptr: %h", sa.entry_stack_ptr);
		$display("Entry_stack[entry_stack_ptr].valid: %h", sa.entry_stack[sa.entry_stack_ptr].valid);
		$display("Entry_stack[entry_stack_ptr]: %h", sa.entry_stack[sa.entry_stack_ptr]);

		en = 0;
		@(negedge clk);

		entry = {64'h0000000000000000, 64'hxxxxxxxxxxxxxxxx};

		en = 1;

        while (~done) @(negedge clk);
		$display("entry_stack_ptr: %h", sa.entry_stack_ptr);
		$display("Entry_stack[entry_stack_ptr].valid: %h", sa.entry_stack[sa.entry_stack_ptr].valid);
		$display("Entry_stack[entry_stack_ptr]: %h", sa.entry_stack[sa.entry_stack_ptr]);
		
		en = 0;
		@(negedge clk);

        for (int i = 64'h300; i >= 64'h2E0; i-=1)
            $display("mem[%h] = %h", i, dram.mem[i]);
	/*	
		08 00 08 40 09 00 00 00 
		00 00 00 00 00 00 00 00 
		00 00 00 00 00 00 00 00 
		*/

		$display("========                        ========");
		 
		$display("======== STARTING NESTED CASE 2 ========");

		$display("========                        ========");
		for (int j = 0; j < 10; j++)

		begin
			@(negedge clk);
			reset = 1;
			en = 0;
			entry_valid = 0;
		end

		@(negedge clk);
		reset = 0;

        for (int i = 64'h0; i <= 64'h300; i+=1)
            dram.mem[i] = 8'h0;

		dram.mem[0] = 8'd150;

        for (int i = 64'h0; i <= 64'h20; i+=1)
            $display("mem[%h] = %h", i, dram.mem[i]);

        for (int i = 64'h2f0; i <= 64'h300; i+=1)
            $display("mem[%h] = %h", i, dram.mem[i]);

		addr = 0;


		entry = {64'h0000001340080101, 64'h0000000000000100};
		entry_valid = 1;
		en = 1;

        while (~done) @(negedge clk);
		$display("entry_stack_ptr: %h", sa.entry_stack_ptr);
		$display("Entry_stack[entry_stack_ptr].valid: %h", sa.entry_stack[sa.entry_stack_ptr].valid);
		$display("Entry_stack[entry_stack_ptr]: %h", sa.entry_stack[sa.entry_stack_ptr]);
		en = 0;
		@(negedge clk);


		entry = {64'h0000000940080008, 64'hxxxxxxxxxxxxxxxx};

		en = 1;

        while (~done) @(negedge clk);
		$display("entry_stack_ptr: %h", sa.entry_stack_ptr);
		$display("Entry_stack[entry_stack_ptr].valid: %h", sa.entry_stack[sa.entry_stack_ptr].valid);
		$display("Entry_stack[entry_stack_ptr]: %h", sa.entry_stack[sa.entry_stack_ptr]);

		en = 0;
		@(negedge clk);



		entry = {64'h0000001340080101, 64'h0000000000000200};
		entry_valid = 1;
		en = 1;

        while (~done) @(negedge clk);
		$display("entry_stack_ptr: %h", sa.entry_stack_ptr);
		$display("Entry_stack[entry_stack_ptr].valid: %h", sa.entry_stack[sa.entry_stack_ptr].valid);
		$display("Entry_stack[entry_stack_ptr]: %h", sa.entry_stack[sa.entry_stack_ptr]);
		en = 0;
		@(negedge clk);


		entry = {64'h0000000940080008, 64'hxxxxxxxxxxxxxxxx};

		en = 1;

        while (~done) @(negedge clk);
		$display("entry_stack_ptr: %h", sa.entry_stack_ptr);
		$display("Entry_stack[entry_stack_ptr].valid: %h", sa.entry_stack[sa.entry_stack_ptr].valid);
		$display("Entry_stack[entry_stack_ptr]: %h", sa.entry_stack[sa.entry_stack_ptr]);

		en = 0;
		@(negedge clk);



		entry = {64'h0000000000000000, 64'hxxxxxxxxxxxxxxxx};

		en = 1;

        while (~done) @(negedge clk);
		$display("entry_stack_ptr: %h", sa.entry_stack_ptr);
		$display("Entry_stack[entry_stack_ptr].valid: %h", sa.entry_stack[sa.entry_stack_ptr].valid);
		$display("Entry_stack[entry_stack_ptr]: %h", sa.entry_stack[sa.entry_stack_ptr]);
		
		en = 0;
		@(negedge clk);




		entry = {64'h0000000000000000, 64'hxxxxxxxxxxxxxxxx};

		en = 1;

        while (~done) @(negedge clk);
		$display("entry_stack_ptr: %h", sa.entry_stack_ptr);
		$display("Entry_stack[entry_stack_ptr].valid: %h", sa.entry_stack[sa.entry_stack_ptr].valid);
		$display("Entry_stack[entry_stack_ptr]: %h", sa.entry_stack[sa.entry_stack_ptr]);
		
		en = 0;
		@(negedge clk);


        for (int i = 64'h2f0; i <= 64'h300; i+=1)
            $display("mem[%h] = %h", i, dram.mem[i]);


        $display("done");
        $finish;
    end

endmodule
