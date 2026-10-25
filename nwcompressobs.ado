capture program drop nwcompressobs
program nwcompressobs
	// BUGFIX: this program had no `syntax' line at all, so any options
	// or arguments a caller typed after the command name were silently
	// ignored instead of raising "invalid syntax"/"option not allowed",
	// and the command still returned rc==0. This program takes no
	// arguments or options at all (confirmed via both of its own real
	// callers, nwdropnodes.ado/nwreplacemat.ado, which both invoke it
	// bare) - a plain `syntax' with no clause rejects anything else.
	syntax
	tempvar allmissing
	tempvar temp
	
	qui gen `allmissing' = .
	// string variables are tested against "", numeric ones against . (encode, used here before, fails above
	// 65,536 distinct strings, e.g. the node labels of a network with more than 65,536 nodes, and then the
	// numeric test hit a string: type mismatch)
	qui foreach var of varlist _all {
		capture confirm string variable `var'
		if (_rc == 0) {
			replace `allmissing' = 0 if `var' != ""
		}
		else {
			replace `allmissing' = 0 if `var' != .
		}
	}
	qui drop if (`allmissing' == .)

	// _rc is left stale from the loop's own "capture encode" probe
	// above: encode legitimately fails (r(107), "not possible with
	// numeric variable") for any already-numeric variable - a fully
	// expected, already-captured outcome, not a real error - but
	// quietly-prefixed commands (like the "qui drop" just above) do
	// not refresh _rc even when they succeed (see nwbrokerage.ado's
	// own certified row for the fuller explanation of this Stata
	// behavior), so that stale, misleading nonzero _rc otherwise
	// survives all the way out to nwcompressobs's own caller. This
	// is a genuinely widespread latent bug, not specific to any one
	// caller - confirmed directly that _rc==107 after nwcompressobs
	// runs on literally any dataset containing at least one numeric
	// variable, which every network's own _nwinclude column already
	// guarantees. Reset explicitly and silently.
	capture local __nw_rcreset = 1
end
*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
