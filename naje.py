#!/usr/bin/env python3

# naje - a minimal assembler for nga
# -----------------------------------------------------------------------------
# 0		nop			7		jump		14		gt			21		and
# 1		lit <v>		8		call		15		fetch		22		or
# 2		dup			9		if			16		store		23		xor
# 3		drop		10		return		17		add			24		shift
# 4		swap		11		eq			18		sub			25		zret
# 5		push		12		-eq			19		mul			26		end
# 6		pop			13		lt			20		divmod
# -----------------------------------------------------------------------------
# Example:
#
# :add
#   add
#   return
#
# :subtract
#   sub
#   return
#
# :increment
#   lit 1
#   lit add
#   call
#   return
#
# :main
#   lit 100
#   lit 95
#   lit subtract
#   call
#   lit increment
#   call
#   end
#
# * naje will compile a jump to the main: line at the start of the image file
# * labels need to be defined before they can be referenced
# * this does not provide any other syntax sugar - use a preprocessor for that
#
# ideas for preprocessor:
#
# * call <label>
# * jump <label>
# * allow for comments
# -----------------------------------------------------------------------------

labels = []
resolve = []
memory = []
i = 0

def comma(v):
    global memory, i
    memory.append(int(v))
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


def lookup(id):
    for label in labels:
        if label[0] == id:
            return label[1]
    return -1

## WIP

comma(1)
comma(0)
comma(7)

with open('test.naje', 'r') as f:
    raw = f.readlines()

src = []
for line in raw:
    src.append(line.strip())

print(src)

for line in src:
    if line != '':
        token = line[0:2]
        if token[0:1] == ':':
            labels.append((line[1:], i))
            print('label = ', line, '@', i)
        else:
            op = map_to_inst(token)
            if op == -1:
                print('error detected', line)
                exit()
            else:
                comma(op)
                if op == 1:
                    parts = line.split()
                    try:
                        a = int(parts[1])
                        comma(a)
                    except:
                        xt = lookup(parts[1])
                        if xt != -1:
                            comma(xt)
                        else:
                            print('error detected', line)
                            exit()

memory[1] = lookup('main')

print(labels)
print(memory)
