# Nga SDK

Nga includes a number of tools to help with building applications using it.

## Naje

Naje is the standard assembler. It's designed to accept interactive input,
redirect files into it.

Requirements: Python 3

Example:

    ./sdk/naje.py < samples/square.naje

## Nabk

Nabk is a preprocessor for use with Naje. It's designed to be used as a
filter; pipe its output to Naje or redirect into a separate file for later
use.

Requirements: Python 3

Example:

    ./sdk/nabk.py samples/square.nabk | ./sdk/naje.py

## PL/0

A port of the PL0-Language-Tools for generating Naje assembly.

Requirements: Python 3

## Tiro

Tiro is a dissassembler for Nga images.

Requirements: Python 3

Example:

    ./sdk/naje.py < samples/square.naje
    ./sdk/tiro.py square.nga | less

