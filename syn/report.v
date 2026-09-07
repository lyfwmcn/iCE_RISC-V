`timescale 1ns / 1ns

// 板上观测引擎：旁路监视数据总线端口，等价复刻 tb.v 的"打印结果"思路。
//
//  报告区  0xE00 ~ 0xE7F（32 个字）：软件把关注的寄存器/结果 sw 到这里，
//          引擎把每次对齐 store 按字节使能镜像进内部 rep[]。
//  信箱    0xF00           ：软件写一个值表示"完成"。收到后引擎把 rep[] 全部
//          经 UART 以十六进制文本输出（每字一行 8 位 hex + CR+LF），最后输出 PASS。
//
//  LED 语义（实际颜色与引脚映射有关，见 top.lpf）：
//    等待/dump 中 led=001，完成 PASS led=111，超时(FAIL) led 闪烁。
module report (
    input  wire       clk,
    input  wire       rst,
    // 与 SystemBus 相同的总线请求端口（同一拍捕获，与 store 落盘数据一致）
    input  wire       req_valid,
    input  wire       req_write,
    input  wire [3:0] req_en,
    input  wire [31:0] req_addr,
    input  wire [31:0] req_data,
    // UART 侧
    input  wire       uart_busy,
    output reg        uart_start,
    output reg  [7:0] uart_data,
    output reg  [2:0] led
);

localparam WIN_LO = 12'hE00;            // 报告区基地址
localparam WIN_WORDS = 32;              // 报告区字数
localparam MAILBOX   = 32'hF00;         // 完成信箱
localparam WATCHDOG  = 25'd25_000_000;  // 等待 done 的超时（约 1s）

// 字符序列：每字 = 8 个 hex + CR + LF（10 字符）；随后 "PASS\r\n"（6 字符）。
localparam WLINE   = 10;
localparam WIN_LEN = WIN_WORDS * WLINE;      // 320
localparam SEQ_LAST = WIN_LEN + 6 - 1;       // 325，末尾为 PASS 的 LF

localparam S_IDLE = 3'd0;
localparam S_DUMP = 3'd1;
localparam S_OK   = 3'd2;
localparam S_FAIL = 3'd3;

reg [31:0] rep [0:WIN_WORDS-1];
reg [25:0] wcnt;        // IDLE 看门狗
reg [24:0] blink;       // FAIL 闪烁分频
reg [25:0] okcnt;       // PASS 态重发间隔计数
reg [8:0]  seq;         // 输出字符序号
reg [2:0]  state;

wire store_in_win =
    req_valid && req_write &&
    req_addr[31:12] == 20'h0 &&
    req_addr[1:0]   == 2'b0 &&
    req_addr[11:2] >= (WIN_LO >> 2) &&
    req_addr[11:2] <  ((WIN_LO >> 2) + WIN_WORDS);

wire done_wr =
    req_valid && req_write &&
    req_addr == MAILBOX;

wire [9:0] word_idx = req_addr[11:2] - (WIN_LO >> 2);

integer ci;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        for (ci = 0; ci < WIN_WORDS; ci = ci + 1)
            rep[ci] <= 32'h0;
    end
    else if (store_in_win) begin
        if (req_en[0]) rep[word_idx][7:0]   <= req_data[7:0];
        if (req_en[1]) rep[word_idx][15:8]  <= req_data[15:8];
        if (req_en[2]) rep[word_idx][23:16] <= req_data[23:16];
        if (req_en[3]) rep[word_idx][31:24] <= req_data[31:24];
    end
end

function [7:0] nibble2ascii;
    input [3:0] v;
    begin
        nibble2ascii = (v < 4'hA) ? (8'h30 + v) : (8'h41 + (v - 4'hA));
    end
endfunction

// 组合产生当前 seq 对应的 ASCII 字符
reg [7:0] ascii_c;
always @* begin
    ascii_c = 8'h0A;
    if (seq < WIN_LEN) begin
        if (seq % WLINE == 8)
            ascii_c = 8'h0D;   // CR
        else if (seq % WLINE == 9)
            ascii_c = 8'h0A;   // LF
        else
            ascii_c = nibble2ascii((rep[seq / WLINE] >> (4 * (7 - (seq % WLINE)))) & 4'hF);
    end
    else case (seq - WIN_LEN)
        0: ascii_c = 8'h50;   // P
        1: ascii_c = 8'h41;   // A
        2: ascii_c = 8'h53;   // S
        3: ascii_c = 8'h53;   // S
        4: ascii_c = 8'h0D;   // CR
        default: ascii_c = 8'h0A;   // LF
    endcase
end

always @* begin
    uart_start = 1'b0;
    uart_data  = 8'h0;
    if (state == S_DUMP && !uart_busy) begin
        uart_start = 1'b1;
        uart_data  = ascii_c;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= S_IDLE;
        led   <= 3'b000;
        wcnt  <= 26'h0;
        blink <= 25'h0;
        okcnt <= 26'h0;
        seq   <= 9'h0;
    end
    else begin
        blink <= blink + 1'b1;
        case (state)
            S_IDLE: begin
                led <= 3'b000;
                if (done_wr) begin
                    state <= S_DUMP;
                    seq   <= 9'h0;
                    wcnt  <= 26'h0;
                end
                else if (wcnt == WATCHDOG) begin
                    state <= S_FAIL;
                end
                else begin
                    wcnt <= wcnt + 1'b1;
                end
            end
            S_DUMP: begin
                led <= 3'b001;
                if (!uart_busy) begin
                    if (seq == SEQ_LAST) begin
                        state <= S_OK;
                        okcnt <= 26'h0;
                    end
                    else begin
                        seq <= seq + 1'b1;
                    end
                end
            end
            S_OK: begin
                led <= 3'b111;
                okcnt <= okcnt + 1'b1;
                if (okcnt == 25'd25_000_000) begin   // 每 ~1s 重发一次 dump+PASS
                    okcnt <= 26'h0;
                    seq   <= 9'h0;
                    state <= S_DUMP;
                end
            end
            S_FAIL: begin
                led <= blink[24] ? 3'b111 : 3'b000;
            end
        endcase
    end
end

endmodule
