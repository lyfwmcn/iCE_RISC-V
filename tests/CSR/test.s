.section .text
.globl _start

_start:
    csrrwi x1, mstatus, 31
    csrrs x2, mstatus, x0

    csrrsi x3, mcycle, 0

flag:
    j flag
