* Core plot commands (nwcug, nwqap, nwdyads, nwtriads, nwmotifs, nwmixing, nwtabulate, nwcorrelate, nwdiffuse): the plot options of the plot convention
* (name(), saving(), export(), graph options, noplot, plot for graph), the checks of options without plot, bad values, data untouched,
* title("") and, when the reference directory exists, that the default pictures are identical to those of the released core.
* Run from the repository root. Reference: run cscripts/nwcore_plots_defaults.do with the released core (global NWP_OUT) and set the environment
* variable NWCORE_PLOT_REF to that directory. Produce the reference after `cscript` (it changes the rendering state: PNG bytes differ without it).
cscript
set graphics off
local tmp `"`c(tmpdir)'/nwcore_plots_test"'
capture mkdir `"`tmp'"'
local nfail 0
run cscripts/nw_pngwidth.do
capture program drop nwp_ok
program define nwp_ok
	args what
	di as text "  PASS: `what'"
end
capture program drop nwp_files
program define nwp_files
	* nwp_files stub ext1 ext2 ...: the files exist and are then erased
	gettoken stub rest : 0
	foreach e of local rest {
		confirm file `"`stub'.`e'"'
		* every picture of this test is exported with width(300): the option must reach graph export
		if "`e'" == "png" nw_assertwidth `"`stub'.`e'"' 300
		erase `"`stub'.`e'"'
	}
end

* ---- default pictures unchanged: identical PNG files with the released core (reference directory from NWCORE_PLOT_REF)
local ref : env NWCORE_PLOT_REF
if `"`ref'"' == "" {
	di as text "  SKIPPED: default pictures vs released core (set NWCORE_PLOT_REF)"
}
else {
	global NWP_OUT `"`tmp'/defaults"'
	do cscripts/nwcore_plots_defaults.do
	local files cug qap dyads triads motifs mixing_plot mixing_eiplot tabulate2_plot tabulate3_plot tabulate3_eiplot correlate diffuse
	foreach f of local files {
		quietly checksum `"`ref'/`f'.png"'
		local c0 = r(checksum)
		local s0 = r(filelen)
		quietly checksum `"$NWP_OUT/`f'.png"'
		if `c0' != r(checksum) | `s0' != r(filelen) {
			di as error "  FAIL: default picture of `f' differs from the released core"
			local ++nfail
		}
	}
	if `nfail' == 0 nwp_ok "default pictures identical to the released core (`: word count `files'' commands)"
}
nwclear
set seed 20261120
nwrandom 12, prob(.3) name(n1)
nwrandom 12, prob(.3) name(n2)
generate byte x = mod(_n, 3) == 0
generate byte toa = 1 + mod(_n, 4)
generate double canary = _n * 2
local stat `"stat(nwcomponents ##net##, generate(_ccomp) replace) rname(components) reps(30) seed(1)"'

* ---- nwcug
nwcug n1, `stat' plot name(t_cug) saving(`"`tmp'/cug"') export(`"`tmp'/cug.png"', width(300)) xlabel(none) title("")
graph describe t_cug
nwp_files `"`tmp'/cug"' gph
nwp_files `"`tmp'/cug"' png
assert canary == _n * 2
nwcug n1, `stat' plot
graph describe cug
capture nwcug n1, `stat' saving(`"`tmp'/x"')
assert _rc == 198
capture nwcug n1, `stat' export(`"`tmp'/x.png"')
assert _rc == 198
capture nwcug n1, `stat' xlabel(none)
assert _rc == 198
nwcug n1, `stat' name(ignored)
capture nwcug n1, `stat' plot name(a b)
assert _rc == 198
capture nwcug n1, `stat' plot saving(`"`tmp'/x"', append)
assert _rc == 198
nwp_ok "nwcug"

* ---- nwqap (graph saving is gsaving(): saving of the data is save())
nwqap n1 n2, permutations(20) type(regress) plot name(t_qap) gsaving(`"`tmp'/qap"') export(`"`tmp'/qap.png"', width(300)) title("")
graph describe t_qap
nwp_files `"`tmp'/qap"' gph
nwp_files `"`tmp'/qap"' png
assert canary == _n * 2
nwqap n1 n2, permutations(20) type(regress) plot
graph describe qap
capture nwqap n1 n2, permutations(20) type(regress) gsaving(`"`tmp'/x"')
assert _rc == 198
capture nwqap n1 n2, permutations(20) type(regress) export(`"`tmp'/x.png"')
assert _rc == 198
capture nwqap n1 n2, permutations(20) type(regress) xlabel(none)
assert _rc == 198
capture nwqap n1 n2, permutations(20) type(regress) plot name(a b)
assert _rc == 198
nwp_ok "nwqap"

