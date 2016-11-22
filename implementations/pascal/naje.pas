// ********************************************************
//  Copyright (c) 2016 Rob Judd <judd@ob-wan.com>
//  Based on C version by Charles Childers et al
//  ISC License - see included file LICENSE
// ********************************************************

unit naje;

{$mode objfpc}{$H+}

{$define ALLOW_FORWARD_REFS}
{$define ENABLE_MAP}
{$define DEBUG}

interface

uses
  Classes, SysUtils;

type
  Cell = Longint;

var
  latest, dindex, pindex, packmode, np : Cell;
  packet : array[0..3] of Cell;
  dataList, dataType, najePointers, najeRefCount : array[0..1023] of Cell;
  najeLabels : array[0..1023] of PChar;
  outputName : array[0..63] of Char;
  memory : array [0..524287] of Cell;
  references : array[0..524287] of Cell;

{$ifdef ALLOW_FORWARD_REFS}
  ref_names : array[0..1023] of PChar;
  refp : Cell;
{$endif}

implementation

function najeLookup(name : PChar) : Cell;
var
  n : Cell;
  slice : Cell = -1;
begin
  n := np;
  while n > 0 do
  begin
    dec(n);
    if (strcomp(najeLabels[n], name) = 0) then
      slice := najePointers[n];
  end;
  result := slice;
end;


{$ifdef ALLOW_FORWARD_REFS}
function najeLookupPtr(name : PChar) : Cell;
var
  n : Cell;
  slice : Cell = -1;
begin
  n := np;
  while n > 0 do
  begin
    dec(n);
    if (strcomp(najeLabels[n], name) = 0) then
      slice := n;
  end;
  result := slice;
end;
{$endif}


procedure najeAddLabel(name : PChar; slice : Cell);
begin
  if najeLookup(name) = -1 then
  begin
    najeLabels[np] := stralloc(strlen(name) + 1);
    strcopy(najeLabels[np], name);
    najePointers[np] := slice;
    najeRefCount[np] := 0;
    inc(np);
  end
  else
  begin
    writeln(format('Error: Label %s already defined', [name]));
    exit();
  end;
end;


{$ifdef ALLOW_FORWARD_REFS}
procedure najeAddReference(name : PChar);
begin
  strcopy(ref_names[refp], name);
  inc(refp);
end;
{$endif}


