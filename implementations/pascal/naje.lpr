// ********************************************************
//  Copyright (c) 2016 Rob Judd <judd@ob-wan.com>
//  Based on C version by Charles Childers et al
//  ISC License - see included file LICENSE
// ********************************************************

program naje;

{$mode objfpc}{$H+}

{$define ALLOW_FORWARD_REFS}
{$define ENABLE_MAP}
{$define DEBUG}

//interface

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


//implementation

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
    halt();
  end;
end;


{$ifdef ALLOW_FORWARD_REFS}
procedure najeAddReference(name : PChar);
begin
  ref_names[refp] := stralloc(strlen(name) + 1);
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
      writeln(LineEnding, 'Error: Failed to resolve a reference: ', ref_names[i]);
  end;
{$endif}
end;


{$ifdef ENABLE_MAP}
procedure najeWriteMap();
var
  f : TextFile;
  i : Cell;
begin
  AssignFile(f, strcat(outputName, '.map'));
  ReWrite(f);
  try
    for i := 0 to np - 1 do
      writeln(f, format('LABEL%8s%4d', [najeLabels[i], najePointers[i]]));
    for i := 0 to latest - 1 do
      if references[i] = 0 then
        writeln(f, format('LITERAL%6d%4d', [memory[i], i]));
    for i := 0 to latest - 1 do
      if references[i] = -1 then
        writeln(f, format('POINTER%6d%4d', [memory[i], i]));
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
    for i := 0 to dindex - 1 do
      najeStore(dataType[i], dataList[i]);
  pindex := 0;
  dindex := 0;
  for i := 0 to 3 do
    packet[i] := 0;
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
      7..10, 25..26 : najeSync();
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
function strspan(const strg : PChar; const delim : PChar; flag : Boolean) : Word;
var
  str, del : PChar;
  s, d : Char;
begin
  str := strg;
  s := str^;
  while s <> #0 do
  begin
    del := delim;
    d := del^;
    while d <> #0 do
    begin
      if flag then
        if d = s then                  // strspn
          break
        else
          exit(str - strg)
      else
        if d = s then                  // strcspn
          exit(str - strg);
      inc(del);
      d := del^;
    end;
    inc(str);
    s := str^;
  end;
  result := (str - strg);
end;


// Inspired by public domain strtok_r() by Charlie Gordon
function strtok_r(str : PChar; const delim: PChar; nextp: PPChar) : PChar;
begin
  if str = nil then
    str := nextp^;
  str += strspan(str, delim, true);
  if str^ = #0 then
    exit(nil);
  result := str;
  str += strspan(str, delim, false);
  if str^ <> #0 then
  begin
    str^ := #0;
    inc(str);
  end;
  nextp^ := str;
end;


procedure najeAssemble(source : PChar);
var
  i : Cell;
  token, rest : PChar;
  relevant : array [0..2] of Char = (#0,#0,#0);
begin
  token := strtok_r(source, ' ', @rest);
  relevant[0] := token[0];
  relevant[1] := token[1];
  // Labels start with ':'
  if relevant[0] = ':' then
  begin
    najeSync();
    najeAddLabel(token + 1, latest);
    exit();
  end;
  // Directives start with '.'
  if relevant[0] = '.' then
  begin
    case relevant[1] of
      'r': begin                                      // .reference
             token := strtok_r(nil, ' ', @rest);
{$ifdef ALLOW_FORWARD_REFS}
             najeAddReference(token);
             najeData(1, -9999);
{$else}
             najeData(0, najeLookup(token));
{$endif}
           end;
      'c': ;                                          // .comment
      'd': begin                                      // .data
             token := strtok_r(nil, ' ', @rest);
             najeSync();
             najeData(0, strtoint(token));
             najeSync();
           end;
      'o': begin                                      // .output
             token := strtok_r(nil, ' ', @rest);
             strcopy(outputName, token);
           end;
      'p': packMode := 1;                             // .packed
      'u': begin                                      // .unpacked
             najeSync();
             packMode := 0;
           end;
      'a': begin                                      // .allocate
             token := strtok_r(nil, ' ', @rest);
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
             token := strtok_r(nil, LineEnding, @rest);
             i := 0;
             najeSync();
             while i < strlen(token) do
             begin
               najeData(0, Cell(token[i]));
               inc(i);
             end;
             najeData(0, 0);
             najeSync();
           end
        else
        begin
          writeln(format('''%s'': Invalid directive!', [String(relevant)]));
          halt();
        end;
    end;
    exit();
  end;
  // Instructions
  case String(relevant) of
    'no' : najeInst(0);
    'li' :
    begin
      token := strtok_r(nil, ' ', @rest);
      najeInst(1);
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
    'du' : najeInst(2);
    'dr' : najeInst(3);
    'sw' : najeInst(4);
    'pu' : najeInst(5);
    'po' : najeInst(6);
    'ju' : najeInst(7);
    'ca' : najeInst(8);
    'cc' : najeInst(9);
    're' : najeInst(10);
    'eq' : najeInst(11);
    'ne' : najeInst(12);
    'lt' : najeInst(13);
    'gt' : najeInst(14);
    'fe' : najeInst(15);
    'st' : najeInst(16);
    'ad' : najeInst(17);
    'su' : najeInst(18);
    'mu' : najeInst(19);
    'di' : najeInst(20);
    'an' : najeInst(21);
    'or' : najeInst(22);
    'xo' : najeInst(23);
    'sh' : najeInst(24);
    'zr' : najeInst(25);
    'en' : najeInst(26);
    else
    begin
      writeln(format('''%s'': Invalid instruction!', [String(relevant)]));
      halt();
    end;
  end;
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
  strcopy(outputName, 'ngaImage');
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
      readln(f, source);
      if strlen(source) <> 0 then
        najeAssemble(source);
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
    ReWrite(f, latest);
  except
    on E: EInOutError do
    begin
      writeln(E.Message, ': ', outputName);
      halt();
    end;
  end;
  try
    BlockWrite(f, memory, sizeOf(Cell));
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
  write(LineEnding, 'Bytecode', LineEnding, '[ ');
  for i := 0 to latest - 1 do
    write(format('%d, ', [memory[i]]));
  write(']', LineEnding, 'Labels', LineEnding);
  for i := 0 to np - 1 do
    write(format('%s^%d.%d ', [najeLabels[i], najePointers[i], najeRefCount[i]]));
  writeln();
  writeln(format('%d cells written to %s', [latest, outputName]));
{$endif}
end.

