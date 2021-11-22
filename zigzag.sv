module zigzag(en, in_val, is_32, out_val);
    input logic en;
    input logic [63:0] in_val;
    input logic is_32;
    output logic [63:0] out_val;

    always_comb
    begin
        if (en)
        begin
            if (is_32)
            begin
                out_val = (in_val << 1) ^ (in_val >>> 31);
            end
            else
            begin
                out_val = (in_val << 1) ^ (in_val >>> 63);
            end
        end
        else 
        begin
            out_val = 64'b0;
        end
    end

endmodule
