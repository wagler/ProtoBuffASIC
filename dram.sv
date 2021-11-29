`define WAIT_CYCLES 20

module DRAM(clk, reset, en, rdwr, data_in , addr, data_out, valid);

    input wire clk;
    input wire reset;
    input wire [7:0] en;
    input wire rdwr;
    input wire [7:0][7:0] data_in;
    input wire [7:0][63:0] addr;
    output logic [7:0][7:0] data_out;
    output logic [7:0] valid;

    parameter [1:0] IDLE        = 2'b00;
    parameter [1:0] WAIT        = 2'b01;
    parameter [1:0] REPLY_RD    = 2'b10;
    parameter [1:0] REPLY_WR    = 2'b11;

    logic [1:0] state, next_state;
    logic [7:0] cnt;
    wire [7:0] next_cnt;
    logic [7:0] mem [0:63]; // actual array representing memory
    logic [7:0] next_mem [0:63];
    logic [7:0] next_valid;

    logic [3:0] i;

    assign next_cnt = (state == WAIT) ? (cnt+1) : 0;

    always_comb
    begin
        next_state = IDLE;
        next_valid = valid;
        case(state)
            IDLE: if (en) begin
                next_state = WAIT; 
            end else begin
                next_state = IDLE;
            end

            WAIT:
                if ((cnt == `WAIT_CYCLES) & rdwr) begin
                    next_state = REPLY_RD; 
                end else if ((cnt == `WAIT_CYCLES) & ~rdwr) begin
                    next_state = REPLY_WR; 
                end else begin
                    next_state = WAIT;
                end

            REPLY_RD:
                for (i = 0; i < 8; i=i+1) begin
                    if (en[i]) begin
                        data_out[i] = mem[addr[i]];
                        next_valid[i] = 1'b1;
                    end
                end

            REPLY_WR:
                for (i = 0; i < 8; i=i+1) begin
                    if (en[i]) begin
                        next_mem[addr[i]] = data_in[i];
                    end
                end

            default: next_state = IDLE;
        endcase
    end

    always @(posedge clk)
    begin
        if (reset) begin
            state <= #1 IDLE;
            cnt   <= #1 0;
            valid <= #1 0;
        end else begin
            state   <= #1 next_state;
            cnt     <= #1 next_cnt;
            valid   <= #1 next_valid;
            mem     <= #1 next_mem;
        end
    end

endmodule
