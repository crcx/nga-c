// ********************************************************
//  Copyright (c) 2016 Rob Judd <judd@ob-wan.com>
//  Based on C version by Charles Childers et al
//  ISC License - see included file LICENSE
// ********************************************************

type
  Cell = Longint;
 
{$define STACK_DEPTH  := 32}
{$define ADDRESSES    := 128}
{$define IMAGE_SIZE   := 524288}
{$define NUM_OPS      := 27}
{$define TOS          := data[sp]}
{$define NOS          := data[sp-1]}
{$define TOA          := address[ap]}

function ngaLoadImage(imageFile : PChar) : Cell; external;
procedure ngaPrepare(); external;
procedure ngaProcessOpcode(opcode : Cell); external;
procedure ngaProcessPackedOpcodes(opcode : Integer); external;
function ngaValidatePackedOpcodes(opcode : Cell) : Integer; external;

