module varint_ser_tb;
    parameter BYTE = 8;
    logic clk;

    logic [(8*BYTE)-1 : 0] in_port;
    logic [(10*BYTE)-1 : 0] out_port;

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

    initial
    begin
        $monitor("@%g input = %d output = %b",$time, in_port, out_port);
        in_port = 64'd150;
        #20;
        $finish;
    end
endmodule
