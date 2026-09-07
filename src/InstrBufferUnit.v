`timescale 1ns / 1ns

module InstrBufferUnit (
    input CLK,
    input RST,
    input Flush,
    input Request_Valid_Instr,
    input Respond_Fault_Instr,
    input Respond_Valid_Instr,
    input Stall,
    input [31:0] Request_Addr_Instr,
    input [31:0] Respond_Data_Instr,
    output Empty,
    output Full,
    output InstrFault,
    output [31:0] Instr,
    output [31:0] PC
);

// 目前还没收到响应的请求
reg [31:0] PendingRequests [7:0];
reg [3:0] PendingRequestsReadPos;
reg [3:0] PendingRequestsWritePos;
wire [3:0] PendingRequestsCount;
// 目前挂起请求总量
assign PendingRequestsCount = PendingRequestsWritePos - PendingRequestsReadPos;

// 目前要丢弃多少挂起请求的响应
reg [3:0] TrashRequestsCount;

// 响应数据缓冲区
reg [31:0] PCBuffer [7:0];
reg InstrFaultBuffer [7:0];
reg [31:0] InstrBuffer [7:0];
reg [3:0] BufferReadPos;
reg [3:0] BufferWritePos;
// 缓冲区响应数据总量
wire [3:0] BufferCount;
assign BufferCount = BufferWritePos - BufferReadPos;

assign Empty = BufferCount == 4'h0;
assign Full = BufferCount + PendingRequestsCount >= 4'h8;
assign InstrFault = Empty ? 1'h0 : InstrFaultBuffer[BufferReadPos[2:0]];
assign Instr = Empty ? 32'h13 : InstrBuffer[BufferReadPos[2:0]];
assign PC = Empty ? 32'h0 : PCBuffer[BufferReadPos[2:0]];

// 是否丢弃 / 完成一个请求
wire PendingRequestsRead;
// 是否写入一个请求
wire PendingRequestsWrite;
// 是否从缓冲区读出一个数据
wire BufferRead;
// 是否将响应数据写入缓冲区
wire BufferWrite;
// 是否冲刷缓冲区
wire BufferFlush;
// 是否要丢弃垃圾响应
wire TrashRequestsDeal;
assign PendingRequestsRead = Respond_Valid_Instr;
assign PendingRequestsWrite = Request_Valid_Instr && !Flush && (!Full || (!BufferWrite && (PendingRequestsRead || BufferRead)) || (BufferWrite && PendingRequestsRead && BufferRead));
assign BufferRead = !Empty && !Stall;
assign BufferWrite = Respond_Valid_Instr && TrashRequestsCount == 4'h0 && !Flush && (BufferCount < 4'h8 || BufferRead);
assign BufferFlush = Flush;
assign TrashRequestsDeal = Respond_Valid_Instr && TrashRequestsCount > 4'h0;

integer i;
always @(posedge CLK or posedge RST) begin
    if (RST) begin
        for (i = 0; i < 8; i = i + 1) begin
            PendingRequests[i] <= 32'h0;
        end
        PendingRequestsReadPos <= 4'h0;
        PendingRequestsWritePos <= 4'h0;
        TrashRequestsCount <= 4'h0;
        for (i = 0; i < 8; i = i + 1) begin
            PCBuffer[i] <= 32'h0;
        end
        for (i = 0; i < 8; i = i + 1) begin
            InstrFaultBuffer[i] <= 1'h0;
        end
        for (i = 0; i < 8; i = i + 1) begin
            InstrBuffer[i] <= 32'h0;
        end
        BufferReadPos <= 4'h0;
        BufferWritePos <= 4'h0;
    end
    else begin
        if (PendingRequestsWrite) begin
            PendingRequests[PendingRequestsWritePos[2:0]] <= Request_Addr_Instr;
            PendingRequestsWritePos <= PendingRequestsWritePos + 4'h1;
        end
        if (PendingRequestsRead) begin
            PendingRequestsReadPos <= PendingRequestsReadPos + 4'h1;
        end
        if (BufferFlush) begin
            BufferWritePos <= BufferReadPos;
            TrashRequestsCount <= PendingRequestsWrite && !PendingRequestsRead ? PendingRequestsCount + 4'h1 :
                                  !PendingRequestsWrite && PendingRequestsRead ? PendingRequestsCount - 4'h1 :
                                  PendingRequestsCount;
        end
        else begin
            if (TrashRequestsDeal) begin
                TrashRequestsCount <= TrashRequestsCount - 4'h1;
            end
            if (BufferWrite) begin
                InstrFaultBuffer[BufferWritePos[2:0]] <= Respond_Fault_Instr;
                InstrBuffer[BufferWritePos[2:0]] <= Respond_Data_Instr;
                PCBuffer[BufferWritePos[2:0]] <= PendingRequests[PendingRequestsReadPos[2:0]];
                BufferWritePos <= BufferWritePos + 4'h1;
            end
            if (BufferRead) begin
                BufferReadPos <= BufferReadPos + 4'h1;
            end
        end
    end
end

endmodule
