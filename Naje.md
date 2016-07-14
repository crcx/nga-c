# Naje

## Overview

Naje is a minimalistic assembler for the Nga instruction set. It provides:

* Single pass (back references only)
* Lables
* Basic literals
* Symbolic names for all instructions

Naje is intended to be a stepping stone for supporting larger applications.
It wasn't designed to be easy or fun to use, just to provide the essentials
needed to build useful things.

## Code

First up, the red tape bits. Include the needed headers and Nga. Naje will use
the Nga memory array, constants, and constraints.

````
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "nga.c"
````

Next up is the dictionary. This is implemented as two arrays:

| name     | description                                                |
| -------- | ---------------------------------------------------------- |
| names    | an array of strings corresponding to label names           |
| pointers | an array of pointers to the memory location for each label |

````
#define MAX_NAMES 1024
#define STRING_LEN 64

char najeLabels[MAX_NAMES][STRING_LEN];
CELL najePointers[MAX_NAMES];
CELL np;

CELL najeLookup(char *name) {
  CELL slice = -1;
  CELL n = np;
  while (n > 0) {
    n--;
    if (strcmp(najeLabels[n], name) == 0)
      slice = najePointers[n];
  }
  return slice;
}


void najeAddLabel(char *name, CELL slice) {
  if (najeLookup(name) == -1) {
    strcpy(najeLabels[np], name);
    najePointers[np] = slice;
    np++;
  } else {
    printf("Fatal error: %s already defined\n", name);
    exit(0);
  }
}
````

````
#ifdef ALLOW_FORWARD_REFS
#define MAX_REFS 1024
char ref_names[MAX_NAMES][STRING_LEN];
CELL ref_offsets[MAX_NAMES];
CELL refp;

void najeAddReference(char *name, CELL slice) {
  strcpy(ref_names[refp], name);
  ref_offsets[refp] = slice;
  refp++;
}
#endif
````

````
#ifdef ENABLE_MAP
void write_map() {
}
#endif
````

Next is the core of the assembler.

| name     | args   | usage                                      |
| -------- | ------ | ------------------------------------------ |
| najeStore    | value  | store a value into memory                  |
| assemble | source | parse and assemble a line of code          |

````
CELL latest;

void najeStore(CELL value) {
  memory[latest] = value;
  latest = latest + 1;
}


void assemble(char *source) {
  char *token;
  char *rest;
  char *ptr = source;

  char relevant[3];
  relevant[0] = 0;
  relevant[1] = 0;
  relevant[2] = 0;

  if (strlen(source) == 0)
    return;

  token = strtok_r(ptr, " ,", &rest);
  ptr = rest;
  relevant[0] = (char)token[0];
  relevant[1] = (char)token[1];

  /* Labels start with : */
  if (relevant[0] == ':') {
    printf("Define: %s\n", (char *)token + 1);
    najeAddLabel((char *)token + 1, latest);
  }

  /* Instructions */
  if (strcmp(relevant, "no") == 0)
    najeStore(0);
  if (strcmp(relevant, "li") == 0) {
    token = strtok_r(ptr, " ,", &rest);
    printf(" <%s>\n", token);
    najeStore(1);
    if (token[0] == '&') {
#ifdef ALLOW_FORWARD_REFS
      najeAddReference((char *)token + 1, latest);
#endif
      najeStore(najeLookup((char *)token + 1));
    } else {
      najeStore(atoi(token));
    }
  }
  if (strcmp(relevant, "du") == 0)
    najeStore(2);
  if (strcmp(relevant, "dr") == 0)
    najeStore(3);
  if (strcmp(relevant, "sw") == 0)
    najeStore(4);
  if (strcmp(relevant, "pu") == 0)
    najeStore(5);
  if (strcmp(relevant, "po") == 0)
    najeStore(6);
  if (strcmp(relevant, "ju") == 0)
    najeStore(7);
  if (strcmp(relevant, "ca") == 0)
    najeStore(8);
  if (strcmp(relevant, "cj") == 0)
    najeStore(9);
  if (strcmp(relevant, "re") == 0)
    najeStore(10);
  if (strcmp(relevant, "eq") == 0)
    najeStore(11);
  if (strcmp(relevant, "ne") == 0)
    najeStore(12);
  if (strcmp(relevant, "lt") == 0)
    najeStore(13);
  if (strcmp(relevant, "gt") == 0)
    najeStore(14);
  if (strcmp(relevant, "fe") == 0)
    najeStore(15);
  if (strcmp(relevant, "st") == 0)
    najeStore(16);
  if (strcmp(relevant, "ad") == 0)
    najeStore(17);
  if (strcmp(relevant, "su") == 0)
    najeStore(18);
  if (strcmp(relevant, "mu") == 0)
    najeStore(19);
  if (strcmp(relevant, "di") == 0)
    najeStore(20);
  if (strcmp(relevant, "an") == 0)
    najeStore(21);
  if (strcmp(relevant, "or") == 0)
    najeStore(22);
  if (strcmp(relevant, "xo") == 0)
    najeStore(23);
  if (strcmp(relevant, "sh") == 0)
    najeStore(24);
  if (strcmp(relevant, "zr") == 0)
    najeStore(25);
  if (strcmp(relevant, "en") == 0)
    najeStore(26);
}
````

The next two functions setup the standard preamble (a jump to :main) and
finalize the image (by patching the jump to the actual offset of :main).

````
void prepare() {
  np = 0;
  latest = 0;

  /* assemble the standard preamble (a jump to :main) */
  najeStore(1);  /* LIT */
  najeStore(0);  /* placeholder */
  najeStore(7);  /* JUMP */
}


void finish() {
  CELL entry = najeLookup("main");
  memory[1] = entry;
}
````

Then two functions for loading a source file and reading it line by line.

````
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
````

Support for saving the results to an image file.

````
void save() {
  FILE *fp;

  if ((fp = fopen("ngaImage", "wb")) == NULL) {
    printf("Unable to save the ngaImage!\n");
    exit(2);
  }

  fwrite(&memory, sizeof(CELL), latest, fp);
  fclose(fp);
}
````

````
CELL main(int argc, char **argv) {
  prepare();
  process_file(argv[1]);
  finish();
  save();

  printf("Bytecode\n");
  for (CELL i = 0; i < latest; i++)
    printf("%d ", memory[i]);
  printf("\nLabels\n");
  for (CELL i = 0; i < np; i++)
    printf("%s@@%d ", najeLabels[i], najePointers[i]);
#ifdef ALLOW_FORWARD_REFS
  printf("\nRefs\n");
  for (CELL i = 0; i < refp; i++)
    printf("%s@@%d ", ref_names[i], ref_offsets[i]);
#endif
  printf("\n");
  return 0;
}
````
