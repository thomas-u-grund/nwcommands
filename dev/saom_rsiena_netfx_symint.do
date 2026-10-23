* nwsaom counterpart of dev/saom_rsiena_netfx_symint.R
qui do unw_core.do
qui do unw_ergm.do
qui do unw_saom.do
nwclear
forvalues w = 1/3 {
	import delimited "sym_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(S`w')
}
import delimited "_tv.csv", clear varnames(1)
tempfile tvd
save `tvd'
forvalues w = 1/3 {
	nwset, mat(S`w') directed name(sk`w') nooutput
}
merge 1:1 _n using `tvd', nogen
forvalues s = 1/2 {
	nwsaom, waves(sk1 sk2 sk3) symmetric outdegree egox(v1) altx(v1) interact(egox#altx) k0(50) k3(1000) seed(`s')
	matrix b = e(b)
	matrix V = e(V)
	local est ""
	local se ""
	forvalues j = 1/`=colsof(b)' {
		local est "`est' `: di %7.3f b[1,`j']'"
		local se "`se' `: di %6.3f sqrt(V[`j',`j'])'"
	}
	di "NSI seed `s' : theta `est' se `se'"
	if `s' == 1 {
		di "NSI targets (directed count)"
		mata: st1 = __nwsaom_last_M.full_statistic(__nwsaom_last_G2); st2 = __nwsaom_last_M.full_statistic(__nwsaom_last_G3); st1 + st2
	}
}
