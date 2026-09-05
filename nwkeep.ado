
capture program drop nwkeep
program nwkeep
	syntax [anything(name=netname)] [if] [in] [, clean]
	unw_defs
	_nwsyntax `netname', max(9999)
	local keeplist `netname'
	
	qui nwset
	local alllist `r(nets)'
	local droplist : list alllist - keeplist
	
	qui if "`if'" == "" & "`in'" == "" {
		foreach netname_temp in `droplist' {
			mata: `nws'.drop("`netname_temp'")
		}
		qui nwset
		if r(networks) == 0 {
			capture mata: mata drop `nw'
		}
	}
	else {
		_nwsyntax `netname', max(1)
		local n `nodes'
		_nwdatasync `netname'
		//list _nw*
		
		tempvar ifcond orig
		tempname keep

		qui gen `orig' = `nw_included'
		//gen o = `nw_included'
		qui gen `ifcond' = 1 `if' `in'

		mata: `keep' = (st_data((1::`nodes'),"`ifcond'"))'
		mata: _editmissing(`keep', 0)
		mata: `netobj'->keep_nodes(`keep')

		_nwsyntax `netname'
		
		if `nodes' == 0 {
			nwdrop `netname'
			exit
		}
		else {
			di "{txt}(`=`n' - `nodes'' nodes deleted)"
		}
		
		mata: mata drop `keep'
		
		_nwdatasync `netname'
		order `nw_nodename' `nw_included'
	}
	if "`clean'" != "" {
		drop if `orig' == 1 & `nw_included' != 1
	}
	mata: st_rclear()
end
