# 实验 c：后向 J `j .`（PredTaken=1，嫌疑路径：预测 taken 的重定向语义）。
# 若嫌疑成立：jal 永不重定向，PC 顺序落到 loop+4 的全零区 -> 非法陷阱。
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
    j loop
