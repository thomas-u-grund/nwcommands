* MCMLE of nwergm for the models of bip_mcmle_models.txt on network D, 3 seeds each (globals BIPREF, BIPSPEC, BIPOUT)
clear all
set more off
adopath ++ "."
quietly do unw_core.do
quietly do unw_ergm.do
tempname fh
file open `fh' using "$BIPOUT", write replace
file write `fh' "id,seed,idx,sname,sb,conv" _n
import delimited "$BIPSPEC", clear delimiters("|") varnames(nonames) stringcols(_all)
local ns = _N
forvalues i = 1/`ns' {
	local id_`i' = v1[`i']
	local op_`i' = v3[`i']
}
forvalues i = 1/`ns' {
	forvalues sd = 1/3 {
		quietly {
			nwclear
			clear
			import delimited "$BIPREF/bipD_nodes.csv", clear
			local n1 = n1[1]
			local n = _N
			drop n1
			tempfile nodes
			save `nodes', replace
			import delimited "$BIPREF/bipD_edges.csv", clear
			local n2 = `n' - `n1'
			mata: B = J(`n1', `n2', 0)
			mata: E = st_data(., ("person","event"))
			mata: for (k=1;k<=rows(E);k++) B[E[k,1],E[k,2]] = 1
			mata: Bt = B'
			nwset, mat(Bt) bipartite name(bip)
			use `nodes', clear
		}
		capture noisily nwergm bip, edges `op_`i'' method(mcmle) seed(`sd') mcmcsamplesize(4000) nomcmcsample
		local rc = _rc
		if `rc' == 0 {
			matrix b = e(b)
			local nm : colfullnames b
			local k = colsof(b)
			forvalues j = 1/`k' {
				local cn : word `j' of `nm'
				file write `fh' "`id_`i'',`sd',`j',`cn',`=b[1,`j']',`=e(converged)'" _n
			}
		}
		else file write `fh' "`id_`i'',`sd',0,ERROR,.,`rc'" _n
	}
}
file close `fh'
