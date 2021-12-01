`define BYTE 8
module varint_ser_tb;
    logic clk;

    logic [(8*`BYTE)-1 : 0] in_port;
    logic [(10*`BYTE)-1 : 0] out_port;

    varint_ser vs0 (
        .in_port(in_port),
        .out_port(out_port)
    );

    logic [28:0] field_id_in;
    logic [4:0] field_type_in;
    logic [39:0] fh_out_port;

    field_header fh (
        .field_id(field_id_in),
        .field_type(field_type_in),
        .out_port(fh_out_port)
    );

    initial
    begin
        clk = 0;
    end

    always
        #5 clk = !clk;

    //int array1 [int];
    reg [7:0] array1 [0:63]; 
    initial
    begin
        $display("Loading file into ram");
        $readmemh("simple_obj.mem", array1);
        $display("array1 = %p", array1);
        $monitor("@%g input = %d output = %b",$time, in_port, out_port);
        in_port = 64'd150;
        #20;

        $monitor("@%g field id=%d \t field type=%d, output=%b",$time, field_id_in, field_type_in, fh_out_port);

        field_id_in = 0;
        field_type_in = 0;

        #1 

        field_id_in = 29'd150;
        field_type_in = 5'd3;

        #20

        field_id_in = 29'd150;
        field_type_in = 5'd1;

        #20
        $finish;
    end
endmodule
