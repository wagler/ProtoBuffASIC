module top_varint(value, field_type, out_port);

	input logic [63:0] value;
	input logic [4:0] field_type;
	output logic [79:0] out_port;

	wire zz_en;
	wire [63:0] varint_ser_input;
	wire is_32_input;
	wire [63:0] zz_output;

	assign zz_en = (field_type == 5'd17 || field_type == 5'd18) ? 1'b1 : 1'b0;
	assign is_32_input = field_type == 5'd17;

	zigzag z1(
			.en(zz_en),
			.in_val(value),
			.is_32(is_32_input),
			.out_val(zz_output)
	);

	assign varint_ser_input = zz_en ? zz_output : value;

	varint_ser vs1(
			.in_port(varint_ser_input),
			.out_port(out_port[79:0])
	);

endmodule
