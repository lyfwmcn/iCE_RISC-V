`timescale 1ns / 1ns

module CSRHazard (
    input IDIsCSR,
    input EXIsCSR,
    input EXCSRWr,
    input M1IsCSR,
    input M1CSRWr,
    input M2IsCSR,
    input M2CSRWr,
    input WBIsCSR,
    input WBCSRWr,
    input [11:0] IDCSRRd,
    input [11:0] EXCSRRd,
    input [11:0] M1CSRRd,
    input [11:0] M2CSRRd,
    input [11:0] WBCSRRd,
    output CSRWait
);

wire [11:0] IDPairCSRRd;
assign IDPairCSRRd = IDCSRRd == 12'h100 ? 12'h300 :
                     IDCSRRd == 12'h104 ? 12'h304 :
                     IDCSRRd == 12'h144 ? 12'h344 :
                     IDCSRRd == 12'h300 ? 12'h100 :
                     IDCSRRd == 12'h304 ? 12'h104 :
                     IDCSRRd == 12'h344 ? 12'h144 :
                     12'h0;

assign CSRWait = IDIsCSR &&
                 ((EXIsCSR && EXCSRWr && (EXCSRRd == IDCSRRd || (IDPairCSRRd == 12'h0 ? 1'h0 : EXCSRRd == IDPairCSRRd))) ||
                 (M1IsCSR && M1CSRWr && (M1CSRRd == IDCSRRd || (IDPairCSRRd == 12'h0 ? 1'h0 : M1CSRRd == IDPairCSRRd))) ||
                 (M2IsCSR && M2CSRWr && (M2CSRRd == IDCSRRd || (IDPairCSRRd == 12'h0 ? 1'h0 : M2CSRRd == IDPairCSRRd))) ||
                 (WBIsCSR && WBCSRWr && (WBCSRRd == IDCSRRd || (IDPairCSRRd == 12'h0 ? 1'h0 : WBCSRRd == IDPairCSRRd))));

endmodule
