#!/usr/bin/awk -f

function SCRIPT_NAME() {return "parse-opts-gen.awk"}
function SCRIPT_VERSION() {return "1.2"}

# <user_api>
# <user_print>
function print_ind_line(str, tabs) {print_tabs(tabs); print_puts(str)}
function print_ind_str(str, tabs) {print_tabs(tabs); print_stdout(str)}
function print_inc_indent() {print_set_indent(print_get_indent()+1)}
function print_dec_indent() {print_set_indent(print_get_indent()-1)}
function print_tabs(tabs,	 i, end) {
	end = tabs + print_get_indent()
	for (i = 1; i <= end; ++i)
		print_stdout("\t")
}
function print_new_lines(num,    i) {
	for (i = 1; i <= num; ++i)
		print_stdout("\n")
}

function print_set_indent(tabs) {__indent_count__ = tabs}
function print_get_indent(tabs) {return __indent_count__}
function print_puts(str) {__print_puts(str)}
function print_puts_err(str) {__print_puts_err(str)}
function print_stdout(str) {__print_stdout(str)}
function print_stderr(str) {__print_stderr(str)}
function print_set_stdout(str) {__print_set_stdout(str)}
function print_set_stderr(str) {__print_set_stderr(str)}
function print_get_stdout() {return __print_get_stdout()}
function print_get_stderr() {return __print_get_stderr()}
# </user_print>

# <user_error>
function error(msg) {__error(msg)}
function error_input(msg) {__error_input(msg)}
# </user_error>

# <user_exit>
function exit_success() {__exit_success()}
function exit_failure() {__exit_failure()}
# </user_exit>

# <user_utils>
function data_or_err() {
	if (NF < 2)
		error_input(sprintf("no data after '%s'", $1))
}

function reset_all() {
	reset_context_arg_type()
	reset_context_var_name()
	reset_unbound_arg_code()
	reset_on_error_code()
	reset_long_name()
	reset_short_name()
	reset_takes_args()
	reset_handler_code()
	reset_help_code()
	reset_end()
}

function get_last_rule() {return __state_get()}

function save_context_arg_type(context_arg_type) {__context_arg_type_arr__[++__context_arg_type_num__] = context_arg_type}
function get_context_arg_type_count() {return __context_arg_type_num__}
function get_context_arg_type(num) {return __context_arg_type_arr__[num]}
function reset_context_arg_type() {delete __context_arg_type_arr__; __context_arg_type_num__ = 0}

function save_context_var_name(context_var_name) {__context_var_name_arr__[++__context_var_name_num__] = context_var_name}
function get_context_var_name_count() {return __context_var_name_num__}
function get_context_var_name(num) {return __context_var_name_arr__[num]}
function reset_context_var_name() {delete __context_var_name_arr__; __context_var_name_num__ = 0}

function save_unbound_arg_code(unbound_arg_code) {__unbound_arg_code_arr__[++__unbound_arg_code_num__] = unbound_arg_code}
function get_unbound_arg_code_count() {return __unbound_arg_code_num__}
function get_unbound_arg_code(num) {return __unbound_arg_code_arr__[num]}
function reset_unbound_arg_code() {delete __unbound_arg_code_arr__; __unbound_arg_code_num__ = 0}

function save_on_error_code(on_error_code) {__on_error_code_arr__[++__on_error_code_num__] = on_error_code}
function get_on_error_code_count() {return __on_error_code_num__}
function get_on_error_code(num) {return __on_error_code_arr__[num]}
function reset_on_error_code() {delete __on_error_code_arr__; __on_error_code_num__ = 0}

function save_long_name(long_name) {__long_name_arr__[++__long_name_num__] = long_name}
function get_long_name_count() {return __long_name_num__}
function get_long_name(num) {return __long_name_arr__[num]}
function reset_long_name() {delete __long_name_arr__; __long_name_num__ = 0}

function save_short_name(short_name) {__short_name_arr__[++__short_name_num__] = short_name}
function get_short_name_count() {return __short_name_num__}
function get_short_name(num) {return __short_name_arr__[num]}
function reset_short_name() {delete __short_name_arr__; __short_name_num__ = 0}

function save_takes_args(takes_args) {__takes_args_arr__[++__takes_args_num__] = takes_args}
function get_takes_args_count() {return __takes_args_num__}
function get_takes_args(num) {return __takes_args_arr__[num]}
function reset_takes_args() {delete __takes_args_arr__; __takes_args_num__ = 0}

