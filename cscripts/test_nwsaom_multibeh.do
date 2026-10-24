* nwsaom with several co-evolving behaviors: behavior(a1 a2 a3 : linear quadratic avalt | b1 b2 b3 : linear avalt)
* Real-data agreement with RSiena (s50 + alcohol + smoking): dev/saom_rsiena_multibeh.{R,do}.
cscript
do unw_core.do
do unw_saom.do

nwclear
set seed 5150
clear
set obs 40
mata:
mata set matastrict off
void mb_data() {
	n = 40
	rseed(31337)
	A = (runiform(n, n) :< 0.08)
	A = A - diag(diag(A))
	for (w=1; w<=3; w++) {
		st_matrix("__W" + strofreal(w), A)
		F = (runiform(n, n) :< 0.05)
		A = abs(A - F)
		A = A - diag(diag(A))
	}
}
mb_data()
end
forvalues w = 1/3 {
	nwset, mat(__W`w') directed name(mb`w') nooutput
}
gen byte a1 = 1 + mod(_n*3, 4)
gen byte a2 = 1 + mod(_n*3 + (_n > 20), 4)
gen byte a3 = 1 + mod(_n*3 + 2*(_n > 12), 4)
gen byte s1 = 1 + mod(_n*5, 3)
gen byte s2 = 1 + mod(_n*5 + (_n > 25), 3)
gen byte s3 = 1 + mod(_n*5 + (_n > 8), 3)

* the colon syntax with ONE behavior equals the global effect options (same random numbers)
capture nwsaom, waves(mb1 mb2 mb3) outdegree reciprocity behavior(a1 a2 a3) linear quadratic avalt k0(30) k3(100) seed(7)
local rc1 = _rc
if `rc1' == 0 matrix __b1 = e(b)
capture nwsaom, waves(mb1 mb2 mb3) outdegree reciprocity behavior(a1 a2 a3 : linear quadratic avalt) k0(30) k3(100) seed(7)
assert _rc == `rc1'
if `rc1' == 0 assert mreldif(__b1, e(b)) < 1e-12
di as text "one behavior, colon syntax PASS"

* two behaviors, native (random behaviors are not identifiable, so rc 0 or 498 are both fine; the point is the plumbing)
capture nwsaom, waves(mb1 mb2 mb3) outdegree reciprocity behavior(a1 a2 a3 : linear avalt | s1 s2 s3 : linear avalt) k0(30) k3(100) seed(7)
assert inlist(_rc, 0, 498)
if _rc == 0 {
	assert e(nbeh) == 2 & colsof(e(b)) == 2 + 2 + 2
	assert "`e(behavior_names)'" == " a s"
	assert rowsof(e(rates_beh)) == 2 & colsof(e(rates_beh)) == 2 & colsof(e(rates)) == 2
	local cn : colfullnames e(b)
	assert strpos("`cn'", "beh_a_linear") & strpos("`cn'", "beh_s_avalt")
	assert "`e(engine)'" == "native"
}
di as text "two behaviors, native PASS"

* two waves with two behaviors (wave1/wave2 path)
capture nwsaom, wave1(mb1) wave2(mb2) outdegree reciprocity behavior(a1 a2 : linear | s1 s2 : linear) k0(30) k3(100) seed(7)
assert inlist(_rc, 0, 498)
if _rc == 0 assert e(nbeh) == 2 & colsof(e(rates)) == 1

* the Mata engine gives a result of the same shape
global NWSAOM_NONATIVE 1
capture nwsaom, wave1(mb1) wave2(mb2) outdegree reciprocity behavior(a1 a2 : linear | s1 s2 : linear) k0(20) k3(40) seed(7)
assert inlist(_rc, 0, 498)
if _rc == 0 assert e(nbeh) == 2 & "`e(engine)'" == "mata"
global NWSAOM_NONATIVE
di as text "two behaviors, Mata engine PASS"

* refusals: wrong number of variables, unknown effect, behsim on a second behavior, unsupported combinations
capture nwsaom, waves(mb1 mb2 mb3) outdegree behavior(a1 a2 a3 : linear | s1 s2 : linear)
assert _rc == 198
capture nwsaom, waves(mb1 mb2 mb3) outdegree behavior(a1 a2 a3 : linear | s1 s2 s3 : bogus)
assert _rc == 198
capture nwsaom, waves(mb1 mb2 mb3) outdegree behavior(a1 a2 a3 : linear | s1 s2 s3 : linear behsim)
assert _rc == 198
capture nwsaom, waves(mb1 mb2 mb3) outdegree symmetric behavior(a1 a2 a3 : linear | s1 s2 s3 : linear)
assert _rc == 198
di as text "multi-behavior refusals PASS"
