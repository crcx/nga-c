# Naje

Naje is a minimalistic assembler for the Nga instruction set. It provides:

* Two passes: assemble, then resolve lables
* Lables
* Basic literals
* Symbolic names for all instructions
* Facilities for inlining simple data
* Directives for setting output filename
* Directives for controlling instruction packing

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

Naje provides four directives which can be useful:

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

**.p**acked enables instruction packing.

**.u**unpacked disables instruction packing.

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

  * a label is being declared
  * when a **.data** directive is issued

Instruction packing is enabled by default. It can be controlled via the
**.p** and **.u** directives.

## The Code

### Imports

````
#!/usr/bin/env python3
import struct
import sys
````

### Global Variables

| name    | usage                                                 |
| ------- | ----------------------------------------------------- |
| output  | stores the name of the file for the assembled image   |
| labels  | stores a list of labels and pointers                  |
| memory  | stores all values                                     |
| i       | pointer to the current memory location                |
| insts   | a list of instructions waiting to be packed           |
| datas   | a list of data waiting to be written                  |
| packed  | a flag indicating whether or not to pack instructions |
| map     | a list of tuples that will be saved as a .map file    |

````
output = ''
labels = []
memory = []
i = 0
insts = []
datas = []
packed = True
map = []
````

### Map

A *map* is a file which, along with the image file, can be used to identify
specific stored elements.

Mapfiles are stored as tab separated values with a format like:

    type <tab> identifier/value <tab> offset

| type    | usage                 |
| ------- | --------------------- |
| label   | a named offset        |
| literal | a numeric value       |
| pointer | pointer to an address |
| raw     | raw data              |

````
def addToMap(type, id, offset):
    global map
    map.append((type, id, offset))

def saveMap(basename):
    with open('{0}.map'.format(basename), 'w') as mapFile:
        for row in map:
            mapFile.write('{0}\t{1}\t{2}\n'.format(row[0], row[1], row[2]))
````

### Assembler Core

This is the heart of the assembler: it takes the instructions and data and
writes them to the **memory** array.

| name  | args | intended use
| ----- | ---- | ------------------------------------------------------- |
| comma | v    | write a value to memory                                 |
| inst  | v    | add an instruction to the list for packing              |
| data  | v    | add a data element to the list for writing              |
| sync  |      | pack instructions and write them and the data to memory |

Normally **comma()** should not be called directly: use **inst()** and
**data()** instead to queue items up.

````
def comma(v):
    global memory, i
    try:
        memory.append(int(v))
    except ValueError:
        memory.append(v)
    i = i + 1
````

**sync()** handles several tasks:

- checks to see if there is anything waiting to be written
- packs instructions, padding with **NOP** if needed
- writes instructions (via **comma()**)
- writes data (via **comma()**)
- resets the queues

It'll be called automatically by Naje where needed.

````
def sync():
    global insts, datas
    if packed:
        if len(insts) == 0 and len(datas) == 0:
            return
        if len(insts) < 4 and len(insts) != 0:
            n = len(insts)
            while n < 4:
                inst(0)
                n = n + 1
        if len(insts) != 0:
            insts[0] = insts[0] & 0xFF
            insts[1] = insts[1] & 0xFF
            insts[2] = insts[2] & 0xFF
            insts[3] = insts[3] & 0xFF
            opcode = int.from_bytes(insts, byteorder='little', signed=False)
            comma(opcode)
        if len(datas) != 0:
            for value in datas:
               addToMap('literal', value, i)
               comma(value)
    insts = []
    datas = []
````

**inst()** adds an instruction to the queue. If there are enough for packing
it'll call **sync()**. It also invokes **sync()** if a flow control
instruction is detected.

If packing is disabled, this just passes the data to **comma()**.

````
def inst(v):
    global insts
    if packed:
        if len(insts) == 4:
            sync()
        insts.append(v)
        if v == 7 or v == 8 or v == 9 or v == 10 or v == 25:
            sync()
    else:
        comma(v)
````

**data()** adds a value to the data queue. This data will be written at the
next **sync()**.

