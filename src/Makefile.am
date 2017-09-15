bin_PROGRAMS = copyfile hello print_rax util

copyfile_SOURCES = copyfile.asm

copyfile_LDFLAGS = -e _start -s

hello_SOURCES = hello.asm

hello_LDFLAGS = -e _start -s

print_rax_SOURCES = print_rax.asm

print_rax_LDFLAGS = -e _start -s

util_SOURCES = util.asm

util_LDFLAGS = -e _start -s

CLEANFILES = copyfile.o copyfile.lst copyfile \
						 hello.o hello.lst hello \
						 print_rax.o print_rax.lst printrax \
						 util.o util.lst util

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

util: util.o
	ld -m elf_x86_64 -o util util.o

util.o: util.asm
	nasm -f elf64 -g -F dwarf -l util.lst util.asm