function save_handler_code(handler_code) {__handler_code_arr__[++__handler_code_num__] = handler_code}
function get_handler_code_count() {return __handler_code_num__}
function get_handler_code(num) {return __handler_code_arr__[num]}
function reset_handler_code() {delete __handler_code_arr__; __handler_code_num__ = 0}

function save_help_code(help_code) {__help_code_arr__[++__help_code_num__] = help_code}
function get_help_code_count() {return __help_code_num__}
function get_help_code(num) {return __help_code_arr__[num]}
function reset_help_code() {delete __help_code_arr__; __help_code_num__ = 0}

function save_end(end) {__end_arr__[++__end_num__] = end}
function get_end_count() {return __end_num__}
function get_end(num) {return __end_arr__[num]}
function reset_end() {delete __end_arr__; __end_num__ = 0}
# </user_utils>
# </user_api>
#==============================================================================#
#                        machine generated parser below                        #
#==============================================================================#
# <gen_parser>
# <gp_print>
function __print_set_stdout(f) {__gp_fout__ = ((f) ? f : "/dev/stdout")}
function __print_get_stdout() {return __gp_fout__}
function __print_stdout(str) {__print(str, __print_get_stdout())}
function __print_puts(str) {__print_stdout(sprintf("%s\n", str))}
function __print_set_stderr(f) {__gp_ferr__ = ((f) ? f : "/dev/stderr")}
function __print_get_stderr() {return __gp_ferr__}
function __print_stderr(str) {__print(str, __print_get_stderr())}
function __print_puts_err(str) {__print_stderr(sprintf("%s\n", str))}
function __print(str, file) {printf("%s", str) > file}
# </gp_print>
# <gp_exit>
function __exit_skip_end_set() {__exit_skip_end__ = 1}
function __exit_skip_end_clear() {__exit_skip_end__ = 0}
function __exit_skip_end_get() {return __exit_skip_end__}
function __exit_success() {__exit_skip_end_set(); exit(0)}
function __exit_failure() {__exit_skip_end_set(); exit(1)}
# </gp_exit>
# <gp_error>
function __error(msg) {
	__print_puts_err(sprintf("%s: error: %s", SCRIPT_NAME(), msg))
	__exit_failure()
}
function __error_input(msg) {
	__error(sprintf("file '%s', line %d: %s", FILENAME, FNR, msg))
}
function GP_ERROR_EXPECT() {return "'%s' expected, but got '%s' instead"}
function __error_parse(expect, got) {
	__error_input(sprintf(GP_ERROR_EXPECT(), expect, got))
}
# </gp_error>
# <gp_state_machine>
function __state_set(state) {__state__ = state}
function __state_get() {return __state__}
function __state_match(state) {return (__state_get() == state)}
function __state_transition(_next) {
	if (__state_match("")) {
		if (__R_CONTEXT_ARG_TYPE() == _next) __state_set(_next)
		else __error_parse(__R_CONTEXT_ARG_TYPE(), _next)
	}
	else if (__state_match(__R_CONTEXT_ARG_TYPE())) {
		if (__R_CONTEXT_VAR_NAME() == _next) __state_set(_next)
		else __error_parse(__R_CONTEXT_VAR_NAME(), _next)
	}
	else if (__state_match(__R_CONTEXT_VAR_NAME())) {
		if (__R_UNBOUND_ARG_CODE() == _next) __state_set(_next)
		else __error_parse(__R_UNBOUND_ARG_CODE(), _next)
	}
	else if (__state_match(__R_UNBOUND_ARG_CODE())) {
		if (__R_ON_ERROR_CODE() == _next) __state_set(_next)
		else __error_parse(__R_ON_ERROR_CODE(), _next)
	}
	else if (__state_match(__R_ON_ERROR_CODE())) {
		if (__R_LONG_NAME() == _next) __state_set(_next)
		else __error_parse(__R_LONG_NAME(), _next)
	}
	else if (__state_match(__R_LONG_NAME())) {
		if (__R_SHORT_NAME() == _next) __state_set(_next)
		else __error_parse(__R_SHORT_NAME(), _next)
	}
	else if (__state_match(__R_SHORT_NAME())) {
		if (__R_TAKES_ARGS() == _next) __state_set(_next)
		else __error_parse(__R_TAKES_ARGS(), _next)
	}
	else if (__state_match(__R_TAKES_ARGS())) {
		if (__R_HANDLER_CODE() == _next) __state_set(_next)
		else __error_parse(__R_HANDLER_CODE(), _next)
	}
	else if (__state_match(__R_HANDLER_CODE())) {
		if (__R_HELP_CODE() == _next) __state_set(_next)
		else __error_parse(__R_HELP_CODE(), _next)
	}
	else if (__state_match(__R_HELP_CODE())) {
		if (__R_END() == _next) __state_set(_next)
		else __error_parse(__R_END(), _next)
	}
	else if (__state_match(__R_END())) {
		if (__R_LONG_NAME() == _next) __state_set(_next)
		else __error_parse(__R_LONG_NAME(), _next)
	}
}
# </gp_state_machine>
# <gp_awk_rules>
function __R_CONTEXT_ARG_TYPE() {return "context_arg_type"}
function __R_CONTEXT_VAR_NAME() {return "context_var_name"}
function __R_UNBOUND_ARG_CODE() {return "unbound_arg_code"}
function __R_ON_ERROR_CODE() {return "on_error_code"}
function __R_LONG_NAME() {return "long_name"}
function __R_SHORT_NAME() {return "short_name"}
function __R_TAKES_ARGS() {return "takes_args"}
function __R_HANDLER_CODE() {return "handler_code"}
function __R_HELP_CODE() {return "help_code"}
function __R_END() {return "end"}

