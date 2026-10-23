* observed statistics (e(target), summed over the periods) of behavior effects in nwsaom multinet; counterpart of dev/saom_rsiena_mnbeh_targets.R. Globals: B1 B2 B12 B21 (the effect lists)
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
import delimited "dev/saom_rsiena_multibeh_data.csv", clear varnames(1)
gen double xa = mod(_n * 7, 5)
forvalues w = 1/3 {
	nwset, mat(W`w') directed name(na`w') nooutput
	nwset, mat(B`w') directed name(nb`w') nooutput
}
nwsaom multinet, net1(na1 na2 na3) net2(nb1 nb2 nb3) behavior(a1 a2 a3) eff1(outdegree reciprocity $N1) eff2(outdegree reciprocity $N2) beheff1(linear quadratic $B1) beheff2($B2) beheff12($B12) beheff21($B21) behint($BI) k0(3) k3(10) fix(net1_reciprocity net2_reciprocity beh_linear beh_quadratic $FIX) seed(1)
matrix tg = e(target)
local cn : colnames tg
forvalues j = 1/`=colsof(tg)' {
	local s = 0
	forvalues pd = 1/`=rowsof(tg)' {
		local s = `s' + tg[`pd',`j']
	}
	local nm : word `j' of `cn'
	di "NWT `nm' " %10.4f `s'
}
