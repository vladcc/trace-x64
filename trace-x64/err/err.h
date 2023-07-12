#ifndef ERR_H
#define ERR_H

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

void err_set_prog_name(const char * name);
void err_print(const char * msg, ...);
void err_quit(const char * msg, ...);
void err_quit_syscall(const char * msg);
void err_quit_libcall(const char * msg);
FILE * xfopen(const char * fname, const char * mode);

#endif
