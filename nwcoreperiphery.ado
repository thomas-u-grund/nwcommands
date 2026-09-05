
capture program drop nwcoreperiphery
program nwcoreperiphery, rclass
	version 12
	syntax [anything(name=netname)][, GENerate(string) replace measure(string) maxiter(int 100) silent]
	set more off

	if `maxiter' < 1 {
		di "{err}maxiter() must be a positive integer."
		error 198
	}

	_nwsyntax `netname', max(9999)

	if `networks' > 1 {
		local k = 1
	}

	qui foreach netname_temp in `netname' {
		_nwsyntax `netname_temp'

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
			local netgenerate = "_core"
		}

		capture confirm variable `netgenerate'`k', exact
		if _rc == 0 & "`replace'" == "" {
			noi di "{err}Variable {bf:`netgenerate'`k'} already exists; specify {bf:replace}"
			err 99
		}

		local val = ("`netmeasure'" == "valued")

		capture drop `netgenerate'`k'
		gen `netgenerate'`k' = .
		mata: st_rclear()
		qui if _N < `nodes' {
			set obs `nodes'
		}
		_nwsyntax `netname_temp'

		tempname __nw_cp
		capture noisily mata: `__nw_cp' = `netobj'->calculate_coreperiphery(`val', `maxiter')
		if _rc != 0 {
			exit _rc
		}
		mata: st_store((1::`nodes'),"`netgenerate'`k'", `__nw_cp'[1::`nodes',1])
		mata: st_numscalar("cp_fitness", `__nw_cp'[`nodes'+1,1])
		mata: st_numscalar("cp_coresize", sum(`__nw_cp'[1::`nodes',1]))
		mata: mata drop `__nw_cp'

		return scalar fitness = cp_fitness
		return scalar core = cp_coresize
		local lfit = cp_fitness
		local lcore = cp_coresize

		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			noi di "{txt}  Core size: {res}`lcore'{txt}   Fitness: {res}`=round(`lfit',0.001)'"
			noi tab `netgenerate'`k'
			noi di " "
		}
		local k = `=`k' + 1'
	}
end
