
capture program drop nwaltergen
program nwaltergen
	version 12

	local 0 = trim("`0'")
	gettoken expr options : 0, parse(",") bind
	if "`options'" != "" {
		local 0 `options'
		syntax [, net(string) replace hop(int 1)]
	}
	if "`hop'" == "" {
		local hop = 1
	}
	if `hop' < 1 {
		di as err "{err}hop() must be a positive integer."
		error 198
	}
	local expr = subinstr("`expr'", " ", "", .)

	// proportion(alter.srcvar==value) / proportion(alter.srcvar!=value):
	// the proportion of ego's alters whose srcvar equals (or does not
	// equal) a specific category - the genuinely new capability;
	// mean(alter.x) already covers "proportion with x==1" for an
	// already-binary x, so a bare proportion(alter.x) (no comparison)
	// is deliberately not offered as a separate synonym for mean() -
	// one unambiguous way to ask for it. Only a numeric comparison
	// value is supported (the common case: an integer-coded category) -
	// checked explicitly with confirm number below rather than left to
	// fail confusingly deep inside the Mata call. Implemented by
	// building the 0/1 comparison indicator in Stata first, then
	// reusing calculate_alterstat()'s existing, already-certified
	// mean path on it - no unw_core.do changes needed at all.
	local isproportion = 0
	if regexm("`expr'", "^([A-Za-z_][A-Za-z0-9_]*)=proportion\(alter\.([A-Za-z_][A-Za-z0-9_]*)(==|!=)(.+)\)$") {
		local isproportion = 1
		local newvarname = regexs(1)
		local srcvar = regexs(2)
		local propop = regexs(3)
		local propval = regexs(4)
		local stat = "mean"

		// Mata's bare == / != test whole-matrix identity (one scalar),
		// not an elementwise comparison - the elementwise operators are
		// :== / :!= . Confirmed directly: a first attempt using the
		// bare operator silently collapsed the comparison to a single
		// scalar 0/1 instead of a per-alter vector, caught only by a
		// downstream conformability error, not by any warning at the
		// point of the mistake itself.
		local matapropop = cond("`propop'" == "==", ":==", ":!=")

		capture confirm number `propval'
		if _rc {
			di as err "{err}proportion()'s comparison value must be numeric; got {bf:`propval'}."
			error 198
		}
	}
	else if !regexm("`expr'", "^([A-Za-z_][A-Za-z0-9_]*)=(mean|sum|min|max|sd|count|diversity)\(alter\.([A-Za-z_][A-Za-z0-9_]*)\)$") {
		di as err "syntax should be: {it:newvar} = {it:stat}(alter.{it:srcvar}), {it:stat} one of mean|sum|min|max|sd|count|diversity|proportion(alter.srcvar==value)"
		error 198
	}
	else {
		local newvarname = regexs(1)
		local stat = regexs(2)
		local srcvar = regexs(3)
	}

	confirm variable `srcvar'

	capture confirm new variable `newvarname'
	if _rc & "`replace'" == "" {
		di as err "{err}Variable {bf:`newvarname'} already exists; specify {bf:replace}"
		// Error-code coherence: was 110 - every sibling command in this
		// group (nwgeodesic/nwpath/nwbridges/nwneighbor/nwego) uses 99
		// for the identical "already exists" situation, matching this
		// package's own standard use of 99 for "a Stata variable already
		// exists" (see nw_errorcodes.sthlp).
		error 99
	}

	nw_syntax `net'

	if _N < `nodes' {
		di as err "dataset has fewer observations (`=_N') than the network has nodes (`nodes')"
		error 4
	}

	tempname __nw_srcvar __nw_alterstat
	mata: `__nw_srcvar' = st_data(1::`nodes', "`srcvar'")
	if `isproportion' {
		// preserves missingness through the comparison rather than
		// letting a missing srcvar silently read as "not in category"
		// (Mata's :== treats missing as an ordinary comparable value,
		// not as "unknown" - a missing alter must still be *excluded*
		// by calculate_alterstat()'s own downstream missing-dropping
		// logic, exactly as it already is for every other stat).
		mata: `__nw_srcvar' = (`__nw_srcvar' `matapropop' `propval')
		mata: `__nw_srcvar'[selectindex(st_data(1::`nodes',"`srcvar'"):==.)] = J(sum(st_data(1::`nodes',"`srcvar'"):==.), 1, .)
	}
	if `hop' == 1 {
		mata: `__nw_alterstat' = `netobj'->calculate_alterstat(`__nw_srcvar', "`stat'")
	}
	else {
		// hop(k>1): aggregate over nodes at exactly k (unweighted)
		// steps away instead of direct neighbors - see
		// calculate_alterstat_hop()'s own header comment in
		// unw_core.do. hop(1) deliberately still calls
		// calculate_alterstat() directly above rather than
		// calculate_alterstat_hop(...,1) - confirmed the two give
		// bit-identical results, but keeping the well-established,
		// unmodified 1-hop code path as the default minimizes any
		// risk of this option regressing existing behavior.
		mata: `__nw_alterstat' = `netobj'->calculate_alterstat_hop(`__nw_srcvar', "`stat'", `hop')
	}

	capture drop `newvarname'
	qui gen `newvarname' = .
	mata: st_store((1::`nodes'), "`newvarname'", `__nw_alterstat')
	mata: mata drop `__nw_srcvar' `__nw_alterstat'

	local hopsuffix ""
	if `hop' > 1 {
		local hopsuffix " (hop `hop')"
	}
	if `isproportion' {
		label variable `newvarname' "proportion of alter.`srcvar' `propop' `propval'`hopsuffix'"
	}
	else {
		label variable `newvarname' "`stat' of alter.`srcvar'`hopsuffix'"
	}

	// _rc is left stale (111, "variable not found") from the earlier
	// "capture drop `newvarname'" line above - a plain, expected no-op
	// on a variable that doesn't exist yet, but quietly-prefixed and
	// inherently silent commands (confirm, mata:, local, label
	// variable) do NOT refresh _rc even when they succeed (see
	// nwbrokerage.ado's own header comment for the full explanation and
	// how this was first found) - reset explicitly and silently here so
	// a caller checking _rc right after this command sees this
	// command's own actual outcome. Pre-existing in this file even for
	// the original mean/sum/... path, not introduced by proportion() -
	// fixed for both while already here.
	capture confirm variable `newvarname', exact
end
