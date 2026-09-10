.section .text.boot
.globl _start
.globl putc

_start:
	la sp, stack_top
	jal ra, main
1:
    j 1b
putc:
	lui t0, 0x1
	addi t0, t0, -4
	sw a0, 0(t0)
	jalr zero, 0(ra)
main:
	addi sp, sp, -16
	sw ra, 12(sp)
	addi s0, sp, 16
	li a0, 65
	jal ra, putc
	li a0, 64
	jal ra, putc
	lw ra, 12(sp)
	addi sp, sp, 16
	jalr zero, 0(ra)
