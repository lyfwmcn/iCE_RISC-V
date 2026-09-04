`timescale 1ns / 1ns

module CSROperand (
    input [11:0] CSRRd,
    input [31:0] RawCSRin,
    output [31:0] CSRin
);

// 需保证 RawCSRin 符合格式
assign CSRin = CSRRd == 12'h100 ? {12'h0, RawCSRin[19:18], 9'h0, RawCSRin[8], 2'h0, RawCSRin[5], 3'h0, RawCSRin[1], 1'h0} :
               CSRRd == 12'h104 ? {22'h0, RawCSRin[9], 3'h0, RawCSRin[5], 3'h0, RawCSRin[1], 1'h0} :
               CSRRd == 12'h105 ? {RawCSRin[31:2], RawCSRin[1:0] >= 2'h2 ? 2'h0 : RawCSRin[1:0]} :
               CSRRd == 12'h140 ? RawCSRin :
               CSRRd == 12'h141 ? {RawCSRin[31:2], 2'h0} :
               CSRRd == 12'h142 ? {RawCSRin[31], 27'h0, RawCSRin[31] == 1'h0 ? (RawCSRin[3:0] == 4'ha || RawCSRin[3:0] == 4'he ? 4'h3 : RawCSRin[3:0]) : (RawCSRin[3:0] != 4'h1 && RawCSRin[3:0] != 4'h3 && RawCSRin[3:0] != 4'h5 && RawCSRin[3:0] != 4'h7 && RawCSRin[3:0] != 4'h9 && RawCSRin[3:0] != 4'hb ? 4'h3 : RawCSRin[3:0])} :
               CSRRd == 12'h143 ? RawCSRin :
               CSRRd == 12'h144 ? {30'h0, RawCSRin[1], 1'h0} :
               CSRRd == 12'h180 ? RawCSRin :
               CSRRd == 12'h300 ? {9'h0, RawCSRin[22:17], 4'h0, RawCSRin[12:11] == 2'h2 ? 2'h3 : RawCSRin[12:11], 2'h0, RawCSRin[8:7], 1'h0, RawCSRin[5], 1'h0, RawCSRin[3], 1'h0, RawCSRin[1], 1'h0} :
               CSRRd == 12'h302 ? {16'h0, RawCSRin[15], 1'h0, RawCSRin[13:11], 1'h0, RawCSRin[9:0]} :
               CSRRd == 12'h303 ? {20'h0, RawCSRin[11], 1'h0, RawCSRin[9], 1'h0, RawCSRin[7], 1'h0, RawCSRin[5], 1'h0, RawCSRin[3], 1'h0, RawCSRin[1], 1'h0} :
               CSRRd == 12'h304 ? {20'h0, RawCSRin[11], 1'h0, RawCSRin[9], 1'h0, RawCSRin[7], 1'h0, RawCSRin[5], 1'h0, RawCSRin[3], 1'h0, RawCSRin[1], 1'h0} :
               CSRRd == 12'h305 ? {RawCSRin[31:2], RawCSRin[1:0] >= 2'h2 ? 2'h0 : RawCSRin[1:0]} :
               CSRRd == 12'h340 ? RawCSRin :
               CSRRd == 12'h341 ? {RawCSRin[31:2], 2'h0} :
               CSRRd == 12'h342 ? {RawCSRin[31], 27'h0, RawCSRin[31] == 1'h0 ? (RawCSRin[3:0] == 4'ha || RawCSRin[3:0] == 4'he ? 4'h3 : RawCSRin[3:0]) : (RawCSRin[3:0] != 4'h1 && RawCSRin[3:0] != 4'h3 && RawCSRin[3:0] != 4'h5 && RawCSRin[3:0] != 4'h7 && RawCSRin[3:0] != 4'h9 && RawCSRin[3:0] != 4'hb ? 4'h3 : RawCSRin[3:0])} :
               CSRRd == 12'h343 ? RawCSRin :
               CSRRd == 12'h344 ? {28'h0, RawCSRin[3], 1'h0, RawCSRin[1], 1'h0} :
               32'h0;

endmodule
