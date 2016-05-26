#!/usr/bin/env python3
import sys
import naje

src = []
with open(sys.argv[1]) as f:
    src = f.readlines()

for line in src:
    tokens = line.strip().split()
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
            if tokens[0] == 'data:':
                ignore = False
                for i in tokens[1:]:
                    if i == '#':
                        ignore = True
                    elif ignore != True:
                        print('lit', i)
            if tokens[0] == 'raw:':
                ignore = False
                for i in tokens[1:]:
                    if i == '#':
                        ignore = True
                    elif ignore != True:
                        print(i)