* ---- nwdyads, nwtriads, nwmotifs
foreach c in dyads triads motifs {
	nw`c' n1, plot name(t_`c') saving(`"`tmp'/`c'"', replace) export(`"`tmp'/`c'.png"', width(300)) title("")
	graph describe t_`c'
	nwp_files `"`tmp'/`c'"' gph
	nwp_files `"`tmp'/`c'"' png
	assert canary == _n * 2
	nw`c' n1, plot
	graph describe `c'
	capture nw`c' n1, saving(`"`tmp'/x"')
	assert _rc == 198
	capture nw`c' n1, export(`"`tmp'/x.png"')
	assert _rc == 198
	capture nw`c' n1, xlabel(none)
	assert _rc == 198
	capture nw`c' n1, plot name(a b)
	assert _rc == 198
	capture nw`c' n1, plot saving(`"`tmp'/nodir/x"')
	assert _rc == 603
	capture nw`c' n1, plot nosuchoption(1)
	assert _rc != 0
	nw`c' n1, name(ignored)
	nwp_ok "nw`c'"
}
* two-mode motifs with plot stop as before
nwclear
nwrandom 12, prob(.3) name(n1)
nwrandom 12, prob(.3) name(n2)
generate byte x = mod(_n, 3) == 0
generate byte toa = 1 + mod(_n, 4)
generate double canary = _n * 2

* ---- nwmixing and nwtabulate: two pictures, name_plot and name_eiplot
foreach call in "nwmixing n1, attribute(x)" "nwtabulate n1, attribute(x)" {
	local stub = cond(substr("`call'", 1, 8) == "nwmixing", "mx", "tb")
	set seed 9
	`call' plot eiplot permutations(20) name(t_`stub') saving(`"`tmp'/`stub'"') export(`"`tmp'/`stub'.png"', width(300))
	graph describe t_`stub'_plot
	graph describe t_`stub'_eiplot
	foreach g in plot eiplot {
		nwp_files `"`tmp'/`stub'_t_`stub'_`g'"' gph png
	}
	assert canary == _n * 2
	set seed 9
	`call' plot permutations(20) name(t_`stub'1) saving(`"`tmp'/`stub'1"') export(`"`tmp'/`stub'1.png"', width(300))
	graph describe t_`stub'1_plot
	nwp_files `"`tmp'/`stub'1"' gph png
	set seed 9
	`call' eiplot permutations(20) name(t_`stub'2) saving(`"`tmp'/`stub'2"')
	graph describe t_`stub'2_eiplot
	nwp_files `"`tmp'/`stub'2"' gph
	set seed 9
	`call' plot eiplot permutations(20) plotoptions(title("my title")) eiplotoptions(title("my ei title"))
	capture `call' permutations(20) saving(`"`tmp'/x"')
	assert _rc == 198
	capture `call' permutations(20) export(`"`tmp'/x.png"')
	assert _rc == 198
	capture `call' permutations(20) name(x)
	assert _rc == 198
	capture `call' plot permutations(20) name(a b)
	assert _rc == 198
}
nwtabulate n1 n2, plot name(t_tb3) saving(`"`tmp'/tb3"') export(`"`tmp'/tb3.png"', width(300))
graph describe t_tb3_plot
nwp_files `"`tmp'/tb3"' gph png
nwp_ok "nwmixing and nwtabulate"

* ---- nwcorrelate: plot with permutations() > 1 as before, noplot, name/saving/export
set seed 3
nwcorrelate n1 n2, permutations(20) name(t_cor) saving(`"`tmp'/cor"') export(`"`tmp'/cor.png"', width(300)) title("")
graph describe t_cor
nwp_files `"`tmp'/cor"' gph png
assert canary == _n * 2
nwcorrelate n1 n2, permutations(20)
capture graph drop t_none
nwcorrelate n1 n2, permutations(20) noplot name(t_none)
capture graph describe t_none
assert _rc != 0
capture nwcorrelate n1 n2, permutations(20) noplot saving(`"`tmp'/x"')
assert _rc == 198
capture nwcorrelate n1 n2, saving(`"`tmp'/x"')
assert _rc == 198
capture nwcorrelate n1 n2, permutations(20) name(a b)
assert _rc == 198
nwcorrelate n1 n2
nwp_ok "nwcorrelate"

