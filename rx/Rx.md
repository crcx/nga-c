# Retro Experimental Core

Let's build a Forth for Nga.

The core instruction set is:

    0  nop        7  jump      14  gt        21  and
    1  lit <v>    8  call      15  fetch     22  or
    2  dup        9  cjump     16  store     23  xor
    3  drop      10  return    17  add       24  shift
    4  swap      11  eq        18  sub       25  zret
    5  push      12  neq       19  mul       26  end
    6  pop       13  lt        20  divmod

Start by naming them. (Not all of these will be exposed as words in the final dictionary)

````
:_nop     `0 ;
:_lit     `1 ;
:_dup     `2 ;
:_drop    `3 ;
:_swap    `4 ;
:_push    `5 ;
:_pop     `6 ;
:_jump    `7 ;
:_call    `8 ;
:_cjump   `9 ;
:_ret     `10 ;
:_eq      `11 ;
:_neq     `12 ;
:_lt      `13 ;
:_gt      `14 ;
:_fetch   `15 ;
:_store   `16 ;
:_add     `17 ;
:_sub     `18 ;
:_mul     `19 ;
:_divmod  `20 ;
:_and     `21 ;
:_or      `22 ;
:_xor     `23 ;
:_shift   `24 ;
:_zret    `25 ;
:_end     `26 ;
````

Assign friendlier, more traditional names to several of the primitives. The naming is derived from Retro and Parable.

````
:+     "nn-n"   _add ;
:-     "nn-n"   _sub ;
:*     "nn-n"   _mul ;
:/mod  "nn-mq"  _divmod ;
:eq?   "nn-f"   _eq ;
:-eq?  "nn-f"   _neq ;
:lt?   "nn-f"   _lt ;
:gt?   "nn-f"   _gt ;
:and   "nn-n"   _and ;
:or    "nn-n"   _or ;
:xor   "nn-n"   _xor ;
:shift "nn-n"   _shift ;
:bye   "-"      _end ;
:@     "a-n"    _fetch ;
:!     "na-"    _store ;
:dup   "n-nn"   _dup ;
:drop  "nx-n"   _drop ;
:swap  "nx-xn"  _swap ;
````


````
:main
  bye
````
