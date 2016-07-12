/*
naje.c - nga assembler
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_NAMES 1024
#define STRING_LEN 1024


char names[MAX_NAMES][STRING_LEN];
int pointers[MAX_NAMES];
int np;

int memory[32768];
int ip;

void prepare()
{
  np = 0;
  ip = 0;
}


int lookup_definition(char *name)
{
  int slice = -1;
  int n = np;
  while (n > 0)
  {
  n--;
  if (strcmp(names[n], name) == 0)
    slice = pointers[n];
  }
  return slice;
}


void add_definition(char *name, int slice)
{
  if (lookup_definition(name) == -1)
  {
  strcpy(names[np], name);
  pointers[np] = slice;
  np++;
  }
  else
  {
  printf("Fatal error: %s already defined\n", name);
  exit(0);
  }
}


void comma(int value)
{
  memory[ip] = value;
  ip = ip + 1;
}


int compile(char *source)
{
  char *token;
  char *rest;
  char *ptr = source;
  char prefix[3];
  prefix[0] = 0;
  prefix[1] = 0;
  prefix[2] = 0;

  token = strtok_r(ptr, " ,", &rest);
  ptr = rest;
  prefix[0] = (char)token[0];
  prefix[1] = (char)token[1];
  if (strcmp(prefix, "no") == 0)
  {
    printf("nop");
    comma(0);
  }
  if (strcmp(prefix, "li") == 0)
  {
    printf("\nopcode 1");
    token = strtok_r(ptr, " ,", &rest);
    printf(" <%s>\n", token);
    comma(1);
    comma(atoi(token));
  }
  if (strcmp(prefix, "du") == 0)
  {
    comma(2);
  }
  if (strcmp(prefix, "dr") == 0)
  {
    comma(3);
  }
  if (strcmp(prefix, "sw") == 0)
  {
    comma(4);
  }
  if (strcmp(prefix, "pu") == 0)
  {
    comma(5);
  }
  if (strcmp(prefix, "po") == 0)
  {
    comma(6);
  }
  if (strcmp(prefix, "ju") == 0)
  {
    comma(7);
  }
  if (strcmp(prefix, "ca") == 0)
  {
    comma(8);
  }
  if (strcmp(prefix, "cj") == 0)
  {
    comma(9);
  }
  if (strcmp(prefix, "re") == 0)
  {
    comma(10);
  }
  if (strcmp(prefix, "eq") == 0)
  {
    comma(11);
  }
  if (strcmp(prefix, "ne") == 0)
  {
    comma(12);
  }
  if (strcmp(prefix, "lt") == 0)
  {
    comma(13);
  }
  if (strcmp(prefix, "gt") == 0)
  {
    comma(14);
  }
  if (strcmp(prefix, "fe") == 0)
  {
    comma(15);
  }
  if (strcmp(prefix, "st") == 0)
  {
    comma(16);
  }
  if (strcmp(prefix, "ad") == 0)
  {
    comma(17);
  }
  if (strcmp(prefix, "su") == 0)
  {
    comma(18);
  }
  if (strcmp(prefix, "mu") == 0)
  {
    comma(19);
  }
  if (strcmp(prefix, "di") == 0)
  {
    comma(20);
  }
  if (strcmp(prefix, "an") == 0)
  {
    comma(21);
  }
  if (strcmp(prefix, "or") == 0)
  {
    comma(22);
  }
  if (strcmp(prefix, "xo") == 0)
  {
    comma(23);
  }
  if (strcmp(prefix, "sh") == 0)
  {
    comma(24);
  }
  if (strcmp(prefix, "zr") == 0)
  {
    comma(25);
  }
  if (strcmp(prefix, "en") == 0)
  {
    comma(26);
  }
  return 0;
}


int main()
{
  prepare();
  char test[] = " lit  100";
  compile(test);

  char test2[] = "lit 22";
  compile(test2);

  char test3[] = "add";
  compile(test3);

  printf("\n");
  for (int i = 0; i < ip; i++)
    printf("%ld ", memory[i]);
  printf("\n");
  return 0;
}
