Calling a function
------------------

* Save all caller-saved registers that should survive the function call:
  (i.e., everything other than rbx, rbp, rsp, r12-r15)
* Store args in the relevant registers (rdi, rsi, etc)
  * SysV ABI: RDI, RSI, RDX, RCX, R8, R9 
* Invoke the function using call <label>
* After function call, rax (and rdx) contain retval
* Restore caller-saved registers stored before call.


Registers and function calls
-----------------------------


Callee saved registers (save these before using in a function):
  rbx, rbp, rsp, r12-r15

All other registers should be saved *before* call if needed.

Returning values from a function
--------------------------------

Return value should be placed in rax. An additional return value
may be placed in rdx.


Using stack-local variables
---------------------------

As inspired by gcc C++ code,

      push rbp      ; we will be using this later, so save it to restore at the end
      mov  rbp, rsp ; store the initial stack pointer before making adjustments
      sub  rsp, 16   ; i.e., allocate 16 bytes on the stack
      lea  rsi, [rbp - 8]  ; i.e., send a pointer to an 8 byte buffer at the end of the stack space
      ; .. rest of the logic
      add  rsp, 16  ; free the stack storage space
      pop rbp       ; restore initial rbp value
