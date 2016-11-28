#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
void read_line(FILE *file, char *line_buffer) {
  if (file == NULL || line_buffer == NULL)
  {
    printf("Error: file or line buffer pointer is null.");
    exit(1);
  }
  int ch = getc(file);
  int count = 0;
  while ((ch != '\n') && (ch != EOF)) {
    line_buffer[count] = ch;
    count++;
    ch = getc(file);
  }
  line_buffer[count] = '\0';
}
void extract(char *fname) {
  char source[4*1024*1024];
  FILE *fp;
  int inBlock;
  inBlock = 0;
  fp = fopen(fname, "r");
  if (fp == NULL)
    return;
  while (!feof(fp)) {
    read_line(fp, source);
    if (!strcmp(source, "````")) {
      if (inBlock == 0)
        inBlock = 1;
      else
        inBlock = 0;
    } else {
      if ((inBlock == 1) && (strlen(source) != 0))
        printf("%s\n", source);
    }
  }
  fclose(fp);
}
int main(int argc, char **argv) {
  int i = 1;
  if (argc > 1) {
    while (i < argc) {
      extract(argv[i++]);
    }
  }
  else
    printf("unu\n(c) 2013, 2016 charles childers\n\nTry:\n  %s filename\n", argv[0]);
  return 0;
}
