module zigzag_tb;

	logic en;
	logic [63:0] in_val;
	logic is_32;
	logic [63:0] out_val;

	zigzag z1(
		.en(en),
		.in_val(in_val),
		.is_32(is_32),
		.out_val(out_val)
	);

	initial
	begin

		$monitor("@%g en=%b \t in_val=%d \t is_32=%b \t out_val=%h", $time, en, in_val, is_32, out_val);

		en = 1'b1;
		in_val = 2;
		is_32 = 1'b1;

		#20

		en = 1'b1;
		in_val = 2;
		is_32 = 1'b0;

		#20

		en = 1'b1;
		in_val = -2;
		is_32 = 1'b1;

		#20

		en = 1'b1;
		in_val = -2;
		is_32 = 1'b0;

		#20

		$finish;

	end

endmodule
