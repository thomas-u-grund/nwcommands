capture program drop nwreplacemat
program nwreplacemat
	version 9.0
	syntax anything(name=netname), newmat(string) [vars(string) labs(string) nosync netonly xvars]

	// nw_syntax itself exports a local called `labs' (the *current*
	// network's own labels, via its own c_local labs "..." with no
	// other() prefix given) - calling it immediately below would
	// silently clobber the caller's own labs() option value before
	// this file ever uses it, which is exactly what was happening
	// here: labs() has never actually done anything in this command,
	// confirmed directly by tracing `labs' immediately after the
	// nw_syntax call below and finding it held the *original*
	// network's labels, not whatever the caller passed. Captured into
	// a differently-named local first so it survives.
	local newmatlabs "`labs'"
	unw_defs
	nw_syntax `netname', max(1)

	capture mat list `newmat'
	if _rc == 0 {
		mata: `newmat' = st_matrix("`newmat'")
	}

	mata: st_numscalar("r(matrows)", rows(`newmat'))
	mata: st_numscalar("r(matcols)", cols(`newmat'))
	local matrows = r(matrows)
	local matcols = r(matcols)

	// newmat is invalid (not N x X matrix)
	if (`matrows' != `matcols'){
		// `errMatrixShape' (6082, unw_defs.ado) - this is the original
		// source of this convention; nwdyadprob.ado's own identical
		// check now also uses it, having previously drifted onto an
		// unrelated code.
		di "{err}input matrix has invalid dimensions"
		error `errMatrixShape'
	}
	
	// newmat is of different size than the network
	if (`matrows' != `nodes'){
		//di "{txt}input matrix has different dimensions than existing {it:network} {bf:`netname'}. size of {bf:`netname'} has been adjusted."
		local nodes = `matrows'
		
		if ("`netonly'" != "" | "`sync'" != "") {
			mata: `newmat'
			mata: nw_mata`id' = `newmat'
			global nwsize_`id' = `matrows'
			if "`vars'" != "" {
				global nw_`id' "`vars'"
			}
			if "`newmatlabs'" != "" {
				global nwlabs_`id' "`newmatlabs'"
			}
		}
		else {
			nwdrop `netname', `netonly'
			// BUGFIX: `nwrandom' has never had a `vars()' option (it
			// generates its own default variable names) - this call
			// only ever "worked" because `nwrandom''s own trailing `*'
			// wildcard used to silently absorb and discard unrecognized
			// options; once that dead wildcard was correctly removed
			// (moderate-severity pass, generators_structural group unit)
			// to make nwrandom reject genuinely misspelled options, this
			// pre-existing call broke outright ("option vars() not
			// allowed", r198) - a real, latent bug this uncovered, not a
			// new one. Harmless to simply drop here: `nwrandom''s own
			// ties (from `prob(1)') are immediately overwritten by the
			// very next line's recursive `nwreplacemat' call regardless
			// of what `nwrandom' names its variables.
			nwrandom `nodes', prob(1) name(`netname') labs(`newmatlabs') `xvars'
			// `nosync' itself is never populated (Stata's own "no"-
			// prefix syntax convention stores the literal string
			// "nosync" in `sync' instead - see the check just above
			// this block, which already gets this right) - so this
			// recursive call previously never actually forwarded the
			// caller's own nosync option. Fixed to forward `sync'.
			nwreplacemat `netname', newmat(`newmat') `sync' `xvars'
			// delete empty observations in Stata
			nwcompressobs
		}
	}
	else {
		// was "mata: nw_mata`id' = `newmat'" - nw_mata<id> is a
		// legacy pre-2016 global the modern netobj/NWdef Mata class
		// architecture never reads from, so this silently did nothing
		// to the network as far as any other command could see.
		// set_edge() is the modern equivalent (already used
		// elsewhere in this package, e.g. nwkatz's own in-place
		// matrix update).
		mata: `netobj'->set_edge(`newmat')
		if "`netonly'" == "" {
			if "`sync'" == "" {
				nwsync `netname'
			}
		}
	}

	// check for directed/undirected of new network and adjust if necessary
	mata: st_numscalar("r(directed)", (issymmetric(`newmat') == 1))

	// was "global nwdirected_`id' = ..." - same legacy-global issue as
	// above; set_directed() is the modern equivalent (matches
	// nw_name.ado's own newdirected() implementation).
	if (`r(directed)' == 1) {
		mata: `netobj'->set_directed(0)
	}
	else {
		mata: `netobj'->set_directed(1)
	}
end
*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
