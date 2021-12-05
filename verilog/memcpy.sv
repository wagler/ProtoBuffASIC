module memcpy(clk, reset, en, src, dst, size, done, dram_en, dram_rdwr, dram_addr, dram_data_in, dram_data_out, dram_valid);

    input logic clk, reset, en;
    input logic [63:0] src, dst;
    input logic [14:0] size;
    input logic [7:0] dram_valid;
    input logic [7:0][7:0] dram_data_in;

    output logic done;
    output logic [7:0] dram_en;
    output logic dram_rdwr;
    output logic [7:0][63:0] dram_addr;
    output logic [7:0][7:0] dram_data_out;

    logic [4:0] cnt, next_cnt;
    logic [14:0] bytes_copied, next_bytes_copied;
    logic next_done;
    logic [7:0] next_dram_en;
    logic next_dram_rdwr;
    logic [7:0][63:0] next_dram_addr;
    logic [7:0][7:0] next_dram_data_out;

    logic [2:0] state, next_state;

    parameter [2:0] IDLE            = 3'd0;
    parameter [2:0] RD_DRAM_SETUP   = 3'd1;
    parameter [2:0] RD_DRAM_WAIT    = 3'd2;
    parameter [2:0] WR_DRAM_SETUP   = 3'd3;
    parameter [2:0] WR_DRAM_WAIT    = 3'd4;
    parameter [2:0] DONE            = 3'd5;

    always_comb
    begin
        next_state = state;
        next_done = done;
        next_dram_en = dram_en;
        next_dram_rdwr = dram_rdwr;
        next_dram_addr = dram_addr;
        next_dram_data_out = dram_data_out;
        next_cnt = cnt;
        next_bytes_copied = bytes_copied;

        case(state)
            IDLE:
                begin
                    next_done = 0;
                    next_bytes_copied = 0;
                    next_dram_en = 0;
                    if (en)
                    begin
                        next_state = RD_DRAM_SETUP;
                        next_dram_rdwr = 1'b1;
                        for (int i = 0; i < 8; i=i+1)
                        begin
                            next_dram_en[i] = (bytes_copied + i + 1) <= size;
                            next_dram_addr[i] = src + bytes_copied + i;
                        end
                    end
                end

            RD_DRAM_SETUP:
                begin
                    next_state = RD_DRAM_WAIT;
                    next_dram_en = 0;
                end

            RD_DRAM_WAIT:
                begin
                    if(dram_valid == 0)
                        next_state = RD_DRAM_WAIT;
                    else
                    begin
                        next_state = WR_DRAM_SETUP;
                        
                        next_dram_rdwr = 1'b0;
                        for (int i = 0; i < 8; i=i+1)
                        begin
                            next_dram_en[i] = (bytes_copied + i + 1) <= size;
                            next_dram_addr[i] = dst + bytes_copied + i;
                            next_bytes_copied += next_dram_en[i];
                            next_dram_data_out[i] = dram_data_in[i];
                        end
                    end
                end

            WR_DRAM_SETUP:
                begin
                    next_cnt = 0;
                    next_state = WR_DRAM_WAIT;
                    next_dram_en = 0;
                end

            WR_DRAM_WAIT:
                begin
                    if (cnt == 20 && (bytes_copied == size))
                    begin
                        next_state = DONE;
                        next_done = 1;
                    end
                    else if (cnt == 20 && (bytes_copied < size))
                    begin
                        next_state = RD_DRAM_SETUP;
                        next_dram_rdwr = 1'b1;
                        for (int i = 0; i < 8; i=i+1)
                        begin
                            next_dram_en[i] = (bytes_copied + i + 1) <= size;
                            next_dram_addr[i] = src + bytes_copied + i;
                        end
                    end
                    else
                    begin
                        next_state = WR_DRAM_WAIT;
                        next_cnt = cnt + 1;
                    end
                end

            DONE:
                begin
                    next_done = 0;
                    next_state = IDLE;
                end
        endcase
    end

    always_ff @(posedge clk)
    begin
        if(reset)
        begin
            state           <= #1 IDLE;
            done            <= #1 0;
            dram_en         <= #1 0;
            dram_rdwr       <= #1 0;
            dram_addr       <= #1 0;
            dram_data_out   <= #1 0; 
            cnt             <= #1 0;
            bytes_copied    <= #1 0;
        end
        else
        begin
            state           <= #1 next_state;
            done            <= #1 next_done;
            dram_en         <= #1 next_dram_en;
            dram_rdwr       <= #1 next_dram_rdwr;
            dram_addr       <= #1 next_dram_addr;
            dram_data_out   <= #1 next_dram_data_out;
            cnt             <= #1 next_cnt;
            bytes_copied    <= #1 next_bytes_copied;
        end
    end
endmodule
