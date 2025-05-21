BITS 32

SECTION .text
    GLOBAL _start
    EXTERN kernel_main

_start:
    jmp $