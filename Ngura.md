# Ngura

## Overview

Ngura is an I/O model for Nga.

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
    case 100: printf("%c", (char)data[sp]);
              sp--;
              break;
    case 101: printf("%d", data[sp]);
              sp--;
              break;
    case 102: printf("\n+ ERROR: IO OPERATION %d NOT IMPLEMENTED\n", opcode);
              break;
    case 103: sp++;
              TOS = getc(stdin);
              break;
    case 104: printf("\n+ ERROR: IO OPERATION %d NOT IMPLEMENTED\n", opcode);
              break;
    case 105: printf("\n+ ERROR: IO OPERATION %d NOT IMPLEMENTED\n", opcode);
              break;
    case 106: printf("\n+ ERROR: IO OPERATION %d NOT IMPLEMENTED\n", opcode);
              break;
    case 107: printf("\n+ ERROR: IO OPERATION %d NOT IMPLEMENTED\n", opcode);
              break;
    case 108: printf("\n+ ERROR: IO OPERATION %d NOT IMPLEMENTED\n", opcode);
              break;
    case 109: printf("\n+ ERROR: IO OPERATION %d NOT IMPLEMENTED\n", opcode);
              break;
    case 110: printf("\n+ ERROR: IO OPERATION %d NOT IMPLEMENTED\n", opcode);
              break;
  }
}
````

### ...

````
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
````
