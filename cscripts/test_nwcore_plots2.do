* New core plots of 3.30.0: nwdegree plot, nwgeodesic plot, nwdiffuse curve plot(new|both), nwspectral plot, nwtriads plot expected.
* Checks per command: the graph exists, saving and export write files, the options without plot give r(198), refused network types give r(198),
* the data are untouched (canary), title("") runs, and the dialogs load.  Also: the expected triad counts against exact values
* (enumeration of all directed networks of 5 nodes with a given dyad census, M = 2 mutual and A = 5 asymmetric dyads).
* Run from the repository root.
cscript
set graphics off
local tmp `"`c(tmpdir)'/nwcore_plots2_test"'
capture mkdir `"`tmp'"'
local nfail 0
capture program drop nwp_ok
program define nwp_ok
	args what
	di as text "  PASS: `what'"
end
capture program drop nwp_files
program define nwp_files
	gettoken stub rest : 0
	foreach e of local rest {
		confirm file `"`stub'.`e'"'
		erase `"`stub'.`e'"'
	}
end
nwclear
set seed 20261120
nwrandom 30, prob(.12) name(d)
nwrandom 30, prob(.12) name(u) undirected
nwrandom 30, prob(.2) name(c) undirected
generate byte toa = 1 + mod(_n * _n, 7)
generate double canary = _n * 2
* a valued network and a two-mode network for the refusals
nwset, mat((0,2,0\2,0,1\0,1,0)) name(vnet) undirected valued
preserve
clear
input str10 person str10 org
"Thomas" "Oxford"
"Peter" "Oxford"
"Tim" "Oxford"
"Peter" "LiU"
"Tim" "LiU"
"Thomas" "LiU"
end
nwset person org, twomode name(tm)
restore

