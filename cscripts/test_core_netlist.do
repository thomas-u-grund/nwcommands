cscript

do unw_core.do

* Lists of networks (core 3.35.0, unreleased). Run from the repository root. PASS marker at the end.
*   B  nwgeodesic and nwclustering: a list of networks, save(file) one row per network, r() = last network
set linesize 255
local tol 1e-12
tempfile fg fc fd

capture program drop _tn_near
program _tn_near
	args x ref tol label
	if missing(`x') & missing(`ref') exit
	if missing(`x') | missing(`ref') | abs(`x' - `ref') > `tol' {
		di as err "FAIL: `label' (`x' against `ref')"
		exit 9
	}
end
* value of variable v in row k of the result data set held in frame res (-> scalar __tnv)
capture program drop _tn_get
program _tn_get
	args v k
	frame res: scalar __tnv = `v'[`k']
end
capture program drop _tn_load
program _tn_load
	args file
	capture frame drop res
	frame create res
	frame res: use `"`file'"'
end

capture program drop _tn_reload
program _tn_reload
	nwclear
	nwuse data/florentine, nwclear
	nwuse data/lazega, nwappend
	nwuse data/gahuku, nwappend
	nwuse data/davis, nwappend
	qui nwset
end
_tn_reload
ds
local uvars `r(varlist)'
_datasignature `uvars'
local sig0 `r(datasignature)'
qui describe
local N0 = r(N)

* ---------------------------------------------------------------- B1. nwgeodesic: a list, save()
nwgeodesic flomarriage lazega_adv gahuku, save("`fg'", replace)
assert "`r(netname)'" == "gahuku"
_tn_load "`fg'"
frame res {
	assert _N == 3
	assert name[1] == "flomarriage" & name[2] == "lazega_adv" & name[3] == "gahuku"
	confirm variable name directed valued nodes numpaths unconnected avgpath diameter radius alpha connected avgpath_connected diameter_connected
	assert directed[2] == 1 & directed[1] == 0 & valued[3] == 1 & valued[1] == 0
}
local k 0
foreach n in flomarriage lazega_adv gahuku {
	local ++k
	qui nwgeodesic `n'
	foreach v in nodes numpaths unconnected alpha {
		_tn_get `v' `k'
		_tn_near `r(`v')' `=scalar(__tnv)' `tol' "geodesic `v' `n'"
	}
	if r(unconnected) > 0 {
		* not defined over all pairs: missing in the data set (-1 in r())
		foreach v in avgpath diameter radius {
			_tn_get `v' `k'
			assert scalar(__tnv) == . & r(`v') == -1
		}
		foreach v in avgpath_connected diameter_connected connected {
			_tn_get `v' `k'
			_tn_near `r(`v')' `=scalar(__tnv)' `tol' "geodesic `v' `n'"
		}
	}
	else {
		foreach v in avgpath diameter radius {
			_tn_get `v' `k'
			_tn_near `r(`v')' `=scalar(__tnv)' `tol' "geodesic `v' `n'"
		}
		_tn_get connected `k'
		assert scalar(__tnv) == 1
	}
}

* r() after the list = the last network, as the single call
qui nwgeodesic flomarriage lazega_adv gahuku
local a1 = r(avgpath)
local u1 = r(unconnected)
local c1 = r(connected)
local d1 = r(diameter_connected)
qui nwgeodesic gahuku
assert r(avgpath) == `a1' & r(unconnected) == `u1' & r(connected) == `c1' & r(diameter_connected) == `d1'
assert "`r(netname)'" == "gahuku"

* a list without save() prints the table; one network with save() writes one row and prints as before
nwgeodesic lazega_adv flomarriage
nwgeodesic lazega_adv, save("`fd'")
_tn_load "`fd'"
frame res: assert _N == 1 & name[1] == "lazega_adv"

* options for ONE network are refused with a list; unknown network; bad save()
foreach o in "generate(x)" "name(zzz)" "plot" "xvars" {
	capture nwgeodesic flomarriage lazega_adv, `o'
	assert _rc == 198
}
capture nwgeodesic flomarriage nosuchnet
assert _rc != 0
capture nwgeodesic flomarriage lazega_adv, save(a, b)
assert _rc == 198

* options that apply to every network of the list: sym, binary, unconnected()
nwgeodesic lazega_adv flomarriage, sym unconnected(max) binary save("`fd'")
_tn_load "`fd'"
frame res: assert _N == 2
qui nwgeodesic lazega_adv, sym unconnected(max) binary
_tn_get avgpath 1
_tn_near `r(avgpath)' `=scalar(__tnv)' `tol' "sym unconnected avgpath"
qui nwgeodesic flomarriage, sym unconnected(max) binary
_tn_get diameter 2
_tn_near `r(diameter)' `=scalar(__tnv)' `tol' "sym unconnected diameter"

* ---------------------------------------------------------------- B2. nwclustering: a list, save()
nwclustering flomarriage lazega_adv gahuku davis, save("`fc'")
assert "`r(measure)'" == "binary"
local g4 = r(C_global)
local a4 = r(C_avg)
_tn_load "`fc'"
frame res {
	assert _N == 4
	confirm variable name directed valued twomode nodes measure level cluster_global cluster_avg nmissing
	assert name[4] == "davis" & twomode[4] == 1 & level[4] == 1 & twomode[1] == 0 & level[1] == .
	assert measure[3] == "arithmetic" & measure[1] == "binary" & measure[2] == "binary"
	assert directed[2] == 1 & directed[1] == 0 & valued[3] == 1
}
_tn_get cluster_global 4
_tn_near `g4' `=scalar(__tnv)' `tol' "r() of the last network (global)"
_tn_get cluster_avg 4
_tn_near `a4' `=scalar(__tnv)' `tol' "r() of the last network (avg)"
* canary: the list calls (geodesic and clustering, one-mode and two-mode, without generate()) never changed the variables or rows of the data in memory
_datasignature `uvars'
assert "`r(datasignature)'" == "`sig0'"
qui describe
assert r(N) == `N0'
local k 0
foreach n in flomarriage lazega_adv gahuku {
	local ++k
	qui nwclustering `n', generate(cl_`k')
	_tn_get cluster_global `k'
	_tn_near `r(cluster_global)' `=scalar(__tnv)' `tol' "clustering global `n'"
	_tn_get cluster_avg `k'
	_tn_near `r(cluster_avg)' `=scalar(__tnv)' `tol' "clustering avg `n'"
	local m`k' = r(measure)
	frame res: assert measure[`k'] == "`m`k''"
}

