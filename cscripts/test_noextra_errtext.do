cscript

* A command that has shown its own error message stops with `exit N`, not `error N` (which printed a second line,
* "invalid syntax" or another canned text, after the real message). The return codes are unchanged.
* Checked by _rc and by the text of a log written around each failing call.

capture program drop nwinstall
clear all
nwrandom 10, prob(.3) name(g)
nwdegree g, generate(d1 d2)
nwdrop _all
nwrandom 10, prob(.3) name(g)

capture program drop _nwchk
program _nwchk
	gettoken expected cmd : 0
	tempfile lg
	quietly log using "`lg'", text replace name(_nwchk)
	capture noisily `cmd'
	local rc = _rc
	quietly log close _nwchk
	assert `rc' == `expected'
	tempname fh
	file open `fh' using "`lg'", read text
	local seen 0
	local extra 0
	file read `fh' line
	while r(eof) == 0 {
		if strpos(`"`line'"', "invalid syntax") local extra 1
		if trim(`"`line'"') != "" local seen 1
		file read `fh' line
	}
	file close `fh'
	assert `extra' == 0
	assert `seen' == 1
end

* required option missing (198)
_nwchk 198 nwdegree g
_nwchk 198 nwclique g
* variable exists (110)
generate dd = 1
_nwchk 110 nwdegree g, generate(dd ee)
* network name taken (483)
_nwchk 483 nwshared g, name(g) undirected
* node id out of range (485)
_nwchk 485 nwpath g, egoid(99) alterid(1)

di "PASS test_noextra_errtext"
