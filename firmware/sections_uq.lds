MEMORY {
    FLASH (rx)  : ORIGIN = 0x30000000, LENGTH = 128K
    SRAM  (rw)  : ORIGIN = 0x10000000, LENGTH = 128K
}

SECTIONS {
    .flash : {
        *(.text)
        *(.rodata)
        *(.rodata.*)
        . = ALIGN(4);
    } > FLASH

    .sram : {
        *(.data)
        *(.sdata)
        *(.bss)
        . = ALIGN(4);
    } > SRAM
}
