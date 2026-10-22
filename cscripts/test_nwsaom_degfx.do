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
di as text "degree effects PASS"
