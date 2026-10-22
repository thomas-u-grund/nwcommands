* nwsaom with joiners and leavers at fractional times, joinat(var) leaveat(var): RSiena's sienaCompositionChange().
* Real-data agreement with RSiena (s50, 3 waves, estimates within noise): dev/saom_rsiena_timedcomp.{R,do};
* simulation agreement at fixed parameters (5 scenarios): dev/saom_rsiena_tc_scen.R, dev/check_timed_fixed.do.
cscript
do unw_core.do
do unw_ergm.do
do unw_saom.do

nwclear
mata:
mata set matastrict off
void tc_data() {
	n = 30
	rseed(2468)
	A = (runiform(n, n) :< 0.10)
	A = A - diag(diag(A))
	for (w=1; w<=3; w++) {
		st_matrix("__W" + strofreal(w), A)
		F = (runiform(n, n) :< 0.06)
		A = abs(A - F)
		A = A - diag(diag(A))
	}
}
tc_data()
end
clear
set obs 30
forvalues w = 1/3 {
	nwset, mat(__W`w') directed name(tc`w') nooutput
}
gen double jn = 1
gen double lv = 3
replace jn = 1.4 in 1/2
replace lv = 1.6 in 3/4
replace lv = 2.5 in 5
replace jn = 2.3 in 6

* a fit with join and leave events runs and is reproducible
nwsaom, waves(tc1 tc2 tc3) outdegree reciprocity joinat(jn) leaveat(lv) k0(30) k3(200) seed(7)
matrix __b1 = e(b)
assert __b1[1,1] < . & __b1[1,2] < .
nwsaom, waves(tc1 tc2 tc3) outdegree reciprocity joinat(jn) leaveat(lv) k0(30) k3(200) seed(7)
assert mreldif(__b1, e(b)) < 1e-12
di as text "timed composition change runs, reproducible PASS"

* joinat() alone / leaveat() alone, and with ratecov()
nwsaom, waves(tc1 tc2 tc3) outdegree reciprocity joinat(jn) k0(30) k3(100) seed(3)
nwsaom, waves(tc1 tc2 tc3) outdegree reciprocity leaveat(lv) ratecov(jn) k0(30) k3(100) seed(3)
di as text "joinat() / leaveat() alone, with ratecov() PASS"

* invalid input
capture noisily nwsaom, waves(tc1 tc2 tc3) outdegree joinat(jn) leaveat(lv) present(jn jn jn) k3(50)
assert _rc == 198
gen double bad1 = 0.5
capture noisily nwsaom, waves(tc1 tc2 tc3) outdegree joinat(bad1) k3(50)
assert _rc == 198
gen double bad2 = 4
capture noisily nwsaom, waves(tc1 tc2 tc3) outdegree leaveat(bad2) k3(50)
assert _rc == 198
gen double inb = 1.4 in 1
replace inb = 1 if missing(inb)
gen double inb2 = 3
replace inb2 = 1.6 in 1
capture noisily nwsaom, waves(tc1 tc2 tc3) outdegree joinat(inb) leaveat(inb2) k3(50)
assert _rc == 198
capture noisily nwsaom, waves(tc1 tc2 tc3) outdegree joinat(jn) symmetric k3(50)
assert _rc == 198
di as text "invalid input refused PASS"
