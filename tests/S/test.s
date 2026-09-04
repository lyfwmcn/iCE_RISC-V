.section .text
.globl _start

_start:
    # sb
    addi x1, x0, 7
    sb x1, 100(x0)

    # sh
    addi x1, x0, 0x107
    sh x1, 102(x0)

    # sw
    lui x1, 0x12345
    addi x1, x1, 0x678
    sw x1, 104(x0)

flag:
    j flag
