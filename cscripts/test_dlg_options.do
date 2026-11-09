* test_dlg_options: every dialog passes its options with a name. A control with option() puts its value on the command line
* without the option name (in 3.17.4 and earlier, the "name of the new network" field of 30 dialogs was lost that way), and the
* generators ask for what the command needs first (the number of nodes, not a network). Run from the repository root.
cscript
local files : dir "." files "*.dlg"
local nbad 0
local nfiles 0
tempname fh
foreach f of local files {
	local ++nfiles
	file open `fh' using "`f'", read text
	file read `fh' line
	while r(eof) == 0 {
		if strpos(`"`line'"', "option()") {
			di as err "`f': `line'"
			local ++nbad
		}
		file read `fh' line
	}
	file close `fh'
}
assert `nfiles' > 100
assert `nbad' == 0
foreach c in nwrandom nwpref nwring nwsmall {
	file open `fh' using "`c'.dlg", read text
	local found 0
	file read `fh' line
	while r(eof) == 0 {
		if strpos(`"`line'"', `"label("Number of nodes:")"') local found 1
		file read `fh' line
	}
	file close `fh'
	assert `found' == 1
}
di as text "PASS test_dlg_options (`nfiles' dialogs)"
