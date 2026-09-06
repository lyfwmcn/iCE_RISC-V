.section .text
.globl _start

_start:
    addi x1, x0, 0xAA
    sw x1, 100(x0)          # mem[100] = AA（正常主路径标记）
    nop
    nop
loop:
    j loop                  # 无条件 taken 自旋：正确 CPU 永不走到下一句
    # ↓ 只有分支没被重定向（顺序执行 fall-through）才会到达 ↓
    addi x2, x0, 0xBB
    sw x2, 104(x0)          # mem[104] = BB（错误哨兵）
