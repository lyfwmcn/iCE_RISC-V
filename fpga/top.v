`timescale 1ns / 1ns

// iCESugar-Pro (ECP5 LFE5U-25F) 板级顶层：
//   clk_i   P6 25MHz 晶振
//   led_a/b/c 板载 RGB LED（A11/A12/B11，LVCMOS25）
//   uart_tx B9 -> iCELink USB-CDC 虚拟串口
//
// 除时钟与复位产生外，CPU/SystemBus 连接方式与 tb.v 一致；
// report 引擎旁路监视同一组总线请求端口，实现板级"打印结果"。
module top (
    input  wire clk_i,
    output wire led_a,
    output wire led_b,
    output wire led_c,
    output wire uart_tx
);

wire clk_s;
wire rst_s;
assign clk_s = clk_i;

rst_gen rst_inst (
    .clk_i(clk_s),
    .rst_i(1'b0),
    .rst_o(rst_s)
);

// ---- 总线信号（CPU <-> SystemBus，与 tb.v 一致）----
wire Respond_Fault_Data;
wire Respond_Fault_Instr;
wire Respond_Valid_Data;
wire Respond_Valid_Instr;
wire [31:0] Respond_Data_Data;
wire [31:0] Respond_Data_Instr;
wire Request_Valid_Instr;
wire Request_Valid_Data;
wire Request_Write_Data;
wire [3:0] Request_EN_Data;
wire [31:0] Request_Addr_Instr;
wire [31:0] Request_Addr_Data;
wire [31:0] Request_Data_Data;

CPU CPU (
    .CLK(clk_s),
    .RST(rst_s),
    .Respond_Fault_Data(Respond_Fault_Data),
    .Respond_Fault_Instr(Respond_Fault_Instr),
    .Respond_Valid_Data(Respond_Valid_Data),
    .Respond_Valid_Instr(Respond_Valid_Instr),
    .Respond_Data_Data(Respond_Data_Data),
    .Respond_Data_Instr(Respond_Data_Instr),
    .Request_Valid_Data(Request_Valid_Data),
    .Request_Valid_Instr(Request_Valid_Instr),
    .Request_Write_Data(Request_Write_Data),
    .Request_EN_Data(Request_EN_Data),
    .Request_Addr_Data(Request_Addr_Data),
    .Request_Addr_Instr(Request_Addr_Instr),
    .Request_Data_Data(Request_Data_Data)
);

SystemBus SystemBus (
    .CLK(clk_s),
    .RST(rst_s),
    .Request_Valid_Data(Request_Valid_Data),
    .Request_Valid_Instr(Request_Valid_Instr),
    .Request_Write_Data(Request_Write_Data),
    .Request_EN_Data(Request_EN_Data),
    .Request_Addr_Data(Request_Addr_Data),
    .Request_Addr_Instr(Request_Addr_Instr),
    .Request_Data_Data(Request_Data_Data),
    .Respond_Fault_Data(Respond_Fault_Data),
    .Respond_Fault_Instr(Respond_Fault_Instr),
    .Respond_Valid_Data(Respond_Valid_Data),
    .Respond_Valid_Instr(Respond_Valid_Instr),
    .Respond_Data_Data(Respond_Data_Data),
    .Respond_Data_Instr(Respond_Data_Instr)
);

// ---- 板级观测：UART 打印 + RGB LED 状态 ----
wire uart_busy;
wire uart_start;
wire [7:0] uart_data;
wire tx_o;
wire [2:0] led;

report report_inst (
    .clk(clk_s),
    .rst(rst_s),
    .req_valid(Request_Valid_Data),
    .req_write(Request_Write_Data),
    .req_en(Request_EN_Data),
    .req_addr(Request_Addr_Data),
    .req_data(Request_Data_Data),
    .uart_busy(uart_busy),
    .uart_start(uart_start),
    .uart_data(uart_data),
    .led(led)
);

uart_tx #(.DIV(25_000_000 / 115_200)) uart_inst (
    .clk(clk_s),
    .rst(rst_s),
    .start(uart_start),
    .data(uart_data),
    .busy(uart_busy),
    .tx(tx_o)
);

assign led_a  = led[0];
assign led_b  = led[1];
assign led_c  = led[2];
assign uart_tx = tx_o;

endmodule
