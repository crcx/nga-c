# Nga

## Overview

Nga is a minimalistic virtual machine emulating a dual stack computer with
a simple instruction set.

This is an implementation of Nga in C. It is intended to serve as the standard
reference implemenation.

## The Code

#### Preamble

The code begins with the copyright block. Several people contributed to Ngaro
(the direct predecessor of Nga).

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

#### Configuration

To make it easier to adapt Nga to a specific target, we keep some important
constants grouped together at the start of the file.

These defaults are targeted towards a 32-bit model, with several megabytes of
RAM.

For smaller targets, drop the IMAGE_SIZE considerably as that's the biggest
pool of memory needed.

````
#define CELL         int32_t
#define IMAGE_SIZE   80
#define ADDRESSES    10
#define STACK_DEPTH  10
#define LOCAL        "retroImage"
#define CELLSIZE     32
````

#### Naming The Instructions

For this implementation an enum is used to name each of the instructions.

````
enum vm_opcode {VM_NOP,  VM_LIT,   VM_DUP,    VM_DROP,   VM_SWAP,   VM_PUSH,
                VM_POP,  VM_JUMP,  VM_CALL,   VM_IF,     VM_RETURN,
                VM_EQ,   VM_NEQ,   VM_LT,     VM_GT,     VM_FETCH,  VM_STORE,
                VM_ADD,  VM_SUB,   VM_MUL,    VM_DIVMOD, VM_AND,    VM_OR,
                VM_XOR,  VM_SHIFT, VM_ZRET,   VM_END };
#define NUM_OPS VM_END + 1
````

````
CELL sp, rsp, ip;
CELL data[STACK_DEPTH];
CELL address[ADDRESSES];
CELL image[IMAGE_SIZE];
CELL filecells;
int stats[NUM_OPS];
int max_sp, max_rsp;


/* Macros ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
#define DROP { data[sp] = 0; if (--sp < 0) ip = IMAGE_SIZE; }
#define TOS  data[sp]
#define NOS  data[sp-1]
#define TORS address[rsp]

CELL ngaLoadImage(char *imageFile) {
  FILE *fp;
  CELL imageSize;
  long fileLen;
  imageSize = 0;

  if ((fp = fopen(imageFile, "rb")) != NULL) {
    fseek(fp, 0, SEEK_END);
    fileLen = ftell(fp) / sizeof(CELL);
    rewind(fp);
    imageSize = fread(&image, sizeof(CELL), fileLen, fp);
    fclose(fp);
  }
  else {
    printf("Unable to find the ngaImage!\n");
    exit(1);
  }
  filecells = imageSize;
  return imageSize;
}

void ngaProcessOpcode() {
  CELL a, b, c, opcode;
  opcode = image[ip];

  stats[opcode]++;

  printf("%d: %d\n", ip, opcode);

  switch(opcode) {
    case VM_NOP:
         break;
    case VM_LIT:
         sp++;
         ip++;
         TOS = image[ip];
         if (max_sp < sp)
           max_sp = sp;
         break;
    case VM_DUP:
         sp++;
         data[sp] = NOS;
         if (max_sp < sp)
           max_sp = sp;
         break;
    case VM_DROP:
         DROP
         break;
    case VM_SWAP:
         a = TOS;
         TOS = NOS;
         NOS = a;
         break;
    case VM_PUSH:
         rsp++;
         TORS = TOS;
         DROP
         if (max_rsp < rsp)
           max_rsp = rsp;
         break;
    case VM_POP:
         sp++;
         TOS = TORS;
         rsp--;
         break;
    case VM_JUMP:
         ip = TOS - 1;
         DROP;
         break;
    case VM_CALL:
         rsp++;
         TORS = ip;
         if (max_rsp < rsp)
           max_rsp = rsp;
         ip = TOS - 1;
         DROP;
         break;
    case VM_IF:
         rsp++;
         TORS = ip;
         if (max_rsp < rsp)
           max_rsp = rsp;
         a = TOS; DROP;  /* False */
         b = TOS; DROP;  /* True  */
         c = TOS; DROP;  /* Flag  */
         if (c != 0)
             ip = b - 1;
         else
             ip = a - 1;
         break;
    case VM_RETURN:
         ip = TORS;
         rsp--;
         break;
    case VM_GT:
         a = TOS; DROP;
         b = TOS; DROP;
         if(b > a)
             TOS = -1;
         else
             TOS = 0;
         if (max_sp < sp)
           max_sp = sp;
         break;
    case VM_LT:
         a = TOS; DROP;
         b = TOS; DROP;
         if(b < a)
             TOS = -1;
         else
             TOS = 0;
         if (max_sp < sp)
           max_sp = sp;
         break;
    case VM_NEQ:
         a = TOS; DROP;
         b = TOS; DROP;
         if(b != a)
             TOS = -1;
         else
             TOS = 0;
         if (max_sp < sp)
           max_sp = sp;
         break;
    case VM_EQ:
         a = TOS; DROP;
         b = TOS; DROP;
         if(b == a)
             TOS = -1;
         else
             TOS = 0;
         if (max_sp < sp)
           max_sp = sp;
         break;
    case VM_FETCH:
         TOS = image[TOS];
         break;
    case VM_STORE:
         image[TOS] = NOS;
         DROP DROP
         break;
    case VM_ADD:
         NOS += TOS;
         DROP
         break;
    case VM_SUB:
         NOS -= TOS;
         DROP
         break;
    case VM_MUL:
         NOS *= TOS;
         DROP
         break;
    case VM_DIVMOD:
         a = TOS;
         b = NOS;
         TOS = b / a;
         NOS = b % a;
         break;
    case VM_AND:
         a = TOS;
         b = NOS;
         DROP
         TOS = a & b;
         break;
    case VM_OR:
         a = TOS;
         b = NOS;
         DROP
         TOS = a | b;
         break;
    case VM_XOR:
         a = TOS;
         b = NOS;
         DROP
         TOS = a ^ b;
         break;
    case VM_SHIFT:
         /* Left -- TODO */
         a = TOS;
         b = NOS;
         DROP
         TOS = b << a;

         /* Right -- TODO */
         a = TOS;
         DROP
         TOS >>= a;
         break;
    case VM_ZRET:
         if (TOS == 0) {
           DROP
           ip = TORS;
           rsp--;
         }
         break;
    case VM_END:
         ip = IMAGE_SIZE;
         break;
    default:
         printf("Error: %d opcode encountered\n", opcode);
         exit(1);
         break;
  }
}

