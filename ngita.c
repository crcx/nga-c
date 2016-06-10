#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <termios.h>
#define CELL         int32_t
CELL ngaLoadImage(char *imageFile);
void ngaPrepare();
void ngaStatsCheckMax();
void ngaProcessOpcode();
void ngaDisplayStats();
#define IMAGE_SIZE   262144
#define TOS  data[sp]
extern CELL ip, sp, rsp, memory[], data[];
void processOpcodes() {
  CELL opcode;
  ip = 0;
  while (ip < IMAGE_SIZE) {
    opcode = memory[ip];
    if (opcode >= 0 && opcode < 27)
      ngaProcessOpcode();
    else
      switch(opcode) {
        case 90: printf("%c", (char)data[sp]);
                 break;
        case 91: sp++;
                 TOS = getc(stdin);
                 ngaStatsCheckMax();
                 break;
      }
    ip++;
  }
}
int main(int argc, char **argv) {
  struct termios new_termios, old_termios;

  ngaPrepare();
  if (argc == 2)
      ngaLoadImage(argv[1]);
  else
      ngaLoadImage("ngaImage");

  tcgetattr(0, &old_termios);
  new_termios = old_termios;
  new_termios.c_iflag &= ~(BRKINT+ISTRIP+IXON+IXOFF);
  new_termios.c_iflag |= (IGNBRK+IGNPAR);
  new_termios.c_lflag &= ~(ICANON+ISIG+IEXTEN+ECHO);
  new_termios.c_cc[VMIN] = 1;
  new_termios.c_cc[VTIME] = 0;
  tcsetattr(0, TCSANOW, &new_termios);

  CELL i;

  processOpcodes();

  for (i = 1; i <= sp; i++)
    printf("%d ", data[i]);
  printf("\n");

  tcsetattr(0, TCSANOW, &old_termios);
  exit(0);

}
