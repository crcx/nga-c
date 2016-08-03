# Ngura

## Overview

Ngura is an I/O model for Nga.

Ngura adds instructions for different I/O operations.

The numbering starts at 100 and runs as follows:

| Inst | Intended Use                                                 |
| ---- | ------------------------------------------------------------ |
| 100  | TTY: Display Character                                       |
| 101  | TTY: Display Number (signed, decimal)                        |
| 102  | TTY: Display String (zero terminated)                        |
| 103  | TTY: Display String (address, length)                        |
| 104  | TTY: Clear Display                                           |
| 105  |                                                              |
| 106  |                                                              |
| 107  |                                                              |
| 108  |                                                              |
| 109  |                                                              |
| 110  | KBD: Read Character                                          |
| 111  | KBD: Read Number (signed, decimal)                           |
| 112  | KBD: Read String (delimiter, address, length)                |
| 113  |                                                              |
| 114  |                                                              |
| 115  |                                                              |
| 116  |                                                              |
| 117  |                                                              |
| 118  | FS: Open                                                     |
| 119  | FS: Close                                                    |
| 120  | FS: Read Character                                           |
| 121  | FS: Write Character                                          |
| 122  | FS: Tell                                                     |
| 123  | FS: Seek                                                     |
| 124  | FS: Size                                                     |
| 125  | BLK: Load (number, address)                                  |
| 126  | BLK: Write (number, address)                                 |
| 127  |                                                              |
| 128  |                                                              |
| 129  |                                                              |
| 130  |                                                              |


(Numbering is subject to change)

## The Code

### Headers

First up, a few standard headers.

````
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <termios.h>
````

````
#define NGURA_FS
#define NGURA_TTY
#define NGURA_KBD
````

````
char request[8192];

/* Helper Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
void nguraGetString(int starting)
{
  CELL i = 0;
  while(memory[starting] && i < 8192)
    request[i++] = (char)memory[starting++];
  request[i] = 0;
}
````

### ...

````
#if defined(NGURA_TTY) || defined(NGURA_KBD)
struct termios new_termios, old_termios;

void nguraConsoleInit() {
#ifdef VERBOSE
  printf("- prepare terminal i/o\n");
#endif
  tcgetattr(0, &old_termios);
  new_termios = old_termios;
  new_termios.c_iflag &= ~(BRKINT+ISTRIP+IXON+IXOFF);
  new_termios.c_iflag |= (IGNBRK+IGNPAR);
  new_termios.c_lflag &= ~(ICANON+ISIG+IEXTEN+ECHO);
  new_termios.c_cc[VMIN] = 1;
  new_termios.c_cc[VTIME] = 0;
  tcsetattr(0, TCSANOW, &new_termios);
}

void nguraConsoleFinish() {
#ifdef VERBOSE
  printf("- restore previous terminal i/o settings\n");
#endif
  tcsetattr(0, TCSANOW, &old_termios);
}
#endif


#ifdef NGURA_TTY
void nguraConsolePutChar(char c) {
  putchar(c);
}

void nguraConsolePutNumber(int i) {
  printf("%d", i);
}
#endif

#ifdef NGURA_KBD
int nguraConsoleGetChar() {
  return (int)getc(stdin);
}
#endif
````

````
#ifdef NGURA_FS
/* File I/O Support ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
#define MAX_OPEN_FILES 128
FILE *nguraFileHandles[MAX_OPEN_FILES];

CELL nguraGetFileHandle()
{
  CELL i;
  for(i = 1; i < MAX_OPEN_FILES; i++)
    if (nguraFileHandles[i] == 0)
      return i;
  return 0;
}

CELL nguraOpenFile() {
  CELL slot, mode, name;
  slot = nguraGetFileHandle();
  mode = TOS; sp--;
  name = TOS; sp--;
  nguraGetString(name);
  if (slot > 0)
  {
    if (mode == 0)  nguraFileHandles[slot] = fopen(request, "r");
    if (mode == 1)  nguraFileHandles[slot] = fopen(request, "w");
    if (mode == 2)  nguraFileHandles[slot] = fopen(request, "a");
    if (mode == 3)  nguraFileHandles[slot] = fopen(request, "r+");
  }
  if (nguraFileHandles[slot] == NULL)
  {
    nguraFileHandles[slot] = 0;
    slot = 0;
  }
  return slot;
}

CELL nguraReadFile() {
  CELL c = fgetc(nguraFileHandles[TOS]); sp--;
  return (c == EOF) ? 0 : c;
}

CELL nguraWriteFile() {
  CELL slot, c, r;
  slot = TOS; sp--;
  c = TOS; sp--;
  r = fputc(c, nguraFileHandles[slot]);
  return (r == EOF) ? 0 : 1;
}

CELL nguraCloseFile() {
  fclose(nguraFileHandles[TOS]);
  nguraFileHandles[TOS] = 0;
  sp--;
  return 0;
}

CELL nguraGetFilePosition() {
  CELL slot = TOS; sp--;
  return (CELL) ftell(nguraFileHandles[slot]);
}

CELL nguraSetFilePosition() {
  CELL slot, pos, r;
  slot = TOS; sp--;
  pos  = TOS; sp--;
  r = fseek(nguraFileHandles[slot], pos, SEEK_SET);
  return r;
}

CELL nguraGetFileSize() {
  CELL slot, current, r, size;
  slot = TOS; sp--;
  current = ftell(nguraFileHandles[slot]);
  r = fseek(nguraFileHandles[slot], 0, SEEK_END);
  size = ftell(nguraFileHandles[slot]);
  fseek(nguraFileHandles[slot], current, SEEK_SET);
  return (r == 0) ? size : 0;
}

CELL nguraDeleteFile() {
  CELL name = TOS; sp--;
  nguraGetString(name);
  return (unlink(request) == 0) ? -1 : 0;
}
#endif
````





### Opcode Processor

| Opcode | Name          | Stack |
| ------ | ------------- | ----- |
| 100    | CONSOLE.PUTC  |  c-   |
| 101    | CONSOLE.PUTN  |  n-   |
| 102    | CONSOLE.PUTS  |  p-   |
| 103    | KEYBOARD.GETC |   -c  |
| 104    | KEYBOARD.GETN |   -n  |
| 105    | KEYBOARD.GETS | cp-n  |

````
void nguraProcessOpcode(CELL opcode) {
  switch(opcode) {
#ifdef NGURA_TTY
    case 100: nguraConsolePutChar((char)data[sp]);
              sp--;
              break;
    case 101: nguraConsolePutNumber(data[sp]);
              sp--;
              break;
#endif
#ifdef NGURA_KBD
    case 103: sp++;
              TOS = nguraConsoleGetChar();
              break;
#endif
  }
}
````

