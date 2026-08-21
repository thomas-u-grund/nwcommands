capture program drop nwcompressobs
program nwcompressobs
	tempvar allmissing
	tempvar temp
	
	qui gen `allmissing' = .
	qui foreach var of varlist _all {
		capture encode `var', gen(`temp')
		if (_rc == 0){
			replace `allmissing' = 0 if `temp' != .
			drop `temp'
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
