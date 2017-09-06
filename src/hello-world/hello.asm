section .data
  message: db 'Hello, World!', 10

section .text
    global _start
  _start:
    mov     rax, 1        ; Syscall: sys_write
    mov     rdi, 1        ; Arg1: File descriptor (stdout)
    mov     rsi, message  ; Arg2: Pointer to source
    mov     rdx, 14       ; Arg3: Length to copy
    syscall               ; Invoke
    mov     rax, 60       ; Syscall: sys_exit
    mov     rdi, 0        ; error_code (0 = OK)
    syscall               ; And return
