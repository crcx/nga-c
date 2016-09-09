# Ngura

## Overview

On its own Nga is not very useful as it lacks a means of interfacing with the world. It expects to be embedded into other, larger environments which can extend the instruction set to allow for I/O and additional desired functionality.

Ngura is intended as a framework for building a closely related (but fully optional) set of I/O functionality. What it seeks to do is provide a broad base that groups related functionality into logical units that can be enabled or disabled by the interface layer. Additionally it provides an abstraction in that an interface layer doesn't need to know the specifics of how the underlying devices work. So an embedded Ngura might direct keyboard and text display over a serial port, while a Unix hosted implementation could use the C standard library and read/write from stdin and stdout.

This reference implementation of Ngura targets Unix-style hosts.

Before including Ngura, an interface layer should define the devices it wants to use. Currently the options are:

* **NGURA_TTY** for text output
* **NGURA_KBD** for keyboard input
* **NGURA_FS** for filesystem

For an interface that needs the display and filesystem something this will suffice:

    #define NGURA_TTY
    #define NGURA_FS
    #include "ngura.c"

The code below defines symbolic names for each I/O instruction for enabled devices.

````
#ifdef NGURA_TTY
#define NGURA_TTY_PUTC  100
#define NGURA_TTY_PUTN  101
#define NGURA_TTY_PUTS  102
#define NGURA_TTY_PUTSC 103
#define NGURA_TTY_CLEAR 104
#endif

#ifdef NGURA_KBD
#define NGURA_KBD_GETC 110
#define NGURA_KBD_GETN 111
#define NGURA_KBD_GETS 112
#endif

#ifdef NGURA_FS
#define NGURA_FS_OPEN   118
#define NGURA_FS_CLOSE  119
#define NGURA_FS_READ   120
#define NGURA_FS_WRITE  121
#define NGURA_FS_TELL   122
#define NGURA_FS_SEEK   123
#define NGURA_FS_SIZE   124
#define NGURA_FS_DELETE 125
#endif
````

## Unfinished Below -- Work In Progress

The numbering starts at 100 and runs as follows:

| Inst | Intended Use                                                 |
| ---- | ------------------------------------------------------------ |
| 100  | TTY: Display Character                                       |
| 101  | TTY: Display Number (signed, decimal)                        |
| 102  | TTY: Display String (zero terminated)                        |
| 103  | TTY: Display String (address, length)                        |
| 104  | TTY: Clear Display                                           |
| 105  |                                                              |
| 106  |                                                              |
| 107  |                                                              |
| 108  |                                                              |
| 109  |                                                              |
| 110  | KBD: Read Character                                          |
| 111  | KBD: Read Number (signed, decimal)                           |
| 112  | KBD: Read String (delimiter, address, length)                |
| 113  |                                                              |
| 114  |                                                              |
| 115  |                                                              |
| 116  |                                                              |
| 117  |                                                              |
| 118  | FS: Open                                                     |
| 119  | FS: Close                                                    |
| 120  | FS: Read Character                                           |
| 121  | FS: Write Character                                          |
| 122  | FS: Tell                                                     |
| 123  | FS: Seek                                                     |
| 124  | FS: Size                                                     |
| 125  | FS: Delete                                                   |
| 126  |                                                              |
| 127  |                                                              |
| 128  |                                                              |
| 129  |                                                              |

(Numbering is subject to change as the requirements get refined through further use)


### Headers

First up, a few standard headers.

**TODO: include the headers selectively based on the desired devices**

````
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
````

### Helper Functions

**nguraGetString** extracts a zero terminated string from the image. This is used in a few places where we need to interface between Nga and libc.

**TODO: consider making this compile only if devices using it are included.**

````
char request[8192];

void nguraGetString(int starting)
{
  CELL i = 0;
  while(memory[starting] && i < 8192)
    request[i++] = (char)memory[starting++];
  request[i] = 0;
}
````

### TTY and KBD

The *TTY* provides a terminal output environment, targetting VT100 comaptible terminals or terminal emulators.

The *KBD* provides keyboard input for a terminal environment.

#### Initialization and Cleanup

The underlying I/O model is based on that of Ngaro, the predecessor to Nga. Terminal I/O is expected to be immediate and not buffered. The initialization and cleanup here takes care of enabling and restoring the original host settings. You'll need *termios* for this to work. Windows users would need to reimplement this using the appropriate API's.

