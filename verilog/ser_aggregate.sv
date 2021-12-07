`define STACK_ROWS 16

module ser_aggregate(clk, reset, en, addr, entry, entry_valid, done, ready, dram_en, dram_rdwr, dram_data_in, dram_addr, dram_data_out, dram_valid);

    input logic clk, reset, en;
    input logic [63:0] addr;
    input TABLE_ENTRY entry;
    input logic entry_valid;
    input logic [7:0][7:0] dram_data_in;
    input logic [7:0] dram_valid;

    output logic done, ready;
    output logic [7:0][7:0] dram_data_out;
    output logic [7:0][63:0] dram_addr;
    output logic [7:0] dram_en;
    output logic dram_rdwr;

    parameter [3:0] IDLE        = 4'b0000;
    parameter [3:0] LOAD_VALUE  = 4'b0001;
    parameter [3:0] DRAM_WAIT1  = 4'b0010;
    parameter [3:0] RUN_SER     = 4'b0011;
    parameter [3:0] WRITE_FH    = 4'b0100;
    parameter [3:0] DRAM_WAIT2  = 4'b0101;
    parameter [3:0] DONE        = 4'b0110;
    parameter [3:0] PUSH        = 4'b0111;
    parameter [3:0] SIZE        = 4'b1000; 
    parameter [3:0] DRAM_WAIT3  = 4'b1001;

    logic [3:0] state, next_state;
    logic [4:0] cnt, next_cnt;
    logic next_done, next_ready;

    // Next DRAM port values
    logic [7:0][7:0]    next_dram_data_out;
    logic [7:0][63:0]   next_dram_addr;
    logic [7:0]         next_dram_en;
    logic               next_dram_rdwr;


    TABLE_ENTRY entry_intrnl;
    STACK_ENTRY [`STACK_ROWS-1:0] entry_stack, next_entry_stack;
    logic [$clog2(`STACK_ROWS)-1:0] entry_stack_ptr, next_entry_stack_ptr;// Changed from STACK_ENTRY to logic

    // The address of the next byte to write to in the output buffer
    logic [63:0] write_point, next_write_point;
    
    // Wire for the output from the field header module
    logic [39:0] field_header,field_header2;

    // The value that we give to the varint serializer, or the start addr for the memcpy
    logic [63:0] loaded_value, next_loaded_value;

    // Memcpy module lines
    logic memcpy_en, next_memcpy_en, memcpy_done;
    logic [63:0]         memcpy_src, next_memcpy_src;
    logic [7:0]          memcpy_dram_en;
    logic                memcpy_dram_rdwr;
    logic [7:0][63:0]    memcpy_dram_addr;
    logic [7:0][7:0]     memcpy_dram_data_out;

    // Varint serializer module lines
    logic vs_en, next_vs_en;
    logic [7:0]         vs_dram_en;
    logic [7:0][63:0]   vs_dram_addr;
    logic [7:0][7:0]    vs_dram_data;
    logic               vs_dram_rdwr;
    logic               vs_done;
    logic [3:0]         vs_bytes_written;

    // Serialization modules
    field_header fh(
       .field_id(entry_intrnl.field_id),
       .field_type(entry_intrnl.field_type),
       .out_port(field_header) 
    );

    field_header fh2(
       .field_id(entry_stack[entry_stack_ptr].field_id),
       .field_type(5'd11),
       .out_port(field_header2) 
    );

    top_varint vs(
        .clk(clk),
        .reset(reset),
        .en(vs_en),
        .dst_addr(write_point),
        .value(loaded_value),
        .field_type(entry_intrnl.field_type),
        .dram_en(vs_dram_en),
        .dram_addr(vs_dram_addr),
        .dram_data(vs_dram_data),
        .dram_rdwr(vs_dram_rdwr),
        .done(vs_done),
        .bytes_written(vs_bytes_written)
    );

    memcpy mc(
        .clk(clk),
        .reset(reset),
        .en(memcpy_en),
        .src(memcpy_src),
        .dst(write_point - entry_intrnl.size + 1),
        .size(entry_intrnl.size),
        .done(memcpy_done),
        .dram_en(memcpy_dram_en),
        .dram_rdwr(memcpy_dram_rdwr),
        .dram_addr(memcpy_dram_addr),
        .dram_data_in(dram_data_in),
        .dram_data_out(memcpy_dram_data_out),
        .dram_valid(dram_valid)
    );

    always_comb
    begin
        next_done = done;
        next_ready = ready;
        next_dram_en = dram_en;
        next_dram_data_out = dram_data_out;
        next_dram_addr = dram_addr;
        next_dram_rdwr = dram_rdwr;
        next_entry_stack = entry_stack;
        next_entry_stack_ptr = entry_stack_ptr;
        next_write_point = write_point;
        next_loaded_value = loaded_value;
        next_cnt = cnt;
        next_state = state;
        next_vs_en = vs_en;
        next_memcpy_en = memcpy_en;
        next_memcpy_src = memcpy_src;

        case(state)
            IDLE:
                begin
                    next_ready = 1;
                    next_done = 0;
                    $display("entry: %h", entry);
                    $display("field_id: %d", entry.field_id);
                    // If the current entry isn't a nested object header or footer
                    if (en & entry_valid & (entry.field_id != 0) & ~entry.nested)
                    begin
                        next_state = LOAD_VALUE;
                        next_ready = 0;
                        next_dram_en = 8'hFF;
                        next_dram_rdwr = 1'b1;
                        for(int i = 0; i < 8; i+=1)
                            next_dram_addr[i] = addr + i;
                    end
                    else if (en & entry_valid & (entry.field_id != 0) & entry.nested)
                    begin
						next_ready = 0;
                        next_state = PUSH;
                        next_entry_stack_ptr += entry_stack[entry_stack_ptr].valid;
                        next_entry_stack[next_entry_stack_ptr].valid = 1'b1;
                        next_entry_stack[next_entry_stack_ptr].field_id = entry.field_id;
                        next_entry_stack[next_entry_stack_ptr].saved_write_point = write_point;
                    end
                    else if (en & entry_valid & (entry.field_id == 0))
                    begin
						next_ready = 0;
                        next_state = SIZE;
                        next_vs_en = 1'b1;
                        next_loaded_value = (entry_stack[entry_stack_ptr].saved_write_point - write_point);
                    end
                end

            SIZE:
                begin
                    next_state = DRAM_WAIT3;
                end

            DRAM_WAIT3:
                begin
                    if (vs_done)
                    begin
                        next_state = WRITE_FH;

                        // Prepare for writing the field header
                        next_vs_en = 1'b0;
                        next_dram_en = 0;
                        next_write_point -= vs_bytes_written;

                        next_dram_rdwr = 1'b0;
                        if (entry_intrnl.field_id == 0) // nested types
                        begin 
                            next_dram_en[0] = |field_header2[7:0];
                            next_dram_en[1] = |field_header2[15:8];
                            next_dram_en[2] = |field_header2[23:16];
                            next_dram_en[3] = |field_header2[31:24];
                            next_dram_en[4] = |field_header2[39:32];
                            
                            next_dram_data_out[0] = field_header2[7:0];
                            next_dram_data_out[1] = field_header2[15:8];
                            next_dram_data_out[2] = field_header2[23:16];
                            next_dram_data_out[3] = field_header2[31:24];
                            next_dram_data_out[4] = field_header2[39:32];
                        end
                        else // non nested types
                        begin
                            next_dram_en[0] = |field_header[7:0];
                            next_dram_en[1] = |field_header[15:8];
                            next_dram_en[2] = |field_header[23:16];
                            next_dram_en[3] = |field_header[31:24];
                            next_dram_en[4] = |field_header[39:32];
                            
                            next_dram_data_out[0] = field_header[7:0];
                            next_dram_data_out[1] = field_header[15:8];
                            next_dram_data_out[2] = field_header[23:16];
                            next_dram_data_out[3] = field_header[31:24];
                            next_dram_data_out[4] = field_header[39:32];
                        end
                        
                        next_dram_addr[4] = next_write_point;
                        next_write_point -= next_dram_en[4];
                        next_dram_addr[3] = next_write_point;
                        next_write_point -= next_dram_en[3];
                        next_dram_addr[2] = next_write_point;
                        next_write_point -= next_dram_en[2];
                        next_dram_addr[1] = next_write_point;
                        next_write_point -= next_dram_en[1];
                        next_dram_addr[0] = next_write_point;
                        next_write_point -= next_dram_en[0];
                    end
                    else
                    begin
                        next_state = DRAM_WAIT3;
                        next_dram_en = 0;
                        next_dram_addr = 'hx;
                        next_dram_data_out = 'hx;
                        next_dram_rdwr = 0;
                        next_dram_en = vs_dram_en;
                        next_dram_addr = vs_dram_addr;
                        next_dram_data_out = vs_dram_data;
                        next_dram_rdwr = vs_dram_rdwr;
                    end
                end

            PUSH:
                begin
                    next_state = DONE;
                    next_done = 1'b1;;
                end
            LOAD_VALUE:
                begin
                    next_state = DRAM_WAIT1;
                    next_dram_en = 0;
                end
            DRAM_WAIT1:
                begin
                    // If the value has been loaded which we'll serialize, then setup the serializers
                    if (dram_valid)
                    begin
                        next_state = RUN_SER; 
                        next_memcpy_en = 0;
                        next_vs_en = 0;
                        next_dram_en = 0;
                        $display("FIELD TYPE!!!!!: %d", entry_intrnl.field_type);
                        case(entry_intrnl.field_type)
                            // Varints
                            5'd1, 5'd2, 5'd3, 5'd4, 5'd5, 5'd8, 5'd13, 5'd14, 5'd15, 5'd16, 5'd17, 5'd18:
                                begin
                                    next_vs_en = 1'b1;
                                    next_loaded_value = dram_data_in;
                                end

                            // Memcpy
                            5'd6, 6'd7, 5'd9, 5'd12, 5'd15, 5'd16:
                                begin
                                    next_memcpy_en = 1'b1;
                                    // If the entry is a string or bytes, then the actual src ptr is 8 bytes after the string/byte object starts
                                    if (entry_intrnl.field_type == 5'd9 || entry_intrnl.field_type == 5'd12)
                                        next_memcpy_src = dram_data_in + 8;
                                    else
                                        next_memcpy_src = dram_data_in;
                                end
                        endcase
                    end
                    else
                        next_state = DRAM_WAIT1;
                end
            RUN_SER:
                begin
                    if (vs_done | memcpy_done)
                    begin
                        next_vs_en = 1'b0;
                        next_memcpy_en = 1'b0;
                        next_dram_en = 0;
                        if (vs_done)
                        begin
                            next_state = WRITE_FH;
                            next_write_point -= vs_bytes_written;
                            next_dram_rdwr = 1'b0;
                            
                            next_dram_en[0] = |field_header[7:0];
                            next_dram_en[1] = |field_header[15:8];
                            next_dram_en[2] = |field_header[23:16];
                            next_dram_en[3] = |field_header[31:24];
                            next_dram_en[4] = |field_header[39:32];
                            
                            next_dram_data_out[0] = field_header[7:0];
                            next_dram_data_out[1] = field_header[15:8];
                            next_dram_data_out[2] = field_header[23:16];
                            next_dram_data_out[3] = field_header[31:24];
                            next_dram_data_out[4] = field_header[39:32];
                            
                            next_dram_addr[4] = next_write_point;
                            next_write_point -= next_dram_en[4];
                            next_dram_addr[3] = next_write_point;
                            next_write_point -= next_dram_en[3];
                            next_dram_addr[2] = next_write_point;
                            next_write_point -= next_dram_en[2];
                            next_dram_addr[1] = next_write_point;
                            next_write_point -= next_dram_en[1];
                            next_dram_addr[0] = next_write_point;
                            next_write_point -= next_dram_en[0];
                        end
                        else
                        begin
                            next_state = SIZE;
                            next_vs_en = 1'b1;
                            next_loaded_value = entry_intrnl.size;
                            next_write_point -= entry_intrnl.size;
                        end


                    end
                    else
                    begin
                        next_dram_en = 0;
                        next_dram_addr = 'hx;
                        next_dram_data_out = 'hx;
                        next_dram_rdwr = 0;
                        case(entry_intrnl.field_type)
                            // Varints
                            5'd1, 5'd2, 5'd3, 5'd4, 5'd5, 5'd8, 5'd13, 5'd14, 5'd15, 5'd16, 5'd17, 5'd18:
                                begin
                                    next_dram_en = vs_dram_en;
                                    next_dram_addr = vs_dram_addr;
                                    next_dram_data_out = vs_dram_data;
                                    next_dram_rdwr = vs_dram_rdwr;
                                end

                            // Memcpy
                            5'd6, 6'd7, 5'd9, 5'd12, 5'd15, 5'd16:
                                begin
                                    next_dram_en = memcpy_dram_en;
                                    next_dram_addr = memcpy_dram_addr;
                                    next_dram_rdwr = memcpy_dram_rdwr;
                                    next_dram_data_out = memcpy_dram_data_out;
                                end
                        endcase
                        next_state = RUN_SER;
                    end
                end
            WRITE_FH:
                begin
                    next_state = DRAM_WAIT2;
                    next_cnt = 0;
                    next_dram_en = 0;
                end
            DRAM_WAIT2:
                begin
                    next_dram_en = 0;
                    if (cnt != 21)
                    begin
                        next_cnt = cnt + 1;
                        next_state = DRAM_WAIT2;
                    end
                    else
                    begin
                        next_state = DONE;
                        next_done = 1'b1;
						if (entry_intrnl.field_id == 0)
						begin
								next_entry_stack[entry_stack_ptr].valid = 1'b0;
								if (entry_stack_ptr != 0) // not a latch, because we set a default at the top
									next_entry_stack_ptr = entry_stack_ptr - 1;
						end
                    end
                end
            DONE:
                begin
                    next_state = IDLE;
                    next_done = 1'b0;
                end
            default:
                next_state = IDLE;
        endcase
    end

    always_ff @(posedge clk)
    begin
        if (reset)
        begin
            done            <= #1 0;
            ready           <= #1 1;
            dram_en         <= #1 0;
            dram_data_out   <= #1 0;
            dram_addr       <= #1 0;
            dram_rdwr       <= #1 0;
            entry_intrnl    <= #1 0;
            entry_stack     <= #1 0;
            entry_stack_ptr <= #1 0;
            write_point     <= #1 64'h300;
            loaded_value    <= #1 0;
            cnt             <= #1 0;
            state           <= #1 IDLE;
            vs_en           <= #1 0;
            memcpy_en       <= #1 0;
            memcpy_src      <= #1 0;
        end
        else
        begin
            done            <= #1 next_done;
            ready           <= #1 next_ready;
            dram_data_out   <= #1 next_dram_data_out;
            dram_addr       <= #1 next_dram_addr;
            dram_en         <= #1 next_dram_en;
            dram_rdwr       <= #1 next_dram_rdwr;
            entry_stack     <= #1 next_entry_stack;
            entry_stack_ptr <= #1 next_entry_stack_ptr;
            write_point     <= #1 next_write_point;
            loaded_value    <= #1 next_loaded_value;
            cnt             <= #1 next_cnt;
            state           <= #1 next_state;
            vs_en           <= #1 next_vs_en;
            memcpy_en       <= #1 next_memcpy_en;
            memcpy_src      <= #1 next_memcpy_src;
            if (entry_valid)
                entry_intrnl <= #1 entry;
        end
    end

endmodule
