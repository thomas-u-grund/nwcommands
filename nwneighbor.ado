
capture program drop nwneighbor
program nwneighbor
	syntax [anything(name=netname)], ego(string) [ mode(string) generate(string) replace]
	nw_syntax `netname', max(1)
	nw_datasync `netname'
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
	capture mata: mata drop neighbors
end

