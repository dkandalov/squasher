build:
	# See https://www.nasm.us and https://ftp.gnu.org/old-gnu/Manuals/ld-2.9.1/html_mono/ld.html
	nasm -fmacho64 -w+all squasher1.asm
	ld squasher1.o -o squasher1 -e _main -lSystem -no_pie -macosx_version_min 10.9
	rm squasher1.o

test:
	~/smoke-v2.1.0-Darwin-x86_64 --command ./squasher1 .
	~/smoke-v2.1.0-Darwin-x86_64 --command ./squasher2 .
