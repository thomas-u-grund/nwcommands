
capture program drop nwduplicate
program nwduplicate
	syntax [anything(name=netname)], [name(string) replace]
	unw_defs
	_nwsyntax `netname', max(1)

	local name_given = ("`name'" != "")
	if "`name'" == "" {
		local name "`netname'_copy"
	}

	// BUGFIX (moderate-severity pass, generators_structural group): used
	// to call `nwvalidate' unconditionally, silently auto-incrementing
	// ("fixedcopy" -> "fixedcopy_1") on an explicit name() collision -
	// unlike every sibling generator in this group (nwrandom/nwpref/
	// nwlattice/nwring/nwsmall), which correctly require `replace' for
	// that case. The underlying `.duplicate()' Mata method has no
	// collision guard of its own either (unlike `nwset', which the
	// siblings ultimately call) - it would silently append a second,
	// same-named registry entry rather than erroring, so the check needs
	// to happen here explicitly. Auto-increment only when name() was
	// omitted (matching the siblings' own "unspecified name() still
	// auto-renames" convention); an explicit, colliding name() now
	// requires `replace' instead, same as every sibling.
	nwvalidate `name'
	if "`r(exists)'" == "true" & `name_given' {
		// a copy onto itself with replace leaves the network as it is
		if "`replace'" != "" & "`name'" == "`netname'" {
			exit
		}
		if "`replace'" != "" {
			nwdrop `name'
			local validname "`name'"
		}
		else {
			di "{err}{p 0 0 2}Network `name' already exists. Specify option {bf:replace} to overwrite it.{p_end}"
			exit 483
		}
	}
	else {
		local validname "`r(validname)'"
	}
	mata: `nws'.duplicate("`netname'", "`validname'")
	// a copy of a temporal network is temporal: event list, times, intervals and their variable names are copied
	if "`istemporal'" == "true" {
		_nwtemporal stash `netname'
		_nwtemporal put `validname'
		_nwtemporal drop
	}
end

