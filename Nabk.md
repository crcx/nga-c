# Nabk

## Overview

The standard assembler for Nga (*Naje*) is very minimalistic in what
it accepts. Nabk is a preprocessor which converts a richer assembly language
into the form required for Naje.

## Syntax

As with Naje, the Nabk preprocessor assumes one instrution per line, with
labels on their own lines.

### Labels

A label starts with a colon, as in:

    :increment
    :main

Labels can contain any valid ASCII other than control characters or
whitespace:

    :+
    :~~Hello!

### Basic Intructions

Nabk allows for all basic instructions to be used. From the Naje
documentation:

    0  nop        7  jump      14  gt        21  and
    1  lit <v>    8  call      15  fetch     22  or
    2  dup        9  if        16  store     23  xor
    3  drop      10  return    17  add       24  shift
    4  swap      11  eq        18  sub       25  zret
    5  push      12  neq       19  mul       26  end
    6  pop       13  lt        20  divmod

### Literals

Naje allows for pushing values to the stack with **lit**:

    lit 100
    lit pointername

Nabk adds this to allow multiple values:

    data: 100 200 300 400

### Calls and Jumps

Nga's **CALL** and **JUMP** instructions take the address from the stack. The
canonical way to do a jump or call is:

    lit pointername
    call

    lit pointername
    jump

Nabk allows calls or jumps with a single line, making intent clearer:

    call pointername
    jump pointername

## The Code

````
#!/usr/bin/env python3
import naje

src = []
with open('test.nabk') as f:
    src = f.readlines()

for line in src:
    tokens = line.split()
    if len(tokens) > 0:
        if len(tokens) == 1:
            print(tokens[0])
        else:
            if tokens[0] == 'lit' or tokens[0] == 'li':
                print('lit', tokens[1])
            if tokens[0] == 'call':
                print('lit', tokens[1])
                print('call')
            if tokens[0] == 'jump':
                print('lit', tokens[1])
                print('jump')

## TODO: implement data:
````
