
capture program drop nwhomophily
program def nwhomophily
	syntax varlist(min=1), homophily(string) density(real) [mode(string) nodes(string) name(string) stub(string) xvars undirected]
	
	local vc = wordcount("`varlist'")
	local hc = wordcount("`homophily'")
	local mc = wordcount("`'")
	
	if (`vc' != `hc') {
		di "{err}option {bf:homophily()} needs to have one entry for each variable in {it:varlist}."
		error 6300
	}
	
	if "`nodes'" == "" {
		local nodes = _N
		foreach var of varlist `varlist' {
			qui sum `varlist'
			local temp = r(N)
			local nodes = min(`temp',`nodes')
		}
	}
	else {
		if `nodes' > `=_N' {
			di "{err}Not enough observations of variables: {bf:`varlist'}{txt}"
			error 6044
		}
	}
	
	if "`name'" == "" {
		local name "homophily"
	}

	//local gencmd "nwgenerate _tempassort ="
	
	tempname __temp0
	tempname __temp
	
	mata: `__temp0' = J(`nodes', `nodes', 0)
	forvalues i = 1/`vc'{
	
		local onevar = word("`varlist'",`i')
		local onehom = word("`homophily'",`i')
		local onemode = word("`mode'",`i')
		
		nwexpand `onevar' if _n <= `nodes', mode(`onemode') name(_tempexpand)
		
		nw_tomata _tempexpand, mat(`__temp')
		nwdrop _tempexpand
		
		mata: `__temp' = `__temp' :* `onehom'
		mata: `__temp0' = `__temp0' :+ `__temp'
		mata: mata drop `__temp'
	}
	mata: `__temp0' = exp(`__temp0')
	nwdyadprob , mat(`__temp0') density(`density') name(`name') `undirected'
	mata: mata drop `__temp0'
	// `__temp' is already dropped at the end of the loop above (every
	// iteration cleans up after itself) - this used to be a second,
	// redundant drop of the same already-gone variable, crashing with
	// "__000001 not found" on every single call despite the command's
	// own actual logic (everything above this line) completing
	// correctly - confirmed directly via `set trace on`, which showed
	// a real network already built and summarized before this line
	// ever ran.

end
