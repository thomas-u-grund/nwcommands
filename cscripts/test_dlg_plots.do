* test_dlg_plots: the dialogs of every core command with a plot expose the plot options (plot/noplot/graph, name, saving or gsaving,
* export and the command's own plot options), each control is wired into the command program of the dialog, the dialog loads, and the
* command line a dialog emits runs.  Run from the repository root.  `db` cannot open a dialog in batch Stata: r(8005) is tolerated.
cscript
set graphics off
local tmp `"`c(tmpdir)'/nwdlg_plots_test"'
capture mkdir `"`tmp'"'

* ---- 1. static: dialog -> expected option() entries, and each control with option() is used in a program of the dialog
local exp_nwcug       plot name saving export
local exp_nwqap       plot name gsaving export
local exp_nwdyads     plot name saving export
local exp_nwtriads    plot expected name saving export
local exp_nwcorrelate noplot name saving export
local exp_nwmixing    eiplot plot name saving export
local exp_nwtabulate  plot eiplot name saving export
local exp_nwdiffuse   plot name saving export
local exp_nwdegree    plot ccdf name saving export
local exp_nwgeodesic  plot average gname saving export
local exp_nwspectral  plot embedding name saving export
local exp_nwcoefplot  name saving export
local exp_nwcompare   graph name saving export
local exp_nwdendrogram name saving export
local exp_nwplotmatrix saving export
local exp_nwplot      export
local exp_nwmovie     export
local nbad 0
tempname fh
foreach c in nwcug nwqap nwdyads nwtriads nwcorrelate nwmixing nwtabulate nwdiffuse nwdegree nwgeodesic nwspectral nwcoefplot nwcompare nwdendrogram nwplotmatrix nwplot nwmovie {
	local have ""
	local ids ""
	local body ""
	local incmd 0
	file open `fh' using "`c'.dlg", read text
	file read `fh' line
	while r(eof) == 0 {
		if regexm(`"`line'"', "^[ ]*(CHECKBOX|EDIT|FILE|COMBOBOX|VARNAME|SPINNER) +([a-z_0-9]+) .*option\(([a-z]+)\)") {
			local have `have' `=regexs(3)'
			local ids `ids' `=regexs(2)'
		}
		if regexm(`"`line'"', "^PROGRAM ") local incmd 1
		if `incmd' local body `"`body' `line'"'
		file read `fh' line
	}
	file close `fh'
	foreach o of local exp_`c' {
		if !`: list o in have' {
			di as error "FAIL: `c'.dlg has no control with option(`o')"
			local ++nbad
		}
	}
	* every control with option() appears in a program of the dialog (the dialog does not drop it)
	foreach id of local ids {
		if !regexm(`"`body'"', "\.`id'([ .]|$|\))") {
			di as error "FAIL: `c'.dlg: control `id' is not used in a program of the dialog"
			local ++nbad
		}
	}
	* the dialog loads (batch Stata cannot open it)
	capture db `c'
	if !inlist(_rc, 0, 8005) {
		di as error "FAIL: db `c' r(" _rc ")"
		local ++nbad
	}
}
assert `nbad' == 0
di as text "  PASS: dialog controls present and wired"

* ---- 2. the command line each dialog emits runs (options in the order and form of the dialog)
nwclear
set seed 20261120
nwrandom 12, prob(.3) name(n1)
nwrandom 12, prob(.3) name(n2)
nwrandom 12, prob(.3) name(u1) undirected
generate byte x = mod(_n, 3) == 0
generate byte toa = 1 + mod(_n, 4)
generate double canary = _n * 2
local stat `"stat(nwcomponents ##net##, generate(_ccomp) replace) rname(components) reps(30) seed(1)"'
local sv `"saving("`tmp'/g1")"'
local ex `"export("`tmp'/g1.png")"'
local files `"`tmp'/g1.gph `tmp'/g1.png"'
capture program drop dlg_run
program define dlg_run
	* dlg_run <graph name> <command>: runs the command line of a dialog; the graph exists; the files exist and are erased
	gettoken gn cmd : 0
	`cmd'
	if "`gn'" != "-" graph describe `gn'
	foreach f in g1.gph g1.png {
		capture confirm file `"`c(tmpdir)'/nwdlg_plots_test/`f'"'
		if _rc == 0 erase `"`c(tmpdir)'/nwdlg_plots_test/`f'"'
	}
end
dlg_run d_cug nwcug n1, `stat' plot name(d_cug) `sv' `ex'
dlg_run d_qap nwqap n1 n2, permutations(20) type(regress) plot name(d_qap) gsaving("`tmp'/g1") `ex'
dlg_run d_dy nwdyads n1, plot name(d_dy) `sv' `ex'
dlg_run d_tr nwtriads n1, plot expected name(d_tr) `sv' `ex'
dlg_run d_co nwcorrelate n1 n2, permutations(20) name(d_co) `sv' `ex'
dlg_run - nwcorrelate n1 n2, permutations(20) noplot
dlg_run d_mx_plot nwmixing n1, attribute(x) plot permutations(20) name(d_mx) `sv' `ex'
dlg_run d_mx_eiplot nwmixing n1, attribute(x) eiplot permutations(20) name(d_mx) `sv' `ex'
dlg_run d_tb_plot nwtabulate n1, attribute(x) plot name(d_tb) `sv' `ex'
dlg_run d_tb_eiplot nwtabulate n1, attribute(x) eiplot name(d_tb) `sv' `ex'
dlg_run d_df nwdiffuse curve n1, toa(toa) plot(both) silent name(d_df) `sv' `ex'
dlg_run d_dg nwdegree n1, generate(dgo dgi) replace plot ccdf name(d_dg) `sv' `ex'
dlg_run d_gd nwgeodesic n1, plot average gname(d_gd) `sv' `ex'
dlg_run d_sp nwspectral u1, generate(spp) replace plot embedding name(d_sp) `sv' `ex'
assert canary == _n * 2
nwclear
nwset, mat((0,1,0,1\1,0,1,0\0,1,0,1\1,0,1,0)) name(net1) undirected labs(A,B,C,D)
* nwplotmatrix: name comes from the Overall tab of the dialog as name(x, replace)
dlg_run d_pm nwplotmatrix net1, name(d_pm, replace) `sv' `ex'
nwhierarchy net1
dlg_run d_dd nwdendrogram, name(d_dd) `sv' `ex'
di as text "PASS test_dlg_plots"
