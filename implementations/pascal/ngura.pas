// ********************************************************
//  Copyright (c) 2016 Rob Judd <judd@ob-wan.com>
//  Based on C version by Charles Childers et al
//  ISC License - see included file LICENSE
// ********************************************************

unit ngura;

{$mode objfpc}{$H+}
{$macro on}

//{$define NGURA_KBD}
//{$define NGURA_TTY}
//{$define NGURA_FS}

interface

type
  Cell = Longint;

procedure nguraInitialize();
procedure nguraCleanup();
procedure nguraProcessOpcode(opcode : Cell);

var
  memory : array[0..524287] of Cell;
  ip, sp : Cell;
  request : array[0..8191] of Char;

{$DEFINE IMAGE_SIZE:=524288}

{$if defined (NGURA_TTY) or defined (NGURA_KBD)}
{$include <termios.h>}
  struct termios nguraConsoleOriginalTermios;
  struct termios nguraConsoleTermios;
{$endif}
{$ifdef NGURA_FS}
{$define MAX_OPEN_FILES 128}
  nguraFileHandles : array[1..128] of File;
{$endif}

{$ifdef NGURA_TTY}
{$define NGURA_TTY_PUTC   100}
{$define NGURA_TTY_PUTN   101}
{$define NGURA_TTY_PUTS   102}
{$define NGURA_TTY_PUTSC  103}
{$define NGURA_TTY_CLEAR  104}
{$endif}

{$ifdef NGURA_KBD}
{$define NGURA_KBD_GETC   110}
{$define NGURA_KBD_GETN   111}
{$define NGURA_KBD_GETS   112}
{$endif}

{$ifdef NGURA_FS}
{$define NGURA_FS_OPEN    118}
{$define NGURA_FS_CLOSE   119}
{$define NGURA_FS_READ    120}
{$define NGURA_FS_WRITE   121}
{$define NGURA_FS_TELL    122}
{$define NGURA_FS_SEEK    123}
{$define NGURA_FS_SIZE    124}
{$define NGURA_FS_DELETE  125}
{$endif}

{$define NGURA_SAVE_IMAGE := 130}

{$define TOS:=data[sp]}
{$define NOS:=data[sp-1]}
{$define TOA:=address[ap]}

implementation

uses
  Classes, SysUtils;

procedure nguraGetString(starting : Integer);
var
  i : Cell = 0;
begin
  while (memory[starting] <> 0) and (i < 8192) do
  begin
    request[i] := Char(memory[starting]);
    inc(i);
    inc(starting);
  end;
  request[i] := #0;
end;

{$if defined(NGURA_TTY) or defined(NGURA_KBD)}
void nguraConsoleInit() {
  tcgetattr(0, @nguraConsoleOriginalTermios);
  nguraConsoleTermios := nguraConsoleOriginalTermios;
  nguraConsoleTermios.c_iflag &= ~(BRKINT+ISTRIP+IXON+IXOFF);
  nguraConsoleTermios.c_iflag |= (IGNBRK+IGNPAR);
  nguraConsoleTermios.c_lflag &= ~(ICANON+ISIG+IEXTEN+ECHO);
  nguraConsoleTermios.c_cc[VMIN] := 1;
  nguraConsoleTermios.c_cc[VTIME] := 0;
  tcsetattr(0, TCSANOW, @nguraConsoleTermios);
}
void nguraConsoleCleanup() {
  tcsetattr(0, TCSANOW, @nguraConsoleOriginalTermios);
}
{$endif}

{$ifdef NGURA_TTY}
procedure nguraTTYPutChar(char c);
begin
  putchar(c);
  if c = 8 then
    putchar(32);
    putchar(8);
  end;
end;

procedure nguraTTYPutNumber(i : Integer);
begin
  write(format('%d', [i]));
end;

procedure nguraTTYPutString(addr : Cell);
begin
  nguraGetString(addr);
  writeln(format('%s', [request]));
end;

procedure nguraTTYPutStringCounted(addr, length : Cell);
var
  i : Cell = 0;
begin
  while(memory[addr] <> 0) and (i < length) do
    nguraTTYPutChar(Char(memory[addr]));
    inc(i);
    inc(addr);
  end;
end;

procedure nguraTTYClearDisplay();
begin
  write(format('\033[2J\033[1;1H'));   // eek!
end;
{$endif}

{$ifdef NGURA_KBD}
function nguraKBDGetChar() : Integer;
var
  i : Integer = 0;
begin
  i := Integer(getc(stdin));
  if (i = #10) or (i = #13) then
    i := 32;
  nguraTTYPutChar(Char(i));
  result := i;
end;

procedure nguraKBDGetString(delim, limit, starting: Cell);
var
  i, k : Cell;
  done : Cell = 0;
begin
  i := starting;
  k := 0;
  while done = 0 do
  begin
    k := nguraKBDGetChar();
    if k = delim then
      done := 1
    else
    begin
      memory[i] := k;
      inc(i);
    end;
    if i >= (limit + starting) then
      done := 1;
  end;
  memory[i] := 0;
end;

nguraKBDGetNumber(delim : Integer) : Cell
var
  i : Cell = 0;
  k : Cell = 0;
  done : Cell = 0;
begin
  while done = 0 do
  begin
    k := nguraKBDGetChar();
    if (k = delim) or (i > 8192) then
      done := 1;
    if done = 0 then
      request[i] := k;
    inc(i);
  end;
  request[i] := 0;
  result := strtolong(request);
end;
{$endif}

{$ifdef NGURA_FS}
nguraGetFileHandle() : Cell;
var
  i : Cell;
begin
  result := 0;
  for i := 1 to MAX_OPEN_FILES do
    if nguraFileHandles[i] = 0 then
      result := i
end;

nguraOpenFile() : Cell;
var
  slot, mode, name : Cell;
begin
  slot := nguraGetFileHandle();
  mode := TOS;
  dec(sp);
  name := TOS;
  dec(sp);
  nguraGetString(name);
  if slot > 0 then
  begin
    if mode = 0 then nguraFileHandles[slot] = fopen(request, "r");
    if mode = 1 then nguraFileHandles[slot] = fopen(request, "w");
    if mode = 2 then nguraFileHandles[slot] = fopen(request, "a");
    if mode = 3 then nguraFileHandles[slot] = fopen(request, "r+");
  end;
  if nguraFileHandles[slot] = nil then
  begin
    nguraFileHandles[slot] := 0;
    slot := 0;
  end;
  result := slot;
end;

nguraReadFile() : Cell;
var
  c : Cell;
begin
  c := fgetc(nguraFileHandles[TOS]);
  dec(sp);
  if c := eof then
    result := 0
  else
    result := c;
}

