
capture program drop nwattime
program nwattime, rclass
	version 12
	syntax [anything(name=netname)], AT(real) [name(string) xvars replace]

	_nwsyntax `netname'

	if "`istemporal'" != "true" {
		di "{err}{p 0 0 2}Network {bf:`netname'} is not temporal; nwattime requires a network declared via {help nwset}'s {bf:time()}, {bf:interval()}, or {bf:eventtime()} options.{p_end}"
		error 198
	}

	if "`name'" == "" {
		local name "atview"
	}
	nwvalidate `name'
	if "`r(exists)'" == "true" {
		if "`replace'" == "" {
			di "{txt}{p 0 0 2}Warning! Switched to netname {res}`r(validname)'{txt} because {res}`name'{txt} already in use.{p_end}"
			local name = r(validname)
		}
		else {
			capture nwdrop `name'
		}
	}

	// captured from the SOURCE network's own netobj/name before both
	// are reassigned to the newly-created static-view network below -
	// mirrors nw2project.ado's own established pattern for exactly the
	// same reason (the second _nwsyntax call below overwrites `netname'
	// itself, not just `netobj' - confirmed via a direct probe: without
	// this capture, the display and provenance note both silently
	// showed the NEW network's own name instead of the source's).
	local srcnetname "`netname'"
	local srctemporaltype "`temporaltype'"
	tempname __srcnames __edges
	mata: `__srcnames' = `netobj'->get_nodenames()
	mata: st_local("srcdirected", strofreal(`netobj'->is_directed_boolean()))
	mata: st_local("srcvalued", strofreal(`netobj'->is_valued_boolean()))
	// a two-mode source keeps its modes and level labels in the slice
	local __at2 = ("`is2mode'" == "true")
	tempname __atmodes __atd1 __atd2
	if `__at2' {
		mata: `__atmodes' = `netobj'->get_modes()
		mata: `__atd1' = `netobj'->get_description_mode1()
		mata: `__atd2' = `netobj'->get_description_mode2()
	}

	if "`temporaltype'" == "snapshot" {
		mata: `__edges' = nwattime_slice_snapshot(`netobj', `at')
	}
	else if "`temporaltype'" == "interval" {
		mata: `__edges' = nwattime_slice_interval(`netobj', `at')
	}
	else {
		mata: `__edges' = nwattime_slice_event(`netobj', `at')
	}

	mata: st_local("__at_ties", strofreal(rows(`__edges'), "%18.0g"))

	mata: __nw.nws.add("`name'")
	_nwsyntax `name'
	mata: `netobj'->create_by_name_sparse(`__srcnames')
	// BUGFIX (see docs/CERTIFICATION.md unit 42): create_by_name_sparse()
	// wipes `name' via its own internal zap() call - nwset.ado's own
	// create_by_name() caller already re-sets it immediately afterward
	// for exactly this reason, mirrored here.
	mata: `netobj'->set_name("`name'")
	mata: `netobj'->set_directed(`srcdirected')
	mata: `netobj'->set_edge_from_triplets(`__edges'[.,1], `__edges'[.,2], `__edges'[.,3], `srcdirected')
	mata: `netobj'->set_valued(`srcvalued')
	if `__at2' {
		mata: `netobj'->set_2mode(1)
		mata: `netobj'->set_modes(`__atmodes')
		mata: `netobj'->set_description_mode1(`__atd1')
		mata: `netobj'->set_description_mode2(`__atd2')
		mata: mata drop `__atmodes' `__atd1' `__atd2'
	}
	mata: `netobj'->set_provenance("static graph view of `srcnetname' at t=`at' (`srctemporaltype')")

	// displayed count: an undirected tie is stored as two triplet rows
	// (i,j) and (j,i); r(ties) keeps counting rows (documented convention),
	// the printed line shows true ties.
	mata: st_local("tiesshown", strofreal(`srcdirected' ? rows(`__edges') : sum(`__edges'[.,1] :<= `__edges'[.,2])))
	mata: mata drop `__srcnames' `__edges'

	return scalar ties = `__at_ties'
	return scalar at = `at'

	di "{hline 40}"
	di "{txt}  Static graph view: {res}`name'"
	di "{txt}  Source network: {res}`srcnetname'{txt} ({res}`srctemporaltype'{txt})"
	di "{txt}  At: {res}`at'"
	di "{txt}  Ties: {res}`tiesshown'"

	if "`xvars'" != "" {
		nwload `name'
	}
end
