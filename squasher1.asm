bits 64
default rel

%define ON          qword 1
%define OFF         qword 0
%define CARD_LEN    80

        section .bss

switch:         resq    1
i:              resq    1
card:           resq    CARD_LEN
t2:             resq    1
squasherOutput: resq    1

        section .text

SYS_READ    equ     0x2000003
SYS_WRITE   equ     0x2000004
SYS_EXIT    equ     0x2000001
STDIN       equ     0
STDOUT      equ     1

; --------------------------------------------------------------------------------
READ_ALL:
		mov     rdx, CARD_LEN           ; maximum number of bytes to read
		mov     rsi, card               ; buffer to read into
		mov     rdi, STDIN              ; file descriptor
        mov     rax, SYS_READ
        syscall
        ret

; --------------------------------------------------------------------------------
RDCRD:
        mov     rsi, [i]
        mov     rdi, card
        mov     rax, 0
        mov     al, [rdi + rsi]

        inc     rsi
        mov     [i], rsi

        ret

; --------------------------------------------------------------------------------
SQUASHER:
        mov     rax, [switch]
        cmp     rax, OFF
        je      .off
.on:
        mov     qword [switch], OFF
        mov     rax, [t2]
        jmp     .output_rax

.off:
        call    RDCRD
        mov     rbx, rax            ; temporary save char into rbx
        cmp     rax, '*'
        jne     .output_rax

        call    RDCRD
        mov     [t2], rax
        cmp     rax, '*'
        je      .do_squashing

        mov     qword [switch], ON  ; remember to write char from t2 next time
        mov     rax, rbx            ; restore char from rbx
        jmp     .output_rax

.do_squashing:
        mov     rax, '^'

.output_rax:
        mov     [squasherOutput], rax
        ret

; --------------------------------------------------------------------------------
WRITE:
.loop:
        call    SQUASHER

        mov     rdx, 1                  ; message length
        mov     rsi, squasherOutput     ; message to write
        mov     rdi, STDOUT             ; file descriptor
        mov     rax, SYS_WRITE
        syscall

        mov     rax, [i]
        cmp     rax, CARD_LEN
        jne     .loop
        ret

; --------------------------------------------------------------------------------
global  _main
_main:
        mov     qword [switch], OFF
        mov     qword [i], 0
        call    READ_ALL
        call    WRITE

        mov     rax, SYS_EXIT
        mov     rdi, 0                  ; return code = 0
        syscall
