section .data
  msg: db 'Hello, World!', 10
  msglen equ $-msg

section .text
    global _start
  _start:
    mov     rax, 1        ; Syscall: sys_write
    mov     rdi, 1        ; Arg1: File descriptor (stdout)
    mov     rsi, msg      ; Arg2: Pointer to source
    mov     rdx, msglen   ; Arg3: Length to copy
    syscall               ; Invoke
    jmp     .exit
  .exit:
    mov     rax, 60       ; Syscall: sys_exit
    mov     rdi, 0        ; error_code (0 = OK)
    syscall               ; And return
