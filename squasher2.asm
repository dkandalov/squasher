bits 64
default rel

%macro _call 1
		pop     rdx                     ; pop address of the instruction store for the current function/coroutine
		mov     rcx, %%_end
		mov     [rdx], rcx              ; update the instruction store

		mov     rdx, instruction_at_%1
        push    rdx                     ; push address of the instruction store so that the next function/coroutine can update it on exit
        jmp     [instruction_at_%1]
%%_end: nop
%endmacro

SYS_EXIT    equ     0x2000001
SYS_READ    equ     0x2000003
SYS_WRITE   equ     0x2000004
STDIN       equ     0
STDOUT      equ     1

CARD_LEN    equ     80

section .data
instruction_at_WRITE:      dq    WRITE
instruction_at_SQUASHER:   dq    SQUASHER

section .bss
i:              resq    1
card:           resq    CARD_LEN
lastChar:       resq    1
squasherOutput: resq    1


section .text

; --------------------------------------------------------------------------------
READ_CARD:
		mov     rdx, CARD_LEN           ; maximum number of bytes to read
		mov     rsi, card               ; buffer to read into
		mov     rdi, STDIN              ; file descriptor
        mov     rax, SYS_READ
        syscall
        mov     qword [i], 0
	    ret

; --------------------------------------------------------------------------------
NEXT_CHAR:
        mov     rsi, [i]
        mov     rdi, card
        mov     rax, 0
        mov     al, [rdi + rsi]         ; output is stored in rax

        inc     rsi
        mov     [i], rsi

        ret

; --------------------------------------------------------------------------------
SQUASHER:
        call    NEXT_CHAR
        cmp     rax, '*'
        jne     .output_rax

        mov     rbx, rax
        call    NEXT_CHAR
        cmp     rax, '*'
        je      .do_squashing

		mov     [lastChar], rax         ; save rax because its value will be erased by another coroutine
		mov     [squasherOutput], rbx
        _call   WRITE

        mov     rax, [lastChar]
        jmp     .output_rax

.do_squashing:
        mov     rax, '^'

.output_rax:
        mov     [squasherOutput], rax
        _call   WRITE
		jmp     SQUASHER

; --------------------------------------------------------------------------------
WRITE:
        mov     rax, instruction_at_WRITE
        push    rax                     ; prepare stack for coroutine call
.loop:
        _call   SQUASHER

        mov     rdx, 1                  ; message length
        mov     rsi, squasherOutput     ; message to write
        mov     rdi, STDOUT             ; file descriptor
        mov     rax, SYS_WRITE
        syscall

        mov     rax, [i]
        cmp     rax, CARD_LEN
        jne     .loop

		pop     rax                     ; clean stack after coroutine call
        ret

; --------------------------------------------------------------------------------
global  _main
_main:
        call    READ_CARD
        call    WRITE

        mov     rax, SYS_EXIT
        mov     rdi, 0                  ; return code = 0
        syscall
