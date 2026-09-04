`timescale 1ns / 1ns

// 支持综合成 ECP5 真双端口 EBR（DP16KD）的存储结构。
// 32bit 字按字节拆进 9bit lane（第 9 位闲置），两块 18bit EBR 各存两个字(节)：
//   mem0[w][8:0]   = 字 w 的字节 0（字节地址 4w  ）
//   mem0[w][17:9]  = 字 w 的字节 1（字节地址 4w+1）
//   mem1[w][8:0]   = 字 w 的字节 2（字节地址 4w+2）
//   mem1[w][17:9]  = 字 w 的字节 3（字节地址 4w+3）
// EBR 的字节使能粒度是 9bit，因此 8bit 字节必须放进 9bit lane 才能对上写使能。
// 每块 EBR 综合为 DP16KD 真双端口：端口 A 做数据读写（load 读 / store 写，互斥），
// 端口 B 做取指只读。
// 只支持对齐访问
module SystemBus (
    input CLK,
    input RST,
    input Request_Valid_Data,
    input Request_Valid_Instr,
    input Request_Write_Data,
    input [3:0] Request_EN_Data,
    input [31:0] Request_Addr_Data,
    input [31:0] Request_Addr_Instr,
    input [31:0] Request_Data_Data,
    output reg Respond_Fault_Data,
    output reg Respond_Fault_Instr,
    output reg Respond_Valid_Data,
    output reg Respond_Valid_Instr,
    output reg [31:0] Respond_Data_Data,
    output reg [31:0] Respond_Data_Instr
);

// 0 ~ 2^12 - 1（按字索引，字宽 32bit，容量仍为 4KB）
reg [17:0] mem0 [1023:0];
reg [17:0] mem1 [1023:0];

// synthesis translate_off
// 仿真用的字节视图：初值由 bin/test 载入，store 时与 mem0/mem1 同步镜像，供 tb 直接读字节。
reg [7:0] mem [4095:0];
integer i;
integer fd;
integer ret;
initial begin
    for (i = 0; i < 4096; i = i + 1)
        mem[i] = 8'h0;
    for (i = 0; i < 1024; i = i + 1) begin
        mem0[i] = 18'h0;
        mem1[i] = 18'h0;
    end
    fd = $fopen("bin/test", "rb");

    if (fd == 0) begin
        $display("Failed to open test");
        $finish;
    end

    ret = $fread(mem, fd);

    $fclose(fd);

    for (i = 0; i < 1024; i = i + 1) begin
        mem0[i] = {1'h0, mem[4*i+1], 1'h0, mem[4*i]};
        mem1[i] = {1'h0, mem[4*i+3], 1'h0, mem[4*i+2]};
    end
end
// synthesis translate_on

reg Request_Valid_Data_Reg;
reg Request_Valid_Instr_Reg;
reg Request_Write_Data_Reg;
reg [3:0] Request_EN_Data_Reg;
reg [31:0] Request_Addr_Data_Reg;
reg [31:0] Request_Addr_Instr_Reg;
reg [31:0] Request_Data_Data_Reg;

always @(posedge CLK or posedge RST) begin
    if (RST) begin
        Request_Valid_Data_Reg <= 1'h0;
        Request_Valid_Instr_Reg <= 1'h0;
        Request_Write_Data_Reg <= 1'h0;
        Request_EN_Data_Reg <= 4'h0;
    end
    else begin
        Request_Valid_Data_Reg <= Request_Valid_Data;
        Request_Valid_Instr_Reg <= Request_Valid_Instr;
        Request_Write_Data_Reg <= Request_Write_Data;
        Request_EN_Data_Reg <= Request_EN_Data;
    end
end

// 地址/写数据寄存器不作异步复位：它们会被 EBR 吸收为内部地址/数据输入寄存器，
// yosys 不接受带异步复位（或置位）的 BRAM 地址寄存器。
always @(posedge CLK) begin
    Request_Addr_Data_Reg <= Request_Addr_Data;
    Request_Addr_Instr_Reg <= Request_Addr_Instr;
    Request_Data_Data_Reg <= Request_Data_Data;
end

wire Respond_Fault_Data_Wire;
wire Respond_Fault_Instr_Wire;
wire Respond_Valid_Data_Wire;
wire Respond_Valid_Instr_Wire;
wire [31:0] Respond_Data_Data_Wire;
wire [31:0] Respond_Data_Instr_Wire;

assign Respond_Fault_Data_Wire = Request_Addr_Data_Reg[1:0] != 2'h0 || Request_Addr_Data_Reg[31:12] != 20'h0;
assign Respond_Fault_Instr_Wire = Request_Addr_Instr_Reg[1:0] != 2'h0 || Request_Addr_Instr_Reg[31:12] != 20'h0;
assign Respond_Valid_Data_Wire = Request_Valid_Data_Reg;
assign Respond_Valid_Instr_Wire = Request_Valid_Instr_Reg;

// 数据字与取指字的 32bit 拼装（字节 3 在最高位，与原 {mem[A+3],..,mem[A]} 一致）
wire [31:0] DataWord;
wire [31:0] InstrWord;
assign DataWord = {mem1[Request_Addr_Data_Reg[11:2]][16:9],
                   mem1[Request_Addr_Data_Reg[11:2]][7:0],
                   mem0[Request_Addr_Data_Reg[11:2]][16:9],
                   mem0[Request_Addr_Data_Reg[11:2]][7:0]};
assign InstrWord = {mem1[Request_Addr_Instr_Reg[11:2]][16:9],
                    mem1[Request_Addr_Instr_Reg[11:2]][7:0],
                    mem0[Request_Addr_Instr_Reg[11:2]][16:9],
                    mem0[Request_Addr_Instr_Reg[11:2]][7:0]};

assign Respond_Data_Data_Wire = Request_Write_Data_Reg ? 32'h0 :
                                {Request_EN_Data_Reg[3] ? DataWord[31:24] : 8'h0,
                                Request_EN_Data_Reg[2] ? DataWord[23:16] : 8'h0,
                                Request_EN_Data_Reg[1] ? DataWord[15:8] : 8'h0,
                                Request_EN_Data_Reg[0] ? DataWord[7:0] : 8'h0};
assign Respond_Data_Instr_Wire = InstrWord;

// store：只在对齐且落在 0x0~0xFFF 内时按字节使能写（错位/越界按访问故障处理，不落盘）
always @(posedge CLK) begin
    if (Request_Valid_Data_Reg && Request_Write_Data_Reg &&
        Request_Addr_Data_Reg[1:0] == 2'h0 && Request_Addr_Data_Reg[31:12] == 20'h0) begin
        if (Request_EN_Data_Reg[0]) begin
            mem0[Request_Addr_Data_Reg[11:2]][8:0] <= {1'b0, Request_Data_Data_Reg[7:0]};
        end
        if (Request_EN_Data_Reg[1]) begin
            mem0[Request_Addr_Data_Reg[11:2]][17:9] <= {1'b0, Request_Data_Data_Reg[15:8]};
        end
        if (Request_EN_Data_Reg[2]) begin
            mem1[Request_Addr_Data_Reg[11:2]][8:0] <= {1'b0, Request_Data_Data_Reg[23:16]};
        end
        if (Request_EN_Data_Reg[3]) begin
            mem1[Request_Addr_Data_Reg[11:2]][17:9] <= {1'b0, Request_Data_Data_Reg[31:24]};
        end
        // synthesis translate_off
        if (Request_EN_Data_Reg[0]) begin
            mem[{Request_Addr_Data_Reg[31:2], 2'h0}] <= Request_Data_Data_Reg[7:0];
        end
        if (Request_EN_Data_Reg[1]) begin
            mem[{Request_Addr_Data_Reg[31:2], 2'h1}] <= Request_Data_Data_Reg[15:8];
        end
        if (Request_EN_Data_Reg[2]) begin
            mem[{Request_Addr_Data_Reg[31:2], 2'h2}] <= Request_Data_Data_Reg[23:16];
        end
        if (Request_EN_Data_Reg[3]) begin
            mem[{Request_Addr_Data_Reg[31:2], 2'h3}] <= Request_Data_Data_Reg[31:24];
        end
        // synthesis translate_on
    end
end

always @(posedge CLK or posedge RST) begin
    if (RST) begin
        Respond_Fault_Instr <= 1'h0;
        Respond_Valid_Instr <= 1'h0;
        Respond_Data_Instr <= 32'h0;
    end
    else if (Request_Valid_Instr_Reg) begin
        Respond_Fault_Instr <= Respond_Fault_Instr_Wire;
        Respond_Valid_Instr <= Respond_Valid_Instr_Wire;
        Respond_Data_Instr <= Respond_Data_Instr_Wire;
    end
end

always @(posedge CLK or posedge RST) begin
    if (RST) begin
        Respond_Fault_Data <= 1'h0;
        Respond_Valid_Data <= 1'h0;
        Respond_Data_Data <= 32'h0;
    end
    else if (Request_Valid_Data_Reg) begin
        Respond_Fault_Data <= Respond_Fault_Data_Wire;
        Respond_Valid_Data <= 1'h1;
        Respond_Data_Data <= Respond_Data_Data_Wire;
    end
    else begin
        Respond_Fault_Data <= 1'h0;
        Respond_Valid_Data <= 1'h0;
        Respond_Data_Data <= 32'h0;
    end
end

endmodule
