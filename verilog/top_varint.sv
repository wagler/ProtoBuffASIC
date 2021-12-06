module top_varint(clk, reset, en, dst_addr, value, field_type, dram_en, dram_addr, dram_data, dram_rdwr, done, bytes_written);

    input logic clk, reset, en;
	input logic [63:0] value;
	input logic [4:0] field_type;
    input logic [63:0] dst_addr;

    output logic [7:0] dram_en;
    output logic [7:0][63:0] dram_addr;
    output logic dram_rdwr;
    output logic [7:0][7:0] dram_data;
    output logic done;
    output logic [3:0] bytes_written;

    logic next_done;

    logic [79:0] vsout, next_vsout;
    logic [79:0] out;
    logic second, next_second;
    logic [3:0] next_bytes_written;


    int j,k;
    logic [7:0] next_dram_en;
    logic [7:0][63:0] next_dram_addr;
    logic next_dram_rdwr;
    logic [7:0][7:0] next_dram_data;
    logic [4:0] cnt, next_cnt;
    logic waiting, next_waiting; 

	wire zz_en;
	wire [63:0] varint_ser_input;
	wire is_32_input;
	wire [63:0] zz_output;

	assign zz_en = (field_type == 5'd17 || field_type == 5'd18) ? 1'b1 : 1'b0;
	//assign is_32_input = field_type == 5'd17;
    assign is_32_input = (field_type == 5'd2) | (field_type == 5'd5) | (field_type == 5'd7) | (field_type == 5'd13) | (field_type == 5'd15) | (field_type == 5'd17);

	zigzag z1(
			.en(zz_en),
			.in_val(value),
			.is_32(is_32_input),
			.out_val(zz_output)
	);

    // Ensures we don't accidentally pickup leading 1's from accidental sign extension
	assign varint_ser_input = zz_en ? zz_output : (is_32_input ? (64'h00_00_00_00_ff_ff_ff_ff & value) : value);

	varint_ser vs1(
			.in_port(varint_ser_input),
			.out_port(out)
	);

    always_comb
    begin
        next_dram_en = dram_en;
        next_dram_addr = dram_addr;
        next_dram_rdwr = dram_rdwr;
        next_dram_data = dram_data;
        next_vsout = vsout;
        next_cnt = cnt;
        next_waiting = waiting;
        next_second = second;
        next_done = 0;
        next_bytes_written = bytes_written;
        j = 0;
        k = 0;
        
        if (en)
        begin
            next_vsout = out;
            if (~waiting & second)
            begin
                next_second = 0;

                next_dram_en[0] = |next_vsout[63:56];
                next_dram_addr[0] = dst_addr - next_bytes_written;
                next_bytes_written +=  next_dram_en[0];

                next_dram_en[1] = |next_vsout[55:48];
                next_dram_addr[1] = dst_addr - next_bytes_written;
                next_bytes_written +=  next_dram_en[1];

                next_dram_en[2] = |next_vsout[47:40];
                next_dram_addr[2] = dst_addr - next_bytes_written;
                next_bytes_written +=  next_dram_en[2];

                next_dram_en[3] = |next_vsout[39:32];
                next_dram_addr[3] = dst_addr - next_bytes_written;
                next_bytes_written +=  next_dram_en[3];

                next_dram_en[4] = |next_vsout[31:24];
                next_dram_addr[4] = dst_addr - next_bytes_written;
                next_bytes_written +=  next_dram_en[4];

                next_dram_en[5] = |next_vsout[23:16];
                next_dram_addr[5] = dst_addr - next_bytes_written;
                next_bytes_written +=  next_dram_en[5];

                next_dram_en[6] = |next_vsout[15:8];
                next_dram_addr[6] = dst_addr - next_bytes_written;
                next_bytes_written +=  next_dram_en[6];

                next_dram_en[7] = |next_vsout[7:0];
                next_dram_addr[7] = dst_addr - next_bytes_written;
                next_bytes_written +=  next_dram_en[7];

                next_dram_data[7] = next_vsout[7:0];
                next_dram_data[6] = next_vsout[15:8];
                next_dram_data[5] = next_vsout[23:16];
                next_dram_data[4] = next_vsout[31:24];
                next_dram_data[3] = next_vsout[39:32];
                next_dram_data[2] = next_vsout[47:40];
                next_dram_data[1] = next_vsout[55:48];
                next_dram_data[0] = next_vsout[63:56];

                //next_second = (|next_vsout[71:64]) | (|next_vsout[79:72]);
                next_waiting = |next_dram_en;
            end
            else if(~waiting & ~second)
            begin
                next_second = 1;
                next_waiting = 0;

                next_dram_addr = 0;
                next_dram_en = 0;

                next_dram_en[1] = |next_vsout[79:72];
                next_dram_addr[1] = dst_addr; // first thing written, so next_bytes_written is 0 here
                next_bytes_written +=  next_dram_en[1];

                next_dram_en[0] = |next_vsout[71:64];
                next_dram_addr[0] = dst_addr - next_bytes_written;
                next_bytes_written +=  next_dram_en[0];

                next_dram_data = 0;
                next_dram_data[1] = next_vsout[79:72];
                next_dram_data[0] = next_vsout[71:64];

                next_waiting = |next_dram_en;

            end
            else if (waiting & (cnt != 20))
            begin
                next_dram_en = 0;
                next_cnt = cnt + 1;
            end
            else // waiting for dram and cnt==20
            begin
                next_cnt = 0;
                next_waiting = 0;
                next_done = ~second;
                if (next_done)
                begin
                    $display("Varint serialization is done");
                    $display("serialized string: %h", out);
                    $display("bytes written: %d", next_bytes_written);
                end
            end
        end
        else
        begin
            next_cnt = 0;
            next_dram_en = 0;
            next_second = 0;
            next_bytes_written = 0;
        end
    end


    always_ff @(posedge clk)
    begin
        if(reset)
        begin
            dram_en      <= #1 0;
            dram_addr    <= #1 0;
            dram_rdwr    <= #1 0;
            dram_data    <= #1 0;
            vsout        <= #1 0;
            cnt          <= #1 0;
            second       <= #1 0;
            waiting      <= #1 0;
            done         <= #1 0;
            bytes_written<= #1 0;
        end 
        else
        begin
            dram_en      <= #1 next_dram_en;
            dram_addr    <= #1 next_dram_addr;
            dram_rdwr    <= #1 next_dram_rdwr;
            dram_data    <= #1 next_dram_data;
            vsout        <= #1 next_vsout;
            cnt          <= #1 next_cnt;
            second       <= #1 next_second;
            waiting      <= #1 next_waiting;
            done         <= #1 next_done;
            bytes_written<= #1 next_bytes_written;
        end
    end

endmodule
