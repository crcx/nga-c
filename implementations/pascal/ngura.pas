// ********************************************************
//  Copyright (c) 2016 Rob Judd <judd@ob-wan.com>
//  Based on C version by Charles Childers et al
//  ISC License - see included file LICENSE
// ********************************************************

unit ngura;

{$mode objfpc}{$H+}
{$macro on}


{$define NGURA_KBD}
{$define NGURA_TTY}
{$define NGURA_FS}

interface

{$include 'nga.inc'}

procedure nguraInitialize();
procedure nguraCleanup();
procedure nguraProcessOpcode(opcode : Cell);

implementation

uses
  SysUtils, vt100 in 'vt100.pas';

var
  sp : Cell;
  data : array [0..STACK_DEPTH-1] of Cell;
  memory : array[0..IMAGE_SIZE-1] of Cell;
  request : array[0..8191] of Char;

{$if defined (NGURA_TTY) or defined (NGURA_KBD)}
{$include termios.inc}
{$endif}

{$ifdef NGURA_TTY}
{$define NGURA_TTY_PUTC   := 100}
{$define NGURA_TTY_PUTN   := 101}
{$define NGURA_TTY_PUTS   := 102}
{$define NGURA_TTY_PUTSC  := 103}
{$define NGURA_TTY_CLEAR  := 104}
{$endif}

{$ifdef NGURA_KBD}
{$define NGURA_KBD_GETC   := 110}
{$define NGURA_KBD_GETN   := 111}
{$define NGURA_KBD_GETS   := 112}
{$endif}

{$ifdef NGURA_FS}
var
  nguraFileHandles : array[1..128] of THandle;
{$define NGURA_FS_OPEN    := 118}
{$define NGURA_FS_CLOSE   := 119}
{$define NGURA_FS_READ    := 120}
{$define NGURA_FS_WRITE   := 121}
{$define NGURA_FS_TELL    := 122}
{$define NGURA_FS_SEEK    := 123}
{$define NGURA_FS_SIZE    := 124}
{$define NGURA_FS_DELETE  := 125}
{$define MAX_OPEN_FILES   := 128}
{$endif}

{$define NGURA_SAVE_IMAGE := 130}


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

procedure nguraTTYPutChar(c : Char);
begin
  write(c);
  if c = #8 then
  begin
    write(#32);
    write(#8);
  end;
end;

{$ifdef NGURA_TTY}
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
  begin
    nguraTTYPutChar(Char(memory[addr]));
    inc(i);
    inc(addr);
  end;
end;

procedure nguraTTYClearDisplay();
begin
  term_clear();
end;
{$endif}

{$ifdef NGURA_KBD}
function nguraKBDGetChar() : Integer;
var
  i : Char = #0;
begin
  read(i);
  if (i = #10) or (i = #13) then
    i := #32;
  nguraTTYPutChar(i);
  result := Integer(i);
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

function nguraKBDGetNumber(delim : Integer) : Cell;
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
      request[i] := Char(k);
    inc(i);
  end;
  request[i] := #0;
  result := strtoint(request);
end;
{$endif}

{$ifdef NGURA_FS}
function nguraGetFileHandle() : Cell;
var
  i : Cell;
begin
  result := 0;
  for i := 1 to MAX_OPEN_FILES do
    if nguraFileHandles[i] = 0 then
      result := i;
end;

function nguraOpenFile() : Cell;
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
    if FileExists(request) then
      case mode of
        0 : nguraFileHandles[slot] := FileOpen(request, fmOpenRead);      // r
        1 : nguraFileHandles[slot] := FileOpen(request, fmOpenWrite);     // w
        2 :
        begin
          nguraFileHandles[slot] := FileOpen(request, fmOpenWrite);       // a
          FileSeek(nguraFileHandles[slot], 0, fsFromEnd);
        end;
        3 : nguraFileHandles[slot] := FileOpen(request, fmOpenReadWrite); // r+
      end
    else
      case mode of
        2, 3 : nguraFileHandles[slot] := FileCreate(request, fmOpenWrite);// w
        1, 4 : writeln('Error: File doesn''t exist!');
      end;
  end;
  if nguraFileHandles[slot] = THandle(-1) then
  begin
    nguraFileHandles[slot] := 0;
    slot := 0;
  end;
  result := slot;
end;

function nguraReadFile() : Cell;
var
  c, err : Cell;
begin
  err := FileRead(nguraFileHandles[TOS], c, SizeOf(Cell));
  dec(sp);
  if err = -1 then
    result := 0
  else
    result := c;
end;

function nguraWriteFile() : Cell;
var
  slot, c, err : Cell;
begin
  slot := TOS;
  dec(sp);
  c := TOS;
  dec(sp);
  err := FileWrite(nguraFileHandles[slot], c, SizeOf(Cell));
  if err = -1 then
    result := 0
  else
    result := 1;
end;

function nguraCloseFile() : Cell;
begin
  FileClose(nguraFileHandles[TOS]);
  nguraFileHandles[TOS] := 0;
  dec(sp);
  result := 0;
end;

function nguraGetFilePosition() : Cell;
var
  slot : Cell;
begin
  slot := TOS;
  dec(sp);
  result := FileSeek(nguraFileHandles[slot], 0, fsFromCurrent);
end;

function nguraSetFilePosition() : Cell;
var
  slot, pos : Cell;
begin
  slot := TOS;
  dec(sp);
  pos := TOS;
  dec(sp);
  result := FileSeek(nguraFileHandles[slot], pos, fsFromBeginning);
end;

function nguraGetFileSize() : Cell;
var
  slot, current, size : Cell;
begin
  slot := TOS;
  dec(sp);
  current := FileSeek(nguraFileHandles[slot], 0, fsFromCurrent);
  size := FileSeek(nguraFileHandles[slot], 0, fsFromEnd);
  FileSeek(nguraFileHandles[slot], current, fsFromBeginning);
  if size <> -1 then
    result := size
  else
    result := 0;
end;

function nguraDeleteFile() : Cell;
var
  name : Cell;
begin
  name := TOS;
  dec(sp);
  nguraGetString(name);
  if DeleteFile(request) then
    result := -1
  else
    result := 0;
end;
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
  term_setup();
{$endif}
end;

procedure nguraCleanup();
begin
{$if defined(NGURA_TTY) or defined(NGURA_KBD)}
  term_cleanup();
{$endif}
end;

procedure nguraProcessOpcode(opcode : Cell);
{$if defined (NGURA_TTY) or defined (NGURA_KBD)}
var
{$endif}
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

