# 实验 b：前向 taken 分支 `beq x0,x0,.`（imm[31]=0 -> PredTaken=0，走 M2 实际裁决路径）。
# 预期(若实际裁决正常)：PC 停在该 beq 自循环，无陷阱。
.section .text
.globl _start
_start:
    li t6, 0x200
    csrw mtvec, t6
    nop
    nop
    nop
    nop
loop:
    beq x0, x0, loop
