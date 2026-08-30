
capture program drop nwnode
program nwnode
	version 9
	syntax [anything(name=netname)], [ego(string) egoid(string)]
	nw_syntax `netname'
	
	if "`ego'" == ""  & "`egoid'" == "" {
		di "{err}Either option {bf:ego()} or {bf:egoid()} needs to be specified."
		err 99
	}
	
	mata: st_numscalar("r(nodeid)", -1)
	
	if "`egoid'" != "" {
		confirm number `egoid'
		if `egoid' <=0 | `egoid' > `nodes'{
			di "{err}Egoid `egoid' out of range"
			err 99
		}
		mata: st_global("r(nodename)", `netobj'->get_nodenames()[`egoid'])
		mata: st_numscalar("r(nodeid)", `egoid')
	}
	else if "`ego'" != "" {
		mata: st_numscalar("r(nodeid)", `netobj'->get_nodeid_from_nodename("`ego'"))
		mata: st_global("r(nodename)", "`ego'")
	}
	else {
		di "{err}Either option {bf:ego()} or {bf:egoid()} needs to be specified."
	}
	
	di ""
	di "{txt}Network: {res}`netname'"
	di "{txt}Search node: {res}`ego'"
	if `r(nodeid)' == -1 {
		di "	Not found"
	}
	else {
		di "{txt}Ego id: {res}`r(nodeid)'"
	}
end

