`timescale 1ns / 1ns

// 需保证 NextPrivilege = 2'h0, 2'h1, 2'h3
module PrivilegeMode (
    input CLK,
    input RST,
    input PrivilegeChange,
    input [1:0] NextPrivilege,
    output reg [1:0] Privilege
);

always @(posedge CLK or posedge RST) begin
    if (RST == 1'h1) begin
        Privilege <= 2'h3;
    end
    else if (PrivilegeChange == 1'h1) begin
        Privilege <= NextPrivilege;
    end
end

endmodule
