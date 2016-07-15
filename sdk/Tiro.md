# Tiro

## Overview

Tiro is a disassembler for use with Nga images.

The Nga virtual machine has a small instruction set and a simple memory model.
The instructions are:

    0  nop        7  jump      14  gt        21  and
    1  lit <v>    8  call      15  fetch     22  or
    2  dup        9  cjump     16  store     23  xor
    3  drop      10  return    17  add       24  shift
    4  swap      11  eq        18  sub       25  zret
    5  push      12  neq       19  mul       26  end
    6  pop       13  lt        20  divmod

Memory is laid out as a flat, linear array of values (generally 32-bit signed
integers).

Nga allows up to four instructions to be packed into each location.

## Output

A typical example of output might be something like:

    88      en      no      no      no
            26      0       0       0
    89      re      no      no      no
            10      0       0       0
    90      li      fe      li      ca
            1       15      1       8
    91      89
    92      58
    93      re      no      no      no
            10      0       0       0

The left column is the *offset*, the columns to the right are the values or
instructions found in each memory location. Tiro will display both a two
letter abbreviation of the instruction and the instruction number below it.

With an optional *map* file (which can be generated using the *Naje*
assembler), the output can become more useful. With the map, Tiro can display
the above sequence as:

    :main
    88      en      no      no      no
            26      0       0       0

    :(return)
    89      re      no      no      no
            10      0       0       0

    :;;
    90      li      fe      li      ca
            1       15      1       8
    91      89
    92      58
    93      re      no      no      no
            10      0       0       0

While still concise, it should be clearer where function breaks, literals,
etc are.

## The Code

````
#!/usr/bin/env python3

import os, sys, math, time, struct
from struct import pack, unpack
````

### The Map

The map file should be named the same as the image, but with a **.map** suffix.
We load it if it exists.

Maps are stored as tab separated values, one line per row, with the following
structure:

    type  identifier  offset

````
map = []

def tiroLoadMap(imgpath):
  global map
  if os.path.exists('{0}.map'.format(imgpath)):
    with open('{0}.map'.format(imgpath), 'r') as f:
      for line in f.readlines():
        map.append(line.split('\t'))
````

### Mapping Opcodes to Names

This is a quick function to return the two letter abbreviation for an opcode.

````
def name(s):
    if s == 0: return 'no'
    if s == 1: return 'li'
    if s == 2: return 'du'
    if s == 3: return 'dr'
    if s == 4: return 'sw'
    if s == 5: return 'pu'
    if s == 6: return 'po'
    if s == 7: return 'ju'
    if s == 8: return 'ca'
    if s == 9: return 'cj'
    if s == 10: return 're'
    if s == 11: return 'eq'
    if s == 12: return 'ne'
    if s == 13: return 'lt'
    if s == 14: return 'gt'
    if s == 15: return 'fe'
    if s == 16: return 'st'
    if s == 17: return 'ad'
    if s == 18: return 'su'
    if s == 19: return 'mu'
    if s == 20: return 'di'
    if s == 21: return 'an'
    if s == 22: return 'or'
    if s == 23: return 'xo'
    if s == 24: return 'sh'
    if s == 25: return 'zr'
    if s == 26: return 'en'
    return str(s)
````

### Packed Cells

These functions are for unpacking a cell and determining if each byte is a
potentially valid instruction.

````
def tiroUnpack(cell):
    a = cell & 0xFF
    b = (cell >> 8)  & 0xFF
    c = (cell >> 16) & 0xFF
    d = (cell >> 24) & 0xFF
    return a, b, c, d


def tiroIsValidPacked(cell):
    a, b, c, d = tiroUnpack(cell)
    valid = True
    if a < 0 or a > 26: valid = False
    if b < 0 or b > 26: valid = False
    if c < 0 or c > 26: valid = False
    if d < 0 or d > 26: valid = False
    return valid
````

### Displaying a Cell

````
def tiroStringFromPacked(cell):
    a, b, c, d = tiroUnpack(cell)
    return '{0}\t{1}\t{2}\t{3}'.format(name(a), name(b), name(c), name(d))

def tiroOpcodeStringFromPacked(cell):
    a, b, c, d = tiroUnpack(cell)
    return '{0}\t{1}\t{2}\t{3}'.format(a, b, c, d)

def tiroMappedElement(i, cell):
  done = False
  for line in map:
    t, v, o = line
    t = t.lower()
    if int(o) == i:
      if t == 'label':
        print('\n:{0}'.format(v))
      if t == 'literal':
        print('{0}\t{1}'.format(i, v))
        done = True
      if t == 'pointer':
        print('{0}\t{1}'.format(i, v))
        done = True
  return done


def tiroDisplayCellContents(i, cell):
  if not tiroMappedElement(i, cell):
    if tiroIsValidPacked(cell):
      print('{0}\t{1}\n\t{2}'.format(i, tiroStringFromPacked(cell), tiroOpcodeStringFromPacked(cell)))
    else:
      print('{0}\t{1}'.format(i, cell))
````


````
def tiroLoadImageFile(named):
  cells = int(os.path.getsize(named) / 4)
  with open(named, 'rb') as f:
    memory = list(struct.unpack( cells * 'i', f.read() ))
  return memory

if __name__ == "__main__":
  imgpath = sys.argv[1]
  cells = int(os.path.getsize(imgpath) / 4)
  print('Nga Image Dump for: {0}'.format(imgpath))
  print('Dumping {0} cells\n'.format(cells))
  i = 0
  tiroLoadMap(imgpath)
  for v in tiroLoadImageFile(imgpath):
    tiroDisplayCellContents(i, v)
    i = i + 1
````
