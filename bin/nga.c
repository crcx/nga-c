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
#define IMAGE_SIZE   256*1024
#define ADDRESSES    128
#define STACK_DEPTH  32
#define CELLSIZE     32
enum vm_opcode {
  VM_NOP,  VM_LIT,    VM_DUP,   VM_DROP,    VM_SWAP,   VM_PUSH,
  VM_POP,  VM_JUMP,   VM_CALL,  VM_IF,      VM_RETURN,
  VM_EQ,   VM_NEQ,    VM_LT,    VM_GT,      VM_FETCH,  VM_STORE,
  VM_ADD,  VM_SUB,    VM_MUL,   VM_DIVMOD,  VM_AND,    VM_OR,
  VM_XOR,  VM_SHIFT,  VM_ZRET,  VM_END
};
#define NUM_OPS VM_END + 1
CELL sp, rp, ip;
CELL data[STACK_DEPTH];
CELL address[ADDRESSES];
CELL image[IMAGE_SIZE];
int stats[NUM_OPS];
int max_sp, max_rp;
#define DROP { data[sp] = 0; if (--sp < 0) ip = IMAGE_SIZE; }
#define TOS  data[sp]
#define NOS  data[sp-1]
#define TORS address[rp]
CELL ngaLoadImage(char *imageFile) {
  FILE *fp;
  CELL imageSize;
  long fileLen;

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
  return imageSize;
}
void ngaPrepare() {
  ip = sp = rp = max_sp = max_rp = 0;

  for (ip = 0; ip < IMAGE_SIZE; ip++)
    image[ip] = VM_NOP;

  for (ip = 0; ip < STACK_DEPTH; ip++)
    data[ip] = 0;

  for (ip = 0; ip < ADDRESSES; ip++)
    address[ip] = 0;

  for (ip = 0; ip < NUM_OPS; ip++)
    stats[ip] = 0;
}
void check_max() {
  if (max_sp < sp)
    max_sp = sp;
  if (max_rp < rp)
    max_rp = rp;
}

void inst_nop() {
}
void inst_lit() {
  sp++;
  ip++;
  TOS = image[ip];
  check_max();
}
void inst_dup() {
  sp++;
  data[sp] = NOS;
  check_max();
}

void inst_drop() {
  DROP
}

void inst_swap() {
  int a;
  a = TOS;
  TOS = NOS;
  NOS = a;
}

void inst_push() {
  rp++;
  TORS = TOS;
  DROP
  check_max();
}

void inst_pop() {
  sp++;
  TOS = TORS;
  rp--;
}

void inst_jump() {
  ip = TOS - 1;
  DROP
}

void inst_call() {
  rp++;
  TORS = ip;
  ip = TOS - 1;
  DROP
  check_max();
}

void inst_if() {
  int a, b, c;
  rp++;
  TORS = ip;
  a = TOS; DROP;  /* False */
  b = TOS; DROP;  /* True  */
  c = TOS; DROP;  /* Flag  */
  if (c != 0)
    ip = b - 1;
  else
    ip = a - 1;
  check_max();
}

void inst_return() {
  ip = TORS;
  rp--;
}

void inst_eq() {
  int a, b;
  a = TOS; DROP;
  b = TOS; DROP;
  if (b == a)
    TOS = -1;
  else
    TOS = 0;
}

void inst_neq() {
  int a, b;
  a = TOS; DROP;
  b = TOS; DROP;
  if (b != a)
    TOS = -1;
  else
    TOS = 0;
}

void inst_lt() {
  int a, b;
  a = TOS; DROP;
  b = TOS; DROP;
  if (b < a)
    TOS = -1;
  else
    TOS = 0;
}

void inst_gt() {
  int a, b;
  a = TOS; DROP;
  b = TOS; DROP;
  if (b > a)
    TOS = -1;
  else
    TOS = 0;
}

void inst_fetch() {
  TOS = image[TOS];
}

void inst_store() {
  image[TOS] = NOS;
  DROP
  DROP
}

void inst_add() {
  NOS += TOS;
  DROP
}

void inst_sub() {
  NOS -= TOS;
  DROP
}

void inst_mul() {
  NOS *= TOS;
  DROP
}

void inst_divmod() {
  int a, b;
  a = TOS;
  b = NOS;
  TOS = b / a;
  NOS = b % a;
}

void inst_and() {
}

void inst_or() {
}

void inst_xor() {
}

void inst_shift() {
}

void inst_zret() {
}

void inst_end() {
}

void ngaProcessOpcode() {
  CELL a, b, c, opcode;
  opcode = image[ip];

  stats[opcode]++;

  printf("%d: %d\n", ip, opcode);

  switch(opcode) {
    case VM_NOP: inst_nop();   break;
    case VM_LIT: inst_lit();   break;
    case VM_DUP: inst_dup();   break;
    case VM_DROP: inst_drop();         break;
    case VM_SWAP: inst_swap();         break;
    case VM_PUSH: inst_push();         break;
    case VM_POP: inst_pop();         break;
    case VM_JUMP: inst_jump();         break;
    case VM_CALL: inst_call();         break;
    case VM_IF: inst_if();         break;
    case VM_RETURN: inst_return(); break;
    case VM_GT:   inst_gt();   break;
    case VM_LT:   inst_lt();   break;
    case VM_NEQ:  inst_neq();  break;
    case VM_EQ:   inst_eq();   break;
    case VM_FETCH: inst_fetch();     break;
    case VM_STORE: inst_store(); break;
    case VM_ADD: inst_add();         break;
    case VM_SUB: inst_sub(); break;
    case VM_MUL: inst_mul(); break;
    case VM_DIVMOD: inst_divmod(); break;
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
           rp--;
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
  printf("Max rp:  %d\n", max_rp);

  for (s = i = 0; s < NUM_OPS; s++)
    i += stats[s];
  printf("Total opcodes processed: %d\n", i);
}
int main(int argc, char **argv) {
  int wantsStats, i;
  wantsStats = 1;

  ngaPrepare();

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
