
capture program drop nwneighbor
program nwneighbor
	syntax [anything(name=netname)], ego(string) [ mode(string) generate(string) replace SUBnet(string) subreplace]
	nw_syntax `netname', max(1)
	_nwdatasync `netname'
	nwname `netname'

	capture confirm variable `generate'
	if _rc == 0 & "`replace'" == "" {
		di "{err}Variable {bf:`generate'} already exists; use {bf:replace}"
		err 99
	}
	qui nwnode `netname', ego(`ego')
	local egoid `r(nodeid)'
	local ego `r(nodename)'
	if `egoid' == -1 {
		di "{err}Node {bf:`ego'} does not exist in network {bf:`netname'}"
		err 99
	}

	if "`mode'" == "" {
		local mode = "outgoing"
	}

	_opts_oneof "incoming outgoing either" "mode" "`mode'" 6556
	
	// Sparse-accessor rewrite: the prior dense-matrix "incoming" line had a
	// stray unbalanced paren (a genuine, latent syntax-error bug - that
	// mode could never have actually run). neighbors()/neighbors_in() are
	// the same sparse CSR/CSC accessors already used by calculate_kcore()
	// etc.; nzmask's own !=0 & !=. edge convention (build_sparse_index())
	// matches the dense comparison this replaces exactly, so results are
	// identical, not just equivalent.
	if "`mode'" == "outgoing" {
		mata: __nb = `netobj'->neighbors(`egoid')
	}
	if "`mode'" == "incoming" {
		mata: __nb = `netobj'->neighbors_in(`egoid')
	}
	if "`mode'" == "either"{
		mata: __nb = uniqrows(`netobj'->neighbors(`egoid') \ `netobj'->neighbors_in(`egoid'))
	}
	mata: _select = J(1, `nodes', 0)
	mata: _select[__nb'] = J(1, rows(__nb), 1)
	mata: neighbors = select((`netobj'->get_nodenames() \ strofreal(1::`netobj'->get_nodes())'), _select)
	mata: mata drop __nb

	// subnet(): induced ego-network extraction (ego + its own neighbors,
	// and the ties among them) as a genuine new named network - built on
	// NWdef::copy_subgraph_into() (unw_core.do), the same
	// extract_subgraph() construction nwcohesion's own Moody-White
	// hierarchy already uses internally, here made user-visible for the
	// first time (that pointer was previously only ever used for a
	// throwaway, never-registered internal recursion step). Deliberately
	// placed HERE, before the r()-posting section below - `nwvalidate'/
	// `nwdrop'/`nw_syntax' each set their OWN r() results as an
	// unavoidable side effect of running, which would otherwise silently
	// clobber nwneighbor's own r(egoid)/r(num_neighbors)/r(neighbors)/
	// r(oneneighbor) before the caller ever sees them (confirmed
	// directly: an earlier version of this block ran AFTER that section
	// and a caller's own `r(num_neighbors)' read back whatever `nw_syntax'
	// itself had most recently set instead). `keep_nodes()' (called
	// inside `copy_subgraph_into()') takes a 0/1 INDICATOR vector aligned
	// to every node, not a list of node indices - confirmed directly from
	// its own real source (`if (cols(k) == cols(nodes))', silently a
	// no-op otherwise - an earlier version passed a short index list here
	// and the subnet silently came back as a full, unpruned copy of the
	// original network instead of erroring). `_select' (already built
	// above, marking neighbors) already has exactly this shape - COPIED
	// (not mutated in place: `_select' is also read later for
	// `generate()''s own neighbor-only variable, and must not silently
	// gain ego's own position too) with ego's own position added in.
	if "`subnet'" != "" {
		mata: __nwneighbor_sel = _select
		mata: __nwneighbor_sel[`egoid'] = 1
		nwvalidate `subnet'
		if "`r(exists)'" == "true" {
			if "`subreplace'" == "" {
				di "{err}Network {bf:`subnet'} already exists; use {bf:subreplace}"
				capture mata: mata drop neighbors
				err 99
			}
			capture nwdrop `subnet'
		}
		// `nw_syntax' sets `netname' itself too, via its own `c_local
		// netname' (nw_syntax.ado) - a real, easy-to-miss side effect
		// (confirmed directly: an earlier version restored via `nw_syntax
		// `netname'' AFTER calling `nw_syntax `subnet'', but by then
		// `netname' had ALREADY been silently overwritten to `subnet''s
		// own value by that same call, so the "restore" call actually
		// re-ran `nw_syntax `subnet'' a second time instead of restoring
		// anything - every remaining line in this program, including the
		// display header, silently kept operating on the new subnet
		// network). Fixed by saving the original name into its own local
		// FIRST, never relying on `netname' surviving the subnet call.
		local __nwneighbor_origname `netname'
		tempname __nwneighbor_src
		mata: `__nwneighbor_src' = `netobj'
		mata: nw.nws.add("`subnet'")
		nw_syntax `subnet'
		mata: `__nwneighbor_src'->copy_subgraph_into(`netobj', __nwneighbor_sel)
		mata: `netobj'->set_name("`subnet'")
		mata: mata drop `__nwneighbor_src' __nwneighbor_sel
		local __nwneighbor_subnetmsg "Induced subgraph saved as network `subnet'"
		nw_syntax `__nwneighbor_origname', max(1)
	}

	capture confirm variable `generate'
	if (_rc != 0 | "`replace'" != "") & "`generate'" != "" {
		capture drop `generate'
		gen `generate' =.
		mata: st_store((1::`nodes'), "`generate'", _select')
	}
	mata: st_rclear()
	capture mata: st_global("r(ego)", "`ego'")
	capture mata: st_numscalar("r(egoid)", `egoid')
	// BUGFIX: was `jumble(neighbors)[1]' - `neighbors' is a 2-row
	// (name-row, id-row) x N-col matrix; `jumble()' shuffles MATRIX
	// ROWS, not columns, so on a matrix with more than one neighbor this
	// only ever randomized whether the name-row or the id-row came
	// first, then linear-indexed (column-major) to whatever landed in
	// position (1,1) - i.e., always "the first neighbor", and a coin
	// flip on whether that returned its name or its numeric id. It
	// happened to look like it worked for exactly one neighbor (name and
	// id both describe "the only neighbor"), but never actually selected
	// AMONG multiple neighbors at all. Fixed to genuinely pick a random
	// COLUMN (one whole neighbor, name+id together), then take that
	// neighbor's own name (row 1).
	mata: st_numscalar("__nwneighbor_n", cols(neighbors))
	if `=__nwneighbor_n' > 0 {
		capture mata: st_global("r(oneneighbor)", neighbors[1, runiformint(1,1,1,`=__nwneighbor_n')])
	}
	else {
		mata: st_global("r(oneneighbor)", "")
	}
	mata: st_numscalar("r(num_neighbors)", cols(neighbors))
	scalar drop __nwneighbor_n

	di ""
	di "{hline 40}"
	di "{txt}  Network: {res}`netname'"
	di "{hline 40}"
	di "{txt}    Ego        :   {res}`ego' (`r(egoid)')"
	di "{txt}    Neighbors  : {res}" _continue
	di ""
	mata: neighbors'
	mata: st_matrix("r(neighbors)", strtoreal(neighbors'[.,2]))
	di ""
	di "{hline 40}"
	if `"`__nwneighbor_subnetmsg'"' != "" {
		di "{txt}    `__nwneighbor_subnetmsg'"
		di "{hline 40}"
	}

	capture mata: mata drop neighbors
end

