.section .text
.globl _start

_start:
    # 计算若干结果
    addi x1, x0, 32
    sw x1, 100(x0)
    lw x2, 100(x0)
    addi x3, x0, -1
    slli x4, x3, 4
    addi x5, x0, 0x55
    addi x6, x0, 0x0F

    nop
    nop
    nop

    # 快照 x1..x6 -> 报告区 0xE00 + 4k
    li t3, 0xE00
    sw x1,  0(t3)
    sw x2,  4(t3)
    sw x3,  8(t3)
    sw x4, 12(t3)
    sw x5, 16(t3)
    sw x6, 20(t3)

    # 完成信箱：写 0xF00，触发板上引擎 dump + PASS
    li t4, 0xF00
    sw x0, 0(t4)

flag:
    j flag
