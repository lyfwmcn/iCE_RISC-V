# 实验 a：无任何跳转，顺序执行后落入全零填充区。
# 预期(若零=非法)：首个全零字即非法陷阱，处理器留下 mepc=该字地址、mcause=2。
.section .text
.globl _start
_start:
    li t6, 0x200
    csrw mtvec, t6
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
