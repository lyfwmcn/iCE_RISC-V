`timescale 1ns / 1ns
// CPU 长跑缺陷诊断：纯 CPU+SystemBus。
// 程序由 fpga/dbg_*.s 装配成 bin/mem*.hex；陷阱处理器(0x200)把现场写到 0xE00 区。
module tb_dbg;
reg CLK=0; reg RST;
wire Respond_Fault_Data,Respond_Fault_Instr,Respond_Valid_Data,Respond_Valid_Instr;
wire [31:0] Respond_Data_Data,Respond_Data_Instr;
wire Request_Valid_Instr,Request_Valid_Data,Request_Write_Data;
wire [3:0] Request_EN_Data;
wire [31:0] Request_Addr_Instr,Request_Addr_Data,Request_Data_Data;

CPU CPU ( .CLK(CLK),.RST(RST),
 .Respond_Fault_Data(Respond_Fault_Data),.Respond_Fault_Instr(Respond_Fault_Instr),
 .Respond_Valid_Data(Respond_Valid_Data),.Respond_Valid_Instr(Respond_Valid_Instr),
 .Respond_Data_Data(Respond_Data_Data),.Respond_Data_Instr(Respond_Data_Instr),
 .Request_Valid_Data(Request_Valid_Data),.Request_Valid_Instr(Request_Valid_Instr),
 .Request_Write_Data(Request_Write_Data),.Request_EN_Data(Request_EN_Data),
 .Request_Addr_Data(Request_Addr_Data),.Request_Addr_Instr(Request_Addr_Instr),
 .Request_Data_Data(Request_Data_Data));
SystemBus SB ( .CLK(CLK),.RST(RST),
 .Request_Valid_Data(Request_Valid_Data),.Request_Valid_Instr(Request_Valid_Instr),
 .Request_Write_Data(Request_Write_Data),.Request_EN_Data(Request_EN_Data),
 .Request_Addr_Data(Request_Addr_Data),.Request_Addr_Instr(Request_Addr_Instr),
 .Request_Data_Data(Request_Data_Data),
 .Respond_Fault_Data(Respond_Fault_Data),.Respond_Fault_Instr(Respond_Fault_Instr),
 .Respond_Valid_Data(Respond_Valid_Data),.Respond_Valid_Instr(Respond_Valid_Instr),
 .Respond_Data_Data(Respond_Data_Data),.Respond_Data_Instr(Respond_Data_Instr));

// ---- 抓取前 6 次 M2 段上的分支裁决（含嫌疑关键信号）----
integer cap_cnt = 0;
always @(posedge CLK) begin
    if (CPU.M2IsInstr && CPU.M2BranchCtr[4:0] != 5'h0 && cap_cnt < 6) begin
        cap_cnt = cap_cnt + 1;
        $display("M2BR@%0t M2pc=%h M2in=%08h BCtr=%02h M2PredT=%b | IDpc=%h IDPredT=%b | Cond=%d PCCtr=%b PredJmp=%b ActJmp=%b",
            $time, CPU.M2PC, CPU.M2Instr, CPU.M2BranchCtr, CPU.M2PredTaken,
            CPU.IDPC, CPU.IDPredTaken,
            CPU.M2Stage.BU.Cond, CPU.M2PCCtr, CPU.M2Stage.PredJump, CPU.M2Stage.ActualJump);
    end
end

// ---- 读取 0xE00 区处理器现场（小端 4 字节组字）----
function [31:0] rdword;
    input [31:0] a;
    begin
        rdword = {SB.mem[a+3], SB.mem[a+2], SB.mem[a+1], SB.mem[a]};
    end
endfunction

integer trap_cnt_last = 0;

reg first_trap = 0, ft_done = 0;
always @(posedge CLK) begin
    if (CPU.Trap && !first_trap) first_trap <= 1'b1;
    if (first_trap && !ft_done) begin
        ft_done <= 1'b1;
        $display("FIRST_TRAP@%0t: mepc=%08h mcause=%08h mtval=%08h pcnow=%08h",
            $time, CPU.CSRFile.mepc, CPU.CSRFile.mcause, CPU.CSRFile.mtval,
            CPU.IFStage.PCReg.PCAddr);
    end
end

initial begin
    RST = 1; #5 RST = 0; #5 CLK = 0;
    forever #5 CLK = ~CLK;
end

initial begin
    #80_000;
    $display("[80us] mepc=%08h mcause=%08h mtval=%08h trap_count=%0d pc=%08h",
        rdword(32'hE00), rdword(32'hE04), rdword(32'hE08), rdword(32'hE0C),
        CPU.IFStage.PCReg.PCAddr);
    #220_000;
    $display("[300us] mepc=%08h mcause=%08h mtval=%08h trap_count=%0d pc=%08h",
        rdword(32'hE00), rdword(32'hE04), rdword(32'hE08), rdword(32'hE0C),
        CPU.IFStage.PCReg.PCAddr);
    $finish;
end

endmodule
