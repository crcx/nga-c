#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include "nga.c"
int main(int argc, char **argv) {
  ngaPrepare();
  CELL size = 0;
  if (argc == 2)
      size = ngaLoadImage(argv[1]);
  else
      size = ngaLoadImage("ngaImage");
  CELL i;
  printf("CELL ngaImageCells = %d;\n", size);
  printf("CELL ngaImage[] = { ");
  i = 0;
  while (i < size) {
    if (i+1 < size)
      printf("%d,", memory[i]);
    else
      printf("%d };\n", memory[i]);
    i++;
  }
  exit(0);
}
