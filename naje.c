#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "nga.c"
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
