* nwdiffuse: exposure, thresholds, adoption curve, hazard data, simulation (3.28.0)
* fixture (cscripts/nwdiffuse_fixture, made by make_fixture.R): R 4.6, netdiffuseR 1.25.1 exposure() and threshold()
clear all
set more off
nwclear
* ---- networks of the fixture ----
insheet using "cscripts/nwdiffuse_fixture/graph.csv", comma names double clear
mata:
st = st_sdata(., "graph")
GG = st_data(., ("t", "i", "j", "w"))
function nwtest_mk(string colvector gname, real matrix GG, string scalar g, real scalar t)
{
	real matrix M
	real scalar k
	M = J(15, 15, 0)
	for (k = 1; k <= rows(GG); k++) {
		if (gname[k] == g & GG[k, 1] == t) M[GG[k, 2], GG[k, 3]] = GG[k, 4]
	}
	return(M)
}
M1 = nwtest_mk(st, GG, "static", 0)
M2 = nwtest_mk(st, GG, "self", 0)
M3 = nwtest_mk(st, GG, "dyn", 1)
M4 = nwtest_mk(st, GG, "dyn", 2)
M5 = nwtest_mk(st, GG, "dyn", 3)
M6 = nwtest_mk(st, GG, "dyn", 4)
M7 = nwtest_mk(st, GG, "dyn", 5)
end
nwset, mat(M1) name(sv) directed valued
nwset, mat(M1 :!= 0) name(st) directed
nwset, mat(M2) name(sf) directed selfloop
forvalues i = 1/5 {
	local j = `i' + 2
	nwset, mat(M`j') name(dyn`i') directed
}
* ---- expected values ----
insheet using "cscripts/nwdiffuse_fixture/expected.csv", comma names double clear
mata: EXs = st_sdata(., "scenario")
mata: EX = st_data(., ("node", "period", "share", "count"))
insheet using "cscripts/nwdiffuse_fixture/toa.csv", comma names double clear
mata:
real scalar nwtest_cmp(string colvector sc, real matrix EX, string scalar s, string scalar stubshare, string scalar stubcount)
{
	real matrix E, X, Y
	real scalar t, bad
	real colvector rows_
	rows_ = selectindex(sc :== s)
	E = EX[rows_, .]
	bad = 0
	for (t = 3; t <= 7; t++) {
		X = select(E[., (1, 3, 4)], E[., 2] :== t)
		Y = st_data((1::15), stubshare + strofreal(t))
		if (any((X[., 2] :>= .) :!= (Y :>= .))) bad = bad + 1
		else if (any(Y :< .)) if (max(abs(select(X[., 2] - Y, Y :< .))) > 1e-9) bad = bad + 1
		Y = st_data((1::15), stubcount + strofreal(t))
		if (any((X[., 3] :>= .) :!= (Y :>= .))) bad = bad + 1
		else if (any(Y :< .)) if (max(abs(select(X[., 3] - Y, Y :< .))) > 1e-9) bad = bad + 1
	}
	return(bad)
}
end
local k = 0
foreach spec in static_out_st_._0 static_out_lag1_st_._1 static_in_st_incoming_0 static_valued_sv_valued_0 self_sf_self_0 {
	local sc ""
	local nets ""
	local opt ""
	local lag ""
	local sc "`=word(subinstr("`spec'", "_", " ", .), 1)'"
	local spec2 : subinstr local spec "_" " ", all
	local nw : word count `spec2'
	local lag : word `nw' of `spec2'
	local opt : word `=`nw'-1' of `spec2'
	local nets : word `=`nw'-2' of `spec2'
	local sc ""
	forvalues w = 1/`=`nw'-3' {
		local sc "`sc'`=cond("`sc'" == "", "", "_")'`: word `w' of `spec2''"
	}
	if "`opt'" == "." local opt ""
	nwdiffuse exposure `nets', toa(toa) generate(s_`sc'_) count(n_`sc'_) lag(`lag') `opt' replace
	assert r(t0) == 3 & r(t1) == 7 & r(periods) == 5
	mata: st_local("bad", strofreal(nwtest_cmp(EXs, EX, "`sc'", "s_`sc'_", "n_`sc'_")))
	assert `bad' == 0
	local ++k
}
* dynamic graphs: one network for each period
foreach spec in dynamic_out_0 dynamic_out_lag1_1 {
	local lag = substr("`spec'", -1, 1)
	local sc = substr("`spec'", 1, length("`spec'") - 2)
	nwdiffuse exposure dyn1 dyn2 dyn3 dyn4 dyn5, toa(toa) generate(s_`sc'_) count(n_`sc'_) lag(`lag') replace
	mata: st_local("bad", strofreal(nwtest_cmp(EXs, EX, "`sc'", "s_`sc'_", "n_`sc'_")))
	assert `bad' == 0
}
* thresholds
foreach lag in 0 1 {
	nwdiffuse threshold st, toa(toa) generate(thr`lag') count(thn`lag') lag(`lag')
	assert r(lag) == `lag'
	quietly count if abs(thr`lag' - th`lag') > 1e-9 & !missing(thr`lag') & !missing(th`lag')
	assert r(N) == 0
	quietly count if missing(thr`lag') != missing(th`lag')
	assert r(N) == 0
}
quietly count if !missing(thr0)
assert r(N) == 9
assert missing(thr0[3])
* count threshold is a count of adopting neighbours
assert thn0 == round(thn0) if !missing(thn0)

