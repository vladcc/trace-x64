#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>

#include <signal.h>

#include <string>
#include <vector>
#include <algorithm>

#include "capstone/capstone.h"

#include "tx64.h"
#include "err/err.h"
#include "parse-opts/parse_opts.h"

// <prog-info>
static const char prog_name[] = "tx64-print";
static const char prog_version[] = "1.0";

static void print_usage_quit(void);
static void print_help_msg(void)
{
printf("%s -- prints disassembly for instruction blobs "
"provided by tx64-trace\n", prog_name);
puts("");
puts("Options:");
}
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
	const char * sym_file;
	const char * blob_file;
} prog_options;
static inline prog_options * prog_opts_get(void)
{
	static prog_options opts;
	return &opts;
}
static void arg_unbound(const char * arg, void * ctx)
{
	err_quit("unbound argument: '%s'", arg);
	return;
}
static void save_sym(const char * arg, void * ctx)
{
	prog_options * opts = (prog_options *)ctx;
	opts->sym_file = arg;
}
static void save_blob(const char * arg, void * ctx)
{
	prog_options * opts = (prog_options *)ctx;
	opts->blob_file = arg;
}

#include "opts_definitions.ic"

static void print_usage_quit(void)
{
	fprintf(stderr, "Use: %s [-%c <sym-file>] -%c <iblob>\n",
		prog_name, sym_opt_short, blob_opt_short);
	fprintf(stderr, "Try: %s --help\n", prog_name);
	exit(EXIT_FAILURE);
}

static void opts_process(int argc, char * argv[], void * ctx)
{
	if (argc < 2)
		print_usage_quit();
		
	#include "opts_process.ic"
	
	prog_options * opts = (prog_options *)ctx;
	if (!opts->blob_file)
		err_quit("iblob file required");
}
// </command-line-options>

// <signal-handlers>
volatile sig_atomic_t g_stop_flag = 0;

static void signal_handler(int signum)
{
	g_stop_flag = 1;
}
// </signal-handlers>

// <symbols>
static inline const char * str_no_name(void)
{
	return "???";
}
typedef struct symbol {
	uint64_t addr;
	std::string name;
	symbol(uint64_t a, const char * n) : addr(a), name(n) {}
} symbol;
static inline std::vector<symbol> * sym_get_vect(void)
{
	static std::vector<symbol> vect;
	return &vect;
}
static inline void sym_push(uint64_t addr, const char * name)
{
	sym_get_vect()->emplace_back(addr, name);
}
struct sym_cmp
{
	bool operator() (const symbol& a, const symbol& b)
	{
		return a.addr < b.addr;
	}
} cmp_sym;
static inline  void sym_sort(void)
{
	auto pvect = sym_get_vect();
	std::sort(pvect->begin(), pvect->end(), cmp_sym);
}
static inline const symbol * sym_get(uint64_t addr)
{
	static symbol base(0, str_no_name());
	static symbol cmp(0, "");

	const symbol * ret = &base;

	auto pvect = sym_get_vect();
	if (pvect->size())
	{
		cmp.addr = addr;
		auto ub = std::upper_bound(pvect->begin(), pvect->end(), cmp, cmp_sym);
		if (ub != pvect->begin())
			ret = &(*(--ub));
	}

	return ret;
}
#if 0
static void sym_dbg_print(void)
{
	auto pvect = sym_get_vect();
	auto data = pvect->data();
	
	for (size_t i = 0, end = pvect->size(); i < end; ++i)
	{
		auto sym = data + i;
		printf("%lX %s\n", sym->addr, sym->name.c_str());
	}
}
#endif
static void sym_read(const char * sym_file)
{
#define MAX_LINE 4095
#define SSCANF_MAX_STR "2096"
	
	if (!sym_file)
		return;
	
	static const char sym_hdr[] = "Base;Offset;Name;Binary";
		
	FILE * fp_sym = xfopen(sym_file, "r");
		
	std::string line(MAX_LINE, ' ');
	std::string sym_name(MAX_LINE, ' ');
	
	uint64_t base = 0;
	uint64_t addr = 0;
	
	char * buff = line.data();
	char * sym = sym_name.data();
	
	unsigned int line_no = 1;
	
	if (fgets(buff, MAX_LINE, fp_sym) != NULL)
	{
		if (sscanf(buff, "%" SSCANF_MAX_STR "s", sym) != 1)
		{
			err_quit("sscanf() failed to symbol file read header at line %u",
				line_no);
		}
			
		if (strcmp(sym_hdr, sym) != 0)
			err_quit("'%s': bad symbol file header", sym_file);
	}
	
	while (fgets(buff, MAX_LINE, fp_sym) != NULL)
	{
		++line_no;
		if (sscanf(buff, "%" SCNx64 ";%" SCNx64 ";%" SSCANF_MAX_STR "[^;]",
			&base , &addr, sym) != 3)
		{
			err_quit("sscanf() failed to read symbol at line %u", line_no);
		}
		
		sym_push(base+addr, sym);
	}
	
	fclose(fp_sym);
	sym_sort();	

#undef SSCANF_MAX_STR
#undef MAX_LINE
}
// </symbols>

