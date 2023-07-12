/*  parse_opts.h -- command line options parsing
    v2.0
    
    Command line option parsing for the classic syntax you'd find on *nix
    systems, implemented with callbacks.
    
    Options can have a single character short name which starts with a dash and
    a long name which starts with a double dash. Short names of options that do
    not takes arguments can be bunched together (e.g. -ixyz). Options that
    do take arguments can have the following syntax:
    -a Arg-To-a
    -aArg-To-a
    --a-option Arg-To-a
    --a-option=Arg-To-a
    --a-option= Arg-To-a
    Short names of options with arguments can be bunched together with
    options without arguments, given the option with the argument is last
    (e.g. -xyzaArg-To-a or -xyza Arg-To-a). Sub-arguments are also supported
    as a delimited list by the opts_get_sub_arg() function. A single dash is
    seen as an argument to the program (not belonging to any option). Everything
    after only a double dash is also seen as program arguments, even option
    names. This library does not copy argv, but does change the strings. If a
    long option name ends in with a '=', the '=' is replaced with '\0', as is
    the first delimiter after a sub-argument when opts_get_sub_arg() is used.
    
    Author: Vladimir Dinev
    vld.dinev@gmail.com
    2020-08-30
*/

#ifndef PARSE_OPTS_H
#define PARSE_OPTS_H

#include <stdbool.h>

// opt_arg is NULL for options that do not take arguments
// context is a pointer to something user defined
typedef void (*opts_handler)(
	const char * opt,
	char * opt_arg,
	void * context
);
typedef struct opts_handler_pair {
	opts_handler handler;
	void * context;
} opts_handler_pair;

// short_name and long_name are passed with '-' and "--" pre-pended respectively
typedef void (*opts_help_printer)(
	const char * short_name,
	const char * long_name
);

// called when an argument not bound to an option is seen
// e.g. 'prog my-arg' as opposed to 'prog --my-opt my-arg'
typedef void (*opts_on_unbound_arg)(const char * arg, void * context);
typedef struct opts_on_unbound_arg_pair {
	opts_on_unbound_arg handler;
	void * context;
} opts_on_unbound_arg_pair;

// error conditions and handler
typedef enum opts_err_code {
	// unknown option is encountered
	OPTS_UNKOWN_OPT_ERR = 1,
	// an option which requires an argument has no argument
	OPTS_ARG_REQ_ERR,
	// an option which does not require an argument has an argument
	// applies only to --takes-no-arg=given-one-anyway
	OPTS_NO_ARG_REQ_ERR
} opts_err_code;
typedef void (*opts_on_error)(
	opts_err_code err_code,
	const char * err_opt,
	void * context
);
typedef struct opts_on_error_pair {
	opts_on_error handler;
	void * context;
} opts_on_error_pair;

// option names
// short_name can be '\0' if not used, long_name can be NULL
typedef struct opts_name_pair {
	const char * long_name;
	char short_name;
} opts_name_pair;

// option table entry; the tbl pointer in opts_table points to an array of this
typedef struct opts_entry {
    opts_name_pair names;
    opts_handler_pair handler;
    opts_help_printer print_help;
    bool takes_arg;
} opts_entry;

// point to the table entry array here, set the length
typedef struct opts_table {
    opts_entry * tbl;
    int length;
} opts_table;

// makes calling opts_parse() more readable
typedef struct opts_parse_data {
	opts_table * the_tbl;
	opts_on_unbound_arg_pair on_unbound;
	opts_on_error_pair on_error;
} opts_parse_data;

void opts_parse(int argc, char * argv[], opts_parse_data * parse_data);
/*
Returns: Nothing.
Description: Parses the strings in argv, calling a handler when an option
from parse_data->the_tbl is encountered, parse_data->on_unbound.handler when an
argument not belonging to any option is met, and parse_data->on_error.handler if
an error occurs. To skip the program name call with opts_parse(argc-1, argv+1...
*/

void opts_print_help(opts_table * the_tbl);
/*
Returns: Nothing.
Description: Goes through the_tbl and calls the print_help callback for every
option in the order of definition.
Note: best use - set the_tbl as the context for the help option and call this
function from the help option handler.
*/

char * opts_get_sub_arg(char ** parg, char delimiter);
/*
Returns: A pointer to the next sub-argument, NULL when no more sub-arguments.
Description: Splits the string pointed to by *parg into tokens separated by
delimiter, much like strtok() from the standard library. However, unlike
strtok(), only a single character can be a delimiter, and it does not use
static storage; instead, it uses parg to save its progress. parg must be set
to point to the address of the sub-argument list before the first call. All
excessive delimiters before and after sub-arguments are ignored, while the
first delimiter after a sub-argument is replaced with '\0'.
Example: If arg is a char * and it points to the string "a,b,c,d", the
following code can be used to split the string into the arguments "a", "b",
"c", and "d":
char * sub_arg, ** parg = &arg;
while ((sub_arg = opts_get_sub_arg(parg, ',')))
    <do-something-with-sub_arg>;
*/
#endif
