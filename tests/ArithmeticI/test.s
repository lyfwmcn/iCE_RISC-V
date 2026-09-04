.section .text
.globl _start

_start:
    # addi
    nop
    addi x1, x0, 1
    addi x2, x1, 1

    # slli
    addi x3, x0, 1
    slli x3, x3, 4
    slli x4, x3, 1

    # slti
    addi x5, x0, 0
    slti x5, x5, 0
    addi x6, x0, -1
    slti x6, x6, 0
    addi x7, x0, 0
    slti x7, x7, -1

    # sltiu
    addi x8, x0, 0
    sltiu x8, x8, 0
    addi x9, x0, -1
    sltiu x9, x9, 0
    addi x10, x0, 0
    sltiu x10, x10, -1

    # xori
    

flag:
    j flag
