# Ngita

## Overview


Ngita is an interface layer for Nga. It's intended to be the basis of the
next generation of Retro.

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

And then include Nga.

````
#include "nga.c"
````

### Opcode Processor

````
void processOpcodes() {
  CELL opcode;
  ip = 0;
  while (ip < IMAGE_SIZE) {
    opcode = memory[ip];
    if (ngaValidatePackedOpcodes(opcode) != 0) {
      ngaProcessPackedOpcodes(opcode);
    } else if (opcode >= 0 && opcode < 27) {
      ngaProcessOpcode(opcode);
    } else {
      switch(opcode) {
        case 90: printf("%c", (char)data[sp]);
                 sp--;
                 break;
        case 91: sp++;
                 TOS = getc(stdin);
                 break;
      }
    }
    ip++;
  }
}
````

### ...

````
int main(int argc, char **argv) {
  struct termios new_termios, old_termios;

  ngaPrepare();
  if (argc == 2)
      ngaLoadImage(argv[1]);
  else
      ngaLoadImage("ngaImage");

  tcgetattr(0, &old_termios);
  new_termios = old_termios;
  new_termios.c_iflag &= ~(BRKINT+ISTRIP+IXON+IXOFF);
  new_termios.c_iflag |= (IGNBRK+IGNPAR);
  new_termios.c_lflag &= ~(ICANON+ISIG+IEXTEN+ECHO);
  new_termios.c_cc[VMIN] = 1;
  new_termios.c_cc[VTIME] = 0;
  tcsetattr(0, TCSANOW, &new_termios);

  CELL i;

  processOpcodes();

  for (i = 1; i <= sp; i++)
    printf("%d ", data[i]);
  printf("\n");

  tcsetattr(0, TCSANOW, &old_termios);
  exit(0);

}
````
