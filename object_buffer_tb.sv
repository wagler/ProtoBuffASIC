module object_buffer_tb;
    logic clk;
    logic reset;
    TABLE_ENTRY new_entry;
    logic valid_in;
    wire full;
    
    object_buffer ob(
        .clk(clk), 
        .reset(reset), 
        .new_entry(new_entry), 
        .valid_in(valid_in), 
        .full(full)
    );

    initial
    begin
        clk = 0;
    end

    always
        #1 clk = !clk;

    /*
    initial
    begin
        $dumpfile("dram.vcd");
        $dumpvars;
    end
    */

    initial
    begin
        $monitor("@%g reset=%b, full=%b, valid_in=%b, new_entry=%h, curr=%d", $time, reset, full, valid_in, new_entry, ob.curr );
        reset = 1;
        @(negedge clk);
        @(negedge clk);
        reset = 0;
        new_entry = 128'h00_00_00_09_40_18_00_08_XX_XX_XX_XX_XX_XX_XX_XX;
        valid_in = 1;
        @(negedge clk);
        valid_in = 0;
        @(negedge clk);

        $finish;
    end
endmodule
