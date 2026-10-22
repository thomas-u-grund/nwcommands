* behavior effects of network position / alters / similarity (beheff()): the 20 tokens indeg ... avsimpopego; all observed statistics and
* the estimates equal siena07 (s50 + alcohol, dev/saom_rsiena_behnet.{R,do}); here: every token fits natively and the refusals
cscript
do unw_core.do
do unw_ergm.do
do unw_saom.do
nwclear
clear
set obs 40
mata:
mata set matastrict off
void bs_data() {
	n = 40
	rseed(8642)
	A = (runiform(n, n) :< 0.09)
	A = A - diag(diag(A))
	for (w=1; w<=3; w++) {
		st_matrix("__W" + strofreal(w), A)
		F = (runiform(n, n) :< 0.05)
		A = abs(A - F)
		A = A - diag(diag(A))
	}
}
bs_data()
end
forvalues w = 1/3 {
	nwset, mat(__W`w') directed name(bs`w') nooutput
}
gen double z1 = mod(_n * 7, 5)
gen double z2 = mod(_n * 7 + (_n > 20), 5)
gen double z3 = mod(_n * 7 + (_n > 20) + (_n > 10), 5)
foreach ef in indeg outdeg recipdeg isolate outisolate totalt avaltpop totaltpop maxalt minalt avrecalt totrecalt totsim avatthigher avattlower totatthigher totattlower avsimpopalt totsimpopalt avsimpopego {
	capture nwsaom, waves(bs1 bs2 bs3) outdegree reciprocity behavior(z1 z2 z3 : linear) beheff(`ef') k0(10) k3(40) seed(3)
	assert inlist(_rc, 0, 498)
	if _rc == 0 {
		assert "`e(engine)'" == "native" & colsof(e(b)) == 4
	}
}
* the native engine reproduces the Mata engine (when the synthetic data identify the effect)
capture nwsaom, waves(bs1 bs2 bs3) outdegree reciprocity behavior(z1 z2 z3 : linear) beheff(recipdeg) k0(30) k3(200) seed(3)
local rn = _rc
if `rn' == 0 {
	assert "`e(engine)'" == "native"
	matrix bn = e(b)
	global NWSAOM_NONATIVE 1
	capture nwsaom, waves(bs1 bs2 bs3) outdegree reciprocity behavior(z1 z2 z3 : linear) beheff(recipdeg) k0(30) k3(200) seed(3)
	global NWSAOM_NONATIVE 0
	if _rc == 0 {
		matrix bm = e(b)
		forvalues c = 1/4 {
			assert abs(bn[1,`c'] - bm[1,`c']) < 1.5
		}
	}
}
capture noisily nwsaom, waves(bs1 bs2 bs3) outdegree beheff(nosuchtoken) k3(50)
assert _rc == 198
capture noisily nwsaom, waves(bs1 bs2 bs3) outdegree beheff(indeg) k3(50)
assert _rc == 198
di as text "behavior network effects PASS"
