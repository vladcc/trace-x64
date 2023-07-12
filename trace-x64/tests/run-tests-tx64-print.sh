#!/bin/bash

function run_tx64_print
{
	eval "../tx64-print" "$@"
}
function test_tx64_print_no_args
{
	local L_EXPECT=\
'Use: tx64-print [-s <sym-file>] -i <iblob>
Try: tx64-print --help'

	local L_OUT=""
	
	L_OUT="$(run_tx64_print "2>&1 1>/dev/null")"
	bt_assert_failure
	bt_diff_ok "<(echo \"$L_EXPECT\") <(echo \"$L_OUT\")"
}
function text_tx64_print_unbound_arg
{
	local L_OUT=""
	
	L_OUT="$(run_tx64_print "foo 2>&1 1>/dev/null")"
	bt_assert_failure
	bt_diff_ok "<(echo \"tx64-print: error: unbound argument: 'foo'\") <(echo \"$L_OUT\")"
}
function test_tx64_print_bad_fnames
{
	local L_OUT=""
	
	L_OUT="$(run_tx64_print "-s foo 2>&1 1>/dev/null")"
	bt_assert_failure
	bt_diff_ok "<(echo \"tx64-print: error: iblob file required\") <(echo \"$L_OUT\")"
	
	L_OUT="$(run_tx64_print "-s foo -i bar 2>&1 1>/dev/null")"
	bt_assert_failure
	bt_diff_ok "<(echo \"tx64-print: error: 'foo': No such file or directory\") <(echo \"$L_OUT\")"
	
	L_OUT="$(run_tx64_print "-i bar 2>&1 1>/dev/null")"
	bt_assert_failure
	bt_diff_ok "<(echo \"tx64-print: error: 'bar': No such file or directory\") <(echo \"$L_OUT\")"
}
function test_tx64_print_bad_fheaders
{
	local L_OUT=""
	
	L_OUT="$(run_tx64_print "-s ./run-tests.sh -i ./run-tests.sh 2>&1 1>/dev/null")"
	bt_assert_failure
	bt_diff_ok "<(echo \"tx64-print: error: './run-tests.sh': bad symbol file header\") <(echo \"$L_OUT\")"

	L_OUT="$(run_tx64_print "-i ./run-tests.sh 2>&1 1>/dev/null")"
	bt_assert_failure
	bt_diff_ok "<(echo \"tx64-print: error: './run-tests.sh': bad iblob file header\") <(echo \"$L_OUT\")"
}
function test_tx64_print_err_case
{
	bt_eval test_tx64_print_no_args
	bt_eval text_tx64_print_unbound_arg
	bt_eval test_tx64_print_bad_fnames
	bt_eval test_tx64_print_bad_fheaders
}
function test_tx64_print_ver
{
	local L_OUT=""
	
	L_OUT="$(run_tx64_print "--version")"
	bt_assert_success
	bt_diff_ok "<(echo \"tx64-print 1.0\") <(echo \"$L_OUT\")"
}
function test_tx64_print_help
{
	local L_EXPECT=\
"tx64-print -- prints disassembly for instruction blobs provided by tx64-trace

Options:
 -s, --sym <sym-file> - if <sym-file> is provided, as output by sym-map.awk,
 use the symbol information in the disassembly.
 -i, --blob <iblob>   - the instruction blob provided by tx64-trace.
 -h, --help           - print this screen.
 -v, --version        - print version information."
 
	L_OUT="$(run_tx64_print "--help")"
	bt_assert_success
	bt_diff_ok "<(echo \"$L_EXPECT\") <(echo \"$L_OUT\")"
}
function test_tx64_print
{
	bt_eval test_tx64_print_ver
	bt_eval test_tx64_print_help
	bt_eval test_tx64_print_err_case
}

function main
{
	source "$(dirname $(realpath $0))/bashtest.sh"
	
	if [ "$#" -gt 0 ]; then
		bt_set_verbose
	fi
	
	bt_enter
	bt_eval test_tx64_print
	bt_exit_success
}

main "$@"
