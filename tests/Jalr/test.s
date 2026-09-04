.section .text
.globl _start

_start:
    addi x1, x0, 4
    jalr x2, 8(x1)

    addi x3, x0, 1
    addi x4, x0, 1
flag:
    j flag
