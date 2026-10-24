* estat timetest after nwsaom multinet: the per-effect test equals the score test of the model with one fixed period dummy, computed by hand
* from the stored per-period statistics and scores; fixrates (rates known, RSiena's sienaTimeTest) is the same test without the rate parameters.
* (Reference: Glasgow friend network + random second network, 3 waves, RSiena 1.6.14 fixed-dummy score.Test for the second network's outdegree
*  1.16 / 1.26 / 1.10 (seeds 1-3), sienaTimeTest 0.29 / 0.28 / 0.33; nwsaom 1.23 / 1.30 / 1.12 and, with fixrates, in the sienaTimeTest range.)
cscript
do unw_core.do
do unw_ergm.do
do unw_saom.do
nwclear
clear
set obs 40
mata:
mata set matastrict off
void tt_data() {
	n = 40
	rseed(4242)
	A = (runiform(n, n) :< 0.09)
	A = A - diag(diag(A))
	B = (runiform(n, n) :< 0.06)
	B = B - diag(diag(B))
	for (w=1; w<=3; w++) {
		st_matrix("__A" + strofreal(w), A)
		st_matrix("__B" + strofreal(w), B)
		F = (runiform(n, n) :< 0.05)
		A = abs(A - F)
		A = A - diag(diag(A))
		F = (runiform(n, n) :< 0.05)
		B = abs(B - F)
		B = B - diag(diag(B))
	}
}
tt_data()
// hand-made score test of one period dummy of effect j (two periods: dummy for period 2), all rates estimated or known
real scalar tt_hand(real scalar j, real scalar neff, real scalar fixrates) {
	external real matrix __nwsaom_score_Zp, __nwsaom_score_Sp
	ptot = cols(__nwsaom_score_Zp) / 2
	K = rows(__nwsaom_score_Zp)
	Z1 = __nwsaom_score_Zp[., 1..ptot]
	Z2 = __nwsaom_score_Zp[., (ptot+1)..(2*ptot)]
	S1 = __nwsaom_score_Sp[., 1..ptot]
	S2 = __nwsaom_score_Sp[., (ptot+1)..(2*ptot)]
	D1 = ((Z1 :- mean(Z1))' * (S1 :- mean(S1))) / K
	D2 = ((Z2 :- mean(Z2))' * (S2 :- mean(S2))) / K
	Zt = Z1 + Z2
	za = (Zt, Z2[., j])
	m = mean(za)
	S = variance(za)
	use = (fixrates ? (1..neff) : (1..ptot))
	D11 = (D1 + D2)[use, use]
	d21 = D2[j, use]
	rg = d21 * luinv(D11)
	z1 = m[use]'
	ov = m[ptot+1] - rg * z1
	S11 = S[use, use]
	S12 = S[use, ptot+1]
	v = S[ptot+1, ptot+1] - rg * S12 - S12' * rg' + rg * S11 * rg'
	return(ov^2 / v)
}
end
forvalues w = 1/3 {
	nwset, mat(__A`w') directed name(na`w') nooutput
	nwset, mat(__B`w') directed name(nb`w') nooutput
}
* Hand check with 3 waves, two periods: dummy of period 2 for effect j, the other effect's dummies left out (the effect-wise test has df = 1 here).
qui nwsaom multinet, net1(na1 na2 na3) net2(nb1 nb2 nb3) cross1(crprod) eff1(outdegree reciprocity) eff2(outdegree reciprocity) k0(30) k3(200) seed(11)
mata: st_local("p", strofreal(cols(st_matrix("e(b)"))))
estat timetest
matrix E = r(effect)
estat timetest, fixrates
matrix F = r(effect)
forvalues j = 1/`p' {
	mata: st_numscalar("hand", tt_hand(`j', `p', 0))
	mata: st_numscalar("handf", tt_hand(`j', `p', 1))
	di "effect `j': timetest " %9.5f E[`j', 1] "  by hand " %9.5f hand "   fixrates " %9.5f F[`j', 1] "  by hand " %9.5f handf
	assert abs(E[`j', 1] - hand) < 1e-6 * max(1, hand)
	assert abs(F[`j', 1] - handf) < 1e-6 * max(1, handf)
}
di "PASS tt"
