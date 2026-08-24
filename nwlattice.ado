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
		forvalues i = 1/`ntimes'{
			if mod(`i', 25) == 0 {
				di in smcl as txt "...`i'"
			}
			nwlattice `cols' `rows', name(`name'_`i') stub(`stub') `xvars' `undirected' labs(`labs') vars(`latticevars')
		}
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
		mata: newmat[2,1]=1
		if (`up' > 0) mata: newmat[`i', `up'] = 1 
		if (`down' > 0 & `down' <= `nodes') mata: newmat[`i', `down'] = 1
		
		if "`xwrap'" != "" {
			if `i' <= `cols'{
				mata: newmat[`i',(`i' + ((`rows' - 1) * `cols'))] = 1
				mata: newmat[(`i' + ((`rows' - 1) * `cols')), `i'] = 1
			}
		}
		if "`ywrap'" != "" {
			if mod(`i', `rows') == 1 {
				mata: newmat[`i',(`i' + (`rows' - 1))] = 1
				mata: newmat[(`i' + (`rows' - 1)), `i'] = 1
			}
		}
		
		
	}
	
	nwset, mat(newmat) vars(`latticevars') name(`name') `undirected' labs(`labs') 
	if "`xvars'" == "" {
		nwload `randomname', xvars
	}
	else {
		nwload `randomname'
	}
	mata: mata drop newmat 
end


*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
