.section .text.boot
.globl _start

_start:
	la sp, stack_top
	call main
	csrr t0, mcycle
	nop
	nop
	nop
	csrr t1, minstret
1:
    j 1b
