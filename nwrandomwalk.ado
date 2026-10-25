
capture program drop nwrandomwalk
program nwrandomwalk, rclass
	version 12
	syntax [anything(name=netname)], TARGET(string) [GENerate(string) replace silent BINary ONEmode]

	_nwsyntax `netname'
	_nw2guard `netname', cmd(nwrandomwalk) allowone `onemode'
	local __nw1m = r(copied)
	local __origname "`netname'"
	local netname "`r(net)'"
	_nwsyntax `netname'
	// a valued network: the walk steps along a tie with probability proportional to its value; binary ignores the values
	local __wtd = ("`valued'" == "true" & "`binary'" == "")

	qui nwnode `netname', ego(`target')
	local tid `r(nodeid)'
	if `tid' == -1 {
		di "{err}Node {bf:`target'} does not exist in network {bf:`netname'}"
		err 99
	}

	if "`generate'" == "" {
		di "{err}option {bf:generate()} required."
		error 198
	}
	capture confirm variable `generate', exact
	if _rc == 0 & "`replace'" == "" {
		di "{err}Variable {bf:`generate'} already exists; specify {bf:replace}"
		err 99
	}

	// BUGFIX: the active dataset was never synced to the target network
	// before st_store() below - see nwpagerank.ado's identical fix and
	// comment for the full account; confirmed to crash the same way
	// here via the same adversarial-input probe.
	_nwsetobs `netname'
	tempvar __nw_ht_included
	_nwdatasync `netname', generate(`__nw_ht_included')

	tempname __nw_ht
	capture noisily mata: `__nw_ht' = `netobj'->calculate_randomwalk_hitting(`tid', `__wtd')
	if _rc != 0 {
		exit _rc
	}
	capture drop `generate'
	gen double `generate' = .
	mata: st_store((1::`nodes'), "`generate'", `__nw_ht')
	mata: mata drop `__nw_ht'

	return local target "`target'"
	return local generate "`generate'"

	if `__nw1m' local netname "`__origname'"
	if "`silent'" == "" {
		di "{hline 40}"
		di "{txt}  Network: {res}`netname'"
		di "{txt}  Target: {res}`target'"
		if `__wtd' di "{txt}  (valued network: steps in proportion to the tie values; {bf:binary} ignores the values)"
		di "{hline 40}"
		summarize `generate'
	}
	if `__nw1m' capture nwdrop __nw1m
end
