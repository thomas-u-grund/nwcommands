* nwinstall, localcopy all: copies the ado, help and dialog files, the Mata library, the plugins (from lib/plugins/<os>/, flattened)
* and nwinstall_buildplugin.ado into dest(); an offline computer gets the same files as a net install.
cscript
capture program drop nwinstall
local here `"`c(pwd)'"'
local dest "`c(tmpdir)'/nwlocalcopy_`=string(runiformint(100000, 999999))'"
mkdir "`dest'"
nwinstall, localcopy all from("`here'") dest("`dest'")
foreach f in nwinstall.ado nwinstall_buildplugin.ado nwinstall_models.ado nwset.ado nwset.sthlp lnwcommands.mlib nwgraph_macos.plugin nwgraph_unix.plugin nwgraph_windows.plugin nwedit_viewer_macos nwedit_viewer_unix nwedit_viewer_windows.exe {
	confirm file "`dest'/`f'"
}
capture confirm file "`dest'/plugins"
assert _rc != 0
quietly shell rm -rf "`dest'"
di as text "PASS test_localcopy"
