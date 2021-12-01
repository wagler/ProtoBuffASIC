`timescale 10ns/1ns
module top_level_tb;

	logic clk;
	logic reset;
	logic [63:0] value;
	logic [28:0] field_id;
	logic [4:0] field_type;
	logic [1:0][119:0] out_port;

    initial
    begin
        clk = 0;
    end

    always
        #1 clk = !clk;

	top_level tl1(
			.clk(clk),
			.reset(reset),
			.value(value),
			.field_id(field_id),
			.field_type(field_type),
			.out_port(out_port)
	);

	initial
	begin

		$monitor("@%g value = %d \t field_id = %d \t field_type = %d \t out_port = %h", $time, value, field_id, field_type, out_port);

		@(negedge clk)
		reset = 1;
		@(negedge clk)
		reset = 0;	
		@(negedge clk)

		value = 64'd150;
		field_id = 29'd1;
		field_type = 5'd5;

		@(negedge clk)

		value = -2;
		field_id = 29'd2;
		field_type = 5'd18;

		@(negedge clk)

/*
		value = 64'd150;
		field_id = 29'd1;
		field_type = 5'd5;

		#20

		value = -2;
		field_id = 29'd2;
		field_type = 5'd18;

		#20

		value = -2;
		field_id = 29'd2;
		field_type = 5'd5;

		#20

		value = 2;
		field_id = 29'd2;
		field_type = 5'd18;

		#20

*/

		$finish;

	end


endmodule;
