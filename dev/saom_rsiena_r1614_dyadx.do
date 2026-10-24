* nwsaom counterpart of dev/saom_rsiena_r1614_dyadx.R (RSiena 1.6.14: WXX / XWX / XWX1 / XWX2 / WXZX in a two-mode network, WXZX in a one-mode network):
* the observed statistics (sum over the periods) and the estimates of two seeds
do unw_core.do
do unw_ergm.do
do unw_saom.do
nwclear
forvalues w = 1/3 {
	import delimited "dev/saom_twomode_w`w'.csv", clear varnames(1)
	mkmat v1-v20, matrix(T`w')
	import delimited "dev/saom_r1614_s50_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(S`w')
}
import delimited "dev/saom_r1614_w40.csv", clear varnames(1)
mkmat v1-v40, matrix(W40)
import delimited "dev/saom_r1614_z20.csv", clear varnames(1)
mkmat v1-v20, matrix(Z20)
import delimited "dev/saom_r1614_z50.csv", clear varnames(1)
mkmat v1-v50, matrix(Z50)
import delimited "dev/saom_rsiena_dyadx_w.csv", clear varnames(1)
mkmat v1-v50, matrix(W50)
forvalues w = 1/3 {
	import delimited "dev/saom_rsiena_symmulti_w`w'.csv", clear varnames(1) case(preserve)
	mkmat V1-V50, matrix(Y`w')
}
clear
forvalues w = 1/3 {
	nwset, mat(T`w') bipartite name(tm`w') nooutput
	nwset, mat(S`w') directed name(om`w') nooutput
	nwset, mat(Y`w') undirected name(sy`w') nooutput
}
foreach spec in "tm|wxx:W40" "tm|xwx:Z20" "tm|xwx1:Z20" "tm|xwx2:Z20" "tm|wxzx:W40:Z20" "om|wxx:W50" "om|wxzx:W50:Z50" "om|wxzx:Z50:W50" "sy|wxzx:W50:Z50" "sy|wxx:W50" {
	gettoken nw dx : spec, parse("|")
	local dx = subinstr("`dx'", "|", "", 1)
	local m = cond("`nw'" == "om", "outdegree reciprocity", "outdegree")
	forvalues s = 1/2 {
		nwsaom, waves(`nw'1 `nw'2 `nw'3) `m' dyadx(`dx') k0(50) k3(1000) seed(`s') unconditional
		matrix b = e(b)
		matrix r = e(rates)
		local bs ""
		forvalues k = 1/`=colsof(b)' {
			local bs "`bs' `=string(b[1,`k'], "%7.3f")'"
		}
		di "NWSAOM `spec' seed `s': rates `=string(r[1,1], "%6.3f")' `=string(r[1,2], "%6.3f")' est `bs'"
	}
	mata: st1 = __nwsaom_last_M.full_statistic(__nwsaom_last_G2); st2 = __nwsaom_last_M.full_statistic(__nwsaom_last_G3); st1 + st2
}
