
capture program drop nwmaxflow
program nwmaxflow, rclass
	version 12
	syntax [anything(name=netname)], SOURCE(string) SINK(string) [WEIGHTed GENerate(string) replace]
	nw_syntax `netname'

	qui nwnode `netname', ego(`source')
	local srcid `r(nodeid)'
	if `srcid' == -1 {
		di "{err}Node {bf:`source'} does not exist in network {bf:`netname'}"
		err 99
	}
	qui nwnode `netname', ego(`sink')
	local snkid `r(nodeid)'
	if `snkid' == -1 {
		di "{err}Node {bf:`sink'} does not exist in network {bf:`netname'}"
		err 99
	}
	if `srcid' == `snkid' {
		di "{err}source() and sink() must be different nodes."
		error 198
	}

	local val = ("`weighted'" != "")

	if "`generate'" != "" {
		capture confirm variable `generate'
		if _rc == 0 & "`replace'" == "" {
			di "{err}Variable {bf:`generate'} already exists; use {bf:replace}"
			err 99
		}
	}

	tempname __nw_mf
	mata: `__nw_mf' = `netobj'->calculate_maxflow(`srcid', `snkid', `val')
	mata: st_numscalar("__nwmaxflow_value", `__nw_mf'[`nodes'+1,1])
	mata: st_numscalar("__nwmaxflow_cutedges", `__nw_mf'[`nodes'+2,1])

	if "`generate'" != "" {
		capture drop `generate'
		gen `generate' = .
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
	if "`generate'" != "" {
		di "{txt}(`generate' == 1 marks the source side of the minimum cut; every existing tie from a 1 to a 0 is a cut edge)"
	}
	scalar drop __nwmaxflow_value __nwmaxflow_cutedges
end
