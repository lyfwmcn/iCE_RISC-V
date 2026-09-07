.section .text
.globl _start

_start:
    addi x1, x0, 0x1EF       # 随便算几个结果
    addi x2, x0, -1
    slli x3, x2, 4           # x3 = 0xfffffff0

    nop
    nop
    nop

    # 板级观测部分
    li   t3, 0xE00
    sw   x1,  0(t3)
    sw   x2,  4(t3)
    sw   x3,  8(t3)

    # 发送信号
    li   t4, 0xF00
    sw   x0, 0(t4)

1:
    j 1b
