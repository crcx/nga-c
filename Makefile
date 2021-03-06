CC = clang
CFLAGS = -Wall

d: s
	cd source && $(CC) $(CFLAGS) nga.c -DSTANDALONE $(CFLAGS) -o ../bin/nga
	cd source && $(CC) $(CFLAGS) muri.c $(CFLAGS) -o ../bin/muri
	cd source && $(CC) $(CFLAGS) naje.c -DDEBUG -DALLOW_FORWARD_REFS -DENABLE_MAP $(CFLAGS) -o ../bin/naje

s:
	rm -rf bin
	mkdir bin
	$(CC) $(CFLAGS) source/unu.c -o bin/unu
	./bin/unu Unu.md >source/unu.c
	$(CC) $(CFLAGS) source/unu.c -o bin/unu
	./bin/unu Nga.md >source/nga.c
	./bin/unu Naje.md >source/naje.c
	./bin/unu Muri.md >source/muri.c
	./bin/unu Tiro.md >source/tiro.py

c:
	rm -f bin/*
