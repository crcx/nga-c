# Nga: a Stack Oriented Virtual Machine

## Overview

Nga is a lightweight, stack based virtual machine.

It features:

* Small core (under 300 lines of C code)
* Dual stack, MISC instruction set
* 27 instructions
* No defined I/O model
* Extensible design

All code, documentation, and any binaries included are provided under
the ISC License unless otherwise noted in the source. Please feel free
to take, use, and modify Nga as you see fit.

## Development

Development is managed using the Git version control system. Our primary
repository is hosted on Github

You can obtain a current copy of the code by doing:

    git clone https://github.com/crcx/nga.git

## Documentation

Nga comes with a variety of documents describing the language, virtual
machine, and implementation details. All of these are in Markdown, with
code fencing and tables from GitHub's variant.

## Source Files

The main sources are:

| File          | Contains                        |
| ------------- | ------------------------------- |
| Nga.md        | Nga virtual machine             |
| nga.h         | Headers for Nga                 |
| Naje.md       | Naje: assembler for Nga         |
| Unu.md        | Unu: extract source from .md    |

These are extracted into source code, in C. (The tools assume a Unix
style environment).

There are also some other source files that may be of use:

| File          | Contains                        |
| ------------- | ------------------------------- |
| EmbedImage.md | Tool to export image to C array |
| Ngita.md      | Example interface layer         |
| Ngura.md      | I/O devices for Ngita           |
| Nuance.md     | A MachineForth to Naje compiler |
| Tiro.md       | A disassembler                  |

## Getting Help

We have an irc channel on the freenode network. Join *#retro* on
*irc.freenode.net*. If you ask a question, please be patient. We have
large idle times, but the channel is logged (see
forthworks.com/retro/irc-logs) and we generally try to answer questions
in a reasonable time period.

*Please read the documentation before asking questions.*

## Bug Reports

Bugs can be reported on the Github issue tracker.
