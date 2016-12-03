// ********************************************************
//  Copyright (c) 2016 Rob Judd <judd@ob-wan.com>
//  Based on C version by Charles Childers et al
//  ISC License - see included file LICENSE
// ********************************************************

unit libc;

{$mode objfpc}{$H+}
{$macro on}

interface

function strspn(const strg : PChar; const delim : PChar) : Word;
function strcspn(const strg : PChar; const delim : PChar) : Word;
function strtok_r(str : PChar; const delim: PChar; nextp: PPChar) : PChar;

implementation

{private}
(*******************************************************************)

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


{public}
(*******************************************************************)

function strspn(const strg : PChar; const delim : PChar) : Word;
begin
  result := strspan(strg, delim, true);
end;

function strcspn(const strg : PChar; const delim : PChar) : Word;
begin
  result := strspan(strg, delim, false);
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
end.

