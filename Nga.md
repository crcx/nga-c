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
#define IMAGE_SIZE   262144
#define ADDRESSES    128
#define STACK_DEPTH  32
#define CELLSIZE     32
````

#### Naming The Instructions

For this implementation an enum is used to name each of the instructions. For
reference, here are the instructions and their corresponding values (in
decimal):

    0  nop        7  jump      14  gt        21  and
    1  lit <v>    8  call      15  fetch     22  or
    2  dup        9  cjump     16  store     23  xor
    3  drop      10  return    17  add       24  shift
    4  swap      11  eq        18  sub       25  zret
    5  push      12  neq       19  mul       26  end
    6  pop       13  lt        20  divmod

````
enum vm_opcode {
  VM_NOP,  VM_LIT,    VM_DUP,   VM_DROP,    VM_SWAP,   VM_PUSH,  VM_POP,
  VM_JUMP, VM_CALL,   VM_CJUMP, VM_RETURN,  VM_EQ,     VM_NEQ,   VM_LT,
  VM_GT,   VM_FETCH,  VM_STORE, VM_ADD,     VM_SUB,    VM_MUL,   VM_DIVMOD,
  VM_AND,  VM_OR,     VM_XOR,   VM_SHIFT,   VM_ZRET,   VM_END
};
#define NUM_OPS VM_END + 1
````

