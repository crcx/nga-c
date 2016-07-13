#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "nga.c"
#define MAX_NAMES 1024
#define STRING_LEN 64

char names[MAX_NAMES][STRING_LEN];
CELL pointers[MAX_NAMES];
CELL np;

CELL lookup(char *name) {
  CELL slice = -1;
  CELL n = np;
  while (n > 0) {
    n--;
    if (strcmp(names[n], name) == 0)
      slice = pointers[n];
  }
  return slice;
}


void new_label(char *name, CELL slice) {
  if (lookup(name) == -1) {
    strcpy(names[np], name);
    pointers[np] = slice;
    np++;
  } else {
    printf("Fatal error: %s already defined\n", name);
    exit(0);
  }
}
CELL latest;

void comma(CELL value) {
  memory[latest] = value;
  latest = latest + 1;
}


void assemble(char *source) {
  char *token;
  char *rest;
  char *ptr = source;

  char prefix[3];
  prefix[0] = 0;
  prefix[1] = 0;
  prefix[2] = 0;

  if (strlen(source) == 0)
    return;

  token = strtok_r(ptr, " ,", &rest);
  ptr = rest;
  prefix[0] = (char)token[0];
  prefix[1] = (char)token[1];

  /* Labels start with : */
  if (prefix[0] == ':') {
    printf("Define: %s\n", (char *)token + 1);
    new_label((char *)token + 1, latest);
  }

  /* Instructions */
  if (strcmp(prefix, "no") == 0)
    comma(0);
  if (strcmp(prefix, "li") == 0) {
    printf("\nopcode 1");
    token = strtok_r(ptr, " ,", &rest);
    printf(" <%s>\n", token);
    comma(1);
    if (token[0] == '&') {
      comma(lookup((char *)token + 1));
    } else {
      comma(atoi(token));
    }
  }
  if (strcmp(prefix, "du") == 0)
    comma(2);
  if (strcmp(prefix, "dr") == 0)
    comma(3);
  if (strcmp(prefix, "sw") == 0)
    comma(4);
  if (strcmp(prefix, "pu") == 0)
    comma(5);
  if (strcmp(prefix, "po") == 0)
    comma(6);
  if (strcmp(prefix, "ju") == 0)
    comma(7);
  if (strcmp(prefix, "ca") == 0)
    comma(8);
  if (strcmp(prefix, "cj") == 0)
    comma(9);
  if (strcmp(prefix, "re") == 0)
    comma(10);
  if (strcmp(prefix, "eq") == 0)
    comma(11);
  if (strcmp(prefix, "ne") == 0)
    comma(12);
  if (strcmp(prefix, "lt") == 0)
    comma(13);
  if (strcmp(prefix, "gt") == 0)
    comma(14);
  if (strcmp(prefix, "fe") == 0)
    comma(15);
  if (strcmp(prefix, "st") == 0)
    comma(16);
  if (strcmp(prefix, "ad") == 0)
    comma(17);
  if (strcmp(prefix, "su") == 0)
    comma(18);
  if (strcmp(prefix, "mu") == 0)
    comma(19);
  if (strcmp(prefix, "di") == 0)
    comma(20);
  if (strcmp(prefix, "an") == 0)
    comma(21);
  if (strcmp(prefix, "or") == 0)
    comma(22);
  if (strcmp(prefix, "xo") == 0)
    comma(23);
  if (strcmp(prefix, "sh") == 0)
    comma(24);
  if (strcmp(prefix, "zr") == 0)
    comma(25);
  if (strcmp(prefix, "en") == 0)
    comma(26);
}
void prepare() {
  np = 0;
  latest = 0;

  /* assemble the standard preamble (a jump to :main) */
  comma(1);  /* LIT */
  comma(0);  /* placeholder */
  comma(7);  /* JUMP */
}


void finish() {
  CELL entry = lookup("main");
  memory[1] = entry;
}
void read_line(FILE *file, char *line_buffer) {
  if (file == NULL) {
    printf("Error: file pointer is null.");
    exit(1);
  }

  if (line_buffer == NULL) {
    printf("Error allocating memory for line buffer.");
    exit(1);
  }

  char ch = getc(file);
  CELL count = 0;

  while ((ch != '\n') && (ch != EOF)) {
    line_buffer[count] = ch;
    count++;
    ch = getc(file);
  }

  line_buffer[count] = '\0';
}


void process_file(char *fname) {
  char source[64000];

  FILE *fp;

  fp = fopen(fname, "r");
  if (fp == NULL)
    return;

  while (!feof(fp)) {
    read_line(fp, source);
    printf("::: '%s'\n", source);
    assemble(source);
  }

  fclose(fp);
}
void save() {
  FILE *fp;

  if ((fp = fopen("ngaImage", "wb")) == NULL) {
    printf("Unable to save the ngaImage!\n");
    exit(2);
  }

  fwrite(&memory, sizeof(CELL), latest, fp);
  fclose(fp);
}
CELL main() {
  prepare();
  process_file("test.a");
  finish();
  save();

  printf("Bytecode\n");
  for (CELL i = 0; i < latest; i++)
    printf("%d ", memory[i]);
  printf("\nLabels\n");
  for (CELL i = 0; i < np; i++)
    printf("%s@@%d ", names[i], pointers[i]);
  printf("\n");
  return 0;
}
