// ********************************************************
//  Copyright (c) 2016 Rob Judd <judd@ob-wan.com>
//  Based on C version by Charles Childers et al
//  ISC License - see included file LICENSE
// ********************************************************

unit termioz;

{$mode objfpc}{$H+}
{$macro on}

interface

type
  Cell = Longint;

{$include termios.inc}

function tcgetattr(_fildes : Integer; _termios_p : Ptermios) : Integer;
function tcsetattr(_fildes, _optional_actions : Integer; const _termios_p : Ptermios) : Integer;

implementation

uses
  Classes, SysUtils;

function tcgetattr(_fildes : Integer; _termios_p : Ptermios) : Integer;
begin
  result := 0;
end;


function tcsetattr(_fildes, _optional_actions : Integer; const _termios_p : Ptermios) : Integer;
begin
  result := 0;
end;
end.
 
