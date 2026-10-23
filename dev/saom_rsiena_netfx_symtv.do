* nwsaom counterpart of dev/saom_rsiena_netfx_symtv.R
qui do unw_core.do
qui do unw_ergm.do
qui do unw_saom.do
nwclear
forvalues w = 1/3 {
	import delimited "sym_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(S`w')
}
forvalues p = 1/2 {
	import delimited "dev/saom_netfx_symdy`p'.csv", clear varnames(1)
	mkmat v1-v50, matrix(sdy`p')
}
import delimited "_tv.csv", clear varnames(1)
tempfile tvd
save `tvd'
forvalues w = 1/3 {
	nwset, mat(S`w') directed name(sk`w') nooutput
}
merge 1:1 _n using `tvd', nogen
foreach ef in higher xrecip {
	forvalues s = 1/2 {
		if "`ef'" == "higher" capture noisily nwsaom, waves(sk1 sk2 sk3) symmetric outdegree higher(v) tvcov(v1 v2) k0(50) k3(1000) seed(`s')
		else capture noisily nwsaom, waves(sk1 sk2 sk3) symmetric outdegree tvdyadcovrecip(sdy) k0(50) k3(1000) seed(`s')
		if _rc {
			di "NSTV `ef' seed `s': rc " _rc
		}
		else {
			matrix b = e(b)
			matrix V = e(V)
			local est ""
			local se ""
			forvalues j = 1/`=colsof(b)' {
				local est "`est' `: di %7.3f b[1,`j']'"
				local se "`se' `: di %6.3f sqrt(V[`j',`j'])'"
			}
			di "NSTV `ef' seed `s' : theta `est' se `se'"
		}
		if `s' == 1 {
			di "NSTV targets (directed count)"
			mata: SaomTVSync(__nwsaom_last_M, 1); st1 = __nwsaom_last_M.full_statistic(__nwsaom_last_G2)
			mata: SaomTVSync(__nwsaom_last_M, 2); st2 = __nwsaom_last_M.full_statistic(__nwsaom_last_G3)
			mata: st1 + st2
		}
	}
}
