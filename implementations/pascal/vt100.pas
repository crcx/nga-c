// ********************************************************
//  Copyright (c) 2016 Rob Judd <judd@ob-wan.com>
//  Based on C version by Charles Childers et al
//  ISC License - see included file LICENSE
// ********************************************************

unit vt100;

{$mode objfpc}{$H+}
{$macro on}

interface

{$include 'termios.inc'}

var
  new_termios, old_termios : termios;

function tcgetattr(_fildes : Integer; _termios_p : Ptermios) : Integer;
function	tcsetattr(_fildes, _optional_actions : Integer; const _termios_p : Ptermios) : Integer;
procedure term_setup();
procedure term_cleanup();
procedure term_clear();
procedure term_move_cursor(x, y : Integer);

implementation

uses
  SysUtils;

function tcgetattr(_fildes : Integer; _termios_p : Ptermios) : Integer;
begin
  result := 0;
end;

function	tcsetattr(_fildes, _optional_actions : Integer; const _termios_p : Ptermios) : Integer;
begin
  result := 0;
end;

procedure term_setup();
begin
  tcgetattr(0, @old_termios);
  new_termios := old_termios;
  new_termios.c_iflag := new_termios.c_iflag and not(BRKINT+ISTRIP+IXON+IXOFF);
  new_termios.c_iflag := new_termios.c_iflag or (IGNBRK+IGNPAR);
  new_termios.c_lflag := new_termios.c_lflag and not(ICANON+ISIG+IEXTEN+ECHO);
  new_termios.c_cc[VMIN] := 1;
  new_termios.c_cc[VTIME] := 0;
  tcsetattr(0, TCSANOW, @new_termios);
end;

procedure term_cleanup();
begin
  tcsetattr(0, TCSANOW, @old_termios);
end;

procedure term_clear();
begin
  write('\033[2J\033[1;1H');
end;

procedure term_move_cursor(x, y : Integer);
begin
  write(format('\033[%d;%dH', [y, x]));
end;
end.