````
#if defined(NGURA_TTY) || defined(NGURA_KBD)
#include <termios.h>
struct termios nguraConsoleOriginalTermios;
struct termios nguraConsoleTermios;

void nguraConsoleInit() {
  tcgetattr(0, &nguraConsoleOriginalTermios);
  nguraConsoleTermios = nguraConsoleOriginalTermios;
  nguraConsoleTermios.c_iflag &= ~(BRKINT+ISTRIP+IXON+IXOFF);
  nguraConsoleTermios.c_iflag |= (IGNBRK+IGNPAR);
  nguraConsoleTermios.c_lflag &= ~(ICANON+ISIG+IEXTEN+ECHO);
  nguraConsoleTermios.c_cc[VMIN] = 1;
  nguraConsoleTermios.c_cc[VTIME] = 0;
  tcsetattr(0, TCSANOW, &nguraConsoleTermios);
}

void nguraConsoleCleanup() {
  tcsetattr(0, TCSANOW, &nguraConsoleOriginalTermios);
}
#endif
````

#### TTY Functions

These handle displaying things on the terminal output. Where escape sequences are used, they assume something close to a VT100/ANSI capable terminal.

Ngura provides for display of characters, zero terminated strings, counted strings, and decimal numbers. It's not hard to do the display of strings in Nga code, but this saves some runtime overhead improving performance and bypassing a potential bottleneck.

````
#ifdef NGURA_TTY
void nguraTTYPutChar(char c) {
  putchar(c);
  if (c == 8) {
    putchar(32);
    putchar(8);
  }
}

void nguraTTYPutNumber(int i) {
  printf("%d", i);
}

void nguraTTYPutString(CELL addr) {
  nguraGetString(addr);
  printf("%s", request);
}

void nguraTTYPutStringCounted(CELL addr, CELL length) {
  CELL i = 0;
  while(memory[addr] && i < length) {
    nguraTTYPutChar((char)memory[addr++]);
    i++;
  }
}

void nguraTTYClearDisplay() {
  printf("\033[2J\033[1;1H");
}
#endif
````

#### KBD Functions