/* Stats ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
void ngaDisplayStats()
{
  int s, i;

  printf("Runtime Statistics\n");
  printf("NOP:     %d\n", stats[VM_NOP]);
  printf("LIT:     %d\n", stats[VM_LIT]);
  printf("DUP:     %d\n", stats[VM_DUP]);
  printf("DROP:    %d\n", stats[VM_DROP]);
  printf("SWAP:    %d\n", stats[VM_SWAP]);
  printf("PUSH:    %d\n", stats[VM_PUSH]);
  printf("POP:     %d\n", stats[VM_POP]);
  printf("JUMP:    %d\n", stats[VM_JUMP]);
  printf("CALL:    %d\n", stats[VM_CALL]);
  printf(":IF      %d\n", stats[VM_IF]);
  printf("RETURN:  %d\n", stats[VM_RETURN]);
  printf(":EQ      %d\n", stats[VM_EQ]);
  printf(":NEQ     %d\n", stats[VM_NEQ]);
  printf(":LT      %d\n", stats[VM_LT]);
  printf(":GT      %d\n", stats[VM_GT]);
  printf("FETCH:   %d\n", stats[VM_FETCH]);
  printf("STORE:   %d\n", stats[VM_STORE]);
  printf("ADD:     %d\n", stats[VM_ADD]);
  printf("SUB:     %d\n", stats[VM_SUB]);
  printf("MUL:     %d\n", stats[VM_MUL]);
  printf("DIVMOD:  %d\n", stats[VM_DIVMOD]);
  printf("AND:     %d\n", stats[VM_AND]);
  printf("OR:      %d\n", stats[VM_OR]);
  printf("XOR:     %d\n", stats[VM_XOR]);
  printf("SHIFT:   %d\n", stats[VM_SHIFT]);
  printf("ZRET:    %d\n", stats[VM_ZRET]);
  printf("END:     %d\n", stats[VM_END]);
  printf("Max sp:  %d\n", max_sp);
  printf("Max rsp: %d\n", max_rsp);

  for (s = i = 0; s < NUM_OPS; s++)
    i += stats[s];
  printf("Total opcodes processed: %d\n", i);
}


/* Main ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
int main(int argc, char **argv) {
  int wantsStats, i;
  wantsStats = 1;

  ip = 0;
  sp = 0;
  rsp = 0;
  max_sp = 0;
  max_rsp = 0;

  for (ip = 0; ip < IMAGE_SIZE; ip++)
    image[ip] = VM_NOP;

  for (ip = 0; ip < STACK_DEPTH; ip++)
    data[ip] = 0;

  for (ip = 0; ip < ADDRESSES; ip++)
    address[ip] = 0;

  ngaLoadImage("ngaImage");

  for (ip = 0; ip < IMAGE_SIZE; ip++)
    ngaProcessOpcode();

  if (wantsStats == 1)
    ngaDisplayStats();

  for (i = 1; i <= sp; i++)
      printf("%d, ", data[i]);

  printf("\n");

  exit(0);
}
````
