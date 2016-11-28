// ********************************************************
//  Copyright (c) 2016 Rob Judd <judd@ob-wan.com>
//  Based on C version by Charles Childers et al
//  ISC License - see included file LICENSE
// ********************************************************

program unu;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils;


procedure extract(fname : String);
var
  source : array[0..4095] of Char;
  f : TextFile;
  inBlock : Boolean = false;
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
      if strcomp(source, '````') = 0 then
        inBlock := not inBlock
      else
        if (inBlock = true) and (strlen(source) <> 0) then
            writeln(format('%s', [source]));
     end;
  finally
    CloseFile(f);
  end;
end;


// ********************************************************
//  Main program
// ********************************************************
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
    extract(ParamStr(i));
end.

