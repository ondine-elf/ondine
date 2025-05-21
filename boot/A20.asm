; Code taken from https://wiki.osdev.org/A20_Line#Fast_A20_Gate

BITS 16

SECTION .text
    GLOBAL enable_A20

get_A20_state:
    ; Push flags register and index registers
    PUSHF
    PUSH SI
    PUSH DI
    PUSH DS
    PUSH ES
    CLI

    ; DS:SI = 0x0000:0x0500
    MOV AX, 0x0000
    MOV DS, AX
    MOV SI, 0x0500

    ; ES:DI = 0x100500 = DS:SI + 1MB
    NOT AX
    MOV ES, AX
    MOV DI, 0x0510

    ; Save original values of DS:SI and ES:DI
    MOV AL, [DS:SI]
    MOV BYTE [BufferBelowMB], AL
    MOV AL, [ES:DI]
    MOV BYTE [BufferOverMB], AL

    ; Compare 0x0000:0x0500 and +1MB . If they're not equal,
    ; decrement AH to 0x00 and exit.
    MOV AH, 0x01
    MOV BYTE [DS:SI], 0x00
    MOV BYTE [ES:DI], 0x01
    MOV AL, [DS:SI]
    CMP AL, [ES:DI]
    JNE .exit
    DEC AH

    ; Restore original memory values and return registers'
    ; original state from stack.
    .exit:
    MOV AL, [BufferBelowMB]
    MOV [DS:SI], AL
    MOV AL, [BufferOverMB]
    MOV [ES:DI], AL
    SHR AX, 0x08
    STI
    POP ES
    POP DS
    POP DI
    POP SI
    POPF
    RET

query_A20_support:
    ; Push BX onto stack as it stores result
    PUSH BX
    CLC

    ; Query A20 support with BIOS
    MOV AX, 0x2403
    INT 0x15
    JC .error

    ; Test if BIOS interrupt failed
    TEST AH, AH
    JNZ .error

    ; Move the result into AX and restore BX
    MOV AX, BX
    POP BX
    RET

    ; Set carry flag and restore BX
    .error:
    STC
    POP BX
    RET

enable_A20_keyboard_controller:
    CLI

    ; .wait_io1 tests if the input buffer is full or empty. If it is full,
    ; it calls itself as it must be clear before writing to 0x60 or 0x64 .
    ; In other words, .wait_io1 waits for the input buffer to be empty.

    ; .wait_io2 tests if the output buffer is full or empty. If it is empty,
    ; it calls itself as it must be full before reading to 0x60 .
    ; In other words, .wait_io2 waits for the output buffer to be full.

    ; Disable PS/2 port
    CALL .wait_io1
    MOV AL, 0xAD
    OUT 0x64, AL

    ; Read controller output (command)
    CALL .wait_io1
    MOV AL, 0xD0
    OUT 0x64, AL

    ; Read in the controller output and push onto stack
    CALL .wait_io2
    IN AL, 0x60
    PUSH EAX

    ; Write the next byte sent to the output port (command)
    CALL .wait_io1
    MOV AL, 0xD1
    OUT 0x64, AL

    ; Fetch old output port, enable the A20 bit, and write to current
    ; output port.
    CALL .wait_io1
    POP EAX
    OR AL, 0x02
    OUT 0x60, AL

    ; Enable PS/2 port
    CALL .wait_io1
    MOV AL, 0xAE
    OUT 0x64, AL

    ; Make sure input buffer is empty (ready to accept new data)
    CALL .wait_io1
    STI
    RET

    .wait_io1:
    IN AL, 0x64
    TEST AL, 0x02
    JNZ .wait_io1
    RET

    .wait_io2:
    IN AL, 0x64
    TEST AL, 0x01
    JZ .wait_io2
    RET

enable_A20:
    ; Clear carry and push all general-purpose registers
    CLC
    PUSHA
    MOV BH, 0x00 ; Used as an attempt counter

    CALL get_A20_state
    ; JC .fast_gate (Bug in OSDEV code)

    TEST AX, AX
    JNZ .done

    ; AL is current 0x00 . If query_A20_support succeeds and
    ; bit 1 is set, then the keyboard controller supports it, so try that.
    CALL query_A20_support
    MOV BL, AL
    TEST BL, 0x01
    JNZ .keyboard_controller

    ; If query_A20_support succeeds and bit 2 is set, then
    ; the fast gate is supported to try that.
    TEST BL, 0x02
    JNZ .fast_gate

    ; If the query A20 support failed, try the directo enabling with
    ; BIOS 0x2401 .
    .bios_int:
    MOV AX, 0x2401
    INT 0x15
    JC .fast_gate
    TEST AH, AH
    JNZ .failed
    CALL get_A20_state
    TEST AX, AX
    JNZ .done

    ; Set the second bit of port 0x92 which enables A20, and then set
    ; bit 1 to 0 which prompts a CPU reset.
    .fast_gate:
    IN AL, 0x92
    TEST AL, 0x02
    JNZ .done

    OR AL, 0x02
    AND AL, 0xFE
    OUT 0x92, AL

    CALL get_A20_state
    TEST AX, AX
    JNZ .done

    ; If keyboard controller has already been tried, fail.
    TEST BH, BH
    JNZ .failed

    .keyboard_controller:
    CALL enable_A20_keyboard_controller
    CALL get_A20_state
    TEST AX, AX
    JNZ .done

    ; If the keyboard controller failed, set the attempt counter to 1
    ; and try to use the fast gate (0x92) if it's supported.
    MOV BH, 0x01
    TEST BL, 0x02
    JNZ .fast_gate
    JMP .failed

    .failed:
    STC

    .done:
    POPA
    RET

SECTION .bss
    BufferBelowMB: RESB 1
    BufferOverMB:  RESB 1