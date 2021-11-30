`define ROWS 64

module object_buffer(clk, reset, new_entry, valid_in, full);

    input wire clk;
    input wire reset;
    input TABLE_ENTRY new_entry;
    input wire valid_in;
    output logic full;

    logic next_full;

    logic [$clog2(`ROWS)-1:0] curr, next_curr;
    logic [$clog2(`ROWS)-1:0] free;

    BUFFER_ENTRY [`ROWS-1:0] entries, next_entries;

    always_ff @(posedge clk)
    begin
        if (reset)
        begin
            full    <= #1 1'b0;
            curr    <= #1 'd0; 
            for(int i = 0; i < `ROWS; i=i+1)
            begin
                entries[i].valid <= #1 1'b0;
            end
        end

        else
        begin
            entries <= #1 next_entries;
            curr    <= #1 next_curr;
            full    <= #1 next_full;
        end
    end

    always_comb
    begin
        next_curr = curr;

        // Check for vacant entries
        next_full = 1'b1;

        // Holds the row number of a free entry (default to 0 even if it's not free)
        // It's up to the user of this verilog module to check the full bit before entering something
        free = 'd0;

        // CAM for invalid rows backwards, so we find the lowest number row last
        for(int i = `ROWS-1; i >= 0; i=i-1)
        begin
           if (entries[i].valid==1'b0)
           begin
               next_full = 1'b0; 
               free = i;
           end
        end


        // If someone is trying to input some new entry, put it in the invalid row we found
        if (valid_in)
        begin
            next_entries[free].valid = 1'b1;
            next_entries[free].entry = new_entry;
        end
    end

endmodule
