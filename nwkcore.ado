
capture program drop nwkcore
program nwkcore, rclass
	version 12
	syntax [anything(name=netname)][, GENerate(string) replace silent]
	set more off

	_nwsyntax `netname', max(9999)

	if `networks' > 1 {
		local k = 1
	}

	qui foreach netname_temp in `netname' {
		_nwsyntax `netname_temp'

		local netgenerate "`generate'"
		if "`netgenerate'" == "" {
			local netgenerate = "_kcore"
		}

		// BUGFIX: this used to check the bare stem `netgenerate' with no
		// iteration suffix at all, so a netlist call with 2+ networks
		// always false-errored on the second (and every later) network,
		// even though its own target variable (`netgenerate'`k') was
		// never actually created - checking the exact suffixed name
		// matches every sibling command in this group (nwclique,
		// nwkcomponents, nwkplex, nwnclan, nwnclique, nwcohesion,
		// nwcomponents).
		capture confirm variable `netgenerate'`k', exact
		if _rc == 0 & "`replace'" == "" {
			noi di "{err}Variable {bf:`netgenerate'`k'} already exists; specify {bf:replace}"
			err 99
		}

		capture drop `netgenerate'`k'
		gen `netgenerate'`k' = .
		mata: st_rclear()
		qui if _N < `nodes' {
			set obs `nodes'
		}
		_nwsyntax `netname_temp'

		tempname __nw_core
		mata: `__nw_core' = `netobj'->calculate_kcore()
		mata: st_store((1::`nodes'),"`netgenerate'`k'", `__nw_core')
		mata: st_numscalar("maxcore", max(`__nw_core'))
		mata: mata drop `__nw_core'

		qui tab `netgenerate'`k', matrow(core_id) matcell(core_size)

		mata: core_id = st_matrix("core_id")
		mata: core_number = rows(core_id)
		mata: core_size = st_matrix("core_size")
		mata: core_share = core_size :/ (sum(core_size))
		mata: core_sizeid = J(core_number, 3, 0)
		mata: core_sizeid[.,1] = core_size
		mata: core_sizeid[.,2] = core_id
		mata: core_sizeid[.,3] = core_share
		mata: core_sizeid = sort(core_sizeid, -1)
		mata: st_matrix("core_sizeid", core_sizeid)
		mata: st_numscalar("corelevels", core_number)

		matrix colnames core_sizeid = size coreid share

		return scalar maxcore = maxcore
		local lmax = maxcore
		local lcorelevels = corelevels

		local rowlabs ""
		forvalues i = 1/`lcorelevels'{
			local rowlabs "`rowlabs' core`i'"
		}
		matrix rownames core_sizeid = `rowlabs'
		return matrix core_sizeid = core_sizeid
		mata: mata drop core_number core_share core_id core_size core_sizeid

		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			noi di "{txt}  Max coreness (degeneracy): {res}`lmax'"
			noi tab `netgenerate'`k'
			noi di " "
		}
		local k = `=`k' + 1'
	}
end
