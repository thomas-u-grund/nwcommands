* more behavior effects of the network (behnet2(): indegavgroup indegtotgroup avaltcc totaltcc avinaltdist2nc ... totgwdspfbaltnc avinsimdist2 totinsimdist2), plugin protocol 55;
* siena07 agreement (s50 + alcohol): dev/saom_rsiena_bu.{R,do}; here: every effect fits natively, refusals
cscript
do unw_core.do
do unw_ergm.do
do unw_saom.do
nwclear
clear
set obs 40
mata:
mata set matastrict off
void bu_data() {
	n = 40
	rseed(1357)
	A = (runiform(n, n) :< 0.09)
	A = A - diag(diag(A))
	for (w=1; w<=3; w++) {
		st_matrix("__W" + strofreal(w), A)
		F = (runiform(n, n) :< 0.05)
		A = abs(A - F)
		A = A - diag(diag(A))
	}
}
bu_data()
end
forvalues w = 1/3 {
	nwset, mat(__W`w') directed name(bu`w') nooutput
}
gen double z1 = mod(_n * 7, 5)
gen double z2 = mod(_n * 7 + (_n > 20), 5)
gen double z3 = mod(_n * 7 + (_n > 20) + (_n > 10), 5)
foreach ef in indegavgroup indegtotgroup indegavgroup:2 avaltcc totaltcc avinaltdist2nc totinaltdist2nc avtinaltdist2nc totainaltdist2nc avinsimdist2 totinsimdist2 totgwdspffalt totgwdspfbalt totgwdspffaltnc totgwdspfbaltnc totgwdspffalt:50 {
	capture nwsaom, waves(bu1 bu2 bu3) outdegree reciprocity behavior(z1 z2 z3 : linear avalt) behnet2(`ef') k0(10) k3(40) seed(3)
	assert inlist(_rc, 0, 498, 505)
	if _rc == 0 assert "`e(engine)'" == "native" & colsof(e(b)) == 5
}
capture noisily nwsaom, waves(bu1 bu2 bu3) outdegree behavior(z1 z2 z3 : linear avalt) behnet2(nosuch) k3(30)
assert _rc == 198
di "PASS behnet2"
