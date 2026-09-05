
capture program drop nwrandomwalk
program nwrandomwalk, rclass
	version 12
	syntax [anything(name=netname)], TARGET(string) [GENerate(string) replace silent]

	_nwsyntax `netname'

	qui nwnode `netname', ego(`target')
	local tid `r(nodeid)'
	if `tid' == -1 {
		di "{err}Node {bf:`target'} does not exist in network {bf:`netname'}"
		err 99
	}

	if "`generate'" == "" {
		local generate "_hitting"
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
	capture noisily mata: `__nw_ht' = `netobj'->calculate_randomwalk_hitting(`tid')
	if _rc != 0 {
		exit _rc
	}
	capture drop `generate'
	gen double `generate' = .
	mata: st_store((1::`nodes'), "`generate'", `__nw_ht')
	mata: mata drop `__nw_ht'

	return local target "`target'"
	return local generate "`generate'"

	if "`silent'" == "" {
		di "{hline 40}"
		di "{txt}  Network: {res}`netname'"
		di "{txt}  Target: {res}`target'"
		di "{hline 40}"
		summarize `generate'
	}
end
