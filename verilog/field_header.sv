module field_header(field_id, field_type, out_port);

    input logic [28:0] field_id;
    input logic [4:0] field_type;
    output logic [39:0] out_port;

    wire [79:0] ser_out;
    wire [63:0] extended_field_id;
    assign extended_field_id[63:29] = 'd0;
    assign extended_field_id[28:0] = field_id;

    varint_ser ser1(
        .in_port(extended_field_id),
        .out_port(ser_out)
    );

    always_comb
    begin
        out_port[39:3] = ser_out[36:0];

        case (field_type)
            5'd3, 5'd4, 5'd5, 5'd13, 5'd14, 5'd17, 5'd18 : out_port[2:0] = 3'd0; // wire type 0
            5'd1, 5'd6, 5'd16 : out_port[2:0] = 3'd1; // wire type 1
            5'd9, 5'd11, 5'd12 : out_port[2:0] = 3'd2; // wire type 2
            5'd2, 5'd7, 5'd15 : out_port[2:0] = 3'd5; // wire type 5
            default: out_port[2:0] = 3'd7; // invalid, to signal error
        endcase
    end

endmodule //field_header
