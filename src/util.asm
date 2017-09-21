%define ascii_zero  0x30
%define uint64_digits 19

section .data

codes: db '0123456789abcdef'
newline_char: db 10
test_string: db 'hello world', 0
val: dq  -1


section .bss
char_buffer:  resb 1
uint_buffer:  resb 21 ; 2^64 = 18446744073709551616 (length 20) + null terminator

section .text
global _start

exit: ; set the exit code specified in rdi and terminate the process
      mov     rax, 60 ; syscall: sys_exit
      syscall
    ret

string_length: ; calculate length or string starting at address in rdi, return in rax
    xor rax,  rax    ; clean out result space
  .iterate:
    cmp byte [rdi + rax], 0   ; is this the null terminator?
    je .end
    inc rax
    jmp .iterate
  .end:
    ret

print_string:     ; prints a null-terminated string to stdout, sent pointer in rdi.
      push rdi        ; store provided argument
      call string_length
      mov rdx, rax    ; move string length to param 2 of syscall
      mov rax,  1     ; syscall: sys_write
      mov rdi,  1     ; fd: stdout
      pop rsi         ; pop string pointer
      syscall
    ret

print_char:     ; prints the character code in rdi to stdout
    mov     [char_buffer], rdi    ; mov contents of rdi into the char buffer storage
    mov     rax,  1 ; syscall: sys_write
    mov     rdi,  1 ; fd: stdout
    mov     rsi, char_buffer ; buf
    mov     rdx,  1 ; count: 1
    syscall
  ret


print_newline:    ; Prints a newline character to stdout
    mov     rax,  1 ; syscall: sys_write
    mov     rdi,  1 ; fd: stdout
    mov     rsi, newline_char ; buf
    mov     rdx,  1 ; count: 1
    syscall
  ret

print_uint:   ; Prints the unsigned 8 byte integer in rdi to stdout
    mov   rax, rdi    ; Copy in provided value to the accumulator

    mov   r8, 10      ; Base to convert to
    mov   rcx, uint64_digits     ; The 64-bit uint can require 20 decimal digits
  .each_char_loop:
    mov   r9, 1   ; Calculate divisor, store in r9
    push  rcx
  .calculate_divisor_loop:
    dec   rcx
    test  rcx, rcx
    jz .divisor_calculation_finished

    push  rax
    mov   rax, r9
    mul   r8
    mov   r9, rax ; mult by 10
    pop   rax

    jmp .calculate_divisor_loop

  .divisor_calculation_finished:

    pop   rcx

    ; The DIV instruction uses a 128 bit number with the low 64 bits in rax and the high
    ; 64 bits stored in rdx. The result is placed into rax and the remainder in rdx.
    ; Of note here is that rdx is implicitly pulled into this and we are trying to use
    ; it to store the divisor.
    div   r9       ; Divide by that calculated divisor. Result in rax, remainder in rdx
    add   rax, ascii_zero ; Convert to ascii code
    ; store caller saved registers
    push  r9
    push  r8
    push  rax
    push  rcx
    push  rdi
    push  rdx
    mov   rdi, rax
    call print_char
    ; Restore registers
    pop   rdx
    pop   rdi
    pop   rcx
    pop   rax
    pop   r8
    pop   r9

    mov   rax, rdx    ; mov remainder over to be processed
    cqo               ; sign extend rax into rdx

    dec   rcx
    test  rcx, rcx
    jnz .each_char_loop
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
    call print_string
    call print_newline

    mov rdi, [test_string]
    call print_char
    call print_newline

    mov rdi, 1122334455667788
    call print_uint
    call print_newline

    mov rdi, test_string
    call string_length
    mov rdi, rax  ; put length into exit code

    mov rax, 60 ; syscall: sys_exit
    ;xor rdi, rdi  ; error_code: 0, all is ok
    syscall
