`define WAIT_CYCLES 20
`define MEM_SIZE_BYTES 1024

// Put rdwr, data_in, and addr values on input lines
// Set en to high for at least one cycle
// rdwr is 1 when we want to read from dram and 0 when we want to write to dram
module DRAM(clk, reset, en, rdwr, data_in , addr, data_out, valid);

    input wire clk;
    input wire reset;
    input wire [15:0] en;
    input wire [1:0] rdwr;
    input wire [15:0][7:0] data_in;
    input wire [15:0][63:0] addr;
    output logic [15:0][7:0] data_out;
    output logic [15:0] valid;

    parameter [1:0] IDLE        = 2'b00;
    parameter [1:0] WAIT        = 2'b01;
    parameter [1:0] REPLY_RD    = 2'b10;
    parameter [1:0] REPLY_WR    = 2'b11;

    logic [1:0] state, next_state;
    logic [1:0] state2, next_state2;
    logic [7:0] cnt;
    wire [7:0] next_cnt;
    logic [7:0] cnt2;
    wire [7:0] next_cnt2;
    logic [7:0] mem [0:(`MEM_SIZE_BYTES-1)]; // actual array representing memory
    logic [7:0] next_mem [0:(`MEM_SIZE_BYTES-1)];
    logic [15:0] next_valid;
    logic [15:0] en_int;
    logic [1:0] rdwr_int;
    logic [15:0][7:0] data_in_int;
    logic [15:0][63:0] addr_int;

    logic [4:0] i;

    assign next_cnt = (state == WAIT) ? (cnt+1) : 0;
    assign next_cnt2 = (state2 == WAIT) ? (cnt2+1) : 0;

    always_comb
    begin
        next_state = IDLE;
        next_state2 = IDLE;
        next_valid = 0;
        next_mem = mem;
        case(state)
            IDLE: 
                begin
                    if (en[7:0]) begin
                        next_state = WAIT; 
                    end else begin
                        next_state = IDLE;
                    end
                end

            WAIT:
                begin
                    if ((cnt == `WAIT_CYCLES-1) & rdwr_int[0]) begin
                        next_state = REPLY_RD; 
                        for (i = 0; i < 8; i=i+1) begin
                            if (en_int[i])
                            begin
                                next_valid[i] = 1'b1;
                                data_out[i] = mem[addr_int[i]];
                            end
                        end
                    end else if ((cnt == `WAIT_CYCLES-1) & ~rdwr_int[0]) begin
                        next_state = REPLY_WR; 

                        for (i = 0; i < 8; i=i+1) begin
                            if (en_int[i]) begin
                                next_mem[addr_int[i]] = data_in_int[i];
                            end
                        end
                    end else begin
                        next_state = WAIT;
                    end
                end

            REPLY_RD:
                begin
                    next_state = IDLE;
                    next_valid[7:0] = 0;
                end

            REPLY_WR:
                begin
                    next_state = IDLE;
                    next_valid[7:0] = 0;
                end

            default: next_state = IDLE;
        endcase

        case(state2)
            IDLE: 
                begin
                    if (en[15:8]) begin
                        next_state2 = WAIT; 
                    end else begin
                        next_state2 = IDLE;
                    end
                end

            WAIT:
                begin
                    if ((cnt2 == `WAIT_CYCLES-1) & rdwr_int[1]) begin
                        next_state2 = REPLY_RD; 
                        for (i = 8; i < 16; i=i+1) begin
                            if (en_int[i])
                            begin
                                next_valid[i] = 1'b1;
                                data_out[i] = mem[addr_int[i]];
                            end
                        end
                    end else if ((cnt2 == `WAIT_CYCLES-1) & ~rdwr_int[1]) begin
                        next_state2 = REPLY_WR; 

                        for (i = 8; i < 16; i=i+1) begin
                            if (en_int[i]) begin
                                next_mem[addr_int[i]] = data_in_int[i];
                            end
                        end
                    end else begin
                        next_state2 = WAIT;
                    end
                end

            REPLY_RD:
                begin
                    next_state2 = IDLE;
                    next_valid[15:8] = 0;
                end

            REPLY_WR:
                begin
                    next_state2 = IDLE;
                    next_valid[15:8] = 0;
					
                end

            default: next_state2 = IDLE;
        endcase
    end

    always @(posedge clk)
    begin
        if (reset) begin
            state       <= #1 IDLE;
            state2      <= #1 IDLE;
            cnt         <= #1 0;
            cnt2        <= #1 0;
            valid       <= #1 0;
            en_int      <= #1 0;
            data_in_int <= #1 0;
            addr_int    <= #1 0;
            rdwr_int    <= #1 0;
        end else begin
            state    <= #1 next_state;
            state2   <= #1 next_state2;
            cnt      <= #1 next_cnt;
            cnt2     <= #1 next_cnt2;
            valid    <= #1 next_valid;
            mem      <= #1 next_mem;

            // In IDLE state, REPLY_RD, and REPLY_WR we are interested in any new values
            // someone puts onto the input lines
            if (state != WAIT)
            begin
                en_int[7:0]      <= #1 en[7:0];
                rdwr_int[0]    <= #1 rdwr[0];
                data_in_int[7:0] <= #1 data_in[7:0];
                addr_int[7:0]    <= #1 addr[7:0];
            end

            if (state2 != WAIT)
            begin
                en_int[15:8]      <= #1 en[15:8];
                rdwr_int[1]    <= #1 rdwr[1];
                data_in_int[15:8] <= #1 data_in[15:8];
                addr_int[15:8]    <= #1 addr[15:8];
            end
        end
    end

endmodule
