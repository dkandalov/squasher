# See https://www.nasm.us and https://ftp.gnu.org/old-gnu/Manuals/ld-2.9.1/html_mono/ld.html
define compile
    nasm -felf64 -w+all $(1).asm && \
    ld $(1).o -o $(1) -e main -m elf_x86_64 10.9 && \
    rm $(1).o
endef

build:
	command -v nasm || sudo apt-get install nasm
	$(call compile,squasher1)
	$(call compile,squasher2)

test:
	command -v ./smoke || wget https://github.com/SamirTalwar/smoke/releases/download/v2.1.0/smoke-v2.1.0-Linux-x86_64 -O smoke && chmod +x ./smoke
	./smoke --command ./squasher1 . && \
	./smoke --command ./squasher2 .

clean:
	rm squasher1
	rm squasher2