procedure najeResolveReferences();
{$ifdef ALLOW_FORWARD_REFS}
var
  i, j, offset, matched : Cell;
{$endif}
begin
{$ifdef ALLOW_FORWARD_REFS}
  for i := 0 to refp - 1 do
  begin
    offset := najeLookup(ref_names[i]);
    matched := 0;
    if offset <> -1 then
    begin
      for j := 0 to latest - 1 do
      begin
        if (references[j] = 1) and (matched = 0) then
        begin
          memory[j] := offset;
          references[j] := -1;
          inc(najeRefCount[najeLookupPtr(ref_names[i])]);
          matched := -1;
        end;
      end;
    end
    else
      writeln(#10, 'Error: Failed to resolve a reference: ', ref_names[i]);
  end;
{$endif}
end;


{$ifdef ENABLE_MAP}
procedure najeWriteMap();
var
  f : TextFile;
  i : Cell;
begin
  AssignFile(f, strcat(@outputName, '.map'));
  ReWrite(f);
  try
    for i := 0 to np - 1 do
      writeln(f, format('LABEL%6s%4d', [najeLabels[i], najePointers[i]]));
    for i := 0 to latest - 1 do
      if references[i] = 0 then
        writeln(f, format('LITERAL%4d%4d', [memory[i], i]))
      else if references[i] = -1 then
        writeln(f, format('POINTER%4d%4d', [memory[i], i]));
  finally
    Close(f);
  end;
end;
{$endif}


procedure najeStore(typo, value : Cell);
begin
  memory[latest] := value;
  references[latest] := typo;          // 'type' is a Pascal reserved word
  inc(latest);
end;


procedure najeSync();
var
  i, opcode : Cell;
begin
  if packMode = 0 then
    exit();
  if (pindex = 0) and (dindex = 0) then
    exit();
  if pindex <> 0 then
  begin
    opcode := 0;
    opcode := packet[3];               // 'packed' is a Pascal reserved word
    opcode := opcode shl 8;
    opcode += packet[2];
    opcode := opcode shl 8;
    opcode += packet[1];
    opcode := opcode shl 8;
    opcode += packet[0];
    najeStore(2, opcode);
  end;
  if dindex <> 0 then
  begin
    for i := 0 to dindex - 1 do
      najeStore(dataType[i], dataList[i]);
  end;
  pindex := 0;
  dindex := 0;
  packet[0] := 0;
  packet[1] := 0;
  packet[2] := 0;
  packet[3] := 0;
end;


procedure najeInst(opcode : Cell);
begin
  if packMode = 0 then
    najeStore(0, opcode)
  else
  begin
    if pindex = 4 then
      najeSync();
    packet[pindex] := opcode;
    inc(pindex);
    case opcode of
      7..10 : ;
      25    : najeSync();
    end;
  end;
end;


procedure najeData(typo, data : Cell);
begin
  if packMode = 0 then
    najeStore(typo, data)
  else
  begin
    dataList[dindex] := data;
    dataType[dindex] := typo;
    inc(dindex);
  end;
end;


// Combination of strspn() and strcspn() for compactness
function strspan(const strg : PChar; const delim : PChar; flag : Boolean) : Integer;
var
  str, del : PChar;
  map : array[0..31] of Byte;
  count : Integer;
begin
  str := PChar(strg);
  del := delim;
  // init the map
  for count := 0 to 31 do
    map[count] := 0;

  while del^ <> #0 do
  begin
    map[Byte(del^) shr 3] := map[Byte(del^) shr 3] or (1 shl (Byte(del^) and 7));
    inc(del);
  end;

  if flag then                         // strspn()
  begin
    // first character NOT in map stops search
    if str^ <> #0 then
    begin
      count := 0;
      while (map[Byte(str^) shr 3] and (1 shl (Byte(str^) and 7))) <> 0 do
      begin
        inc(count);
        inc(str);
      end;
      exit(count);
    end;
    exit(0);
  end
  else                                 // strcspn()
  begin
    // first character in map stops search
    count := 0;
    map[0] := map[0] or 1;             // no null chars
    while (map[Byte(str^) shr 3] and (1 shl (Byte(str^) and 7))) = 0 do
    begin
      inc(count);
      inc(str);
    end;
    exit(count);
  end;
end;


// Inspired by public domain strtok_r() by Charlie Gordon
function strtok_r(str : PChar; const delim: String; nextp: PPChar) : PChar;
var
  del : PChar;
begin
  del := PChar(delim);

  if str = nil then
    str := nextp^;
  //writeln('str = ', str);
  str += strspan(str, del, true);
  if str^ = #0 then
    exit(nil);
  result := str;
  writeln('result = ', str);
  str += strspan(str, del, false);
  if str^ <> #0 then
  begin
    inc(str);
    str^ := #0;
  end;
  nextp^ := str;
end;


procedure najeAssemble(source : PChar);
var
  i : Cell;
  token, rest, ptr : PChar;
  relevant : array [0..2] of Char;
begin
  ptr := source;
  relevant[0] := #0;
  relevant[1] := #0;
  relevant[2] := #0;
  if strlen(source) = 0 then
    exit();
  token := strtok_r(ptr, ' ,', @rest);
  ptr := rest;
  relevant[0] := token[0];
  relevant[1] := token[1];
  // Labels start with ':'
  if relevant[0] = ':' then
  begin
    najeSync();
    najeAddLabel(token + 1, latest);
  end;
  // Directives start with '.'
  if relevant[0] = '.' then
  begin
    case relevant[1] of
      'r': begin                                      // .reference
             token := strtok_r(ptr, ' ,', @rest);
{$ifdef ALLOW_FORWARD_REFS}
             najeAddReference(token);
             najeData(1, -9999);
{$else}
             najeData(0, najeLookup(token));
{$endif}
           end;
      'c': ;                                          // .comment
      'd': begin                                      // .data
             token := strtok_r(ptr, ' ,', @rest);
             najeSync();
             najeData(0, strtoint(token));
             najeSync();
           end;
      'o': begin                                      // .output
             token := strtok_r(ptr, ' ,', @rest);
             strcopy(@outputName, token);
           end;
      'p': packMode := 1;                             // set packed mode
      'u': begin                                      // set unpacked mode
             najeSync();
             packMode := 0;
           end;
      'a': begin                                      // .allocate
             token := strtok_r(ptr, ' ,', @rest);
             i := strtoint(token);
             najeSync();
             while i > 0 do
             begin
               najeData(0, 0);
               dec(i);
             end;
             najeSync();
           end;
      's': begin                                      // .string
             token := strtok_r(ptr, #10, @rest);
             i := 0;
             najeSync();
             while i < strlen(token) do
             begin
               najeData(0, Cell (token[i]));
               inc(i);
             end;
             najeData(0, 0);
             najeSync();
           end;
    end;
  end;
  // Instructions
  if strcomp(relevant, 'no') = 0 then
    najeInst(0);
  if strcomp(relevant, 'li') = 0 then
  begin
    token := strtok_r(ptr, ' ,', @rest);
    najeInst(1);
    writeln('token', token[0]);
    if token[0] = '&' then
    begin
{$ifdef ALLOW_FORWARD_REFS}
      najeAddReference(token + 1);
      najeData(1, -9999);
{$else}
      najeData(0, najeLookup(token + 1));
{$endif}
    end
    else
      najeData(0, strtoint(token));
  end;
  if strcomp(relevant, 'du') = 0 then
    najeInst(2);
  if strcomp(relevant, 'dr') = 0 then
    najeInst(3);
  if strcomp(relevant, 'sw') = 0 then
    najeInst(4);
  if strcomp(relevant, 'pu') = 0 then
    najeInst(5);
  if strcomp(relevant, 'po') = 0 then
    najeInst(6);
  if strcomp(relevant, 'ju') = 0 then
    najeInst(7);
  if strcomp(relevant, 'ca') = 0 then
    najeInst(8);
  if strcomp(relevant, 'cc') = 0 then
    najeInst(9);
  if strcomp(relevant, 're') = 0 then
    najeInst(10);
  if strcomp(relevant, 'eq') = 0 then
    najeInst(11);
  if strcomp(relevant, 'ne') = 0 then
    najeInst(12);
  if strcomp(relevant, 'lt') = 0 then
    najeInst(13);
  if strcomp(relevant, 'gt') = 0 then
    najeInst(14);
  if strcomp(relevant, 'fe') = 0 then
    najeInst(15);
  if strcomp(relevant, 'st') = 0 then
    najeInst(16);
  if strcomp(relevant, 'ad') = 0 then
    najeInst(17);
  if strcomp(relevant, 'su') = 0 then
    najeInst(18);
  if strcomp(relevant, 'mu') = 0 then
    najeInst(19);
  if strcomp(relevant, 'di') = 0 then
    najeInst(20);
  if strcomp(relevant, 'an') = 0 then
    najeInst(21);
  if strcomp(relevant, 'or') = 0 then
    najeInst(22);
  if strcomp(relevant, 'xo') = 0 then
    najeInst(23);
  if strcomp(relevant, 'sh') = 0 then
    najeInst(24);
  if strcomp(relevant, 'zr') = 0 then
    najeInst(25);
  if strcomp(relevant, 'en') = 0 then
    najeInst(26);
end;


procedure prepare();
var
  i : Word;
begin
  np := 0;
  latest := 0;
  packMode := 1;
  for i := 0 to 1023 do
    najeLabels[i] := nil;
  strcopy(@outputName, 'ngaImage');
  // assemble the standard preamble (a jump to :main)
  najeInst(1);                         // LIT
  najeData(0, 0);                      // placeholder
  najeInst(7);                         // JUMP
end;


procedure finish();
var
  entry : Cell = 0;
begin
  entry := najeLookup('main');
  memory[1] := entry;
end;


procedure read_line(var fptr : TextFile; line_buffer : PChar);
var
  ch : Char;
  count : Cell = 0;
begin
  if line_buffer = nil then
  begin
    writeln('Can''t allocate line buffer memory.');
    halt();
  end;
  read(fptr, ch);
  while (ch <> #10) and (not eof(fptr)) do
  begin
    line_buffer[count] := ch;
    inc(count);
    read(fptr, ch);
  end;
  line_buffer[count] := #0;
end;


procedure process_file(fname : string);
var
  f : TextFile;
  source : array [0..63999] of Char;
begin
  try
    AssignFile(f, fname);
    Reset(f);
  except
    on E: EInOutError do
    begin
      writeln(E.Message, ': ', fname );
      halt();
    end;
  end;
  try
    while not eof(f) do
    begin
      read_line(f, @source);
      najeAssemble(@source);
    end;
  finally
    CloseFile(f);
  end;
end;


procedure save();
var
  f : File;
begin
  try
    Assignfile(f, outputName);
    ReWrite(f);
  except
    on E: EInOutError do
    begin
      writeln(E.Message, ': ', outputName);
      halt();
    end;
  end;
  try
    BlockWrite(f, memory, sizeOf(Cell), latest);
  finally
    CloseFile(f);
  end;
end;


// ********************************************************
//  Main program
// ********************************************************
{$ifdef DEBUG}
var
  i : Cell;
{$endif}
begin
  // make sure we have a filename
  if ParamCount = 0 then
  begin
    writeln('No filename specified!');
    exit();
  end;
  // ok, continue
  prepare();
  process_file(ParamStr(1));
  najeSync();
  najeResolveReferences();
  najeSync();
  finish();
  save();
{$ifdef ENABLE_MAP}
  najeWriteMap();
{$endif}
{$ifdef DEBUG}
  write(#10, 'Bytecode', #10, '[ ');
  for i := 0 to latest - 1 do
    write(format('%d, ', [memory[i]]));
  write(']', #10, 'Labels', #10);
  for i := 0 to np - 1 do
    write(format('%s^%d.%d ', [najeLabels[i], najePointers[i], najeRefCount[i]]));
  writeln();
  writeln(format('%d cells written to ngaImage', [latest]));
{$endif}
end.
