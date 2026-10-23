* nwsaom multinet: two co-evolving networks with cross-network effects (plugin protocol 52). siena07 agreement (observed statistics and estimates):
* dev/saom_rsiena_mn.R / .do (s50 friendship + a second network); here: every cross-network effect runs natively, refusals
cscript
do unw_core.do
do unw_ergm.do
do unw_saom.do
nwclear
clear
set obs 40
mata:
mata set matastrict off
void mn_data() {
	n = 40
	rseed(7771)
	A = (runiform(n, n) :< 0.09)
	A = A - diag(diag(A))
	B = (runiform(n, n) :< 0.06)
	B = B - diag(diag(B))
	for (w=1; w<=3; w++) {
		st_matrix("__A" + strofreal(w), A)
		st_matrix("__B" + strofreal(w), B)
		F = (runiform(n, n) :< 0.04)
		A = abs(A - F)
		A = A - diag(diag(A))
		F = (runiform(n, n) :< 0.04)
		B = abs(B - F)
		B = B - diag(diag(B))
	}
}
mn_data()
end
forvalues w = 1/3 {
	nwset, mat(__A`w') directed name(na`w') nooutput
	nwset, mat(__B`w') directed name(nb`w') nooutput
}
gen double xa = mod(_n * 7, 4)
foreach ef in crprod crprodrecip crprodmutual from frommutual fromany to toback torecip clxwx clxwx1 clxwx2 mixedinxw ///
	inpopintn inactintn crprodinactintn outpopintn outactintn divoutegointn divinegointn divoutaltintn divinaltintn avdegintn absoutdiffintn both ///
	outoutactintn outoutavintn dist2outinactintn outoutdist2actintn ndist2actintn doubleoutact ///
	closure cyclosure sharedin wwxee wwxfr wxxfe wxxer xwxer xwxfe jinmix joutmix gwespffmix gwespbbmix gwespbfmix gwespfbmix gwesprrmix inpopoutw sharedto avalt2mtie avalt2mtot doubleinpop {
	capture nwsaom multinet, net1(na1 na2 na3) net2(nb1 nb2 nb3) cross1(`ef') k0(10) k3(40) seed(3)
	assert inlist(_rc, 0, 498, 505)
	if _rc == 0 {
		assert "`e(engine)'" == "native" & colsof(e(b)) == 5
		local nm : colnames e(b)
		assert strpos("`nm'", "net1_x_`ef'") > 0
		assert colsof(e(rates)) == 2 & rowsof(e(rates)) == 4
	}
}
* cross effects of both networks, covariate effects, a third effect
capture nwsaom multinet, net1(na1 na2 na3) net2(nb1 nb2 nb3) eff1(outdegree reciprocity transtrip egox:xa) eff2(outdegree reciprocity) cross1(crprod to) cross2(crprodrecip) k0(10) k3(40) seed(3)
assert inlist(_rc, 0, 498, 505)
if _rc == 0 assert colsof(e(b)) == 9
capture noisily nwsaom multinet, net1(na1 na2 na3) net2(nb1 nb2 nb3) cross1(nosuch) k3(30)
assert _rc == 198
capture noisily nwsaom multinet, net1(na1 na2 na3) net2(nb1 nb2) k3(30)
assert _rc == 198
capture noisily nwsaom multinet, net1(na1 na2 na3) net2(nb1 nb2 nb3) eff1(nosuch) k3(30)
assert _rc == 198
di "PASS multinet"

* cross-network effects with a covariate (protocol 56): siena07 agreement in dev/saom_rsiena_xc.R/.do; here every effect fits natively
gen double xc = mod(_n * 7, 5)
foreach ef in samewwclosure diffwwclosure jumpwwclosure jumpfrom jumpsharedin samewxclosure diffwxclosure jumpwxclosure homwxclosure samexwclosure diffxwclosure ///
	covnetnet homcovnetnet contrastcovnetnet alldifcovnetnet covnetnetin homcovnetnetin contrastcovnetnetin alldifcovnetnetin inpopintnx inactintnx outpopintnx outactintnx ///
	samexinpopintn samexinactintn samexoutpopintn samexoutactintn altdist2w totdist2w simdist2w altindist2w totindist2w simegodist2w simegoindist2w {
	capture nwsaom multinet, net1(na1 na2 na3) net2(nb1 nb2 nb3) cross1(`ef':xc) k0(10) k3(40) seed(3)
	assert inlist(_rc, 0, 498, 505)
	if _rc == 0 {
		assert "`e(engine)'" == "native" & colsof(e(b)) == 5
		local nm : colnames e(b)
		assert strpos("`nm'", "xc_`ef'_xc") > 0
	}
}
capture nwsaom multinet, net1(na1 na2 na3) net2(nb1 nb2 nb3) cross1(covnetnet:nosuchvar) k3(30)
assert _rc != 0
di "PASS multinet covariate effects"

