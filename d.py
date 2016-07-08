#!/usr/bin/env python3

import os, sys, math, time, struct
from struct import pack, unpack

def ngaUnpack(cell):
    a = cell & 0xFF
    b = (cell >> 8)  & 0xFF
    c = (cell >> 16) & 0xFF
    d = (cell >> 24) & 0xFF
    return a, b, c, d


def ngaIsValidPacked(cell):
    a, b, c, d = ngaUnpack(cell)
    valid = True
    if a < 0 or a > 26: valid = False
    if b < 0 or b > 26: valid = False
    if c < 0 or c > 26: valid = False
    if d < 0 or d > 26: valid = False
    return valid


def ngaStringFromPacked(cell):
    a, b, c, d = ngaUnpack(cell)
    return '{0}\t{1}\t{2}\t{3}'.format(a, b, c, d)


def ngaLoadImageFile(named):
  cells = int(os.path.getsize(named) / 4)
  with open(named, 'rb') as f:
    memory = list(struct.unpack( cells * 'i', f.read() ))
  return memory


def ngaDisplayCellContents(i, cell):
  if ngaIsValidPacked(cell):
    print('{0}\t{1}'.format(i, ngaStringFromPacked(cell)))
  else:
    print('{0}\t{1}'.format(i, cell))


if __name__ == "__main__":
  imgpath = 'hello'
  cells = int(os.path.getsize(imgpath) / 4)
  print('Nga Image Dump for: {0}'.format(imgpath))
  print('Dumping {0} cells\n'.format(cells))
  i = 0
  for v in ngaLoadImageFile(imgpath):
    ngaDisplayCellContents(i, v)
    i = i + 1
