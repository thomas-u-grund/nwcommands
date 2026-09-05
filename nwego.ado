
capture program drop nwego
program nwego, rclass
	version 12
	syntax [anything(name=netname)][, sizevar(string) densvar(string) replace silent]
	set more off

	_nwsyntax `netname', max(9999)

	// sizevar()/densvar() are required (suite-wide generate()-required
	// style decision, 2026-09-05): nwego's whole purpose is producing
	// these two variables, so - matching Stata's own egen/predict
	// convention - there is no default name to silently fall back to.
	if "`sizevar'" == "" {
		di "{err}option {bf:sizevar()} required."
		error 198
	}
	if "`densvar'" == "" {
		di "{err}option {bf:densvar()} required."
		error 198
	}

	if `networks' > 1 {
		local k = 1
	}

	qui foreach netname_temp in `netname' {
		_nwsyntax `netname_temp'

		local netsizevar "`sizevar'"
		local netdensvar "`densvar'"

		capture confirm variable `netsizevar'`k', exact
		if _rc == 0 & "`replace'" == "" {
			noi di "{err}Variable {bf:`netsizevar'`k'} already exists; specify {bf:replace}"
			err 99
		}
		capture confirm variable `netdensvar'`k', exact
		if _rc == 0 & "`replace'" == "" {
			noi di "{err}Variable {bf:`netdensvar'`k'} already exists; specify {bf:replace}"
			err 99
		}

		mata: st_rclear()
		qui if _N < `nodes' {
			set obs `nodes'
		}
		_nwsyntax `netname_temp'

		tempname __nw_ego
		mata: `__nw_ego' = `netobj'->calculate_egostats()
		capture drop `netsizevar'`k'
		gen `netsizevar'`k' = .
		capture drop `netdensvar'`k'
		gen `netdensvar'`k' = .
		mata: st_store((1::`nodes'), "`netsizevar'`k'", `__nw_ego'[.,1])
		mata: st_store((1::`nodes'), "`netdensvar'`k'", `__nw_ego'[.,2])
		mata: mata drop `__nw_ego'

		// see nwbrokerage.ado's own header comment: the "already
		// exists" probes above leave _rc stale even after a fully
		// successful run - reset explicitly and silently.
		capture confirm variable `netsizevar'`k', exact

		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			noi sum `netsizevar'`k' `netdensvar'`k'
			noi di " "
		}
		local k = `=`k' + 1'
	}
end
