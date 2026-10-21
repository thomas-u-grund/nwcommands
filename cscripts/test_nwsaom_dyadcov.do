cscript

do unw_core.do
do unw_ergm.do
do unw_saom.do

* Dyadic covariates dyadcov() / dyadcovrecip() (RSiena X / XRecip): the native statistic equals the Mata one
* (centred, missing cells excluded), the fit runs natively, and invalid matrices are refused.
* Real-data check against RSiena: dev/saom_rsiena_dyadcov.{R,do}.

mata:
mata set matastrict off
void dyad_test() {
	class ErgmModel scalar M
	class ErgmGraph scalar G0, Gw
	class ErgmTermData scalar t1, t2, t3
	struct SaomCountedResult scalar res
	struct SaomNativeConfig scalar cfg
	real matrix X, W
	real scalar n, k, i, j, r, m
	n = 30
	rseed(61)
	X = floor(runiform(n, n) * 5)
	for (k=1; k<=40; k++) X[ceil(runiform(1,1)*n), ceil(runiform(1,1)*n)] = .
	W = SaomDyadPrep(X, 1, m)
	// centring: mean of the non-missing off-diagonal cells, missing cells and the diagonal are 0
	assert(all(diagonal(W) :== 0))
	assert(all(W :< .))
	M = ErgmModel(); M.init()
	t1 = ErgmTermData(); M.addterm("outdegree", 1, &stat_edges(), &change_edges(), t1, ("outdegree"))
	t2 = ErgmTermData(); t2.edgecovmat = W; M.addterm("dyadcov", 1, &stat_saom_dyadcov(), &change_saom_dyadcov(), t2, ("dyadcov_X"))
	t3 = ErgmTermData(); t3.edgecovmat = W; M.addterm("dyadcovrecip", 1, &stat_saom_dyadcovrecip(), &change_saom_dyadcovrecip(), t3, ("dyadcovrecip_X"))
	cfg = SaomNativeSetup(M)
	assert(cfg.eligible == 1 & SaomNativeAvailable() == 1)
	assert(cfg.termcodes == (1, 40, 41))
	assert(cols(cfg.attrmat) == 2 * n)
	G0 = ErgmGraph(); G0.init(n, 1)
	for (k=1; k<=round(0.12*n*(n-1)); k++) {
		i = ceil(runiform(1,1)*n); j = ceil(runiform(1,1)*n)
		if (i!=j & !G0.has_edge(i,j)) G0.toggle(i,j)
	}
	for (r=1; r<=15; r++) {
		Gw = ErgmGraph(); SaomCopyGraph(G0, Gw)
		res = SaomSimulateIntervalNative(Gw, M, cfg, (-2, 0.3, 0.2), 3, 1, 0)
		assert(max(abs(res.stat - M.full_statistic(Gw))) < 1e-8)
	}
}
dyad_test()
end

nwclear
mata:
void dyad_data() {
	n = 50
	rseed(4321)
	A = (runiform(n, n) :< 0.08)
	A = A - diag(diag(A))
	for (w=1; w<=3; w++) {
		st_matrix("__D" + strofreal(w), A)
		F = (runiform(n, n) :< 0.10)
		A = abs(A - F)
		A = A - diag(diag(A))
	}
	X = floor(runiform(n, n) * 4)
	st_matrix("__DX", X)
	X[3,4] = .
	X[10,2] = .
	st_matrix("__DXm", X)
}
dyad_data()
end
forvalues w = 1/3 {
	nwset, mat(__D`w') directed name(dd`w') nooutput
}
nwsaom, waves(dd1 dd2 dd3) outdegree reciprocity dyadcov(__DX) k3(300) seed(3)
assert colsof(e(b)) == 3 & !missing(el(e(b),1,3)) & "`e(engine)'" == "native"
assert "`: colnames e(b)'" == "outdegree reciprocity dyadcov___DX"
nwsaom, waves(dd1 dd2 dd3) outdegree reciprocity dyadcovrecip(__DX) k3(300) seed(3)
assert colsof(e(b)) == 3 & !missing(el(e(b),1,3))
nwsaom, wave1(dd1) wave2(dd2) outdegree reciprocity dyadcov(__DXm) dyadcovrecip(__DX) k3(300) seed(3)
assert colsof(e(b)) == 4
nwsaom, wave1(dd1) wave2(dd2) outdegree reciprocity dyadcov(__DXm) nocenter k3(300) seed(3)
assert colsof(e(b)) == 3
* invalid input
matrix __small = J(10, 10, 1)
capture nwsaom, wave1(dd1) wave2(dd2) outdegree dyadcov(__small) k3(50)
assert _rc == 198
capture nwsaom, wave1(dd1) wave2(dd2) outdegree dyadcov(nosuchmat) k3(50)
assert _rc == 111
di as text "dyadic covariates PASS"
