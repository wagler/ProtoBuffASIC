module top_varint_tb;

	logic [63:0] value;
	logic [28:0] field_id;
	logic [4:0] field_type;
	logic [119:0] out_port;

	top_varint tv1(
			.value(value),
			.field_id(field_id),
			.field_type(field_type),
			.out_port(out_port)
	);

	initial
	begin

		$monitor("@%g value = %d \t field_id = %d \t field_type = %d \t out_port = %h", $time, value, field_id, field_type, out_port);

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

		$finish;

	end


endmodule;
