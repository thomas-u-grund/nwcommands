* Compares nwergm's observed statistic of every structural term with R's summary() (ref_summary.csv)
clear all
set more off
adopath ++ "."
adopath ++ "lib/plugins/macos"
quietly do unw_core.do
quietly do unw_ergm.do
local D "dev/E3"
import delimited "`D'/spec.csv", clear stringcols(_all) varnames(1)
local nsp = _N
forvalues i = 1/`nsp' {
	local id_`i' = id[`i']
	local kind_`i' = kind[`i']
	local nw_`i' = nw[`i']
}
import delimited "`D'/ref_summary.csv", clear
tempfile ref
save `ref'
tempname fh
file open `fh' using "`D'/stata_summary.csv", write replace
file write `fh' "net,id,idx,sname,sval" _n
foreach net in und_a und_b und_c und_d dir_a dir_b dir_c dir_d {
	local isd = (substr("`net'",1,3) == "dir")
	import delimited "`D'/`net'_adj.csv", clear
	qui mkmat v*, mat(A)
	import delimited "`D'/`net'_nodes.csv", clear
	qui mkmat a b x, mat(NA)
	forvalues i = 1/`nsp' {
		if "`kind_`i''" == "und" & `isd' continue
		if "`kind_`i''" == "dir" & !`isd' continue
		qui nwclear
		qui clear
		qui nwset, mat(A) `=cond(`isd',"directed","undirected")' name(`net')
		qui svmat NA, names(col)
		capture noisily nwergm `net', edges structural(`nw_`i'') method(mple)
		if _rc {
			file write `fh' "`net',`id_`i'',0,ERROR`=_rc',."  _n
			continue
		}
		mata: st_local("cn", invtokens(__nwergm_last_M.coefnames))
		mata: st_matrix("__S", __nwergm_last_M.full_statistic(__nwergm_last_G))
		local k = colsof(__S)
		forvalues j = 1/`k' {
			local cname : word `j' of `cn'
			file write `fh' "`net',`id_`i'',`j',`cname',`=__S[1,`j']'" _n
		}
	}
}
file close `fh'
