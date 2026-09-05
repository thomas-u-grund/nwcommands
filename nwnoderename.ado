
capture program drop nwnoderename
program nwnoderename	
	syntax [anything(name=netname)], old(string) new(string)
	nw_syntax `netname'
	_nwdatasync `netname'
	unw_defs
	
	mata: st_numscalar("r(success)", (*`netobj').rename_nodename("`old'", "`new'"))

	if `r(success)' == 1 {
		tempvar original
		expand 2 if `nw_nodename' == "`old'", generate(`original')
		replace `nw_nodename' = "`new'" if `nw_nodename' == "`old'" & `original' == 1
		capture rename `old' `new'
		_nwdatasync `netname'
		mata: st_numscalar("r(success)", 1)
	}
	else{
		di "{err}Old name not found or new name invalid."
		mata: st_numscalar("r(success)", 0)
		exit
	}
end

