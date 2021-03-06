`define ROWS 64
`define STACK_ROWS 16

module object_buffer(clk, reset, new_cpp_base_addr, new_cpp_base_addr_valid, new_entry, valid_in, full, ser_ready, ser_done, out_entry, out_entry_valid, cpp_base_addr, done);

    input wire clk;
    input wire reset;
    input TABLE_ENTRY new_entry;
    input wire valid_in;
    input logic ser_ready;
    input logic ser_done;
    input logic [63:0] new_cpp_base_addr; // Should only input a new address 1 cycle after reset. Else, addr stack gets messed up
    input logic new_cpp_base_addr_valid;
    output logic full;
    output TABLE_ENTRY out_entry;
    output logic out_entry_valid;
    output logic [63:0] cpp_base_addr;
	output logic done;

    logic next_full;
    logic next_out_entry_valid;
    TABLE_ENTRY next_out_entry;
    logic [63:0] next_cpp_base_addr;
	logic next_done;


    logic [$clog2(`ROWS)-1:0] curr, next_curr;
    logic [$clog2(`ROWS)-1:0] free;

    logic [`STACK_ROWS-1:0][63:0] cpp_obj_ptr_stack, next_cpp_obj_ptr_stack;
    logic [$clog2(`STACK_ROWS)-1:0] cpp_obj_ptr_stack_ptr, next_cpp_obj_ptr_stack_ptr;

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

            cpp_obj_ptr_stack_ptr   <= #1 0;
           	cpp_obj_ptr_stack[0]       <= #1 64'h100;
			for (int i = 1; i < `STACK_ROWS; i = i + 1)
			begin
            	cpp_obj_ptr_stack[i]       <= #1 0;
			end
            out_entry_valid         <= #1 0;
            out_entry               <= #1 0;
            cpp_base_addr           <= #1 64'h100;
			done					<= #1 0;
        end

        else
        begin
            entries <= #1 next_entries;
            curr    <= #1 next_curr;
            full    <= #1 next_full;
            cpp_obj_ptr_stack_ptr <= #1 next_cpp_obj_ptr_stack_ptr;
            cpp_obj_ptr_stack     <= #1 next_cpp_obj_ptr_stack;
            out_entry_valid         <= #1 next_out_entry_valid;
            out_entry               <= #1 next_out_entry;
            cpp_base_addr           <= #1 next_cpp_base_addr;
			done					<= #1 next_done;
        end
    end

    logic found;
    always_comb
    begin
        next_curr = ser_done ? curr+1 : curr;
        next_entries = entries;
        next_cpp_obj_ptr_stack = cpp_obj_ptr_stack;
        next_cpp_obj_ptr_stack_ptr = cpp_obj_ptr_stack_ptr;
        next_out_entry_valid = out_entry_valid;
		next_done = done;
        found = 0;

        // Check for vacant entries
        next_full = 1'b1;

        // Holds the row number of a free entry (default to 0 even if it's not free)
        // It's up to the user of this verilog module to check the full bit before entering something
        free = 'd0;

        // CAM for invalid rows backwards, so we find the lowest number row last
        for(int i = 0; i <= `ROWS-1; i+=1)
        begin
           if ((i >= curr) & entries[i].valid==1'b0 & (found == 0))
           begin
               next_full = 1'b0; 
               free = i;
               found = 1;
           end
        end


        if (ser_done)
        begin
            next_entries[curr].valid = 1'b0;
        end

        // If someone is trying to input some new entry, put it in the invalid row we found
        if (valid_in)
        begin
            next_entries[free].valid = 1'b1;
            next_entries[free].entry = new_entry;
        end

        // Make sure the outputted entry is always from the row that the curr ptr points to
        next_out_entry = next_entries[next_curr];

        // Only give the output entry to the serializers once the serializers are ready
        //next_out_entry_valid = next_entries[next_curr].valid & ser_ready;
        next_out_entry_valid = next_entries[next_curr].valid && ~(next_entries[next_curr].entry.field_id == 0 && cpp_obj_ptr_stack_ptr == 0);

        next_done = next_entries[next_curr].valid && (next_entries[next_curr].entry.field_id == 0 && cpp_obj_ptr_stack_ptr == 0 && ser_done);
        
        // Serialization is going to happen on a nested object, so add it to the stack
        if ((next_curr != curr) & next_entries[next_curr].valid & next_entries[next_curr].entry.nested)
        begin
            next_cpp_obj_ptr_stack_ptr = cpp_obj_ptr_stack_ptr + 1;
            next_cpp_obj_ptr_stack[next_cpp_obj_ptr_stack_ptr] = cpp_obj_ptr_stack[cpp_obj_ptr_stack_ptr] + next_entries[next_curr].entry.offset;
        end
        else if (entries[curr].valid & (entries[curr].entry.field_id == 0) & (cpp_obj_ptr_stack_ptr > 0))
        begin
            next_cpp_obj_ptr_stack_ptr = cpp_obj_ptr_stack_ptr - 1;
        end
        next_cpp_base_addr = new_cpp_base_addr_valid ? new_cpp_base_addr : next_cpp_obj_ptr_stack[next_cpp_obj_ptr_stack_ptr];
    end

endmodule
