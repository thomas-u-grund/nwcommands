
capture program drop nwbrokerage
program nwbrokerage, rclass
	version 12
	syntax [anything(name=netname)], GROUP(varname) [GENerate(string) replace silent]

	_nwsyntax `netname', max(9999)

	if `networks' > 1 {
		local k = 1
	}

	local roles coordinator gatekeeper representative consultant liaison

	qui foreach netname_temp in `netname' {
		_nwsyntax `netname_temp'

		if "`generate'" == "" {
			di "{err}option {bf:generate()} required."
			error 198
		}
		local netgenerate "`generate'"

		foreach role of local roles {
			capture confirm variable `netgenerate'_`role'`k', exact
			if _rc == 0 & "`replace'" == "" {
				noi di "{err}Variable {bf:`netgenerate'_`role'`k'} already exists; specify {bf:replace}"
				err 99
			}
		}

		mata: st_rclear()
		qui if _N < `nodes' {
			set obs `nodes'
		}
		_nwsyntax `netname_temp'

		tempname __nw_grp __nw_brk
		mata: `__nw_grp' = st_data((1::`nodes'), "`group'")
		capture noisily mata: `__nw_brk' = `netobj'->calculate_brokerage(`__nw_grp')
		if _rc != 0 {
			exit _rc
		}

		local ri = 1
		foreach role of local roles {
			capture drop `netgenerate'_`role'`k'
			gen `netgenerate'_`role'`k' = .
			mata: st_store((1::`nodes'), "`netgenerate'_`role'`k'", `__nw_brk'[.,`ri'])
			local ri = `ri' + 1
		}
		mata: st_numscalar("brk_pairs", sum(`__nw_brk'))
		mata: mata drop `__nw_grp' `__nw_brk'

		// _rc is left stale (still 111, "variable not found") from the
		// earlier already-exists probes above, both the deliberately-
		// failing capture confirm checks and the capture drop calls on
		// not-yet-created variables - quietly-prefixed and inherently
		// silent commands (confirm, mata:, local) do NOT refresh _rc
		// even when they succeed, only a *captured* command deterministically
		// does (confirmed by direct testing: bare "confirm variable X"
		// and "qui sum X" both leave a prior nonzero _rc untouched, but
		// "capture confirm variable X" always sets _rc to exactly that
		// command's own result) - reset explicitly and silently here so
		// a caller checking _rc right after this command sees this
		// command's own actual outcome, not a leftover probe result.
		capture confirm variable `netgenerate'_liaison`k', exact

		return scalar pairs = brk_pairs
		local lpairs = brk_pairs

		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			noi di "{txt}  Two-paths classified: {res}`lpairs'"
			noi di "{txt}{col 2}{ralign 16:Role}{col 20}{c |}{col 25}Total"
			noi di "{txt}{hline 19}{c +}{hline 15}"
			local ri = 1
			foreach role of local roles {
				qui sum `netgenerate'_`role'`k'
				noi di "{txt}{col 2}{ralign 16:`role'}{col 20}{c |}{col 25}{res}`=r(sum)'"
				local ri = `ri' + 1
			}
			noi di " "
		}
		local k = `=`k' + 1'
	}
end
