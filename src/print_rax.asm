
section .data
  hex_digits:
    db '0123456789ABCDEF'
  new_line: db 10

section .text
global _start
  _start:
    mov   rax,  0x11223344CAFEBABE ; Put the value of interest into rax

    mov   rdi, 1 ; sys_write Arg1, stdout file descriptor
    mov   rdx, 1 ; sys_write Arg2, # of bytes to write
    mov   rcx, 64 ; counter, 64 bits to write

  .loop:
    push rax      ; store the value we are printing
    sub rcx, 4    ; each 4 bits is one hex character
    sar rax, cl   ; right shift (signed) "cl" times (60, 56, 52, 48, etc)
    and rax, 0xF  ; Zero out all but the least significant 4 bits

    ; load the address of the relevant hex character into rsi
    lea rsi, [hex_digits + rax]
    mov rax, 1  ; syscall: sys_write

    ; save caller-saved values
    push rcx
    syscall
    pop rcx

    pop rax
    test rcx, rcx
    jnz .loop

    ; End with a newline
    mov rax, 1    ; sys_write
    lea rsi, [new_line] ; Load newline character as the message pointer arg
    syscall

    jmp .exit
  .exit: ; Exit with an error code of zero
    mov   rax,  60  ; sys_exit
    mov   rdi,  0   ; error code = 0
    syscall
