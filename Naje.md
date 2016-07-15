# Naje

Naje is a minimalistic assembler for the Nga instruction set. It provides:

* Two passes: assemble, then resolve lables
* Lables
* Basic literals
* Symbolic names for all instructions
* Facilities for inlining simple data

Naje is intended to be a stepping stone for supporting larger applications.
It wasn't designed to be easy or fun to use, just to provide the essentials
needed to build useful things.

## Instruction Set

Nga has a very small set of instructions. These can be briefly listed in a
short table:

    0  nop        7  jump      14  gt        21  and
    1  lit <v>    8  call      15  fetch     22  or
    2  dup        9  cjump     16  store     23  xor
    3  drop      10  return    17  add       24  shift
    4  swap      11  eq        18  sub       25  zret
    5  push      12  neq       19  mul       26  end
    6  pop       13  lt        20  divmod

All instructions except for **lit** are one cell long. **lit** takes two: one
for the instruction and one for the value to push to the stack.

Naje provides a simple syntax. A short example:

    .output test.nga
    :add
      add
      return
    :subtract
      sub
      return
    :increment
      lit 1
      lit &add
      call
      return
    :main
      lit 100
      lit 95
      lit &subtract
      call
      lit &increment
      call
      end

Delving a bit deeper:

* Blank lines are ok and will be stripped out
* One instruction (or assembler directive) per line
* Labels start with a colon
* A **lit** can be followed by a number or a label name
* References to labels must start with an &

### Technical Notes

Naje has a trivial parser. In deciding how to deal with a line, it will first
strip it to its core elements, then proceed. So given a line like:

    lit 100 ... push 100 to the stack! ...

Naje will take the first two characters of the first token (*li*) to identify
the instruction and the second token for the value. The rest is ignored.

## Instruction Packing

Nga allows for packing multiple instructions per memory location. The Nga code
does this automatically.

What this does is effectively reduce the memory a program takes significantly.
In a standard configuration, cells are 32-bits in length.  With one
instruction per cell, much potential space is wasted. Packing allows up to
four to be stored in each cell.

Some notes on this:

- unused slots are stored as NOP instructions
- packing ends when:

  * four instructions have been queued
  * a flow control instruction has been queued

    - JUMP
    - CJUMP
    - CALL
    - RET
    - ZRET

  * a label is being declared
  * when a **.data** directive is issued

## Code

Include the standard headers and Nga. (This uses various constants and some
dat structures from Nga)

````
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "nga.c"
````

Global variables.

| name         | description                                                |
| ------------ | ---------------------------------------------------------- |
| latest       | index into the **memory** buffer (buffer in *nga.c*)       |
| packed       | array of opcodes for packing                               |
| pindex       | index into **packed**                                      |
| dataList     | array of data elements waiting to be stored                |
| dataType     | array of type codes for data elements                      |
| dindex       | index into **dataList** and **dataType**                   |
| najeLabels   | array of label names                                       |
| najePointers | array of pointers that go with **najeLabels**              |
| np           | index into **najeLabels** and **najePointers**             |
| references   | array of types used to identify references needing patched |

````
CELL latest;
CELL packed[4];
CELL pindex;

CELL dataList[1024];
CELL dataType[1024];
CELL dindex;

#define MAX_NAMES 1024
#define STRING_LEN 64

char najeLabels[MAX_NAMES][STRING_LEN];
CELL najePointers[MAX_NAMES];
CELL np;

CELL references[IMAGE_SIZE];



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

Naje can be configured to allow for forward references. This can use a
significant amount of RAM, so is disabled by default. To enable, compile with
-DALLOW_FORWARD_REFERENCES

````
#ifdef ALLOW_FORWARD_REFS
#define MAX_REFS 32*1024
char ref_names[MAX_NAMES][STRING_LEN];
CELL refp;
#endif

void najeAddReference(char *name) {
#ifdef ALLOW_FORWARD_REFS
  strcpy(ref_names[refp], name);
  refp++;
#endif
}

void najeResolveReferences() {
#ifdef ALLOW_FORWARD_REFS
  CELL offset, matched;

  for (CELL i = 0; i < refp; i++) {
    offset = najeLookup(ref_names[i]);
    matched = 0;
    printf("RESOLVE: %s ", ref_names[i]);
    if (offset != -1) {
        printf(" / defined");
        for (CELL j = 0; j < latest; j++) {
          if (references[j] == 1 && matched == 0) {
            printf(" / success\n");
            memory[j] = offset;
            references[j] = -1;
            matched = -1;
          }
        }
    } else {
      printf(" / failed\n");
    }
  }
#endif
}
````

A *map* is a file which, along with the image file, can be used to identify
specific stored elements.

Mapfiles are stored as tab separated values with a format like:

    type <tab> identifier/value <tab> offset

| type    | usage                 |
| ------- | --------------------- |
| label   | a named offset        |
| literal | a numeric value       |
| pointer | pointer to an address |

To enable this, compile with -DENABLE_MAP.

