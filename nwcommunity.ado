
capture program drop nwcommunity
program nwcommunity, rclass
	version 12
	syntax [anything(name=netname)][, GENerate(string) replace measure(string) SYMmetrize resolution(real 1) algorithm(string) seed(int -1) silent listall ONEmode STARTs(int 30)]
	set more off

	// resolution() had no input validation at all - zero or negative
	// values run without error but push the reported r(modularity) well
	// outside modularity's own normal [-1,1] range (confirmed directly:
	// resolution(-1) on a standard two-triangle bridge network yields
	// r(modularity)=2). Reichardt-Bornholdt resolution is conventionally
	// > 0; validated here rather than silently accepting a value that
	// produces a result the package's own test suite elsewhere asserts
	// should never occur.
	if `resolution' <= 0 {
		di "{err}Option {bf:resolution()} must be > 0."
		error 198
	}

	local algorithm = lower("`algorithm'")
	if "`algorithm'" == "" {
		local algorithm "louvain"
	}
	_opts_oneof "louvain labelprop" "algorithm" "`algorithm'" 6556

	if `seed' != -1 {
		set seed `seed'
	}

	if `starts' < 1 {
		di "{err}Option {bf:starts()} must be at least 1."
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
			noi di "{err}Community detection not defined for directed networks. Either specify {bf:symmetrize} or symmetrize the network first (see {help nwsym})."
			error 198
		}

		if "`generate'" == "" {
			noi di "{err}option {bf:generate()} required."
			error 198
		}
		local netgenerate "`generate'"

		// Checks the exact suffixed name this iteration is about to
		// create, not the bare stem - Stata's own variable-name
		// abbreviation would otherwise let `confirm variable
		// _community' match an already-existing `_community1' on a
		// later netlist iteration, falsely blocking that iteration
		// even though its own target name is still free. Found while
		// building nwconcor.ado's netlist support (same underlying
		// bug, same fix - see its own certified row).
		capture confirm variable `netgenerate'`k', exact
		if _rc == 0 & "`replace'" == "" {
			noi di "{err}Variable {bf:`netgenerate'`k'} already exists; specify {bf:replace}"
			err 99
		}

		local val = ("`netmeasure'" == "valued")
		// a two-mode network is scored and searched with Barber's bipartite modularity (R: bipartite::computeModules,
		// the null model counts only pairs of nodes from different modes); onemode gives Newman's Q of the bipartite
		// graph read as a one-mode graph (igraph::cluster_louvain)
		local __bip = ("`is2mode'" == "true" & "`onemode'" == "")
		local __qtype = cond(`__bip', "barber", "newman")
		local __qlab = cond(`__bip', "{space 1}(Barber, two-mode)", "")

		capture drop `netgenerate'`k'
		gen `netgenerate'`k' = .
		mata: st_rclear()
		qui if _N < `nodes' {
			set obs `nodes'
		}
		// align row i of the data set with node i of this network before the
		// positional st_store() below (a data set that was sorted or reordered, or
		// synced to another network such as a two-mode projection, would otherwise
		// receive the values on the wrong rows)
		_nwsyncrows `netname_temp'
		mata: st_rclear()
		_nwsyntax `netname_temp'

		tempname __nw_comm
		if "`algorithm'" == "labelprop" {
			mata: `__nw_comm' = `netobj'->detect_communities_labelprop(`val')
		}
		else if `__bip' {
			mata: `__nw_comm' = `netobj'->detect_communities_bipartite(`val', `resolution', `starts')
		}
		else {
			mata: `__nw_comm' = `netobj'->detect_communities_louvain(`val', `resolution')
		}
		mata: st_store((1::`nodes'),"`netgenerate'`k'", `__nw_comm')
		// BUGFIX: `val' (already computed above from measure()) used to
		// never be forwarded, so calculate_modularity() always scored on
		// the network's raw valued weights regardless of what measure()
		// requested - measure(binary) was a complete no-op, silently
		// corrupting the reported r(modularity) for the community
		// partition detect_communities_louvain()/labelprop() actually
		// searched for under measure(binary).
		if `__bip' {
			mata: st_numscalar("modularity", `netobj'->calculate_modularity_bipartite(`__nw_comm', `val', `resolution'))
		}
		else {
			mata: st_numscalar("modularity", `netobj'->calculate_modularity(`__nw_comm', `val', `resolution'))
		}
		mata: mata drop `__nw_comm'

		// PERFORMANCE/CORRECTNESS FIX: `tab ..., matrow() matcell()'
		// crashes outright ("too many values", r134) once the network
		// has enough distinct communities - confirmed directly:
		// Louvain on a sparse (avg degree ~10) random n=10,000 graph
		// genuinely finds 4,322 communities (not a pathological edge
		// case - large sparse graphs commonly lack strong community
		// structure, so this is expected algorithm behavior, not a
		// bug in detect_communities_louvain() itself), which exceeds
		// Stata's own `tab' command's internal category-count limit.
		// The later `matrix rownames = `rowlabs'' line has the exact
		// same class of failure for the same reason, one level down
		// (a 4,322-token command-line string blows Stata's own
		// matsize-driven row-name-parsing limit, r915) - confirmed
		// directly with an isolated repro completely independent of
		// this command. Both replaced with Mata-native equivalents
		// that never route the community count through a Stata
		// command-line string or `tab''s own tabulation limit at all:
		// a single sort + panelsetup() pass computes the same
		// (id, size) tabulation `tab' used to (O(n log n) instead of
		// paying `tab''s own overhead, and with no category-count
		// ceiling), and `st_matrixrowstripe()' sets the "commN" row
		// labels directly via Mata's own matrix API, which has no
		// analogous token-count limit.
		mata: __nwc_vals = st_data((1::`nodes'), "`netgenerate'`k'")
		mata: __nwc_sorted = sort(__nwc_vals, 1)
		mata: __nwc_info = panelsetup(__nwc_sorted, 1)
		mata: comm_number = rows(__nwc_info)
		mata: comm_id = __nwc_sorted[__nwc_info[.,1]]
		mata: comm_size = __nwc_info[.,2] :- __nwc_info[.,1] :+ 1
		mata: comm_share = comm_size :/ (sum(comm_size))
		mata: comm_sizeid = J(comm_number, 3, 0)
		mata: comm_sizeid[.,1] = comm_size
		mata: comm_sizeid[.,2] = comm_id
		mata: comm_sizeid[.,3] = comm_share
		mata: comm_sizeid = sort(comm_sizeid, (-1, 2))
		mata: st_numscalar("communities", comm_number)
		mata: st_matrix("comm_sizeid", comm_sizeid)

		matrix colnames comm_sizeid = size compid share

		return scalar modularity = modularity
		return local modularity_type "`__qtype'"
		return scalar communities = communities
		local lcomm = communities
		local lmod = modularity

		mata: __nwc_stripe = J(comm_number, 2, "")
		mata: __nwc_stripe[., 2] = "comm" :+ strofreal((1::comm_number))
		mata: st_matrixrowstripe("comm_sizeid", __nwc_stripe)
		return matrix comm_sizeid = comm_sizeid
		mata: mata drop comm_number comm_share comm_id comm_size comm_sizeid __nwc_vals __nwc_sorted __nwc_info __nwc_stripe

		if "`silent'" == "" {
			noi di "{hline 40}"
			noi di "{txt}  Network name: {res}`netname_temp'"
			noi di "{txt}  Communities: {res}`lcomm'"
			noi di "{txt}  Modularity Q`__qlab': {res}`=strtrim(string(round((`lmod')*1000)/1000,"%9.0g"))'"
			if `lcomm' <= 30 | (`lcomm' <= 1000 & "`listall'" != "") {
				noi tab `netgenerate'`k'
			}
			else if `lcomm' <= 1000 {
				noi tab `netgenerate'`k' if `netgenerate'`k' <= 30
				noi di "{txt}  (first 30 of `lcomm' communities shown; use {bf:listall} for the full table)"
			}
			else {
				noi di "{txt}  (the table of the `lcomm' communities is not shown; sizes are in r(comm_sizeid))"
			}
			noi di " "
		}
		local k = `=`k' + 1'
	}
end
