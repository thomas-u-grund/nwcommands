* nwsaom inpop / outpop / inact / outactsqrt (RSiena inPop, outPop, inAct, outActSqrt). Real-data agreement with RSiena 1.6.6
* (s50, 3 waves; targets 798, 676, 676, 416.092; estimates within noise): dev/saom_rsiena_degfx.{R,do}.
cscript
do unw_core.do
do unw_ergm.do
do unw_saom.do
nwclear
clear
set obs 40
mata:
mata set matastrict off
void dg_data() {
	n = 40
	rseed(97531)
	A = (runiform(n, n) :< 0.09)
	A = A - diag(diag(A))
	for (w=1; w<=3; w++) {
		st_matrix("__W" + strofreal(w), A)
		F = (runiform(n, n) :< 0.05)
		A = abs(A - F)
		A = A - diag(diag(A))
	}
}
dg_data()
end
forvalues w = 1/3 {
	nwset, mat(__W`w') directed name(dg`w') nooutput
}
nwsaom, waves(dg1 dg2 dg3) outdegree reciprocity inpop outpop outactsqrt k0(30) k3(150) seed(4)
assert colsof(e(b)) == 5 & !missing(el(e(b),1,3), el(e(b),1,5)) & "`e(engine)'" == "native"
* statistics are those of the degree distribution
mata: A = __nwsaom_last_G2.to_dense(); st = __nwsaom_last_M.full_statistic(__nwsaom_last_G2); od = rowsum(A); id = colsum(A)'
mata: st_numscalar("__d1", abs(st[3] - sum(id:^2)) + abs(st[4] - sum(od:*id)) + abs(st[5] - sum(od:^1.5)))
assert scalar(__d1) < 1e-9
nwsaom, waves(dg1 dg2 dg3) outdegree reciprocity inact k0(30) k3(150) seed(4)
assert colsof(e(b)) == 3 & !missing(el(e(b),1,3))
global NWSAOM_NONATIVE 1
nwsaom, wave1(dg1) wave2(dg2) outdegree inpop outactsqrt k0(20) k3(50) seed(4)
assert "`e(engine)'" == "mata"
global NWSAOM_NONATIVE
capture nwsaom, waves(dg1 dg2 dg3) outdegree outpop inact
assert _rc == 198
di as text "degree effects PASS"

* endowment / creation split of the degree effects: RSiena's statistics (endowment: minus the sum over lost ties of the tie statistic in the start
* network; creation: the sum over gained ties of it in the end network - but for the ego-activity effects, which override endowmentStatistic(), in the START
* network too; s50: inPop -382 / 395, outActSqrt -179.11 / 167.86, outAct -316 / 278, inAct -293 / 299 - dev/saom_rsiena_degsplit.{R,do})
capture nwsaom, waves(dg1 dg2) outdegree reciprocity endow(inpop outactsqrt) creation(inpop outactsqrt) k0(5) k3(5) seed(2)
mata:
mata set matastrict off
void dg_split_check() {
	external class ErgmModel scalar __nwsaom_last_M
	external class ErgmGraph scalar __nwsaom_last_G1, __nwsaom_last_G2
	real rowvector st
	real matrix ties1, ties2
	real scalar k, e1, c1, e2, c2
	assert(__nwsaom_last_M.nterms == 6)
	assert(__nwsaom_last_M.names[3] == "inpopendow" & __nwsaom_last_M.names[4] == "inpopcreation" & __nwsaom_last_M.names[5] == "outactsqrtendow" & __nwsaom_last_M.names[6] == "outactsqrtcreation")
	st = SaomNetworkPatchEndowCreation(__nwsaom_last_M, SaomFntypeFromNames(__nwsaom_last_M), __nwsaom_last_M.full_statistic(__nwsaom_last_G2), __nwsaom_last_G1, __nwsaom_last_G2)
	ties1 = __nwsaom_last_G1.all_ties()
	ties2 = __nwsaom_last_G2.all_ties()
	e1 = 0
	c1 = 0
	e2 = 0
	c2 = 0
	for (k=1; k<=rows(ties1); k++) {
		if (!__nwsaom_last_G2.has_edge(ties1[k,1], ties1[k,2])) {
			e1 = e1 - __nwsaom_last_G1.din[ties1[k,2]]
			e2 = e2 - sqrt(__nwsaom_last_G1.dout[ties1[k,1]])
		}
	}
	for (k=1; k<=rows(ties2); k++) {
		if (!__nwsaom_last_G1.has_edge(ties2[k,1], ties2[k,2])) {
			c1 = c1 + __nwsaom_last_G2.din[ties2[k,2]]
			c2 = c2 + sqrt(__nwsaom_last_G1.dout[ties2[k,1]])
		}
	}
	assert(abs(st[3] - e1) < 1e-9 & abs(st[4] - c1) < 1e-9 & abs(st[5] - e2) < 1e-9 & abs(st[6] - c2) < 1e-9)
	assert(e1 < 0 & c1 > 0 & e2 < 0 & c2 > 0)
}
dg_split_check()
end
di as text "endow/creation of the degree effects PASS"
capture noisily nwsaom, waves(dg1 dg2 dg3) outdegree inpop endow(inpop) creation(inpop) k3(50)
assert _rc == 198

