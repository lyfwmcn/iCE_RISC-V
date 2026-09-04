.section .text
.globl _start

_start:
    lui x1, 0x9234a
    addi x1, x1, 0x678
    sw x1, 100(x0)

    # lb
    lb x2, 100(x0)
    lb x3, 101(x0)

    # lh
    lh x4, 102(x0)

    # lw
    lw x5, 100(x0)

    # lbu
    lbu x6, 100(x0)
    lbu x7, 101(x0)

    # lhu
    lhu x8, 102(x0)

flag:
    j flag
