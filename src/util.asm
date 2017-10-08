%define ascii_newline 0x10
%define ascii_hyphen 0x2D
%define ascii_zero  0x30
%define uint64_digits 20
%define uint_buffer_size uint64_digits + 1
%define leading_zero_flag 0x8000

section .data

codes: db '0123456789abcdef'
newline_char: db 10
test_string: db 'hello world', 0
overflow_string: db 'More characters than buffer space.', 0
prompt_string: db 'enter a character> ', 0
word_prompt_string: db 'enter a word> ', 0
conf_string: db 'printing your response: ', 0
val: dq  -1

section .text
;global _start

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

; Copy the string pointed to in RDI to the buffer pointed to in RSI with size stored
; in RDX. If src fits in the dst buffer, the destination address will be returned in
; RAX. Otherwise 0 will be stored in RAX.
string_copy:
    mov     rax,  rsi ; Default return value is original buffer address

    mov     rcx,  rdx ; move buffer size to rcx

    .loop_start:
    test    rcx,  rcx
    jz      .buffer_full


    mov     r8, [rdi]  ; Copy the current character
    mov     [rsi], r8  ; Copy the current character
    test    r8, r8  ; null terminator?
    jz      .copy_complete

    inc     rsi ; on to the next spot
    inc     rdi ; for source and dest

    dec     rcx ; one less character is available in the buffer
    jmp     .loop_start

    .buffer_full: ; buffer has been overrun, return zero
    xor     rax, rax
    .copy_complete: ; end of process, return original buffer address
  ret

print_string:     ; prints a null-terminated string to stdout, sent pointer in rdi.
      push rdi        ; store provided string pointer
      call string_length
      mov rdx, rax    ; move string length to param 2 of syscall
      mov rax,  1     ; syscall: sys_write
      mov rdi,  1     ; fd: stdout
      pop rsi         ; pop string pointer
      syscall
    ret

print_char:     ; prints the character code in rdi to stdout
    ; Reserve a single character buffer on the stack
    push    rbp
    mov     rbp, rsp
    sub     rsp, 1

    mov     [rbp - 1], rdi    ; mov contents of rdi into the char buffer storage
    mov     rax,  1 ; syscall: sys_write
    mov     rdi,  1 ; fd: stdout
    lea     rsi, [rbp - 1] ; buf
    mov     rdx,  1 ; count: 1
    syscall

    add     rsp, 1  ; free buffer
    pop     rbp
  ret


print_newline:    ; Prints a newline character to stdout
    mov     rax,  1 ; syscall: sys_write
    mov     rdi,  1 ; fd: stdout
    mov     rsi, newline_char ; buf
    mov     rdx,  1 ; count: 1
    syscall
  ret

print_uint:   ; Prints the unsigned 8 byte integer in rdi to stdout
    ; TODO: A callee-preserved register is not being preserved
    push  rbp
    mov   rbp, rsp  ; copy initial stack pointer to rbp

    sub   rsp, uint_buffer_size    ; Allocate space for 20 digits and a null terminator

    lea   rsi, [rbp - uint_buffer_size] ; point to buffer with rsi
    call  render_uint_to_buffer
    lea   rdi, [rbp - uint_buffer_size] ; move pointer to rdi
    call  print_string

    add   rsp, uint_buffer_size ; free space for uint buffer
    pop   rbp
  ret

; writes decimal representation of the unsigned 8-byte integer in rdi
; to the buffer pointed to in rsi. The resulting string will be null
; terminated. The provided buffer should be at least 21 bytes in length.
render_uint_to_buffer:   
    ; the lowest byte of r10 (r10b) will store the current offset into
    ; the provided buffer. The most significant bit of the lower 16 bits
    ; will be used as a flag to skip leading zeroes.
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
    push  r10
    and   r10w, leading_zero_flag
    test  r10w, r10w
    pop   r10
    jnz   .leading_zero_flag_already_set
    test  rax, rax    ; check the quotient
    ; leading zero && divisor != 1
    jnz   .flip_the_flag   ; non-zero quotient, flip the flag
    cmp   r9, 1
    je    .flip_the_flag  ; divisor = 1, flip the flag
    jmp   .after_write_char ; otherwise skip it (leading zero)
  .flip_the_flag:
    or   r10w,  leading_zero_flag ; flip the flag
  .leading_zero_flag_already_set:
    add   rax, ascii_zero ; Convert to ascii code

    ; Write character to the buffer, increment buffer offset
    push  r10
    and   r10, 0x1F
    lea   r11, [rsi + r10]
    pop   r10
    mov   [r11], rax
    inc   r10

  .after_write_char:

    mov   rax, rdx    ; mov remainder over to be processed
    cqo               ; sign extend rax into rdx

    dec   rcx
    test  rcx, rcx
    jnz .each_char_loop
    ; Write null terminator
    push  r10   ; r10 is holding the offset into our char buffer in the low byte
    and   r10, 0x1F
    lea   r11, [rsi + r10]
    pop   r10
    mov   byte[r11], 0x00
  ret

