section .data

newline_char: db 10
codes: db '0123456789abcdef'
val: dq  -1
test_string: db 'hello world', 0

section .text
global _start

strlen: ; calculate length or string starting at address in rdi, return in rax
    xor rax,  rax    ; clean out result space
  .iterate:
    cmp byte [rdi + rax], 0   ; is this the null terminator?
    je .end
    inc rax
    jmp .iterate
  .end:
    ret

print_newline:    ; Prints a newline character to stdout
    mov     rax,  1 ; syscall: sys_write
    mov     rdi,  1 ; fd: stdout
    mov     rsi, newline_char ; buf
    mov     rdx,  1 ; count: 1
    syscall
  ret

print_hex:    ; prints contents of rdi as a stream of hexidecimal digits to stdout
    mov rax, rdi  ; store provided argument

    ; Prep for the sys_write call. These args do not vary
    mov rdi,  1   ; fd: stdout
    mov rdx,  1   ; count: 1
    mov rcx,  64  ; how far to shift rax - i.e., how many bits are we displaying

  .iterate:
    push rax      ; save initial value
    sub rcx,  4   ; we are processing 4 bits at a time
    sar rax,  cl  ; shift rax over to the current digit to print (60, 56, 52, etc)
    and rax, 0xf  ; clear all but the lowest four bits (0b00001111)

    lea rsi,  [codes + rax] ; Load the character from our codes map
    mov rax,  1   ; syscall: sys_write
    push rcx      ; syscall will clobber rcx
    syscall
    pop rcx
    pop rax       ; restore rax

    test rcx, rcx
    jnz .iterate   ; Is there more to print?


  ret

_start:
    ; setup
    mov rcx, 0xA  ; print ten times
    ; Have to move 64 bit immediate value through the rax register
    mov rax, 0x11223344CAFEBABE
    mov qword[val], rax
  .iterate:
    mov rdi, qword [val]
    push rcx
    call print_hex  ; print it
    call print_newline
    pop rcx
    add qword[val], 1  ; add one to the value to print

    dec rcx   ; one iteration complete
    test rcx, rcx
    jnz .iterate

    mov rdi, test_string
    call strlen
    mov rdi, rax  ; put length into exit code

    mov rax, 60 ; syscall: sys_exit
    ;xor rdi, rdi  ; error_code: 0, all is ok
    syscall
