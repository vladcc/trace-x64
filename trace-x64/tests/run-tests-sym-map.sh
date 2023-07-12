#!/bin/bash

function run_sym_map
{
	eval "../sym-map.awk" "$@"
}
function test_sym_map_no_args
{
	local L_EXPECT=\
'Use: sym-map.awk <maps-file>
Try: sym-map.awk -v Help=1'

	local L_OUT=""
	
	L_OUT="$(run_sym_map "2>&1 1>/dev/null")"
	bt_assert_failure
	bt_diff_ok "<(echo \"$L_EXPECT\") <(echo \"$L_OUT\")"
}
function test_sym_map_too_many_args
{
	local L_EXPECT=\
'Use: sym-map.awk <maps-file>
Try: sym-map.awk -v Help=1'

	local L_OUT=""
	
	L_OUT="$(run_sym_map "foo bar 2>&1 1>/dev/null")"
	bt_assert_failure
	bt_diff_ok "<(echo \"$L_EXPECT\") <(echo \"$L_OUT\")"
}
function test_sym_map_bad_maps_file
{
	local L_OUT=""
	
	L_OUT="$(run_sym_map "./run-tests.sh 2>&1 1>/dev/null")"
	bt_assert_failure
	bt_diff_ok "<(echo \"sym-map.awk: error: './run-tests.sh': broken maps file\") <(echo \"$L_OUT\")"
}
function test_sym_map_err_case
{
	bt_eval test_sym_map_no_args
	bt_eval test_sym_map_too_many_args
	bt_eval test_sym_map_bad_maps_file
}
function test_sym_map_ver
{
	local L_OUT=""
	
	L_OUT="$(run_sym_map "-v Version=1")"
	bt_assert_success
	bt_diff_ok "<(echo \"sym-map.awk 1.0\") <(echo \"$L_OUT\")"
}
function test_sym_map_help
{
	local L_EXPECT=\
"sym-map.awk -- takes a /proc/<pid>/maps file, outputs a symbol info csv file

Executes the 'file' and 'nm' commands to collect the text symbols for all ELF
files in the maps file, then maps the memory regions to the symbols for each
of the binaries. The output file name is <input-file-name>.sym including the
input file path.

Options:
-v Help=1    - this screen
-v Version=1 - version information"
 
	L_OUT="$(run_sym_map "-v Help=1")"
	bt_assert_success
	bt_diff_ok "<(echo \"$L_EXPECT\") <(echo \"$L_OUT\")"
}
function test_sym_map
{
	bt_eval test_sym_map_ver
	bt_eval test_sym_map_help
	bt_eval test_sym_map_err_case
}

function main
{
	source "$(dirname $(realpath $0))/bashtest.sh"
	
	if [ "$#" -gt 0 ]; then
		bt_set_verbose
	fi
	
	bt_enter
	bt_eval test_sym_map
	bt_exit_success
}

main "$@"
