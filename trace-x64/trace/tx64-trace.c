#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#include <sys/personality.h>
#include <sys/ptrace.h>
#include <sys/wait.h>
#include <sys/user.h>
#include <sys/uio.h>
#include <signal.h>
#include <unistd.h>

#include <string>
#include <vector>

#include "tx64.h"
#include "err/err.h"
#include "parse-opts/parse_opts.h"

// <prog-info>
static const char prog_name[] = "tx64-trace";
static const char prog_version[] = "1.0";

static void print_usage_quit(void)
{
	fprintf(stderr, "Use: %s [run-option] <executable-or-pid>\n", prog_name);
	fprintf(stderr, "Try: %s --help\n", prog_name);
	exit(EXIT_FAILURE);
}
static void print_help_msg(void);
static void print_help_quit(opts_table * tbl)
{
	print_help_msg();
	opts_print_help(tbl);
	exit(EXIT_SUCCESS);
}
static void print_version_quit(void)
{	
	printf("%s %s\n", prog_name, prog_version);
	exit(EXIT_SUCCESS);
}
// </prog-info>

// <command-line-options>
typedef struct prog_options {
	std::vector<char *> exv;
	const char * prog;
	const char ** argv;
	size_t max_instr;
	size_t seconds;
	pid_t pid;
	opts_err_code err_code;
	bool no_aslr;
	bool ignore_opt;
	bool has_pid;
} prog_options;

static inline prog_options * prog_opts_get(void)
{
	static prog_options opts;
	return &opts;
}
#if 0
static void dbg_print_execv(void)
{
	auto pvect = &(prog_opts_get()->exv);
	char ** str = pvect->data();
	auto end = pvect->size();
	for (typeof(end) i = 0; i < end; ++i)
		printf("%s\n", str[i] ? str[i] : "NULL"); 
}
#endif
static void save_pid(const char * str, prog_options * opts)
{
	opts->has_pid = true;
	if (sscanf(str, "%d", &opts->pid) != 1)
		err_quit("'%s' not a valid pid", str);
}
static void save_execv(const char * arg, prog_options * opts)
{
	opts->exv.push_back((char *)arg);
}
static void save_no_aslr(const char * arg, prog_options * opts)
{
	opts->no_aslr = true;
}
static void save_prog(const char * prog, prog_options * opts)
{
	opts->prog = prog;
	opts->ignore_opt = true;
	
	const char ** argv = opts->argv;
	while (*argv && *argv != prog)
		++argv;
	
	for (; *argv; ++argv)
		save_execv(*argv, opts);
		
	save_execv(NULL, opts);
}
static void save_max_instr(const char * num, prog_options * opts)
{
	if (sscanf(num, "%zu", &opts->max_instr) != 1)
		err_quit("'%s' not a valid number", num);
}
static void save_seconds(const char * num, prog_options * opts)
{
	if (sscanf(num, "%zu", &opts->seconds) != 1)
		err_quit("'%s' not a valid number", num);
}
static void opt_error(opts_err_code err_code, const char * err_opt)
{	
	switch (err_code)
	{
		case OPTS_UNKOWN_OPT_ERR:
			err_quit("option '%s' unknown", err_opt);
			break;
		case OPTS_ARG_REQ_ERR:
			err_quit("option '%s' requires an argument", err_opt);
			break;
		case OPTS_NO_ARG_REQ_ERR:
			err_quit("option '%s' does not take arguments", err_opt);
			break;
		default:
			break;
	}
}
typedef enum {
	OPT_UNBOUND,
	OPT_ERROR,
	OPT_EXEC,
	OPT_NO_ASLR,
	OPT_PID,
	OPT_MAX_INST,
	OPT_SECONDS,
	OPT_HELP,
	OPT_VERSION
} cli_opt;
static void opt_action(cli_opt what, const char * arg, void * ctx)
{
	prog_options * opts = prog_opts_get();
	
	if (!opts->ignore_opt)
	{
		switch (what)
		{
			case OPT_UNBOUND:
				err_quit("unbound argument: '%s'", arg);
				break;
			case OPT_ERROR:
				opt_error(opts->err_code, arg);
				break;
			case OPT_EXEC:
				save_prog(arg, (prog_options *)ctx);
				break;
			case OPT_NO_ASLR:
				save_no_aslr(arg, (prog_options *)ctx);
				break;
			case OPT_PID:
				save_pid(arg, (prog_options *)ctx);
				break;
			case OPT_MAX_INST:
				save_max_instr(arg, (prog_options *)ctx);
				break;
			case OPT_SECONDS:
				save_seconds(arg, (prog_options *)ctx);
				break;
			case OPT_HELP:
				print_help_quit((opts_table *)ctx);
				break;
			case OPT_VERSION:
				print_version_quit();
				break;
			default:
				err_quit("undefined call to opt_action()");
				break;
		}
	}
}

