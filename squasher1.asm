bits 64
default rel

%define NULL    qword 0

card_len equ    80

        section .bss

switch: resq    1                       ; module global data for SQUASHER
%define ON      qword 1
%define OFF     qword 0

i:      resq    1                       ; module global data for RDCRD and SQUASHER
card:   resq    card_len                ; module global data for RDCRD and SQUASHER

t1:     resq    1                       ; module global data for SQUASHER
t2:     resq    1                       ; module global data for SQUASHER

bytesRead: resq 1                       ; module local data for SQUASHER

out:    resq    1                       ; module global data for SQUASHER, WRITE

        section .text

SYS_READ    equ     0x2000003
SYS_WRITE   equ     0x2000004
SYS_EXIT    equ     0x2000001
STDIN       equ     0
STDOUT      equ     1

; --------------------------------------------------------------------------------
READ_ALL:
		mov     rdx, card_len           ; maximum number of bytes to read
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
        mov     rax, [t2]
        mov     [out], rax
        mov     qword [switch], OFF
        jmp     .exit

.off:
        call    RDCRD
        mov     [t1], rax
        cmp     rax, '*'
        jne     .output_t1

        call    RDCRD
        mov     [t2], rax
        cmp     rax, '*'
        je      .equal_second_ast
        mov     qword [switch], ON
        jmp     .output_t1

.equal_second_ast:
        mov     qword [t1], '^'

.output_t1:
        mov     rax, [t1]
        mov     [out], rax

.exit:
        ret

; --------------------------------------------------------------------------------
WRITE:
.loop:
        call    SQUASHER

        ; out is output area of SQUASHER and only holds a single byte,
        ; so it can only return a single read element. The look ahead
        ; reads a second element and thus needs a switch to return the
        ; looked "ahead" element on next call.
        mov     rdx, 1                  ; message length
        mov     rsi, out                ; message to write
        mov     rdi, STDOUT             ; file descriptor
        mov     rax, SYS_WRITE
        syscall

        mov     rax, [i]
        cmp     rax, card_len
        jne     .loop

        ret

; --------------------------------------------------------------------------------
_exitProgram:
        mov     rax, SYS_EXIT
        mov     rdi, 0                  ; return code = 0
        syscall

; --------------------------------------------------------------------------------
        global  _main

_main:
        mov     qword [switch], OFF
        mov     qword [i], 0
        call    READ_ALL
        call    WRITE

.finished:
        jmp     _exitProgram
