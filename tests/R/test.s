.section .text
.globl _start

_start:
    # add
    addi x1, x0, 1
    addi x2, x0, 2
    add x1, x1, x2

flag:
    j flag
