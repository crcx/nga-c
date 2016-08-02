d:
	./build.py
	$(CC) nga.c -DSTANDALONE -Wall -o nga
	$(CC) -DVERBOSE ngita.c -Wall -o ngita
	$(CC) naje.c -DALLOW_FORWARD_REFS -DENABLE_MAP -Wall -o naje

c:
	rm -f nga ngita naje

