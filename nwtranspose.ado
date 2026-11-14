
capture program drop nwtranspose
program nwtranspose
	version 9
	// Naming consistency (moderate-severity pass, generators_derived
	// group): every other command in this group (nwdyadprob/
	// nwhomophily/nwexpand/nwdissimilar/nwsimilar/nwsubset/nwshared)
	// uses `name()' to name a new output network; nwtranspose alone used
	// `generate()'. Added `name()' as a working alias, kept `generate()'
	// for backward compatibility.
	syntax [anything(name=netname)], [ generate(string) name(string) replace]
	if "`generate'" != "" & "`name'" != "" {
		di "{err}{p 0 0 2}Specify only one of {bf:generate()} or {bf:name()} (they are the same option) - not both.{p_end}"
		exit 198
	}
	if "`name'" != "" {
		local generate "`name'"
	}
	unw_defs

	_nwsyntax `netname', max(1)
	local netobj1 `netobj'

	if ("`generate'" != ""){
		mata: nw_assert_netname(st_local("generate"))
		capture _nwsyntax `generate', other(_check)
		local __tr_exists = (_rc == 0)
		if `__tr_exists' & "`replace'" == "" {
			di "{err}{p 0 0 2}Network {bf:`generate'} already exists. Use option {bf:replace} or specify a different {bf:generate()}.{p_end}"
			exit `errNWsExists'
		}
		// transpose into a temporary copy; the network replaced by
		// generate() is dropped only then (it may be the source itself,
		// and dropping shifts the registry positions of the others)
		tempname __trnet
		nwduplicate `netname', name(`__trnet')
		_nwsyntax `netname', max(1)
		local netobj1 `netobj'
		_nwsyntax `__trnet', max(1)
		mata: nw_transpose_net(`netobj1', `netobj')
		if `__tr_exists' nwdrop `generate'
		mata: `nws'.rename("`__trnet'", "`generate'")
		exit
	}
	_nwsyntax `netname', max(1)
	local netobj2 `netobj'
	
	mata: nw_transpose_net(`netobj1', `netobj2')
	
end
