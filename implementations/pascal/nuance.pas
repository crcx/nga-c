// ********************************************************
//  Copyright (c) 2016 Rob Judd <judd@ob-wan.com>
//  Based on C version by Charles Childers et al
//  ISC License - see included file LICENSE
// ********************************************************

program nuance;

{$mode objfpc}{$H+}

//interface

uses
  Classes, SysUtils;

//type

var
  reform : array[0..998] of Char;
  cycle : Integer = 0;

//implementation


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


procedure resetReform();
begin
  fillchar(reform, 999, #0);
end;


function compile(source : PChar) : Integer;
var
  token : PChar = nil;
  state : PChar;
  prefix : Char;
  scratch, i : Integer;
  nmax : Integer = 0;
  nest : Integer = 0;
begin
  writeln(format('.comment %s', [source]));
  token := strtok_r(source, ' ', @state);
  while token <> nil do
  begin
    prefix := Char(token[0]);
    case prefix of
      '''':
      begin
        if token[strlen(token) - 1] = '''' then
        begin
          resetReform();
          move(token[1], reform, strlen(token) - 2);
          reform[strlen(token) - 2] := #0;
          writeln(format('  .string %s', [reform]));
        end
        else
        begin
          resetReform();
          move(token[1], reform, strlen(token) - 1);
          i := 0;
          while i = 0 do
          begin
            strcat(reform, ' ');
            token := strtok_r(nil, ' ', @state);
            if (token[strlen(token) - 1] = '''') or (token = nil) then
            begin
              i := 1;
              token[strlen(token) - 1] := #0;
              strcat(reform, token);
            end
            else
              strcat(reform, token);
          end;
          writeln(format('  .string %s', [reform]));
        end;
      end;
      '"':
      begin
        if token[strlen(token) - 1] <> '"' then
        begin
          i := 0;
          while i = 0 do
          begin
            token := strtok_r(nil, ' ', @state);
            if (token[strlen(token) - 1] = '"') or (token = nil) then
              i := 1;
          end;
        end;
      end;
      ':':
        writeln(format('%s', [token]));
      '#':
      begin
        resetReform();
        move(token[1], reform, strlen(token) - 1);
        writeln(format('  lit %s', [PChar(token + 1)]));
      end;
      '~':
      begin
        resetReform();
        move(token[1], reform, strlen(token) - 1);
        writeln(format('  .allocate %s', [reform]));
      end;
      '&':
      begin
        resetReform();
        move(token[1], reform, strlen(token) - 1);
        writeln(format('  lit &%s', [reform]));
      end;
      '^':
      begin
        resetReform();
        move(token[1], reform, strlen(token) - 1);
        writeln(format('  lit &%s%d  jump', [#10, reform]));
      end;
      '$':
      begin
        scratch := Integer(token[1]);
        writeln(format('  lit %d', [scratch]));
      end;
      '`':
      begin
        resetReform();
        move(token[1], reform, strlen(token) - 1);
        writeln(format('  .data %s', [reform]));
      end;
      '|':
      begin
        resetReform();
        move(token[1], reform, strlen(token) - 1);
        writeln(format('  .ref %s', [reform]));
      end;
      else
        if (strcomp(token, '[') = 0) then
        begin
          if (nmax > 0) and (nest = 0) then
            cycle += cycle;
          nest += nest;
          writeln(format('  lit &%d<%d_s>', [cycle, nest]));
          writeln(format('  lit &%d<%d_e>%d  jump', [cycle, nest, #0]));
          writeln(format(':%d<%d_s>', [cycle, nest]));
        end
        else if strcomp(token, ']') = 0 then
        begin
          writeln('  ret');
          writeln(format(':%d<%d_e>', [cycle, nest]));
          if nest > nmax then
            nmax := nest;
          nest -= nest;
        end
        else if strcomp(token, '0;') = 0 then
          writeln('  zret')
        else if strcomp(token, 'push') = 0 then
          writeln('  push')
        else if strcomp(token, 'pop') = 0 then
        begin
          writeln('  pop');
        end
        else
        begin
          if strcomp(token, ';') = 0 then
            writeln('  ret')
          else
            writeln(format('  lit &%s%d  call', [token, #10]));
        end;
    end;
  token := strtok_r(nil, ' ', @state);
  end;
  cycle += cycle;
  result := 0;
end;


procedure read_line(var fptr : TextFile; line_buffer : PChar);
var
  ch : Char;
  count : Cardinal = 0;
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


procedure parse(fname : String);
var
  f : TextFile;
  source : array[0..63000] of Char;
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
      compile(@source);
    end;
  finally
    CloseFile(f);
  end;
end;


//*********************************************************
// Main
//*********************************************************
var
  i : Byte;
begin
  // make sure we have a filename
  if ParamCount = 0 then
  begin
    writeln('No filename specified!');
    exit();
  end;
  // ok, continue
  for i := 1 to ParamCount do
    parse(ParamStr(i));
end.
