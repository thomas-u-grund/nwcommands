
capture program drop nwmatching
program nwmatching, rclass
	version 12
	syntax [anything(name=netname)], [GENerate(string) replace silent]
	nw_syntax `netname'

	if "`generate'" == "" {
		local generate "_match"
	}
	capture confirm variable `generate'
	if _rc == 0 & "`replace'" == "" {
		di "{err}Variable {bf:`generate'} already exists; use {bf:replace}"
		err 99
	}

	// BUGFIX: the active dataset was never synced to the target network
	// before st_store() below - see nwpagerank.ado's identical fix and
	// comment for the full account; confirmed to crash the same way
	// here via the same adversarial-input probe.
	_nwsetobs `netname'
	tempvar __nw_match_included
	_nwdatasync `netname', generate(`__nw_match_included')

	tempname __nw_match
	capture noisily mata: `__nw_match' = `netobj'->calculate_bipartite_matching()
	if _rc != 0 {
		exit _rc
	}
	capture drop `generate'
	gen `generate' = .
	mata: st_store((1::`nodes'), "`generate'", `__nw_match')

	mata: st_numscalar("__nwmatching_n", sum(`__nw_match' :> 0))
	mata: mata drop `__nw_match'

	return scalar matched = __nwmatching_n
	return local matchvar "`generate'"

	if "`silent'" == "" {
		di "{hline 40}"
		di "{txt}  Network: {res}`netname'"
		di "{txt}  Matched pairs: {res}`=__nwmatching_n'"
		di "{hline 40}"
		di "{txt}(`generate' holds each mode-1 node's own matched mode-2 partner's node id, 0 if unmatched; mode-2 nodes always show 0 - read the match off the mode-1 side)"
	}
	scalar drop __nwmatching_n
end