These are used for input. The predecessor to Nga had a simple keyboard input function for reading single keys. Ngura adds support for reading strings and numbers as well. (This is a concession for performance. Normally I don't obsess over performance, but I/O is a big bottleneck and this small concession is worth implementing.)

````
#ifdef NGURA_KBD
int nguraKBDGetChar() {
  int i = 0;
  i = (int)getc(stdin);
  nguraTTYPutChar((char)i);
  return i;
}

void nguraKBDGetString(CELL delim, CELL limit, CELL starting) {
  CELL i = starting;
  CELL k = 0;
  CELL done = 0;
  while (done == 0) {
    k = nguraKBDGetChar();
    if (k == delim)
      done = 1;
    if (i >= (limit + starting))
      done = 1;
    if (done == 0) {
      memory[i] = k;
    }
    i++;
  }
  memory[i] = 0;
}

CELL nguraKBDGetNumber(int delim) {
  CELL i = 0;
  CELL k = 0;
  CELL done = 0;
  while (done == 0) {
    k = nguraKBDGetChar();
    if (k == delim)
      done = 1;
    if (i > 8192)
      done = 1;
    if (done == 0) {
      request[i] = k;
    }
    i++;
  }
  request[i] = 0;
  k = atol(request);
  return k;
}
#endif
````

### FS

*FS* implements functions for interacting with the host filesystem. This is closely modeled after the C standard library.

````
#ifdef NGURA_FS
#define MAX_OPEN_FILES 128
FILE *nguraFileHandles[MAX_OPEN_FILES];

CELL nguraGetFileHandle()
{
  CELL i;
  for(i = 1; i < MAX_OPEN_FILES; i++)
    if (nguraFileHandles[i] == 0)
      return i;
  return 0;
}

CELL nguraOpenFile() {
  CELL slot, mode, name;
  slot = nguraGetFileHandle();
  mode = TOS; sp--;
  name = TOS; sp--;
  nguraGetString(name);
  if (slot > 0)
  {
    if (mode == 0)  nguraFileHandles[slot] = fopen(request, "r");
    if (mode == 1)  nguraFileHandles[slot] = fopen(request, "w");
    if (mode == 2)  nguraFileHandles[slot] = fopen(request, "a");
    if (mode == 3)  nguraFileHandles[slot] = fopen(request, "r+");
  }
  if (nguraFileHandles[slot] == NULL)
  {
    nguraFileHandles[slot] = 0;
    slot = 0;
  }
  return slot;
}

CELL nguraReadFile() {
  CELL c = fgetc(nguraFileHandles[TOS]); sp--;
  return (c == EOF) ? 0 : c;
}

CELL nguraWriteFile() {
  CELL slot, c, r;
  slot = TOS; sp--;
  c = TOS; sp--;
  r = fputc(c, nguraFileHandles[slot]);
  return (r == EOF) ? 0 : 1;
}

CELL nguraCloseFile() {
  fclose(nguraFileHandles[TOS]);
  nguraFileHandles[TOS] = 0;
  sp--;
  return 0;
}

CELL nguraGetFilePosition() {
  CELL slot = TOS; sp--;
  return (CELL) ftell(nguraFileHandles[slot]);
}

CELL nguraSetFilePosition() {
  CELL slot, pos, r;
  slot = TOS; sp--;
  pos  = TOS; sp--;
  r = fseek(nguraFileHandles[slot], pos, SEEK_SET);
  return r;
}

CELL nguraGetFileSize() {
  CELL slot, current, r, size;
  slot = TOS; sp--;
  current = ftell(nguraFileHandles[slot]);
  r = fseek(nguraFileHandles[slot], 0, SEEK_END);
  size = ftell(nguraFileHandles[slot]);
  fseek(nguraFileHandles[slot], current, SEEK_SET);
  return (r == 0) ? size : 0;
}

CELL nguraDeleteFile() {
  CELL name = TOS; sp--;
  nguraGetString(name);
  return (unlink(request) == 0) ? -1 : 0;
}
#endif
````


````
void nguraInitialize() {
#if defined(NGURA_TTY) || defined(NGURA_KBD)
  nguraConsoleInit();
#endif
}

void nguraCleanup() {
#if defined(NGURA_TTY) || defined(NGURA_KBD)
  nguraConsoleCleanup();
#endif
}
````


### Opcode Processor

````
void nguraProcessOpcode(CELL opcode) {
  CELL addr, length;
  CELL delim, limit, starting;
  switch(opcode) {
#ifdef NGURA_TTY
    case NGURA_TTY_PUTC:
      nguraTTYPutChar((char)data[sp]);
      sp--;
      break;
    case NGURA_TTY_PUTN:
      nguraTTYPutNumber(data[sp]);
      sp--;
      break;
    case NGURA_TTY_PUTS:
      nguraTTYPutString(TOS);
      sp--;
      break;
    case NGURA_TTY_PUTSC:
      addr = TOS;
      sp--;
      length = TOS;
      sp--;
      nguraTTYPutStringCounted(addr, length);
      break;
    case NGURA_TTY_CLEAR:
      nguraTTYClearDisplay();
      break;
#endif
#ifdef NGURA_KBD
    case NGURA_KBD_GETC:
      sp++;
      TOS = nguraKBDGetChar();
      break;
    case NGURA_KBD_GETN:
      delim = TOS;
      TOS = nguraKBDGetNumber(delim);
      break;
    case NGURA_KBD_GETS:
      starting = TOS; sp--;
      limit = TOS; sp--;
      delim = TOS; sp--;
      nguraKBDGetString(delim, limit, starting);
      break;
#endif
#ifdef NGURA_FS
    case NGURA_FS_OPEN:
      nguraOpenFile();
      break;
    case NGURA_FS_CLOSE:
      nguraCloseFile();
      break;
    case NGURA_FS_READ:
      nguraReadFile();
      break;
    case NGURA_FS_WRITE:
      nguraWriteFile();
      break;
    case NGURA_FS_TELL:
      nguraGetFilePosition();
      break;
    case NGURA_FS_SEEK:
      nguraSetFilePosition();
      break;
    case NGURA_FS_SIZE:
      nguraGetFileSize();
      break;
    case NGURA_FS_DELETE:
      nguraDeleteFile();
      break;
#endif
  }
}
````
