CC = clang-3.5
#CC = gcc
CFLAGS =

# Uncomment for Windows
#EXT = .exe

d: s
	cd source && $(CC) $(CFLAGS) nga.c -DSTANDALONE -Wall -o ../bin/nga$(EXT)
	cd source && $(CC) $(CFLAGS) naje.c -DDEBUG -DALLOW_FORWARD_REFS -DENABLE_MAP -Wall -o ../bin/naje$(EXT)
	cd source && $(CC) $(CFLAGS) nuance.c -Wall -o ../bin/nuance$(EXT)
	cd source && $(CC) $(CFLAGS) embedimage.c -Wall -o ../bin/embedimage$(EXT)

s:
	$(CC) $(CFLAGS) source/unu.c -o bin/unu$(EXT)
	./bin/unu Unu.md >source/unu.c
	$(CC) $(CFLAGS) source/unu.c -o bin/unu$(EXT)
	./bin/unu Nga.md >source/nga.c
	./bin/unu Nuance.md >source/nuance.c
	./bin/unu Naje.md >source/naje.c
	./bin/unu EmbedImage.md >source/embedimage.c
	./bin/unu Tiro.md >source/tiro.py

c:
	rm -f bin/*
