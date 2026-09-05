
capture program drop nwfactions
program nwfactions, rclass
	version 12
	syntax [anything(name=netname)][, GROUPS(int 2) GENerate(string) replace measure(string) maxiter(int 100) silent]
	set more off

	if `groups' < 2 {
		di "{err}groups() must be at least 2 - a 1-group partition is not a factions solution."
		error 198
	}
	if `maxiter' < 1 {
		di "{err}maxiter() must be a positive integer."
		error 198
	}

	nw_syntax `netname'

	if `groups' > `nodes' {
		di "{err}groups(`groups') exceeds the number of nodes (`nodes')."
		error 198
	}

	local netmeasure "`measure'"
	if "`netmeasure'" == "" {
		if "`valued'" == "true" {
			local netmeasure "valued"
		}
		else {
			local netmeasure "binary"
		}
	}
	_opts_oneof "binary valued" "measure" "`netmeasure'" 6556

	local netgenerate "`generate'"
	if "`netgenerate'" == "" {
		local netgenerate = "_faction"
	}

	capture confirm variable `netgenerate', exact
	if _rc == 0 & "`replace'" == "" {
		di "{err}Variable {bf:`netgenerate'} already exists; specify {bf:replace}"
		err 99
	}

	local val = ("`netmeasure'" == "valued")

	// BUGFIX: the active dataset was never synced to the target network
	// before st_store() below - see nwpagerank.ado's identical fix and
	// comment for the full account; confirmed to crash the same way
	// here via the same adversarial-input probe.
	_nwsetobs `netname'
	tempvar __nw_fac_included
	_nwdatasync `netname', generate(`__nw_fac_included')

	capture drop `netgenerate'
	gen `netgenerate' = .
	mata: st_rclear()

	tempname __nw_fac
	capture noisily mata: `__nw_fac' = `netobj'->calculate_factions(`groups', `val', `maxiter')
	if _rc != 0 {
		exit _rc
	}
	mata: st_store((1::`nodes'),"`netgenerate'", `__nw_fac'[1::`nodes',1])
	mata: st_numscalar("faction_fitness", `__nw_fac'[`nodes'+1,1])
	mata: mata drop `__nw_fac'

	return scalar fitness = faction_fitness
	return scalar groups = `groups'
	return local netgenerate "`netgenerate'"
	local lfit = faction_fitness

	if "`silent'" == "" {
		di "{hline 40}"
		di "{txt}  Network name: {res}`netname'"
		di "{txt}  Groups: {res}`groups'{txt}   Fitness: {res}`=round(`lfit',0.001)'"
		tab `netgenerate'
		di " "
	}
end
