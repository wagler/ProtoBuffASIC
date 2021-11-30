`define ROWS 64

typedef struct packed {

    logic           valid;
    logic [28:0]    field_id;
    logic [4:0]     field_type;
    logic [15:0]    size;
    logic           nested;
    logic [63:0]    nested_type_table;
} BUFFER_ENTRY;

module object_buffer(clk, reset, full);

    input wire clk;
    input wire reset;
    output reg full;

    logic next_full;

    logic [$clog2(`ROWS)-1:0] head, tail;

    BUFFER_ENTRY [`ROWS-1:0] entries, next_entries;

    always_ff @(posedge clk)
    begin
        if (reset)
        begin
            // Invalidate all the table's rows
            for (int i = 0; i < `ROWS; i=i+1)
            begin
                entries[i].valid <= #1 1'b0;
            end

            full <= #1 1'b0;
        end
    end

    always_comb
    begin

        // Check for vacant entries
        next_full = 1'b1;
        for(int i = 0; i < `ROWS; i=i+1)
        begin
           if (entries[i].valid==1'b0)
               next_full = 1'b0; 
        end
    end

endmodule
