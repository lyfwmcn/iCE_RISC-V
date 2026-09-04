`timescale 1ns / 1ns

// 需保证 WBCSRin 符合格式
module TrapCSRByPass (
    input WBCSRWr,
    input [1:0] CurMPP,
    input [11:0] WBCSRRd,
    input [31:0] Curmepc,
    input [31:0] Curmtvec,
    input [31:0] WBCSRin,
    output [1:0] MPP,
    output [31:0] mepc,
    output [31:0] mtvec
);

assign MPP = WBCSRWr == 1'h1 && WBCSRRd == 12'h300 ? WBCSRin[12:11] : CurMPP;
assign mtvec = WBCSRWr == 1'h1 && WBCSRRd == 12'h305 ? WBCSRin : Curmtvec;
assign mepc = WBCSRWr == 1'h1 && WBCSRRd == 12'h341 ? WBCSRin : Curmepc;

endmodule
