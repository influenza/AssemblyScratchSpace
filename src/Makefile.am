bin_PROGRAMS = copyfile hello print_rax

copyfile_SOURCES = copyfile.asm

copyfile_LDFLAGS = -e _start -s

hello_SOURCES = hello.asm

hello_LDFLAGS = -e _start -s

print_rax_SOURCES = print_rax.asm

print_rax_LDFLAGS = -e _start -s

CLEANFILES = copyfile.o copyfile.lst copyfile \
						 hello.o hello.lst hello \
						 print_rax.o print_rax.lst printrax

copyfile: copyfile.o
	ld -m elf_x86_64 -o copyfile copyfile.o

copyfile.o: copyfile.asm
	nasm -f elf64 -g -F dwarf -l copyfile.lst copyfile.asm

hello: hello.o
	ld -m elf_x86_64 -o hello hello.o

hello.o: hello.asm
	nasm -f elf64 -g -F dwarf -l hello.lst hello.asm

print_rax: print_rax.o
	ld -m elf_x86_64 -o print_rax print_rax.o

print_rax.o: print_rax.asm
	nasm -f elf64 -g -F dwarf -l print_rax.lst print_rax.asm