The VM state is held in a few global variables. (It'd be better to use a
struct here, as Ngaro does, but this makes everything else a bit less
readable.

Some things to note:

The data stack (**data**), address stack (**address**), and memory (**memory**)
are simple linear arrays.

There are stack pointers (**sp** for **data** and **rp** for **address**),
and an instruction pointer (**ip**). These are *not* exposed via the
instruction set.

There are three additional items that aren't strictly necessary:

* **stats** is used to hold the number of times an instruction is executed
* **max_sp** holds the highest value **sp** has been assigned to
* **max_rp** holds the highest value **rp** has been assigned to

````
CELL sp, rp, ip;
CELL data[STACK_DEPTH];
CELL address[ADDRESSES];
CELL memory[IMAGE_SIZE];
int stats[NUM_OPS];
int max_sp, max_rp;
````

The final thing before we enter the actual code is a couple of snippits that
we let the preprocessor inline for us. These are intended to make the code a
bit more readable later.

````
#define TOS  data[sp]
#define NOS  data[sp-1]
#define TORS address[rp]
````

#### Loading an Image File

A standard image file is a raw memory dump of 32-bit, signed integer values.

What we do here is:

* attempt to open the file
* use **fseek()** and **ftell()** to find the length of the file.
* divide the length by the size of a cell to determine the number of cells
* read the cells into memory (**image**)
* return the size of the data read (in bytes)

````
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
````

#### Preparations

This function initializes all of the variables and fills the arrays with
known values. Memory is filled with **VM_NOP** instructions; the others are
populated with zeros.

````
void ngaPrepare() {
  ip = sp = rp = max_sp = max_rp = 0;

  for (ip = 0; ip < IMAGE_SIZE; ip++)
    memory[ip] = VM_NOP;

  for (ip = 0; ip < STACK_DEPTH; ip++)
    data[ip] = 0;

  for (ip = 0; ip < ADDRESSES; ip++)
    address[ip] = 0;

  for (ip = 0; ip < NUM_OPS; ip++)
    stats[ip] = 0;
}
````

#### Statistics

This implementation of Nga tracks the number of times each instruction is
reached during an application's run. It also tracks the maximum stack depth
for both stacks.

This information can be useful when debugging and profiling code. If your
host system is resource contrained it may be worth dropping this to save a
little space and processing time.

**ngaStatsCheckMax()** is used by a few of the instructions to check the
current stack depths against the previous maximum and updates it if
necessary. Only instructions that push more than they consume need to call
this. These are **LIT**, **DUP**, **PUSH**, **CALL**, and **IF**.

````
void ngaStatsCheckMax() {
  if (max_sp < sp)
    max_sp = sp;
  if (max_rp < rp)
    max_rp = rp;
}
````

The other function of interest is **ngaDisplayStats()**. It provides the basic
output on the usage of each instruction and the maximum stack depths.

````
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
  printf("CJUMP:   %d\n", stats[VM_CJUMP]);
  printf("RETURN:  %d\n", stats[VM_RETURN]);
  printf("EQ:      %d\n", stats[VM_EQ]);
  printf("NEQ:     %d\n", stats[VM_NEQ]);
  printf("LT:      %d\n", stats[VM_LT]);
  printf("GT:      %d\n", stats[VM_GT]);
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
````


#### The Instructions

I've chosen to implement each instruction as a separate function. This keeps
them shorter, and lets me simplify the instruction processor later on.

There is a bit of commentary on each one, but see the Nga Specification for
full details.

The **NOP** instruction does nothing.

````
void inst_nop() {
}
````

**LIT** is a special case: it's followed by a value to push to the stack. This
needs to increment the **sp** and **ip** and push the value at the incremented
**ip** to the stack.

````
void inst_lit() {
  sp++;
  ip++;
  TOS = memory[ip];
  ngaStatsCheckMax();
}
````

**DUP** duplicates the top item on the stack.

````
void inst_dup() {
  sp++;
  data[sp] = NOS;
  ngaStatsCheckMax();
}
````

**inst_drop();** removes the top item from the stack.

````
void inst_drop() {
  data[sp] = 0;
   if (--sp < 0)
     ip = IMAGE_SIZE;
}
````

**SWAP** switches the top and second items on the stack.

````
void inst_swap() {
  int a;
  a = TOS;
  TOS = NOS;
  NOS = a;
}
````

**PUSH** moves the top value from the data stack to the address stack.

````
void inst_push() {
  rp++;
  TORS = TOS;
  inst_drop();
  ngaStatsCheckMax();
}
````

**POP** moves the top item on the address stack to the data stack.

````
void inst_pop() {
  sp++;
  TOS = TORS;
  rp--;
}
````

**JUMP** moves execution to the address on the top of the stack.

````
void inst_jump() {
  ip = TOS - 1;
  inst_drop();
}
````

**CALL** calls a subroutine at the address on the top of the stack.

````
void inst_call() {
  rp++;
  TORS = ip;
  ip = TOS - 1;
  inst_drop();
  ngaStatsCheckMax();
}
````

**CJUMP** is a conditional call. It takes two values: a flag and a pointer for
an address to jump to if the flag is true.

A false flag is zero. Any other value is true.

Example:

    :t
      lit 100
      return
    :f
      lit 200
      return
    :main
      lit 1
      lit 2
      eq
      lit t
      cjump
      li f
      call
    end

````
void inst_cjump() {
  int a, b;
  rp++;
  TORS = ip;
  a = TOS; inst_drop();  /* False */
  b = TOS; inst_drop();  /* Flag  */
  if (b != 0)
    ip = a - 1;
}
````

**RETURN** ends a subroutine and returns flow to the instruction following
the last **CALL**.

````
void inst_return() {
  ip = TORS;
  rp--;
}
````

**EQ** compares two values for equality and returns a flag.

````
void inst_eq() {
  if (NOS == TOS)
    NOS = -1;
  else
    NOS = 0;
  inst_drop();
}
````

**NEQ** compares two values for inequality and returns a flag.

````
void inst_neq() {
  if (NOS != TOS)
    NOS = -1;
  else
    NOS = 0;
  inst_drop();
}
````

**LT** compares two values for less than and returns a flag.

````
void inst_lt() {
  if (NOS < TOS)
    NOS = -1;
  else
    NOS = 0;
  inst_drop();
}
````

**GT** compares two values for greater than and returns a flag.

````
void inst_gt() {
  if (NOS > TOS)
    NOS = -1;
  else
    NOS = 0;
  inst_drop();
}
````

**FETCH** takes an address and returns the value stored there.

````
void inst_fetch() {
  TOS = memory[TOS];
}
````

**STORE** stores a value into an address.

````
void inst_store() {
  memory[TOS] = NOS;
  inst_drop();
  inst_drop();
}
````

**ADD* adds two numbers together.

````
void inst_add() {
  NOS += TOS;
  inst_drop();
}
````

**SUB** subtracts two numbers.

````
void inst_sub() {
  NOS -= TOS;
  inst_drop();
}
````

**MUL** multiplies two numbers.

````
void inst_mul() {
  NOS *= TOS;
  inst_drop();
}
````

**DIVMOD** divides and returns the quotient and remainder.

````
void inst_divmod() {
  int a, b;
  a = TOS;
  b = NOS;
  TOS = b / a;
  NOS = b % a;
}
````

**AND** performs a bitwise AND operation.

````
void inst_and() {
  NOS = TOS & NOS;
  inst_drop();
}
````

**OR** performs a bitwise OR operation.

````
void inst_or() {
  NOS = TOS | NOS;
  inst_drop();
}
````

**XOR** performs a bitwise XOR operation.

````
void inst_xor() {
  NOS = TOS ^ NOS;
  inst_drop();
}
````

**SHIFT** performs a bitwise SHIFT operation.

````
void inst_shift() {
  if (TOS < 0)
    NOS = NOS << (TOS * -1);
  else
    NOS >>= TOS;
  inst_drop();
}
````

**ZRET** returns from a subroutine if the top item on the stack is zero. If
not, it acts like a **NOP** instead.

````
void inst_zret() {
  if (TOS == 0) {
    inst_drop();
    ip = TORS;
    rp--;
  }
}
````

**END** tells Nga that execution should end.

````
void inst_end() {
  ip = IMAGE_SIZE;
}
````

## Instruction Handler

In the past I handled the instructions via a big switch. With Nga, I changed
this to use a jump table. This is significantly more concise and makes
maintenance easier overall.

So first up, the jump table itself. Just a list of pointers to the instruction
implementations, in the proper order.

````
typedef void (*Handler)(void);

Handler instructions[NUM_OPS] = {
  inst_nop, inst_lit, inst_dup, inst_drop, inst_swap, inst_push, inst_pop,
  inst_jump, inst_call, inst_cjump, inst_return, inst_eq, inst_neq, inst_lt,
  inst_gt, inst_fetch, inst_store, inst_add, inst_sub, inst_mul, inst_divmod,
  inst_and, inst_or, inst_xor, inst_shift, inst_zret, inst_end
};
````

And now **ngaProcessOpcode()** which calls the functions in the jump table.
This also updates the statistics for each.

````
void ngaProcessOpcode() {
  stats[memory[ip]]++;
  instructions[memory[ip]]();
}
````


````
#ifdef STANDALONE
int main(int argc, char **argv) {
  ngaPrepare();
  if (argc == 2)
      ngaLoadImage(argv[1]);
  else
      ngaLoadImage("ngaImage");

  CELL opcode, i;

  ip = 0;
  while (ip < IMAGE_SIZE) {
    opcode = memory[ip];
    if (opcode >= 0 && opcode < 27) {
      ngaProcessOpcode();
    } else {
      printf("Invalid instruction!\n");
      printf("At %d, opcode %d\n", ip, opcode);
      exit(1);
    }
    ip++;
  }

  for (i = 1; i <= sp; i++)
    printf("%d ", data[i]);
  printf("\n");
  exit(0);
}
#endif
