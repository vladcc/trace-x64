#!/usr/bin/awk -f

BEGIN {
	FS="\\|"
}

$NF ~ / call | jmp qword ptr / {
	getline
	ctbl[$1]++
}

END {
	for (c in ctbl)
		print (c "| " ctbl[c])
}
