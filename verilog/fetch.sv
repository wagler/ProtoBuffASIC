module fetch(clk, reset, en, new_addr, new_addr_valid, dram_en, dram_rdwr, dram_data, dram_addr, dram_valid, entry, ob_valid, ob_full);

    // Input and output ports for this module
    input logic clk;
    input logic reset
    input logic en;
    input logic [63:0] new_addr;
    input logic new_addr_valid;

    // Input and outputs for interacting with DRAM
    input  logic [7:0]       dram_valid;
    input  logic [7:0][7:0]  dram_data;
    output logic [7:0]       dram_en;
    output logic             dram_rdwr;
    output logic [7:0][63:0] dram_addr;

    // Input and outputs for interacting with object buffer
    input   logic       ob_full;
    output  logic       ob_valid;
    output  TABLE_ENTRY entry;

    // Next state values
    logic               next_ob_valid;
    logic TABLE_ENTRY   next_entry;
    logic [7:0]         next_dram_en;
    logic               next_dram_rdwr;
    logic [7:0][63:0]   next_dram_addr;


    // The address we should be reading from
    logic [63:0] addr, next_addr;

    // Keeps state of the state machine this module operates from
    logic [2:0] state, next_state;

    parameter [2:0] IDLE        = 3'b000;
    parameter [2:0] WAIT1       = 3'b001; // While waiting for DRAM to return first 64 bits of table entry
    parameter [2:0] WAIT2       = 3'b010; // While waiting for DRAM to return second 64 bits of table entry (optional address)
    parameter [2:0] DRAM1_START = 3'b011; // Starts DRAM request for first 64 bits
    parameter [2:0] DRAM2_START = 3'b100; // Starts DRAM request for second 64 bits
    parameter [2:0] OB_OUT1     = 3'b101; // Asserts values to object buffer (stays here until full goes low)
    parameter [2:0] OB_OUT2     = 3'b110; // Asserts values to object buffer (stays here until full goes low)

    always_comb
    begin
        next_state = IDLE;

        case(state)
            IDLE:
                if (en)
                begin
                    next_state      = DRAM1_START;
                    next_dram_en    = 8'hFF;
                    next_dram_rdwr  = 1'b1; // Read
                    next_dram_addr  = new_addr_valid ? new_addr : (addr+1);
                end
                else
                    next_state = IDLE;

            DRAM1_START:
                next_state   = WAIT1;
                next_dram_en = 0;

            WAIT1:
                if(dram_valid != 8'hFF)
                    next_state = WAIT1;
                else
                begin
                end

            default: next_state = IDLE;
        endcase
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
