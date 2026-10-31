* nwinstall, buildplugin(): compile the core plugin nwgraph from the source of this checkout on this computer (macOS or Linux) and install
* it into a scratch folder with dest(); buildfrom() points to a folder with one subfolder per package (here a link to this checkout).
cscript
if !inlist("`c(os)'", "MacOSX", "Unix") {
	di as text "skipped: nwinstall, buildplugin() builds on macOS and Linux only"
	di as text "PASS test_buildplugin (skipped on `c(os)')"
	exit
}
capture program drop nwinstall
capture program drop nwinstall_buildplugin
local here `"`c(pwd)'"'
local scratch "`c(tmpdir)'/nwbuildtest_`=string(runiformint(100000, 999999))'"
mkdir "`scratch'"
mkdir "`scratch'/from"
mkdir "`scratch'/dest"
quietly shell ln -s "`here'" "`scratch'/from/nwcommands"
nwinstall, buildplugin(nwcommands) buildfrom("`scratch'/from") dest("`scratch'/dest")
local plat = cond("`c(os)'" == "MacOSX", "macos", "unix")
confirm file "`scratch'/dest/nwgraph_`plat'.plugin"
assert `"`r(plugin_nwcommands)'"' == `"`scratch'/dest/nwgraph_`plat'.plugin"'
* a second run keeps the first plugin as .prev
nwinstall, buildplugin(nwcommands) buildfrom("`scratch'/from") dest("`scratch'/dest")
confirm file "`scratch'/dest/nwgraph_`plat'.plugin.prev"
* an unknown package is refused
capture nwinstall, buildplugin(nwxyz)
assert _rc == 198
quietly shell rm -rf "`scratch'"
di as text "PASS test_buildplugin"
