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

* --- viewer-alive check (Unix, fake viewer) and the WebM sniffer
if "`c(os)'" != "Windows" {
	local td "`c(tmpdir)'"
	if substr("`td'", -1, 1) != "/" local td "`td'/"
	local n = 500000 + int(runiform()*190000)
	local fv "`td'nwedit_viewer_`n'"
	tempname fh
	file open `fh' using "`fv'", write text replace
	file write `fh' "#!/bin/sh" _n "sleep 20" _n
	file close `fh'
	shell chmod +x "`fv'"
	_nwmovie_viewerlive "`fv'"
	assert r(live) == 0
	shell "`fv'" > /dev/null 2>&1 &
	sleep 1500
	_nwmovie_viewerlive "`fv'"
	assert r(live) == 1
	_nwmovie_killviewer "`fv'"
	sleep 800
	_nwmovie_viewerlive "`fv'"
	assert r(live) == 0
}
tempfile wf
mata: fh = fopen(st_local("wf"), "w"); fwrite(fh, char(26) + char(69)); fclose(fh)
* (a short file is not WebM; the real signature is checked on Linux/Windows by the export test)
mata: st_local("w", strofreal(_nwmovie_iswebm(st_local("wf"))))
assert "`w'" == "0"

* --- no display (Linux): export() stops with 498 before anything is launched
if "`c(os)'" == "Unix" {
	nwset, mat((0,1,0\1,0,0\0,0,0)) name(nd_w1) undirected labs(A,B,C)
	nwset, mat((0,1,1\1,0,0\1,0,0)) name(nd_w2) undirected labs(A,B,C)
	global NW_FAKE_NODISPLAY 1
	capture nwmovie nd_w1 nd_w2, fixedlayout export(`td'nwnd.mp4) replace timeout(30)
	local rc = _rc
	global NW_FAKE_NODISPLAY
	assert `rc' == 498
	capture confirm file `td'nwnd.mp4
	assert _rc != 0
}

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

* --- real export on Linux/Windows when a display exists (a file, or a clear error within the timeout; never a hang, no stray viewer)
if inlist("`c(os)'", "Unix", "Windows") & "$NW_NOREALEXPORT" == "" {
	local disp : environment DISPLAY
	if "`c(os)'" == "Windows" | "`disp'" != "" {
		nwset, mat((0,1,0\1,0,0\0,0,0)) name(re_w1) undirected labs(A,B,C)
		nwset, mat((0,1,1\1,0,0\1,0,0)) name(re_w2) undirected labs(A,B,C)
		local sd "`c(tmpdir)'"
		if substr("`sd'", -1, 1) != "/" & substr("`sd'", -1, 1) != "\" local sd "`sd'/"
		foreach e in gif mp4 {
			capture erase "`sd'nwre.`e'"
			capture erase "`sd'nwre.webm"
			timer clear 78
			timer on 78
			capture noisily nwmovie re_w1 re_w2, fixedlayout export(`sd'nwre.`e') replace timeout(120)
			local rc = _rc
			timer off 78
			qui timer list 78
			assert r(t78) < 150
			if `rc' == 0 {
				capture confirm file "`sd'nwre.`e'"
				local ok1 = (_rc == 0)
				capture confirm file "`sd'nwre.webm"
				assert `ok1' | _rc == 0
			}
			else assert `rc' == 498
			di "real export `e': rc=`rc'"
		}
		capture erase "`sd'nwre.gif"
		capture erase "`sd'nwre.mp4"
		capture erase "`sd'nwre.webm"
	}
}

di "PASS test_nwmovie_kill"
