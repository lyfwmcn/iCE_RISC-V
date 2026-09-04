.section .text
.globl _start

_start:
    addi x1, x0, 32
    sw x1, 100(x0)
    lw x2, 100(x0)
    nop
    nop
    nop
    nop
    nop

flag:
    j flag
