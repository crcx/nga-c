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

void prepare()
{
  np = 0;
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



int compile(char *source)
{
  char *token;
  char *rest;
  char *ptr = source;
  char prefix[3];
  char reform[STRING_LEN];
  double scratch;
  int o = 0;
  int i;
  prefix[0] = 0;
  prefix[1] = 0;
  prefix[2] = 0;

  token = strtok_r(ptr, " ,", &rest);
  printf("%s\n", token); // print the token returned.
  ptr = rest;
  prefix[0] = (char)token[0];
  prefix[1] = (char)token[1];
  printf("%s\n", prefix);
  if (strcmp(prefix, "no") == 0)
  {
    printf("nop");
  }
  if (strcmp(prefix, "li") == 0)
  {
    printf("\nopcode 1");
    token = strtok_r(ptr, " ,", &rest);
    printf(" <%s>\n", token);
  }
  if (strcmp(prefix, "du") == 0)
  {
  }
  if (strcmp(prefix, "dr") == 0)
  {
  }
  if (strcmp(prefix, "sw") == 0)
  {
  }
  if (strcmp(prefix, "pu") == 0)
  {
  }
  if (strcmp(prefix, "po") == 0)
  {
  }
  if (strcmp(prefix, "ju") == 0)
  {
  }
  if (strcmp(prefix, "ca") == 0)
  {
  }
  if (strcmp(prefix, "cj") == 0)
  {
  }
  if (strcmp(prefix, "re") == 0)
  {
  }
  if (strcmp(prefix, "eq") == 0)
  {
  }
  if (strcmp(prefix, "ne") == 0)
  {
  }
  if (strcmp(prefix, "lt") == 0)
  {
  }
  if (strcmp(prefix, "gt") == 0)
  {
  }
  if (strcmp(prefix, "fe") == 0)
  {
  }
  if (strcmp(prefix, "st") == 0)
  {
  }
  if (strcmp(prefix, "ad") == 0)
  {
  }
  if (strcmp(prefix, "su") == 0)
  {
  }
  if (strcmp(prefix, "mu") == 0)
  {
  }
  if (strcmp(prefix, "di") == 0)
  {
  }
  if (strcmp(prefix, "an") == 0)
  {
  }
  if (strcmp(prefix, "or") == 0)
  {
  }
  if (strcmp(prefix, "xo") == 0)
  {
  }
  if (strcmp(prefix, "sh") == 0)
  {
  }
  if (strcmp(prefix, "zr") == 0)
  {
  }
  if (strcmp(prefix, "en") == 0)
  {
  }
  return 0;
}


int main()
{
  prepare();
  char test[] = " lit  100";
  compile(test);
  return 0;
}
