.section .text
.globl _start

_start:
    addi x1, x0, 0
    beq x1, x0, t
    addi x2, x0, 1
t:
    addi x1, x0, 0
    bne x1, x0, u
    addi x3, x0, 1
u:
    addi x1, x0, -1
    blt x1, x0, w
    addi x4, x0, 1
w:
    addi x1, x0, -1
    bge x0, x1, p
    addi x5, x0, 1
p:
    addi x1, x0, -1
    bltu x0, x1, q
    addi x6, x0, 1
q:
    addi x1, x0, -1
    bgeu x0, x1, flag
    addi x7, x0, 1

flag:
    j flag
