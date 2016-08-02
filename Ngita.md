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

And then include Nga and Ngura.

````
#include "nga.c"
#include "ngura.c"
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
      nguraProcessOpcode(opcode);
    }
    ip++;
  }
}
````

### ...

````
int main(int argc, char **argv) {
  ngaPrepare();
  if (argc == 2)
      ngaLoadImage(argv[1]);
  else
      ngaLoadImage("ngaImage");

  nguraConsoleInit();

  CELL i;

  processOpcodes();

  for (i = 1; i <= sp; i++)
    printf("%d ", data[i]);
  printf("\n");

  nguraConsoleFinish();
  exit(0);

}
````
