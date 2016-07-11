# Forth

This is the start of a Forth dialect for Nga. It's intended to be pretty
small and fairly traditional (within the bounds Nga sets), but will still
draw some design influences from Retro.

The code bits are written in Nga assembly and should be run through Nabk and
Naje to get an image file.

Doing this in Naje is less elegant than having a metacompiler, but allows for
greater overall flexibility since I can do forward references without vector
related hacks.

## Legal Stuff

This code derives from Retro. As such, it is copyrighted by the following:

    Copyright (c) 2008 - 2016, Charles Childers
    Copyright (c) 2009 - 2010, Luke Parrish
    Copyright (c) 2010,        Marc Simpson
    Copyright (c) 2010,        Jay Skeer
    Copyright (c) 2012,        Michal J Wallace

Use is subject to the terms of the ISC License.

## The Model

This is a *subroutine threaded forth*. E.g.,

    : test 1 2 + ;

Will compile into machine code:

    :test
      lit 1
      lit 2
      lit &add
      call
      ret

This isn't as compact as other models, but is very trivial to implement and
use.

Currently this does not do any optimizations. Some things to try later:

* inline primitives
* pack multiple instructions per cell

## Code

````
.packed
.output forth.nga
````

## Primitives

These wrap the individual instructions into functions that can be called. I
keep this in the same order as the instruction opcodes and have a brief note
for each one that is treated as a special case (ones that modify the IP).

````
:nop
  nop
  ret

# lit does not get called as a function

:dup
  dup
  ret

:drop
  drop
  ret

:swap
  swap
  ret

# push does not get called as a function

# pop does not get called as a function

# jump does not get called as a function

# call does not get called as a function

# cjump does not get called as a function

# return does not get called as a function

:eq
  eq
  ret

:neq
  neq
  ret

:lt
  lt
  ret

:gt
  gt
  ret

:fetch
  fetch
  ret

:store
  store
  ret

:add
  add
  ret

:sub
  sub
  ret

:mul
  mul
  ret

:divmod
  divmod
  ret

:and
  and
  ret

:or
  or
  ret

:xor
  xor
  ret

:shift
  shift
  ret

# zret does not get called as a function

:end
  end
  ret
````

## Kernel Words

The next group of words are used to flesh the primitives into a more useful
set of functions that we can use to build an actual Forth dialect from.

### Stack Shufflers

Since the stack is one of the defining elements of Forth, I first define a few
functions for controlling it.

````
:over
  push
  dup
  pop
  swap
  ret
````

### Memory

````
:@+
  dup
  lit &1+
  call
  swap
  fetch
  ret

:!+
  dup
  lit &1+
  call
  push
  store
  pop
  ret
````

### Unsorted

````
:not
  lit -1
  xor
  ret

:/
  lit &divmod
  call
  swap
  drop
  ret

:mod
  lit &divmod
  call
  drop
  ret

:negate
  lit -1
  mul
  rer

:do
  lit &1-
  call
  push
  ret

:here
  lit &heap
  fetch
  ret

:(return)
  ret

:;;
  lit &(return)
  fetch
  lit &comma
  call
  ret

:;
  lit &;
  call
  lit 0
  lit &compiler
  store
  call
  ret

:1+
  lit 1
  add
  ret

:1-
  lit 1
  sub
  ret
````

## The Compiler

Compilation is controlled by a single global variable named **compile**. The
*class handlers* will check this to decide whether to lay down code or call
a function.

````
:compiler
  .data 0

:compiling?
  lit &compiler
  fetch
  ret
````


````
:heap
  .data 0

:comma
  lit &heap
  fetch
  dup
  lit 1
  add
  push
  store
  pop
  lit &heap
  store
  ret

:withClass
  lit 1
  sub
  push
  ret

:.word
  lit &compiler
  fetch
  lit 0
  neq
  lit &.word<1>
  cjump
  lit &comma
  call
  ret
:.word<1>
  lit &withClass
  call
  ret

:.macro
  lit &withClass
  jump
  ret

:.data
  lit &compiler
  fetch
  zret
  drop
  lit 1
  lit &comma
  call
  lit &comma
  call
  ret

:main
  end
````
