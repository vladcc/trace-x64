#include "err.h"

static const char * err_prog_name = NULL;

static void real_err_print(const char * msg, va_list args)
{
	fflush(stdout);
	fprintf(stderr, "%s: error: ", err_prog_name);
	vfprintf(stderr, msg, args);
	fprintf(stderr, "%s", "\n");
}
void err_set_prog_name(const char * name)
{
	err_prog_name = name;
}
void err_print(const char * msg, ...)
{
	va_list args;
	va_start(args, msg);
	real_err_print(msg, args);
	va_end(args);
}
void err_quit(const char * msg, ...)
{
	va_list args;
	va_start(args, msg);
	real_err_print(msg, args);
	va_end(args);
	exit(EXIT_FAILURE);
}
void err_quit_syscall(const char * msg)
{
	err_quit("%s failed: %s", msg, strerror(errno));
}
void err_quit_libcall(const char * msg)
{
	err_quit("%s failed", msg);
}
FILE * xfopen(const char * fname, const char * mode)
{
	FILE * fp = fopen(fname, mode);
	if (!fp)
		err_quit("'%s': %s", fname, strerror(errno));
	return fp;
}
