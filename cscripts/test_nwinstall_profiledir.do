* nwinstall without path(): profile.do goes to the folder Stata reads at every start (macOS ~/Documents/Stata,
* Windows %USERPROFILE%, Unix PERSONAL), or to an existing profile.do there, in PERSONAL or in SITE;
* never to the current folder (before 3.17.3 it went to the current folder).
* Runs only when the environment variable HOME points to a scratch folder named in the global NWTEST_HOME, so that the
* real profile.do is never touched:  NWTEST_HOME=/tmp/x HOME=/tmp/x stata -b do cscripts/test_nwinstall_profiledir.do
cscript
capture program drop nwinstall
clear all
local home : environ HOME
local want : environ NWTEST_HOME
if `"`want'"' == "" | `"`home'"' != `"`want'"' {
	di as text "test_nwinstall_profiledir: skipped (HOME is not the scratch folder NWTEST_HOME)"
	exit
}
local core "`c(pwd)'"
foreach d in plus personal site run {
	capture mkdir "`home'/`d'"
}
sysdir set PLUS "`home'/plus"
sysdir set PERSONAL "`home'/personal/"
sysdir set SITE "`home'/site/"
cd "`home'/run"
adopath ++ "`core'"
local os = c(os)
if "`os'" == "Windows" local up : environ USERPROFILE
local target = cond("`os'" == "MacOSX", "`home'/Documents/Stata", cond("`os'" == "Windows", "`up'", "`home'/personal/"))
local target = subinstr("`target'/profile.do", "//", "/", .)

* 1. no profile.do anywhere: created in the home folder (created if missing), not in the current folder
capture confirm file "`target'"
assert _rc
nwinstall, gui
confirm file "`target'"
capture confirm file "`home'/run/profile.do"
assert _rc
* the line is there once
tempname h
file open `h' using "`target'", read text
file read `h' line
local n 0
while r(eof) == 0 {
	if strtrim(`"`line'"') == "nwinstall, usermenu" local ++n
	file read `h' line
}
file close `h'
assert `n' == 1

* 2. a second run edits the same file and adds nothing
nwinstall, gui
capture confirm file "`home'/run/profile.do"
assert _rc
file open `h' using "`target'", read text
file read `h' line
local n 0
while r(eof) == 0 {
	if strtrim(`"`line'"') == "nwinstall, usermenu" local ++n
	file read `h' line
}
file close `h'
assert `n' == 1

* 3. an existing profile.do in PERSONAL (none in the home folder) is the one that is edited
erase "`target'"
file open `h' using "`home'/personal/profile.do", write text replace
file write `h' "* mine" _n
file close `h'
nwinstall, gui
capture confirm file "`target'"
assert _rc
file open `h' using "`home'/personal/profile.do", read text
file read `h' line
assert `"`line'"' == "* mine"
file read `h' line
assert strtrim(`"`line'"') == "nwinstall, usermenu"
file close `h'

* 4. path() still decides when it is given (no menu line elsewhere)
erase "`home'/personal/profile.do"
capture mkdir "`home'/explicit"
nwinstall, gui path("`home'/explicit")
confirm file "`home'/explicit/profile.do"

di as result "test_nwinstall_profiledir: all checks passed"
