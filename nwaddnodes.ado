
capture program drop nwaddnodes
program nwaddnodes
	syntax [anything(name=netname)], nodenames(string) [mode(numlist) generate(string) xvars]

	_nwsyntax `netname', max(1)

	// harmonisation unit 158: `mode()' fixes a previously-documented gap
	// (this command's own help header used to read "does not offer a
	// way to choose which mode the new (isolate) nodes belong to - not
	// recommended for two-mode networks until that is clarified/
	// documented"). REQUIRED (not merely accepted) on a two-mode
	// network - every other node-attribute-style option in this
	// package that has no sensible default on a mismatched network
	// type errors outright rather than silently assuming mode 1 for
	// what might genuinely be a mode-2 isolate (e.g. an institution
	// with no current members, not a person with no memberships) -
	// getting this wrong silently would corrupt every downstream
	// bipartite computation (nwergm's own `bcov1()'/`bstar1()'/etc.,
	// dyad-space size, proposal space) with no indication anything was
	// wrong.
	if "`is2mode'" == "true" & "`mode'" == "" {
		di "{err}option {bf:mode()} is required when adding nodes to a two-mode (bipartite) network {bf:`netname'} - say which of the two node sets each new node belongs to (mode 1 or mode 2). nwaddnodes never silently assumes mode 1 for what might be a mode-2 isolate."
		error 198
	}
	if "`is2mode'" != "true" & "`mode'" != "" {
		di "{err}option {bf:mode()} only applies to two-mode (bipartite) networks; {bf:`netname'} is one-mode."
		error 198
	}

	if "`generate'" != "" {
		nwduplicate `netname', name(`generate')
		_nwsyntax, max(1)
	}

	// Counted via its OWN tokenize pass (not by re-joining segments into
	// a single space-separated local) - a node name is free to contain
	// its own internal spaces (see this file's own worked example,
	// "Thomas Grund"), and `foreach ... of local' below would silently
	// re-split any such name back into separate words if the count pass
	// and the add pass shared one collapsed macro. Two independent
	// tokenize passes over the same `nodenames' string are used instead
	// - harmless and deterministic (tokenize has no side effects beyond
	// setting `1'/`2'/... and consuming nothing external) - the first
	// purely to get `__nan_nnames' for the mode()-count check below,
	// the second (further down) to actually add each node, exactly
	// mirroring this command's own original single-pass loop.
	tokenize "`nodenames'", parse(",")
	local __nan_nnames = 0
	local onename `1'
	while ("`onename'"!= ""){
		if "`onename'" != "," local __nan_nnames = `__nan_nnames' + 1
		macro shift
		local onename `1'
	}

	// `mode()' is either a single value (broadcast to every new node)
	// or exactly one value per node in `nodenames()', in the same
	// order - matching the count-check discipline nwergm.ado's own
	// multi-value options already use (e.g. degree()'s own numlist).
	local __nan_nmode : word count `mode'
	if "`mode'" != "" & `__nan_nmode' != 1 & `__nan_nmode' != `__nan_nnames' {
		di "{err}option {bf:mode()} lists `__nan_nmode' value(s) but {bf:nodenames()} lists `__nan_nnames' node(s) - specify either a single mode (applied to every new node) or exactly one mode per node, in order."
		error 198
	}
	if "`mode'" != "" {
		foreach __nan_m of numlist `mode' {
			if !inlist(`__nan_m', 1, 2) {
				di "{err}option {bf:mode()} accepts only 1 or 2 (this package's own two-mode convention); got `__nan_m'."
				error 198
			}
		}
	}

	tokenize "`nodenames'", parse(",")
	local __nan_i = 0
	local onename `1'
	while ("`onename'"!= ""){
		if "`onename'" != "," {
			local ++__nan_i
			if "`mode'" == "" {
				mata: `netobj'->add_node("`onename'")
			}
			else if `__nan_nmode' == 1 {
				mata: `netobj'->add_node("`onename'", "`mode'")
			}
			else {
				local __nan_thismode : word `__nan_i' of `mode'
				mata: `netobj'->add_node("`onename'", "`__nan_thismode'")
			}
		}
		macro shift
		local onename `1'
	}


	if "`xvars'" != "" {
		nwload `netname'
	}
end
