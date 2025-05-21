BITS 16

SECTION .text
    GLOBAL _start
    EXTERN enable_A20
    EXTERN kernel_main

_start:
    call kernel_main


