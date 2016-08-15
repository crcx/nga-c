d: s
	cd source && $(CC) nga.c -DSTANDALONE -Wall -o ../bin/nga
	cd source && $(CC) -DVERBOSE ngita.c -Wall -o ../bin/ngita
	cd source && $(CC) naje.c -DALLOW_FORWARD_REFS -DENABLE_MAP -Wall -o ../bin/naje

s:
	$(CC) source/unu.c -o bin/unu
	./bin/unu Unu.md >source/unu.c
	$(CC) source/unu.c -o bin/unu
	./bin/unu Nga.md >source/nga.c
	./bin/unu Ngita.md >source/ngita.c
	./bin/unu Ngura.md >source/ngura.c
	./bin/unu Naje.md >source/naje.c
	./bin/unu sdk/Tiro.md >sdk/tiro.py
	./bin/unu sdk/Naje.md >sdk/naje.py
	./bin/unu sdk/Nabk.md >sdk/nabk.py


c:
	rm -f bin/*

