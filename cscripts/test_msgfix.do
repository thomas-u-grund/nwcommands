cscript

do unw_core.do

* Regression test: error messages that were printed with a plain `di' inside a `qui foreach' block were swallowed, so the user
* saw only "invalid syntax" (for example `nw2degree davis' without generate()). The messages are now printed with `noi di'.
* The helper runs a command with its output written to a text log and checks that the log contains the message.

capture program drop msgfix_chk
program define msgfix_chk
	args cmd needle
	tempfile lg
	quietly log using `"`lg'"', text replace name(msgfix)
	capture noisily `cmd'
	local rc = _rc
	quietly log close msgfix
	tempname fh
	local found 0
	file open `fh' using `"`lg'"', read text
	file read `fh' line
	while r(eof) == 0 {
		if strpos(`"`macval(line)'"', `"`needle'"') > 0 local found 1
		file read `fh' line
	}
	file close `fh'
	if `rc' == 0 | !`found' {
		di as error "FAIL: {it:`cmd'} (rc `rc'): message `needle' not shown"
		exit 9
	}
	di as text "  PASS: `cmd' prints its message (rc `rc')"
end

nwclear
nwwebuse florentine, nwclear
nwwebuse davis, nwappend

* two-mode network without generate()
msgfix_chk "nw2degree davis" "option generate() required"
msgfix_chk "nw2clustering davis" "option generate() required"

* one-mode commands without generate()
foreach c in nwclique nwcohesion nwcommunity nwconcor nwcoreperiphery nwdegree nwkcomponents nwkcore nwnclan nwnclique {
	msgfix_chk "`c' flomarriage" "option generate() required"
}
generate byte grp = 1
msgfix_chk "nwbrokerage flomarriage, group(grp)" "option generate() required"

* an existing variable without replace
quietly nwbetween flomarriage, generate(zzbet)
msgfix_chk "nwbetween flomarriage, generate(zzbet)" "already exists"

di as result "ALL TESTS PASSED"
