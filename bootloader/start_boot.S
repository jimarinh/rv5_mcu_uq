.section .text
.globl _start
.globl reset_vec
.globl boot_main

reset_vec:
_start:
    // RAM válida: 0x10000000 .. 0x1001FFFF
    // SP dentro y alineado (16 bytes)
    lui  x2, 0x10020        // x2 = 0x10020000
    addi x2, x2, -16        // x2 = 0x1001FFF0

    jal  x1, boot_main

1:
    jal  x0, 1b