print_int:    ; prints the signed integer passed in $rdi (including sign)
    push  rbp
    mov   rbp, rsp  ; copy initial stack pointer to rbp
    sub   rsp, uint_buffer_size    ; Allocate space for 20 digits and a null terminator

    xor   r10, r10  ; Will store buffer offset in r10
    ; write sign to the buffer if necessary
    ; use uint for the remaining characters
    mov   rax, rdi
    test  rax, rax ; test will AND the operands, thereby maintaining the sign bit
    jns   .unsigned
    ; otherwise print '-' and convert the absolute value to its
    ; unsigned representation
    inc   r10 ; Move buffer pointer offset by one
    mov   byte[rbp - uint_buffer_size], ascii_hyphen

    ; Convert the provided number to an unsigned int
    dec   rdi
    not   rdi
  .unsigned:

    lea   rsi, [rbp - uint_buffer_size + r10] ; point to space with rsi
    call  render_uint_to_buffer
    lea   rdi, [rbp - uint_buffer_size] ; move pointer to rdi
    call  print_string

    add   rsp, uint_buffer_size ; free buffer space
    pop rbp
  ret

; Read a character from STDIN and return its value in rax, return the value
; returned by sys_read in rdx
read_char:
    ; Allocate a one-byte buffer
    push  rbp
    mov   rbp, rsp
    sub   rsp, 1          ; allocate a one-byte buffer
    ; Call sys_read for a single character
    xor   rax,  rax       ; syscall: 0 = sys_read
    xor   rdi,  rdi       ; param 1, file desc: 0 = STDIN
    lea   rsi,  [rbp - 1] ; param 2, buffer
    mov   rdx,  1         ; read one char

    syscall

    ; Pass along return value from sys_read to the caller
    mov   rdx, rax
    ; value should now be in [rbp - 1]
    mov   al, byte[rbp - 1]

    add rsp, 1
    pop rbp
  ret

; Read a word from STDIN into a provided buffer. Skip whitespace*. The provided
; buffer will be null-terminated if the input fits into the buffer. On success,
; return the buffer address, or zero if the input exceeds the buffer size.
;     * whitespace characters -> 0x20, 0x90, 0x10
read_word:  ; rdi buffer address, rsi size, return 0 if problem, buffer address otherws
    ; rdi = buffer
    ; rsi = buffer size

    ; Effective buffer size is one less than what is provided
    dec     rsi

    xor     r9, r9  ; use r9 for buffer index
    .read_char_loop:
    ; read a character, if whitespace or end-of-file, break
    push    rdi
    push    rsi
    push    r9
    call    read_char
    pop     r9
    pop     rsi
    pop     rdi
    ; after calling read_char, if rdx is negative, something is amiss and we 
    ; should abort
    test    rdx, rdx ; test will AND the operands, maintaining a sign bit
    js      .end_of_read_loop ; signed - negative value = problem
    jz      .end_of_read_loop ; zero - indicates no character was read
    cmp     rax, 0x09 ; tab
    je      .end_of_read_loop
    cmp     rax, 0x10 ; newline
    je      .end_of_read_loop
    cmp     rax, 0x20 ; space
    je      .end_of_read_loop
    ; else store in current buffer, increment buffer index
    mov     [rdi + r9], al
    inc     r9
    ; if buffer index >= buffer size - 1; null terminate string and return 0
    cmp     r9, rsi
    jge     .overflowed_buffer
    jmp     .read_char_loop
    
    .end_of_read_loop:
    mov     rax, rdi  ; return pointer to buffer
    jmp     .end

    .overflowed_buffer:
    xor   rax, rax  ; return 0 to indicate overflow

    .end:
    mov     byte[rdi + r9], 0 ; null-terminate the buffer

  ret

parse_uint:
  ret

parse_int:
  ret

string_equals:
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

_definitely_not_start:
    ; Exercise print_char and print_newline
    ; ---------------------------------------
    mov rdi, [test_string]
    call print_char
    call print_newline

    ; Exercise print_string
    ; ---------------------------------------
    mov rdi, prompt_string
    call print_string

    ; Exercise read_char
    ; ---------------------------------------
    call  read_char
    push  rax

    mov   rdi, conf_string
    call  print_string
    call  print_newline

    pop   rax
    mov   rdi, rax
    call  print_char
    call  print_newline

    ; Exercise read_word
    ; ---------------------------------------
    mov     rdi, word_prompt_string
    call    print_string

    lea     rdi,  [rbp - 16]
    mov     rsi,  16
    call    read_word

    test    rax, rax
    jnz     .read_word_no_problem
    mov     rdi, overflow_string
    call    print_string
    call    print_newline
    jmp     .exercise_print_uint

    .read_word_no_problem:
    push    rax

    mov     rdi, conf_string
    call    print_string
    call    print_newline

    pop     rax
    mov     rdi, rax
    call    print_string
    call    print_newline


    ; Exercise print_uint
    ; ---------------------------------------
    .exercise_print_uint:
    mov rdi, 18446744073709551615   ; <-- 2^64-1
    call print_uint
    call print_newline

    mov rdi, 42   ; Test omission of leading zeroes
    call print_uint
    call print_newline

    mov rdi, -42   ; Test omission of leading zeroes
    call print_int
    call print_newline

    ; Exercise string_length
    ; ---------------------------------------
    mov     rdi, test_string
    call    string_length
    mov     rdi, rax  ; put length into exit code

    add   rsp, 16   ; Free up buffer space
    pop   rbp

    ; Exercise string copy
    ; ---------------------------------------
    sub     rsp,  16 ; Allocate a buffer on the stack
    mov     rdi,  test_string
    lea     rsi,  [rsp]
    mov     rdx,  16
    call    string_copy
    ; We should now have the test string also on the stack. Print them both
    mov     rdi, test_string
    call    print_string
    call    print_newline
    lea     rdi, [rsp]
    call    print_string
    call    print_newline

    add     rsp,  16 ; Free buffer

    call exit
