
capture program drop nwvalidate
program nwvalidate
	syntax anything(name=netname) [, self(string) ]
	unw_defs

	// BUGFIX: `anything' does not strip the surrounding quote characters
	// from a space-containing quoted argument the way Stata's own
	// option-value `string' type does (there is no positional-argument
	// equivalent of `string' to switch to instead - `namelist'/
	// `varlist' both reject this input outright with "invalid syntax",
	// confirmed directly) - the literal quote characters ended up
	// embedded in `netname', which then broke the
	// `strtoname("`netname'",1)' expression's own quoting further down
	// (re-embedding an already-quote-containing macro inside another
	// pair of literal double quotes), silently producing empty
	// r(tryname)/r(validname) with rc==0 rather than erroring or
	// sanitizing the space. Fixed by stripping any literal double-quote
	// characters via the `subinstr local' extended macro function
	// (which operates on the macro's own content directly, unlike a
	// plain string re-substitution, so it cannot itself trip the same
	// quoting collision) before `strtoname()' - which then sanitizes
	// the now-bare embedded space exactly like any other invalid
	// character - ever sees the value.
	local netname : subinstr local netname `"""' "", all
	local netname = strtoname("`netname'",1)
	local valid = "false"

	local prefix = ""
	local p = 1

	mata: st_global("r(tryname)", "`netname'")

	// BUGFIX: `self' was accepted by syntax but never referenced
	// anywhere in the program body - passing it (with any value) had
	// zero effect. `get_valid_name()' (the underlying Mata collision
	// check) has no built-in way to exclude a name from its own search,
	// so the one case `self' can meaningfully fix without touching that
	// shared Mata method - re-validating a network against ITS OWN
	// current name, which should never count as a collision against
	// itself - is handled directly here: if `netname' (once sanitized)
	// is exactly `self' (also sanitized, for a consistent comparison),
	// short-circuit to "no collision" before ever calling
	// `get_valid_name()'.
	if "`self'" != "" & "`netname'" == strtoname("`self'",1) {
		mata: st_global("r(validname)", "`netname'")
		mata: st_global("r(exists)", "false")
		exit
	}

	capture mata: st_global("r(validname)", `nws'.get_valid_name("`netname'"))
	if _rc != 0 {
		mata: st_global("r(validname)","`netname'")
	}

	if r(tryname) != r(validname) {
		mata: st_global("r(exists)", "true")
	}
	else {
		mata: st_global("r(exists)", "false")
	}
end

