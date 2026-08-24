capture program drop nworder
program nworder
	syntax anything(name=netname) [, *]
	unw_defs
	local userorder `netname'
	nw_syntax _all, max(9999)
	local allnets `netname'
	local netname `userorder'

	// BUGFIX (error-code coherence pass): the requested `netname's were
	// never validated against the actual loaded network list before
	// being used as if they were already dataset variables (via the
	// `order'/`gen' calls below) - a misspelled/nonexistent network
	// name fell through to a raw, unfriendly Stata "variable not
	// found" (r(111)) instead of this package's own standard "Network
	// ... not found" (`errNWsNotFound', 482, unw_defs.ado), unlike
	// every other command in this group (nwtomata/nwtomatafast/
	// nwsync/nwload).
	foreach onerequested of local userorder {
		local found : list onerequested in allnets
		if `found' == 0 {
			di "{err}Network {bf:`onerequested'} not found"
			error `errNWsNotFound'
		}
	}


	preserve
	clear
	foreach v in `allnets' {
		gen `v' = .
	}
	if "`options'" != "" {
		qui order `netname', `options'
	}
	else {
		qui order `netname'
	}
	qui ds 
	local newnetlist `r(varlist)'
	restore
	
	local newnetlist `r(varlist)'
	qui foreach onenet in `newnetlist' {
		nwduplicate `onenet', name(_dupl_`onenet')
	}
	qui nwdrop `newnetlist'
	
	qui foreach onenet in `newnetlist' {
		nwname _dupl_`onenet', newname(`onenet')
	}
end


*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
