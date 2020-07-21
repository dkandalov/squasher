bits 64
default rel

%macro _call 1
        mov     rdx, %%_end
        push    rdx         ; save returning point on stack
        jmp     %1          ; call sub-function
%%_end: nop                 ; returning point
%endmacro

%macro _ret 0
        pop     rdx         ; load returning point from stack
        jmp     rdx         ; jump back into caller function
%endmacro

SYS_EXIT        equ     0x2000001
SYS_READ        equ     0x2000003
SYS_WRITE       equ     0x2000004
STDIN           equ     0
STDOUT          equ     1

FALSE           equ     0
TRUE            equ     1
INPUT_SIZE      equ     80

section .bss
i:              resq    1
input:          resq    INPUT_SIZE
lastChar:       resq    1
hasLastChar:    resq    1


section .text

; --------------------------------------------------------------------------------
read_input:
        mov     rdx, INPUT_SIZE             ; maximum number of bytes to read
        mov     rsi, input                  ; buffer to read into
        mov     rdi, STDIN                  ; file descriptor
        mov     rax, SYS_READ
        syscall
        mov     qword [i], 0
        _ret

; --------------------------------------------------------------------------------
next_char:
        mov     rsi, [i]
        mov     rdi, input
        mov     rax, 0
        mov     al, [rdi + rsi]             ; output is stored in rax

        inc     rsi
        mov     [i], rsi

        _ret

; --------------------------------------------------------------------------------
squasher:
        mov     rax, [hasLastChar]
        cmp     rax, FALSE
        je      .no_lastChar
        mov     qword [hasLastChar], FALSE
        mov     rax, [lastChar]
        _ret
.no_lastChar:
        _call   next_char
        cmp     rax, '*'
        je     .check_second_asterisk
        _ret
.check_second_asterisk:
        mov     rbx, rax                    ; temporary save first char to rbx
        _call   next_char
        cmp     rax, '*'
        je      .do_squashing

        mov     [lastChar], rax
        mov     qword [hasLastChar], TRUE   ; remember to write lastChar next time
        mov     rax, rbx                    ; load first char from rbx
        _ret
.do_squashing:
        mov     rax, '^'
        _ret

; --------------------------------------------------------------------------------
write:
        mov     rdx, 1                      ; message length
        push    rax
        mov     rsi, rsp                    ; message to write
        mov     rdi, STDOUT                 ; file descriptor
        mov     rax, SYS_WRITE
        syscall
        pop     rax
        _ret

; --------------------------------------------------------------------------------
global  main
main:
        _call   read_input
        mov     qword [hasLastChar], FALSE
.loop:
        _call   squasher
        _call   write

        mov     rax, [i]
        cmp     rax, INPUT_SIZE
        jne     .loop

        mov     rax, SYS_EXIT
        mov     rdi, 0                      ; return code = 0
        syscall
