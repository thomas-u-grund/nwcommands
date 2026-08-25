capture program drop nwtomatafast
program nwtomatafast
	syntax [anything(name=netname)]
	// _nwsyntax/"nw_mata`id'" assumed the pre-2016 storage design, where
	// each network had its own standalone global Mata matrix by that
	// name - that convention no longer exists under the current
	// NWs/NWsdef/NWdef class-based architecture, so every caller of this
	// command (nwdissimilar, nwsimilar, nwhierarchy) was broken
	// ("nw_mata1 not found"). Fixed to return a valid Mata EXPRESSION
	// (a dereferenced pointer to the live adjacency matrix, matching
	// nw_tomata's own r(adj) convention) rather than a now-nonexistent
	// named matrix - this preserves every caller's existing contract of
	// substituting `r(mata)' directly into a later mata: line unchanged.
	unw_defs
	// BUGFIX: same misspelled/nonexistent network name crash (raw Mata
	// r3301) already fixed in nw_tomata.ado - nwtomatafast doesn't share
	// that helper (it calls nw_syntax directly for its own performance
	// reasons), so needs its own independent fix.
	capture nw_syntax `netname'
	if _rc != 0 {
		di "{err}Network `netname' not found."
		error `errNWsNotFound'
	}
	mata: st_global("r(mata)", "(*`netobj'->get_matrix())")
end
*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
