module fetch(clk, reset, en, new_addr, new_addr_valid, dram_en, dram_rdwr, dram_data, dram_addr, dram_valid, entry, ob_valid, ob_full);

    input logic clk;
    input logic reset
    input logic en;
    input logic [63:0] new_addr;
    input logic new_addr_valid;

    input logic [7:0] dram_valid;
    output logic [7:0] dram_en;
    output logic dram_rdwr;
    output logic [7:0][7:0] dram_data;
    output logic [7:0][63:0] dram_addr;

    input ob_full;
    output ob_valid;
    output TABLE_ENTRY entry;

    always_comb
    begin

    end

    always_ff @(posedge clk)
    begin
        if(reset | ~en)
        begin
            ob_valid    <= #1 0;
            dram_en     <= #1 0;
        end
        else
        begin

        end
    end
endmodule
