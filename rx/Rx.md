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


````
:+ _add ;
:- _sub ;
:* _mul ;
:/mod _divmod ;
:eq? _eq ;
:-eq? _neq ;
:lt? _lt ;
:gt? _gt ;
:and _and ;
:or _or ;
:xor _xor ;
:shift _shift ;
:bye _end ;
:@ _fetch ;
:! _store ;
:dup _dup ;
:drop _drop ;
:swap _swap ;
````
