
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

	// the condition is checked before anything is copied or replaced
	// (a copy onto the network itself would otherwise lose it)
	if "`if'" != "" {
		_nwdatasync `netname'
		qui count if ((`if') != 0) in 1/`nodes'
		if r(N) == 0 {
			di "{err}{p 0 0 2}The if condition selects no nodes; network {bf:`name'} would have zero nodes remaining.{p_end}"
			exit 198
		}
	}
	nwduplicate `netname', name(`name') `replace'
	// the condition in parentheses: "a == 1 & b == 2" must not become "a == 1 & (b == 2 == 0)"
	if "`if'" != "" {
		nwdrop `name' if ((`if') == 0)
	}

end