// <disasm>
static void handle_blob_hdr(FILE * blob, const char * name)
{
	static const char hdr_txt[] = "tx64-trace le 1u64 16b";
	
	byte hdr[TX64_HDR_SZ];
	memset(hdr, 0, sizeof(hdr));
	memcpy(hdr, hdr_txt, sizeof(hdr_txt));
	
	byte hdr_buff[TX64_HDR_SZ];
	if (fread(hdr_buff, TX64_HDR_SZ, 1, blob) < 1)
		err_quit("fread() failed to read header");
	
	if (memcmp(hdr, hdr_buff, TX64_HDR_SZ) != 0)
		err_quit("'%s': bad iblob file header", name);
}
static void disasm(const char * fsym, const char * blob)
{
	sym_read(fsym);
	
	FILE * fp_blob = xfopen(blob, "rb");
	handle_blob_hdr(fp_blob, blob);
	
	csh cs_handle;
	cs_err err = cs_open(CS_ARCH_X86, CS_MODE_64, &cs_handle);
	if (err != CS_ERR_OK)
		err_quit_libcall("cs_open()");
		
	err = cs_option(cs_handle, CS_OPT_SYNTAX, CS_OPT_SYNTAX_INTEL);
	if (err != CS_ERR_OK)
		err_quit_libcall("cs_option(CS_OPT_SYNTAX)");
	
	err = cs_option(cs_handle, CS_OPT_DETAIL, CS_OPT_ON);
	if (err != CS_ERR_OK)
		err_quit_libcall("cs_option(CS_OPT_DETAIL)");
		
	tx64_instr_info instr;
	memset(&instr, 0, sizeof(instr));
	size_t cs_ip = 0;
	const byte * cs_buff = NULL;
	cs_insn * cs_inst = NULL;
	uint64_t sym_offs = 0;
	const symbol * sym = NULL;
	const char * sym_name = NULL;
	cs_x86 * x86 = NULL;
	size_t code_size = 0;
	
	cs_inst = cs_malloc(cs_handle);
	if (!cs_inst)
		err_quit_libcall("cs_malloc()");

	while (fread(&instr, sizeof(instr), 1, fp_blob) == 1)
	{
		cs_ip = instr.ip;
		sym = sym_get(cs_ip);
		sym_offs = cs_ip - sym->addr;
		sym_name = sym->name.c_str();
		
		code_size = TX64_MAX_INSTR_LEN;
		cs_buff = instr.itxt_mem;
		
		if (cs_disasm_iter(cs_handle, &cs_buff, &code_size, &cs_ip, cs_inst))
		{
			printf("0x%04jx <%s+%" PRIu64 "> | ", cs_inst->address, sym_name,
				sym_offs);
			
			for (size_t j = 0; j < cs_inst->size; ++j)
				printf("%02x ", cs_inst->bytes[j]);
			
			x86 = &(cs_inst->detail->x86);
			if (1 == x86->op_count && X86_OP_IMM == x86->operands->type &&
				(cs_insn_group(cs_handle, cs_inst, X86_GRP_JUMP) ||
				cs_insn_group(cs_handle, cs_inst, X86_GRP_CALL)))
			{			
				uint64_t target = 0;
				
				sscanf(cs_inst->op_str, "%" SCNx64, &target); 
				
				sym = sym_get(target);
				sym_offs = target - sym->addr;
				sym_name = sym->name.c_str();
				
				if (sym_offs)
				{
					printf("| %s %s <%s+%" PRIu64 ">\n",
						cs_inst->mnemonic, cs_inst->op_str, sym_name, sym_offs);
				}
				else
				{
					printf("| %s %s <%s>\n",
						cs_inst->mnemonic, cs_inst->op_str, sym_name);
				}
			}
			else
			{
				printf("| %s %s\n", cs_inst->mnemonic, cs_inst->op_str);
			}
		}
		else
		{
			printf("0x%04jx | ", instr.ip);
			for (size_t i = 0; i < TX64_MAX_INSTR_LEN; ++i)
				printf("%02x ", instr.itxt_mem[i]);
			printf("| %s\n", str_no_name());
			
			cs_err err = cs_errno(cs_handle);
			if (err != CS_ERR_OK)
				err_print("disasm: %s", cs_strerror(err));
		}
	}
	
	cs_free(cs_inst, 1);
	cs_close(&cs_handle);
	fclose(fp_blob);
}
// </disasm>

int main(int argc, char * argv[])
{
	err_set_prog_name(prog_name);
	signal(SIGINT, signal_handler);
	
	prog_options * opts = prog_opts_get();
	opts_process(argc, argv, opts);
	
	disasm(opts->sym_file, opts->blob_file);
	
	return 0;
}