* ---- adoption curve ----
nwdiffuse curve, toa(toa) silent
matrix C = r(curve)
assert rowsof(C) == 5 & C[1,1] == 3 & C[5,1] == 7
assert C[5,2] == 9 & abs(C[5,3] - 9/15) < 1e-12
assert C[1,5] + C[2,5] + C[3,5] + C[4,5] + C[5,5] == 9
assert C[1,4] == 0
assert abs(C[3,4] - (C[3,2] - C[2,2]) / C[2,2]) < 1e-9
nwdiffuse curve st, toa(toa) silent t0(2) t1(8) matrix(CM)
assert rowsof(CM) == 7 & CM[1,2] == 0 & CM[7,2] == 9
assert r(t0) == 2 & r(t1) == 8
* adopt(): one 0/1 variable per period gives the same curve
forvalues t = 3/7 {
	generate byte a`t' = toa <= `t'
}
nwdiffuse curve, adopt(a3 a4 a5 a6 a7) t0(3) silent
matrix D = r(curve)
assert mreldif(C, D) < 1e-12
nwdiffuse exposure st, adopt(a3 a4 a5 a6 a7) t0(3) generate(w_) replace
forvalues t = 3/7 {
	assert abs(w_`t' - s_static_out_`t') < 1e-12 | (missing(w_`t') & missing(s_static_out_`t'))
}
nwdiffuse curve, toa(toa) graph silent

* ---- person-period data ----
preserve
quietly count if toa > 3 & toa < .
local nev = r(N)
nwdiffuse long st, toa(toa) clear keep(toa)
assert r(lag) == 1 & r(events) == `nev'
sort node period
* every adopter after the first period ends with its adoption; nobody is in the data before period 4 or after adopting
bysort node: egen mx = max(adopt)
assert (mx == 1) == (toa < .)
by node: assert adopt[_N] == (toa[_N] < .)
assert period <= toa | missing(toa)
assert period >= 4
quietly summarize exposure
assert r(N) == _N
restore
preserve
generate double age = node * 10
nwdiffuse long st, toa(toa) lag(0) keep(age) clear
assert r(events) == 9
assert age == node * 10
sort node period
quietly summarize period if node == 1
assert r(min) == 3 & r(max) == 3
quietly summarize period if node == 2
assert r(min) == 3 & r(max) == 7
restore

* ---- simulation: deterministic cases ----
nwclear
clear
set obs 6
gen byte seedv = _n == 1
* chain: node i has a tie to node i-1, so influence runs 1 -> 2 -> 3 ...
nwset, mat((0,0,0,0,0,0\1,0,0,0,0,0\0,1,0,0,0,0\0,0,1,0,0,0\0,0,0,1,0,0\0,0,0,0,1,0)) name(chain) directed
nwdiffuse simulate chain, model(cascade) prob(1) seedvar(seedv) generate(tc) steps(10)
assert tc == _n
assert r(adopters) == 6 & r(lastperiod) == 6
* with incoming ties the influence runs the other way: nobody follows node 1
nwdiffuse simulate chain, model(cascade) prob(1) seedvar(seedv) generate(tc) steps(10) incoming replace
assert r(adopters) == 1
* only a few steps
nwdiffuse simulate chain, model(cascade) prob(1) seedvar(seedv) generate(tc) steps(2) replace
assert r(adopters) == 3 & missing(tc[4])
* absolute threshold: node 4 follows nodes 1, 2 and 3
nwclear
clear
set obs 5
gen byte seedv = inlist(_n, 1, 2)
nwset, mat((0,0,0,0,0\0,0,0,0,0\1,0,0,0,0\1,1,1,0,0\0,0,0,1,0)) name(tri) directed
nwdiffuse simulate tri, model(threshold) threshold(2) seedvar(seedv) generate(tt) steps(5)
assert tt[1] == 1 & tt[2] == 1 & missing(tt[3]) & tt[4] == 2 & missing(tt[5])
nwdiffuse simulate tri, model(threshold) threshold(1) seedvar(seedv) generate(tt) steps(5) replace
assert tt[3] == 2 & tt[4] == 2 & tt[5] == 3
* fractional threshold: node 4 has three out-ties; two adopters are 2/3 of them
nwdiffuse simulate tri, model(fraction) threshold(0.7) seedvar(seedv) generate(tt) steps(5) replace
assert tt[3] == 2 & tt[4] == 3 & tt[5] == 4
nwdiffuse simulate tri, model(fraction) threshold(0.6) seedvar(seedv) generate(tt) steps(5) replace
assert tt[4] == 2 & tt[5] == 3
* thresholds of single nodes
gen double need = cond(_n == 3, 1, 3)
nwdiffuse simulate tri, model(threshold) thresholdvar(need) seedvar(seedv) generate(tt) steps(5) replace
assert tt[3] == 2 & tt[4] == 3
* spontaneous adoption only
nwdiffuse simulate tri, model(cascade) prob(0.5) spont(1) generate(ts) steps(3) replace
assert ts == 2
assert r(share) == 1
* one network for each step
nwset, mat((0,0,0,0,0\0,0,0,0,0\0,0,0,0,0\0,0,0,0,0\0,0,0,0,0)) name(empty) directed
nwdiffuse simulate empty tri, model(threshold) threshold(1) seedvar(seedv) generate(tt) steps(2) replace
assert tt[3] == 3 & missing(tt[5])
nwdiffuse simulate empty tri tri, model(threshold) threshold(1) seedvar(seedv) generate(tt) steps(3) replace
assert tt[3] == 3 & tt[4] == 3 & tt[5] == 4
* random: reproducible, number of seeds
nwclear
clear
set obs 300
nwrandom 300, prob(0.03) name(rnd) directed
nwdiffuse simulate rnd, model(cascade) prob(0.2) nseeds(5) seed(11) generate(r1) steps(30)
local a1 = r(adopters)
quietly count if r1 == 1
assert r(N) == 5
nwdiffuse simulate rnd, model(cascade) prob(0.2) nseeds(5) seed(11) generate(r2) steps(30)
assert r(adopters) == `a1'
assert r1 == r2 | (missing(r1) & missing(r2))
nwdiffuse simulate rnd, model(cascade) prob(0.2) nseeds(5) seed(12) generate(r3) steps(30)
nwdiffuse simulate rnd, model(cascade) prob(0.0001) nseeds(5) seed(11) generate(r4) steps(30)
assert r(adopters) < `a1'
nwdiffuse simulate rnd, model(cascade) prob(1) nseeds(1) spont(0.01) seed(3) generate(r5) steps(5)
nwdiffuse simulate rnd, model(fraction) threshold(0.3) nseeds(30) seed(5) generate(r6) steps(5)
nwdiffuse simulate rnd, model(threshold) threshold(2) nseeds(30) seed(5) generate(r7) steps(5)
* simulated times feed the other subcommands
nwdiffuse exposure rnd, toa(r1) generate(rx) count(rc)
nwdiffuse threshold rnd, toa(r1) generate(rt)
nwdiffuse curve rnd, toa(r1) silent

* ---- error paths ----
capture nwdiffuse
assert _rc == 198
capture nwdiffuse foo
assert _rc == 198
capture nwdiffuse exposure rnd, generate(q)
assert _rc == 198
capture nwdiffuse exposure rnd, toa(r1) adopt(r2) generate(q)
assert _rc == 198
capture nwdiffuse exposure rnd, toa(r1)
assert _rc == 198
capture nwdiffuse exposure rnd, toa(r1) generate(rx)
assert _rc == 110
capture nwdiffuse exposure rnd, toa(r1) generate(q) lag(-1)
assert _rc == 198
capture nwdiffuse exposure rnd, toa(r1) generate(q) t0(30)
assert _rc == 198
capture nwdiffuse exposure nonet, toa(r1) generate(q)
assert _rc != 0
capture nwdiffuse exposure rnd rnd, toa(r1) generate(q)
assert _rc == 198
generate double frac = 1.5
capture nwdiffuse exposure rnd, toa(frac) generate(q)
assert _rc == 198
generate double allmiss = .
capture nwdiffuse exposure rnd, toa(allmiss) generate(q)
assert _rc == 198
generate byte b1 = 1
generate byte b2 = 0
capture nwdiffuse curve, adopt(b1 b2)
assert _rc == 198
generate byte b3 = 2
capture nwdiffuse curve, adopt(b1 b3)
assert _rc == 198
capture nwdiffuse long rnd, toa(r1)
assert _rc == 4
capture nwdiffuse long rnd, toa(r1) lag(40) clear
assert _rc == 198
capture nwdiffuse simulate rnd, generate(q)
assert _rc != 0
capture nwdiffuse simulate rnd, model(cascade) generate(q) nseeds(1)
assert _rc == 198
capture nwdiffuse simulate rnd, model(cascade) prob(0.5) generate(q)
assert _rc == 198
capture nwdiffuse simulate rnd, model(threshold) generate(q) nseeds(1)
assert _rc == 198
capture nwdiffuse simulate rnd, model(fraction) threshold(2) generate(q) nseeds(1)
assert _rc == 198
capture nwdiffuse simulate rnd, model(cascade) prob(0.5) generate(q) nseeds(1) spont(2)
assert _rc == 198
capture nwdiffuse simulate rnd, model(cascade) prob(0.5) generate(r1) nseeds(1)
assert _rc == 110
capture nwdiffuse simulate rnd, model(cascade) prob(0.5) generate(q) nseeds(1000)
assert _rc == 198
capture nwdiffuse simulate rnd, model(cascade) prob(0.5) generate(q) nseeds(2) seedvar(r1)
assert _rc == 198
capture nwdiffuse simulate rnd, model(cascade) prob(0.5) generate(q) nseeds(2) steps(0)
assert _rc == 198
capture nwdiffuse simulate rnd rnd, model(cascade) prob(0.5) generate(q) nseeds(2) steps(5)
assert _rc == 198
* two-mode networks are refused
nwset, mat((1,0,1\0,1,1)) name(tm) bipartite
capture nwdiffuse simulate tm, model(cascade) prob(0.5) generate(q) nseeds(1)
assert _rc != 0
di "test_nwdiffuse: all passed"
