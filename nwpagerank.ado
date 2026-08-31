
capture program drop nwpagerank
program nwpagerank, rclass
	version 12
	syntax [anything(name=netname)][, GENerate(string) replace DAMPing(real 0.85) maxiter(int 1000) tol(real 1e-10) silent]

	if `damping' <= 0 | `damping' >= 1 {
		di "{err}damping() must be strictly between 0 and 1."
		error 198
	}
	if `maxiter' < 1 {
		di "{err}maxiter() must be a positive integer."
		error 198
	}

	nw_syntax `netname'

	if "`generate'" == "" {
		local generate "_pagerank"
	}
	capture confirm variable `generate', exact
	if _rc == 0 & "`replace'" == "" {
		di "{err}Variable {bf:`generate'} already exists; specify {bf:replace}"
		err 99
	}

	tempname __nw_pr
	mata: `__nw_pr' = `netobj'->calculate_pagerank(`damping', `maxiter', `tol')
	capture drop `generate'
	gen double `generate' = .
	mata: st_store((1::`nodes'), "`generate'", `__nw_pr')
	mata: mata drop `__nw_pr'

	return local generate "`generate'"

	if "`silent'" == "" {
		di "{hline 40}"
		di "{txt}  Network: {res}`netname'"
		di "{txt}  Damping: {res}`damping'"
		di "{hline 40}"
		summarize `generate'
	}
end
