
capture program drop nwreplace
program nwreplace, rclass
	local arg =`"`0'"'
	gettoken netname nonet: arg, parse("=")
	local netname = trim("`netname'")

	// specific enrtries are given
	local ego = strpos("`netname'","[") 
	local alter = strpos("`netname'","]") 
	local sep = strpos("`netname'",",")
	local subset = substr("`netname'",`ego',.)
	if (`ego' != 0) {
		local e1 = `ego' + 1
		local e2 = `sep' - `ego' - 1
		local a1 =  `sep' + 1
		local a2 = `alter' - `sep' - 1
		local n1 = `ego' - 1
		local egoid = substr("`netname'", `e1', `e2')
		local alterid = substr("`netname'", `a1', `a2')
		local netname = substr("`netname'", 1, `n1')
	}

	nw_syntax `netname'
	nw_datasync `netname'
	
	local newcmd0 "(*`netobj'->get_matrix())"
	local newcmd "(*`netobj'->get_matrix())`subset'"
	
	capture mata: `newcmd'
	if _rc != 0 {
		di "{err}{it:nwsubset} {bf:`subset'} invalid"
		error 6400
	}
	
	if "`netname'" == "=" {
		di "{err}{it:networkname} required before ="
		error 6001
	}
	
	// get rid of first equal sign
	local nonet = substr(trim(`"`nonet'"'),2,.)
	
	// separate conditions
	local inpos = strpos(`"`nonet'"', " in ")
	local ifpos = strpos(`"`nonet'"', " if ")
	local ifegopos = strpos(`"`nonet'"', " ifego ")
	local ifalterpos = strpos(`"`nonet'"'," ifalter ")
	
	if (`inpos' == 0) { 
		local inpos = "" 
	}
	if (`ifpos' == 0) { 
		local ifpos = "" 
	}
	if (`ifegopos' == 0) { 
		local ifegopos = "" 
	}
	if (`ifalterpos' == 0) { 
		local ifalterpos = "" 
	}
	capture numlist "`ifpos' `ifegopos' `ifalterpos' `inpos'", sort
	local condition "`r(numlist)'"
	local condlength = wordcount("`condition'")

	forvalues i = 1 / `condlength' {
		local w = word("`condition'", `i')
		if ("`w'" == "`inpos'"){
			local inend = word("`condition'", `=`i' + 1')
			if "`inend'" == "" {
				local inend = "."
			}
			local incmd = substr(`"`nonet'"', `=`inpos'  + 4', `=`inend' - `inpos' - 4')
		}
		if ("`w'" == "`ifpos'"){
			local ifend = word("`condition'", `=`i' + 1')
			if "`ifend'" == "" {
				local ifend = "."
			}
			local ifcmd = substr(`"`nonet'"', `=`ifpos'  + 4', `=`ifend' - `ifpos' - 4')
		}
		if ("`w'" == "`ifegopos'"){
			local ifegoend = word("`condition'", `=`i' + 1')
			if "`ifegoend'" == "" {
				local ifegoend = "."
			}
			local ifegocmd = substr(`"`nonet'"', `=`ifegopos'  + 7', `=`ifegoend' - `ifegopos' - 7')
		}
		if ("`w'" == "`ifalterpos'"){
			local ifalterend = word("`condition'", `=`i' + 1')
			if "`ifalterend'" == "" {
				local ifalterend = "."
			}
			local ifaltercmd = substr(`"`nonet'"', `=`ifalterpos'  + 9', `=`ifalterend' - `ifalterpos' - 9')
		
		}
	}

	local firstcond = word("`condition'",1) 
	if "`firstcond'"=="" {
		local firstcond = "."
	}
	local netexp = substr(`"`nonet'"',1, `firstcond') 
	local netexp `"(`netexp')"'
	_nwexpnetexp `netexp', nodes(`nodes')
	local newnetexp `netexp'

	local cndcmd "J(`nodes',`nodes',1)"
	if `"`ifcmd'"' != "" {
		local netexp ""
		capture _nwexpnetexp `ifcmd', nodes(`nodes')
		local ifnetexp `"`netexp'"'
		local cndcmd `"`cndcmd' :* `ifnetexp'"'
	}
	
	if `"`ifegocmd'"' != "" {
		local netexp ""
		capture _nwexpnetexp `ifegocmd', nodes(`nodes')
		local ifegonetexp `"`netexp'"'
		local cndcmd `"(`cndcmd') :* (`ifegonetexp')"'
	}
	
	if `"`ifaltercmd'"' != "" {
		local netexp ""
		capture _nwexpnetexp `ifaltercmd', nodes(`nodes')
		local ifalternetexp `"`netexp'"'
		local cndcmd `"(`cndcmd') :* (`ifalternetexp')'"'
	}

	if `"`cndcmd'"' != "" {
		local cmd `"`newcmd' = ((`newnetexp' :* (`cndcmd')) + (`newcmd0' :* ((`cndcmd') :!= 1)))`subset'"'  
	}
	else {
		local cmd `"`newcmd' = (`newnetexp')`subset'"'
	}
	
	mata: `cmd'
	mata: `netobj'->invalidate_sparse()

	nw_syntax `netname'
	mata: st_numscalar("r(symmetric)", `netobj'->check_symmetry())
	mata: st_numscalar("r(valued)", `netobj'->check_valued())
	// BUGFIX: captured into plain locals IMMEDIATELY after the two
	// `mata: st_numscalar("r(...)", ...)' calls above, before either
	// `if' block below can run `_nwname' - a separate ado invocation
	// that, like any command, replaces r() with its own results the
	// moment it runs. The previous ordering read `r(symmetric)'/
	// `r(valued)' AFTER these `if' blocks, so whenever the
	// newdirected(false)/newvalued(true) correction actually fired
	// (network content and RNG-state dependent - confirmed via a live
	// repro: `nwcorrelate ..., permutations(100)' followed by
	// `nwrandom ... undirected' occasionally produces a matrix that
	// isn't perfectly symmetric, triggering the correction), `_nwname'
	// had already wiped r(), leaving `` `r(symmetric)' `` empty and
	// `local __symmetric = `r(symmetric)'' a bare `local x = ' -
	// Stata's own generic "invalid syntax" (r(198)), not a message
	// this package ever wrote. Found while preparing this package's own
	// Stata Journal submission (the article's generate/replace example
	// hit this directly).
	local __symmetric = `r(symmetric)'
	local __valued = `r(valued)'
	if ("`directed'"=="false" & `__symmetric'==0) {
		_nwname `netname', newdirected(false)
	}
	if ("`valued'" == "false" & "`r(valued)'" == "false"){
		_nwname `netname', newvalued(true)
	}
	nwsync `netname'
	return scalar symmetric = `__symmetric'
	return scalar valued = `__valued'

end

