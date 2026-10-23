* nwsaom_meta: the multi-group meta-analysis (RSiena siena08). Mata port checked against RSiena 1.6.6 (dev/saom_meta_check.{R,do}), real fits below.
cscript
do unw_core.do
do unw_ergm.do
do unw_saom.do

* 1. made-up group estimates: the numbers RSiena's iwlsm/maxlik/confint.mu/confint.sig give (R: dev/saom_meta_check.R)
local th "0.8 1.2 0.5 1.6 0.9 1.1 -0.2 2.1"
local se "0.3 0.4 0.25 0.5 0.35 0.3 0.6 0.45"
clear
set obs 5
gen byte touse = 1
capture program drop mk_est
program mk_est, eclass
	args g th se
	tempname b V
	matrix `b' = (`th')
	matrix colnames `b' = eff
	matrix `V' = (`se')^2
	matrix colnames `V' = eff
	matrix rownames `V' = eff
	ereturn post `b' `V'
	ereturn local cmd "fakefit"
	estimates store g`g'
end
forvalues g = 1/8 {
	mk_est `g' `: word `g' of `th'' `: word `g' of `se''
}
nwsaom_meta g1 g2 g3 g4 g5 g6 g7 g8, notable
matrix M = r(meta)
assert reldif(M[1,4], 0.99902) < 1e-4 & reldif(M[1,5], 0.22069) < 1e-4 & reldif(M[1,8], 0.6242) < 1e-4
assert reldif(M[1,9], 72.29669) < 1e-6 & reldif(M[1,11], 16.03115) < 1e-6 & reldif(M[1,12], 0.02483) < 1e-3
assert reldif(M[1,13], 0.98569) < 1e-4 & reldif(M[1,14], 0.17689) < 1e-4 & reldif(M[1,15], 0.5871) < 1e-3 & reldif(M[1,16], 1.41721) < 1e-3
assert reldif(M[1,17], 0.33111) < 1e-3 & M[1,18] == 0 & reldif(M[1,19], 0.90395) < 1e-3
assert reldif(M[1,20], 102.75934) < 1e-6 & reldif(M[1,22], 2.05971) < 1e-4 & M[1,1] == 8
di as text "meta-analysis numbers match RSiena PASS"

* 2. real fits on four small networks, the same model
mata:
mata set matastrict off
void mt_data(real scalar g) {
	n = 30
	rseed(2000 + g)
	A = (runiform(n, n) :< 0.10)
	A = A - diag(diag(A))
	st_matrix("__MA", A)
	F = (runiform(n, n) :< 0.06)
	A = abs(A - F)
	A = A - diag(diag(A))
	st_matrix("__MB", A)
}
end
clear
set obs 30
forvalues g = 1/4 {
	nwclear
	mata: mt_data(`g')
	nwset, mat(__MA) directed name(ma) nooutput
	nwset, mat(__MB) directed name(mb) nooutput
	nwsaom, waves(ma mb) outdegree reciprocity k0(20) k3(60) seed(`g')
	estimates store c`g'
}
nwsaom_meta c1 c2 c3 c4, rates
matrix M = r(meta)
assert rowsof(M) == 3 & M[1,1] > 0 & !missing(M[1,4])
assert r(groups) == 4
di as text "meta-analysis of real nwsaom fits PASS"

* 3. refusals
capture noisily nwsaom_meta c1 nosuch
assert _rc == 111
capture noisily nwsaom_meta g1 c1
assert _rc == 198
di as text "nwsaom_meta input checks PASS"

* 4. the subcommand form: nwsaom meta == nwsaom_meta
capture noisily nwsaom meta c1 nosuch
assert _rc == 111
nwsaom_meta c1 c2, notable
matrix M1 = r(meta)
nwsaom meta c1 c2, notable
matrix M2 = r(meta)
assert mreldif(M1, M2) < 1e-12
di as text "nwsaom meta subcommand PASS"
