BITS 16
ORG 0x7C00

_start:
    CLI
    XOR AX, AX
    MOV DS, AX
    MOV ES, AX
    MOV FS, AX
    MOV GS, AX
    MOV SS, AX
    MOV SP, 0x7BFF
    STI

    MOV AH, 0x00
    MOV AL, 0x03
    INT 0x10

    MOV SI, boot_message
    CALL print

    MOV AH, 0x02
    MOV AL, 0x20
    MOV CH, 0x00
    MOV CL, 0x02
    MOV DH, 0x00
    MOV DL, 0x80
    MOV BX, 0x0500
    INT 0x13

    JC .error

    MOV SI, jump_message
    CALL print

    JMP 0x0000:0x0500

    .error:
    MOV SI, loading_failed_message
    CALL print
    JMP $


boot_message DB "Booting from HDD (0x80)...", 0x0A, 0x0D, 0x00
loading_message DB "Loading bootloader (16kB) to 0x0000:0x0500 ...", 0x0A, 0x0D, 0x00
loading_failed_message DB "Failed to load bootloader from disk. Aborting.", 0x00
jump_message DB "Jumping to bootloader at 0x0000:0x0500 ...", 0x0A, 0x0D, 0x00

print:
    LODSB
    TEST AL, AL
    JZ .done

    MOV AH, 0x0E
    MOV BH, 0x00
    INT 0x10
    JMP print

    .done:
    RET

TIMES 510 - ($ - $$) DB 0x00
DW 0xAA55