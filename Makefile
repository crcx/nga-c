d:
	./build.py
	$(CC) nga.c -DSTANDALONE -Wall -o nga
	$(CC) ngita.c -Wall -o ngita
	$(CC) naje.c -Wall -o naje
