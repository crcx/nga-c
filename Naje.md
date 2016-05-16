# Naje

This is a minimal assembler for the Nga virtual machine instruction set. It
provides:

* labels
* literals (integers, pointers to labels)
* symbolic names for all instructions

Naje is intended to be a stepping stone for supporting larger applications.
It's not designed to be easy or fun to use, just to provide the absolute core
needed to build useful things.

## Instruction Set

Nga has a very small set of instructions. These can be briefly listed in a
short table:

    0  nop        7  jump      14  gt        21  and
    1  lit <v>    8  call      15  fetch     22  or
    2  dup        9  if        16  store     23  xor
    3  drop      10  return    17  add       24  shift
    4  swap      11  eq        18  sub       25  zret
    5  push      12  neq       19  mul       26  end
    6  pop       13  lt        20  divmod

All instructions except for **lit** are one cell long. **lit** takes two: one
for the instruction and one for the value to push to the stack.

## Syntax

Naje provides a simple syntax. A short example:

    :add
      add
      return
    :subtract
      sub
      return
    :increment
      lit 1
      lit add
      call
      return
    :main
      lit 100
      lit 95
      lit subtract
      call
      lit increment
      call
      end

Blank lines are ok, one instruction per line, labels start with a colon. A
**lit** can be followed by a number or a label name. Labels must be defined
before they can be used.

## The Code

First up, the preamble, and some variables.

| name   | usage                                  |
| ------ | -------------------------------------- |
| labels | stores a list of labels and pointers   |
| memory | stores all values                      |
| i      | pointer to the current memory location |

````
#!/usr/bin/env python3

labels = []
resolve = []
memory = []
i = 0
````

The next two functions are for adding labels to the dictionary and searching
for them.

````
def define(id):
    global labels
    labels.append((id, i))

def lookup(id):
    for label in labels:
        if label[0] == id:
            return label[1]
    return -1
````

**comma** is used to compile a value into memory.

````
def comma(v):
    global memory, i
    memory.append(int(v))
    i = i + 1
````

This next one maps a symbolic name to its opcode. It requires a two character
string (this is sufficent to identify any of the instructions).

*It may be worth looking into using a simple lookup table instead of this.*

````
def map_to_inst(s):
    inst = -1
    if s == 'no': inst = 0
    if s == 'li': inst = 1
    if s == 'du': inst = 2
    if s == 'dr': inst = 3
    if s == 'sw': inst = 4
    if s == 'pu': inst = 5
    if s == 'po': inst = 6
    if s == 'ju': inst = 7
    if s == 'ca': inst = 8
    if s == 'if': inst = 9
    if s == 're': inst = 10
    if s == 'eq': inst = 11
    if s == 'ne': inst = 12
    if s == 'lt': inst = 13
    if s == 'gt': inst = 14
    if s == 'fe': inst = 15
    if s == 'st': inst = 16
    if s == 'ad': inst = 17
    if s == 'su': inst = 18
    if s == 'mu': inst = 19
    if s == 'di': inst = 20
    if s == 'an': inst = 21
    if s == 'or': inst = 22
    if s == 'xo': inst = 23
    if s == 'sh': inst = 24
    if s == 'zr': inst = 25
    if s == 'en': inst = 26
    return inst
````

This next function saves the memory image to a file.

````
def save(filename):
    import struct
    with open(filename, 'wb') as file:
        j = 0
        while j < i:
            file.write(struct.pack('i', memory[j]))
            j = j + 1
````

An image starts with a jump to the main entry point (the *:main* label).
Since the offset of *:main* isn't known initially, this compiles a jump to
offset 0, which will be patched by a later routine.

````
def preamble():
    comma(1)
    comma(0)
    comma(7)
````

**patch_entry()** replaces the target of the jump compiled by **preamble()**
with the offset of the *:main* label.

````
def patch_entry():
    memory[1] = lookup('main')
````

A source file consists of a series of lines, with one instruction (or label)
per line. While minimalistic, Naje does allow for blank lines and indention.
This function strips out the leading and trailing whitespace as well as blank
lines so that the rest of the assembler doesn't need to deal with it.

````
def load_source(filename):
    with open(filename, 'r') as f:
        raw = f.readlines()

    cleaned = []
    for line in raw:
        cleaned.append(line.strip())

    final = []
    for line in cleaned:
        if line != '':
            final.append(line)

    return final
````

We now have a couple of routines that are intended to make future maintenance
easier by keeping the source more readable. It should be pretty obvious what
these do.

````
def is_label(token):
    if token[0:1] == ':':
        return True
    else:
        return False

def is_inst(token):
    if map_to_inst(token) == -1:
        return False
    else:
        return True
````

Ok, now for a somewhat messier bit. The **LIT** instruction is two part: the
first is the actual opcode (1), the second (stored in the following cell) is
the value to push to the stack. A source line is setup like:

    lit 100
    lit increment

In the first case, we want to compile the number 100 in the following cell.
But in the second, we need to lookup the *:increment* label and compile a
pointer to it.

````
def handle_lit(line):
    parts = line.split()
    try:
        a = int(parts[1])
        comma(a)
    except:
        xt = lookup(parts[1])
        if xt != -1:
            comma(xt)
        else:
            print('LIT encountered with a value that is not an integer or label')
            print(line)
            exit()
````

Now for the meat of the assembler. This takes a single line of input, checks
to see if it's a label or instruction, and lays down the appropriate code,
calling whatever helper functions are needed (**handle_lit()** being notable).

````
def assemble(line):
    token = line[0:2]
    if is_label(token):
        labels.append((line[1:], i))
        print('label = ', line, '@', i)
    elif is_inst(token):
        op = map_to_inst(token)
        comma(op)
        if op == 1:
            handle_lit(line)
    else:
        print('Line was not a label or instruction.')
        print(line)
        exit()
````

And finally we can tie everything together into a coherent package.

````
if __name__ == '__main__':
    preamble()
    src = load_source('test.naje')
    for line in src:
        assemble(line)
    patch_entry()
    save('test.bin')

    print(src)
    print(labels)
    print(memory)
````

## TODO

There is still some work needed on this.

* ability to specify input file name from command line
* ability to specify output file name from the command line
