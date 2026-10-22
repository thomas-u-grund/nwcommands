* nwsaom with time-varying covariates, tvcov(x1 x2 x3): period p uses the covariate of wave p (RSiena's varCovar).
* Real-data agreement with RSiena (s50, alcohol as the changing covariate; observed statistics identical, estimates
* within noise): dev/saom_rsiena_tvcov.{R,do}.
cscript
do unw_core.do
do unw_ergm.do
do unw_saom.do

nwclear
mata:
mata set matastrict off
void tv_data() {
	n = 40
	rseed(1357)
	A = (runiform(n, n) :< 0.08)
	A = A - diag(diag(A))
	for (w=1; w<=3; w++) {
		st_matrix("__W" + strofreal(w), A)
		F = (runiform(n, n) :< 0.05)
		A = abs(A - F)
		A = A - diag(diag(A))
	}
}
tv_data()
end
clear
set obs 40
forvalues w = 1/3 {
	nwset, mat(__W`w') directed name(tv`w') nooutput
}
gen double x1 = mod(_n * 7, 5)
gen double x2 = mod(_n * 7 + (_n > 20), 5)
gen double x3 = mod(_n * 7 + 2 * (_n > 12), 5)
gen double xc1 = x1
gen double xc2 = x1
gen double xc3 = x1

* a covariate that does not change: tvcov(xc1 xc2 xc3) is the same model as the plain covariate (same random numbers)
nwsaom, waves(tv1 tv2 tv3) outdegree reciprocity nodeocov(x1) nodeicov(x1) k0(30) k3(150) seed(5)
matrix __bp = e(b)
nwsaom, waves(tv1 tv2 tv3) outdegree reciprocity tvcov(xc1 xc2 xc3) nodeocov(xc) nodeicov(xc) k0(30) k3(150) seed(5)
matrix __bt = e(b)
assert mreldif(__bp, __bt) < 1e-9
assert "`e(tvcov)'" == " xc"
di as text "constant covariate through tvcov() PASS"

* a really changing covariate gives another model than its first wave's values
nwsaom, waves(tv1 tv2 tv3) outdegree reciprocity tvcov(x1 x2 x3) nodeocov(x) simcov(x) k0(30) k3(150) seed(5)
matrix __bv = e(b)
nwsaom, waves(tv1 tv2 tv3) outdegree reciprocity nodeocov(x1) simcov(x1) k0(30) k3(150) seed(5)
assert mreldif(__bv, e(b)) > 1e-6
assert colsof(__bv) == 4 & !missing(__bv[1,1], __bv[1,4])
di as text "changing covariate PASS"

* the Mata engine (tiny)
global NWSAOM_NONATIVE 1
nwsaom, waves(tv1 tv2 tv3) outdegree reciprocity tvcov(x1 x2 x3) nodeocov(x) k0(20) k3(60) seed(5)
assert "`e(engine)'" == "mata"
global NWSAOM_NONATIVE
di as text "Mata engine PASS"

* refusals: wrong number of variables, missing values, behavior
capture nwsaom, waves(tv1 tv2 tv3) outdegree tvcov(x1) nodeocov(x)
assert _rc == 198
replace x2 = . in 3
capture nwsaom, waves(tv1 tv2 tv3) outdegree tvcov(x1 x2 x3) nodeocov(x) k3(30)
assert _rc == 198
replace x2 = 1 in 3
capture nwsaom, waves(tv1 tv2 tv3) outdegree tvcov(x1 x2 x3) nodeocov(x) behavior(x1 x2 x3) linear
assert _rc == 198
di as text "tvcov refusals PASS"
