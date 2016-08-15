d: s
	$(CC) nga.c -DSTANDALONE -Wall -o nga
	$(CC) -DVERBOSE ngita.c -Wall -o ngita
	$(CC) naje.c -DALLOW_FORWARD_REFS -DENABLE_MAP -Wall -o naje

s:
	$(CC) unu.c -o unu
	./unu Unu.md >unu.c
	$(CC) unu.c -o unu
	./unu Nga.md >nga.c
	./unu Ngita.md >ngita.c
	./unu Ngura.md >ngura.c
	./unu Naje.md >naje.c
	./unu sdk/Tiro.md >sdk/tiro.py
	./unu sdk/Naje.md >sdk/naje.py
	./unu sdk/Nabk.md >sdk/nabk.py


c:
	rm -f nga ngita naje

