`timescale 10ns/1ns
module top_level(

   	input clk,
	input reset,
    input en,

    input logic [15:0]       dram_valid,
    input logic  [15:0][7:0]  data_from_dram,
    output logic [15:0]       dram_en,
    output logic [1:0]			dram_rdwr,
    output logic [15:0][63:0] dram_addr,
    output logic  [15:0][7:0]  data_to_dram,
	output logic 				done

); 

	TABLE_ENTRY fetch_out_entry;
	logic fetch_out_valid;

	logic ob_full;
	logic [63:0] ob_cpp_base_addr;
	TABLE_ENTRY ob_out_entry;
	logic ob_out_entry_valid;

	logic ser_done, ser_ready;

    fetch f(
        .clk(clk),
        .reset(reset),
        .en(en),
        .new_addr(64'h0),
        .new_addr_valid(1'b0),
        .dram_valid(dram_valid[7:0]),
        .dram_data(data_from_dram[7:0]),
        .dram_en(dram_en[7:0]),
        .dram_rdwr(dram_rdwr[0]),
        .dram_addr(dram_addr[7:0]),
        .entry(fetch_out_entry),
        .ob_full(ob_full),
        .ob_valid(fetch_out_valid)
    );

    object_buffer ob(
        .clk(clk), 
        .reset(reset),
        .new_cpp_base_addr(64'h0),
        .new_cpp_base_addr_valid(1'b0),
        .new_entry(fetch_out_entry), 
        .valid_in(fetch_out_valid), 
        .full(ob_full),
        .ser_ready(ser_ready),
        .ser_done(ser_done),
        .out_entry(ob_out_entry),
        .out_entry_valid(ob_out_entry_valid),
        .cpp_base_addr(ob_cpp_base_addr),
		.done(done)
    );

    ser_aggregate sa
    (
        .clk(clk), 
        .reset(reset), 
        .en(en), 
        .addr(ob_cpp_base_addr + ob_out_entry.offset), 
        .entry(ob_out_entry), 
        .entry_valid(ob_out_entry_valid), 
        .done(ser_done), 
        .ready(ser_ready), 
        .dram_en(dram_en[15:8]), 
        .dram_rdwr(dram_rdwr[1]), 
        .dram_data_in(data_from_dram[15:8]), 
        .dram_addr(dram_addr[15:8]), 
        .dram_data_out(data_to_dram[15:8]), 
        .dram_valid(dram_valid[15:8])
    );

endmodule
