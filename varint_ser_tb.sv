`define BYTE 8
module varint_ser_tb;
    logic clk;

    logic [(8*`BYTE)-1 : 0] in_port;
    logic [(10*`BYTE)-1 : 0] out_port;

    varint_ser vs0 (
        .in_port(in_port),
        .out_port(out_port)
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
        $readmemh("raw_obj.bin", array1);
        $display("array1 = %p", array1);
        $monitor("@%g input = %d output = %b",$time, in_port, out_port);
        in_port = 64'd150;
        #20;
        $finish;
    end
endmodule
