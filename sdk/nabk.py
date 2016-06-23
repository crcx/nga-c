#!/usr/bin/env python3
import sys

src = []
with open(sys.argv[1]) as f:
    src = f.readlines()

for line in src:
    tokens = line.strip().split()
    if len(tokens) > 0:
        if len(tokens) == 1:
            if tokens[0][0:1] == ':':
                print(tokens[0])
            else:
                print(tokens[0][0:2])
        else:
            if tokens[0] == 'lit' or tokens[0] == 'li':
                print('li', tokens[1])
            if tokens[0] == 'call':
                print('li', tokens[1])
                print('ca')
            if tokens[0] == 'jump':
                print('li', tokens[1])
                print('ju')
            if tokens[0] == 'data:':
                ignore = False
                for i in tokens[1:]:
                    if i == '#':
                        ignore = True
                    elif ignore != True:
                        print('.d', i)