````
void najeWriteMap() {
#ifdef ENABLE_MAP
  FILE *fp;

  if ((fp = fopen("ngaImage.map", "w")) == NULL) {
    printf("Unable to save the ngaImage.map!\n");
    exit(2);
  }

  for (CELL i = 0; i < np; i++)
    fprintf(fp, "LABEL\t%s\t%d\n", najeLabels[i], najePointers[i]);

  for (CELL i = 0; i < latest; i++) {
    if (references[i] == 0)
      fprintf(fp, "LITERAL\t%d\t%d\n", memory[i], i);
  }

  for (CELL i = 0; i < latest; i++) {
    if (references[i] == -1)
      fprintf(fp, "POINTER\t%d\t%d\n", memory[i], i);
  }

  fclose(fp);
#else
  return;
#endif
}
````

````
void najeStore(CELL type, CELL value) {
  memory[latest] = value;
  references[latest] = type;
  latest = latest + 1;
}


void najeSync() {
  if (pindex == 0 && dindex == 0)
    return;

  if (pindex != 0) {
    unsigned int opcode = 0;
    opcode = packed[3];
    opcode = opcode << 8;
    opcode += packed[2];
    opcode = opcode << 8;
    opcode += packed[1];
    opcode = opcode << 8;
    opcode += packed[0];
    printf("Packed Opcode: %d\n", opcode);
    najeStore(2, opcode);
  }
  if (dindex != 0) {
    for (CELL i = 0; i < dindex; i++)
      najeStore(dataType[i], dataList[i]);
  }
  pindex = 0;
  dindex = 0;
  packed[0] = 0;
  packed[1] = 0;
  packed[2] = 0;
  packed[3] = 0;
}

void najeInst(CELL opcode) {
  if (pindex == 4) {
    najeSync();
  }

  packed[pindex] = opcode;
  pindex++;

  switch (opcode) {
    case 7:
    case 8:
    case 9:
    case 10:
    case 25: printf("___\n");
             najeSync();
             break;
    default: break;
  }
}

void najeData(CELL type, CELL data) {
  dataList[dindex] = data;
  dataType[dindex] = type;
  dindex++;
}

void najeAssemble(char *source) {
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
    najeSync();
    printf("Define: %s\n", (char *)token + 1);
    najeAddLabel((char *)token + 1, latest);
  }

  /* Instructions */
  if (strcmp(relevant, "no") == 0)
    najeInst(0);
  if (strcmp(relevant, "li") == 0) {
    token = strtok_r(ptr, " ,", &rest);
    printf(" <%s>\n", token);
    najeInst(1);
    if (token[0] == '&') {
#ifdef ALLOW_FORWARD_REFS
      najeAddReference((char *)token + 1);
      najeData(1, -9999);
#else
      najeData(0, najeLookup((char *)token + 1));
#endif
    } else {
      najeData(0, atoi(token));
    }
  }
  if (strcmp(relevant, "du") == 0)
    najeInst(2);
  if (strcmp(relevant, "dr") == 0)
    najeInst(3);
  if (strcmp(relevant, "sw") == 0)
    najeInst(4);
  if (strcmp(relevant, "pu") == 0)
    najeInst(5);
  if (strcmp(relevant, "po") == 0)
    najeInst(6);
  if (strcmp(relevant, "ju") == 0)
    najeInst(7);
  if (strcmp(relevant, "ca") == 0)
    najeInst(8);
  if (strcmp(relevant, "cj") == 0)
    najeInst(9);
  if (strcmp(relevant, "re") == 0)
    najeInst(10);
  if (strcmp(relevant, "eq") == 0)
    najeInst(11);
  if (strcmp(relevant, "ne") == 0)
    najeInst(12);
  if (strcmp(relevant, "lt") == 0)
    najeInst(13);
  if (strcmp(relevant, "gt") == 0)
    najeInst(14);
  if (strcmp(relevant, "fe") == 0)
    najeInst(15);
  if (strcmp(relevant, "st") == 0)
    najeInst(16);
  if (strcmp(relevant, "ad") == 0)
    najeInst(17);
  if (strcmp(relevant, "su") == 0)
    najeInst(18);
  if (strcmp(relevant, "mu") == 0)
    najeInst(19);
  if (strcmp(relevant, "di") == 0)
    najeInst(20);
  if (strcmp(relevant, "an") == 0)
    najeInst(21);
  if (strcmp(relevant, "or") == 0)
    najeInst(22);
  if (strcmp(relevant, "xo") == 0)
    najeInst(23);
  if (strcmp(relevant, "sh") == 0)
    najeInst(24);
  if (strcmp(relevant, "zr") == 0)
    najeInst(25);
  if (strcmp(relevant, "en") == 0)
    najeInst(26);
}

void prepare() {
  np = 0;
  latest = 0;

  /* assemble the standard preamble (a jump to :main) */
  najeInst(1);  /* LIT */
  najeData(0, 0);  /* placeholder */
  najeInst(7);  /* JUMP */
}


void finish() {
  CELL entry = najeLookup("main");
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
    najeAssemble(source);
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

CELL main(int argc, char **argv) {
  prepare();
    process_file(argv[1]);
    najeResolveReferences();
    najeSync();
  finish();
  save();

  printf("\nBytecode\n[");
  for (CELL i = 0; i < latest; i++)
    printf("%d, ", memory[i]);
  printf("]\nLabels\n");
  for (CELL i = 0; i < np; i++)
    printf("%s@@%d ", najeLabels[i], najePointers[i]);
  printf("\n");

  najeWriteMap();

  return 0;
}
````
