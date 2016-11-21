// ********************************************************
//  Copyright (c) 2016 Rob Judd <judd@ob-wan.com>
//  Based on C version by Charles Childers et al
//  ISC License - see included file LICENSE
// ********************************************************

unit nga;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type Cell = Longint;

type vm_opcode = (
   VM_NOP, VM_LIT, VM_DUP, VM_DROP, VM_SWAP, VM_PUSH, VM_POP,
   VM_JUMP, VM_CALL, VM_CCALL, VM_RET, VM_EQ, VM_NEQ, VM_LT,
   VM_GT, VM_FETCH, VM_STORE, VM_ADD, VM_SUB, VM_MUL, VM_DIVMOD,
   VM_AND, VM_OR, VM_XOR, VM_SHIFT, VM_ZRET, VM_END
);

var
  NUM_OPS : Byte = ord(VM_END) + 1;    // number of opcodes
  IMAGE_SIZE : Cell = 524288;          // memory image (512k x 32 bits)
  ip, ap, sp : Cell;                   // instruction, address & stack pointers
  data : array [1..32] of Cell;        // stack depth
  address : array [1..128] of Cell;    // addresses
  memory : array [1..524288] of Cell;  // image size
  TOS, NOS, TOA : Cell;                // top stack, next stack & top address

implementation

function ngaLoadImage(imageFile : string) : Cell;
var
  f : File;
  sr : TSearchRec;
  fileLen: Cell;
  imageSize : Cell = 0;
