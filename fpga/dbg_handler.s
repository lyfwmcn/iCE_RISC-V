# 陷阱处理器（链接到 0x200，.text.system）：把异常现场写入报告区并触发 mailbox。
#   0xE00 mepc   0xE04 mcause   0xE08 mtval   0xE0C 陷阱计数
# 然后自旋停在处理器内，便于 tb_dbg 读取。
.section .text.system
.globl handler
handler:
    csrr t0, mepc
    li   t1, 0xE00
    sw   t0, 0(t1)
    csrr t0, mcause
    sw   t0, 4(t1)
    csrr t0, mtval
    sw   t0, 8(t1)
    lw   t2, 12(t1)
    addi t2, t2, 1
    sw   t2, 12(t1)
    li   t1, 0xF00
    sw   x0, 0(t1)
spin:
    j spin
