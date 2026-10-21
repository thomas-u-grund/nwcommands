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

* (co-evolution with the network split is tested at the end of this file)
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

* --- ratecov() with waves(): directed (RSiena RateX is one shared coefficient) and symmetric
gen double rcx = mod(_n * 7, 5)
nwsaom, waves(sy1 sy2 sy3) symmetric symtype(joint) outdegree ratecov(rcx) k3(500) seed(3)
assert !missing(e(ratecoef)) & !missing(e(ratecoef_se)) & colsof(e(rates)) == 2
nwsaom, waves(sy1 sy2 sy3) outdegree reciprocity ratecov(rcx) k3(300) seed(3)
assert !missing(e(ratecoef)) & colsof(e(b)) == 2 & colsof(e(rates)) == 2
* ratecov() is still refused with present() / missnet()
capture nwsaom, waves(sy1 sy2 sy3) symmetric outdegree ratecov(rcx) present(sp1 sp2 sp3)
assert _rc == 198
di as text "ratecov() with waves() PASS"

* --- transTies endowment/creation: native statistic equals the Mata one, then the full fit
nwclear
mata:
mata set matastrict off
void tte_test() {
	class ErgmModel scalar M
	class ErgmGraph scalar G0, Gw
	class ErgmTermData scalar t1, t2, t3, t4
	struct SaomCountedResult scalar res
	struct SaomNativeConfig scalar cfg
	real rowvector fn, mst, maxerr
	real scalar n, k, i, j, r
	n = 40
	rseed(77)
	M = ErgmModel(); M.init()
	t1 = ErgmTermData(); M.addterm("outdegree", 1, &stat_edges(), &change_edges(), t1, ("outdegree"))
	t2 = ErgmTermData(); M.addterm("reciprocity", 1, &stat_mutual(), &change_mutual(), t2, ("reciprocity"))
	t3 = ErgmTermData(); M.addterm("transtiesendow", 1, &stat_transitiveties(), &change_saom_transties(), t3, ("transtiesendow"))
	t4 = ErgmTermData(); M.addterm("transtiescreation", 1, &stat_transitiveties(), &change_saom_transties(), t4, ("transtiescreation"))
	fn = SaomFntypeFromNames(M)
	assert(fn == (0, 0, 1, 2))
	cfg = SaomNativeSetup(M)
	cfg.fntype = fn
	assert(cfg.eligible == 1 & SaomNativeAvailable() == 1)
	G0 = ErgmGraph(); G0.init(n, 1)
	for (k=1; k<=round(0.12*n*(n-1)); k++) {
		i = ceil(runiform(1,1)*n); j = ceil(runiform(1,1)*n)
		if (i!=j & !G0.has_edge(i,j)) G0.toggle(i,j)
	}
	maxerr = J(1, 4, 0)
	for (r=1; r<=20; r++) {
		Gw = ErgmGraph(); SaomCopyGraph(G0, Gw)
		res = SaomSimulateIntervalNative(Gw, M, cfg, (-2, 1.5, -0.3, 1.0), 3, 1, 0)
		mst = SaomNetworkPatchEndowCreation(M, fn, M.full_statistic(Gw), G0, Gw)
		maxerr = colmax(abs(res.stat \ mst) )
		assert(max(abs(res.stat - mst)) < 1e-9)
	}
}
tte_test()
end
mata:
void tte_data() {
	n = 50
	rseed(99)
	A = (runiform(n, n) :< 0.08)
	A = A - diag(diag(A))
	for (w=1; w<=3; w++) {
		st_matrix("__T" + strofreal(w), A)
		F = (runiform(n, n) :< 0.10)
		A = abs(A - F)
		A = A - diag(diag(A))
	}
}
tte_data()
end
forvalues w = 1/3 {
	nwset, mat(__T`w') directed name(tt`w') nooutput
}
nwsaom, waves(tt1 tt2 tt3) outdegree reciprocity transtiesendow transtiescreation k3(300) seed(4)
assert colsof(e(b)) == 4 & !missing(el(e(b),1,3), el(e(b),1,4))
* plain + endow is collinear, a single role is refused
capture nwsaom, waves(tt1 tt2 tt3) outdegree transties transtiesendow transtiescreation
assert _rc == 198
capture nwsaom, waves(tt1 tt2 tt3) outdegree transtiesendow
assert _rc == 198
di as text "transTies endowment/creation PASS"

* --- endow() / creation() syntax: identical to the long option pair, refuses invalid combinations
quietly nwsaom, waves(tt1 tt2 tt3) outdegree reciprocity transtiesendow transtiescreation k3(300) seed(4)
matrix __a = e(b)
quietly nwsaom, waves(tt1 tt2 tt3) outdegree reciprocity endow(transties) creation(transties) k3(300) seed(4)
matrix __b = e(b)
assert mreldif(__a, __b) < 1e-12
assert "`: colnames e(b)'" == "outdegree reciprocity transtiesendow transtiescreation"
capture nwsaom, waves(tt1 tt2 tt3) outdegree endow(transties)
assert _rc == 198
capture nwsaom, waves(tt1 tt2 tt3) outdegree transties endow(transties) creation(transties)
assert _rc == 198
capture nwsaom, waves(tt1 tt2 tt3) outdegree endow(gwesp) creation(gwesp)
assert _rc == 198
* behavior side: same estimates as the long option pair
gen byte tb1 = mod(_n*3, 5) + 1
gen byte tb2 = mod(_n*3 + (_n > 25), 5) + 1
nwsaom, wave1(tt1) wave2(tt2) outdegree reciprocity behavior(tb1 tb2) linear quadraticendow quadraticcreation k0(30) k3(200) seed(2)
matrix __c = e(b)
nwsaom, wave1(tt1) wave2(tt2) outdegree reciprocity behavior(tb1 tb2) linear endow(quadratic) creation(quadratic) k0(30) k3(200) seed(2)
matrix __d = e(b)
assert mreldif(__c, __d) < 1e-12
di as text "endow()/creation() syntax PASS"

* --- gwesp / cycle4 endowment/creation: native statistic equals the Mata one; fits; refusals
mata:
mata set matastrict off
void gwc_test() {
	class ErgmModel scalar M
	class ErgmGraph scalar G0, Gw
	class ErgmTermData scalar t1, t2, t3, t4, t5
	struct SaomCountedResult scalar res
	struct SaomNativeConfig scalar cfg
	real rowvector fn, mst
	real scalar n, k, i, j, r
	n = 40
	rseed(55)
	M = ErgmModel(); M.init()
	t1 = ErgmTermData(); M.addterm("outdegree", 1, &stat_edges(), &change_edges(), t1, ("outdegree"))
	t2 = ErgmTermData(); t2.decay = 0.69; t2.sptype = "OTP"; M.addterm("gwespendow", 1, &stat_gwesp(), &change_saom_gwesp(), t2, ("gwespendow"))
	t3 = ErgmTermData(); t3.decay = 0.69; t3.sptype = "OTP"; M.addterm("gwespcreation", 1, &stat_gwesp(), &change_saom_gwesp(), t3, ("gwespcreation"))
	t4 = ErgmTermData(); M.addterm("cycle4endow", 1, &stat_saom_cycle4(), &change_saom_cycle4(), t4, ("cycle4endow"))
	t5 = ErgmTermData(); M.addterm("cycle4creation", 1, &stat_saom_cycle4(), &change_saom_cycle4(), t5, ("cycle4creation"))
	fn = SaomFntypeFromNames(M)
	assert(fn == (0, 1, 2, 1, 2))
	cfg = SaomNativeSetup(M)
	cfg.fntype = fn
	assert(cfg.eligible == 1 & SaomNativeAvailable() == 1)
	G0 = ErgmGraph(); G0.init(n, 1)
	for (k=1; k<=round(0.12*n*(n-1)); k++) {
		i = ceil(runiform(1,1)*n); j = ceil(runiform(1,1)*n)
		if (i!=j & !G0.has_edge(i,j)) G0.toggle(i,j)
	}
	for (r=1; r<=15; r++) {
		Gw = ErgmGraph(); SaomCopyGraph(G0, Gw)
		res = SaomSimulateIntervalNative(Gw, M, cfg, (-2, -0.2, 0.5, 0.1, 0.3), 3, 1, 0)
		mst = SaomNetworkPatchEndowCreation(M, fn, M.full_statistic(Gw), G0, Gw)
		assert(max(abs(res.stat - mst)) < 1e-8)
	}
}
gwc_test()
end
mata:
mata set matastrict off
void bal_test() {
	class ErgmModel scalar M
	class ErgmGraph scalar G0, Gw
	class ErgmTermData scalar t1, t2, t3
	struct SaomCountedResult scalar res
	struct SaomNativeConfig scalar cfg
	real rowvector fn, mst
	real scalar n, k, i, j, r
	n = 40
	rseed(56)
	M = ErgmModel(); M.init()
	t1 = ErgmTermData(); M.addterm("outdegree", 1, &stat_edges(), &change_edges(), t1, ("outdegree"))
	t2 = ErgmTermData(); t2.decay = 0.09; M.addterm("balanceendow", 1, &stat_saom_balance(), &change_saom_balance(), t2, ("balanceendow"))
	t3 = ErgmTermData(); t3.decay = 0.09; M.addterm("balancecreation", 1, &stat_saom_balance(), &change_saom_balance(), t3, ("balancecreation"))
	fn = SaomFntypeFromNames(M)
	assert(fn == (0, 1, 2))
	cfg = SaomNativeSetup(M)
	cfg.fntype = fn
	assert(cfg.eligible == 1 & SaomNativeAvailable() == 1)
	G0 = ErgmGraph(); G0.init(n, 1)
	for (k=1; k<=round(0.12*n*(n-1)); k++) {
		i = ceil(runiform(1,1)*n); j = ceil(runiform(1,1)*n)
		if (i!=j & !G0.has_edge(i,j)) G0.toggle(i,j)
	}
	for (r=1; r<=15; r++) {
		Gw = ErgmGraph(); SaomCopyGraph(G0, Gw)
		res = SaomSimulateIntervalNative(Gw, M, cfg, (-2, -0.1, 0.5), 3, 1, 0)
		mst = SaomNetworkPatchEndowCreation(M, fn, M.full_statistic(Gw), G0, Gw)
		assert(max(abs(res.stat - mst)) < 1e-7)
	}
}
bal_test()
end
mata:
mata set matastrict off
void triad_test() {
	class ErgmModel scalar M
	class ErgmGraph scalar G0, Gw
	class ErgmTermData scalar t1, t2, t3
	struct SaomCountedResult scalar res
	struct SaomNativeConfig scalar cfg
	real rowvector fn, mst
	real scalar n, k, i, j, r, q
	string rowvector nms
	n = 40
	rseed(57)
	nms = ("transtrip", "cycle3", "transmedtrip", "transrectrip")
	G0 = ErgmGraph(); G0.init(n, 1)
	for (k=1; k<=round(0.12*n*(n-1)); k++) {
		i = ceil(runiform(1,1)*n); j = ceil(runiform(1,1)*n)
		if (i!=j & !G0.has_edge(i,j)) G0.toggle(i,j)
	}
	for (q=1; q<=4; q++) {
		M = ErgmModel(); M.init()
		t1 = ErgmTermData(); t2 = ErgmTermData(); t3 = ErgmTermData()
		M.addterm("outdegree", 1, &stat_edges(), &change_edges(), t1, ("outdegree"))
		if (q==1) {
			M.addterm("transtripendow", 1, &stat_saom_transtrip(), &change_saom_transtrip(), t2, ("a"))
			M.addterm("transtripcreation", 1, &stat_saom_transtrip(), &change_saom_transtrip(), t3, ("b"))
		}
		if (q==2) {
			M.addterm("cycle3endow", 1, &stat_saom_cycle3(), &change_saom_cycle3(), t2, ("a"))
			M.addterm("cycle3creation", 1, &stat_saom_cycle3(), &change_saom_cycle3(), t3, ("b"))
		}
		if (q==3) {
			M.addterm("transmedtripendow", 1, &stat_saom_transmedtrip(), &change_saom_transmedtrip(), t2, ("a"))
			M.addterm("transmedtripcreation", 1, &stat_saom_transmedtrip(), &change_saom_transmedtrip(), t3, ("b"))
		}
		if (q==4) {
			M.addterm("transrectripendow", 1, &stat_saom_transrectrip(), &change_saom_transrectrip(), t2, ("a"))
			M.addterm("transrectripcreation", 1, &stat_saom_transrectrip(), &change_saom_transrectrip(), t3, ("b"))
		}
		fn = SaomFntypeFromNames(M)
		assert(fn == (0, 1, 2))
		cfg = SaomNativeSetup(M)
		cfg.fntype = fn
		assert(cfg.eligible == 1 & SaomNativeAvailable() == 1)
		for (r=1; r<=10; r++) {
			Gw = ErgmGraph(); SaomCopyGraph(G0, Gw)
			res = SaomSimulateIntervalNative(Gw, M, cfg, (-2, -0.1, 0.3), 3, 1, 0)
			mst = SaomNetworkPatchEndowCreation(M, fn, M.full_statistic(Gw), G0, Gw)
			assert(max(abs(res.stat - mst)) < 1e-7)
		}
	}
}
triad_test()
end
foreach ef in transtrip cycle3 transmedtrip {
	nwsaom, waves(tt1 tt2 tt3) outdegree reciprocity endow(`ef') creation(`ef') k3(300) seed(4)
	assert colsof(e(b)) == 4 & !missing(el(e(b),1,3), el(e(b),1,4))
}
capture nwsaom, waves(tt1 tt2 tt3) outdegree reciprocity endow(transrectrip) creation(transrectrip) k3(300) seed(4)
assert inlist(_rc, 0, 498)
nwsaom, waves(tt1 tt2 tt3) outdegree reciprocity endow(balance) creation(balance) k3(300) seed(4)
assert colsof(e(b)) == 4 & !missing(el(e(b),1,3), el(e(b),1,4))
matrix __bm = J(50, 50, 0)
capture nwsaom, waves(tt1 tt2 tt3) outdegree endow(balance) creation(balance) missnet(__bm __bm __bm) k3(50)
assert _rc == 198
nwsaom, waves(tt1 tt2 tt3) outdegree reciprocity gwesp(0.69) endow(gwesp) creation(gwesp) k3(300) seed(4)
assert colsof(e(b)) == 4 & !missing(el(e(b),1,3), el(e(b),1,4))
nwsaom, waves(tt1 tt2 tt3) outdegree reciprocity endow(cycle4) creation(cycle4) k3(300) seed(4)
assert colsof(e(b)) == 4 & !missing(el(e(b),1,3), el(e(b),1,4))
* gwesp needs its decay; plain cycle4 plus the split is collinear
capture nwsaom, waves(tt1 tt2 tt3) outdegree endow(gwesp) creation(gwesp)
assert _rc == 198
capture nwsaom, waves(tt1 tt2 tt3) outdegree cycle4 endow(cycle4) creation(cycle4)
assert _rc == 198
di as text "gwesp/cycle4 endowment/creation PASS"

* --- network endowment/creation together with behavior() (co-evolution): two waves, three waves, present().
* The synthetic behavior is random, so a fit may legitimately hit RSiena's thetaBound (rc 498); the point
* here is that the combination is accepted and runs natively (real-data check: dev/saom_rsiena_coev_netendow.*)
gen byte tb3 = mod(_n*3 + 2*(_n > 20), 5) + 1
gen byte cp1 = 1
gen byte cp2 = 1
replace cp2 = 0 in 1/2
capture nwsaom, wave1(tt1) wave2(tt2) outdegree endow(reciprocity) creation(reciprocity) behavior(tb1 tb2) linear quadratic avalt k0(30) k3(200) seed(2)
assert inlist(_rc, 0, 498)
if _rc == 0 assert colsof(e(b)) == 6 & "`e(engine)'" == "native"
capture nwsaom, waves(tt1 tt2 tt3) outdegree endow(reciprocity) creation(reciprocity) behavior(tb1 tb2 tb3) linear quadratic avalt k0(30) k3(200) seed(2)
assert inlist(_rc, 0, 498)
if _rc == 0 assert colsof(e(b)) == 6
capture nwsaom, wave1(tt1) wave2(tt2) outdegree endow(reciprocity) creation(reciprocity) behavior(tb1 tb2) linear quadratic present(cp1 cp2) k0(30) k3(200) seed(2)
assert inlist(_rc, 0, 498)
if _rc == 0 assert colsof(e(b)) == 5
di as text "network endowment/creation with behavior() PASS"

* --- symmetric (undirected) co-evolution: tie-symmetric waves + a behavior, native batch path.
* (Real-data check against RSiena: dev/saom_rsiena_symmetric_coev*.{R,do}.)
nwclear
mata:
mata set matastrict off
void symcoev_data() {
	n = 50
	rseed(8675)
	A = (runiform(n, n) :< 0.07)
	A = A :| A'
	A = A - diag(diag(A))
	for (w=1; w<=3; w++) {
		st_matrix("__Y" + strofreal(w), A)
		F = (runiform(n, n) :< 0.05)
		F = F :| F'
		F = F - diag(diag(F))
		A = abs(A - F)
		A = A - diag(diag(A))
	}
}
symcoev_data()
end
forvalues w = 1/3 {
	nwset, mat(__Y`w') directed name(yc`w') nooutput
}
gen byte yb1 = mod(_n*3, 5) + 1
gen byte yb2 = mod(_n*3 + (_n > 25), 5) + 1
gen byte yb3 = mod(_n*3 + 2*(_n > 20), 5) + 1
capture nwsaom, wave1(yc1) wave2(yc2) symmetric symtype(joint) outdegree behavior(yb1 yb2) linear avalt k0(30) k3(200) seed(2)
assert inlist(_rc, 0, 498)
if _rc == 0 assert colsof(e(b)) == 3 & "`e(engine)'" == "native" & e(rate) < 5
capture nwsaom, waves(yc1 yc2 yc3) symmetric symtype(joint) outdegree behavior(yb1 yb2 yb3) linear avalt k0(30) k3(200) seed(2)
assert inlist(_rc, 0, 498)
if _rc == 0 assert colsof(e(b)) == 3
di as text "symmetric co-evolution PASS"