* two-mode: level(), the single call on a data set with one row per node
nwclustering davis, level(2) save("`fd'")
_tn_load "`fd'"
frame res: assert _N == 1 & level[1] == 2 & twomode[1] == 1
_tn_get cluster_avg 1
local savg = scalar(__tnv)
_tn_get cluster_global 1
local sglob = scalar(__tnv)
preserve
nwuse data/davis, nwclear
qui nwclustering davis, level(2) generate(cl_d2)
_tn_near `r(C_avg)' `savg' `tol' "two-mode level(2) avg"
_tn_near `r(C_global)' `sglob' `tol' "two-mode level(2) global"
restore
_tn_reload

* symmetrize and measure() apply to every network
nwclustering lazega_adv flomarriage, symmetrize save("`fd'")
_tn_load "`fd'"
qui nwclustering lazega_adv, symmetrize generate(cl_s)
_tn_get cluster_global 1
_tn_near `r(cluster_global)' `=scalar(__tnv)' `tol' "symmetrize global"
nwclustering flomarriage lazega_adv, measure(binary) silent save("`fd'")
_tn_load "`fd'"
frame res: assert _N == 2

* errors: options for ONE network refused with a list; unknown network; bad save(); an invalid measure
capture nwclustering flomarriage lazega_adv, generate(x)
assert _rc == 198
capture nwclustering davis flomarriage, ra
assert _rc == 198
capture nwclustering flomarriage nosuchnet
assert _rc != 0
capture nwclustering flomarriage lazega_adv, save(a, b)
assert _rc == 198
capture nwclustering flomarriage lazega_adv, measure(nonsense)
assert _rc != 0
* a directed network with a valued measure is still refused (as for a single network)
capture nwclustering lazega_adv flomarriage, measure(arithmetic)
assert _rc == 198

* ---------------------------------------------------------------- B3. the book: 20 networks from nwrandom / nwsmall
nwrandom 30, prob(.12) undirected name(draw) ntimes(20)
nwsmall 30, k(4) prob(.1) undirected name(sw) ntimes(20)
foreach stub in draw sw {
	nwgeodesic `stub'_*, save("`fg'")
	_tn_load "`fg'"
	frame res: assert _N == 20
	nwclustering `stub'_*, save("`fc'")
	capture frame drop res2
	frame create res2
	frame res2: use "`fc'"
	frame res2: assert _N == 20
	forvalues i = 1/20 {
		qui nwgeodesic `stub'_`i'
		frame res: scalar __tnrow = .
		frame res: forvalues r = 1/20 { 
			if name[`r'] == "`stub'_`i'" scalar __tnrow = `r'
		}
		local r = scalar(__tnrow)
		assert `r' < .
		foreach v in nodes numpaths unconnected alpha {
			_tn_get `v' `r'
			_tn_near `r(`v')' `=scalar(__tnv)' `tol' "`stub'_`i' geodesic `v'"
		}
		if r(unconnected) > 0 {
			foreach v in avgpath_connected diameter_connected connected {
				_tn_get `v' `r'
				_tn_near `r(`v')' `=scalar(__tnv)' `tol' "`stub'_`i' geodesic `v'"
			}
		}
		else {
			foreach v in avgpath diameter radius {
				_tn_get `v' `r'
				_tn_near `r(`v')' `=scalar(__tnv)' `tol' "`stub'_`i' geodesic `v'"
			}
		}
		qui nwclustering `stub'_`i', generate(cl_`stub'_`i')
		frame res2: scalar __tnrow = .
		frame res2: forvalues r = 1/20 {
			if name[`r'] == "`stub'_`i'" scalar __tnrow = `r'
		}
		local r = scalar(__tnrow)
		assert `r' < .
		frame res2: scalar __tnv = cluster_global[`r']
		_tn_near `r(cluster_global)' `=scalar(__tnv)' `tol' "`stub'_`i' clustering global"
		frame res2: scalar __tnv = cluster_avg[`r']
		_tn_near `r(cluster_avg)' `=scalar(__tnv)' `tol' "`stub'_`i' clustering avg"
	}
}

di "PASS: test_core_netlist"
