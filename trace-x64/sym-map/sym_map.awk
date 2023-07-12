#!/usr/bin/awk -f

### !!! Do not edit sym-map.awk by hand !!! ###

BEGIN {
	init()
}

{
	process_line()
}

END {
	if (!should_skip_end())
		sym_map()
}

# <constants>
function SCRIPT_NAME() {return "sym-map.awk"}
function SCRIPT_VERSION() {return "1.0"}
function CSV_HEADER() {return "Base;Offset;Name;Binary"}
# </constants>

# <prog-info>
function print_use_quit() {
pstderr(sprintf("Use: %s <maps-file>", SCRIPT_NAME()))
pstderr(sprintf("Try: %s -v Help=1", SCRIPT_NAME()))
exit_failure()
}
function print_version_quit() {
print sprintf("%s %s", SCRIPT_NAME(), SCRIPT_VERSION())
exit_success()
}
function print_help_quit() {
print sprintf("%s -- takes a /proc/<pid>/maps file, outputs a symbol info csv file", SCRIPT_NAME())
print ""
print "Executes the 'file' and 'nm' commands to collect the text symbols for all ELF"
print "files in the maps file, then maps the memory regions to the symbols for each"
print "of the binaries. The output file name is <input-file-name>.sym including the"
print "input file path."
print ""
print "Options:"
print "-v Help=1    - this screen"
print "-v Version=1 - version information"
exit_success()
}
# </prog-info>

# <init>
function init() {

	set_program_name(SCRIPT_NAME())
	
	if (Help)
		print_help_quit()

	if (Version)
		print_version_quit()

	if (ARGC != 2)
		print_use_quit()

	maps_file_name_set(ARGV[1])
}
# </init>

# <maps-file-struct>
function maps_file_name_set(name) {_B_maps_file_name = name}
function maps_file_name_get() {return _B_maps_file_name}

function maps_file_entity_save(addr, bin) {
	_B_maps_file_ent_ord[++_B_maps_file_ent_ord_count] = bin
	_B_maps_file_ent_bin_addr[bin] = addr
}
function maps_file_entity_get_count() {return _B_maps_file_ent_ord_count}
function maps_file_entity_get_bin(num) {return _B_maps_file_ent_ord[num]}
function maps_file_entity_get_addr(num) {
	return _B_maps_file_ent_bin_addr[maps_file_entity_get_bin(num)]
}
function maps_file_entity_is_seen(bin) {
	return (bin in _B_maps_file_ent_bin_addr)
}
# </maps-file-struct>

# <processing>
function run_cmd(arr_out, cmd,    _res, _len) {
	
	_len = exec_cmd_sh(cmd, arr_out)
	_res = arr_out[_len]
	
	if (_res != 0) {
		error_print(sprintf("'%s' failed with exit code %s", _cmd, _res))
		error_quit(sprintf("'%s'", _arr[1]))
	}
	
	return _len
}

function is_file_exec(fname,    _arr) {

	run_cmd(_arr, ("file -L " fname))
	return match(_arr[1], " ELF ")
}

function process_line(    _arr) {

	if (!match($0, "^[0-9a-f]+-[0-9a-f]+ "))
		error_quit(sprintf("'%s': broken maps file", maps_file_name_get()))
		
	if (match($NF, "/") && !maps_file_entity_is_seen($NF)) {
	
		if (is_file_exec($NF)) {
		
			split($1, _arr, "-")
			maps_file_entity_save(_arr[1], $NF)
		}
	}
}

function sym_read(arr_out, bin, addr,    _arr, _cmd, _len, _i, _arr_spl,
_tmp, _out_i) {
	
	delete arr_out
	
	_out_i = 0
	_cmd = "nm "
	if (match(bin, "\\.so"))
		_cmd = (_cmd "-gD ")
	_cmd = (_cmd bin)
	
	_len = run_cmd(_arr, _cmd)
	
	for (_i = 1; _i <= _len; ++_i) {
		
		if (split(_arr[_i], _arr_spl) == 3) {
		
			_tmp = _arr_spl[2]
			
			if ("T" == _tmp || "t" == _tmp) {
			
				arr_out[++_out_i] = sprintf("%s;%s;%s;%s", \
					addr, _arr_spl[1], _arr_spl[3], bin)
			}
		}
	}
	
	return _out_i
}

function sym_map(    _i, _end, _bin, _addr, _arr_sym, _len, _fout, _j) {

	_fout = maps_file_name_get()
	_fout = (_fout ".sym")
	
	print CSV_HEADER() > _fout
	
	_end = maps_file_entity_get_count()
	for (_i = 1; _i <= _end; ++_i) {
		
		_bin = maps_file_entity_get_bin(_i)
		_addr = maps_file_entity_get_addr(_i)
		
		_len = sym_read(_arr_sym, _bin, _addr)
		
		for (_j = 1; _j <= _len; ++_j)
			print _arr_sym[_j] > _fout
	}
}
# </processing>
