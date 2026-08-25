
capture program drop nwhomophily
program def nwhomophily
	// `stub(string)' removed - it was accepted by syntax but never
	// referenced anywhere in this file's body (generated Stata variables
	// always used the package's own default naming regardless of any
	// stub() value), and the underlying nwdyadprob call this delegates to
	// has no stub()-equivalent option of its own to forward it to either -
	// wiring up a real implementation would mean extending nwdyadprob
	// too, out of scope for a moderate-severity doc/dead-option fix.
	syntax varlist(min=1), homophily(string) density(real) [mode(string) nodes(string) name(string) xvars undirected]
	
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
	
	// BUGFIX: an unspecified name() has always been documented/expected
	// to auto-rename on collision ("homophily", "homophily_1", ...)
	// rather than require replace() - see nwrandom.ado's/nwpref.ado's own
	// identical fix (harmonisation unit 126/129/130) for the full root
	// cause. Resolved the same way: only when the caller did NOT supply
	// name(), pre-resolve the actual (possibly auto-incremented) target
	// name via nwvalidate before nwset ever sees it.
	local name_was_given = ("`name'" != "")
	if "`name'" == "" {
		local name "homophily"
	}
	if !`name_was_given' {
		nwvalidate `name'
		local name = r(validname)
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
	nwdyadprob , mat(`__temp0') density(`density') name(`name') `undirected' `xvars'
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
