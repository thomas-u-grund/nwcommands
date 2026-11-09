* nwinstall, buildplugin(): compile the core plugin nwgraph from the source of this checkout on this computer (macOS, Linux or Windows)
* and install it into a scratch folder with dest(); buildfrom() points to a folder with one subfolder per package (here a link to this
* checkout). On Windows without Microsoft's C compiler the command must stop with r(601) and say what to install.
cscript
capture program drop nwinstall
capture program drop nwinstall_buildplugin
local here `"`c(pwd)'"'
local scratch "`c(tmpdir)'/nwbuildtest_`=subinstr("`c(current_time)'", ":", "", .)'_`=string(runiformint(100000, 999999))'"
mkdir "`scratch'"
mkdir "`scratch'/from"
mkdir "`scratch'/dest"
local win = ("`c(os)'" == "Windows")
if `win' quietly shell mklink /J "`=subinstr("`scratch'/from/nwcommands", "/", char(92), .)'" "`=subinstr("`here'", "/", char(92), .)'"
else quietly shell ln -s "`here'" "`scratch'/from/nwcommands"
capture noisily nwinstall, buildplugin(nwcommands) buildfrom("`scratch'/from") dest("`scratch'/dest")
if `win' & _rc == 601 {
	* no compiler on this Windows computer: the message was shown, nothing was installed
	capture confirm file "`scratch'/dest/nwgraph_windows.plugin"
	assert _rc != 0
	quietly shell rmdir "`=subinstr("`scratch'/from/nwcommands", "/", char(92), .)'"
	quietly shell rmdir /s /q "`=subinstr("`scratch'", "/", char(92), .)'"
	di as text "PASS test_buildplugin (Windows without the C compiler: the message is shown)"
	exit
}
assert _rc == 0
local plat = cond("`c(os)'" == "MacOSX", "macos", cond(`win', "windows", "unix"))
confirm file "`scratch'/dest/nwgraph_`plat'.plugin"
assert `"`r(plugin_nwcommands)'"' == `"`scratch'/dest/nwgraph_`plat'.plugin"'
* a second run keeps the first plugin as .prev
nwinstall, buildplugin(nwcommands) buildfrom("`scratch'/from") dest("`scratch'/dest")
confirm file "`scratch'/dest/nwgraph_`plat'.plugin.prev"
* an unknown package is refused
capture nwinstall, buildplugin(nwxyz)
assert _rc == 198
if `win' {
	quietly shell rmdir "`=subinstr("`scratch'/from/nwcommands", "/", char(92), .)'"
	quietly shell rmdir /s /q "`=subinstr("`scratch'", "/", char(92), .)'"
}
else quietly shell rm -rf "`scratch'"
di as text "PASS test_buildplugin"
