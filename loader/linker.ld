OUTPUT_FORMAT("binary")

ENTRY(_start)

SECTIONS {
    . = 0x0500;

    .text : {
        build/loader/entry.o(.text)
        *(.text)
    }

    .data : {
        *(.data)
    }

    .rodata : {
        *(.rodata)
    }

    .bss : {
        *(.bss)
    }
}