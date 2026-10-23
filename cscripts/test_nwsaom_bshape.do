* behavior shape effects (behshape(): quad_cc quad_nc constant threshold:# simallnear:# simallfar:# avgroup:# totgroup:#), plugin protocol 51; estimates equal
* siena07 (s50 + alcohol, dev/saom_rsiena_bshape.{R,do}); here: every effect fits natively, names, refusals. (constant equals minus the rate statistic: singular, rc 505)
cscript
do unw_core.do
do unw_ergm.do
do unw_saom.do
nwclear
clear
set obs 40
mata:
mata set matastrict off
void bh_data() {
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
bh_data()
end
forvalues w = 1/3 {
	nwset, mat(__W`w') directed name(bh`w') nooutput
}
gen double z1 = mod(_n * 7, 5)
gen double z2 = mod(_n * 7 + (_n > 20), 5)
gen double z3 = mod(_n * 7 + (_n > 20) + (_n > 10), 5)
foreach ef in quad_cc quad_nc threshold:2 simallnear:2 simallfar:3 avgroup:1 totgroup:1 avgroup totgroup simallnear simallfar {
	capture nwsaom, waves(bh1 bh2 bh3) outdegree reciprocity behavior(z1 z2 z3 : linear) behshape(`ef') k0(10) k3(40) seed(3)
	assert inlist(_rc, 0, 498, 505)
	if _rc == 0 {
		assert "`e(engine)'" == "native" & colsof(e(b)) == 4
		local nm : colnames e(b)
		assert strpos("`nm'", "beh_") > 0
	}
}
capture noisily nwsaom, waves(bh1 bh2 bh3) outdegree behavior(z1 z2 z3 : linear) behshape(nosuch) k3(50)
assert _rc == 198
capture noisily nwsaom, waves(bh1 bh2 bh3) outdegree behavior(z1 z2 z3 : linear) behshape(threshold) k3(50)
assert _rc == 198
capture noisily nwsaom, waves(bh1 bh2 bh3) outdegree behavior(z1 z2 z3 : linear) behshape(quad_cc:2) k3(50)
assert _rc == 198
capture noisily nwsaom, waves(bh1 bh2 bh3) outdegree behshape(avgroup) k3(50)
assert _rc == 198
di "PASS bshape"
