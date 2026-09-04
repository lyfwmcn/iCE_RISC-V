`timescale 1ns / 1ns

module RegFile (
    input CLK,
    input RST,
    input RegWr,
    input [4:0] Rd,
    input [4:0] Rs1,
    input [4:0] Rs2,
    input [31:0] Regin,
    output [31:0] RegoutA,
    output [31:0] RegoutB
);

reg [31:0] regs [1:31];

assign RegoutA = Rs1 == 5'h0 ? 32'h0 : regs[Rs1];
assign RegoutB = Rs2 == 5'h0 ? 32'h0 : regs[Rs2];

integer i;

always @(posedge CLK or posedge RST) begin
    if (RST == 1'h1) begin
        for (i = 1; i < 32; i = i + 1) begin
            regs[i] <= 32'h0;
        end
    end
    else if (RegWr == 1'h1 && Rd > 5'h0) begin
        regs[Rd] <= Regin;
    end
end

endmodule
