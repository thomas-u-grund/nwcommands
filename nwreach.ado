capture program drop nwreach
program nwreach
	// `vars(string)' removed - it was accepted by syntax but never
	// referenced anywhere in this file's body (a fully dead, undocumented
	// no-op).
	syntax [anything(name=reachnet)], [ name(string) xvars sym nwreplace force]
	_nwsyntax `reachnet', name(reachnet)
	unw_defs
	_nwdenseguard, command(nwreach) nodes(`nodes') copies(2) alternative(Reachability between all pairs of nodes is an n x n matrix. Use nwcomponents for connectedness (undirected networks), nwpath for one pair, or a part of the network (nwsubset).) `force'

	if "`name'" == "" {
		local name "`nwgen_reach'"
	}

	// BUGFIX: this used to unconditionally `capture nwdrop `name'' with
	// no existence check and no way to opt out at all - a real,
	// undocumented data-loss risk (any pre-existing network happening to
	// share this command's target name, default `_reach' or whatever
	// name() specifies, was silently destroyed with zero warning).
	// Unlike this, every sibling command in the group (nwgeodesic/
	// nwpath/nwbridges) requires `nwreplace' before overwriting an
	// existing target name - now matches that convention.
	capture _nwsyntax `name', other(_check)
	if _rc == 0 & "`nwreplace'" == "" {
		di "{err}Network {bf:`name'} already exists; specify {bf:nwreplace} or a different {bf:name()}."
		error 99
	}
	if _rc == 0 {
		nwdrop `name'
	}
	qui nwgeodesic `reachnet', name(`name') `sym' unconnected(`missing2') nwreplace
	_nwsyntax `name'
	mata: nw_reach_inplace(`netobj', `missing2')
	mata: `netobj'->set_valued(0)
	
	if "`xvars'" != "" {
		nwload `name'
	}
end
