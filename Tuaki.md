     _               _    _ 
    | |_ _   _  __ _| | _(_)
    | __| | | |/ _` | |/ / |
    | |_| |_| | (_| |   <| |
     \__|\__,_|\__,_|_|\_\_|

Tuaki is a dissassembler for Nga bytecode.

........................................................................


........................................................................

````
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#define CELL         int32_t
#define IMAGE_SIZE   524288 * 16
#define ADDRESSES    2048
#define STACK_DEPTH  512
CELL memory[IMAGE_SIZE + 1];

CELL ngaLoadImage(char *imageFile) {
  FILE *fp;
  CELL imageSize;
  long fileLen;
  if ((fp = fopen(imageFile, "rb")) != NULL) {
    /* Determine length (in cells) */
    fseek(fp, 0, SEEK_END);
    fileLen = ftell(fp) / sizeof(CELL);
    rewind(fp);
    /* Read the file into memory */
    imageSize = fread(&memory, sizeof(CELL), fileLen, fp);
    fclose(fp);
  }
  else {
    printf("Unable to find the ngaImage!\n");
    exit(1);
  }
  return imageSize;
}

int ngaValidatePackedOpcodes(CELL opcode) {
  CELL raw = opcode;
  CELL current;
  int valid = -1;
  int i;
  for (i = 0; i < 4; i++) {
    current = raw & 0xFF;
    if (!(current >= 0 && current <= 26))
      valid = 0;
    raw = raw >> 8;
  }
  return valid;
}

void ngaProcessPackedOpcodes(CELL opcode, CELL ip) {
  CELL raw = opcode;
  int i;
  char *opcodes = "..lidudrswpupojucaccreeqneltgtfestadsumudianorxoshzren";
  printf("i ");
  for (i = 0; i < 4; i++) {
    printf("%c", opcodes[(raw & 0xFF) * 2]);
    printf("%c", opcodes[((raw & 0xFF) * 2) + 1]);
    raw = raw >> 8;
  }
  printf("\t%d\t%d\n", ip, opcode);
}

int main(int argc, char **argv) {
  printf("  data\t\taddr\traw\n");

  CELL last = 0;
  if (argc == 2)
      last = ngaLoadImage(argv[1]);
  else
      last = ngaLoadImage("ngaImage");
  CELL opcode, i = 0;
  while (i < last) {
    opcode = memory[i];
    if (ngaValidatePackedOpcodes(opcode) != 0) {
      ngaProcessPackedOpcodes(opcode, i);
    } else {
      printf("d %d\n", opcode);
    }
    i++;
  }
  printf("\n");
  exit(0);
}
````
