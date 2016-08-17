/* nuance
 * copyright (c)2013 - 2016, charles childers
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
//#include <math.h>
#include <ctype.h>

int compile(char *source)
{
    char *token;
    char *state;
    char prefix;
    char reform[999];
    int scratch;
    int i;

    for (token = strtok_r(source, " ", &state); token != NULL; token = strtok_r(NULL, " ", &state))
    {
        prefix = (char)token[0];
        switch (prefix)
        {
            case '\'':
                if (token[strlen(token) - 1] == '\'')
                {
                    memset(reform, '\0', 999);
                    memcpy(reform, &token[1], strlen(token) - 2);
                    reform[strlen(token) - 2] = '\0';
                    printf("  .string %s\n", reform);
                }
                else
                {
                    memset(reform, '\0', 999);
                    memcpy(reform, &token[1], strlen(token) - 1);

                    i = 0;
                    while (i == 0)
                    {
                        strcat(reform, " ");
                        token = strtok_r(NULL, " ", &state);
                        if (token[strlen(token) - 1] == '\'' || token == NULL)
                        {
                            i = 1;
                            token[strlen(token) - 1] = '\0';
                            strcat(reform, token);
                        }
                        else
                            strcat(reform, token);
                    }
                    printf("  .string %s\n", reform);
                }
                break;
            case '"':
                if (token[strlen(token) - 1] == '"')
                {
                    memset(reform, '\0', 999);
                    memcpy(reform, &token[1], strlen(token) - 2);
                    reform[strlen(token) - 2] = '\0';
                }
                else
                {
                    memset(reform, '\0', 999);
                    memcpy(reform, &token[1], strlen(token) - 1);

                    i = 0;
                    while (i == 0)
                    {
                        strcat(reform, " ");
                        token = strtok_r(NULL, " ", &state);
                        if (token[strlen(token) - 1] == '"' || token == NULL)
                        {
                            i = 1;
                            token[strlen(token) - 1] = '\0';
                            strcat(reform, token);
                        }
                        else
                            strcat(reform, token);
                    }
                }
                break;
            case ':':
                printf("%s\n", token);
                break;
            case '#':
                memset(reform, '\0', 999);
                memcpy(reform, &token[1], strlen(token));
                scratch = (double) atof(reform);
                printf("  lit %s\n", reform);
                break;
            case '&':
                memset(reform, '\0', 999);
                memcpy(reform, &token[1], strlen(token));
                printf("  lit &%s\n", reform);
                break;
            case '$':
                scratch = (double) token[1];
                printf("  lit %d\n", scratch);
                break;
            case '`':
                memset(reform, '\0', 999);
                memcpy(reform, &token[1], strlen(token));
                scratch = (double) atof(reform);
                printf("  .data %d\n", scratch);
                break;
            default:
                if (strcmp(token, ";") == 0)
                    printf("  ret\n");
                else
                    printf("  lit &%s\n  call\n", token);
                break;
        }
    }
    return 0;
}


/*  Load and run bootstrap  */

void read_line(FILE *file, char *line_buffer)
{
    if (file == NULL)
    {
        printf("Error: file pointer is null.");
        exit(1);
    }

    if (line_buffer == NULL)
    {
        printf("Error allocating memory for line buffer.");
        exit(1);
    }

    char ch = getc(file);
    int count = 0;

    while ((ch != '\n') && (ch != EOF))
    {
        line_buffer[count] = ch;
        count++;
        ch = getc(file);
    }

    line_buffer[count] = '\0';
}


void parse_bootstrap(char *fname)
{
    char source[64000];

    FILE *fp;

    fp = fopen(fname, "r");
    if (fp == NULL)
        return;

    while (!feof(fp))
    {
        read_line(fp, source);
        compile(source);
    }

    fclose(fp);
}


int main(int argc, char **argv)
{
    parse_bootstrap("stdlib.p");
    return 0;
}
