#!/bin/bash

function main
{
	local MY_DIR="$(dirname $(realpath $0))"
	"${MY_DIR}/cleanup.sh" "${MY_DIR}"
	"${MY_DIR}/run-tests-tx64-trace.sh" "$@"
	"${MY_DIR}/run-tests-tx64-print.sh" "$@"
	"${MY_DIR}/run-tests-sym-map.sh" "$@"
	"${MY_DIR}/run-tests-pipeline.sh" "$@"
}

main "$@"
