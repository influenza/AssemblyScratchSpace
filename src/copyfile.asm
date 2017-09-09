; Read a file name from stdin, write to a hardcoded output file
section .data
  outfile:  db    'copied-file.out', 10 ; Write the input to this file
  outfilelen equ $-outfile

  buffer:   resb  256

section .text
  global _start

  _start:

  .open_file: ; Open the file who's path is pointed to by rdi

  .exit:
    mov   rax,  60      ; sys_exit
    mov   rdi,  0       ; Exit 0
    syscall
