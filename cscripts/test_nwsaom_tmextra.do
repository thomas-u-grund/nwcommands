* two-mode (bipartite) networks: degree functions, centred degree effects, covariate-weighted degree effects and covariate threshold / contrast
* effects (native only). siena07 agreement: dev/saom_rsiena_tm_extra.R (40 x 20; observed statistics identical, estimates within noise).
cscript
do unw_core.do
do unw_ergm.do
do unw_saom.do
nwclear
mata:
mata set matastrict off
void te_data() {
	na = 24
	ne = 10
	rseed(1357)
	X = (runiform(na, ne) :< 0.18)
	for (w=1; w<=3; w++) {
		st_matrix("__T" + strofreal(w), X)
		F = (runiform(na, ne) :< 0.12)
		X = abs(X - F)
	}
	st_matrix("__CA", floor(runiform(na, 1) * 3))
	st_matrix("__CB", floor(runiform(ne, 1) * 3))
}
te_data()
end
clear
forvalues w = 1/3 {
	nwset, mat(__T`w') bipartite name(te`w') nooutput
}
gen double xa = .
gen double xe = .
mata: md = st_sdata(., "_nwmode"); st_store(selectindex(md :== "2"), "xa", st_matrix("__CA")); st_store(selectindex(md :== "1"), "xe", st_matrix("__CB"))
foreach spec in "outtrunc(2)" "outmore(2)" "outthreshold(2)" "outinv(1)" "outsqinv(1)" "inpopc" "outactc" "diffxinpop(xa)" "altxoutact(xe)" "altlthresholdx(xe)" "altrthresholdx(xe)" "egolthresholdx(xa)" "degabsdiffx(xa)" {
	capture nwsaom, waves(te1 te2 te3) outdegree `spec' k0(10) k3(30) seed(3)
	assert inlist(_rc, 0, 498, 505)
	if _rc == 0 assert "`e(engine)'" == "native" & e(twomode) == 1 & colsof(e(b)) == 2
}
* an effect with a covariate of the wrong kind for a two-mode network is refused
capture nwsaom, waves(te1 te2 te3) outdegree diffsqx(xa) k3(30)
assert _rc == 198
capture nwsaom, waves(te1 te2 te3) outdegree avdeg(2) k3(30)
assert _rc == 198
di as text "two-mode extras PASS"
