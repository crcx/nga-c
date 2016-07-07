#!/usr/bin/env python3
import sys

output = ''
labels = []
resolve = []
memory = []
packed = False
i = 0
def define(id):
    global labels
    labels.append((id, i))

def lookup(id):
    for label in labels:
        if label[0] == id:
            return label[1]
    return -1
def comma(v):
    global memory, i
    try:
        memory.append(int(v))
    except ValueError:
        memory.append(v)
    i = i + 1
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
def save(filename):
    import struct
    with open(filename, 'wb') as file:
        j = 0
        while j < i:
            file.write(struct.pack('i', memory[j]))
            j = j + 1
def preamble():
    comma(1)  # LIT
    comma(0)  # value will be patched to point to :main
    comma(7)  # JUMP
def patch_entry():
    memory[1] = lookup('main')
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
def handle_lit(line):
    parts = line.split()
    try:
        a = int(parts[1])
        comma(a)
    except:
        xt = str(parts[1])
        comma(xt)
def handle_directive(line):
    global output, packed
    parts = line.split()
    token = line[0:2]
    if token == '.o': output = parts[1]
    if token == '.d': comma(int(parts[1]))
    if token == '.p': packed = True
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
                print('Label: ' + cell[1:])
                exit()
        results.append(value)
    memory = results
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
