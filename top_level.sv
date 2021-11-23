module top_level(
    /*** APB3 BUS INTERFACE ***/
	/*
    input PCLK, 				// clock
    input PRESERN, 				// system reset
    input PSEL, 				// peripheral select
    input PENABLE, 				// distinguishes access phase
    output wire PREADY, 		// peripheral ready signal
    output wire PSLVERR,		// error signal
    input PWRITE,				// distinguishes read and write cycles
    input [31:0] PADDR,			// I/O address
    input wire [31:0] PWDATA,	// data from processor to I/O device (32 bits)
    output reg [31:0] PRDATA,	// data to processor from I/O device (32-bits)
	*/

   	input clk,
	input [63:0] value,
	input [4:0] field_type,
	input [28:0] field_id,
	output logic [119:0] out_port

    /*** I/O PORTS DECLARATION ***/	
); 

    // Probably want to change this for more informative interaction with CPU
	/*
    assign PSLVERR = 0;
    assign PREADY = 1;
	*/

    top_varint tv1(
		.value(value),
	  	.field_type(field_type),
	 	.out_port(out_port[119:40])       
	);

	field_header fh1(
		.field_id(field_id),
		.field_type(field_type),
		.out_port(out_port[39:0])
	);


endmodule
