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
