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

type
  Cell = Longint;

{$define IMAGE_SIZE:=524288}

// implementation

procedure processOpcodes();
var
  opcode: Cell;
begin
  ip := 0;
  while ip < IMAGE_SIZE - 1 do
  begin
    opcode := memory[ip];
    if nga.ngaValidatePackedOpcodes(opcode) <> 0 then
      nga.ngaProcessPackedOpcodes(opcode)
    else
    if (opcode >= 0) and (opcode < 27) then
      nga.ngaProcessOpcode(opcode)
    else
      ngura.nguraProcessOpcode(opcode);
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
    size := ngaLoadImage(ParamStr(1))
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

