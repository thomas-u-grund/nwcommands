capture program drop nwsimmelian
program nwsimmelian
	syntax [anything(name=netname)] [, name(string) nwreplace]
	unw_defs
	_nwsyntax `netname'
	
	if "`name'" == "" {
		local name "_simmelian"
	}
	nwvalidate `name'
	if "`r(exists)'" == "true" & "`nwreplace'" == "" {
		// BUGFIX: was `error 3000' - a bare Stata error code with its
		// own, unrelated built-in meaning ("Mata compile-time error"),
		// so Stata prints ITS OWN generic canned text for that alongside
		// this command's own custom message, confusingly implying an
		// actual crash rather than a deliberate name-collision guard.
		// Error-code coherence pass: this situation ("network already
		// exists") is exactly what `errNWsExists' (483, unw_defs.ado)
		// already names and documents - several sibling commands
		// (nwset/nwfromedge/nwshared/nwtranspose/nwgenerate/nwuse) had
		// independently drifted onto an undocumented ad-hoc `6099'
		// instead of this already-established constant; all now
		// consolidated onto `errNWsExists'.
		noi di "{err}No, network {bf:`name'} already exists; use differentname or option {bf:nwreplace}."
		error `errNWsExists'
	}
	capture nwdrop `name'

	nwduplicate `netname', name(`name')
	_nwsyntax
	// mutual ties with a mutual neighbour in common (for a network held as stored ties they are found from the tie
	// list, without the n x n matrices of the dense route)
	mata: nw_simmelian_net(`netobj')
end
