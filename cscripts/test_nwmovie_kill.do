cscript

* nwmovie export(): the viewer that nwmovie started is stopped by its exact staged name (on a timeout, an error
* and after the export), and on macOS a locked screen is reported before the viewer is launched.
* The kill helper is tested with fake "viewers" (shell scripts named like the staged copies), no GUI needed.

capture program drop nwinstall
do unw_core.do
run nwmovie.ado

* --- the lock check returns a clear answer or "unknown", and never an error
_nwmovie_screenlocked
assert inlist(r(locked), -1, 0, 1)
if "`c(os)'" != "MacOSX" assert r(locked) == -1

if "`c(os)'" != "Windows" {
	local td "`c(tmpdir)'"
	if substr("`td'", -1, 1) != "/" local td "`td'/"
	local n = 700000 + int(runiform()*200000)
	local nlong = `n' * 10 + 7
	local f1 "`td'nwedit_viewer_`n'"
	local f2 "`td'nwedit_viewer_`nlong'"
	foreach f in f1 f2 {
		tempname fh
		file open `fh' using "``f''", write text replace
		file write `fh' "#!/bin/sh" _n "sleep 25" _n
		file close `fh'
		shell chmod +x "``f''"
	}
	shell "`f1'" > /dev/null 2>&1 &
	shell "`f2'" > /dev/null 2>&1 &
	sleep 1500
	tempfile cnt
	shell pgrep -f "nwedit_viewer_`n'( |$)" | wc -l > "`cnt'"
	file open `fh' using "`cnt'", read text
	file read `fh' line
	file close `fh'
	assert real(strtrim("`line'")) >= 1
	* stop the first one only
	_nwmovie_killviewer "`f1'"
	sleep 700
	shell pgrep -f "nwedit_viewer_`n'( |$)" | wc -l > "`cnt'"
	file open `fh' using "`cnt'", read text
	file read `fh' line
	file close `fh'
	assert real(strtrim("`line'")) == 0
	* a process whose name only starts with the same digits is untouched
	shell pgrep -f "nwedit_viewer_`nlong'( |$)" | wc -l > "`cnt'"
	file open `fh' using "`cnt'", read text
	file read `fh' line
	file close `fh'
	assert real(strtrim("`line'")) >= 1
	capture confirm file "`f1'"
	assert _rc != 0
	_nwmovie_killviewer "`f2'"
	sleep 700
	shell pgrep -f "nwedit_viewer_`nlong'( |$)" | wc -l > "`cnt'"
	file open `fh' using "`cnt'", read text
	file read `fh' line
	file close `fh'
	assert real(strtrim("`line'")) == 0
}

* --- names that are not a staged viewer are refused silently (nothing is killed, nothing erased)
tempfile keep
shell echo x > "`keep'"
_nwmovie_killviewer "`keep'"
confirm file "`keep'"
_nwmovie_killviewer ""

* --- the whole command (macOS): fake lock stops at once with 498; timeout stops with 498; no stray viewer
if "`c(os)'" == "MacOSX" {
	nwset, mat((0,1,0\1,0,0\0,0,0)) name(mk_w1) undirected labs(A,B,C)
	nwset, mat((0,1,1\1,0,0\1,0,0)) name(mk_w2) undirected labs(A,B,C)
	local sd "`c(tmpdir)'"
	if substr("`sd'", -1, 1) != "/" local sd "`sd'/"
	tempfile cnt
	local oldpwd "`c(pwd)'"
	cd "`sd'"
	capture erase nwmk_a.mp4
	capture erase nwmk_b.mp4

	* (2) fake lock: error 498 at once, nothing started, no file
	global NW_FAKE_LOCKED 1
	timer clear 77
	timer on 77
	capture nwmovie mk_w1 mk_w2, fixedlayout export(nwmk_a.mp4) replace timeout(60)
	local rc = _rc
	timer off 77
	global NW_FAKE_LOCKED
	assert `rc' == 498
	qui timer list 77
	assert r(t77) < 20
	capture confirm file nwmk_a.mp4
	assert _rc != 0

	* (1)/(3) real run: count viewer processes before and after (counts only; other viewers may run)
	shell pgrep -f nwedit_viewer_ | wc -l > "`cnt'"
	tempname fh
	file open `fh' using "`cnt'", read text
	file read `fh' line
	file close `fh'
	local before = real(strtrim("`line'"))
	_nwmovie_screenlocked
	local locked = r(locked)
	if `locked' == 1 {
		* the screen really is locked: the check stops it (498)
		capture nwmovie mk_w1 mk_w2, fixedlayout export(nwmk_b.mp4) replace timeout(2)
		assert _rc == 498
		* and with the check bypassed the viewer cannot draw: the timeout path stops it with 498
		global NW_FAKE_LOCKED 0
		capture nwmovie mk_w1 mk_w2, fixedlayout export(nwmk_b.mp4) replace timeout(2)
		global NW_FAKE_LOCKED
		assert _rc == 498
		capture confirm file nwmk_b.mp4
		assert _rc != 0
	}
	else {
		nwmovie mk_w1 mk_w2, fixedlayout export(nwmk_b.mp4) replace timeout(120)
		confirm file nwmk_b.mp4
	}
	sleep 1500
	shell pgrep -f nwedit_viewer_ | wc -l > "`cnt'"
	file open `fh' using "`cnt'", read text
	file read `fh' line
	file close `fh'
	assert real(strtrim("`line'")) <= `before'
	capture erase nwmk_a.mp4
	capture erase nwmk_b.mp4
	cd "`oldpwd'"
}

di "PASS test_nwmovie_kill"
