module ser_aggregate(clk, reset, en, addr, entry, done, ready, dram_en, dram_rdwr, dram_data_in, dram_addr, dram_data_out, dram_valid);

    input logic clk, reset, en;
    input logic [63:0] addr;
    input TABLE_ENTRY entry;
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

    always_comb
    begin
        next_done = done;
        next_ready = ready;
        next_dram_data_out = dram_data_out;
        next_dram_addr = dram_addr;
        next_dram_en = dram_en;
        next_dram_rdwr = dram_rdwr;

    end

    always_ff @(posedge clk)
    begin
        if (reset)
        begin
            done            <= #1 0;
            ready           <= #1 0;
            dram_en         <= #1 0;
            dram_data_out   <= #1 0;
            dram_addr       <= #1 0;
            dram_rdwr       <= #1 0;
            entry_intrnl    <= #1 0;
        end
        else
        begin
            done            <= #1 next_done;
            ready           <= #1 next_ready;
            dram_data_out   <= #1 next_dram_data_out;
            dram_addr       <= #1 next_dram_addr;
            dram_en         <= #1 next_dram_en;
            dram_rdwr       <= #1 next_dram_rdwr;
            if (next_ready)
                entry_intrnl <= #1 entry;
        end
    end

endmodule
