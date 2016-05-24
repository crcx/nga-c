/* Nga ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
   Copyright (c) 2008 - 2016, Charles Childers
   Copyright (c) 2009 - 2010, Luke Parrish
   Copyright (c) 2010,        Marc Simpson
   Copyright (c) 2010,        Jay Skeer
   Copyright (c) 2011,        Kenneth Keating
   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#define CELL         int32_t
#define IMAGE_SIZE   262144
CELL ngaLoadImage(char *imageFile);
void ngaPrepare();
void ngaStatsCheckMax();
void ngaProcessOpcode();
void ngaDisplayStats();
extern CELL ip, sp, rsp, memory[], data[];
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
