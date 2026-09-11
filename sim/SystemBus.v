`timescale 1ns / 1ns

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

reg [7:0] mem [4095:0];

integer i;
integer fd;
integer r;
initial begin
    for (i = 0; i < 4096; i = i + 1)
        mem[i] = 8'h0;
    fd = $fopen("build/sim_test.bin", "rb");
    if(fd == 0) begin
        $display("ERROR: cannot open build/sim_test.bin");
        $finish;
    end
    r = $fread(mem, fd);
    $fclose(fd);
end

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
        Request_Addr_Data_Reg <= 32'h0;
        Request_Addr_Instr_Reg <= 32'h0;
        Request_Data_Data_Reg <= 32'h0;
    end
    else begin
        Request_Valid_Data_Reg <= Request_Valid_Data;
        Request_Valid_Instr_Reg <= Request_Valid_Instr;
        Request_Write_Data_Reg <= Request_Write_Data;
        Request_EN_Data_Reg <= Request_EN_Data;
        Request_Addr_Data_Reg <= Request_Addr_Data;
        Request_Addr_Instr_Reg <= Request_Addr_Instr;
        Request_Data_Data_Reg <= Request_Data_Data;
    end
end

always @(posedge CLK or posedge RST) begin
    if (RST) begin
        Respond_Valid_Instr <= 1'h0;
        Respond_Fault_Instr <= 1'h0;
        Respond_Data_Instr <= 32'h13;
    end
    else begin
        Respond_Valid_Instr <= Request_Valid_Instr_Reg;
        Respond_Fault_Instr <= Request_Valid_Instr_Reg ?
                               Request_Addr_Instr_Reg[1:0] != 2'h0 || Request_Addr_Instr_Reg[31:12] != 20'h0 :
                               1'h0;
        Respond_Data_Instr <= Request_Valid_Instr_Reg && !Respond_Fault_Instr ?
                              {mem[{Request_Addr_Instr_Reg[31:2], 2'h3}],
                              mem[{Request_Addr_Instr_Reg[31:2], 2'h2}],
                              mem[{Request_Addr_Instr_Reg[31:2], 2'h1}],
                              mem[{Request_Addr_Instr_Reg[31:2], 2'h0}]} :
                              32'h13;
    end
end

always @(posedge CLK or posedge RST) begin
    if (RST) begin
        Respond_Valid_Data <= 1'h0;
        Respond_Fault_Data <= 1'h0;
        Respond_Data_Data <= 32'h0;
    end
    else begin
        Respond_Valid_Data <= Request_Valid_Data_Reg;
        Respond_Fault_Data <= Request_Valid_Data_Reg ? Request_Addr_Data_Reg[1:0] != 2'h0 || Request_Addr_Data_Reg[31:12] != 20'h0 : 1'h0;
        Respond_Data_Data <= Request_Valid_Data_Reg && !Request_Write_Data ?
                             {mem[{Request_Addr_Data_Reg[31:2], 2'h3}],
                             mem[{Request_Addr_Data_Reg[31:2], 2'h2}],
                             mem[{Request_Addr_Data_Reg[31:2], 2'h1}],
                             mem[{Request_Addr_Data_Reg[31:2], 2'h0}]} :
                             32'h0;
    end
end

always @(posedge CLK) begin
    if (Request_Valid_Data_Reg && Request_Write_Data_Reg &&
        Request_Addr_Data_Reg[1:0] == 2'h0 && Request_Addr_Data_Reg[31:12] == 20'h0) begin
        if (Request_Addr_Data_Reg == 32'hffc &&
            (Request_EN_Data_Reg[0] || Request_EN_Data_Reg[1] ||
            Request_EN_Data_Reg[2] || Request_EN_Data_Reg[3])) begin
            $write("%c", Request_Data_Data_Reg[7:0]);
        end
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
    end
end

endmodule
