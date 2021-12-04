module object_buffer_tb;
    logic clk;
    logic reset;
    logic [63:0] new_cpp_base_addr;
    logic new_cpp_base_addr_valid;
    logic ser_ready;
    logic ser_done;

    TABLE_ENTRY new_entry;
    logic valid_in;
    logic full;
    TABLE_ENTRY out_entry;
    logic out_entry_valid;
    logic [63:0] cpp_base_addr;

    logic fetch_en;
    logic [63:0] fetch_new_addr;
    logic fetch_new_addr_en;
    logic [7:0] fetch_dram_valid;
    logic [7:0] fetch_dram_en;
    logic fetch_dram_rdwr;
    logic [7:0][7:0] fetch_dram_data;
    logic [7:0][63:0] fetch_dram_addr;
    
    fetch f(
        .clk(clk),
        .reset(reset),
        .en(fetch_en),
        .new_addr(fetch_new_addr),
        .new_addr_valid(fetch_new_addr_en),
        .dram_valid(fetch_dram_valid),
        .dram_data(fetch_dram_data),
        .dram_en(fetch_dram_en),
        .dram_rdwr(fetch_dram_rdwr),
        .dram_addr(fetch_dram_addr),
        .entry(new_entry),
        .ob_full(full),
        .ob_valid(valid_in)
    );

    DRAM dram(
        .clk(clk),
        .reset(reset),
        .en(fetch_dram_en),
        .rdwr(fetch_dram_rdwr),
        .data_in({64{1'b0}}),
        .addr(fetch_dram_addr),
        .data_out(fetch_dram_data),
        .valid(fetch_dram_valid)
    );

    object_buffer ob(
        .clk(clk), 
        .reset(reset),
        .new_cpp_base_addr(new_cpp_base_addr),
        .new_cpp_base_addr_valid(new_cpp_base_addr_valid),
        .new_entry(new_entry), 
        .valid_in(valid_in), 
        .full(full),
        .ser_ready(ser_ready),
        .ser_done(ser_done),
        .out_entry(out_entry),
        .out_entry_valid(out_entry_valid),
        .cpp_base_addr(cpp_base_addr)
    );

    initial
    begin
        clk = 0;
    end

    always
        #1 clk = !clk;

    task print_ob;
        $display("\t  +-------------------------------------------------------------------------------------+");
        $display("\t  |                                 Object Buffer        @%g                            |",$time);
        $display("\t  +-------------------------------------------------------------------------------------+");
        $display("\t  |    entry    | valid | Field ID  | Type | Offset | Size  | Nested | Nested Table Addr|");
        $display("\t  +-------------------------------------------------------------------------------------+");
        for (int i = 0; i < 9; i=i+1)
        begin

            //if (ob.entries[i].valid)
            //begin
                if (ob.curr == i)
                begin
                    $display("\t->| %d |   %b   | %d |  %d  | %d  | %d |   %b    | %h |", 
                        i, ob.entries[i].valid, ob.entries[i].entry.field_id, ob.entries[i].entry.field_type, 
                        ob.entries[i].entry.offset, ob.entries[i].entry.size, ob.entries[i].entry.nested, ob.entries[i].entry.nested_type_table
                    );            
                end
                else
                begin
                    $display("\t  | %d |   %b   | %d |  %d  | %d  | %d |   %b    | %h |", 
                        i, ob.entries[i].valid, ob.entries[i].entry.field_id, ob.entries[i].entry.field_type, 
                        ob.entries[i].entry.offset, ob.entries[i].entry.size, ob.entries[i].entry.nested, ob.entries[i].entry.nested_type_table
                    );
                end
                $display("\t  +-------------------------------------------------------------------------------------+");
            //end
        end
    endtask

    task print_ob_stack;
        $display("\t  +--------------------------------------------------+");
        $display("\t  |                 OB Stack @%g                    |",$time);
        $display("\t  +--------------------------------------------------+");
        $display("\t  |     Stack Item        |     C++ Object Ptr       |");
        $display("\t  +--------------------------------------------------+");
        for (int i = 0; i < 16; i=i+1)
        begin
            if (ob.cpp_obj_ptr_stack_ptr == i)
                $display("\t->|%d            |        %h  |",i, ob.cpp_obj_ptr_stack[i]);
            else
                $display("\t  |%d            |        %h  |",i, ob.cpp_obj_ptr_stack[i]);
        $display("\t  +--------------------------------------------------+");
        end
    endtask

    initial
    begin
        $readmemh("testbench/table3.mem", dram.mem);
        $readmemh("testbench/table4.mem", dram.mem, 64'h100);
        $readmemh("testbench/table5.mem", dram.mem, 64'h200);
        $monitor("@%g reset=%b, new_cpp_base_addr=%h, new_cpp_base_addr_valid=%b, full=%b, valid_in=%b, new_entry=%h, curr=%d, ser_ready=%b, ser_done=%b, out_entry=%h, out_entry_valid=%b, cpp_base_addr=%h", $time, reset, new_cpp_base_addr, new_cpp_base_addr_valid, full, valid_in, new_entry, ob.curr, ser_ready, ser_done, out_entry, out_entry_valid, cpp_base_addr);
        reset = 1;
        fetch_en = 0;
        fetch_new_addr_en = 0;
        new_cpp_base_addr = 64'd0;
        new_cpp_base_addr_valid = 1'b0;
        ser_ready = 1'b1;
        ser_done = 1'b0;
        @(negedge clk);
        @(negedge clk);
        reset = 0;
        fetch_new_addr = 0;
        fetch_new_addr_en = 1;
        @(negedge clk);
        fetch_new_addr_en = 0;
        @(negedge clk);
        fetch_en = 1;

        for (int i = 0; i < 9; i=i+1)
        begin
            while(~valid_in) @(negedge clk);
            @(negedge clk);
            print_ob();
        end

        for (int i = 0; i < 8; i=i+1)
        begin
            ser_ready = 0;
            @(negedge clk);
            ser_ready = 1;
            ser_done = 1;
            @(negedge clk);
            ser_done = 0;
            @(negedge clk);
            print_ob();
            print_ob_stack();
        end

        $write("\n");
        $finish;
    end
endmodule
