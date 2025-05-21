OUTPUT_FORMAT("binary")

ENTRY(_start)

SECTIONS {
    . = 0x100000;

    .text : {
        build/entry.o(.text)
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