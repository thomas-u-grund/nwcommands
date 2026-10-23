* MPLE of every structural term with nwergm (edges + term; term only for density/meandeg) -> stata_mple.csv
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
tempname fh
file open `fh' using "`D'/stata_mple.csv", write replace
file write `fh' "net,id,idx,sname,scoef,sse" _n
foreach net in und_a und_b und_c dir_a dir_b dir_c {
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
		local ed "edges"
		if inlist("`id_`i''", "density", "meandeg") local ed ""
		capture noisily nwergm `net', `ed' structural(`nw_`i'') method(mple)
		if _rc {
			file write `fh' "`net',`id_`i'',0,ERROR`=_rc',.,." _n
			continue
		}
		matrix b = e(b)
		matrix V = e(V)
		local cn : colnames b
		local k = colsof(b)
		forvalues j = 1/`k' {
			local cname : word `j' of `cn'
			file write `fh' "`net',`id_`i'',`j',`cname',`=b[1,`j']',`=sqrt(V[`j',`j'])'" _n
		}
	}
}
file close `fh'
