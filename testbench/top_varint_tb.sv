module top_varint_tb;

    logic clk, reset, en;

	logic [63:0] value;
	logic [4:0] field_type;
    logic [63:0] dst_addr;

    logic [7:0] dram_en;
    logic [7:0][63:0] dram_addr;
    logic dram_rdwr;
    logic [7:0][7:0] dram_data;
    logic done;
    logic [3:0] bytes_written;

    DRAM ram(
        .clk(clk),
        .reset(reset),
        .en({{8{1'b0}},dram_en}),
        .rdwr({1'b0,dram_rdwr}),
        .data_in({{8{8'd0}},dram_data}),
        .addr({{8{64'd0}},dram_addr}),
        .data_out(),
        .valid()
    );

	top_varint tv1(
        .clk(clk),
        .reset(reset),
        .en(en),
        .dst_addr(dst_addr),
        .value(value),
        .field_type(field_type),
        .dram_en(dram_en),
        .dram_addr(dram_addr),
        .dram_data(dram_data),
        .dram_rdwr(dram_rdwr),
        .done(done),
        .bytes_written(bytes_written)
	);

    initial
    begin
        clk = 0;
    end

    always
        #1 clk = !clk;

	initial
	begin

        $monitor("@%g reset=%b, en=%b, field_type=%d, dst_addr=%h, dram_en=%b, dram_addr=%h, dram_rdwr=%b, dram_data=%h, done=%b, waiting=%b, second=%b, varint_out=%h, bytes_written=%d", $time, reset, en, field_type, dst_addr, dram_en, dram_addr, dram_rdwr, dram_data, done, tv1.waiting, tv1.second, tv1.vsout, bytes_written);

        reset = 1;
        en = 0;
        @(negedge clk);
        reset = 0;
        value = 64'd150;
        field_type = 5'd5;
        dst_addr = 64'h100;
        en = 1;
        @(negedge clk);
        while (~done) @(negedge clk);
		$finish;

	end


endmodule;
