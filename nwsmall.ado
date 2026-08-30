capture program drop nwsmall
program nwsmall
	// BUGFIX: `name(string)' was missing from this syntax line entirely
	// - the body below already references `` `name' `` (defaulting to
	// the hardcoded "small" when empty), but with no way to declare it
	// on the command line at all, that local could never actually be
	// set by a caller: every single nwsmall call silently ignored any
	// name() a caller tried to pass and produced a network hardcoded to
	// "small" every time (a second call without a different name(),
	// wanted or not, would collide). Found while restoring nwgenerate's
	// own small( shortcut, which failed outright with "option name()
	// not allowed" the moment it tried to pass one - not a new bug,
	// this file's own body already assumed the option existed. Added
	// here to match its own sibling nwring.ado, which already declares
	// name(string) correctly.
	syntax anything(name=nodes), k(integer) [ weights(string) ntimes(integer 1) labs(string) name(string) prob(string) shortcuts(string) undirected noreplace xvars]
	
	if "`prob'" != "" {
		if (`prob' > 1) | (`prob' < 0){
			di "{err}Probability needs to be between 0 and 1.{txt}"
		}
	}
	if "`density'" != "" {
		if (`density' > 1 | `density' < 0){
			di "{err}Density needs to be between 0 and 1.{txt}"
		}
	}
	local directed = ("`undirected'" == "")

	// BUGFIX: an unspecified name() has always been documented/expected
	// to auto-rename on collision ("small", "small_1", ...) rather than
	// require replace() - see nwrandom.ado's/nwpref.ado's own identical
	// fix (harmonisation unit 126/129) for the full root cause. Resolved
	// the same way: only when the caller did NOT supply name(),
	// pre-resolve the actual (possibly auto-incremented) target name via
	// nwvalidate before nwset ever sees it.
	local name_was_given = ("`name'" != "")
	if "`name'" == "" {
		local name "small"
	}
	if !`name_was_given' {
		nwvalidate `name'
		local name = r(validname)
	}
	
	if `ntimes' != 1 {
		di in smcl as txt "{p}"
		qui nwset
		local oldnetlist `r(nets)'
		forvalues i = 1/`ntimes'{
			if mod(`i', 25) == 0 {
				di in smcl as txt "...`i'"
			}
			// BUGFIX: was `stub(`stub')' - nwsmall's own syntax line
			// never declares a `stub' option at all, so this stray
			// token made EVERY ntimes()>1 call crash with r(198)
			// "option stub() not allowed" - identical root cause to
			// nwring.ado's own bug. Also forwards `weights' now, which
			// this recursive call never did (ntimes()>1 always came
			// back unweighted regardless of weights() - see
			// nwrandom.ado's/nwpref.ado's own identical fix).
			nwsmall `nodes', k(`k') name(`name'_`i') shortcuts(`shortcuts') prob(`prob') weights(`weights') `xvars' `undirected'
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
	
	
	if ("`prob'"=="" & "`shortcuts'"==""){
		di "{err}either {it:prob}() or {it:shortcuts}() missing"
		exit
	}
	
	tempname __nwnew
	if "`prob'" != "" {
		mata: `__nwnew' = smallworldprob(`nodes', `k', `prob', `directed')
	}
	if "`shortcuts'" != "" {
		mata: `__nwnew' = smallworldsk(`nodes', `k', `shortcuts', `directed')
	}
	
	if "`weights'" != "" {
		tempname w
		capture mata: `w' = rdiscrete(`nodes', `nodes',(`weights')) 
		if _rc != 0 {
			di "{err}Could not sample tie weights, check option {bf:weights()}.{txt}"
		}
		capture mata: `w' = `w' :/ sum((`weights'))
		if "`undirected'" != "" {
			mata: `w' = lowertriangle(`w',0)
			mata: `w' = `w' + `w''
		}
		capture mata: `__nwnew' = `__nwnew' :* `w'
	}
	
	mata: st_rclear()
	nwset, mat(`__nwnew') labs(`labs') name(`name') `undirected'
	if "`xvars'" == "" {
		nwload, xvars
	}
	else {
		nwload
	}
	mata: st_global("r(netlist)", "`name'")
end

capture mata: mata drop smallworldsk()
capture mata: mata drop smallworldprob()
capture mata: mata drop insideBand()

mata: 
real matrix smallworldsk(nodes, k, shortcuts, directed){
	real matrix net, rewires, blub, blub2
	real scalar rows, i, j, y, alreadyRewired, rx_old, ry_old, wrongPick, ry,sign
	
	// generate ring lattice
	net = J(nodes, nodes, 0)
	rows = (1::nodes)
	for (i = 1; i<=k; i++) {
		y = (editvalue(mod((rows' :+ i), (nodes)),0,nodes))'
		for (j = 1; j<= rows(y); j++){
			net[j, y[j,1]] = 1
		}
		y = (editvalue(mod((rows' :- i), (nodes)),0,nodes))'
		for (j = 1; j<= rows(y); j++){
			net[j, y[j,1]] = 1
		}
	}
	
	// initial list of ties to rewire
	rewires = runiform(shortcuts, 2)
	rewires[,1] = ceil(rewires[,1]:* nodes)
	
	if (directed == 0) {
		blub = ceil(rewires[,2]:*k)
		blub2 = editvalue(mod((rewires[,1] :+ blub), nodes), 0, nodes)
		rewires[,2] = blub2[,1]
	}
	if (directed == 1) {
		sign = round(runiform(shortcuts,1))
		sign = J(shortcuts,1,1) :- (sign :* 2) 
		rewires[,2] = editvalue(mod((rewires[,1] :+ (ceil(rewires[,2]:*k):*sign)), nodes),0,nodes)
	}
	
	alreadyRewired = 0
	for (i = 1; i<= shortcuts; i++) {		
		//make sure that tie to rewire is valid
		alreadyRewired = 1
		while (alreadyRewired == 1){
			alreadyRewired = 0
			if (net[rewires[i,1],rewires[i,2]] == 0){
				alreadyRewired = 1
			
				rewires[i,1] = ceil(runiform(1,1) * nodes)
				if (directed == 0) {
					rewires[i,2] = runiform(1,1)
					rewires[i,2] = editvalue(mod(rewires[i,1] :+ ceil(rewires[i,2]:*k), nodes), 0, nodes)
				}
				if (directed == 1) {
					sign = round(runiform(1,1))
					sign = 1 :- (sign :* 2) 
					rewires[i,2] = editvalue(mod(rewires[i,1] :+ (ceil(rewires[i,2]:*k):*sign), nodes),0,nodes)
				}
			}
		}	
		
		rx_old = rewires[i,1]
		ry_old = rewires[i,2]
		
		//require new tie
		wrongPick = 1
		while(wrongPick == 1){
			wrongPick = 0
			ry = ceil(runiform(1,1) :* nodes)
			wrongPick = (((insideBand(nodes, k, rx_old, ry)) == 1) | (net[rx_old, ry] != 0)) 
		}
		net[rx_old,ry] = 1
		if (directed == 0) {
			net[ry,rx_old] = 1
		}
		
		// delete old tie
		net[rx_old,ry_old ] = 0
		if (directed == 0) {
			net[ry_old ,rx_old ] = 0
		}		
	}
	
	return(net)
}

real scalar insideBand(nodes, k, ego, alter) {
	real scalar inside
	
	inside = 0
	
	if (((ego - alter) <= k) & (ego >= alter)) {
		inside = 1
	}
	
	if (((ego - alter) > k ) & (((alter + nodes) - ego) <= k)) {
		inside = 1
	}

	if (((alter - ego) <= k) & (alter >= ego)) {
		inside = 1
	}
	
	if (((alter - ego) > k) & (((ego + nodes) - alter) <= k)) {
		inside = 1
	}
	if (ego == alter){
		inside = 1
	}
	return(inside)
} 

real matrix smallworldprob(nodes, k, prob, directed) {
	real matrix net
	real scalar rows, i, y, j, ego, alter, wrongPick, alter_new
	// generate ring lattice
	net = J(nodes, nodes, 0)
	rows = (1::nodes)
	for (i = 1; i<=k; i++) {
		y = (editvalue(mod((rows' :+ i), (nodes)),0,nodes))'
		for (j = 1; j<= rows(y); j++){
			net[j, y[j,1]] = 1
		}
		y = (editvalue(mod((rows' :- i), (nodes)),0,nodes))'
		for (j = 1; j<= rows(y); j++){
			net[j, y[j,1]] = 1
		}
	}
	// undirected network
	if (directed == 0) {
		// loop through all nodes
		for (ego = 1; ego<= rows(y); ego++){
			// loop through all undirected ties for each node
			for (i = 1; i <= k; i++) {
				alter = mod((ego + i), nodes)
				if (alter == 0) {
					alter = nodes
				}
				
				// undirected tie to potentially rewire between ego and alter
				if (runiform(1,1) <= prob){
				
					// find new tie
					wrongPick = 1
					while(wrongPick == 1){
						wrongPick = 0
						alter_new = ceil(runiform(1,1) :* nodes)
						wrongPick = (((insideBand(nodes, k, ego, alter_new)) == 1) | (net[ego, alter_new] != 0)) 
					}
					
					
					//rewire undirected tie from ego to alter
					net[ego, alter] = 0
					net[alter, ego] = 0
					net[ego, alter_new] = 1
					net[alter_new, ego] = 1	
				}
			}
		}
	}
	
	// directed network
	if (directed == 1) {
		// loop through all nodes
		for (ego = 1; ego<= rows(y); ego++){
			// loop through all directed ties for each node
			for (i = (-k); i <= k; i++) {
				// exclude self-loops
				if (i != 0) {
					
					alter = mod((ego + i), nodes)
					if (alter == 0) {
						alter = nodes
					}
					// directed tie to potentially rewire between ego and alter
					if (runiform(1,1) <= prob){
					
						// find new tie
						wrongPick = 1
						while(wrongPick == 1){
							wrongPick = 0
							alter_new = ceil(runiform(1,1) :* nodes)
							wrongPick = (((insideBand(nodes, k, ego, alter_new)) == 1) | (net[ego, alter_new] != 0)) 
						}
					
						//rewire directed tie from ego to alter
						net[ego, alter] = 0
						net[ego, alter_new] = 1
					}
				}
			}
		}
	}
	
	return(net)
}
end

