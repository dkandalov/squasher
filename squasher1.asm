bits 64
default rel

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

SYS_EXIT        equ     0x2000001
SYS_READ        equ     0x2000003
SYS_WRITE       equ     0x2000004
STDIN           equ     0
STDOUT          equ     1

OFF             equ     0
ON              equ     1
CARD_LEN        equ     80

section .bss
i:              resq    1
card:           resq    CARD_LEN
lastChar:       resq    1
switch:         resq    1


section .text

; --------------------------------------------------------------------------------
read_card:
		mov     rdx, CARD_LEN           ; maximum number of bytes to read
		mov     rsi, card               ; buffer to read into
		mov     rdi, STDIN              ; file descriptor
        mov     rax, SYS_READ
        syscall
        mov     qword [i], 0
	    _return

; --------------------------------------------------------------------------------
next_char:
        mov     rsi, [i]
        mov     rdi, card
        mov     rax, 0
        mov     al, [rdi + rsi]         ; output is stored in rax

        inc     rsi
        mov     [i], rsi

        _return

; --------------------------------------------------------------------------------
squasher:
        mov     rax, [switch]
        cmp     rax, OFF
        je      .off
.on:
        mov     qword [switch], OFF
        mov     rax, [lastChar]
        _return

.off:
        _call   next_char
        cmp     rax, '*'
        je     .check_second_asterisk
		_return

.check_second_asterisk:
        mov     rbx, rax                ; temporary save first char to rbx
        _call   next_char
        cmp     rax, '*'
        je      .do_squashing

        mov     [lastChar], rax
        mov     qword [switch], ON      ; remember to write lastChar next time
        mov     rax, rbx                ; load first char from rbx
        _return

.do_squashing:
        mov     rax, '^'
        _return

; --------------------------------------------------------------------------------
write:
        mov     rdx, 1                  ; message length
        push    rax
        mov     rsi, rsp                ; message to write
        mov     rdi, STDOUT             ; file descriptor
        mov     rax, SYS_WRITE
        syscall
        pop     rax
        _return

; --------------------------------------------------------------------------------
global  main
main:
        _call   read_card
        mov     qword [switch], OFF
.loop:
        _call   squasher
        _call   write

        mov     rax, [i]
        cmp     rax, CARD_LEN
        jne     .loop

        mov     rax, SYS_EXIT
        mov     rdi, 0                  ; return code = 0
        syscall
