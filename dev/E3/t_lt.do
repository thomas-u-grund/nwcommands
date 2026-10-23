clear all
set more off
adopath ++ "."
adopath ++ "lib/plugins/macos"
quietly do unw_core.do
quietly do unw_ergm.do
foreach nm in und_a dir_a {
	local d = cond("`nm'"=="dir_a","directed","undirected")
	import delimited "dev/E3/`nm'_adj.csv", clear
	qui mkmat v*, mat(A)
	import delimited "dev/E3/`nm'_x.csv", clear
	qui mkmat v*, mat(X)
	qui nwclear
	qui clear
	qui nwset, mat(X) undirected name(xnet)
	qui nwset, mat(A) `d' name(g)
	qui nwergm g, edges structural(localtriangle(x=xnet)) method(mple)
	mata: __nwergm_last_M.full_statistic(__nwergm_last_G)
}
