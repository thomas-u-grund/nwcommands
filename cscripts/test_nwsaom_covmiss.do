cscript

do unw_core.do
do unw_saom.do

* Covariates with missing values: masked statistics (Mata) and their native (C)
* counterparts (termcodes 35-39) must agree EXACTLY on the statistic of any graph,
* and the simulated means must agree within Monte Carlo tolerance.

mata:
mata set matastrict off
void covmiss_test() {
struct SaomCountedResult scalar res
real scalar mu
struct SaomNativeConfig scalar cfg
class SaomModel scalar M
class SaomGraph scalar G0, Gw
class SaomTermData scalar td0, td1, td2, td3, td4, td5
n = 30
mu = 0
nruns = 600
rseed(20261021)
xa = rnormal(n, 1, 0, 1); xb = ceil(runiform(n, 1) * 3); xc = rnormal(n, 1, 5, 2)
xd = floor(runiform(n, 1) * 4); xe = rnormal(n, 1, 0, 1)
xa[(3, 11, 17)] = J(3, 1, .)
xb[(2, 5, 29)] = J(3, 1, .)
xc[(7, 8, 19, 24)] = J(4, 1, .)
xd[(1, 30)] = J(2, 1, .)
xe[(4, 9, 14)] = J(3, 1, .)
st_addobs(max((0, n - st_nobs())))
st_store((1::n), st_addvar("double", "xa"), xa)
st_store((1::n), st_addvar("double", "xb"), xb)
st_store((1::n), st_addvar("double", "xc"), xc)
st_store((1::n), st_addvar("double", "xd"), xd)
st_store((1::n), st_addvar("double", "xe"), xe)

M = SaomModel()
M.init()
td0 = SaomTermData()
M.addterm("outdegree", 1, &sn_stat_edges(), &sn_change_edges(), td0, ("outdegree"))
td1 = SaomTermData(); SaomRegCov(M, "nodematch", "xb", n, 0, td1, ("nodematch_xb"), mu)
td2 = SaomTermData(); SaomRegCov(M, "nodecov", "xc", n, 0, td2, ("nodecov_xc"), mu)
td3 = SaomTermData(); SaomRegCov(M, "nodeicov", "xa", n, 0, td3, ("nodeicov_xa"), mu)
td4 = SaomTermData(); SaomRegCov(M, "nodeocov", "xd", n, 0, td4, ("nodeocov_xd"), mu)
td5 = SaomTermData(); SaomRegCov(M, "simcov", "xe", n, 0, td5, ("simcov_xe"), mu)

cfg = SaomNativeSetup(M)
assert(cfg.eligible == 1)
assert(SaomNativeAvailable() == 1)
assert(cfg.termcodes == (1, 35, 36, 37, 38, 39))
assert(cols(cfg.attrmat) == 10)

G0 = SaomGraph()
G0.init(n, 1)
for (k=1; k<=round(0.15*n*(n-1)); k++) {
	i = ceil(runiform(1,1)*n); j = ceil(runiform(1,1)*n)
	if (i!=j & !G0.has_edge(i,j)) G0.toggle(i,j)
}
theta = (-1.5, 0.4, 0.2, 0.3, -0.2, 0.5)
p = M.nparam()

Zm = J(nruns, p, 0); Zn = J(nruns, p, 0)
maxerr = 0
rseed(1)
for (r=1; r<=nruns; r++) {
	Gw = SaomGraph(); SaomCopyGraph(G0, Gw)
	junk = SaomSimulateInterval(Gw, M, theta, 3)
	Zm[r,.] = M.full_statistic(Gw)
}
rseed(2)
for (r=1; r<=nruns; r++) {
	Gw = SaomGraph(); SaomCopyGraph(G0, Gw)
	res = SaomSimulateIntervalNative(Gw, M, cfg, theta, 3, 1, 0)
	Zn[r,.] = M.full_statistic(Gw)
	maxerr = max((maxerr, max(abs(res.stat - Zn[r,.]))))
}
printf("native vs Mata full_statistic on the same final graph: max abs error %g\n", maxerr)
assert(maxerr < 1e-9)
mm = mean(Zm); mn = mean(Zn)
for (k=1; k<=p; k++) {
	z = (mm[k] - mn[k]) / sqrt(variance(Zm[.,k])/nruns + variance(Zn[.,k])/nruns)
	printf("term %g: Mata mean %9.3f native mean %9.3f z %6.2f\n", k, mm[k], mn[k], z)
	assert(abs(z) < 4.5)
}
printf("covariate-missing native equivalence PASS\n")
}
covmiss_test()
end

* --- end-to-end through nwsaom.ado: missing covariates are accepted, centered/masked,
* and the fit still runs natively; an interact() with a missing-valued covariate is rejected.
nwclear
set seed 90210
mata:
n = 40
A = rdiscrete(n, n, (0.88, 0.12)) :- 1
A = A - diag(diag(A))
B = abs(A - (runiform(n, n) :< 0.08))
B = B - diag(diag(B))
st_matrix("__w1m", A)
st_matrix("__w2m", B)
end
nwset, mat(__w1m) directed name(w1)
nwset, mat(__w2m) directed name(w2)
gen double g1 = mod(_n,2)
gen double x1 = _n
replace g1 = . in 3
replace g1 = . in 10
replace x1 = . in 5/7
nwsaom, wave1(w1) wave2(w2) outdegree nodeicov(x1) nodeocov(x1) nodematch(g1) simcov(x1) nocenter k0(20) k3(60) seed(7)
assert colsof(e(b)) == 5
nwsaom, wave1(w1) wave2(w2) outdegree nodeicov(x1) nodeocov(x1) nodematch(g1) simcov(x1) k0(20) k3(60) seed(7)
assert colsof(e(b)) == 5
assert !missing(e(b)[1,1])
capture nwsaom, wave1(w1) wave2(w2) outdegree reciprocity nodematch(g1) interact(reciprocity#nodematch) k0(10) k3(10)
assert _rc == 198
* a centred altX with missing values is not masked (imputed value 0), so it may be interacted
nwsaom, wave1(w1) wave2(w2) outdegree reciprocity nodeicov(x1) interact(reciprocity#nodeicov) k0(10) k3(10) seed(7)
assert colsof(e(b)) == 4
di as text "nwsaom missing-covariate .ado test PASS"
