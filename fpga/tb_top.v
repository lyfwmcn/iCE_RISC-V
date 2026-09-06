`timescale 1ns / 1ps

// 板级 top 的仿真验证：时钟 40ns(25MHz)，直接对 UART 引脚按 115200 采样，
// 把 report 引擎打印的文本抓下来，验证 CPU 程序 → 报告区 → dump → PASS 全链路。
module tb_top;

reg clk = 0;
always #20 clk = ~clk;

wire led_a, led_b, led_c, uart_tx;

top dut (
    .clk_i(clk),
    .led_a(led_a),
    .led_b(led_b),
    .led_c(led_c),
    .uart_tx(uart_tx)
);

localparam real BIT = 1e9 / 115200.0;   // ~8680.6 ns

reg [7:0] cap [0:1023];
integer ccnt = 0;

task receive_byte;
    output [7:0] b;
    integer i;
    begin
        @(negedge uart_tx);          // 起始位
        #(BIT / 2);                  // 采到起始位中点
        b = 0;
        for (i = 0; i < 8; i = i + 1) begin
            #BIT;
            b[i] = uart_tx;
        end
        #BIT;                        // 跳过停止位
    end
endtask

reg [7:0] rx;
initial begin
    ccnt = 0;
    forever begin
        receive_byte(rx);
        if (ccnt < 1024) begin
            cap[ccnt] = rx;
            ccnt = ccnt + 1;
        end
    end
end

integer k;
integer tx_edges = 0;
reg mailbox_seen = 0;
reg [63:0] n_fault = 0;
reg [63:0] n_pc88 = 0, n_pc8c = 0, n_pc00 = 0, n_pc30 = 0;
always @(posedge clk) begin
    if (dut.Respond_Fault_Data) n_fault <= n_fault + 1;
    if (dut.Request_Valid_Data && dut.Request_Write_Data && dut.Request_Addr_Data == 32'hF00)
        mailbox_seen <= 1;
    case (dut.CPU.IFStage.PCReg.PCAddr)
        32'h00000000: n_pc00 = n_pc00 + 1;
        32'h00000030: n_pc30 = n_pc30 + 1;
        32'h00000088: n_pc88 = n_pc88 + 1;
        32'h0000008c: n_pc8c = n_pc8c + 1;
    endcase
end
always @(negedge uart_tx) tx_edges = tx_edges + 1;
integer trapcnt = 0;
always @(posedge clk) begin
    if (dut.CPU.Trap && trapcnt < 6) begin
        trapcnt = trapcnt + 1;
        $display("TRAP@%0t mc=%h mepc=%h mtval=%h | ID pc=%h in=%08h | EX pc=%h in=%08h | M1 in=%08h | M2 in=%08h",
            $time, dut.CPU.CSRFile.mcause, dut.CPU.CSRFile.mepc, dut.CPU.CSRFile.mtval,
            dut.CPU.IDPC, dut.CPU.IDInstr, dut.CPU.EXPC, dut.CPU.EXInstr,
            dut.CPU.M1Instr, dut.CPU.M2Instr);
    end
end

initial begin
    #200_000;
    $display("T200us: PC=%h rstate=%d led=%b tx_edges=%0d mailbox_seen=%b fault=%0d (pc00=%0d pc30=%0d pc88=%0d pc8c=%0d)",
        dut.CPU.IFStage.PCReg.PCAddr, dut.report_inst.state, {led_c,led_b,led_a}, tx_edges, mailbox_seen,
        n_fault, n_pc00, n_pc30, n_pc88, n_pc8c);
    $display("  mcause=%h mepc=%h mtvec=%h", dut.CPU.CSRFile.mcause, dut.CPU.CSRFile.mepc, dut.CPU.CSRFile.mtvec);
    #800_000;
    $display("T1ms:   PC=%h rstate=%d led=%b tx_edges=%0d mailbox_seen=%b", dut.CPU.IFStage.PCReg.PCAddr, dut.report_inst.state, {led_c,led_b,led_a}, tx_edges, mailbox_seen);
    $display("  mem0xE00..E03=%02x%02x%02x%02x 0xE20..=%02x%02x%02x%02x",
        dut.SystemBus.mem[16'hE00], dut.SystemBus.mem[16'hE01], dut.SystemBus.mem[16'hE02], dut.SystemBus.mem[16'hE03],
        dut.SystemBus.mem[16'hE20], dut.SystemBus.mem[16'hE21], dut.SystemBus.mem[16'hE22], dut.SystemBus.mem[16'hE23]);
    #29_000_000;
    $display("T3ms:  PC=%h rstate=%d led=%b tx_edges=%0d mailbox_seen=%b", dut.CPU.IFStage.PCReg.PCAddr, dut.report_inst.state, {led_c,led_b,led_a}, tx_edges, mailbox_seen);
    $display("=== captured %0d bytes ===", ccnt);
    for (k = 0; k < ccnt; k = k + 1)
        $write("%c", cap[k]);
    $display("");
    $finish;
end

endmodule
