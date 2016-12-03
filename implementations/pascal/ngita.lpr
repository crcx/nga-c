// ********************************************************
//  Copyright (c) 2016 Rob Judd <judd@ob-wan.com>
//  Based on C version by Charles Childers et al
//  ISC License - see included file LICENSE
// ********************************************************

program ngita;

{$mode objfpc}{$H+}
{$macro on}

uses
  SysUtils, nga in 'nga.pas', ngura in 'ngura.pas';

{$include 'nga.inc'}

// implementation

procedure processOpcodes();
var
  opcode: Cell;
begin
  ip := 0;
  while ip < IMAGE_SIZE - 1 do
  begin
    opcode := memory[ip];
    if ngaValidatePackedOpcodes(opcode) <> 0 then
      ngaProcessPackedOpcodes(opcode)
    else
    if (opcode >= 0) and (opcode < 27) then
      ngaProcessOpcode(opcode)
    else
      nguraProcessOpcode(opcode);
    inc(ip);
  end;
end;


//*********************************************************
// Main
//*********************************************************
var
  i, size : Cell;
begin
  ngaPrepare();

  if ParamCount > 0 then
    size := ngaLoadImage(PChar(ParamStr(1)))
  else
    size := ngaLoadImage('ngaImage');
  if size = 0 then
    exit();

  nguraInitialize();
  processOpcodes();
  nguraCleanup();
  for i := 1 to sp do
    write(format('%d ', [data[i]]));
  writeln;
end.

