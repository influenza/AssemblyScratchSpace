hello: hello.o
	ld -e _start -s -o hello hello.o

hello.o: hello.asm
	nasm -f elf64 hello.asm

CLEANFILES = hello.o hello
