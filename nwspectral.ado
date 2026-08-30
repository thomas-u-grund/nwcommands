
capture program drop nwspectral
program nwspectral, rclass
	version 12
	syntax [anything(name=netname)][, GENerate(string) bipartition measure(string) replace silent]
	set more off

	nw_syntax `netname', max(1)

	local netmeasure "`measure'"
	if "`netmeasure'" == "" {
		if "`valued'" == "true" {
			local netmeasure "valued"
		}
		else {
			local netmeasure "binary"
		}
	}
	_opts_oneof "binary valued" "measure" "`netmeasure'" 6556
	local val = ("`netmeasure'" == "valued")

	local netgenerate "`generate'"
	if "`netgenerate'" == "" {
		local netgenerate = "_fiedler"
	}
	local signvar = "`netgenerate'" + "sign"

	capture confirm variable `netgenerate', exact
	if _rc == 0 & "`replace'" == "" {
		noi di "{err}Variable {bf:`netgenerate'} already exists; specify {bf:replace}"
		err 99
	}
	if "`bipartition'" != "" {
		capture confirm variable `signvar', exact
		if _rc == 0 & "`replace'" == "" {
			noi di "{err}Variable {bf:`signvar'} already exists; specify {bf:replace}"
			err 99
		}
	}

	// BUGFIX: a single-node network's Laplacian is a 1x1 matrix with
	// only one eigenvalue, but this command's own algebraic-connectivity
	// step below unconditionally indexes the SECOND eigenvalue
	// (`__nw_EV'[1,2]', the Fiedler value) - crashing with a raw,
	// uncaught Mata "subscript invalid" (r3301) instead of a clean,
	// validated error. Sibling command nwhierarchy already handles the
	// identical degenerate input cleanly (via clustermat's own "1x1
	// matrix not allowed" error); nwspectral had no equivalent guard at
	// all.
	if `nodes' < 2 {
		di "{err}Network {bf:`netname'} has fewer than 2 nodes; spectral decomposition needs at least 2 nodes."
		error 198
	}

	mata: st_rclear()
	qui if _N < `nodes' {
		set obs `nodes'
	}
	nw_syntax `netname', max(1)

	tempname __nw_L __nw_EC __nw_EV __nw_ord __nw_fiedler
	mata: `__nw_L' = `netobj'->calculate_laplacian(`val')
	mata: symeigensystem(`__nw_L', `__nw_EC' = ., `__nw_EV' = .)
	mata: `__nw_ord' = order(`__nw_EV'', 1)
	mata: `__nw_EV' = (`__nw_EV''[`__nw_ord'])'
	mata: `__nw_EC' = `__nw_EC'[.,`__nw_ord']
	mata: st_matrix("nw_spectral_eigenvalues", `__nw_EV')
	mata: st_numscalar("nw_spectral_components", sum(abs(`__nw_EV') :< 1E-8))
	mata: st_numscalar("nw_spectral_algconn", `__nw_EV'[1,2])
	mata: `__nw_fiedler' = `__nw_EC'[.,2]

	capture drop `netgenerate'
	qui gen `netgenerate' = .
	mata: st_store((1::`nodes'), "`netgenerate'", `__nw_fiedler')
	if "`bipartition'" != "" {
		capture drop `signvar'
		qui gen `signvar' = .
		mata: st_store((1::`nodes'), "`signvar'", sign(`__nw_fiedler'))
	}
	mata: mata drop `__nw_L' `__nw_EC' `__nw_EV' `__nw_ord' `__nw_fiedler'

	return scalar algebraic_connectivity = nw_spectral_algconn
	return scalar components = nw_spectral_components
	return matrix eigenvalues = nw_spectral_eigenvalues
	local lalgconn = nw_spectral_algconn
	local lcomponents = nw_spectral_components

	// see nwbrokerage.ado's own header comment: the "already exists"
	// probes above leave _rc stale even after a fully successful run -
	// reset explicitly and silently.
	capture confirm variable `netgenerate', exact

	if "`silent'" == "" {
		noi di "{hline 40}"
		noi di "{txt}  Network name: {res}`netname'"
		noi di "{txt}  Connected components: {res}`lcomponents'"
		noi di "{txt}  Algebraic connectivity: {res}`=round(`lalgconn',0.0001)'"
		noi sum `netgenerate'
		noi di " "
	}
end
