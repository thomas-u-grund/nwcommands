* Stata side of the bipartite cross-validation (tag bip): for each spec row and network, fit MPLE and write observed statistics, coefficients, SEs.
* usage (from a scratch copy of the tree): do bip_run.do  with globals BIPREF (dir with csv), BIPSPEC, BIPOUT
clear all
set more off
adopath ++ "."
quietly do unw_core.do
quietly do unw_ergm.do
tempname fh
file open `fh' using "$BIPOUT", write replace
tempname fd
file open `fd' using "$BIPOUT.design", write replace
file write `fh' "net,id,idx,sname,sstat,sb,sse,rc" _n
import delimited "$BIPSPEC", clear delimiters("|") varnames(nonames) stringcols(_all)
local ns = _N
forvalues i = 1/`ns' {
	local id_`i' = v1[`i']
	local op_`i' = v3[`i']
}
foreach net in A B C {
	forvalues i = 1/`ns' {
		quietly {
			nwclear
			clear
			import delimited "$BIPREF/bip`net'_nodes.csv", clear
			local n1 = n1[1]
			local n = _N
			drop n1
			tempfile nodes
			save `nodes'
			import delimited "$BIPREF/bip`net'_edges.csv", clear
			local n2 = `n' - `n1'
			mata: B = J(`n1', `n2', 0)
			mata: E = st_data(., ("person","event"))
			mata: for (k=1;k<=rows(E);k++) B[E[k,1],E[k,2]] = 1
			* nwset's mat()+bipartite takes the mode-1 nodes from the matrix COLUMNS
			mata: Bt = B'
			nwset, mat(Bt) bipartite name(bip)
			use `nodes', clear
		}
		capture noisily nwergm bip, edges `op_`i'' method(mple)
		local rc = _rc
		if `rc' == 0 {
			matrix b = e(b)
			matrix V = e(V)
			local nm : colfullnames b
			mata: st_matrix("__sst", __nwergm_last_M.full_statistic(__nwergm_last_G))
			* design matrix of change statistics (all dyads), to compare with R's ergmMPLE()
			mata: Dm = ErgmNativeBuildMPLEData(__nwergm_last_M, __nwergm_last_G)
			mata: st_numscalar("__dnr", rows(Dm)); st_numscalar("__dnc", cols(Dm))
			forvalues r = 1/`=__dnr' {
				mata: st_local("__drow", invtokens(strofreal(Dm[`r',.], "%18.10g")))
				file write `fd' "`net',`id_`i'',`r',`=subinstr("`__drow'"," ",",",.)'" _n
			}
			local k = colsof(b)
			forvalues j = 2/`k' {
				local cn : word `j' of `nm'
				local se = sqrt(V[`j',`j'])
				file write `fh' "`net',`id_`i'',`=`j'-1',`cn',`=__sst[1,`j']',`=b[1,`j']',`se',0" _n
			}
		}
		else file write `fh' "`net',`id_`i'',0,ERROR,.,.,.,`rc'" _n
	}
}
file close `fh'
file close `fd'
