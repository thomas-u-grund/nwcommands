* rate effects of nwsaom (native only): structural rate effects (outrate, outrateinv, outratelog) of non-directed and two-mode networks,
* ratecov() for a two-mode network. Estimates agree with siena07 (dev/saom_rsiena_rates_sym.R, dev/saom_rsiena_rates_tm.R).
cscript
do unw_core.do
do unw_ergm.do
do unw_saom.do
nwclear
clear

* ---- non-directed network (s50 symmetrized, 3 waves)
forvalues w = 1/3 {
	import delimited "dev/saom_rsiena_symmulti_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(W`w')
}
forvalues w = 1/3 {
	nwset, mat(W`w') directed name(sr`w') nooutput
}
* observed statistics: the sum over the tie changes of the actor's degree at the start of the period (siena07 targets 1004, 64.493, 398.158)
mata:
real scalar rate_target(real scalar kind) {
	real scalar w, i, j, s, d
	real matrix A, B
	s = 0
	for (w=1; w<=2; w++) {
		A = st_matrix("W" + strofreal(w)); B = st_matrix("W" + strofreal(w+1))
		for (i=1; i<=50; i++) {
			d = sum(A[i,.])
			for (j=1; j<=50; j++) if (A[i,j] != B[i,j]) s = s + (kind == 1 ? d : (kind == 2 ? 1/(d+1) : ln(d+1)))
		}
	}
	return(s)
}
end
mata: assert(abs(rate_target(1) - 1004) < 1e-9 & abs(rate_target(2) - 64.493) < 1e-3 & abs(rate_target(3) - 398.158) < 1e-3)
* estimates (siena07, modelType 2: outRate 0.445/0.440, density -1.170/-1.203; outRateLog 2.276/2.287, density -1.153)
nwsaom, waves(sr1 sr2 sr3) symmetric symtype(forcing) outdegree outrate k0(50) k3(1000) seed(1)
assert "`e(engine)'" == "native" & colsof(e(ratecoefs)) == 1
assert abs(e(ratecoef) - 0.44) < 0.12 & abs(el(e(b),1,1) + 1.19) < 0.12
nwsaom, waves(sr1 sr2 sr3) symmetric symtype(forcing) outdegree outratelog k0(50) k3(1000) seed(1)
assert abs(e(ratecoef) - 2.28) < 0.5 & abs(el(e(b),1,1) + 1.153) < 0.12
nwsaom, waves(sr1 sr2 sr3) symmetric symtype(forcing) outdegree outrateinv k0(50) k3(1000) seed(1)
assert abs(e(ratecoef) + 12.4) < 4 & abs(el(e(b),1,1) + 1.12) < 0.12
* pairwise model (modelType 6) and the other unilateral model
foreach st in joint agree force confirmation {
	capture nwsaom, waves(sr1 sr2 sr3) symmetric symtype(`st') outdegree outratelog k0(20) k3(60) seed(2)
	assert inlist(_rc, 0, 498, 505)
	if _rc == 0 assert "`e(engine)'" == "native" & colsof(e(ratecoefs)) == 1
}
* refusals: in-degree and reciprocal versions do not exist for a non-directed network
foreach ef in inrate reciprate inrateinv inratelog {
	capture nwsaom, waves(sr1 sr2 sr3) symmetric outdegree `ef' k3(30)
	assert _rc != 0
}

* ---- two-mode network (40 actors x 20 events)
forvalues w = 1/3 {
	import delimited "dev/saom_rates_tm_w`w'.csv", clear varnames(1)
	mkmat v1-v20, matrix(T`w')
}
import delimited "dev/saom_rates_tm_cv.csv", clear varnames(1)
mkmat ega, matrix(CA)
mata: CAm = st_matrix("CA")
clear
forvalues w = 1/3 {
	nwset, mat(T`w') bipartite name(tm`w') nooutput
}
gen double ega = .
mata: md = st_sdata(., "_nwmode"); ia = selectindex(md :== "2"); st_store(ia, "ega", CAm)
* siena07: outRate 0.184/0.165 (se 0.15), outRateLog 0.62/0.60, RateX 0.221/0.228, outRate + RateX 0.185 + 0.223 / 0.175 + 0.215
nwsaom, waves(tm1 tm2 tm3) outdegree indegpopularity outrate k0(50) k3(1000) seed(1)
assert "`e(engine)'" == "native" & colsof(e(ratecoefs)) == 1 & abs(e(ratecoef) - 0.17) < 0.12 & abs(el(e(b),1,1) + 1.69) < 0.15
nwsaom, waves(tm1 tm2 tm3) outdegree indegpopularity outratelog k0(50) k3(1000) seed(1)
assert abs(e(ratecoef) - 0.61) < 0.3 & abs(el(e(b),1,1) + 1.68) < 0.15
nwsaom, waves(tm1 tm2 tm3) outdegree indegpopularity ratecov(ega) k0(50) k3(1000) seed(1)
assert abs(e(ratecoef) - 0.225) < 0.1 & abs(el(e(b),1,1) + 1.795) < 0.15
nwsaom, waves(tm1 tm2 tm3) outdegree indegpopularity ratecov(ega) outrate k0(50) k3(1000) seed(2)
assert colsof(e(ratecoefs)) == 2 & abs(el(e(ratecoefs),1,1) - 0.22) < 0.1 & abs(el(e(ratecoefs),1,2) - 0.18) < 0.12
* siena07 has no in-degree / reciprocal rate effect for a two-mode network (inRateInv, inRateLog stop with an error)
foreach ef in inrate reciprate inrateinv inratelog {
	capture nwsaom, waves(tm1 tm2 tm3) outdegree `ef' k3(30)
	assert _rc != 0
}

* ---- RateX with a changing covariate: tvcov() names in ratecov() (siena07 varCovar; dev/saom_rsiena_rates_tv.R)
clear
forvalues w = 1/3 {
	import delimited "dev/saom_rsiena_netendow_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(D`w')
}
import delimited "dev/saom_rsiena_multibeh_data.csv", clear varnames(1)
forvalues w = 1/3 {
	nwset, mat(D`w') directed name(dr`w') nooutput
	nwset, mat(W`w') directed name(sy`w') nooutput
}
* observed statistics: the sum over the tie changes of the actor's centred covariate of the period (siena07 targets 51.21 directed, 58.66 non-directed)
mata:
real scalar tv_target(string scalar mat1, real scalar sym) {
	real scalar pd, i, j, s, m
	real matrix A, B, X
	X = st_data(., ("a1", "a2"))
	m = mean(vec(X))
	s = 0
	for (pd=1; pd<=2; pd++) {
		A = st_matrix(mat1 + strofreal(pd)); B = st_matrix(mat1 + strofreal(pd+1))
		for (i=1; i<=50; i++) for (j=1; j<=50; j++) if (A[i,j] != B[i,j]) s = s + (X[i,pd] - m)
	}
	return(s)
}
end
mata: assert(abs(tv_target("D", 0) - 51.21) < 1e-2 & abs(tv_target("W", 1) - 58.66) < 1e-2)
nwsaom, waves(dr1 dr2 dr3) outdegree reciprocity tvcov(a1 a2 a3) ratecov(a) k0(50) k3(1000) seed(1)
assert "`e(engine)'" == "native" & abs(e(ratecoef) - 0.275) < 0.06 & abs(el(e(b),1,1) + 2.366) < 0.12 & abs(el(e(b),1,2) - 2.84) < 0.25
nwsaom, waves(sy1 sy2 sy3) symmetric outdegree tvcov(a1 a2 a3) ratecov(a) k0(50) k3(1000) seed(1)
assert abs(e(ratecoef) - 0.30) < 0.08 & abs(el(e(b),1,1) + 1.39) < 0.1
* a changing and a constant covariate together, in this order and in the other
gen double cst = mod(_n, 4)
nwsaom, waves(dr1 dr2 dr3) outdegree reciprocity tvcov(a1 a2 a3) ratecov(a cst) k0(20) k3(60) seed(1)
assert colsof(e(ratecoefs)) == 2
nwsaom, waves(dr1 dr2 dr3) outdegree reciprocity tvcov(a1 a2 a3) ratecov(cst a) k0(20) k3(60) seed(1)
assert colsof(e(ratecoefs)) == 2
* two-mode network
nwclear
clear
forvalues w = 1/3 {
	import delimited "dev/saom_rates_tm_w`w'.csv", clear varnames(1)
	mkmat v1-v20, matrix(T`w')
}
import delimited "dev/saom_rates_tm_tv.csv", clear varnames(1)
mkmat t1 t2, matrix(TV)
mata: TVm = st_matrix("TV")
clear
forvalues w = 1/3 {
	nwset, mat(T`w') bipartite name(tm`w') nooutput
}
gen double t1 = .
gen double t2 = .
mata: md = st_sdata(., "_nwmode"); ia = selectindex(md :== "2"); st_store(ia, ("t1", "t2"), TVm)
nwsaom, waves(tm1 tm2 tm3) outdegree indegpopularity tvcov(t1 t2) ratecov(t) k0(50) k3(1000) seed(1)
assert abs(e(ratecoef) - 0.163) < 0.09 & abs(el(e(b),1,1) + 1.78) < 0.15
di as text "rate effects PASS"
