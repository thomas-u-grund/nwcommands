
capture program drop nwattime
program nwattime, rclass
	version 12
	syntax [anything(name=netname)], AT(real) [name(string) xvars replace]

	nw_syntax `netname'

	if "`istemporal'" != "true" {
		di "{err}Network {bf:`netname'} is not temporal; nwattime requires a network declared via {help nwset}'s {bf:time()}, {bf:interval()}, or {bf:eventtime()} options."
		error 198
	}

	if "`name'" == "" {
		local name "atview"
	}
	nwvalidate `name'
	if "`r(exists)'" == "true" {
		if "`replace'" == "" {
			di "{txt}Warning! Switched to netname {res}`r(validname)'{txt} because {res}`name'{txt} already in use."
			local name = r(validname)
		}
		else {
			capture nwdrop `name'
		}
	}

	// captured from the SOURCE network's own netobj/name before both
	// are reassigned to the newly-created static-view network below -
	// mirrors nw2project.ado's own established pattern for exactly the
	// same reason (the second nw_syntax call below overwrites `netname'
	// itself, not just `netobj' - confirmed via a direct probe: without
	// this capture, the display and provenance note both silently
	// showed the NEW network's own name instead of the source's).
	local srcnetname "`netname'"
	local srctemporaltype "`temporaltype'"
	tempname __srcnames __edges
	mata: `__srcnames' = `netobj'->get_nodenames()
	mata: st_local("srcdirected", strofreal(`netobj'->is_directed_boolean()))
	mata: st_local("srcvalued", strofreal(`netobj'->is_valued_boolean()))

	if "`temporaltype'" == "snapshot" {
		mata: `__edges' = nwattime_slice_snapshot(`netobj', `at')
	}
	else if "`temporaltype'" == "interval" {
		mata: `__edges' = nwattime_slice_interval(`netobj', `at')
	}
	else {
		mata: `__edges' = nwattime_slice_event(`netobj', `at')
	}

	mata: st_numscalar("ties", rows(`__edges'))

	mata: nw.nws.add("`name'")
	nw_syntax `name'
	mata: `netobj'->create_by_name_sparse(`__srcnames')
	// BUGFIX (see docs/CERTIFICATION.md unit 42): create_by_name_sparse()
	// wipes `name' via its own internal zap() call - nwset.ado's own
	// create_by_name() caller already re-sets it immediately afterward
	// for exactly this reason, mirrored here.
	mata: `netobj'->set_name("`name'")
	mata: `netobj'->set_directed(`srcdirected')
	mata: `netobj'->set_edge_from_triplets(`__edges'[.,1], `__edges'[.,2], `__edges'[.,3], `srcdirected')
	mata: `netobj'->set_valued(`srcvalued')
	mata: `netobj'->set_provenance("static graph view of `srcnetname' at t=`at' (`srctemporaltype')")

	mata: mata drop `__srcnames' `__edges'

	return scalar ties = ties
	return scalar at = `at'

	di "{hline 40}"
	di "{txt}  Static graph view: {res}`name'"
	di "{txt}  Source network: {res}`srcnetname'{txt} ({res}`srctemporaltype'{txt})"
	di "{txt}  At: {res}`at'"
	di "{txt}  Ties: {res}`=ties'"

	if "`xvars'" != "" {
		nwload `name'
	}
end
