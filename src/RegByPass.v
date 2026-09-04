`timescale 1ns / 1ns

module RegByPass (
    input IDBusAused,
    input IDBusBused,
    input EXRegWr,
    input M1RegWr,
    input M2RegWr,
    input WBRegWr,
    input [2:0] EXRegSrc,
    input [2:0] M1RegSrc,
    input [2:0] M2RegSrc,
    input [4:0] IDRs1,
    input [4:0] IDRs2,
    input [4:0] EXRd,
    input [4:0] M1Rd,
    input [4:0] M2Rd,
    input [4:0] WBRd,
    input [31:0] RegoutA,
    input [31:0] RegoutB,
    input [31:0] EXBusW,
    input [31:0] EXCSRout,
    input [31:0] EXimm,
    input [31:0] EXPCPlus4,
    input [31:0] M1BusW,
    input [31:0] M1CSRout,
    input [31:0] M1imm,
    input [31:0] M1PCPlus4,
    input [31:0] M2BusW,
    input [31:0] M2CSRout,
    input [31:0] M2imm,
    input [31:0] M2PCPlus4,
    input [31:0] Regin,
    output RegWait,
    output [31:0] IDBusA,
    output [31:0] IDBusB
);

wire [3:0] CondA;
assign CondA = IDBusAused == 1'h0 || IDRs1 == 5'h0 ? 4'h8 :
               EXRd == IDRs1 && EXRegWr == 1'h1 ? (EXRegSrc == 3'h2 ? 4'h7 : 4'h6) :
               M1Rd == IDRs1 && M1RegWr == 1'h1 ? (M1RegSrc == 3'h2 ? 4'h5 : 4'h4) :
               M2Rd == IDRs1 && M2RegWr == 1'h1 ? (M2RegSrc == 3'h2 ? 4'h3 : 4'h2) :
               WBRd == IDRs1 && WBRegWr == 1'h1 ? 4'h1 : 4'h0;

wire [3:0] CondB;
assign CondB = IDBusBused == 1'h0 || IDRs2 == 5'h0 ? 4'h8 :
               EXRd == IDRs2 && EXRegWr == 1'h1 ? (EXRegSrc == 3'h2 ? 4'h7 : 4'h6) :
               M1Rd == IDRs2 && M1RegWr == 1'h1 ? (M1RegSrc == 3'h2 ? 4'h5 : 4'h4) :
               M2Rd == IDRs2 && M2RegWr == 1'h1 ? (M2RegSrc == 3'h2 ? 4'h3 : 4'h2) :
               WBRd == IDRs2 && WBRegWr == 1'h1 ? 4'h1 : 4'h0;

wire [31:0] IDBusAs [8:0];

assign IDBusAs[0] = RegoutA;
assign IDBusAs[1] = Regin;
assign IDBusAs[2] = M2RegSrc == 3'h0 ? M2BusW :
                    M2RegSrc == 3'h1 ? M2PCPlus4 :
                    M2RegSrc == 3'h2 ? 32'h0 :
                    M2RegSrc == 3'h3 ? M2imm :
                    M2RegSrc == 3'h4 ? M2CSRout :
                    32'h0;
assign IDBusAs[3] = 32'h0;
assign IDBusAs[4] = M1RegSrc == 3'h0 ? M1BusW :
                    M1RegSrc == 3'h1 ? M1PCPlus4 :
                    M1RegSrc == 3'h2 ? 32'h0 :
                    M1RegSrc == 3'h3 ? M1imm :
                    M1RegSrc == 3'h4 ? M1CSRout :
                    32'h0;
assign IDBusAs[5] = 32'h0;
assign IDBusAs[6] = EXRegSrc == 3'h0 ? EXBusW :
                    EXRegSrc == 3'h1 ? EXPCPlus4 :
                    EXRegSrc == 3'h2 ? 32'h0 :
                    EXRegSrc == 3'h3 ? EXimm :
                    EXRegSrc == 3'h4 ? EXCSRout :
                    32'h0;
assign IDBusAs[7] = 32'h0;
assign IDBusAs[8] = 32'h0;

assign IDBusA = IDBusAs[CondA];

wire [31:0] IDBusBs [8:0];

assign IDBusBs[0] = RegoutB;
assign IDBusBs[1] = Regin;
assign IDBusBs[2] = IDBusAs[2];
assign IDBusBs[3] = 32'h0;
assign IDBusBs[4] = IDBusAs[4];
assign IDBusBs[5] = 32'h0;
assign IDBusBs[6] = IDBusAs[6];
assign IDBusBs[7] = 32'h0;
assign IDBusBs[8] = 32'h0;

assign IDBusB = IDBusBs[CondB];

assign RegWait = CondA == 4'h3 || CondA == 4'h5 || CondA == 4'h7 ||
              CondB == 4'h3 || CondB == 4'h5 || CondB == 4'h7;

endmodule
