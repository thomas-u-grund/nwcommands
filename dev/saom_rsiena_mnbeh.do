* nwsaom multinet + behavior counterpart of dev/saom_rsiena_mnbeh.R. Globals: BEH12 BEH21 (behavior effects of both networks), XB1 (further behavior effects of net1), SEEDS, K3
quietly do unw_core.do
quietly do unw_ergm.do
quietly do unw_saom.do
nwclear
forvalues w = 1/3 {
	import delimited "dev/saom_rsiena_netendow_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(W`w')
	import delimited "dev/saom_mn_b`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(B`w')
}
if "$MISS" == "1" import delimited "dev/saom_rsiena_mnbeh_miss.csv", clear varnames(1)
else import delimited "dev/saom_rsiena_multibeh_data.csv", clear varnames(1)
gen double xa = mod(_n * 7, 5)
forvalues w = 1/3 {
	nwset, mat(W`w') directed name(na`w') nooutput
	nwset, mat(B`w') directed name(nb`w') nooutput
}
if "$SEEDS" == "" global SEEDS 2
if "$K3" == "" global K3 1000
if "$XB1" == "" global XB1 "linear quadratic avalt"
forvalues s = 1/$SEEDS {
	nwsaom multinet, net1(na1 na2 na3) net2(nb1 nb2 nb3) behavior(a1 a2 a3) eff1(outdegree reciprocity $N1) eff2(outdegree reciprocity $N2) beheff1($XB1) beheff2($XB2) beheff12($BEH12) beheff21($BEH21) $MISSOPT k0(50) k3($K3) seed(`s')
	matrix bb = e(b)
	matrix se = vecdiag(e(V))
	matrix rr = e(rates)
	local cn : colfullnames bb
	di "MNB names: `cn'"
	local o ""
	local ose ""
	forvalues j = 1/`=colsof(bb)' {
		local o "`o' `: di %7.3f bb[1,`j']'"
		local ose "`ose' `: di %6.3f sqrt(se[1,`j'])'"
	}
	di "MNB seed `s' est:`o'"
	di "MNB seed `s' se:`ose'"
	di "MNB seed `s' rates:" _c
	forvalues j = 1/`=colsof(rr)' {
		forvalues i = 1/3 {
			di " " %6.3f rr[`i',`j'] _c
		}
	}
	di ""
	matrix tg = e(target)
	forvalues pd = 1/`=rowsof(tg)' {
		local o ""
		forvalues j = 1/`=colsof(tg)' {
			local o "`o' `: di %8.3f tg[`pd',`j']'"
		}
		di "MNB target period`pd':`o'"
	}
}
