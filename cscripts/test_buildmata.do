* nwinstall, buildmata(): compile the core Mata library from the source of this checkout with the running Stata and install it into a
* scratch folder with dest(); buildfrom() points to a folder with one subfolder per package (here a link to this checkout).
* Run from the repository root. The build takes a few minutes (the core source has ~13,000 lines).
cscript
capture program drop nwinstall
capture program drop nwinstall_buildmata
capture program drop nwinstall_buildmata_run
capture program drop nwinstall_buildmata_tab
local here `"`c(pwd)'"'
local scratch "`c(tmpdir)'/nwbuildmatatest_`=subinstr("`c(current_time)'", ":", "", .)'_`=string(runiformint(100000, 999999))'"
mkdir "`scratch'"
mkdir "`scratch'/from"
mkdir "`scratch'/dest"
if "`c(os)'" == "Windows" {
	* a directory junction (no administrator rights needed); mklink is a command of cmd, which shell runs
	quietly shell mklink /J "`=subinstr("`scratch'/from/nwcommands", "/", char(92), .)'" "`=subinstr("`here'", "/", char(92), .)'"
}
else quietly shell ln -s "`here'" "`scratch'/from/nwcommands"
* data in memory: refused, nothing is touched
sysuse auto, clear
capture nwinstall, buildmata(nwcommands) buildfrom("`scratch'/from") dest("`scratch'/dest")
assert _rc == 4
clear
* an unknown package is refused
capture nwinstall, buildmata(nwxyz)
assert _rc == 198
* the core library is built and installed
nwinstall, buildmata(nwcommands) buildfrom("`scratch'/from") dest("`scratch'/dest")
confirm file "`scratch'/dest/lnwcommands.mlib"
assert `"`r(built)'"' == " lnwcommands"
assert `"`c(pwd)'"' == `"`here'"'
* the new library is usable: it is found first, and the class machinery works
adopath ++ "`scratch'/dest"
mata: mata mlib index
mata: mata which nws_create()
global NW_LIBCHECK_OK
_nwlibcheck
* the built library is not rebuilt over itself without keeping the old one
nwinstall, buildmata(nwcommands) buildfrom("`scratch'/from") dest("`scratch'/dest")
confirm file "`scratch'/dest/lnwcommands.mlib.prev"
adopath - "`scratch'/dest"
if "`c(os)'" == "Windows" {
	* remove the junction first (rmdir on a junction removes the link, not the checkout), then the scratch folder
	quietly shell rmdir "`=subinstr("`scratch'/from/nwcommands", "/", char(92), .)'"
	quietly shell rmdir /s /q "`=subinstr("`scratch'", "/", char(92), .)'"
}
else quietly shell rm -rf "`scratch'"
di as text "PASS test_buildmata"
