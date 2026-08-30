
capture program drop nwsym
program nwsym
	version 9.0
	// `vars(string)' removed - it was accepted by syntax but never
	// referenced anywhere in this file's body (a fully dead,
	// undocumented no-op; confirmed via a direct probe).
	syntax [anything(name=netname)][, check generate(string) replace mode(string)]
	nw_syntax `netname', max(1)


	if "`check'" != "" {
		tempname __is_symmetric
		mata: st_numscalar("`__is_symmetric'", `netobj'->check_symmetry())
		if (`__is_symmetric' == 1) {
			mata: st_global("r(is_symmetric)", "true")
		}
		else {
			mata: st_global("r(is_symmetric)", "false")
		}
		mata: st_global("r(name)", "`netname'")
		di "{hline 50}"
		di "{txt}   Network name: {res} `netname'"
		di "{txt}   Directed: {res}`directed'"
		di "{txt}   Symmetric: {res}`r(is_symmetric)'"
		exit
	}

	// HARMONISATION: `noreplace' (a "no"-prefixed option whose local was
	// always named `replace' per Stata's own stem convention, holding
	// "noreplace" when passed) is replaced by a plain `replace' option -
	// stated explicitly for the in-place case, matching the package's
	// standard positive-flag convention (see NWCOMMANDS_COMMAND_STYLE.md
	// "Output creation"), rather than the double-negative "noreplace
	// without generate() errors" it used to be. Deliberately NOT declared
	// alongside a separate `noreplace' option in the same `syntax' line:
	// this package already found (see nwgeodesic.ado / docs/
	// CERTIFICATION.md) that declaring a plain `replace' option next to
	// an existing `noreplace' option in the same `syntax' line causes
	// Stata's parser to silently fail to populate `replace' at all - so
	// `noreplace' is dropped entirely rather than kept alongside `replace'.
	// `replace' and `generate()' are mutually exclusive - they request
	// opposite outcomes (mutate the original vs. leave it untouched).
	if "`replace'" != "" & "`generate'" != "" {
		di "{err}Options {bf:replace} and {bf:generate()} cannot be combined - {bf:replace} symmetrizes {help netname:netname} in place, {bf:generate()} leaves it untouched and saves the result under a new name instead."
		error 198
	}

	if "`mode'" == "" {
		local mode = "max"
	}

	// Consistency: was `nw_optsoneof' - the legacy, near-duplicate
	// validator this package has otherwise fully migrated away from
	// (23 other files, including this command's own sibling
	// nw2project.ado, already use `_opts_oneof'; nwsym.ado was the last
	// real caller of the old one).
	_opts_oneof "max min sum mean" "mode" "`mode'" 6555

	if ("`generate'" != ""){
		nwduplicate `netname', name(`generate')
		nw_syntax
		mata: `netobj'->symmetrize("`mode'")
	}
	else{
		nw_syntax `netname'
		mata: `netobj'->symmetrize("`mode'")
	}
	nwsync `netname'
end
