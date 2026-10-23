* nwsaom multinet counterpart of dev/saom_rsiena_mnbeh_sym.R: directed network + a non-directed second network (sym2) + behavior. Globals: BEH12 (effects, first = net1), SEEDS, K3, FIX (fix list)
quietly do unw_core.do
quietly do unw_ergm.do
quietly do unw_saom.do
nwclear
forvalues w = 1/3 {
	import delimited "dev/saom_rsiena_netendow_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(W`w')
	import delimited "sym_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(S`w')
}
import delimited "dev/saom_rsiena_multibeh_data.csv", clear varnames(1)
forvalues w = 1/3 {
	nwset, mat(W`w') directed name(na`w') nooutput
	nwset, mat(S`w') undirected name(ns`w') nooutput
}
if "$SEEDS" == "" global SEEDS 2
if "$K3" == "" global K3 1000
forvalues s = 1/$SEEDS {
	nwsaom multinet, net1(na1 na2 na3) net2(ns1 ns2 ns3) sym2 behavior(a1 a2 a3) eff1(outdegree reciprocity) eff2(outdegree) beheff1(linear quadratic avalt) beheff12($BEH12) k0(50) k3($K3) $FIXOPT seed(`s')
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
	matrix tg = e(target)
	forvalues pd = 1/`=rowsof(tg)' {
		local o ""
		forvalues j = 1/`=colsof(tg)' {
			local o "`o' `: di %8.3f tg[`pd',`j']'"
		}
		di "MNB target period`pd':`o'"
	}
}
