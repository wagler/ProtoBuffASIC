`define BYTE 8

module varint_ser(in_port, out_port);

output logic [(10*`BYTE)-1 : 0] out_port;
input logic [(8*`BYTE)-1 : 0] in_port;

logic [8:0] packet_valid;

assign out_port[79:73] = 7'b0;
assign out_port[72] = in_port[63];
assign packet_valid[8] = in_port[63];

// for (i=0; i < 8; i++) packet_valid[i] = |in_port[(7*i + 13) : (7*(i + 1))];
assign packet_valid[0] = |in_port[13:7];
assign packet_valid[1] = |in_port[(7 + 13):(7 + 7)];
assign packet_valid[2] = |in_port[(14 + 13):(14 + 7)];
assign packet_valid[3] = |in_port[(21 + 13):(21 + 7)];
assign packet_valid[4] = |in_port[(28 + 13):(28 + 7)];
assign packet_valid[5] = |in_port[(35 + 13):(35 + 7)];
assign packet_valid[6] = |in_port[(42 + 13):(42 + 7)];
assign packet_valid[7] = |in_port[(49 + 13):(49 + 7)];

always_comb
begin	
    // for (i=0; i < 9; i++) out_port[(8*i-1)] = |packet_valid[8:i];
	out_port[7] = |packet_valid[8:0];
	out_port[15] = |packet_valid[8:1];
	out_port[23] = |packet_valid[8:2];
	out_port[31] = |packet_valid[8:3];
	out_port[39] = |packet_valid[8:4];
	out_port[47] = |packet_valid[8:5];
	out_port[55] = |packet_valid[8:6];
	out_port[63] = |packet_valid[8:7];
	out_port[71] = |packet_valid[8:8];

    // for (i=0; i < 9; i++) out_port[(8*i + 6):(8*i)] = in_port[(7*i+6):(7*i)];
	out_port[6:0] = in_port[6:0];
	out_port[14:8] = in_port[13:7];
	out_port[22:16] = in_port[20:14];
	out_port[30:24] = in_port[27:21];
	out_port[38:32] = in_port[34:28];
	out_port[46:40] = in_port[41:35];
	out_port[54:48] = in_port[48:42];
	out_port[62:56] = in_port[55:49];
	out_port[70:64] = in_port[62:56];
end
endmodule //varint_ser
