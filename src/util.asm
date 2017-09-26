%define ascii_newline 0x10
%define ascii_hyphen 0x2D
%define ascii_zero  0x30
%define uint64_digits 20

%define reciprocal_log2_of_10 0.30102999

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
    xor   r10, r10    ; Zero out register for later flag use
    mov   rax, rdi    ; Copy in provided value to the accumulator

    mov   r8, 10      ; Base to convert to for display - base 10
    mov   rcx, uint64_digits  ; The 64-bit uint can require up to this many digits

  .each_char_loop:  ; print each character possible in an 8-byte unsigned integer
    mov   r9, 1   ; Calculate divisor, store in r9
    push  rcx
  .calculate_divisor_loop:
    ; The last spot, the ones digit, should use 1 as a divider
    dec   rcx
    test  rcx, rcx
    jz .divisor_calculation_finished

    push  rax
    mov   rax, r9 ; move the partial result back to the accumulator
    mul   r8      ; mul applies (and destroys) the accumulator - rax
    mov   r9, rax ; copy the result back over to r9
    pop   rax

    jmp .calculate_divisor_loop

  .divisor_calculation_finished:    ; Indicates that the divisor for this digit is ready

    pop   rcx

    ; At this point, let's avoid printing out leading zeroes.
    ; Note that the number of digits can be pre-computed as 1 + floor(log10(rax)),
    ; but the use of logarithm functionality in the FPU is new to me right now.
    ; Some notes for later: FILD, FYL2X, F2XM1, and FDIVP are likely to be used.
    ;
    ; For now, just spin and print nothing until a non-zero quotient is found.
    ; TODO: Make sure the value '0' prints as such and is not displayed as the
    ;   empty string.

    ; The DIV instruction uses a 128 bit number with the low 64 bits in rax and the high
    ; 64 bits stored in rdx. The result is placed into rax and the remainder in rdx.
    ; Of note here is that rdx is implicitly pulled into this and we are trying to use
    ; it to store the divisor.
    div   r9       ; Divide by that calculated divisor. Result in rax, remainder in rdx
    test  r10, r10
    jnz   .leading_zero_flag_already_set
    test  rax, rax
    jz    .after_print_char   ; Leading zero, don't print it
    mov   r10,  1           ; flip the flag
  .leading_zero_flag_already_set:
    add   rax, ascii_zero ; Convert to ascii code
    ; store caller saved registers
    push  r10
    push  r9
    push  r8
    push  rax
    push  rcx
    push  rdi
    push  rdx
    mov   rdi, rax  ; print out the quotient
    call print_char
    ; Restore registers
    pop   rdx
    pop   rdi
    pop   rcx
    pop   rax
    pop   r8
    pop   r9
    pop   r10

  .after_print_char:

    mov   rax, rdx    ; mov remainder over to be processed
    cqo               ; sign extend rax into rdx

    dec   rcx
    test  rcx, rcx
    jnz .each_char_loop
  ret

print_int:    ; prints a signed integer (including sign)
    ; TODO: Write sign to buffer, pass remaining buffer to print_uint
    ; print sign if necessary
    ; use uint for the remaining characters
    mov   rax, rdi
    test  rax, rax
    jns   .unsigned
    ; otherwise print '-' and convert the absolute value to its
    ; unsigned representation
    push  rdi
    mov   rdi, ascii_hyphen
    call  print_char
    pop   rdi
    dec   rdi
    not   rdi
  .unsigned:
    call print_uint
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

    mov rdi, 18446744073709551615   ; <-- 2^64-1
    call print_uint
    call print_newline

    mov rdi, 42   ; Test omission of leading zeroes
    call print_uint
    call print_newline

    mov rdi, -42   ; Test omission of leading zeroes
    call print_int
    call print_newline

    mov rdi, test_string
    call string_length
    mov rdi, rax  ; put length into exit code

    mov rax, 60 ; syscall: sys_exit
    ;xor rdi, rdi  ; error_code: 0, all is ok
    syscall
