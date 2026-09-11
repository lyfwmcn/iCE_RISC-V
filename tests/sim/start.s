.section .text.boot
.globl _start

_start:
	la sp, stack_top
	call main
1:
    j 1b
