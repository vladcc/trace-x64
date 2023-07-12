#!/bin/bash

function compile
{
	gcc "$1" -o "$2" -Wall
	bt_assert_success
}
function clean_up
{
	rm -f *.bin.*.tx64-trace.* "$@"
}
function run_tx64_trace
{
	eval "../tx64-trace" "$@"
}
function run_sym_map
{
	eval "../sym-map.awk" "$@"
}
function run_tx64_print
{
	eval "../tx64-print" "$@"
}
function get_iblob
{
	echo "$(ls *$@*.tx64-trace.iblob)"
}
function get_maps_start
{
	echo "$(ls *$@*.tx64-trace.maps.start)"
}
function get_maps_end
{
	echo "$(ls *$@*.tx64-trace.maps.end)"
}
function get_sym
{
	echo "$(ls *$@*.tx64-trace.maps.*.sym)"
}

function test_tx64_trace_run
{
	local L_BIN="$1"
	shift 1
	
	local L_BIN_ARGS="$1"
	shift 1
	
	local L_OUT=""
	
	L_OUT="$(run_tx64_trace "$@")"
	bt_assert_success
	bt_diff_ok "<(echo \"$L_BIN_ARGS\") <(echo \"$L_OUT\")"
	bt_diff_ok "<(echo 1) <(echo \"$(get_iblob $L_BIN)\" | wc -l)"
	bt_diff_ok "<(echo 1) <(echo \"$(get_maps_start $L_BIN)\" | wc -l)"
	bt_diff_ok "<(echo 1) <(echo \"$(get_maps_end $L_BIN)\" | wc -l)"
}
function test_sym_map_run
{
	local L_FN="$1"
	local L_BIN="$2"
	
	run_sym_map "$($L_FN $L_BIN)"
	bt_assert_success
	bt_diff_ok "<(echo 1) <(echo \"$(get_sym $L_BIN)\" | wc -l)"
}
function test_tx64_print_max_instr
{
	local L_BIN="$1"
	local L_MAX_INSTR="$2"
	local L_SYM="$(get_sym $L_BIN)"
	local L_IBLOB="$(get_iblob $L_BIN)"
	
	run_tx64_print "-s $L_SYM -i $L_IBLOB" | grep -E 'push|pop|mov|ret|test|call|jmp' > /dev/null
	bt_assert_success
	
	run_tx64_print "-i $L_IBLOB" | grep -E '<???\+[0-9]+> | [0-9a-f ]+ | [a-z]+' > /dev/null
	bt_assert_success
	
	bt_diff_ok "<(echo $L_MAX_INSTR) <(run_tx64_print -s $L_SYM -i $L_IBLOB | wc -l)"
}

# <trace-exec>
function test_tx64_trace_exec_full
{
	local L_ECHO_BIN="$1"
	local L_ECHO_ARGS="foo -x bar -s baz -Z zig"
	
	bt_eval test_tx64_trace_run "$L_ECHO_BIN" "\"$L_ECHO_ARGS\"" "-x ./$L_ECHO_BIN $L_ECHO_ARGS"
	bt_eval test_sym_map_run "get_maps_end" "$L_ECHO_BIN"
	bt_eval test_tx64_print_exec_full "$L_ECHO_BIN"
}
function test_tx64_print_exec_full
{
	local L_BIN="$1"
	local L_SYM="$(get_sym $L_BIN)"
	local L_IBLOB="$(get_iblob $L_BIN)"
	
	run_tx64_print "-s $L_SYM -i $L_IBLOB" | grep -E '<main\+[0-9]+> | [0-9a-f ]+ | [a-z]+' > /dev/null
	bt_assert_success
	
	run_tx64_print "-s $L_SYM -i $L_IBLOB" | grep -E '<echo\+[0-9]+> | [0-9a-f ]+ | [a-z]+' > /dev/null
	bt_assert_success
	
	run_tx64_print "-s $L_SYM -i $L_IBLOB" | grep -E 'push|pop|mov|ret|test|call|jmp' > /dev/null
	bt_assert_success
	
	run_tx64_print "-i $L_IBLOB" | grep -E '<???\+[0-9]+> | [0-9a-f ]+ | [a-z]+' > /dev/null
	bt_assert_success
}
function test_tx64_trace_no_aslr
{
	local L_ECHO_BIN="$1"
	local L_ECHO_ARGS="foo -x bar -s baz -Z zig"
	
	bt_eval test_tx64_trace_run "$L_ECHO_BIN" "\"$L_ECHO_ARGS\"" "-x ./$L_ECHO_BIN $L_ECHO_ARGS"
	bt_eval_ok "mv $(get_maps_end) aslr-maps-file"
	bt_eval clean_up
	
	bt_eval test_tx64_trace_run "$L_ECHO_BIN" "\"$L_ECHO_ARGS\"" "-n -x ./$L_ECHO_BIN $L_ECHO_ARGS"
	bt_eval_ok "mv $(get_maps_end) no-aslr-maps-file-1"
	bt_eval clean_up
	
	bt_eval test_tx64_trace_run "$L_ECHO_BIN" "\"$L_ECHO_ARGS\"" "-n -x ./$L_ECHO_BIN $L_ECHO_ARGS"
	bt_eval_ok "mv $(get_maps_end) no-aslr-maps-file-2"
	
	bt_eval "diff aslr-maps-file no-aslr-maps-file-1 > /dev/null"
	bt_assert_failure
	bt_diff_ok "no-aslr-maps-file-1" "no-aslr-maps-file-2"
	
	bt_eval "rm *aslr-maps-file*"
}
function test_tx64_trace_exec_max_instr
{
	local L_ECHO_BIN="$1"
	local L_ECHO_ARGS=""
	local L_MAX_INSTR="17"
	
	bt_eval test_tx64_trace_run "$L_ECHO_BIN" "\"$L_ECHO_ARGS\"" "-m $L_MAX_INSTR -x ./$L_ECHO_BIN $L_ECHO_ARGS"
	bt_eval test_sym_map_run "get_maps_end" "$L_ECHO_BIN"
	bt_eval test_tx64_print_max_instr "$L_ECHO_BIN" "$L_MAX_INSTR"
	
}
function test_tx64_trace_exec
{
	local L_ECHO_BIN="echo.bin"
	
	bt_eval compile "./echo.c" "$L_ECHO_BIN"
	bt_eval test_tx64_trace_exec_full "$L_ECHO_BIN"
	bt_eval clean_up
	
	bt_eval test_tx64_trace_no_aslr "$L_ECHO_BIN"
	bt_eval clean_up
	
	bt_eval test_tx64_trace_exec_max_instr "$L_ECHO_BIN"
	bt_eval clean_up "$L_ECHO_BIN"
}
# </trace-exec>

