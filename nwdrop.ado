
capture program drop nwdrop
program nwdrop
	version 9
	syntax [anything(name=netname)] [if] [in], [clean]
	unw_defs
	local __bare = (`"`netname'"' == "")
	_nwsyntax `netname', max(9999)
	if `__bare' & `"`if'`in'"' == "" di "{txt}(no network named: dropping the current network {res}`netname'{txt})"

	if `"`if'"' == "" & `"`in'"' == "" {
		// one compiled function drops the networks and counts the rest (nwf_drop() in unw_core.do)
		mata: st_local("__nwdrop_left", strofreal(nwf_drop(`"`netname'"')))
		if `__nwdrop_left' == 0 {
			capture mata: mata drop `nw'
		}
	}
	else {
		_nwsyntax `netname', max(1)
		local n `nodes'
		_nwdatasync `netname'
		
		tempvar ifcond temp
		tempname drop
		qui gen `ifcond' = 1 `if' `in'
		qui gen `temp' = `ifcond' * `nw_included'
		mata: `drop' = (st_data((1::`nodes'),"`ifcond'"))'
		mata: _editmissing(`drop', 0)
		mata: st_local("__alldrop", strofreal(sum(`drop' :!= 0) >= cols(`drop')))
		if `__alldrop' {
			mata: mata drop `drop'
			di "{err}{p 0 0 2}The condition selects every node of {bf:`netname'}. To drop the network, type {bf:nwdrop `netname'}.{p_end}"
			exit 198
		}
		mata: `netobj'->drop_nodes(`drop')
		mata: mata drop `drop'
		if "`clean'" != "" {
			capture drop if `temp' == 1
		}
		_nwdatasync `netname'
	}
	mata: st_rclear()
end


