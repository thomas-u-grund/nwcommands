* behavior effects of the network x a constant dyadic covariate (behw(): avAltW ... totSimW, parameters 1 and 2; RSiena's default is 2): all observed statistics and
* the estimates equal siena07 (s50 + alcohol, dev/saom_rsiena_behw.{R,do}); here: every family fits natively, names, refusals
cscript
do unw_core.do
do unw_ergm.do
do unw_saom.do
nwclear
clear
set obs 40
mata:
mata set matastrict off
void bw_data() {
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
	D = floor(runiform(n, n) :* 4)
	D = D - diag(diag(D))
	st_matrix("DW", D)
}
bw_data()
end
forvalues w = 1/3 {
	nwset, mat(__W`w') directed name(bw`w') nooutput
}
gen double z1 = mod(_n * 7, 5)
gen double z2 = mod(_n * 7 + (_n > 20), 5)
gen double z3 = mod(_n * 7 + (_n > 20) + (_n > 10), 5)
foreach ef in avaltw totaltw avinaltw totinaltw avwalt totwalt avwinalt totwinalt avsimw totsimw {
	capture nwsaom, waves(bw1 bw2 bw3) outdegree reciprocity behavior(z1 z2 z3 : linear) behw(`ef':DW) k0(10) k3(40) seed(3)
	assert inlist(_rc, 0, 498)
	if _rc == 0 {
		assert "`e(engine)'" == "native" & colsof(e(b)) == 4
		local nm : colnames e(b)
		assert strpos("`nm'", "`ef'_DW") > 0
	}
}
* behwparam(1): RSiena's parameter 1 of avAltW, avInAltW, avSimW (default 2); the names carry _p1
foreach ef in avaltw avinaltw avsimw {
	capture nwsaom, waves(bw1 bw2 bw3) outdegree reciprocity behavior(z1 z2 z3 : linear) behw(`ef':DW) behwparam(1) k0(10) k3(40) seed(3)
	assert inlist(_rc, 0, 498)
	if _rc == 0 {
		assert "`e(engine)'" == "native"
		local nm : colnames e(b)
		assert strpos("`nm'", "`ef'_p1_DW") > 0
	}
}
capture noisily nwsaom, waves(bw1 bw2 bw3) outdegree behavior(z1 z2 z3 : linear) behw(nosuch:DW) k3(50)
assert _rc == 198
capture noisily nwsaom, waves(bw1 bw2 bw3) outdegree behavior(z1 z2 z3 : linear) behw(avaltw:NOMAT) k3(50)
assert _rc == 111
capture noisily nwsaom, waves(bw1 bw2 bw3) outdegree behavior(z1 z2 z3 : linear) behw(avaltw:DW) behwparam(3) k3(50)
assert _rc == 198
capture noisily nwsaom, waves(bw1 bw2 bw3) outdegree behw(avaltw:DW) k3(50)
assert _rc == 198
di "PASS behw"

* changing dyadic covariates (protocol 57): tvbehw(family:stem) with the matrices stem1, stem2 (siena07: dev/saom_rsiena_tvbehw.R/.do)
matrix TV1 = DW
matrix TV2 = DW'
foreach ef in avaltw totaltw avinaltw totinaltw avwalt totwalt avwinalt totwinalt avsimw totsimw {
	capture nwsaom, waves(bw1 bw2 bw3) outdegree reciprocity behavior(z1 z2 z3 : linear) tvbehw(`ef':TV) k0(10) k3(40) seed(3)
	assert inlist(_rc, 0, 498)
	if _rc == 0 {
		assert "`e(engine)'" == "native" & colsof(e(b)) == 4
		local nm : colnames e(b)
		assert strpos("`nm'", "`ef'_TV") > 0
	}
}
capture noisily nwsaom, waves(bw1 bw2 bw3) outdegree behavior(z1 z2 z3 : linear) tvbehw(avaltw:NOSTEM) k3(50)
assert _rc == 111
di "PASS tvbehw"