# <trace-pid>
function test_tx64_trace_pid_max_instr
{
	local L_PID="$1"
	local L_MAX_INSTR="$2"
	local L_BIN="$3"
		
	bt_eval test_tx64_trace_run "$L_PID" "\"\"" "-m $L_MAX_INSTR -p $L_PID"
	bt_eval test_sym_map_run "get_maps_start" "$L_BIN"
	bt_eval test_tx64_print_max_instr "$L_BIN" "$L_MAX_INSTR"
}
function test_tx64_trace_pid_timeout
{
	local L_PID="$1"
	local L_TIMEOUT="$2"
	local L_BIN="$3"
	local L_SYM=""
	local L_IBLOB=""
	
	bt_eval test_tx64_trace_run "$L_PID" "\"\"" "-s $L_TIMEOUT -p $L_PID"
	
	bt_eval test_sym_map_run "get_maps_end" "$L_BIN"
	L_SYM="$(get_sym $L_BIN)"
	L_IBLOB="$(get_iblob $L_BIN)"
	
	run_tx64_print "-s $L_SYM -i $L_IBLOB" | grep -E '<main\+[0-9]+> | [0-9a-f ]+ | [a-z]+' > /dev/null
	bt_assert_success

	run_tx64_print "-s $L_SYM -i $L_IBLOB" | grep -E 'push|pop|mov|ret|test|call|jmp' > /dev/null
	bt_assert_success
	
	run_tx64_print "-i $L_IBLOB" | grep -E '<???\+[0-9]+> | [0-9a-f ]+ | [a-z]+' > /dev/null
	bt_assert_success
}
function test_tx64_trace_pid
{
	local L_SLEEP_BIN="sleep.bin"
	local L_SLEEP_PID=""
	
	bt_eval compile "./sleep.c" "$L_SLEEP_BIN"
	
	"./$L_SLEEP_BIN" &
	L_SLEEP_PID="$!"
	
	bt_eval test_tx64_trace_pid_max_instr "$L_SLEEP_PID" "19" "$L_SLEEP_BIN"
	bt_eval clean_up
	
	bt_eval test_tx64_trace_pid_timeout "$L_SLEEP_PID" "5" "$L_SLEEP_BIN"
	bt_eval_ok "kill $L_SLEEP_PID"
	bt_eval clean_up "$L_SLEEP_BIN"
}
# </trace-pid>
function test_all
{
	bt_eval test_tx64_trace_exec
	bt_eval test_tx64_trace_pid
}

function main
{
	source "$(dirname $(realpath $0))/bashtest.sh"
	
	if [ "$#" -gt 0 ]; then
		bt_set_verbose
	fi
	
	bt_enter
	bt_eval test_all
	bt_exit_success
}

main "$@"
