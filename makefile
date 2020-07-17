# https://www.nasm.us
# https://ftp.gnu.org/old-gnu/Manuals/ld-2.9.1/html_mono/ld.html

SRC := $(wildcard ./*.asm)
EXE := $(SRC:.asm=)

./%.o: ./%.asm
	nasm -fmacho64 -w+all $< -o $@

./%: ./%.o
	ld $< -o $@ -e _main -lSystem -no_pie -macosx_version_min 10.9

build: ${EXE}

.PHONY: test
test: ${EXE}
	~/smoke-v2.1.0-Darwin-x86_64 .
