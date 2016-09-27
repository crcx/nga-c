#!/usr/bin/env python3
import struct
import sys
output = ''
labels = []
memory = []
i = 0
insts = []
datas = []
packed = True
map = []
def addToMap(type, id, offset):
    global map
    map.append((type, id, offset))
def saveMap(basename):
    with open('{0}.map'.format(basename), 'w') as mapFile:
        for row in map:
            mapFile.write('{0}\t{1}\t{2}\n'.format(row[0], row[1], row[2]))
def comma(v):
    global memory, i
    try:
        memory.append(int(v))
    except ValueError:
        memory.append(v)
    i = i + 1
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
def data(v):
    global datas
    if packed:
        datas.append(v)
    else:
        comma(v)
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
def preamble():
    inst(1)  # LIT
    data('&main')  # value will be patched to point to :main
    inst(7)  # JUMP
    sync()
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
        data(a)
    except:
        xt = str(parts[1])
        data(xt)
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
def save(filename):
    with open(filename, 'wb') as file:
        j = 0
        while j < i:
            file.write(struct.pack('i', memory[j]))
            j = j + 1
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