$1 == __R_CONTEXT_ARG_TYPE() {__state_transition($1); on_context_arg_type(); next}
$1 == __R_CONTEXT_VAR_NAME() {__state_transition($1); on_context_var_name(); next}
$1 == __R_UNBOUND_ARG_CODE() {__state_transition($1); on_unbound_arg_code(); next}
$1 == __R_ON_ERROR_CODE() {__state_transition($1); on_on_error_code(); next}
$1 == __R_LONG_NAME() {__state_transition($1); on_long_name(); next}
$1 == __R_SHORT_NAME() {__state_transition($1); on_short_name(); next}
$1 == __R_TAKES_ARGS() {__state_transition($1); on_takes_args(); next}
$1 == __R_HANDLER_CODE() {__state_transition($1); on_handler_code(); next}
$1 == __R_HELP_CODE() {__state_transition($1); on_help_code(); next}
$1 == __R_END() {__state_transition($1); on_end(); next}
$0 ~ /^[[:space:]]*$/ {next} # ignore empty lines
$0 ~ /^[[:space:]]*#/ {next} # ignore comments
{__error_input(sprintf("'%s' unknown", $1))} # all else is error

function __init() {
	__print_set_stdout()
	__print_set_stderr()
	__exit_skip_end_clear()
}
BEGIN {
	__init()
	on_BEGIN()
}

END {
	if (!__exit_skip_end_get()) {
		if (__state_get() != __R_END())
			__error_parse(__R_END(), __state_get())
		else
			on_END()
	}
}
# </gp_awk_rules>
# </gen_parser>

# <user_input>
# Command line:
# -vScriptName=parse-opts-gen.awk
# -vScriptVersion=1.0
# Rules:
# context_arg_type -> context_var_name
# context_var_name -> unbound_arg_code
# unbound_arg_code -> on_error_code
# on_error_code -> long_name
# long_name -> short_name
# short_name -> takes_args
# takes_args -> handler_code
# handler_code -> help_code
# help_code -> end
# end -> long_name
# </user_input>
# generated by scriptscript.awk 2.21
# <user_events>
function on_context_arg_type() {
	data_or_err()
	save_context_arg_type($2)

}

function on_context_var_name() {
	data_or_err()
	save_context_var_name($2)

}

function on_unbound_arg_code() {
	#data_or_err()
	save_unbound_arg_code(get_code())

}

function on_on_error_code() {
	#data_or_err()
	save_on_error_code(get_code())

}

function name_check(name) {
	
	if (name != "\\0" && (name in _B_name_check)) {
		error_input(sprintf("name '%s' redefined from line %d",
			name, _B_name_check[name]))
	} else {
		_B_name_check[name] = FNR
	}
}

function on_long_name(    _name) {
	data_or_err()
	
	_name = $2
	name_check(_name)
	save_long_name(_name)

}

