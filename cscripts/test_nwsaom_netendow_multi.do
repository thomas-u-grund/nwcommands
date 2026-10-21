cscript

do unw_core.do
do unw_ergm.do
do unw_saom.do

* Network endowment/creation split of reciprocity (outdegree + reciprocityendow +
* reciprocitycreation) with waves(), present() and missnet(), all through nwsaom.ado, plus
* symmetric with waves(). Three waves are SIMULATED from known parameters
* (outdegree -1.8, reciprocity endow 1.5, creation 1.0, rate 3) and re-estimated.

nwclear
mata:
mata set matastrict off
void simwaves() {
	struct SaomCountedResult scalar res
	struct SaomNativeConfig scalar cfg
	class ErgmModel scalar M
	class ErgmGraph scalar G
	class ErgmTermData scalar t1, t2, t3
	n = 60
	rseed(31415)
	M = ErgmModel(); M.init()
	t1 = ErgmTermData(); M.addterm("outdegree", 1, &stat_edges(), &change_edges(), t1, ("outdegree"))
	t2 = ErgmTermData(); M.addterm("reciprocityendow", 1, &stat_mutual(), &change_mutual(), t2, ("reciprocityendow"))
	t3 = ErgmTermData(); M.addterm("reciprocitycreation", 1, &stat_mutual(), &change_mutual(), t3, ("reciprocitycreation"))
	cfg = SaomNativeSetup(M)
	cfg.fntype = (0, 1, 2)
	assert(cfg.eligible == 1 & SaomNativeAvailable() == 1)
	G = ErgmGraph(); G.init(n, 1)
	for (k=1; k<=round(0.08*n*(n-1)); k++) {
		i = ceil(runiform(1,1)*n); j = ceil(runiform(1,1)*n)
		if (i!=j & !G.has_edge(i,j)) G.toggle(i,j)
	}
	theta = (-1.8, 1.5, 1.0)
	for (w=1; w<=3; w++) {
		st_matrix("__W" + strofreal(w), G.to_dense())
		if (w < 3) res = SaomSimulateIntervalNative(G, M, cfg, theta, 3, 1, 0)
	}
}
simwaves()
end
forvalues w = 1/3 {
	nwset, mat(__W`w') directed name(rw`w') nooutput
}
gen byte p1 = 1
gen byte p2 = 1
gen byte p3 = 1
replace p3 = 0 in 1/3
replace p2 = 0 in 58/60
matrix __M1 = J(60, 60, 0)
matrix __M2 = J(60, 60, 0)
matrix __M3 = J(60, 60, 0)
matrix __M2[1,2] = 1
matrix __M2[4,7] = 1
matrix __M3[10,11] = 1

local m "outdegree reciprocityendow reciprocitycreation"
nwsaom, waves(rw1 rw2 rw3) `m' k3(500) seed(5)
matrix b = e(b)
di "3-wave: outdegree " b[1,1] " recip endow " b[1,2] " recip creation " b[1,3]
assert colsof(b) == 3 & !missing(b[1,1], b[1,2], b[1,3])
assert abs(b[1,1] + 1.8) < 1.2 & abs(b[1,2] - 1.5) < 2 & abs(b[1,3] - 1) < 2
assert colsof(e(rates)) == 2
di as text "reciprocity endow/creation, waves() PASS"

nwsaom, wave1(rw1) wave2(rw2) `m' present(p1 p2) k3(300) seed(5)
assert colsof(e(b)) == 3 & !missing(el(e(b),1,1))
nwsaom, waves(rw1 rw2 rw3) `m' present(p1 p2 p3) k3(300) seed(5)
assert colsof(e(b)) == 3 & !missing(el(e(b),1,1))
di as text "reciprocity endow/creation + present() PASS"

nwsaom, wave1(rw1) wave2(rw2) `m' missnet(__M1 __M2) k3(300) seed(5)
assert colsof(e(b)) == 3 & !missing(el(e(b),1,1))
nwsaom, waves(rw1 rw2 rw3) `m' missnet(__M1 __M2 __M3) k3(300) seed(5)
assert colsof(e(b)) == 3 & !missing(el(e(b),1,1))
di as text "reciprocity endow/creation + missnet() PASS"

* co-evolution is still refused
gen byte beh1 = mod(_n, 3)
gen byte beh2 = mod(_n, 3)
capture nwsaom, wave1(rw1) wave2(rw2) outdegree reciprocityendow reciprocitycreation behavior(beh1 beh2) linear
assert _rc == 198
di as text "network endow/creation test PASS"

* --- symmetric with waves(): three tie-symmetric waves, simulated by OR-ing each wave with its reverse
nwclear
mata:
mata set matastrict off
void symwaves() {
	n = 50
	rseed(2718)
	A = (runiform(n, n) :< 0.06)
	A = A :| A'
	A = A - diag(diag(A))
	for (w=1; w<=3; w++) {
		st_matrix("__S" + strofreal(w), A)
		F = (runiform(n, n) :< 0.04)
		F = F :| F'
		F = F - diag(diag(F))
		A = abs(A - F)
		A = A - diag(diag(A))
	}
}
symwaves()
end
forvalues w = 1/3 {
	nwset, mat(__S`w') directed name(sy`w') nooutput
}
nwsaom, waves(sy1 sy2 sy3) symmetric outdegree transties k3(500) seed(3)
assert colsof(e(b)) == 2 & colsof(e(rates)) == 2
assert !missing(el(e(b),1,1), el(e(b),1,2), el(e(rates),1,1), el(e(rates),1,2))
assert el(e(rates),1,1) > 0 & el(e(rates),1,2) > 0
* tie-symmetric waves are now modeled as a non-directed relation automatically, also with waves()
nwsaom, waves(sy1 sy2 sy3) outdegree transties k3(500) seed(3)
assert colsof(e(b)) == 2
* symmetric + present() + waves()
gen byte sp1 = 1
gen byte sp2 = 1
gen byte sp3 = 1
replace sp3 = 0 in 1/2
nwsaom, waves(sy1 sy2 sy3) symmetric outdegree transties present(sp1 sp2 sp3) k3(300) seed(3)
assert colsof(e(b)) == 2
di as text "symmetric with waves() PASS"
