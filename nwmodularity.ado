
capture program drop nwmodularity
program nwmodularity, rclass
	version 12
	syntax [anything(name=netname)], GROUP(varname) [measure(string) SYMmetrize resolution(real 1) silent ONEmode]
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
		// a two-mode network is scored with Barber's bipartite modularity (only pairs of nodes from different modes
		// enter the null model); onemode gives Newman's Q of the bipartite graph read as a one-mode graph
		local __bip = ("`is2mode'" == "true" & "`onemode'" == "")
		local __qtype = cond(`__bip', "barber", "newman")
		local __qlab = cond(`__bip', "{space 1}(Barber, two-mode)", "")

		tempname __nw_group
		mata: `__nw_group' = nw_community_denserelabel(st_data((1::`nodes'), "`group'"))

		// BUGFIX: `val' (already computed above from measure()) used to
		// never be forwarded, so calculate_modularity() always scored on
		// the network's raw valued weights regardless of what measure()
		// requested - measure(binary) was a complete no-op.
		tempname __t1 __t2 __t3 __t4
		if `__bip' {
			mata: st_numscalar("`__t1'", `netobj'->calculate_modularity_bipartite(`__nw_group', `val', `resolution'))
		}
		else {
			mata: st_numscalar("`__t1'", `netobj'->calculate_modularity(`__nw_group', `val', `resolution'))
		}
		mata: st_numscalar("`__t2'", max(`__nw_group'))
		mata: mata drop `__nw_group'

		return scalar modularity = `__t1'
		return local modularity_type "`__qtype'"
		return scalar communities = `__t2'
		local lcomm = `__t2'
		local lmod = `__t1'

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
		mata: __nwmodularity_comm_number = rows(__nwm_info)
		mata: __nwmodularity_comm_id = __nwm_sorted[__nwm_info[.,1]]
		mata: __nwmodularity_comm_size = __nwm_info[.,2] :- __nwm_info[.,1] :+ 1
		mata: __nwmodularity_comm_share = __nwmodularity_comm_size :/ (sum(__nwmodularity_comm_size))
		mata: __nwmodularity_comm_sizeid = J(__nwmodularity_comm_number, 3, 0)
		mata: __nwmodularity_comm_sizeid[.,1] = __nwmodularity_comm_size
		mata: __nwmodularity_comm_sizeid[.,2] = __nwmodularity_comm_id
		mata: __nwmodularity_comm_sizeid[.,3] = __nwmodularity_comm_share
		// ties in size: ascending id (a sort on the size alone orders equal sizes by the state of the random-number generator)
		mata: __nwmodularity_comm_sizeid = sort(__nwmodularity_comm_sizeid, (-1, 2))
		mata: st_matrix("`__t3'", __nwmodularity_comm_sizeid)
		mata: st_numscalar("`__t4'", __nwmodularity_comm_number)
		matrix colnames `__t3' = size compid share

		mata: __nwm_stripe = J(__nwmodularity_comm_number, 2, "")
		mata: for (__nwm_i=1; __nwm_i<=__nwmodularity_comm_number; __nwm_i++) __nwm_stripe[__nwm_i,2] = "comm" + strofreal(__nwm_i)
		mata: st_matrixrowstripe("`__t3'", __nwm_stripe)
		return matrix comm_sizeid = `__t3'
		mata: mata drop __nwmodularity_comm_number __nwmodularity_comm_share __nwmodularity_comm_id __nwmodularity_comm_size __nwmodularity_comm_sizeid __nwm_vals __nwm_sorted __nwm_info __nwm_stripe __nwm_i

		// Consistency (moderate-severity pass, community_spectral group):
		// nwmodularity had no `silent' option at all, unlike its closest
		// sibling nwcommunity (same detect/score-and-print-a-summary
		// family) and nwspectral, both of which already support it.
		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			noi di "{txt}  Communities: {res}`lcomm'"
			noi di "{txt}  Modularity Q`__qlab': {res}`=strtrim(string(round((`lmod')*1000)/1000,"%9.0g"))'"
			noi di " "
		}
		local k = `=`k' + 1'
	}
	capture mata: mata drop __nwmodularity_*
	capture confirm number 0
end
