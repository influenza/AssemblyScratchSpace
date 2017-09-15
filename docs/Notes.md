Calling a function
------------------

* Save all caller-saved registers that should survive the function call:
  (i.e., everything other than rbx, rbp, rsp, r12-r15)
* Store args in the relevant registers (rdi, rsi, etc)
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
