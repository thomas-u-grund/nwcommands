* nwinstall, everything: installs the core and the four model packages as one set; nwinstall, all installs the core only and prints a hint.
* Everything is installed from LOCAL folders into a scratch PLUS (nothing is downloaded, the real PLUS and profile.do are not touched).
* Run from the core folder, with the global NWMODELS set to a folder with the subfolders nwsaom nwergm nwdynam nwrem
* (default: the parent folder of the core), e.g.   global NWMODELS "/path/to/models"
* Logs through the version of Stata that runs it (the test is meant to be run under Stata 17 and Stata 18).
cscript
capture program drop nwinstall
capture program drop nwversion
capture program drop nwinstall_models
clear all
set linesize 240
capture program drop tcount
program tcount, rclass
	// number of "nwinstall, usermenu" lines and of all lines of a file
	syntax , file(string)
	tempname h
	local n = 0
	local tot = 0
	capture file open `h' using `"`file'"', read text
	if _rc == 0 {
		file read `h' line
		while r(eof) == 0 {
			local ++tot
			if strtrim(`"`line'"') == "nwinstall, usermenu" local ++n
			file read `h' line
		}
		file close `h'
	}
	return scalar n = `n'
	return scalar tot = `tot'
end

local core "`c(pwd)'"
if `"$NWMODELS"' == "" {
	local models = subinstr("`core'", "/" + substr("`core'", strrpos("`core'", "/") + 1, .), "", 1)
}
else local models `"$NWMODELS"'
tempfile marker
local scratch = subinstr("`marker'", "St", "nwie_", 1) + "_dir"
capture mkdir "`scratch'"
capture mkdir "`scratch'/plus"
capture mkdir "`scratch'/personal"
capture mkdir "`scratch'/prof"
capture mkdir "`scratch'/prof2"
capture mkdir "`scratch'/prof4"
sysdir set PLUS "`scratch'/plus"
sysdir set PERSONAL "`scratch'/personal"
cd "`scratch'"

* 1. the bootstrap package from the local folder
net install nwcommands, from("`core'/") replace
capture program drop nwinstall

* 2. all: core only, with the hint
log using "`scratch'/all.log", text replace name(allrun)
capture program drop nwinstall
nwinstall, all from("`core'") path("`scratch'/prof2")
log close allrun
capture confirm file "`scratch'/plus/n/nwdegree.ado"
assert _rc == 0
capture program drop nwinstall
tempname fh
local hint 0
file open `fh' using "`scratch'/all.log", read text
file read `fh' line
while r(eof) == 0 {
	if strpos(`"`line'"', "To also install the model packages type: nwinstall, models   (or nwinstall, everything)") local hint 1
	file read `fh' line
}
file close `fh'
assert `hint' == 1
* all (and everything) set up the menu once: one line in profile.do
tcount, file("`scratch'/prof2/profile.do")
assert r(n) == 1 & r(tot) == 1
foreach p in nwsaom nwergm nwdynam nwrem {
	capture confirm file "`scratch'/plus/`=substr("`p'",1,1)'/`p'.ado"
	assert _rc != 0
}

* 3. everything
log using "`scratch'/every.log", text replace name(everyrun)
nwinstall, everything from("`core'") modelsfrom("`models'") path("`scratch'/prof")
log close everyrun
foreach p in nwsaom nwergm nwdynam nwrem {
	capture confirm file "`scratch'/plus/`=substr("`p'",1,1)'/`p'.ado"
	assert _rc == 0
}
capture confirm file "`scratch'/plus/n/nwdegree.ado"
assert _rc == 0
local nver 0
local hint 0
file open `fh' using "`scratch'/every.log", read text
file read `fh' line
while r(eof) == 0 {
	foreach p in nwsaom nwergm nwdynam nwrem {
		if substr(strtrim(`"`line'"'), 1, strlen("`p'")) == "`p'" & strpos(`"`line'"', "not installed") == 0 & strpos(`"`line'"', "Installing") == 0 & regexm(`"`line'"', "[0-9]+\.[0-9]+\.[0-9]+") local ++nver
	}
	if strpos(`"`line'"', "To also install the model packages") local hint 1
	file read `fh' line
}
file close `fh'
assert `nver' == 4
assert `hint' == 0

