*! Date        : 26oct2015
*! Version     : 2.0
*! Author      : Thomas Grund, University College Dublin
*! Email	   : thomas.u.grund@gmail.com

capture program drop nw_syntax
program nw_syntax
	syntax [anything],[max(integer 1) min(passthru) other(string) nocurrent name(string)]
	unw_defs

	if "`name'" == "" {
		local name = "netname"
	}
	
	local networks_count = 1
	if "`anything'" == ""  & "`current'" == ""{
		capture mata: st_local("_temp", `nws'.get_current_name())
		capture mata: st_numscalar("r(id)",`nws'.get_index_of_current())
	}
	else {
		capture nwunab _temp : `anything', max(`max') `min'
		local networks_count : word count `_temp'
		capture local lastnet : word `networks_count' of `_temp'
		mata: st_numscalar("r(id)", first_index_match(`nws'.names, "`lastnet'"))
	}
	
	if _rc != 0 {
		di "{err}Network {bf:`anything'} not found"
	    error `errNWsNotFound'
	}

	mata: st_local("directed", `nws'.pdefs[`r(id)']->is_directed())
	mata: st_local("valued", `nws'.pdefs[`r(id)']->is_valued())
	mata: st_local("nodes", strofreal(`nws'.pdefs[`r(id)']->get_nodes()))
	mata: st_local("selfloops", `nws'.pdefs[`r(id)']->is_selfloop())
	mata: st_local("is2mode", `nws'.pdefs[`r(id)']->is_2mode())
	mata: st_local("istemporal", `nws'.pdefs[`r(id)']->is_temporal())
	mata: st_local("temporaltype", `nws'.pdefs[`r(id)']->get_temporal_type())
	mata: st_local("datasync", strofreal(`nws'.get_datasync()))
    mata: st_local("labs", invtokens(`nws'.pdefs[`r(id)']->get_nodenames(),","))

	c_local `other'selfloops "`selfloops'"
	c_local `other'nodes "`nodes'"
	c_local `other'is2mode "`is2mode'"
	c_local `other'istemporal "`istemporal'"
	c_local `other'temporaltype "`temporaltype'"
	c_local `other'directed "`directed'"
	c_local `other'valued "`valued'"
	c_local `other'netobj "`nws'.pdefs[`r(id)']"
	c_local `other'datasync "`datasync'"
	c_local `other'id `r(id)'
	c_local `other'netname `_temp'
	c_local `other'labs "`labs'"
	c_local networks `networks_count'	
end
