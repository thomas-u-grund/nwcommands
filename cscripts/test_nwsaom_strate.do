* structural rate effects (protocol 42, native only): outrate inrate reciprate outrateinv inrateinv reciprateinv outratelog inratelog recipratelog
* (RSiena outRate ... recipRateLog). Rate covariates that follow the network: estimates agree with siena07 (conditional, s50; dev/saom_rsiena_strate.R).
cscript
do unw_core.do
do unw_saom.do
nwclear
clear
set obs 40
mata:
mata set matastrict off
void sr_data() {
	n = 40
	rseed(77123)
	A = (runiform(n, n) :< 0.10)
	A = A - diag(diag(A))
	for (w=1; w<=3; w++) {
		st_matrix("__W" + strofreal(w), A)
		F = (runiform(n, n) :< 0.06)
		A = abs(A - F)
		A = A - diag(diag(A))
	}
}
sr_data()
end
forvalues w = 1/3 {
	nwset, mat(__W`w') directed name(sr`w') nooutput
}
foreach ef in outrate inrate reciprate outrateinv inrateinv reciprateinv outratelog inratelog recipratelog {
	capture nwsaom, waves(sr1 sr2 sr3) outdegree reciprocity `ef' k0(10) k3(40) seed(3)
	assert inlist(_rc, 0, 498, 505)
	if _rc == 0 {
		assert "`e(engine)'" == "native" & colsof(e(b)) == 2
		assert colsof(e(ratecoefs)) == 1
	}
}
* two of them together, and with ratecov()
gen double zc = mod(_n, 3)
capture nwsaom, waves(sr1 sr2 sr3) outdegree reciprocity outrate inrate ratecov(zc) k0(10) k3(40) seed(3)
assert inlist(_rc, 0, 498, 505)
if _rc == 0 assert colsof(e(ratecoefs)) == 3
* refusals
capture nwsaom, waves(sr1 sr2 sr3) outdegree outrate behavior(zc zc zc) k3(30)
assert _rc != 0
di as text "structural rate effects PASS"
