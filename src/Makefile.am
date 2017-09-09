bin_PROGRAMS = copyfile hello

copyfile_SOURCES = copyfile.asm

copyfile_LDFLAGS = -e _start -s

hello_SOURCES = hello.asm

hello_LDFLAGS = -e _start -s

CLEANFILES = copyfile.o copyfile \
						 hello.o hello

copyfile: copyfile.o
	ld -e _start -s -o copyfile copyfile.o

copyfile.o: copyfile.asm
	nasm -f elf64 copyfile.asm

hello: hello.o
	ld -e _start -s -o hello hello.o

hello.o: hello.asm
	nasm -f elf64 hello.asm
