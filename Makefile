CC = clang-3.5
CFLAGS =

d: s
	cd source && $(CC) $(CFLAGS) nga.c -DSTANDALONE -Wall -o ../bin/nga
	cd source && $(CC) $(CFLAGS) -DVERBOSE ngita.c -Wall -o ../bin/ngita
	cd source && $(CC) $(CFLAGS) naje.c -DALLOW_FORWARD_REFS -DENABLE_MAP -Wall -o ../bin/naje
	cd source && $(CC) $(CFLAGS) nuance.c -Wall -o ../bin/nuance
	cd source && $(CC) $(CFLAGS) embedimage.c -Wall -o ../bin/embedimage

s:
	$(CC) $(CFLAGS) source/unu.c -o bin/unu
	./bin/unu Unu.md >source/unu.c
	$(CC) $(CFLAGS) source/unu.c -o bin/unu
	./bin/unu Nga.md >source/nga.c
	./bin/unu Ngita.md >source/ngita.c
	./bin/unu Ngura.md >source/ngura.c
	./bin/unu Nuance.md >source/nuance.c
	./bin/unu Naje.md >source/naje.c
	./bin/unu EmbedImage.md >source/embedimage.c
	./bin/unu sdk/Tiro.md >sdk/tiro.py
	./bin/unu sdk/Naje.md >sdk/naje.py
	./bin/unu sdk/Nabk.md >sdk/nabk.py


c:
	rm -f bin/*
