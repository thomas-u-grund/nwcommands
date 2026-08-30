capture program drop nwshared
program nwshared
	// BUGFIX: `undirected' is documented (syntax diagram + synoptset)
	// and referenced in this program's own body below, but was never
	// declared here - Stata rejected it outright as an unrecognized
	// option, so the documented option could never actually be used.
	//
	// Naming consistency (moderate-severity pass, generators_derived
	// group): this group had three different, differently-spelled
	// collision-override conventions (auto-rename-on-unspecified-name()
	// for most siblings; a plain `replace' for nwsubset; `nwreplace'
	// here, the only one prefixed "nw"). Added `replace' as the primary
	// name, keeping `nwreplace' working as a backward-compatible alias.
	syntax [anything(name=netname)] [, name(string) nwreplace replace undirected]
	if "`nwreplace'" != "" & "`replace'" != "" {
		di "{err}Specify only one of {bf:nwreplace} or {bf:replace} (they are the same option) - not both."
		error 198
	}
	if "`replace'" != "" {
		local nwreplace "replace"
	}
	unw_defs
	nw_syntax `netname'

	if "`name'" == "" {
		local name "_shared"
	}
	nwvalidate `name'
	local name_exists = "`r(exists)'"
	if "`r(exists)'" == "true" & "`nwreplace'" == "" {
		// BUGFIX: was `error 3000' - a bare Stata error code with its
		// own, unrelated built-in meaning ("Mata compile-time error"),
		// so Stata prints ITS OWN generic canned text for that alongside
		// this command's own custom message, confusingly implying an
		// actual crash rather than a deliberate name-collision guard.
		// Error-code coherence pass: consolidated onto `errNWsExists'
		// (483, unw_defs.ado) - see nwsimmelian.ado's own identical fix
		// for the full history of this convention's drift.
		noi di "{err}No, network {bf:`name'} already exists; use differentname or option {bf:nwreplace}."
		error `errNWsExists'
	}
	// BUGFIX: was an unconditional `capture nwdrop `name'' - when `name'
	// did NOT already exist (the ordinary first-creation case), `nwdrop'
	// itself failed (as expected) and `capture' swallowed the error, but
	// left `_rc' nonzero with nothing afterward to reset it - a
	// successful `nwshared' call could still leak a stale nonzero `_rc'
	// to its own caller (found via a new regression test asserting
	// `_rc==0' immediately after an ordinary, successful call - the
	// pre-existing test coverage never checked `_rc' at that specific
	// point). `nwvalidate' above already knows whether `name' exists, so
	// only drop it when it genuinely does, removing the need for
	// `capture' here at all.
	if "`name_exists'" == "true" {
		nwdrop `name'
	}


	tempname symmetrized
	if "`undirected'" != "" {
		// BUGFIX: was `name(`symmetrized')' - nwsym.ado's own real
		// option for its output network name is `generate()', not
		// `name()' (confirmed against its own syntax line). This was
		// unreachable until the `undirected' option itself was fixed
		// above (previously rejected before ever getting this far), so
		// it never actually ran until now.
		nwsym `netname', generate(`symmetrized')
		local netname `symmetrized'
	}
	
	nwduplicate `netname', name(`name')
	nw_syntax

	mata: `netobj'->set_edge((`netobj'->get_matrix_unvalued_copy()):* ((`netobj'->get_matrix_unvalued_copy()) * (`netobj'->get_matrix_unvalued_copy())))
	// BUGFIX: was an unconditional `capture nwdrop `symmetrized'' - the
	// tempname `symmetrized' is only ever actually created as a real
	// network when `undirected' was given (see above); otherwise this
	// drop failed every time (nothing to drop) and, being the very last
	// line of the program, its own swallowed `capture' failure became
	// this command's own final, leaked `_rc' on an otherwise entirely
	// successful call - the same trailing-capture leak class as the
	// `nwdrop `name'' fix above, just at the opposite end of the
	// program.
	if "`undirected'" != "" {
		capture nwdrop `symmetrized'
	}
end
