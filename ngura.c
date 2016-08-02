#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <termios.h>
char request[8192];

/* Helper Functions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
void nguraGetString(int starting)
{
  CELL i = 0;
  while(memory[starting] && i < 8192)
    request[i++] = (char)memory[starting++];
  request[i] = 0;
}
struct termios new_termios, old_termios;

void nguraConsoleInit() {
#ifdef VERBOSE
  printf("- prepare terminal i/o\n");
#endif
  tcgetattr(0, &old_termios);
  new_termios = old_termios;
  new_termios.c_iflag &= ~(BRKINT+ISTRIP+IXON+IXOFF);
  new_termios.c_iflag |= (IGNBRK+IGNPAR);
  new_termios.c_lflag &= ~(ICANON+ISIG+IEXTEN+ECHO);
  new_termios.c_cc[VMIN] = 1;
  new_termios.c_cc[VTIME] = 0;
  tcsetattr(0, TCSANOW, &new_termios);
}

void nguraConsoleFinish() {
#ifdef VERBOSE
  printf("- restore previous terminal i/o settings\n");
#endif
  tcsetattr(0, TCSANOW, &old_termios);
}

void nguraConsolePutChar(char c) {
  putchar(c);
}

void nguraConsolePutNumber(int i) {
  printf("%d", i);
}

int nguraConsoleGetChar() {
  return (int)getc(stdin);
}
#ifdef UNFINISHED
/* File I/O Support ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
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
void nguraProcessOpcode(CELL opcode) {
  switch(opcode) {
    case 100: nguraConsolePutChar((char)data[sp]);
              sp--;
              break;
    case 101: nguraConsolePutNumber(data[sp]);
              sp--;
              break;
    case 102: printf("\n+ ERROR: IO OPERATION %d NOT IMPLEMENTED\n", opcode);
              break;
    case 103: sp++;
              TOS = nguraConsoleGetChar();
              break;
    case 104: printf("\n+ ERROR: IO OPERATION %d NOT IMPLEMENTED\n", opcode);
              break;
    case 105: printf("\n+ ERROR: IO OPERATION %d NOT IMPLEMENTED\n", opcode);
              break;
    case 106: printf("\n+ ERROR: IO OPERATION %d NOT IMPLEMENTED\n", opcode);
              break;
    case 107: printf("\n+ ERROR: IO OPERATION %d NOT IMPLEMENTED\n", opcode);
              break;
    case 108: printf("\n+ ERROR: IO OPERATION %d NOT IMPLEMENTED\n", opcode);
              break;
    case 109: printf("\n+ ERROR: IO OPERATION %d NOT IMPLEMENTED\n", opcode);
              break;
    case 110: printf("\n+ ERROR: IO OPERATION %d NOT IMPLEMENTED\n", opcode);
              break;
  }
}