* 3b. everything also sets up the menu: one line, said once; a second run does not add another
tcount, file("`scratch'/prof/profile.do")
assert r(n) == 1 & r(tot) == 1
local said 0
file open `fh' using "`scratch'/every.log", read text
file read `fh' line
while r(eof) == 0 {
	if strpos(`"`line'"', "Network Analysis menu: installed.") local ++said
	file read `fh' line
}
file close `fh'
assert `said' == 1
nwinstall, everything from("`core'") modelsfrom("`models'") path("`scratch'/prof")
tcount, file("`scratch'/prof/profile.do")
assert r(n) == 1 & r(tot) == 1
capture confirm file "`scratch'/prof/profile.do.nwinstall_bak"
assert _rc != 0

* 3c. nogui: everything without the menu and without touching any profile.do
log using "`scratch'/nogui.log", text replace name(noguirun)
nwinstall, everything nogui from("`core'") modelsfrom("`models'") path("`scratch'/prof4")
log close noguirun
capture confirm file "`scratch'/prof4/profile.do"
assert _rc != 0
local said 0
file open `fh' using "`scratch'/nogui.log", read text
file read `fh' line
while r(eof) == 0 {
	if strpos(`"`line'"', "not installed (nogui)") local said 1
	file read `fh' line
}
file close `fh'
assert `said' == 1

* 3d. remove takes the line out again (profile.do keeps its other content: here none) and leaves no second copy
nwinstall, remove path("`scratch'/prof")
tcount, file("`scratch'/prof/profile.do")
assert r(n) == 0 & r(tot) == 0
nwinstall, models remove
foreach p in nwsaom nwergm nwdynam nwrem {
	capture confirm file "`scratch'/plus/`=substr("`p'",1,1)'/`p'.ado"
	assert _rc != 0
}
capture confirm file "`scratch'/plus/n/nwdegree.ado"
assert _rc != 0
* the same set once more for the checks below
nwinstall, everything from("`core'") modelsfrom("`models'") path("`scratch'/prof")
tcount, file("`scratch'/prof/profile.do")
assert r(n) == 1 & r(tot) == 1

* nwversion lists five versions
nwversion
assert "`r(version)'" != ""

* 4. a model repository that cannot be reached: clear message, nothing installed
capture program drop nwinstall
capture mkdir "`scratch'/plus2"
sysdir set PLUS "`scratch'/plus2"
net install nwcommands, from("`core'/") replace
capture program drop nwinstall
capture nwinstall, everything from("`core'") modelsfrom("`scratch'/nonexistent") path("`scratch'/prof2")
assert _rc == 601
capture confirm file "`scratch'/plus2/n/nwdegree.ado"
assert _rc != 0

* 5. everything cannot be combined with modelpkg()
capture nwinstall, everything modelpkg(nwsaom)
assert _rc == 198

* 5b. a model that needs a newer core than the one being installed: stop before installing anything, name the package
foreach p in nwsaom nwergm nwdynam nwrem {
	capture mkdir "`scratch'/fake"
	capture mkdir "`scratch'/fake/`p'"
	copy "`models'/`p'/`p'.pkg" "`scratch'/fake/`p'/`p'.pkg", replace
}
tempname fi fo
file open `fi' using "`models'/nwsaom/nwsaom.pkg", read text
file open `fo' using "`scratch'/fake/nwsaom/nwsaom.pkg", write text replace
file read `fi' line
while r(eof) == 0 {
	if strpos(`"`line'"', "Requires nwcommands (core), version") local line "d Requires nwcommands (core), version 9.0.0 or later"
	file write `fo' `"`line'"' _n
	file read `fi' line
}
file close `fi'
file close `fo'
capture mkdir "`scratch'/plus3"
sysdir set PLUS "`scratch'/plus3"
net install nwcommands, from("`core'/") replace
capture program drop nwinstall
capture noisily nwinstall, everything from("`core'") modelsfrom("`scratch'/fake") path("`scratch'/prof2")
assert _rc == 498
capture confirm file "`scratch'/plus3/n/nwdegree.ado"
assert _rc != 0

display "NWINSTALL_EVERYTHING_OK (Stata " c(stata_version) ")"
