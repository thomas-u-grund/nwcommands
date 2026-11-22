
capture program drop nwmaxflow
program nwmaxflow, rclass
	version 12
	syntax [anything(name=netname)], SOURCE(string) SINK(string) [WEIGHTed GENerate(string) replace]
	_nwsyntax `netname'
	local __wasdir = ("`directed'" == "true")
	local __wasval = ("`valued'" == "true")
	_nwmissnote `netname', quiet
	local __nmiss = r(nmissing)

	qui nwnode `netname', ego(`source')
	local srcid `r(nodeid)'
	if `srcid' == -1 {
		di "{err}Node {bf:`source'} does not exist in network {bf:`netname'}"
		exit 485
	}
	qui nwnode `netname', ego(`sink')
	local snkid `r(nodeid)'
	if `snkid' == -1 {
		di "{err}Node {bf:`sink'} does not exist in network {bf:`netname'}"
		exit 485
	}
	if `srcid' == `snkid' {
		di "{err}source() and sink() must be different nodes."
		exit 198
	}

	local val = ("`weighted'" != "")

	if "`generate'" != "" {
		capture confirm variable `generate'
		if _rc == 0 & "`replace'" == "" {
			di "{err}Variable {bf:`generate'} already exists; use {bf:replace}"
			exit 110
		}
	}

	tempname __nw_mf
	mata: `__nw_mf' = `netobj'->calculate_maxflow(`srcid', `snkid', `val')
	mata: st_numscalar("__nwmaxflow_value", `__nw_mf'[`nodes'+1,1])
	mata: st_numscalar("__nwmaxflow_cutedges", `__nw_mf'[`nodes'+2,1])

	if "`generate'" != "" {
		// BUGFIX: the active dataset was never synced to the target
		// network before st_store() below - see nwpagerank.ado's
		// identical fix and comment for the full account; confirmed to
		// crash the same way here via the same adversarial-input probe
		// (only exercised when generate() is actually used, which is
		// why this went unnoticed - nwmaxflow's own regression test
		// never called generate() on a freshly cleared dataset).
		_nwsetobs `netname'
		tempvar __nw_mf_included
		_nwdatasync `netname', generate(`__nw_mf_included')

		capture confirm new variable `generate'
		if _rc capture drop `generate'
		qui gen `generate' = .
		mata: st_store((1::`nodes'),"`generate'", `__nw_mf'[1::`nodes',1])
	}
	mata: mata drop `__nw_mf'

	return scalar maxflow = __nwmaxflow_value
	return scalar cutedges = __nwmaxflow_cutedges
	return local source "`source'"
	return local sink "`sink'"

	di "{hline 40}"
	di "{txt}  Network: {res}`netname'"
	di "{txt}  Source: {res}`source'{txt}   Sink: {res}`sink'"
	di "{txt}  Max flow: {res}`=__nwmaxflow_value'{txt}   Min-cut edges: {res}`=__nwmaxflow_cutedges'"
	di "{hline 40}"
	if `__wasdir' {
		di "{txt}{p 2 2 2}(directed network: flow follows the direction of the ties){p_end}"
	}
	else {
		di "{txt}{p 2 2 2}(undirected network: a tie carries flow in both directions){p_end}"
	}
	if `__wasval' & !`val' {
		di "{txt}{p 2 2 2}(valued network: every tie has capacity 1, tie values ignored; option {bf:weighted} uses the tie values as capacities){p_end}"
	}
	else if `__wasval' {
		di "{txt}{p 2 2 2}(valued network: the tie values are the capacities){p_end}"
	}
	else {
		di "{txt}{p 2 2 2}(every tie has capacity 1){p_end}"
	}
	if `__nmiss' > 0 {
		di "{txt}{p 2 2 2}(`__nmiss' missing ties treated as 0){p_end}"
	}
	if "`generate'" != "" {
		di "{txt}{p 0 0 2}(`generate' == 1 marks the source side of the minimum cut; every existing tie from a 1 to a 0 is a cut edge){p_end}"
	}
	scalar drop __nwmaxflow_value __nwmaxflow_cutedges
end
