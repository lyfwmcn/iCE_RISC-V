`timescale 1ns / 1ns

// 需保证 Privilege = 2'h0, 2'h1, 2'h3
// 需保证 MPP = 2'h0, 2'h1, 2'h3
module TrapUnit (
    input M2Ebreak,
    input M2Ecall,
    input M2InstrAccessFault,
    input M2InstrAlignFault,
    input M2InstrFault,
    input M2InstrPageFault,
    input M2LoadAccessFault,
    input M2LoadAlignFault,
    input M2LoadPageFault,
    input M2StoreAccessFault,
    input M2StoreAlignFault,
    input M2StorePageFault,
    input Ret,
    input [1:0] MPP,
    input [1:0] Privilege,
    input [31:0] M2BusW,
    input [31:0] M2Instr,
    input [31:0] M2PC,
    input [31:0] M2PCCtrPC,
    output PrivilegeChange,
    output Trap,
    output [1:0] NextMPP,
    output [1:0] NextPrivilege,
    output [31:0] Nextmcause,
    output [31:0] Nextmepc,
    output [31:0] Nextmtval
);

wire [3:0] _cause;
assign _cause = M2InstrPageFault ? 4'hc :
                M2InstrAccessFault ? 4'h1 :
                M2InstrFault ? 4'h2 :
                M2Ebreak ? 4'h3 :
                M2Ecall ? (Privilege == 2'h0 ? 4'h8 : Privilege == 2'h1 ? 4'h9 : 4'hb) :
                M2InstrAlignFault ? 4'h0 :
                M2LoadAlignFault ? 4'h4 :
                M2LoadPageFault ? 4'hd :
                M2LoadAccessFault ? 4'h5 :
                M2StoreAlignFault ? 4'h6 :
                M2StorePageFault ? 4'hf :
                M2StoreAccessFault ? 4'h7 :
                4'ha;

assign PrivilegeChange = Trap || Ret;
assign Trap = _cause != 4'ha;
// 需保证 NextMPP = 2'h0, 2'h1, 2'h3
assign NextMPP = Trap ? Privilege :
                 Ret ? 2'h0 :
                 2'h0;
// 需保证 NextPrivilege = 2'h0, 2'h1, 2'h3
assign NextPrivilege = Trap ? 2'h3 :
                  Ret ? MPP :
                  2'h0;
// 需保证 Nextmcause 符合格式
assign Nextmcause = Trap ? {28'h0, _cause} :
                    32'h3;
// 需保证 Nextmepc 符合格式
assign Nextmepc = Trap ? M2PC :
                  32'h0;
// 需保证 Nextmtval 符合格式
assign Nextmtval = Trap == 1'h0 ? 32'h0 :
                   _cause == 4'ha || _cause == 4'h3 || _cause == 4'h8 || _cause == 4'h9 || _cause == 4'hb ? 32'h0 :
                   _cause == 4'h0 ? M2PCCtrPC :
                   _cause == 4'h1 || _cause == 4'hc ? M2PC :
                   _cause == 4'h2 ? M2Instr :
                   M2BusW;

endmodule