#include "opts_definitions.ic"
static void print_help_msg(void)
{
printf("%s -- instruction execution tracer for x64\n", prog_name);
puts("");
puts("Attaches to a process and single-steps the instructions being executed. "
"Outputs");
puts("three files: a binary instruction blob and two copies of the "
"/proc/<pid>/maps");
puts("file - one taken at the attach time and one at detach. Any of the maps "
"files");
puts("can be given to sym-map.awk to produce a symbol map, which can then be "
"given to");
printf("tx64-print along with the instruction blob for disassembly. If both "
"-%c and -%c\n", max_inst_opt_short, seconds_opt_short);
puts("options are present, tracing stops when whichever happens first.");
puts("");
puts("Options:");
}
static void opts_process(int argc, char * argv[], void * ctx)
{
	if (argc < 2)
		print_usage_quit();

#include "opts_process.ic"
}
// </command-line-options>

// <signal-handlers>
volatile sig_atomic_t g_stop_flag = 0;

static void signal_handler(int signum)
{
	g_stop_flag = 1;
}
// </signal-handlers>

// <trace>
static pid_t trace_spawn(const char * prog, char * const args[], bool no_aslr)
{
	pid_t forked = fork();
	
	if (0 == forked)
	{
		if (no_aslr && (personality(ADDR_NO_RANDOMIZE) < 0))
			err_quit_syscall("personality(ADDR_NO_RANDOMIZE)");
		
		if (ptrace(PTRACE_TRACEME, 0, NULL, NULL) < 0)
			err_quit_syscall("ptrace(PTRACE_TRACEME)");
		
		if (execvp(prog, args) < 0)
			err_quit_syscall("execvp()");
	}
	else if (forked < 0)
		err_quit_syscall("fork()");
	
	return forked;
}
static void trace_attach(pid_t pid)
{
	if (ptrace(PTRACE_ATTACH, pid, NULL, NULL) < 0)
		err_quit_syscall("ptrace(PTRACE_ATTACH)");
}
static std::string get_proc_comm(const char * pid)
{
	std::string fname("/proc/");
	fname.append(pid).append("/comm");
	
	FILE * fp = xfopen(fname.c_str(), "r");
	
	std::string comm(32, ' ');
	if (fscanf(fp, "%31s", comm.data()) != 1)
		err_quit_libcall("scanf() failed in get_proc_comm()");
	fclose(fp);
	
	comm.resize(strlen(comm.c_str()));
	return comm;
}
static void copy_proc_maps(const char * nm, const char * pid, const char * ext)
{
	std::string in_maps("/proc/");
	in_maps.append(pid).append("/maps");
	
	std::string out_maps(nm);
	out_maps.append(".maps").append(ext);
	
	FILE * fp_in_maps = xfopen(in_maps.c_str(), "r");
	FILE * fp_out_maps = xfopen(out_maps.c_str(), "w");
	
	int ch = 0;
	while ((ch = fgetc(fp_in_maps)) != EOF)
		fputc(ch, fp_out_maps);
	
	fclose(fp_out_maps);
	fclose(fp_in_maps);
}
static void write_blob_header(FILE * fp_blob)
{
	std::string header(prog_name);
	header.append(" le 1u64 16b");
	
	byte bhdr[TX64_HDR_SZ];
	memset(bhdr, 0, sizeof(bhdr));
	
	memcpy(bhdr, header.c_str(), header.length());
	
	if (fwrite(bhdr, sizeof(bhdr), 1, fp_blob) != 1)
		err_quit_libcall("fwrite()");
}
static void set_timer(size_t secs)
{
	timer_t tmid = 0;
	struct sigevent sev;
	memset(&sev, 0, sizeof(sev));

	sev.sigev_notify = SIGEV_SIGNAL;
    sev.sigev_signo = SIGINT;
	if (timer_create(CLOCK_REALTIME, &sev, &tmid) != 0)
		err_quit_syscall("timer_create()");

	struct itimerspec its;
	memset(&its, 0, sizeof(its));
	its.it_value.tv_sec = secs;
	if (timer_settime(tmid, 0, &its, NULL) != 0)
		err_quit_syscall("timer_settime()");
}
static void trace_run(pid_t pid, size_t max_instr, size_t secs)
{
#define GET_MAPS(which) \
copy_proc_maps(base_name.c_str(), pid_str.c_str(), (which));

	int status;
	if (waitpid(pid, &status, 0) < 0)
		err_quit_syscall("waitpid()");
	
	std::string pid_str(std::to_string(pid));
	std::string base_name(get_proc_comm(pid_str.c_str()));
	base_name.append(".").append(pid_str).append(".").append(prog_name);
	
	GET_MAPS(".start");
	
	std::string out_blob_name(base_name);
	out_blob_name.append(".iblob");
	
	FILE * fp_out_blob = xfopen(out_blob_name.c_str(), "wb");
	write_blob_header(fp_out_blob);
	
	tx64_instr_info instr;
	memset(&instr, 0, sizeof(instr));
			
	struct user_regs_struct regs;
	struct iovec local;
	struct iovec remote;
	
	local.iov_base = &instr.itxt_mem;
	local.iov_len = TX64_ITXT_SZ;
	remote.iov_len = TX64_ITXT_SZ;
	
	if (ptrace(PTRACE_SETOPTIONS, pid, NULL, (void *)PTRACE_O_TRACEEXIT) < 0)
		err_quit_syscall("ptrace(PTRACE_SETOPTIONS)");
	
	if (secs)
		set_timer(secs);

	while (1)
	{
		if ((status >> 8) == (SIGTRAP | (PTRACE_EVENT_EXIT << 8)))
			GET_MAPS(".end");
			
		if (WIFEXITED(status) || WIFSIGNALED(status))
			break;
		
		if (ptrace(PTRACE_GETREGS, pid, NULL, &regs) < 0)
			err_quit_syscall("ptrace(PTRACE_GETREGS)");
		instr.ip = regs.rip;
		
		remote.iov_base = (void *)instr.ip;
		if (process_vm_readv(pid, &local, 1, &remote, 1, 0) != TX64_ITXT_SZ)
			err_quit_syscall("process_vm_readv()");
		
		if (fwrite(&instr, sizeof(instr), 1, fp_out_blob) != 1)
			err_quit_libcall("fwrite()");
		
		if (g_stop_flag || (max_instr && (0 == --max_instr)))
		{
			copy_proc_maps(base_name.c_str(), pid_str.c_str(), ".end");
			
			if (ptrace(PTRACE_DETACH, pid, NULL, NULL) < 0)
				err_quit_syscall("ptrace(PTRACE_DETACH)");
			break;
		}
			
		if (ptrace(PTRACE_SINGLESTEP, pid, NULL, NULL) < 0)
			err_quit_syscall("ptrace(PTRACE_SINGLESTEP)");
			
		if (waitpid(pid, &status, 0) < 0)
			err_quit_syscall("waitpid()");
	}
	
	fflush(fp_out_blob);
	fclose(fp_out_blob);
	
#undef GET_MAPS
}
// </trace>

int main(int argc, char * argv[])
{
	err_set_prog_name(prog_name);
	signal(SIGINT, signal_handler);

	prog_options * opts = prog_opts_get();
	
	opts->argv = (const char **)argv;
	opts_process(argc, argv, opts);
	
	if (opts->prog)
		opts->pid = trace_spawn(opts->prog, opts->exv.data(), opts->no_aslr);
	else if (opts->has_pid)
		trace_attach(opts->pid);
	else
		err_quit("no pid nor executable given");
	
	trace_run(opts->pid, opts->max_instr, opts->seconds);

	return 0;
}
