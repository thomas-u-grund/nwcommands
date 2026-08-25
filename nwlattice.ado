capture program drop nwlattice
program nwlattice
	syntax anything(name=dims) , [xwrap ywrap name(string) labs(string) vars(string) stub(string) xvars undirected noreplace ntimes(integer 1)]
	version 9
	set more off
	
	// Get parameters
	local cols = word("`dims'",1)
	local rows = 1
	if (wordcount("`dims'") > 1) {
		local rows = word("`dims'",2)
	}
	local nodes = `cols' * `rows'
	
	// Check if this is the first network in this Stata session
	if "$nwtotal" == "" {
		global nwtotal = 0
	}

	// Generate valid network name and valid varlist
	// BUGFIX: an unspecified name() has always been documented/expected
	// to auto-rename on collision ("lattice", "lattice_1", ...) rather
	// than require replace() - see nwrandom.ado's/nwpref.ado's own
	// identical fix (harmonisation unit 126/129) for the full root
	// cause. Resolved the same way: only when the caller did NOT supply
	// name(), pre-resolve the actual (possibly auto-incremented) target
	// name via nwvalidate before nwset ever sees it.
	local name_was_given = ("`name'" != "")
	if "`name'" == "" {
		local name "lattice"
	}
	if !`name_was_given' {
		nwvalidate `name'
		local name = r(validname)
	}
	if "`stub'" == "" {
		local stub "lattice"
	}
	nwvalidate `name'
	local latticename = r(validname)
	local varscount : word count `vars'
	if (`varscount' != `nodes'){
		nwvalidvars `nodes', stub(`stub')
		local latticevars "$validvars"
	}
	else {
		local latticevars "`vars'"
	}
	
	if `ntimes' != 1 {
		di in smcl as txt "{p}"
		qui nwset
		local oldnetlist `r(nets)'
		forvalues i = 1/`ntimes'{
			if mod(`i', 25) == 0 {
				di in smcl as txt "...`i'"
			}
			nwlattice `cols' `rows', name(`name'_`i') stub(`stub') `xvars' `undirected' labs(`labs') vars(`latticevars')
		}
		// Feature parity (moderate-severity pass, generators_structural
		// group): only nwrandom exposed r(netlist) for its own ntimes()>1
		// case; nwpref/nwlattice/nwring/nwsmall all share the identical
		// convention but never returned it.
		qui nwset
		local newnetlist `r(nets)'
		local netlist : list newnetlist - oldnetlist
		mata: st_rclear()
		mata: st_global("r(netlist)", "`netlist'")
		exit
	}

	
	// Generate network	
	mata: newmat = J(`nodes',`nodes', 0)
	forvalues i = 1/`nodes' {
		local right = `i' + 1
		local left = `i' - 1
		
		local up = `i' - `cols'
		local down = `i' + `cols'
		
		if ((mod(`=`right'-1', `cols') != 0) & `right' <= `nodes') mata: newmat[`i', `right'] = 1
		if ((mod(`left', `cols') != 0) & `left' > 1) mata: newmat[`i', `left'] = 1
		// BUGFIX: was unconditional - a targeted patch for the left-
		// neighbor condition above excluding node 2's own tie back to
		// node 1 (`left' > 1' skips `left'==1, i.e. i==2), executed on
		// every outer-loop iteration regardless of matrix size. For a
		// single-node lattice (`nodes'==1) there is no node 2 at all,
		// so indexing [2,1] into the 1x1 `newmat' crashed ("subscript
		// invalid", r3301). Guarded rather than reformulating the
		// left-neighbor condition itself, to avoid any risk of changing
		// behavior for the nodes>=2 case this line already handles
		// (specifically the cols()==1 lattice, where changing the
		// general condition instead could alter which ties get created
		// - not attempted here without the same cross-validation rigor
		// a correctness-affecting formula change would need).
		if (`nodes' >= 2) mata: newmat[2,1]=1
		if (`up' > 0) mata: newmat[`i', `up'] = 1 
		if (`down' > 0 & `down' <= `nodes') mata: newmat[`i', `down'] = 1
		
		// BUGFIX: xwrap/ywrap's own implementations were swapped relative
		// to nwlattice.sthlp's documented meaning ("xwrap: wrap
		// horizontally" / "ywrap: wrap vertically"), and the block that
		// used to run under `ywrap' additionally had the wrong divisor/
		// offset (`rows' where row-major indexing - row length `cols' -
		// needs `cols'), so it only ever matched a horizontal wrap by
		// coincidence on a square lattice (rows==cols), which is exactly
		// the only shape the pre-existing tests ever exercised. Node `i'
		// is at row `=`i'-1'/`cols'+1`, column `=mod(`i'-1',`cols')+1`
		// (0-indexed row-major, then +1). A horizontal wrap connects
		// column-1 to column-`cols' within the same row (identify
		// column-1 nodes via mod(i-1,cols)==0, connect i to i+cols-1); a
		// vertical wrap connects row-1 to row-`rows' within the same
		// column (identify row-1 nodes via i<=cols, connect i to
		// i+(rows-1)*cols - this part was already correct, just under
		// the wrong option name).
		if "`xwrap'" != "" {
			if mod(`i' - 1, `cols') == 0 {
				mata: newmat[`i',(`i' + `cols' - 1)] = 1
				mata: newmat[(`i' + `cols' - 1), `i'] = 1
			}
		}
		if "`ywrap'" != "" {
			if `i' <= `cols'{
				mata: newmat[`i',(`i' + ((`rows' - 1) * `cols'))] = 1
				mata: newmat[(`i' + ((`rows' - 1) * `cols')), `i'] = 1
			}
		}
		
		
	}
	
	mata: st_rclear()
	nwset, mat(newmat) vars(`latticevars') name(`name') `undirected' labs(`labs')
	if "`xvars'" == "" {
		nwload `randomname', xvars
	}
	else {
		nwload `randomname'
	}
	mata: st_global("r(netlist)", "`name'")
	mata: mata drop newmat
end


*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
