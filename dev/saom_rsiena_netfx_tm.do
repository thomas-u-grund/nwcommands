* nwsaom counterpart of dev/saom_rsiena_netfx_tm.R (40 actors x 20 events): bipartite dyadic covariate and interactions
qui do unw_core.do
qui do unw_ergm.do
qui do unw_saom.do
nwclear
forvalues w = 1/3 {
	import delimited "dev/saom_twomode_w`w'.csv", clear varnames(1)
	mkmat v1-v20, matrix(T`w')
}
import delimited "dev/saom_twomode_cvA.csv", clear varnames(1)
mkmat ega, matrix(CA)
import delimited "dev/saom_twomode_cvB.csv", clear varnames(1)
mkmat altb, matrix(CB)
import delimited "dev/saom_netfx_dyad.csv", clear varnames(1)
mkmat v1-v20, matrix(DY)
mata: CAm = st_matrix("CA"); CBm = st_matrix("CB")
clear
forvalues w = 1/3 {
	nwset, mat(T`w') bipartite name(tm`w') nooutput
}
gen double ega = .
gen double altb = .
mata: md = st_sdata(., "_nwmode"); ia = selectindex(md :== "2"); ie = selectindex(md :== "1"); st_store(ia, "ega", CAm); st_store(ie, "altb", CBm)
local specs "dyadX intEgoAlt"
if "$SPECS" != "" local specs "$SPECS"
foreach spec of local specs {
	if "`spec'" == "dyadX" local opt "indegpopularity dyadcov(DY)"
	if "`spec'" == "intEgoAlt" local opt "nodeocov(ega) nodeicov(altb) interact(nodeocov#nodeicov)"
	forvalues s = 1/2 {
		nwsaom, waves(tm1 tm2 tm3) outdegree `opt' k0(50) k3(1000) seed(`s')
		matrix b = e(b)
		matrix V = e(V)
		local est ""
		local se ""
		forvalues j = 1/`=colsof(b)' {
			local est "`est' `: di %7.3f b[1,`j']'"
			local se "`se' `: di %6.3f sqrt(V[`j',`j'])'"
		}
		di "NWSAOM `spec' seed `s' : est `est' se `se'"
		if `s' == 1 {
			mata: st1 = __nwsaom_last_M.full_statistic(__nwsaom_last_G2); st2 = __nwsaom_last_M.full_statistic(__nwsaom_last_G3); st1 + st2
		}
	}
}
