module fetch_tb;

    logic clk, reset;
    FETCH_PORT port(clk, reset);
    fetch f(port);

endmodule
