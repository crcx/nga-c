This directory contains the source tree for the basic tests of the Nga instruction set.

You will need:

- nga, built for standalone use
- naje
- make

To use:

    make i
    make r

Compare RESULTS with EXPECTED, or the table below.

| Opcode | Expected                 |
| ------ | ------------------------ |
| 0      |                          |
| 1      | 1 -1 99 -99              |
| 2      | 100 100 200 200          |
| 3      | 100 200                  |
| 4      | 200 300 100              |
| 5      | 100 300 200              |
| 6      | 100 300 200              |
| 7      | 0 0 0 0                  |
| 8      | 0                        |
| 9      | 100                      |
| 10     | 0                        |
| 11     | 0 -1                     |
| 12     | -1 0                     |
| 13     | -1 0 0                   |
| 14     | 0 0 -1                   |
| 15     | 97 98 99                 |
| 16     | 97 98 48                 |
| 17     | 300 1                    |
| 18     | -100 199                 |
| 19     | 20000 -9900              |
| 20     | 100 0 1 -1 89 2          |
| 21     | -1 0 0                   |
| 22     | -1 -1 0                  |
| 23     | 0 -1 0                   |
| 24     | 3640 455                 |
| 25     | 2                        |
| 26     |                          |

