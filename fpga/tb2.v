`timescale 1ns / 1ns
// 隔离实验：只有 CPU + SystemBus，无任何板级观测模块，验证 prog 能否跑到底。
module tb2;
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

integer trap=0;
always @(posedge CLK) begin
  if (CPU.Trap) begin
    trap=trap+1;
    if(trap<=4)
      $display("T%0t TRAP mc=%h mepc=%h mtval=%h EXpc=%h EXin=%08h", $time,
        CPU.CSRFile.mcause,CPU.CSRFile.mepc,CPU.CSRFile.mtval,CPU.EXPC,CPU.EXInstr);
  end
end

reg [63:0] n88=0;
always @(posedge CLK) if (CPU.IFStage.PCReg.PCAddr==32'h88) n88<=n88+1;

initial begin RST=1; #5 RST=0; #5 CLK=0; forever #5 CLK=~CLK; end
initial begin
  #300_000;
  $display("end trap=%0d pc88=%0d memF00=%02x%02x%02x%02x x1=%h pc=%h mc=%h",
    trap, n88, SB.mem[16'hF00],SB.mem[16'hF01],SB.mem[16'hF02],SB.mem[16'hF03],
    CPU.RegFile.regs[1], CPU.IFStage.PCReg.PCAddr, CPU.CSRFile.mcause);
  $finish;
end
endmodule
