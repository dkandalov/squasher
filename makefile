# See https://www.nasm.us and https://ftp.gnu.org/old-gnu/Manuals/ld-2.9.1/html_mono/ld.html
define compile
    nasm -fmacho64 -w+all $(1).asm && \
    ld $(1).o -o $(1) -e main -lSystem -no_pie -macosx_version_min 10.9 && \
    rm $(1).o
endef

build:
	command -v nasm || brew install nasm
	$(call compile,squasher1)
	$(call compile,squasher2)

test:
	command -v ./smoke || curl -L https://github.com/SamirTalwar/smoke/releases/download/v2.1.0/smoke-v2.1.0-Darwin-x86_64 -o smoke && chmod +x ./smoke
	./smoke --command ./squasher1 . && \
	./smoke --command ./squasher2 .

clean:
	rm squasher1
	rm squasher2
