.section .text
.globl _start

_start:
    jal x1, t
    addi x6, x0, 1
y:
    addi x2, x0, 1
    jal x5, flag
    addi x7, x0, 1
t:
    addi x3, x0, 1
    jal x4, y
    addi x8, x0, 1

flag:
    j flag
