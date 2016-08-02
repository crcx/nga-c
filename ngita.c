#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <termios.h>
#include "nga.c"
#include "ngura.c"
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
