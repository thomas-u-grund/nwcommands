
capture program drop nwsubset
program nwsubset
	version 9
	
	unw_defs
	
	syntax [ anything(name=netname)] [if/] [, name(string) replace]
	
	_nwsyntax `netname', max(1)
	local original `netname'

	// BUGFIX (moderate-severity pass, generators_derived group):
	// nwsubset's own DEFAULT name (`netname'_sub, when name() is not
	// given at all) used to hard-error on collision instead of
	// auto-incrementing the way every sibling in this group
	// (nwdyadprob/nwhomophily/nwexpand/nwdissimilar/nwsimilar) does for
	// their own default names - inconsistent within the same group.
	// Resolved the same way as those siblings: only when the caller did
	// NOT supply name(), pre-resolve the actual (possibly
	// auto-incremented) target name via nwvalidate up front; an
	// explicit, caller-chosen name() still requires `replace' on a
	// genuine collision, now enforced by nwduplicate itself (see its own
	// moderate-severity-pass fix) rather than by a second, redundant
	// check duplicated here.
	local name_was_given = ("`name'" != "")
	if "`name'" == "" {
		local name "`netname'_sub"
	}
	if !`name_was_given' {
		nwvalidate `name'
		local name = r(validname)
	}

	nwduplicate `netname', name(`name') `replace'
	// BUGFIX: was unconditional - when no `if' condition is given (the
	// documented "simply generates a duplicate" behavior), `if' is
	// empty, so this became the literal, invalid `nwdrop `name' if ( ==
	// 0)' and crashed (r198) on every no-if call. Only apply the filter
	// when an `if' condition was actually given.
	if "`if'" != "" {
		// BUGFIX: an `if' condition matching zero nodes (a perfectly
		// ordinary user mistake, or a legitimate "this subset is
		// empty" request) crashed with an uncontrolled, uninformative
		// Mata error deep inside the network-registration machinery
		// (r3300) rather than a clean message. Caught and converted;
		// the half-built `name' network nwduplicate already created is
		// dropped too, rather than left behind in a broken state.
		capture nwdrop `name' if (`if' == 0)
		if _rc != 0 {
			capture nwdrop `name'
			di "{err}The if condition selects no nodes; network {bf:`name'} would have zero nodes remaining."
			error 198
		}
	}

end