begin
  // Does the file exist?
  if FindFirst(imageFile, faAnyFile-faDirectory, sr) = 0 then
  begin
    // Determine number of Cells
    fileLen := sr.Size div sizeof(Cell);
    // Read the file into memory
    Assignfile(f, imageFile);
    try
      BlockRead(f, memory, fileLen, imageSize);
    finally
      CloseFile(f);
    end;
  end
  else
  begin
    writeln('Unable to find ', imageFile + '!' + #13);
    exit();
  end;
  FindClose(sr);
  result := imageSize;
end;

procedure ngaPrepare();
var
  i : Cell;
begin
  // Initialize pointers
  ip := 0;
  ap := 0;
  sp := 0;
  // Initialize arrays
  for i := 1 to length(data) do
    data[i] := ord(VM_NOP);            // normally zero
  for i := 1 to length(address) do
    address[i] := 0;
  for i := 1 to length(memory) do
    memory[i] := 0;
end;

procedure inst_nop();
begin
  // Do nothing
end;

procedure inst_lit();
begin
  inc(ip);
  inc(sp);
  TOS := memory[ip];
end;

procedure inst_dup();
begin
  inc(sp);
  data[sp] := NOS;
end;

procedure inst_drop();
begin
  data[sp] := 0;
  dec(sp);
  if sp < 0 then
    ip := IMAGE_SIZE;
end;

procedure inst_swap();
var a : Cell;
begin
  a := TOS;
  TOS := NOS;
  NOS := a;
end;

procedure inst_push();
begin
  inc(ap);
  TOA := TOS;
  inst_drop();
end;

procedure inst_pop();
begin
  inc(sp);
  TOS := TOA;
  dec(ap);
end;

procedure inst_jump();
begin
  ip := TOS - 1;
  inst_drop();
end;

procedure inst_call();
begin
  inc(ap);
  TOA := ip;
  ip := TOS - 1;
  inst_drop();
end;

procedure inst_ccall();
var
  a, b : Cell;
begin
  a := TOS;
  inst_drop();                         // false
  b := TOS;
  inst_drop();                         // flag
  if b <> 0 then
  begin
    inc(ap);
    TOA := ip;
    ip := a - 1;
  end;
end;

procedure inst_ret();
begin
  ip := TOA;
  dec(ap);
end;

procedure inst_eq();
begin
  if NOS = TOS then
    NOS := -1
  else
    NOS := 0;
  inst_drop();
end;

procedure inst_neq();
begin
  if NOS <> TOS then
    NOS := -1
  else
    NOS := 0;
  inst_drop();
end;

procedure inst_lt();
begin
  if NOS < TOS then
    NOS := -1
  else
    NOS := 0;
  inst_drop();
end;

procedure inst_gt();
begin
  if NOS > TOS then
    NOS := -1
  else
    NOS := 0;
  inst_drop();
end;

procedure inst_fetch();
begin
  case TOS of
    -1 : TOS := sp - 1;
    -2 : TOS := ap;
  else
    TOS := memory[TOS];
  end;
end;

procedure inst_store();
begin
  memory[TOS] := NOS;
  inst_drop();
  inst_drop();
end;

procedure inst_add();
begin
  NOS := NOS + TOS;
  inst_drop();
end;

procedure inst_sub();
begin
  NOS := NOS - TOS;
  inst_drop();
end;

procedure inst_mul();
begin
  NOS := NOS * TOS;
  inst_drop();
end;

procedure inst_divmod();
var
  a, b : Cell;
begin
  a := TOS;
  b := NOS;
  TOS := b div a;
  NOS := b mod a;
end;

procedure inst_and();
begin
  NOS := NOS and TOS;
  inst_drop();
end;

procedure inst_or();
begin
  NOS := NOS or TOS;
  inst_drop();
end;

procedure inst_xor();
begin
  NOS := NOS xor TOS;
  inst_drop();
end;

procedure inst_shift();
var
  x, y : Cell;
  z : Cell = 0;
begin
  x := NOS;
  y := TOS;
  if TOS < 0 then
    NOS := NOS shl (TOS * -1)
  else
  begin
    if (x < 0) and (y > 0) then
      NOS := x shr y or not(not z shr y)
    else
      NOS := x shr y;
  end;
end;

procedure inst_zret();
begin
  if TOS = 0 then
  begin
    inst_drop();
    ip := TOA;
    dec(ap);
  end;
end;

procedure inst_end();
begin
  ip := IMAGE_SIZE;
end;

procedure ngaProcessOpcode(opcode : Cell);
begin
  case opcode of
    1  : inst_nop();
    2  : inst_lit();
    3  : inst_dup();
    4  : inst_drop();
    5  : inst_swap();
    6  : inst_push();
    7  : inst_pop();
    8  : inst_jump();
    9  : inst_call();
    10 : inst_ccall();
    11 : inst_ret();
    12 : inst_eq();
    13 : inst_neq();
    14 : inst_lt();
    15 : inst_gt();
    16 : inst_fetch();
    17 : inst_store();
    18 : inst_add();
    19 : inst_sub();
    20 : inst_mul();
    21 : inst_divmod();
    22 : inst_and();
    23 : inst_or();
    24 : inst_xor();
    25 : inst_shift();
    26 : inst_zret();
    27 : inst_end();
  end;
end;

function ngaValidatePackedOpcodes(opcode : Cell) : Integer;
var
  raw, current : Cell;
  valid : Integer = - 1;               // value for "true" in Unix-land
  i : Integer;
begin
  raw := opcode;
  for i := 1 to 4 do
  begin
    current := raw and $FF;
    if ((current >= 0) and (current < NUM_OPS)) = false then
      valid := 0;
    raw := raw shr 8;
  end;
  result := valid;
end;

procedure ngaProcessPackedOpcodes(opcode : Cell);
var
  raw : Cell;
  i : Byte;
begin
  raw := opcode;
  for i := 1 to 4 do
  begin
    ngaProcessOpcode(raw and $FF);
    raw := raw shr 8;
  end;
end;

// ********************************************************
//  Main program
// ********************************************************
var
  i, opcode, size : Cell;
begin
  ngaPrepare();
  if ParamCount > 0 then
    size := ngaLoadImage(ParamStr(1))
  else
    size := ngaLoadImage('ngaImage');

  for ip := 1 to size do
  begin
    opcode := memory[ip];
    if (ngaValidatePackedOpcodes(opcode)) <> 0 then
      ngaProcessPackedOpcodes(opcode)
    else if ((opcode >= 0) and (opcode < NUM_OPS)) = true then
      ngaProcessOpcode(opcode)
    else
    begin
      writeln('Invalid instruction loaded!' + #13);
      writeln('at offset %d, opcode %d.', ip, opcode);
      exit();
    end;
  end;
  // Screen dump addresses for testing
  for i := 1 to ap do
    writeln(' %d', data[i]);
  writeln(#13);
end.

