`timescale 1ns / 1ns

module WBStage (
    // 全局参数
    output [31:0] Regin,

    // 流水线参数
    input [2:0] WBRegSrc,
    input [31:0] WBBusW,
    input [31:0] WBCSRout,
    input [31:0] WBimm,
    input [31:0] WBmem,
    input [31:0] WBPCPlus4
);

assign Regin = WBRegSrc == 3'h0 ? WBBusW :
               WBRegSrc == 3'h1 ? WBPCPlus4 :
               WBRegSrc == 3'h2 ? WBmem :
               WBRegSrc == 3'h3 ? WBimm :
               WBRegSrc == 3'h4 ? WBCSRout :
               32'h0;

endmodule
