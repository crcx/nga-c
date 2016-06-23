# Naje

Naje is a minimalistic assembler for the Nga instruction set. It provides:

* Two passes: assemble, then resolve lables
* Lables
* Basic literals
* Symbolic names for all instructions
* Facilities for inlining simple data
* Directives for setting output filename

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

## Syntax

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

### Assembler Directives

Naje provides two directives which can be useful:

**.o**utput is used to set the name of the file that will be created with
the Nga bytecode. If none is set, the filename will be defaulted to
*output.nga*

Example:

    .output sample.nga

**.d**ata is used to inline raw data into the generated image.

Example:

    .data 98
    .data 99
    .data 100

### Technical Notes

Naje has a trivial parser. In deciding how to deal with a line, it will first
strip it to its core elements, then proceed. So given a line like:

    lit 100 ... push 100 to the stack! ...

Naje will take the first two characters of the first token (*li*) to identify
the instruction and the second token for the value. The rest is ignored.

## The Code

First up, the preamble, and some variables.

| name   | usage                                               |
| ------ | --------------------------------------------------- |
| output | stores the name of the file for the assembled image |
| labels | stores a list of labels and pointers                |
| memory | stores all values                                   |
| i      | pointer to the current memory location              |

````
#!/usr/bin/env python3
import sys

output = ''
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
    try:
        memory.append(int(v))
    except ValueError:
        memory.append(v)
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
    if s == 'cj': inst = 9
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
    comma(1)  # LIT
    comma(0)  # value will be patched to point to :main
    comma(7)  # JUMP
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
def clean_source(raw):
    cleaned = []
    for line in raw:
        cleaned.append(line.strip())
    final = []
    for line in cleaned:
        if line != '':
            final.append(line)
    return final


def load_source(filename):
    with open(filename, 'r') as f:
        raw = f.readlines()
    return clean_source(raw)
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

def is_directive(token):
    if token[0:1] == '.':
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
    lit &increment

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
        xt = str(parts[1])
        comma(xt)
````

For assembler directives we have a single handler. There are currently two
directives; one for setting the **output** filename and one for inlining data.

````
def handle_directive(line):
    global output
    parts = line.split()
    token = line[0:2]
    if token == '.o': output = parts[1]
    if token == '.d': comma(int(parts[1]))
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
    elif is_directive(token):
        handle_directive(line)
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

**resolve_labels()** is the second pass; it converts any labels into addresses.

````
def resolve_labels():
    global memory
    results = []
    for cell in memory:
        value = 0
        try:
            value = int(cell)
        except ValueError:
            value = lookup(cell[1:])
            if value == -1:
                print('Label not found!')
                exit()
        results.append(value)
    memory = results
````

And finally we can tie everything together into a coherent package.

````
if __name__ == '__main__':
    if len(sys.argv) < 3:
        raw = []
        for line in sys.stdin:
            raw.append(line)
        src = clean_source(raw)
    else:
        src = load_source(sys.argv[1])

    preamble()
    for line in src:
        assemble(line)
    resolve_labels()
    patch_entry()

    if len(sys.argv) < 3:
        if output == '':
            save('output.nga')
        else:
            save(output)
    else:
        save(sys.argv[2])

    print(src)
    print(labels)
    print(memory)
````
