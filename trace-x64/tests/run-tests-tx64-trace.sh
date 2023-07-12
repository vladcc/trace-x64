#!/bin/bash

function run_tx64_trace
{
	eval "../tx64-trace" "$@"
}
function test_tx64_trace_no_args
{
	local L_EXPECT=\
'Use: tx64-trace [run-option] <executable-or-pid>
Try: tx64-trace --help'

	local L_OUT=""
	
	L_OUT="$(run_tx64_trace "2>&1 1>/dev/null")"
	bt_assert_failure
	bt_diff_ok "<(echo \"$L_EXPECT\") <(echo \"$L_OUT\")"
}
function text_tx64_trace_unbound_arg
{
	local L_OUT=""
	
	L_OUT="$(run_tx64_trace "foo 2>&1 1>/dev/null")"
	bt_assert_failure
	bt_diff_ok "<(echo \"tx64-trace: error: unbound argument: 'foo'\") <(echo \"$L_OUT\")"
}
function test_tx64_trace_bad_pid
{
	local L_OUT=""
	
	L_OUT="$(run_tx64_trace "-p foo 2>&1 1>/dev/null")"
	bt_assert_failure
	bt_diff_ok "<(echo \"tx64-trace: error: 'foo' not a valid pid\") <(echo \"$L_OUT\")"
	
	L_OUT="$(run_tx64_trace "-p 0 2>&1 1>/dev/null")"
	bt_assert_failure
	bt_eval_ok "echo \"$L_OUT\" | grep \"^tx64-trace: error: ptrace(PTRACE_ATTACH) failed:\" > /dev/null"
	
	L_OUT="$(run_tx64_trace "-p -1234 2>&1 1>/dev/null")"
	bt_assert_failure
	bt_eval_ok "echo \"$L_OUT\" | grep \"^tx64-trace: error: ptrace(PTRACE_ATTACH) failed:\" > /dev/null"
}
function test_tx64_trace_bad_max_instr
{
	local L_OUT=""
	
	L_OUT="$(run_tx64_trace "-m foo 2>&1 1>/dev/null")"
	bt_assert_failure
	bt_diff_ok "<(echo \"tx64-trace: error: 'foo' not a valid number\") <(echo \"$L_OUT\")"
	
	L_OUT="$(run_tx64_trace "-m -123 2>&1 1>/dev/null")"
	bt_assert_failure
	bt_diff_ok "<(echo \"tx64-trace: error: no pid nor executable given\") <(echo \"$L_OUT\")"
}
function test_tx64_trace_bad_executable
{
	local L_OUT=""
	
	L_OUT="$(run_tx64_trace "-x ./foo 2>&1 1>/dev/null")"
	bt_assert_failure
	bt_eval_ok "echo \"$L_OUT\" | grep \"^tx64-trace: error: execvp() failed:\" > /dev/null"
	bt_eval_ok "echo \"$L_OUT\" | grep -E \"^tx64-trace: error: '/proc/[0-9]+/comm':\" > /dev/null"
}
function test_tx64_trace_err_case
{
	bt_eval test_tx64_trace_no_args
	bt_eval text_tx64_trace_unbound_arg
	bt_eval test_tx64_trace_bad_pid
	bt_eval test_tx64_trace_bad_max_instr
	bt_eval test_tx64_trace_bad_executable
}
function test_tx64_trace_ver
{
	local L_OUT=""
	
	L_OUT="$(run_tx64_trace "--version")"
	bt_assert_success
	bt_diff_ok "<(echo \"tx64-trace 1.0\") <(echo \"$L_OUT\")"
}
function test_tx64_trace_help
{
	local L_EXPECT=\
"tx64-trace -- instruction execution tracer for x64

Attaches to a process and single-steps the instructions being executed. Outputs
three files: a binary instruction blob and two copies of the /proc/<pid>/maps
file - one taken at the attach time and one at detach. Any of the maps files
can be given to sym-map.awk to produce a symbol map, which can then be given to
tx64-print along with the instruction blob for disassembly. If both -m and -s
options are present, tracing stops when whichever happens first.

Options:
 -x, --exec ...       - everything after this option is taken to be a command
 and its arguments. It's executed as given and traced from the start.
 -n, --no-aslr        - no address space layout randomization when used with -x.
 -p, --pid <pid>      - attach to an already running process.
 -m, --max-inst <num> - collect only the next <num> number of instructions.
 -s, --seconds <num>  - collect instructions for <num> seconds.
 -h, --help           - print this screen.
 -v, --version        - print version information."
 
	L_OUT="$(run_tx64_trace "--help")"
	bt_assert_success
	bt_diff_ok "<(echo \"$L_EXPECT\") <(echo \"$L_OUT\")"
}
function test_tx64_trace
{
	bt_eval test_tx64_trace_ver
	bt_eval test_tx64_trace_help
	bt_eval test_tx64_trace_err_case
}

function main
{
	source "$(dirname $(realpath $0))/bashtest.sh"
	
	if [ "$#" -gt 0 ]; then
		bt_set_verbose
	fi
	
	bt_enter
	bt_eval test_tx64_trace
	bt_exit_success
}

main "$@"
