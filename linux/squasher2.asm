bits 64
default rel

%macro co_call 1
        pop     rdx                     ; pop entry point store address for the current coroutine
        mov     rcx, %%_end             ; move next entry point address to rcx
        mov     [rdx], rcx              ; update value in the store

        mov     rdx, instruction_at_%1  ; address of the entry point store for the next coroutine
        push    rdx                     ; push address to update it on exit
        jmp     [rdx]                   ; call coroutine
%%_end: nop                             ; next entry point
%endmacro

SYS_EXIT        equ     60
SYS_READ        equ     0
SYS_WRITE       equ     1
STDIN           equ     0
STDOUT          equ     1
INPUT_SIZE      equ     80

section .bss
i:              resq    1
input:          resq    INPUT_SIZE
lastChar:       resq    1

section .data
instruction_at_main:       dq    main     ; stores resuming point of main
instruction_at_squasher:   dq    squasher ; stores resuming point of squasher


section .text

; --------------------------------------------------------------------------------
read_input:
        mov     rdx, INPUT_SIZE         ; maximum number of bytes to read
        mov     rsi, input              ; buffer to read into
        mov     rdi, STDIN              ; file descriptor
        mov     rax, SYS_READ
        syscall
        mov     qword [i], 0
        ret

; --------------------------------------------------------------------------------
next_char:
        mov     rsi, [i]
        mov     rdi, input
        mov     rax, 0
        mov     al, [rdi + rsi]         ; output is stored in rax

        inc     rsi
        mov     [i], rsi

        ret

; --------------------------------------------------------------------------------
squasher:
        call    next_char
        cmp     rax, '*'
        je     .check_second_asterisk
        co_call main
        jmp     squasher

.check_second_asterisk:
        mov     rbx, rax                ; temporary save first char to rbx
        call    next_char
        cmp     rax, '*'
        je      .do_squashing

        mov     [lastChar], rax         ; save rax because its value will be erased by another coroutine
        mov     rax, rbx                ; load first char from rbx
        co_call main

        mov     rax, [lastChar]
        co_call main
        jmp     squasher

.do_squashing:
        mov     rax, '^'
        co_call main
        jmp     squasher

; --------------------------------------------------------------------------------
write:
        mov     rdx, 1                  ; message length
        push    rax
        mov     rsi, rsp                ; message to write
        mov     rdi, STDOUT             ; file descriptor
        mov     rax, SYS_WRITE
        syscall
        pop     rax
        ret

; --------------------------------------------------------------------------------
global  main
main:
        call    read_input
        mov     rax, instruction_at_main
        push    rax                     ; prepare stack for coroutine call
.loop:
        co_call squasher
        call    write

        mov     rax, [i]
        cmp     rax, INPUT_SIZE
        jne     .loop

        pop     rax                     ; clean stack after coroutine calls
        mov     rax, SYS_EXIT
        mov     rdi, 0                  ; return code = 0
        syscall
