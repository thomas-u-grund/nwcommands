
capture program drop nwmodularity
program nwmodularity, rclass
	version 12
	syntax [anything(name=netname)], GROUP(varname) [measure(string) SYMmetrize resolution(real 1) silent]
	set more off

	// resolution() had no input validation - same fix as nwcommunity's
	// own identical option in this same group; see its own comment for
	// the full reasoning.
	if `resolution' <= 0 {
		di "{err}Option {bf:resolution()} must be > 0."
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

		if "`directed'" == "true" & "`symmetrize'" == "" {
			noi di "{err}Modularity not defined for directed networks. Either specify {bf:symmetrize} or symmetrize the network first (see {help nwsym})."
			error 198
		}

		capture assert `group' < .
		if _rc != 0 {
			noi di "{err}Variable {bf:`group'} contains missing values; every node must be assigned to a group."
			error 198
		}

		local val = ("`netmeasure'" == "valued")

		tempname __nw_group
		mata: `__nw_group' = nw_community_denserelabel(st_data((1::`nodes'), "`group'"))

		// BUGFIX: `val' (already computed above from measure()) used to
		// never be forwarded, so calculate_modularity() always scored on
		// the network's raw valued weights regardless of what measure()
		// requested - measure(binary) was a complete no-op.
		mata: st_numscalar("modularity", `netobj'->calculate_modularity(`__nw_group', `val', `resolution'))
		mata: st_numscalar("communities", max(`__nw_group'))
		mata: mata drop `__nw_group'

		return scalar modularity = modularity
		return scalar communities = communities
		local lcomm = communities
		local lmod = modularity

		// same fix as nwcommunity.ado's own identical bug: `tab ...,
		// matrow() matcell()' crashes ("too many values", r134) once
		// there are enough distinct groups, and the later `matrix
		// rownames = `rowlabs'' has the same class of failure one
		// level down (a long enough command-line token list blows
		// Stata's own matsize-driven limit, r915) - both replaced with
		// Mata-native equivalents with no such ceiling. See
		// nwcommunity.ado's own identical fix for the full detail.
		mata: __nwm_vals = st_data((1::`nodes'), "`group'")
		mata: __nwm_sorted = sort(__nwm_vals, 1)
		mata: __nwm_info = panelsetup(__nwm_sorted, 1)
		mata: comm_number = rows(__nwm_info)
		mata: comm_id = __nwm_sorted[__nwm_info[.,1]]
		mata: comm_size = __nwm_info[.,2] :- __nwm_info[.,1] :+ 1
		mata: comm_share = comm_size :/ (sum(comm_size))
		mata: comm_sizeid = J(comm_number, 3, 0)
		mata: comm_sizeid[.,1] = comm_size
		mata: comm_sizeid[.,2] = comm_id
		mata: comm_sizeid[.,3] = comm_share
		mata: comm_sizeid = sort(comm_sizeid, -1)
		mata: st_matrix("comm_sizeid", comm_sizeid)
		mata: st_numscalar("commnum", comm_number)
		matrix colnames comm_sizeid = size compid share

		mata: __nwm_stripe = J(comm_number, 2, "")
		mata: for (__nwm_i=1; __nwm_i<=comm_number; __nwm_i++) __nwm_stripe[__nwm_i,2] = "comm" + strofreal(__nwm_i)
		mata: st_matrixrowstripe("comm_sizeid", __nwm_stripe)
		return matrix comm_sizeid = comm_sizeid
		mata: mata drop comm_number comm_share comm_id comm_size comm_sizeid __nwm_vals __nwm_sorted __nwm_info __nwm_stripe __nwm_i

		// Consistency (moderate-severity pass, community_spectral group):
		// nwmodularity had no `silent' option at all, unlike its closest
		// sibling nwcommunity (same detect/score-and-print-a-summary
		// family) and nwspectral, both of which already support it.
		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			noi di "{txt}  Communities: {res}`lcomm'"
			noi di "{txt}  Modularity Q: {res}`=round(`lmod',0.001)'"
			noi di " "
		}
		local k = `=`k' + 1'
	}
end