* functions of the outdegree with a parameter (RSiena outTrunc, outMore, outThreshold, outInv, outSqInv; s50 targets 207, 76, 45, 37.15, 11.533 - dev/saom_rsiena_degfun.{R,do})
nwsaom, waves(dg1 dg2 dg3) outdegree reciprocity outtrunc(3) outmore(2) outinv(1) k0(30) k3(150) seed(5)
assert colsof(e(b)) == 5 & !missing(el(e(b),1,3), el(e(b),1,5)) & "`e(engine)'" == "native"
mata:
mata set matastrict off
void dg_fun_check() {
	external class ErgmModel scalar __nwsaom_last_M
	external class ErgmGraph scalar __nwsaom_last_G3
	real rowvector st
	real colvector d
	st = __nwsaom_last_M.full_statistic(__nwsaom_last_G3)
	d = __nwsaom_last_G3.dout
	assert(abs(st[3] - sum(d :* (d :< 3) + 3 :* (d :>= 3))) < 1e-9)
	assert(abs(st[4] - sum((d :- 2) :* (d :> 2))) < 1e-9)
	assert(abs(st[5] - sum(1 :/ (d :+ 1))) < 1e-9)
}
dg_fun_check()
end
capture noisily nwsaom, wave1(dg1) wave2(dg2) outdegree outtrunc(0) k3(50)
assert _rc == 125 | _rc == 198 | _rc == 121
di as text "functions of the outdegree PASS"

* reciprocated-degree effects, copied exactly from RSiena (reciPop 532, reciPopSqrt 335.803, reciAct 505, reciAct(2) 319.113 on s50 - dev/saom_rsiena_reci.{R,do})
nwsaom, waves(dg1 dg2 dg3) outdegree reciprocity recipop reciact k0(30) k3(150) seed(6)
assert colsof(e(b)) == 4 & !missing(el(e(b),1,3), el(e(b),1,4)) & "`e(engine)'" == "native"
mata:
mata set matastrict off
void dg_reci_check() {
	external class ErgmModel scalar __nwsaom_last_M
	external class ErgmGraph scalar __nwsaom_last_G3
	real rowvector st
	real colvector rd
	real scalar j, k, nb
	rd = J(__nwsaom_last_G3.n, 1, 0)
	for (j=1; j<=__nwsaom_last_G3.n; j++) {
		for (k=1; k<=__nwsaom_last_G3.n; k++) if (__nwsaom_last_G3.has_edge(j, k) & __nwsaom_last_G3.has_edge(k, j)) rd[j] = rd[j] + 1
	}
	st = __nwsaom_last_M.full_statistic(__nwsaom_last_G3)
	assert(abs(st[3] - sum(__nwsaom_last_G3.din :* rd)) < 1e-9)
	assert(abs(st[4] - sum(__nwsaom_last_G3.dout :* rd)) < 1e-9)
}
dg_reci_check()
end
di as text "reciprocated-degree effects PASS"

* gwdspFF, gwdspFB, betweenness (s50 targets 450.806, 494.808, 291 - dev/saom_rsiena_gwdsp.{R,do}); the statistics against a brute-force count
nwsaom, waves(dg1 dg2 dg3) outdegree reciprocity gwdspff(0.69) gwdspfb(0.69) between k0(30) k3(150) seed(7)
assert colsof(e(b)) == 5 & !missing(el(e(b),1,3), el(e(b),1,5)) & "`e(engine)'" == "native"
mata:
mata set matastrict off
void dg_gwdsp_check() {
	external class ErgmModel scalar __nwsaom_last_M
	external class ErgmGraph scalar __nwsaom_last_G3
	real rowvector st
	real scalar n, i, h, k, ff, fb, bt, cff, cfb
	n = __nwsaom_last_G3.n
	ff = 0
	fb = 0
	bt = 0
	for (i=1; i<=n; i++) {
		for (h=1; h<=n; h++) {
			if (h == i) continue
			cff = 0
			cfb = 0
			for (k=1; k<=n; k++) {
				if (__nwsaom_last_G3.has_edge(i, k) & __nwsaom_last_G3.has_edge(k, h)) cff++
				if (__nwsaom_last_G3.has_edge(i, k) & __nwsaom_last_G3.has_edge(h, k)) cfb++
			}
			ff = ff + gw_kernel(cff, 0.69)
			fb = fb + gw_kernel(cfb, 0.69)
			if (__nwsaom_last_G3.has_edge(h, i)) {
				for (k=1; k<=n; k++) if (k != i & k != h & __nwsaom_last_G3.has_edge(i, k) & !__nwsaom_last_G3.has_edge(h, k)) bt++
			}
		}
	}
	st = __nwsaom_last_M.full_statistic(__nwsaom_last_G3)
	assert(abs(st[3] - ff) < 1e-8 & abs(st[4] - fb) < 1e-8 & abs(st[5] - bt) < 1e-9)
}
dg_gwdsp_check()
end
capture noisily nwsaom, wave1(dg1) wave2(dg2) outdegree gwdspff(-1) k3(50)
assert _rc == 198
di as text "gwdsp and betweenness PASS"
