`define STACK_ROWS 16

module ser_aggregate(clk, reset, en, addr, entry, entry_valid, done, ready, dram_en, dram_rdwr, dram_data_in, dram_addr, dram_data_out, dram_valid);

    input logic clk, reset, en;
    input logic [63:0] addr;
    input TABLE_ENTRY entry;
    input logic entry_valid;
    output logic done, ready;

    input logic [7:0][7:0] dram_data_in;
    input logic [7:0] dram_valid;
    output logic [7:0][7:0] dram_data_out;
    output logic [7:0][63:0] dram_addr;
    output logic [7:0] dram_en;
    output logic dram_rdwr;

    logic next_done, next_ready;
    logic [7:0][7:0] next_dram_data_out;
    logic [7:0][63:0] next_dram_addr;
    logic [7:0] next_dram_en;
    logic next_dram_rdwr;

    TABLE_ENTRY entry_intrnl;
    logic [39:0] field_header;
    logic [79:0] varint_out;
    logic [63:0] loaded_value;
    TABLE_ENTRY [`STACK_ROWS-1:0] entry_stack, next_entry_stack;
    TABLE_ENTRY [$clog2(`STACK_ROWS)-1:0] entry_stack_ptr, next_entry_stack_ptr;

    logic memcpy_en, memcpy_done;
    logic [63:0] memcpy_src, memcpy_dst;
    logic [14:0] memcpy_size;
    logic [7:0] memcpy_dram_en;
    logic memcpy_dram_rdwr;
    logic [7:0][63:0] memcpy_dram_addr;
    logic [7:0][7:0] memcpy_dram_data_out;

    field_header fh(
       .field_id(entry_intrnl.field_id),
       .field_type(entry_intrnl.field_type),
       .out_port(field_header) 
    );

    top_varint vs(
       .value(loaded_value),
       .field_type(entry_intrnl.field_type),
       .out_port(varint_out)
    );

    memcpy mc(
        .clk(clk),
        .reset(reset),
        .en(memcpy_en),
        .src(memcpy_src),
        .dst(memcpy_dst),
        .size(memcpy_size),
        .done(memcpy_done),
        .dram_en(memcpy_dram_en),
        .dram_rdwr(memcpy_dram_rdwr),
        .dram_addr(memcpy_dram_addr),
        .dram_data_in(memcpy_dram_data_in),
        .dram_data_out(memcpy_dram_data_out),
        .dram_valid(memcpy_dram_valid)
    );

    always_comb
    begin
        next_done = done;
        next_ready = ready;
        next_dram_data_out = dram_data_out;
        next_dram_addr = dram_addr;
        next_dram_en = dram_en;
        next_dram_rdwr = dram_rdwr;
        next_entry_stack = entry_stack;
        next_entry_stack_ptr = entry_stack_ptr;

        if (

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
            if (next_ready & entry_valid)
                entry_intrnl <= #1 entry;
        end
    end

endmodule