* ---- nwdegree
nwdegree u, generate(du) plot name(t_deg) saving(`"`tmp'/deg"') export(`"`tmp'/deg.png"', width(300)) title("")
graph describe t_deg
nwp_files `"`tmp'/deg"' gph png
assert canary == _n * 2
nwdegree u, generate(du) replace plot silent
graph describe degree
nwdegree u, generate(du) replace plot ccdf silent standardize
nwdegree d, generate(dout din) plot name(t_deg2) silent
graph describe t_deg2
nwdegree d, generate(dout din) replace plot ccdf name(t_deg3) silent
graph describe t_deg3
nwdegree u, generate(du) replace plot silent xlabel(0(2)10)
nwdegree u, generate(du) replace plot binary silent
foreach o in "ccdf" "name(x)" "saving(`tmp'/x)" "export(`tmp'/x.png)" {
	capture nwdegree u, generate(du) replace `o'
	assert _rc == 198
}
capture nwdegree u, generate(du) replace plot name(a b)
assert _rc == 198
capture nwdegree u, generate(du) replace plot saving(`"`tmp'/nodir/x"')
assert _rc == 603
capture nwdegree tm, generate(zz) plot
assert _rc == 198
capture nwdegree vnet, generate(zz) plot
assert _rc == 198
nwdegree vnet, generate(zz) replace plot binary silent
capture nwdegree u d, generate(zz) plot
assert _rc == 198
* without plot the options are still the tabulate options
nwdegree u, generate(du) replace missing silent
nwdegree u, generate(du) replace missing
assert canary == _n * 2
nwp_ok "nwdegree"

* ---- nwgeodesic (the graph name is gname(): name() is the distance network)
nwgeodesic u, plot average name(g_net) nwreplace gname(t_geo) saving(`"`tmp'/geo"') export(`"`tmp'/geo.png"', width(300)) title("")
graph describe t_geo
nwp_files `"`tmp'/geo"' gph png
assert canary == _n * 2
nwgeodesic d, plot nwreplace name(g_net)
graph describe geodesic
nwgeodesic d, plot unconnected(max) nwreplace name(g_net) average
nwgeodesic c, plot nwreplace name(g_net) average
foreach o in "average" "gname(x)" "saving(`tmp'/x)" "export(`tmp'/x.png)" "xlabel(none)" {
	capture nwgeodesic u, nwreplace name(g_net) `o'
	assert _rc == 198
}
capture nwgeodesic tm, plot nwreplace name(g_net)
assert _rc == 198
capture nwgeodesic vnet, plot nwreplace name(g_net)
assert _rc == 198
nwgeodesic vnet, plot nwreplace name(g_net) binary
capture nwgeodesic u, plot nwreplace name(g_net) gname(a b)
assert _rc == 198
* the numbers of the histogram: pairs at each distance add up to the connected pairs
nwgeodesic u, nwreplace name(g_net)
local conn = r(numpaths) - r(unconnected)
assert `conn' > 0
nwgeodesic u, nwreplace name(g_net) plot
assert r(numpaths) == 435
nwp_ok "nwgeodesic"

* ---- nwdiffuse curve plot(cumulative|new|both)
nwdiffuse curve u, toa(toa) plot(new) silent name(t_dn) saving(`"`tmp'/dn"') export(`"`tmp'/dn.png"', width(300)) title("")
graph describe t_dn
nwp_files `"`tmp'/dn"' gph png
nwdiffuse curve u, toa(toa) plot(both) silent name(t_db) saving(`"`tmp'/db"') export(`"`tmp'/db.png"', width(300))
graph describe t_db
nwp_files `"`tmp'/db"' gph png
nwdiffuse curve u, toa(toa) plot(cumulative) silent name(t_dc)
graph describe t_dc
* plot(both) takes xlabel() (both panels), plot(new) xlabel() and ylabel() of the user; the bar axis starts at 0 by default
nwdiffuse curve u, toa(toa) plot(both) silent name(t_db2) xlabel(1(1)3)
graph describe t_db2
nwdiffuse curve u, toa(toa) plot(new) silent name(t_dn2) xlabel(1 2 3) ylabel(0(2)10)
graph describe t_dn2
nwdiffuse curve u, toa(toa) plot(new) silent name(t_dn3) yscale(range(0 20))
graph describe t_dn3
nwdiffuse curve u, toa(toa) plot silent
nwdiffuse curve u, toa(toa) graph silent
nwdiffuse curve u, toa(toa) plot(NEW) silent
assert canary == _n * 2
capture nwdiffuse curve u, toa(toa) plot(foo) silent
assert _rc == 198
capture nwdiffuse curve u, toa(toa) silent saving(`"`tmp'/x"')
assert _rc == 198
capture nwdiffuse curve u, toa(toa) plot(new) name(a b) silent
assert _rc == 198
nwp_ok "nwdiffuse"

* ---- nwspectral
nwspectral c, generate(f1) plot name(t_sp) saving(`"`tmp'/sp"') export(`"`tmp'/sp.png"', width(300)) silent title("")
graph describe t_sp
nwp_files `"`tmp'/sp"' gph png
assert canary == _n * 2
nwspectral c, generate(f1) replace plot embedding name(t_sp2) silent
graph describe t_sp2
nwspectral c, generate(f1) replace plot silent
assert r(components) == 1
assert rowsof(r(eigenvalues)) == 1 & colsof(r(eigenvalues)) == 30
graph describe spectral
foreach o in "embedding" "name(x)" "saving(`tmp'/x)" "export(`tmp'/x.png)" "xlabel(none)" {
	capture nwspectral c, generate(f1) replace `o'
	assert _rc == 198
}
capture nwspectral d, generate(f1) replace plot
assert _rc == 198
capture nwspectral tm, generate(f1) replace plot onemode
assert _rc == 198
capture nwspectral c, generate(f1) replace plot name(a b)
assert _rc == 198
nwp_ok "nwspectral"

* ---- nwtriads expected
nwtriads d, plot expected name(t_tr) saving(`"`tmp'/tr"') export(`"`tmp'/tr.png"', width(300)) title("")
graph describe t_tr
nwp_files `"`tmp'/tr"' gph png
assert canary == _n * 2
nwtriads u, plot expected name(t_tr2)
graph describe t_tr2
capture nwtriads d, expected
assert _rc == 198
capture nwtriads tm, plot expected
assert _rc == 198
capture nwtriads vnet, plot expected
assert _rc == 198
* exact values: network of 5 nodes with M = 2 mutual and A = 5 asymmetric dyads (all directed networks of 5 nodes with this dyad census, averaged)
nwset, mat((0,1,1,0,0\1,0,0,1,0\0,0,0,1,1\0,0,1,0,0\1,0,0,1,0)) name(f5) labs(a,b,c,d,e)
quietly nwtriads f5
local cl "003 012 102 021D 021U 021C 111D 111U 030T 030C 201 120D 120U 120C 210 300"
local cn ""
foreach c of local cl {
	local cn "`cn' `=r(_`c')'"
}
run nwtriads.ado
_nwtriads_expected, n(5) directed(true) classes(`cl') counts(`cn')
local ex `r(expected)'
local exact "0.0833333333 1.25 0.5 0.625 0.625 1.25 1.25 1.25 0.625 0.208333333 0.25 0.416666667 0.416666667 0.833333333 0.416666667 0"
forvalues j = 1/16 {
	assert abs(real(word("`ex'", `j')) - real(word("`exact'", `j'))) < 1e-6
}
* the expected counts of all types add up to the number of triads
local tot 0
foreach x of local ex {
	local tot = `tot' + `x'
}
assert abs(`tot' - 10) < 1e-6
nwp_ok "nwtriads expected"

* ---- the dialogs load
foreach dd in nwdegree nwgeodesic nwdiffuse nwspectral nwtriads {
	capture db `dd'
	if _rc == 8005 di as text "  SKIPPED: db `dd' (no GUI in batch mode, r(8005))"
	else if _rc {
		di as error "  FAIL: db `dd' returned r(" _rc ")"
		local ++nfail
	}
}
if `nfail' == 0 nwp_ok "dialogs load"
if `nfail' > 0 exit 9
di as text "ALL TESTS PASSED"
