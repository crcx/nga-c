CC = clang-3.5
#CC = gcc
CFLAGS =

# Uncomment for Windows
#EXT = .exe

d: s
	cd source && $(CC) $(CFLAGS) -DVERBOSE ngita.c -Wall -o ../ngita$(EXT)

s:
	../bin/unu Ngita.md >source/ngita.c
	../bin/unu Ngura.md >source/ngura.c
	cp ../source/nga.c source
	cp ../nga.h source

c:
	rm -f ngita$(EXT)
	rm -f source/nga.c source/nga.h