function on_short_name(    _name) {
	data_or_err()
	
	_name = $2
	name_check(_name)
	save_short_name(_name)

}

function on_takes_args() {
	data_or_err()
	save_takes_args($2)

}

function on_handler_code() {
	#data_or_err()
	save_handler_code(get_code())

}

function on_help_code() {
	#data_or_err()
	save_help_code(get_code())

}

function on_end() {
	#data_or_err()
	#save_end($2)

}

function init() {

	out_dir_set(OutDir)

	if (Help)
		print_help()
	if (Version)
		print_version()
	if (ARGC != 2)
		print_use_try()
}

function on_BEGIN() {
	init()
}

function on_END() {
	main()
}

# <user_messages>
function use_str() {
	return sprintf("Use: %s <input-file>", SCRIPT_NAME())
}

function print_use_try() {
	print_puts_err(use_str())
	print_puts_err(sprintf("Try '%s -vHelp=1' for more info", SCRIPT_NAME()))
	exit_failure()
}

function print_version() {
	print_puts(sprintf("%s %s", SCRIPT_NAME(), SCRIPT_VERSION()))
	exit_success()
}

function print_help() {
print sprintf("--- %s %s ---", SCRIPT_NAME(), SCRIPT_VERSION())
print use_str()
print "A line oriented state machine parser."
print ""
print "Options:"
print "-vOutDir=<dir> - set an output directory for the generated *.ic files"
print "-vVersion=1    - print version"
print "-vHelp=1       - print this screen"
print ""
print "Rules:"
print "'->' means 'must be followed by'"
print "'|'  means 'or'"
print "Each line of the input file must begin with a rule."
print "The rules must appear in the below order of definition."
print "Empty lines and lines which start with '#' are ignored."
print ""
print "context_arg_type -> context_var_name"
print "context_var_name -> unbound_arg_code"
print "unbound_arg_code -> on_error_code"
print "on_error_code -> long_name"
print "long_name -> short_name"
print "short_name -> takes_args"
print "takes_args -> handler_code"
print "handler_code -> help_code"
print "help_code -> end"
print "end -> long_name"
	exit_success()
}
# </user_messages>
# </user_events>

# <user_code>
# v1.11

function get_cname(name) {
	gsub("-", "_", name)
	return name
}
function get_long_cname(name) {
	return (get_cname(name) "_opt_long")
}
function get_short_cname(name) {
	return (get_cname(name) "_opt_short")
}

function gen_names(opt_num,    long_name, sanitized, ret) {
	long_name = get_long_name(opt_num)
	
	ret = sprintf("static const char %s = '%s';",
		get_short_cname(long_name), get_short_name(opt_num))
	ret = (ret "\n" sprintf("static const char %s[] = \"%s\";",
		get_long_cname(long_name),
		long_name)\
	)
	ret = (ret "\n")
	
	return ret
}

function END_CODE() {return "end_code"}

function get_code(    code_str) {
	while ((getline > 0) && (END_CODE() != $1))
		code_str = (code_str $0 "\n")
	return code_str
}

function RET_TYPE() {return "static void"}
function HANDLER_UNBOUND() {return "on_unbound_arg"}
function HANDLER_ERROR() {return "on_error"}

function gen_handler_defn(opt_num,
    title_cmnt, opt_declr, fname, sign, long_name, arg_t, code) {
    
	long_name = get_long_name(opt_num)
	arg_t = get_context_arg_type(1)
	name = get_cname(long_name)
	title_cmnt = sprintf("// %s", long_name)
	opt_declr = ""
	code = ""
	
	if (match(long_name, HANDLER_UNBOUND())) {
		code = get_unbound_arg_code(1)
		sign = "const char * arg, void * ctx"
	} else if (match(long_name, HANDLER_ERROR())) {
		code = get_on_error_code(1)
		sign = "opts_err_code err_code, const char * err_opt, void * ctx"
	} else {
		title_cmnt = sprintf("// --%s|-%s", long_name, get_short_name(opt_num))
		code = get_handler_code(opt_num)
		name = sprintf("handle_%s", name)
		sign = "const char * opt, char * opt_arg, void * ctx"
		opt_declr = gen_names(opt_num)
	}
	
	print_ind_line(title_cmnt)	
	
	if (opt_declr)
		print_ind_str(opt_declr)
		
	print_ind_line(sprintf("%s %s(%s)", RET_TYPE(), name, sign))
		
	print_ind_line("{")
	print_ind_str(code)
	print_ind_line("}")
	print_ind_line()
}