nguraWriteFile() : Cell;
var
  slot, c, r : Cell;
begin
  slot := TOS;
  dec(sp);
  c := TOS;
  dec(sp);
  r := fputc(c, nguraFileHandles[slot]);
  if r = eof then
    result := 0
  else
    result := 1;
end;

nguraCloseFile() : Cell;
begin
  close(nguraFileHandles[TOS]);
  nguraFileHandles[TOS] := 0;
  dec(sp);
  result := 0;
end;

nguraGetFilePosition() : Cell;
var
  slot : Cell;
begin
  slot := TOS;
  dec(sp);
  result := Cell(ftell(nguraFileHandles[slot]));
end;

nguraSetFilePosition() : Cell;
var
  slot, pos : Cell;
begin
  slot := TOS;
  dec(sp);
  pos := TOS;
  dec(sp);
  result := fseek(nguraFileHandles[slot], pos, SEEK_SET);
end;

nguraGetFileSize() : Cell;
var
  slot, current, r, size : Cell;
begin
  slot := TOS;
  dec(sp);
  current := ftell(nguraFileHandles[slot]);
  r := fseek(nguraFileHandles[slot], 0, SEEK_END);
  size := ftell(nguraFileHandles[slot]);
  fseek(nguraFileHandles[slot], current, SEEK_SET);
  if r = 0 then
    result := size
  else
    result := 0;
end;

nguraDeleteFile() : Cell;
var
  name : Cell;
begin
  name := TOS;
  dec(sp);
  nguraGetString(name);
  if unlink(request) = 0 then
    result := -1
  else
    result := 0;
}
{$endif}

procedure nguraSaveImage();
var
  f : FILE;
begin
try
  Assignfile(f, 'rx.nga');
  ReWrite(f, IMAGE_SIZE);
except
  on E: EInOutError do
  begin
    writeln('Unable to save the ngaImage!', E.Message, ': rx.nga');
    halt();
  end;
end;
try
  BlockWrite(f, memory, sizeOf(Cell));
finally
  CloseFile(f);
end;
end;

procedure nguraInitialize();
begin
{$if defined(NGURA_TTY) or defined(NGURA_KBD)}
    nguraConsoleInit();
{$endif}
end;

procedure nguraCleanup();
begin
{$if defined(NGURA_TTY) or defined(NGURA_KBD)}
  nguraConsoleCleanup();
{$endif}
end;

procedure nguraProcessOpcode(opcode : Cell);
var
  dummy : Byte;
{$ifdef NGURA_TTY}
  addr, length : Cell;
{$endif}
{$ifdef NGURA_KBD}
  delim, limit, starting : Cell;
{$endif}
begin
  case (opcode) of
{$ifdef NGURA_TTY}
    NGURA_TTY_PUTC:
    begin
      nguraTTYPutChar(Char(data[sp]));
      dec(sp);
    end;
    NGURA_TTY_PUTN:
    begin
      nguraTTYPutNumber(data[sp]);
      dec(sp);
    end;
    NGURA_TTY_PUTS:
    begin
      nguraTTYPutString(TOS);
      dec(sp);
    end;
    NGURA_TTY_PUTSC:
    begin
      addr := TOS;
      dec(sp);
      length := TOS;
      dec(sp);
      nguraTTYPutStringCounted(addr, length);
    end;
    NGURA_TTY_CLEAR:
      nguraTTYClearDisplay();
{$endif}
{$ifdef NGURA_KBD}
    NGURA_KBD_GETC:
    begin
      inc(sp);
      TOS := nguraKBDGetChar();
    end;
    NGURA_KBD_GETN:
    begin
      delim := TOS;
      TOS := nguraKBDGetNumber(delim);
    end;
    NGURA_KBD_GETS:
    begin
      starting := TOS;
      dec(sp);
      limit := TOS;
      dec(sp);
      delim := TOS;
      dec(sp);
      nguraKBDGetString(delim, limit, starting);
    end;
{$endif}
{$ifdef NGURA_FS}
    NGURA_FS_OPEN:
      nguraOpenFile();
    NGURA_FS_CLOSE:
      nguraCloseFile();
    NGURA_FS_READ:
      nguraReadFile();
    NGURA_FS_WRITE:
      nguraWriteFile();
    NGURA_FS_TELL:
      nguraGetFilePosition();
    NGURA_FS_SEEK:
      nguraSetFilePosition();
    NGURA_FS_SIZE:
      nguraGetFileSize();
    NGURA_FS_DELETE:
      nguraDeleteFile();
{$endif}
    NGURA_SAVE_IMAGE:
      nguraSaveImage();
  end;
end;
end.

