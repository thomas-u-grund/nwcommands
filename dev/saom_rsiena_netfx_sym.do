* nwsaom counterpart of dev/saom_rsiena_netfx_sym.R
qui do unw_core.do
qui do unw_ergm.do
qui do unw_saom.do
nwclear
import delimited "dev/saom_netfx_symbeh.csv", clear varnames(1)
tempfile bd
save `bd'
forvalues w = 1/3 {
	import delimited "sym_w`w'.csv", clear varnames(1)
	mkmat v1-v50, matrix(S`w')
}
forvalues w = 1/3 {
	nwset, mat(S`w') directed name(sk`w') nooutput
}
merge 1:1 _n using `bd', nogen
local efs "degabsdiffx degposdiffx higher"
if "$EFFS" != "" local efs "$EFFS"
foreach ef of local efs {
	forvalues s = 1/2 {
		capture noisily nwsaom, waves(sk1 sk2 sk3) symmetric outdegree behavior(b1 b2 b3 : linear quadratic avalt) netbeh(`ef') k0(50) k3(1000) seed(`s')
		if _rc {
			di "NFS `ef' seed `s': rc " _rc
			continue
		}
		matrix b = e(b)
		matrix V = e(V)
		local est ""
		local se ""
		forvalues j = 1/`=colsof(b)' {
			local est "`est' `: di %7.3f b[1,`j']'"
			local se "`se' `: di %6.3f sqrt(V[`j',`j'])'"
		}
		di "NFS `ef' seed `s' : theta `est' se `se'"
		if `s' == 1 {
			* the observed statistics: the end network of each period with the behavior at the START of the period (a non-directed relation counts each tie once)
			mata: SaomBehSimSync(__nwsaom_last_M, *__nwsaom_last_Behwaves[1]); st1 = __nwsaom_last_M.full_statistic(__nwsaom_last_G2)
			mata: SaomBehSimSync(__nwsaom_last_M, *__nwsaom_last_Behwaves[2]); st2 = __nwsaom_last_M.full_statistic(__nwsaom_last_G3)
			di "NFS targets (directed count)"
			mata: st1 + st2
		}
	}
}
