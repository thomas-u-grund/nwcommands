cscript

do unw_core.do

* Lists of networks (core 3.35.0, unreleased). Run from the repository root. PASS marker at the end.
*   B  nwgeodesic and nwclustering: a list of networks, save(file) one row per network, r() = last network
*   C  nwmixing notes, ntimes() of nwdyadprob and nwhomophily, nwsummarize notes, the missing-ties note of nwbetween, nwcloseness,
*      nwevcent, nwpagerank, nwdyads and nwmotifs
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
* run a command with the log on; every needle (separated by |) must be in the output
capture program drop _tn_log
program _tn_log
	args needles cmd
	tempfile lg
	qui log using `"`lg'"', text replace name(tnlog)
	capture noisily `cmd'
	local rc = _rc
	qui log close tnlog
	mata: st_local("__L", stritrim(invtokens(cat(st_local("lg"))')))
	local __rest `"`needles'"'
	while `"`__rest'"' != "" {
		gettoken one __rest : __rest, parse("|")
		if `"`one'"' == "|" continue
		if !strpos(`"`__L'"', `"`one'"') {
			di as err `"FAIL: the output of {`cmd'} does not contain "`one'""'
			exit 9
		}
	}
	exit `rc'
end
* the output must NOT contain the text
capture program drop _tn_not
program _tn_not
	args needle cmd
	tempfile lg
	qui log using `"`lg'"', text replace name(tnlog)
	capture noisily `cmd'
	local rc = _rc
	qui log close tnlog
	mata: st_local("__L", stritrim(invtokens(cat(st_local("lg"))')))
	if strpos(`"`__L'"', `"`needle'"') {
		di as err `"FAIL: the output of {`cmd'} contains "`needle'""'
		exit 9
	}
	exit `rc'
end
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


* ---------------------------------------------------------------- C. small items
nwclear
local m0 "0,1,1,0,0,0\1,0,1,1,0,0\1,1,0,1,0,0\0,1,1,0,1,0\0,0,0,1,0,1\0,0,0,0,1,0"
local mm "0,1,1,0,.,0\1,0,1,1,0,0\1,1,0,1,0,0\0,1,1,0,1,0\.,0,0,1,0,1\0,0,0,0,1,0"
local d0 "0,1,1,0,0,0\0,0,1,1,0,0\1,0,0,1,0,0\0,0,1,0,1,0\0,0,0,0,0,1\0,0,0,0,1,0"
local dm "0,1,1,0,.,0\0,0,1,1,0,0\1,0,0,1,0,0\0,0,1,0,1,0\.,0,0,0,0,1\0,0,0,0,1,0"
local v0 "0,2,3,0,0,0\2,0,1,4,0,0\3,1,0,1,0,0\0,4,1,0,5,0\0,0,0,5,0,1\0,0,0,0,1,0"
local vm "0,2,3,0,.,0\2,0,1,4,0,0\3,1,0,1,0,0\0,4,1,0,5,0\.,0,0,5,0,1\0,0,0,0,1,0"
nwset, mat((`m0')) name(u0) undirected
nwset, mat((`mm')) name(um) undirected
nwset, mat((`d0')) name(d0) directed
nwset, mat((`dm')) name(dm) directed
nwset, mat((`v0')) name(v0) undirected
nwset, mat((`vm')) name(vm) undirected
gen grp = mod(_n, 2)
gen xv = _n

* C1. nwmixing: how the table is read, missing ties
_tn_log "(undirected network)" "nwmixing u0, attribute(grp) permutations(1)"
_tn_not "missing ties treated" "nwmixing u0, attribute(grp) permutations(1)"
_tn_log "(directed network: the table counts every tie from ego (row) to alter (column))" "nwmixing d0, attribute(grp) permutations(1)"
_tn_log "(1 missing ties treated as 0)|(undirected network)" "nwmixing um, attribute(grp) permutations(1)"
_tn_log "(2 missing ties treated as 0)" "nwmixing dm, attribute(grp) permutations(1)"
qui nwmixing u0, attribute(grp) permutations(1)
local ei0 = r(EI_index)
qui nwmixing um, attribute(grp) permutations(1)
assert reldif(r(EI_index), `ei0') < 1e-12
* nwmixing takes one network
capture nwmixing u0 um, attribute(grp)
assert _rc != 0

* C2. ntimes() of nwdyadprob and nwhomophily (as nwrandom, nwsmall, nwring, nwpref)
nwdyadprob v0, name(dpn) ntimes(5)
assert wordcount("`r(netlist)'") == 5
forvalues i = 1/5 {
	qui nwsummarize dpn_`i'
	assert r(nodes) == 6
}
capture nwsummarize dpn_6
assert _rc != 0
nwdyadprob, mat(J(6,6,.4)) name(dpm) ntimes(3) undirected
assert "`r(netlist)'" == "dpm_1 dpm_2 dpm_3"
nwdyadprob, mat(J(6,6,.4)) name(dp1)
qui nwsummarize dp1
assert r(nodes) == 6
capture nwdyadprob, mat(J(6,6,.4)) name(dpx) ntimes(0)
assert _rc == 198
nwhomophily grp, homophily(1) density(.3) name(hom) ntimes(4) undirected
assert "`r(netlist)'" == "hom_1 hom_2 hom_3 hom_4"
nwgeodesic hom_*, save("`fd'")
_tn_load "`fd'"
frame res: assert _N == 4
nwhomophily grp, homophily(1) density(.3) name(hom1) undirected
qui nwsummarize hom1
assert r(nodes) == 6

* C3. nwsummarize: valued note, missing-ties note
_tn_log "(valued network: edges and density count every tie with a non-zero value; minimum and maximum are tie values)" "nwsummarize v0"
_tn_log "(1 missing ties are not counted as ties and not as pairs in the density)|(valued network" "nwsummarize vm"
_tn_log "(1 missing ties are not counted as ties and not as pairs in the density; the measures of detail treat them as 0)" "nwsummarize um, detail"
_tn_not "missing ties" "nwsummarize u0"
_tn_not "valued network" "nwsummarize u0"
_tn_not "missing ties" "nwsummarize um, silent"
nwsummarize u0 um, save("`fd'")
_tn_load "`fd'"
frame res: assert _N == 2

* C4. the missing-ties note of nwbetween, nwcloseness, nwevcent, nwpagerank, nwdyads, nwmotifs: printed with a missing tie and
* never without one; the results are the results of the same network with 0 in place of the missing tie
foreach p in u d {
	if "`p'" == "d" local k 2
	else local k 1
	_tn_log "(`k' missing ties treated as 0)" "nwbetween `p'm, generate(bm) replace"
	_tn_not "missing ties" "nwbetween `p'0, generate(b0) replace"
	_tn_log "(`k' missing ties treated as 0)" "nwcloseness `p'm, generate(cm fm nm) replace"
	_tn_not "missing ties" "nwcloseness `p'0, generate(c0 f0 n0) replace"
	_tn_log "(`k' missing ties treated as 0)" "nwevcent `p'm, generate(em) replace"
	_tn_not "missing ties" "nwevcent `p'0, generate(e0) replace"
	_tn_log "(`k' missing ties treated as 0)" "nwpagerank `p'm, generate(pm) replace"
	_tn_not "missing ties" "nwpagerank `p'0, generate(p0) replace"
	_tn_log "(`k' missing ties treated as 0)" "nwdyads `p'm"
	_tn_not "missing ties" "nwdyads `p'0"
	foreach pair in "b0 bm" "c0 cm" "e0 em" "p0 pm" {
		tokenize `pair'
		qui count if abs(`1' - `2') > 1e-9 | missing(`1') != missing(`2')
		assert r(N) == 0
	}
}
_tn_log "(1 missing ties treated as 0)" "nwmotifs um"
_tn_not "missing ties" "nwmotifs u0"
_tn_not "missing ties" "nwmotifs um, silent"
qui nwmotifs u0
local mo0 = r(_4_1)
qui nwmotifs um
di "motif census of the network with a missing tie equals that with 0: r(_4_1) = `mo0' = `r(_4_1)'"

di "PASS: test_core_netlist"
