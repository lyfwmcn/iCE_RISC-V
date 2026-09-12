.section .text
.globl trap_entry

trap_entry:
    li t0, 4092
    li t1, 66
    sw t1, 0(t0)
    csrr t2, mepc
    addi t2, t2, 4
    csrw mepc, t2
    mret
