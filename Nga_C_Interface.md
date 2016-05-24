# Nga Interface

## Overview

Nga is a minimalistic virtual machine emulating a dual stack computer with
a simple instruction set.

The virtual machine does not provide any I/O functionality. This is an
*interface layer* which demonstrates how to use Nga and extend it with some
simple I/O operations.

## The Code

#### Preamble

````
/* Nga ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   Copyright (c) 2008 - 2016, Charles Childers
   Copyright (c) 2009 - 2010, Luke Parrish
   Copyright (c) 2010,        Marc Simpson
   Copyright (c) 2010,        Jay Skeer
   Copyright (c) 2011,        Kenneth Keating
   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
````

Next up, include the needed headers.

````
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
````

#### Headers and Externs

Nga doesn't provide a separate header file. For now it's necessary to manually
specify the header information and externs.

````
#define CELL         int32_t
#define IMAGE_SIZE   262144
CELL ngaLoadImage(char *imageFile);
void ngaPrepare();
void ngaStatsCheckMax();
void ngaProcessOpcode();
void ngaDisplayStats();
extern CELL ip, sp, rsp, memory[], data[];
````

Nga has a function (**ngaProcessOpcode()**) to process a single instruction at
a time. It doesn't provide a full processor loop currently.

The interface layer is intended to provide this, along with handlers for any
additional instructions that may be needed.

The basic loop should be:

    IP = 0
    WHILE IP < IMAGE_SIZE:
        fetch opcode from current memory location
        if opcode is in range that Nga handles:
            execute ngaProcessOpcode()
        otherwise
            provide a custom handler or report an error
        increment IP by 1
    REPEAT

In this simple example, we add a new instruction (#90), which displays a
character on the screen.

````
void processOpcodes() {
  CELL opcode;
  ip = 0;
  while (ip < IMAGE_SIZE) {
    opcode = memory[ip];
    if (opcode >= 0 && opcode < 27)
      ngaProcessOpcode();
    else
      switch(opcode) {
        case 90: printf("%c", (char)data[sp]);
                 break;
      }
    ip++;
  }
}
````

````
int main(int argc, char **argv) {
  ngaPrepare();
  ngaLoadImage("ngaImage");
  processOpcodes();
  int i;
  for (i = 1; i <= sp; i++)
      printf("%d, ", data[i]);
  printf("\n");
  exit(0);
}
````
