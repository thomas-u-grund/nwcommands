* nwsaom counterpart of dev/saom_rsiena_netfx_tmbeh.R: bipartite network effects with the dependent behavior of the actors as the covariate
qui do unw_core.do
qui do unw_ergm.do
qui do unw_saom.do
nwclear
forvalues w = 1/3 {
	import delimited "dev/saom_twomode_w`w'.csv", clear varnames(1)
	mkmat v1-v20, matrix(T`w')
}
import delimited "dev/saom_netfx_tmbeh.csv", clear varnames(1)
mkmat z1 z2 z3, matrix(ZB)
mata: ZBm = st_matrix("ZB")
clear
forvalues w = 1/3 {
	nwset, mat(T`w') bipartite name(tm`w') nooutput
}
forvalues w = 1/3 {
	gen double zb`w' = 0
}
mata: md = st_sdata(., "_nwmode"); ia = selectindex(md :== "2"); st_store(ia, ("zb1", "zb2", "zb3"), ZBm)
local efs "crossxoutact avgroupegox totgroupegox"
if "$EFFS" != "" local efs "$EFFS"
foreach ef of local efs {
	forvalues s = 1/2 {
		nwsaom, waves(tm1 tm2 tm3) outdegree behavior(zb1 zb2 zb3 : linear quadratic) netbeh(`ef') k0(50) k3(1000) seed(`s')
		matrix b = e(b)
		matrix V = e(V)
		local est ""
		local se ""
		forvalues j = 1/`=colsof(b)' {
			local est "`est' `: di %7.3f b[1,`j']'"
			local se "`se' `: di %6.3f sqrt(V[`j',`j'])'"
		}
		di "NFT `ef' seed `s' : theta `est' se `se'"
		if `s' == 1 {
			* the observed statistics: the end network of each period with the behavior at the START of the period
			mata: SaomBehSimSync(__nwsaom_last_M, *__nwsaom_last_Behwaves[1]); st1 = __nwsaom_last_M.full_statistic(__nwsaom_last_G2)
			mata: SaomBehSimSync(__nwsaom_last_M, *__nwsaom_last_Behwaves[2]); st2 = __nwsaom_last_M.full_statistic(__nwsaom_last_G3)
			di "NFT targets"
			mata: st1 + st2
		}
	}
}