* ---- nwdiffuse curve: plot is a synonym of graph
nwdiffuse curve n1, toa(toa) plot name(t_dif) saving(`"`tmp'/dif"') export(`"`tmp'/dif.png"', width(300)) title("")
graph describe t_dif
nwp_files `"`tmp'/dif"' gph png
assert canary == _n * 2
nwdiffuse curve n1, toa(toa) graph silent
nwdiffuse curve n1, toa(toa) silent name(ignored)
capture nwdiffuse curve n1, toa(toa) silent saving(`"`tmp'/x"')
assert _rc == 198
capture nwdiffuse curve n1, toa(toa) silent export(`"`tmp'/x.png"')
assert _rc == 198
capture nwdiffuse curve n1, toa(toa) plot name(a b)
assert _rc == 198
nwp_ok "nwdiffuse"

* ---- nwplotmatrix and nwdendrogram: name(), saving(), export() added; unnamed unless one is given
nwclear
nwset, mat((0,1,0,1\1,0,1,0\0,1,0,1\1,0,1,0)) name(net1) undirected labs(A,B,C,D)
nwplotmatrix net1, name(t_pm) saving(`"`tmp'/pm"') export(`"`tmp'/pm.png"', width(300))
graph describe t_pm
nwp_files `"`tmp'/pm"' gph png
nwplotmatrix net1, export(`"`tmp'/pm2.png"', width(300))
graph describe plotmatrix
nwp_files `"`tmp'/pm2"' png
capture nwplotmatrix net1, name(a b)
assert _rc == 198
nwhierarchy net1
nwdendrogram, name(t_dg) saving(`"`tmp'/dg"') export(`"`tmp'/dg.png"', width(300))
graph describe t_dg
nwp_files `"`tmp'/dg"' gph png
capture nwdendrogram, saving(`"`tmp'/nodir/x"')
assert _rc == 603
nwp_ok "nwplotmatrix and nwdendrogram"

* ---- nwcoefplot and nwcompare: export() with width(), also as the double-quoted string some callers pass; two widths each
capture program drop nwp_fake
program define nwp_fake, eclass
	matrix b = (0.4, -0.3, 0.4)
	matrix V = I(3) * 0.04
	matrix colnames b = edges mutual tie
	matrix colnames V = edges mutual tie
	matrix rownames V = edges mutual tie
	ereturn post b V, obs(50)
	ereturn local cmd "nwergm"
end
nwp_fake
estimates store nwp_f1
foreach w in 500 700 {
	nwcoefplot nwp_f1, export(`"`tmp'/cp`w'.png"', width(`w')) name(t_cp, replace)
	nw_assertwidth `"`tmp'/cp`w'.png"' `w'
	nwcompare nwp_f1 nwp_f1, graph name(t_cmp, replace) export(`"`tmp'/cmp`w'.png"', width(`w'))
	nw_assertwidth `"`tmp'/cmp`w'.png"' `w'
	nwcompare nwp_f1 nwp_f1, graph coefopts(export(`"`tmp'/cmpc`w'.png"', width(`w')))
	nw_assertwidth `"`tmp'/cmpc`w'.png"' `w'
	erase `"`tmp'/cp`w'.png"'
	erase `"`tmp'/cmp`w'.png"'
	erase `"`tmp'/cmpc`w'.png"'
}
* the width really changes the picture (the failure of the double-quoted style was a silent 720 x 432)
nwclear
nwrandom 12, prob(.3) name(n1)
nwcug n1, `stat' plot export(`"`tmp'/w1.png"', width(500))
nwcug n1, `stat' plot export(`"`tmp'/w2.png"', width(900))
nw_assertwidth `"`tmp'/w1.png"' 500
nw_assertwidth `"`tmp'/w2.png"' 900
erase `"`tmp'/w1.png"'
erase `"`tmp'/w2.png"'
nwp_ok "nwcoefplot and nwcompare: export width in pixels"

* ---- the dialogs of the plot commands load (batch mode: db returns r(8005), not testable there)
foreach d in nwcug nwqap nwdyads nwtriads nwmixing nwtabulate nwcorrelate nwcoefplot nwcompare {
	capture db `d'
	if _rc == 8005 di as text "  SKIPPED: db `d' (no GUI in batch mode, r(8005))"
	else if _rc {
		di as error "  FAIL: db `d' returned r(" _rc ")"
		local ++nfail
	}
}
if `nfail' == 0 nwp_ok "dialogs load (or skipped in batch mode)"
if `nfail' > 0 exit 9
di as text "ALL TESTS PASSED"
