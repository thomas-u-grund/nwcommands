clear all
set more off
adopath ++ "."
adopath ++ "lib/plugins/macos"
quietly do unw_core.do
quietly do unw_ergm.do
local D "dev/E3"
import delimited "`D'/mcmle_specs.csv", clear stringcols(_all) varnames(1)
local nsp = _N
forvalues i = 1/`nsp' {
	local id_`i' = id[`i']
	local kind_`i' = kind[`i']
	local nw_`i' = nw[`i']
}
tempname fh
file open `fh' using "`D'/stata_mcmle.csv", write replace
file write `fh' "id,seed,idx,sname,scoef,sse" _n
forvalues i = 1/`nsp' {
	import delimited "`D'/mcmle_`id_`i''_adj.csv", clear
	qui mkmat v*, mat(A)
	forvalues sd = 1/3 {
		qui nwclear
		qui clear
		qui nwset, mat(A) `=cond("`kind_`i''"=="dir","directed","undirected")' name(g)
		capture noisily nwergm g, edges structural(`nw_`i'') method(mcmle) seed(`sd')
		if _rc {
			file write `fh' "`id_`i'',`sd',0,ERROR`=_rc',.,." _n
			continue
		}
		matrix b = e(b)
		matrix V = e(V)
		local cn : colnames b
		forvalues j = 1/`=colsof(b)' {
			local cname : word `j' of `cn'
			file write `fh' "`id_`i'',`sd',`j',`cname',`=b[1,`j']',`=sqrt(V[`j',`j'])'" _n
		}
	}
}
file close `fh'
