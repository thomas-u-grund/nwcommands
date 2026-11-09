* nwinstall puts the files that net install skips (page templates, JavaScript, native viewer) into the install folder,
* under their lib/ paths, so that nwmovie and nwplot, interactive work from an installed copy (bug up to 3.16.0:
* "required file not found: .../plus/n/nwmovie_template.html").
* Run from the core folder. Installs from this folder into a scratch PLUS; the real PLUS and profile.do are not touched.
cscript
capture program drop nwinstall
clear all
local core "`c(pwd)'"
local scratch "`c(tmpdir)'/nwanc_`=subinstr("`c(current_time)'", ":", "", .)'_`=string(runiformint(100000, 999999))'"
mkdir "`scratch'"
mkdir "`scratch'/plus"
mkdir "`scratch'/work"
sysdir set PLUS "`scratch'/plus"

* 1. the list in nwinstall_ancillary equals the f lines of _pkg_ado.txt that net install does not install
local want ""
tempname fh
file open `fh' using "`core'/_pkg_ado.txt", read
file read `fh' line
while r(eof) == 0 {
	if substr(`"`line'"', 1, 2) == "f " {
		local f = substr(`"`line'"', 3, .)
		if regexm("`f'", "\.(html|js|exe)$") | regexm("`f'", "nwedit_viewer_[a-z]+$") local want `want' `f'
	}
	file read `fh' line
}
file close `fh'
mata:
_anc_L = cat(st_local("core") + "/nwinstall.ado")
_anc_i = selectindex(strpos(_anc_L, "local files nwmovie_template.html"))[1]
_anc_s = ""
while (1) {
	_anc_s = _anc_s + " " + subinstr(subinstr(_anc_L[_anc_i], "local files", ""), "///", "")
	if (!strpos(_anc_L[_anc_i], "///")) break
	_anc_i++
}
st_local("have", stritrim(strtrim(subinstr(_anc_s, char(9), " "))))
mata drop _anc_L _anc_i _anc_s
end
local want : list sort want
local have : list sort have
di "manifest: `want'"
di "nwinstall: `have'"
assert `: list want === have'
di "PASS list of ancillary files matches _pkg_ado.txt"

* 2. install from this folder into the empty PLUS, from a working folder that is not the core
cd "`scratch'/work"
nwinstall, all from("`core'") path("`scratch'/work")
capture confirm file "`scratch'/work/nwmovie_template.html"
assert _rc != 0
di "PASS nothing is dropped into the working folder"

* 3. leave only the installed copy on the ado path
* (both spellings of the folder: on Windows c(pwd) has backslashes, a runner may have added it with slashes)
local plat = cond("`c(os)'" == "Windows", "windows", cond("`c(os)'" == "MacOSX", "macos", "unix"))
local core2 = subinstr("`core'", char(92), "/", .)
foreach c in "`core'" "`core2'" {
	foreach d in "`c'/lib/plugins/`plat'" "`c'/lib" "`c'" {
		capture adopath - "`d'"
	}
}
discard
capture mata: mata mlib index
findfile nwset.ado
assert strpos("`r(fn)'", "`scratch'/plus") == 1
local inst = substr("`r(fn)'", 1, strlen("`r(fn)'") - strlen("nwset.ado") - 1)
foreach f in nwmovie_template.html nwedit_template.html lib/vendor/cytoscape.min.js lib/vendor/gif.js lib/vendor/gif.worker.js lib/vendor/mp4-muxer.js lib/plugins/macos/nwedit_viewer_macos lib/plugins/windows/nwedit_viewer_windows.exe lib/plugins/unix/nwedit_viewer_unix {
	confirm file "`inst'/`f'"
}
di "PASS ancillary files installed under `inst'"

* 4. the commands find them
nwuse "`core'/data/glasgow", nwclear
nwplot glasgow1, interactive noopen fname("`scratch'/work/g1")
confirm file "`scratch'/work/g1.html"
di "PASS nwplot, interactive from the installed copy"
if "`c(os)'" == "MacOSX" {
	nwmovie glasgow1 glasgow2, duration(500) export("`scratch'/work/m.gif") replace timeout(300)
	confirm file "`scratch'/work/m.gif"
	di "PASS nwmovie, export() from the installed copy"
}
else {
	nwmovie glasgow1 glasgow2, duration(500) noopen fname("`scratch'/work/m")
	confirm file "`scratch'/work/m.html"
	di "PASS nwmovie from the installed copy"
}

* 5. remove takes them away again
nwinstall, remove path("`scratch'/work")
capture confirm file "`inst'/nwmovie_template.html"
assert _rc != 0
di "PASS nwinstall, remove erases the ancillary files"
cd "`core'"
