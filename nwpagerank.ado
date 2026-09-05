
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

	_nwsyntax `netname'

	// generate() is required (suite-wide generate()-required style
	// decision, 2026-09-05): nwpagerank's whole purpose is producing
	// this variable, so - matching Stata's own egen/predict convention -
	// there is no default name to silently fall back to.
	if "`generate'" == "" {
		di "{err}option {bf:generate()} required."
		error 198
	}
	capture confirm variable `generate', exact
	if _rc == 0 & "`replace'" == "" {
		di "{err}Variable {bf:`generate'} already exists; specify {bf:replace}"
		err 99
	}

	// BUGFIX: the active dataset was never synced to the target network
	// before st_store() below - a fresh or differently-sized dataset
	// (e.g. right after `clear', or after working with a different
	// network) crashed with a raw "argument out of range" (r3300) the
	// instant st_store() tried to write into row `nodes' of a dataset
	// with fewer rows than that. Confirmed directly via an adversarial-
	// input probe (a bare `clear' immediately before this command).
	_nwsetobs `netname'
	tempvar __nw_pr_included
	_nwdatasync `netname', generate(`__nw_pr_included')

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
