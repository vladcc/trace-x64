#!/bin/bash

function main
{
	local L_DIR="$1"
	L_DIR="${L_DIR:=.}"
	rm -f "${L_DIR}"/*.bin "${L_DIR}"/*.bin.*.tx64-trace.* "${L_DIR}"/*aslr-*
}

main "$@"
