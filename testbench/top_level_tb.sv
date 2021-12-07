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
        .rdwr(rdwr),
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


	initial
	begin

	reset = 1;
	@(negedge clk);
	reset = 0;

	$finish;
	end

endmodule
