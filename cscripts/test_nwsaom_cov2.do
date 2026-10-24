* nwsaom diffx, higher, egosqx, altsqx, samexrecip, simrecipx (RSiena diffX, higher, egoSqX, altSqX, sameXRecip, simRecipX).
* Real-data agreement with RSiena 1.6.6 (s50, alcohol; targets -10, 122.5, 327.587, 303.187, 52, 13.655 identical,
* estimates within noise): dev/saom_rsiena_cov2.{R,do}.
cscript
do unw_core.do
do unw_saom.do
nwclear
clear
set obs 36
mata:
mata set matastrict off
void c2_data() {
	n = 36
	rseed(86420)
	A = (runiform(n, n) :< 0.10)
	A = A - diag(diag(A))
	for (w=1; w<=3; w++) {
		st_matrix("__W" + strofreal(w), A)
		F = (runiform(n, n) :< 0.05)
		A = abs(A - F)
		A = A - diag(diag(A))
	}
}
c2_data()
end
forvalues w = 1/3 {
	nwset, mat(__W`w') directed name(c2`w') nooutput
}
gen double z = mod(_n * 5, 4)
foreach ef in diffx higher egosqx altsqx samexrecip simrecipx {
	nwsaom, wave1(c22) wave2(c23) outdegree reciprocity `ef'(z) k0(30) k3(120) seed(2)
	assert colsof(e(b)) == 3 & !missing(el(e(b),1,3)) & "`e(engine)'" == "native"
	* the observed statistic is the tie sum of the definition
	mata: A = __nwsaom_last_G2.to_dense(); R = A :* A'; x = st_data(1::36, "z"); xm = x :- mean(x); XI = xm * J(1, 36, 1); XJ = J(36, 1, 1) * xm'; ZI = x * J(1, 36, 1); ZJ = J(36, 1, 1) * x'
	mata: stv = __nwsaom_last_M.full_statistic(__nwsaom_last_G2); st_numscalar("__obs", stv[3])
	if "`ef'" == "diffx" mata: st_numscalar("__ref", sum(A :* (XJ - XI)))
	if "`ef'" == "higher" mata: st_numscalar("__ref", sum(A :* ((XI :> XJ) + 0.5 * (XI :== XJ))))
	if "`ef'" == "egosqx" mata: st_numscalar("__ref", sum(A :* XI:^2))
	if "`ef'" == "altsqx" mata: st_numscalar("__ref", sum(A :* XJ:^2))
	if "`ef'" == "samexrecip" mata: st_numscalar("__ref", sum(R :* (ZI :== ZJ)))
	if "`ef'" != "simrecipx" assert abs(scalar(__obs) - scalar(__ref)) < 1e-9
}
global NWSAOM_NONATIVE 1
nwsaom, wave1(c22) wave2(c23) outdegree higher(z) k0(20) k3(50) seed(2)
assert "`e(engine)'" == "mata"
global NWSAOM_NONATIVE
capture nwsaom, wave1(c22) wave2(c23) outdegree diffx(z) symmetric
assert _rc != 0
* missing covariate values (RSiena: pairs with a missing value are skipped; higher counts them 0.5)
replace z = . in 3/5
foreach ef in absdiffx egoxaltx diffx higher egosqx altsqx samexrecip simrecipx {
	nwsaom, wave1(c22) wave2(c23) outdegree `ef'(z) k0(30) k3(100) seed(2)
	assert colsof(e(b)) == 2 & !missing(el(e(b),1,2)) & "`e(engine)'" == "native"
}
mata: A = __nwsaom_last_G2.to_dense(); x = st_data(1::36, "z"); ok = (x :< .); K = (ok * ok')
mata: st_numscalar("__ties", sum(A)); st_numscalar("__obsties", sum(A :* K))
assert scalar(__obsties) < scalar(__ties)
nwsaom, wave1(c22) wave2(c23) outdegree diffx(z) k0(30) k3(100) seed(2)
mata: A = __nwsaom_last_G2.to_dense(); x = st_data(1::36, "z"); ok = (x :< .); xm = x :- mean(select(x, ok)); xm = editmissing(xm, 0); stv = __nwsaom_last_M.full_statistic(__nwsaom_last_G2)
mata: XI = xm * J(1, 36, 1); XJ = J(36, 1, 1) * xm'; K = (ok * ok'); st_numscalar("__ref", sum(A :* K :* (XJ - XI))); st_numscalar("__obs", stv[2])
assert abs(scalar(__ref) - scalar(__obs)) < 1e-9
* endow/creation split of covariate effects: endow(altx:z) creation(altx:z) (RSiena includeEffects(altX, type = "endow"/"creation"))
replace z = mod(_n * 5, 4)
foreach ef in altx egox samex simx {
	nwsaom, waves(c21 c22 c23) outdegree reciprocity endow(`ef':z) creation(`ef':z) k0(30) k3(120) seed(2)
	assert colsof(e(b)) == 4 & !missing(el(e(b),1,3), el(e(b),1,4)) & "`e(engine)'" == "native"
	local cn : colfullnames e(b)
	assert strpos("`cn'", "`ef'endow_z") & strpos("`cn'", "`ef'creation_z")
}
capture nwsaom, waves(c21 c22 c23) outdegree endow(altx:z)
assert _rc == 198
capture nwsaom, waves(c21 c22 c23) outdegree altx(z) endow(altx:z) creation(altx:z)
assert _rc == 198
global NWSAOM_NONATIVE 1
nwsaom, wave1(c22) wave2(c23) outdegree endow(samex:z) creation(samex:z) k0(20) k3(50) seed(2)
assert "`e(engine)'" == "mata"
global NWSAOM_NONATIVE
di as text "covariate variants PASS"
