cscript

* nwmovie export(): the viewer that nwmovie started is stopped by its exact staged name (on a timeout, an error
* and after the export), and on macOS a locked screen is reported before the viewer is launched.
* The kill helper is tested with fake "viewers" (shell scripts named like the staged copies), no GUI needed.

capture program drop nwinstall
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

di "PASS test_nwmovie_kill"