function gen_help_defn(opt_num,    long_name) {
	long_name = get_long_name(opt_num)
	
	print_ind_line(sprintf(\
		"%s help_%s(const char * short_name, const char * long_name)",\
		RET_TYPE(), get_cname(long_name))\
	)
	print_ind_line("{")
	print_ind_str(get_help_code(opt_num))
	print_ind_line("}")
	print_ind_line()
}

function gen_default_handlers() {
	save_long_name("on_unbound_arg")
	gen_handler_defn(get_long_name_count())
	
	save_long_name("on_error")
	gen_handler_defn(get_long_name_count())
}

function open_tbl() {
	print_ind_line("opts_table the_tbl;")
	print_ind_line("opts_entry all_entries[] = {")
	print_inc_indent()
}

function gen_tbl_entry(opt_num,    ctx, long_name, underscores, short_name) {
	long_name = get_long_name(opt_num)
	ctx = (match(long_name, "^help$")) ? "(&the_tbl)" : get_context_var_name(1)
	short_name = get_short_name(opt_num)
	
	underscores = get_cname(long_name)
	print_ind_line("{")
	print_inc_indent()
	print_ind_line(".names = {")
		print_inc_indent()
		print_ind_line(sprintf(".long_name = %s,", get_long_cname(long_name)))
		print_ind_line(sprintf(".short_name = %s", get_short_cname(long_name)))
		print_dec_indent()
	print_ind_line("},")
	print_ind_line(".handler = {")
		print_inc_indent()
		print_ind_line(sprintf(".handler = handle_%s,", underscores))
		print_ind_line(sprintf(".context = (void *)%s,", ctx))
		print_dec_indent()
	print_ind_line("},")
	print_ind_line(sprintf(".print_help = help_%s,", underscores))
	print_ind_line(sprintf(".takes_arg = %s,", get_takes_args(opt_num)))
	print_dec_indent()
	print_ind_line("},")
}

function close_tbl(    src) {
	print_dec_indent()
	print_ind_line("};")
	print_ind_line()
	print_ind_line("the_tbl.tbl = all_entries;")
    print_ind_line("the_tbl.length = sizeof(all_entries)/sizeof(*all_entries);")
    print_ind_line()
}

function opts_parse_data() {
	print_ind_line("opts_parse_data parse_data = {")
	print_inc_indent()
	print_ind_line(".the_tbl = &the_tbl,")
	print_ind_line(".on_unbound = {")
		print_inc_indent()
		print_ind_line(sprintf(".handler = %s,", HANDLER_UNBOUND()))
		print_ind_line(sprintf(".context = (void *)%s,", get_context_var_name(1)))
		print_dec_indent()
	print_ind_line("},")
	print_ind_line(".on_error = {")
		print_inc_indent()
		print_ind_line(sprintf(".handler = %s,", HANDLER_ERROR()))
		print_ind_line(sprintf(".context = (void *)%s,", get_context_var_name(1)))
		print_dec_indent()
	print_ind_line("}")
	print_dec_indent()
	print_ind_line("};")
}

function out_dir_set(out_dir) {_B_out_dir_ = out_dir}
function out_dir_get() {return _B_out_dir_}

function out_file_get(fname,   _out_dir) {
	_out_dir = out_dir_get()
	return _out_dir ? (_out_dir "/" fname) : fname
}

function main(    i, end, opt) {
	end = get_long_name_count()
	
	print_set_stdout(out_file_get("opts_definitions.ic"))
	print_puts("// <opts_definitions>")
	print_ind_line()
	for (i = 1; i <= end; ++i) {
		gen_handler_defn(i)
		gen_help_defn(i)
	}
	gen_default_handlers()
	print_puts("// </opts_definitions>")
	
	print_set_stdout(out_file_get("opts_process.ic"))
	print_puts("// <opts_process>")
	open_tbl()
	for (i = 1; i <= end; ++i)
		gen_tbl_entry(i)
	close_tbl()
	
	opts_parse_data()
	
	print_ind_line()
	print_ind_line("opts_parse(argc-1, argv+1, &parse_data);")
	print_puts("// </opts_process>")
}
# </user_code>