If packing is disabled, this just passes the data to **comma()**.

````
def data(v):
    global datas
    if packed:
        datas.append(v)
    else:
        comma(v)
````

### Dictionary

Nga uses a simple dictionary to map label names to addresses. There are two
functions.

| name   | args | intended use                                                       |
| ------ | ---- | ------------------------------------------------------------------ |
| define | id   | sync, then create a label pointing to the current location         |
| lookup | id   | return a the location corresponding to a label, or -1 if not found |

````
def define(id):
    print('define ' + id)
    global labels
    sync()
    labels.append((id, i))
    addToMap('label', id, i)


def lookup(id):
    for label in labels:
        if label[0] == id:
            return label[1]
    return -1
````

### Instruction Mapping

| name        | args | intended use                                             |
| ----------- | ---- | -------------------------------------------------------- |
| map_to_inst | s    | Given an instruction name, return the instruction number |

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

### Uncategorized

| name        | args | intended use                              |
| ----------- | ---- | ----------------------------------------- |
| preamble    |      | initial code at the start of each image   |
| patch_entry |      | patch the jump compiled by **preamble()** |

**preamble()** compiles a jump to the label :main. Since this isn't known
at the start, **patch_entry()** will replace the stub jump with the correct
address at the end of assembly.

````
def preamble():
    inst(1)  # LIT
    data('&main')  # value will be patched to point to :main
    inst(7)  # JUMP
    sync()

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
pointer to it. For now though this just stores the *string* for the label in
memory. The actual address will be resolved later, once all other assembly is
finished.

````
def handle_lit(line):
    parts = line.split()
    try:
        a = int(parts[1])
        data(a)
    except:
        xt = str(parts[1])
        data(xt)
````

For assembler directives we have a single handler. There are currently four
directives; one for setting the **output** filename, one for inlining data,
and two for enabling or disabling packing multiple instructions per cell.

````
def handle_directive(line):
    global output, packed
    parts = line.split()
    token = line[0:2]
    if token == '.o':
        output = parts[1]
    if token == '.d':
        sync()
        data(int(parts[1]))
        sync()
    if token == '.p':
        sync()
        packed = True
    if token == '.u':
        sync()
        packed = False
````

Now for the meat of the assembler. This takes a single line of input, checks
to see if it's a label or instruction, and lays down the appropriate code,
calling whatever helper functions are needed (**handle_lit()** being notable).

````
def assemble(line):
    token = line[0:2]
    if is_label(token):
        define(line[1:])
    elif is_directive(token):
        handle_directive(line)
    elif is_inst(token):
        op = map_to_inst(token)
        inst(op)
        if op == 1:
            handle_lit(line)
    else:
        print('Line was not a label or instruction.')
        print(line)
        exit()
````

**resolve_labels()** is the second pass; it converts any labels into addresses.

````
def resolve_label(name):
    value = 0
    try:
        value = int(name)
    except ValueError:
        value = lookup(name[1:])
        if value == -1:
            print('Label not found!')
            print('Label: ' + name[1:])
            exit()
    return value

def resolve_labels():
    global memory
    results = []
    for cell in memory:
        value = resolve_label(cell)
        results.append(value)
    memory = results

def resolve_labels_in_map():
    global map
    results = []
    for row in map:
        current = row
        if row[0] == 'literal':
            try:
                if row[1][0:1] == '&':
                    current = [0, 0, 0]
                    current[0] = 'pointer'
                    current[1] = resolve_label(row[1])
                    current[2] = row[2]
            except:
                pass
        results.append(current)
    map = results
````

This next function saves the memory image to a file.

````
def save(filename):
    with open(filename, 'wb') as file:
        j = 0
        while j < i:
            file.write(struct.pack('i', memory[j]))
            j = j + 1
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
    sync()
    resolve_labels()
    patch_entry()

    if len(sys.argv) < 3:
        if output == '':
            output = 'output.nga'
        save(output)
    else:
        save(sys.argv[2])

    resolve_labels_in_map()
    saveMap(output)

    print(memory)
    print('{0} cells written'.format(len(memory)))
````
