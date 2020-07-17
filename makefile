# See https://www.nasm.us and https://ftp.gnu.org/old-gnu/Manuals/ld-2.9.1/html_mono/ld.html
define compile
    nasm -fmacho64 -w+all $(1).asm && \
    ld $(1).o -o $(1) -e _main -lSystem -no_pie -macosx_version_min 10.9 && \
    rm $(1).o
endef

build:
	$(call compile,squasher1)
	$(call compile,squasher2)

test:
	~/smoke-v2.1.0-Darwin-x86_64 --command ./squasher1 . && \
	~/smoke-v2.1.0-Darwin-x86_64 --command ./squasher2 .

clean:
	rm squasher1
	rm squasher2
