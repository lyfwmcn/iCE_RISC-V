`timescale 1ns / 1ns

// 板上复位产生：配置完成后保持复位若干周期再释放（iCE 板无复位按键）。
// rst_o 高有效，与 CPU/SystemBus 的异步复位一致。
module rst_gen (
    input clk_i,
    input rst_i,
    output rst_o
);

/* try to generate a reset */
reg [2:0] rst_cpt = 3'b0;
always @(posedge clk_i) begin
    if (rst_i)
        rst_cpt = 3'b0;
    else begin
        if (rst_cpt == 3'b100)
            rst_cpt = rst_cpt;
        else
            rst_cpt = rst_cpt + 3'h1;
    end
end

assign rst_o = !rst_cpt[2];

endmodule
