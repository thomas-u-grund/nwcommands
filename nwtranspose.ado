
capture program drop nwtranspose
program nwtranspose
	version 9
	// Naming consistency (moderate-severity pass, generators_derived
	// group): every other command in this group (nwdyadprob/
	// nwhomophily/nwexpand/nwdissimilar/nwsimilar/nwsubset/nwshared)
	// uses `name()' to name a new output network; nwtranspose alone used
	// `generate()'. Added `name()' as a working alias, kept `generate()'
	// for backward compatibility.
	syntax [anything(name=netname)], [ generate(string) name(string) replace]
	if "`generate'" != "" & "`name'" != "" {
		di "{err}Specify only one of {bf:generate()} or {bf:name()} (they are the same option) - not both."
		error 198
	}
	if "`name'" != "" {
		local generate "`name'"
	}
	unw_defs

	nw_syntax `netname', max(1)
	local netobj1 `netobj'

	if ("`generate'" != ""){
		// BUGFIX: nwduplicate's own collision guard silently
		// auto-renames the DUPLICATE to `generate'_1 on a name
		// collision (leaving it as an orphaned, never-used stray
		// network), but this line still operated on the literal
		// string `generate' regardless - so `nw_syntax `generate''
		// below resolved to the ORIGINAL, pre-existing network of
		// that name (not the fresh duplicate), and the transpose then
		// silently overwrote ITS edge matrix in place. Fixed with the
		// same explicit "error unless replace" collision guard
		// nwsubset.ado's own generate()/name() option already uses,
		// rather than relying on nwduplicate's own silent auto-rename
		// (which nwduplicate itself doesn't even report back to the
		// caller - there is no way to recover the actual name used).
		capture nw_syntax `generate', other(_check)
		if _rc == 0 {
			if "`replace'" == "" {
				// Error-code coherence pass: consolidated onto
				// `errNWsExists' (483, unw_defs.ado) - see
				// nwsimmelian.ado's own fix for the history of this
				// convention's drift onto an undocumented `6099'.
				di "{err}Network {bf:`generate'} already exists. Use option {bf:replace} or specify a different {bf:generate()}."
				error `errNWsExists'
			}
			nwdrop `generate'
		}
		nwduplicate `netname', name(`generate')
		local netname `generate'
	}
	nw_syntax `netname', max(1)
	local netobj2 `netobj'
	
	mata: `netobj2'->set_edge((*`netobj1'->get_matrix())')
	
end
