# RETRO 12

## Syntax

**Prefixes**

Prefixes tell Retro how to deal with tokens:

| Prefix | Used For    | Example 1   | Example 2                          |
| ------ | ----------- | ----------- | ---------------------------------- |
| #      | Numbers     | `#10`       | `#-216`                            |
| $      | Characters  | `$a`        | `$b`                               |
| '      | Strings     | `'Hello`    | `'String_tokens_can't_have_spaces` |
| &amp;  | Pointer     | `&amp;Heap` | `&amp;Dictionary`                  |
| (      | Comments    | `(n-)`      | `(Comments_can't_have_spaces)`     |
| :      | Definitions | `:name`     | `:cube dup dup * * ;`              |

Word names may not start with a prefix character.

**Defining Words**

    :name (stack-comment)  ...code... ;

**Variables**

With a value of zero:

    'name var

With a provided value:

    #10 'Base var<n>

## The Words

| Word            | Stack     | Notes                                             |
| --------------- | --------- | ------------------------------------------------- |
| &#42;           | nn-n      | Multiply two numbers                              |
| &#42;/          | nnn-n     | (n1 * n2) / n3                                    |
| +               | nn-n      | Add two numbers                                   |
| ,               | n-        | Compile a value into memory at **here**           |
| -               | nn-n      | Subtract two numbers                              |
| ---reveal---    |           | Switch to public portion of lexical scope         |
| -eq?            | nn-f      | Compare two values for inequality                 |
| -if             | fp-?      | Execute *p* if flag *f* is false (0)              |
| /               | nq-d      | Divide two numbers                                |
| /mod            | nn-mq     | Divide two numbers, return quotient and remainder |
| 0;              | n-n OR n- | Exit word (and **drop**) if TOS is zero           |
| ;               | -         | End compilation and compile a *return* instruction|
| ?dup            | n-nn||n-n | Duplicate top item if not equal to zero           |
| Compiler        | -p        | Variable; holds compiler state                    |
| Dictionary      | -p        | Variable; points to most recent header            |
| EOM             | -p        | Returns the last address in memory                |
| FALSE           | -n        | Constant for fals flag (0)                        |
| Heap            | -p        | Variable; points to next free memory address      |
| STRINGS         | -p        | Return the start of the temporary string table    |
| ScopeList       |           | Variable, holds state for lexical scope           |
| TRUE            | -n        | Constant for true flag (-1)                       |
| &#91;           | -         | Begin a quotation                                 |
| &#92;           | -         | End a quotation                                   |
| again           | a-        | End an unconditional loop                         |
| allot           | n-        | Allocate the specified number of cells            |
| and             | nn-n      | Perform bitwise AND operation                     |
| bi              | xqq-      | Apply q1 and q2 to copies of x                    |
| bi&#42;         | xyqq-     | Apply q1 to x and q2 to y                         |
| bi@             | xyq-      | Apply q1 to x then apply q1 to y                  |
| buffer:add      | c-        | Store a value to the buffer                       |
| buffer:empty    | -         | Remove all values from the buffer                 |
| buffer:end      | -a        | Return address of buffer end                      |
| buffer:get      | -c        | Pop a value from the buffer                       |
| buffer:set      | a-        | Set the active buffer                             |
| buffer:size     | -n        | Return the size of the buffer                     |
| buffer:start    | -a        | Return address of buffer start                    |
| call            | p-        | Call a function (via pointer)                     |
| case            |           |                                                   |
| choose          | fpp-?     | Execute *p1* if *f* is -1, or *p2* if *f* is 0    |
| chr:CR          | -c        | Constant, for ASCII CR (13)                       |
| chr:ESC         | -c        | Constant, for ASCII ESC (27)                      |
| chr:LF          | -c        | Constant, for ASCII LF (10)                       |
| chr:SPACE       | -c        | Constant, for ASCII SPACE (32)                    |
| chr:TAB         | -c        | Constant, for ASCII TAB (9)                       |
| chr:digit?      | c-f       | True if character is numeral, false otherwise     |
| chr:letter?     | c-f       | True if character is letter, false otherwise      |
| chr:lowercase?  | c-f       | True if character is lowercase, false otherwise   |
| chr:to-lower    | c-c       | Convert character to lowercase                    |
| chr:to-string   | c-s       | Return a string representation of a character     |
| chr:to-upper    | c-c       | Convert character to uppercase                    |
| chr:toggle-case | c-c       | Switch the case of a character                    |
| chr:uppercase?  | c-f       | True if character is uppercase, false otherwise   |
| chr:visible?    | c-f       | True if character is printable, false otherwise   |
| chr:whitespace? | c-f       | True if character is whitespace, false otherwise  |
| class:data      | p-        | Class handler for data                            |
| class:macro     | p-        | Class handler for immediate functions             |
| class:primitive | p-        | Class handler for Nga primitives                  |
| class:word      | p-        | Class handler for standard functions              |
| compile:call    | p-        | Compile a CALL instruction                        |
| compile:jump    | p-        | Compile a JUMP instruction                        |
| compile:lit     | p-        | Compile a LIT instruction                         |
| compile:ret     | -         | Compile a RET instruction                         |
| compiling?      | -f        | True if **Compiler** is on or false otherwise     |
| cons            | nn-p      | Return a pointer to a cons cell                   |
| const           | ns-       | Create a constant                                 |
| copy            | aan-      | Copy (n) cells from source (a1) to dest (a2)      |
| curry           | vp-p      |                                                   |
| d:add-header    | saa-      | Add an item to the dictionary                     |
| d:add-name      | s-        | Add a new name pointing to the next free address  |
| d:class         | p-p       | Given a DT, return the address of the class field |
| d:link          | p-p       | Given a DT, return the address of the link field  |
| d:lookup        | s-p       | Given a string, return the DT (or 0 if undefined) |
| d:name          | p-p       | Given a DT, return the address of the name field  |
| d:xt            | p-p       | Given a DT, return the address of the xt field    |
| data            | -         | Change most recent word to **clas:data**          |
| depth           | -n        | Return number of items on the stack               |
| dip             | nq-n      | Equivilent to `push call pop`                     |
| drop            | nx-n      | Discard the top item on the stack                 |
| drop-pair       | nn-       | Drop top two items on stack                       |
| dup             | n-nn      | Duplicate the top item on the stack               |
| dup-pair        | xy-xyxy   | Duplicate top two items on stack                  |
| eq?             | nn-f      | Compare two values for equality                   |
| err:notfound    | -         | Handler for token not found errors                |
| fetch           | p-n       | Fetch a value stored at the pointer               |
| fetch-next      | a-an      | Fetch a value and return next address             |
| gt?             | nn-f      | Compare two values for greater than               |
| if              | fp-?      | Execute *p* if flag *f* is true (-1)              |
| immediate       | -         | Change most recent word to **class:macro**        |
| interpret       | s-?       | Evaluate a token                                  |
| later           | -         | Defer execution of remainder until later          |
| lt?             | nn-f      | Compare two values for less than                  |
| mark            | -         | Save information on the current Dictionary, Heap  |
| mod             | nq-r      | Divide two numbers, return remainder              |
| n:-zero?        | n-f       | True if number is not zero or false otherwise     |
| n:abs           | n-n       | Return the absolute value of a number             |
| n:between?      | nul-      | True if number is within limits, false otherwise  |
| n:dec           | n-n       | Decrement a value                                 |
| n:inc           | n-n       | Increment a value                                 |
| n:limit         | nlu-n     | Return a value, such that n is within the limits  |
| n:max           | nn-n      | Return the greater of two numbers                 |
| n:min           | nn-n      | Return the lesser of two numbers                  |
| n:negate        | n-n       | Negate a number                                   |
| n:negative?     | n-f       | True if number is negative or false otherwise     |
| n:positive?     | n-f       | True if number is positive or false otherwise     |
| n:pow           | bp-n      | Raise number to specified power                   |
| n:sqrt          | n-n       | Return the square root of a number                |
| n:square        | n-n       | Return the square of a number                     |
| n:to-string     | n-s       | Return a string representation of a number        |
| n:zero?         | n-f       | True if number is zero or false otherwise         |
| nip             | xy-y      | Remove NOS from stack                             |
| not             | n-n       | Same as -1 xor; invert TOS and subtract 1         |
| or              | nn-n      | Perform bitwise OR operation                      |
| over            | xy-xyx    | Put a copy of NOS on top of stack                 |
| pop             | -n        | Move value from address stack to data stack       |
| prefix:#        | s-        | # prefix for numbers                              |
| prefix:$        | s-        | $ prefix for ASCII characters                     |
| prefix:&        | s-        | & prefix for pointers                             |
| prefix:'        | s-        | Prefix for string tokens                          |
| prefix:(        | s-        | Parse token as a comment                          |
| prefix::        | s-        | : prefix for definitions                          |
| prefix:&#96;    | s-        | Compile a VM bytecode                             |
| push            | n-        | Move value from data stack to address stack       |
| putc            | c-        | Send a character to the output                    |
| putn            | n-        | Send a number to the output                       |
| puts            | s-        | Send a string to the output                       |
| reclass         | p-        | Change the class of the most recent word          |
| repeat          | -a        | Start an unconditional loop                       |
| reset           | ...-      | Remove all values from stack                      |
| rot             | abc-bca   | Rotate top three values on stack                  |
| s,              | s-        | Compile a string into memory at **here**          |
| shift           | nn-n      | Perform bitwise shift                             |
| sip             | nq-n      | Equivilent to `dup push call pop`                 |
| store           | np-       | Store a value into the address at pointer         |
| store-next      | na-a      | Store a value to address and return next address  |
| str:append      | ss-s      | Append the second string to the first             |
| str:chop        | s-s       | Remove last character from string                 |
| str:compare     | ss-f      | Compare two strings for equality                  |
| str:empty       | -s        | Return an empty string                            |
| str:has-chr?    | sc-f      | True if char is in string, false otherwise        |
| str:hash        | s-n       | Return the hash of a string                       |
| str:keep        | s-s       | Compile a string into the heap                    |
| str:length      | s-n       | Return length of string                           |
| str:prepend     | ss-s      | Prepend the second string to the first            |
| str:reverse     | s-s       | Reverse the order of characters in a string       |
| str:skip        | -         | Helper function, skips over stored strings        |
| str:temp        | s-s       | Copy string to temporary buffer                   |
| str:to-number   | s-n       | Convert a string to a number                      |
| str:trim        | s-s       | Remove leading and trailing whitespace            |
| str:trim-left   | s-s       | Remove leading whitespace from a string           |
| str:trim-right  | s-s       | Remove trailing whitespace from a string          |
| swap            | nx-xn     | Switch the top two items on the stack             |
| sweep           | -         | Restore saved Dictionary, Heap information        |
| times           | nq-       | Execute a quote the specified number of times     |
| tors            | -n        | Return copy of top item on address stack          |
| tri             | xqqq-     | Apply q1, q2, q3 to copies of x                   |
| tri&#42;        | xyzqqq-   | Apply q1 to x, q2 to y, q3 to z                   |
| tri@            | xyzq-     | Apply q to x, then to y, then to z                |
| tuck            | xy-yxy    | Put a copy of TOS under NOS                       |
| until           | q-        | Execute quote until quote returns a flag of -1    |
| v:dec           | n-n       | Decrement a variable                              |
| v:dec-by        | na-       | Decrement a variable by a specified amount        |
| v:inc           | n-n       | Increment a variable                              |
| v:inc-by        | na-       | Increment a variable by a specified amount        |
| v:limit         | alu-      | Like **n:limit** for stored values                |
| var             | s-        | Create a variable with a value of 0               |
| var&lt;n&gt;    | ns-       | Create a variable with a provided initial value   |
| while           | q-        | Execute quote until quote returns a flag of 0     |
| xor             | nn-n      | Perform bitwise XOR operation                     |
| {{              | -         | Start lexical scope, private words                |
| }}              |           | End lexical scope, hiding private words           |
