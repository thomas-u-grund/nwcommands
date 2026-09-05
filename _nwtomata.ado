
capture program drop _nwtomata
program _nwtomata
version 9
syntax [anything(name=netname)], [ mat(string) ]

	unw_defs
	// BUGFIX: a misspelled/nonexistent network name crashed with a raw,
	// low-level Mata "subscript invalid" error (r3301) instead of a
	// clean message - the same _nwsyntax-name-resolution class of bug
	// already fixed independently in several other commands this pass
	// (there is no single shared fix point, since _nwsyntax's own
	// failure is not routed through any shared validation helper).
	// Fixing it here also fixes nwtomata.ado, which forwards straight
	// to this shared helper.
	capture _nwsyntax `netname', max(1)
	if _rc != 0 {
		di "{err}Network `netname' not found."
		error `errNWsNotFound'
	}
	mata: st_rclear()
	mata: st_global("r(netname)","`netname'")
	mata: st_global("r(netobj)", "`netobj'")
	mata: st_global("r(adj)", "(*`netobj'->get_matrix())")
	
	if "`mat'" != "" {
		mata: `mat' = `r(adj)'
		mata: st_global("r(adj_copy)", "`mat'")
	}
 end
