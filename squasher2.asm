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

SYS_EXIT        equ     0x2000001
SYS_READ        equ     0x2000003
SYS_WRITE       equ     0x2000004
STDIN           equ     0
STDOUT          equ     1
CARD_LEN        equ     80

section .bss
i:              resq    1
card:           resq    CARD_LEN
lastChar:       resq    1

section .data
instruction_at_main:       dq    main
instruction_at_squasher:   dq    squasher


section .text

; --------------------------------------------------------------------------------
read_card:
        mov     rdx, CARD_LEN           ; maximum number of bytes to read
        mov     rsi, card               ; buffer to read into
        mov     rdi, STDIN              ; file descriptor
        mov     rax, SYS_READ
        syscall
        mov     qword [i], 0
        ret

; --------------------------------------------------------------------------------
next_char:
        mov     rsi, [i]
        mov     rdi, card
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
        _call   main
        jmp     squasher

.check_second_asterisk:
        mov     rbx, rax                ; temporary save first char to rbx
        call    next_char
        cmp     rax, '*'
        je      .do_squashing

        mov     [lastChar], rax         ; save rax because its value will be erased by another coroutine
        mov     rax, rbx                ; load first char from rbx
        _call   main

        mov     rax, [lastChar]
        _call   main
        jmp     squasher

.do_squashing:
        mov     rax, '^'
        _call   main
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
        call    read_card
        mov     rax, instruction_at_main
        push    rax                     ; prepare stack for coroutine call
.loop:
        _call   squasher
        call    write

        mov     rax, [i]
        cmp     rax, CARD_LEN
        jne     .loop

        pop     rax                     ; clean stack after coroutine calls
        mov     rax, SYS_EXIT
        mov     rdi, 0                  ; return code = 0
        syscall
