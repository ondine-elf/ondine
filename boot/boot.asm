BITS 16 ; Initial boot is 16-bit Real Mode
ORG 0x7C00 ; BIOS loads bootloader at 0x7C00

_start:
    CLI ; Disable interrupts
    XOR AX, AX ; Clear AX (= 0) and clear segment registers for linear memory addressing
    MOV DS, AX
    MOV ES, AX
    MOV FS, AX
    MOV GS, AX
    MOV SS, AX
    MOV SP, 0x7BFF ; Move stack pointer to top of first block of conventional memory
    STI ; Resume interrupts

    ; Set video mode to 0x03
    MOV AH, 0x00
    MOV AL, 0x03
    INT 0x10

    ; Display boot message
    MOV SI, boot_message
    CALL print

    ; Load in kernel from disk (assuming it is a 16kB binary)
    MOV AH, 0x02
    MOV AL, 0x20
    MOV CH, 0x00
    MOV CL, 0x02
    MOV DH, 0x00
    MOV DL, 0x80
    MOV BX, 0x0500
    INT 0x13

    ; Jump to error routine if reading kernel from disk fails
    JC .error

    ; Display message for jumping to kernel
    MOV SI, jump_message
    CALL print

    ; Jump to kernel
    JMP 0x0000:0x0500

    ; Error handler for if disk-read fails
    .error:
    MOV SI, loading_failed_message
    CALL print
    JMP $


boot_message DB "Booting from HDD (0x80)...", 0x0A, 0x0D, 0x00
loading_message DB "Loading kernel (16kB) to 0x0000:0x0500 ...", 0x0A, 0x0D, 0x00
loading_failed_message DB "Failed to load kernel from disk. Aborting.", 0x00
jump_message DB "Jumping to kernel at 0x0000:0x0500 ...", 0x0A, 0x0D, 0x00

; Routine for printing strings (null-terminated)
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