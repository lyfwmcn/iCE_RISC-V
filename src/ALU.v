`timescale 1ns / 1ns

// 需保证 ALUCtr[3:0]: 4‘h0-4'h8, 4'hd
module ALU (
    input [5:0] ALUCtr,
    input [31:0] OperA,
    input [31:0] OperB,
    output ZF,
    output CF,
    output SF,
    output OF,
    output [31:0] BusW
);

wire [31:0] _OperA;
assign _OperA = ALUCtr[4] == 1'h0 ? OperA : ~OperA;
wire [31:0] _OperB;
assign _OperB = ALUCtr[5] == 1'h0 ? OperB : ~OperB;

wire [31:0] result [7:0];

wire [31:0] __OperB;
assign __OperB = ALUCtr[3] == 1'h0 ? _OperB : ~_OperB + 32'h1;
wire cout;

assign {cout, result[0]} = _OperA + __OperB;
assign result[1] = _OperA << _OperB[4:0];
assign result[2] = $signed(_OperA) < $signed(_OperB) ? 32'h1 : 32'h0;
assign result[3] = _OperA < _OperB ? 32'h1 : 32'h0;
assign result[4] = _OperA ^ _OperB;
assign result[5] = ALUCtr[3] == 1'h0 ? _OperA >> _OperB[4:0] : $unsigned($signed(_OperA) >>> _OperB[4:0]);
assign result[6] = _OperA | _OperB;
assign result[7] = _OperA & _OperB;

assign ZF = result[0] == 32'h0;
assign CF = ALUCtr[3] ^ cout;
assign SF = result[0][31];
assign OF = (_OperA[31] & __OperB[31] & ~result[0][31]) | (~_OperA[31] & ~__OperB[31] & result[0][31]);
assign BusW = result[ALUCtr[2:0]];

endmodule
