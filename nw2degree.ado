
capture program drop nw2degree
program nw2degree, rclass
	version 12
	syntax [anything(name=netname)][, GENerate(string) replace silent]
	set more off

	nw_syntax `netname', max(9999)

	if `networks' > 1 {
		local k = 1
	}

	qui foreach netname_temp in `netname' {
		nw_syntax `netname_temp'

		if "`is2mode'" != "true" {
			noi di "{err}nw2degree requires a two-mode network; `netname_temp' is one-mode. See {help nwdegree} instead."
			error 198
		}

		local netgenerate "`generate'"
		if "`netgenerate'" == "" {
			local netgenerate = "_2degree"
		}

		capture confirm variable `netgenerate'`k', exact
		if _rc == 0 & "`replace'" == "" {
			noi di "{err}Variable {bf:`netgenerate'`k'} already exists; specify {bf:replace}"
			err 99
		}

		capture drop `netgenerate'`k'
		gen `netgenerate'`k' = .
		mata: st_rclear()
		qui if _N < `nodes' {
			set obs `nodes'
		}
		nw_syntax `netname_temp'
		mata: st_store((1::`nodes'), "`netgenerate'`k'", `netobj'->calculate_2mode_degree())

		// see nwbrokerage.ado's own header comment for why this is
		// needed: quietly/mata:-only commands above do not refresh _rc
		// on their own, so the "already exists" probe's own stale rc
		// would otherwise leak out as this command's own exit code.
		capture confirm variable `netgenerate'`k', exact

		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			noi sum `netgenerate'`k'
			noi di " "
		}
		local k = `=`k' + 1'
	}
end
