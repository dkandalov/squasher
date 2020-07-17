bits 64
default rel

SYS_EXIT    equ     0x2000001
SYS_READ    equ     0x2000003
SYS_WRITE   equ     0x2000004
STDIN       equ     0
STDOUT      equ     1

OFF         equ     0
ON          equ     1
CARD_LEN    equ     80

%macro _call 1
		mov     rdx, %%_end
        push    qword rdx
        jmp     %1
%%_end: nop
%endmacro

%macro _return 0
		pop     rdx
        jmp     rdx
%endmacro

section .bss

i:              resq    1
card:           resq    CARD_LEN

char:           resq    1
lastChar:       resq    1
switch:         resq    1
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
	    _return

; --------------------------------------------------------------------------------
NEXT_CHAR:
        mov     rsi, [i]
        mov     rdi, card
        mov     rax, 0
        mov     al, [rdi + rsi]         ; output is stored in rax

        inc     rsi
        mov     [i], rsi

        _return

; --------------------------------------------------------------------------------
SQUASHER:
        mov     rax, [switch]
        cmp     rax, OFF
        je      .off
.on:
        mov     qword [switch], OFF
        mov     rax, [lastChar]
        jmp     .output_rax

.off:
        _call   NEXT_CHAR
        cmp     rax, '*'
        jne     .output_rax

        mov     [char], rax
        _call   NEXT_CHAR
        cmp     rax, '*'
        je      .do_squashing

        mov     [lastChar], rax
        mov     qword [switch], ON  ; remember to write char from lastChar next time
        mov     rax, [char]
        jmp     .output_rax

.do_squashing:
        mov     rax, '^'

.output_rax:
        mov     [squasherOutput], rax
        _return

; --------------------------------------------------------------------------------
WRITE:
        mov     qword [switch], OFF
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
        _return

; --------------------------------------------------------------------------------
global  _main
_main:
        _call   READ_CARD
        _call   WRITE

        mov     rax, SYS_EXIT
        mov     rdi, 0                  ; return code = 0
        syscall
