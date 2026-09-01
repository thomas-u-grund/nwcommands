
capture program drop nwrandom
program nwrandom
	// Trailing `*' wildcard removed - it was never referenced (`options''
	// does not appear anywhere in this file), so it only served to
	// silently accept and discard any misspelled/unrecognized option
	// instead of erroring, unlike every sibling generator in this group
	// (nwpref/nwlattice/nwring/nwsmall), none of which have this
	// wildcard and all of which correctly reject unknown options.
	syntax anything(name=nodes), [weights(string) selfloop ntimes(integer 1) Census(numlist integer min=1 max=3) Density(string) Prob(string) labs(string) name(string) undirected xvars noreplace]
	unw_defs
	
	// Generate valid network name and valid varlist
	// BUGFIX: an unspecified name() has always been documented/expected
	// to auto-rename on collision ("random", "random_1", ...) rather than
	// require replace() - unlike an explicit, caller-chosen name(), which
	// nwset.ado's own guard (harmonisation unit 116) now correctly holds
	// to the create/replace convention. Since this default "random" is
	// itself passed to nwset as an explicit name() below, nwset can no
	// longer tell it apart from a genuine user-chosen one and started
	// raising an uncaught r(6099) on a second bare `nwrandom N, prob(P)'
	// call in the same session (confirmed via a direct probe; also the
	// root cause of cscripts/test_nwplot_multinet_regression.do's own
	// failure). Resolved the same way as nwuse.ado's/nwqap.ado's own
	// identical cases: only when the caller did NOT supply name()
	// (preserving the strict, correct error for a genuine explicit
	// collision), pre-resolve the actual (possibly auto-incremented)
	// target name via nwvalidate before nwset ever sees it.
	local name_was_given = ("`name'" != "")
	if "`name'" == "" {
		local name "random"
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
			// BUGFIX: this recursive call never forwarded `weights' -
			// every ntimes()>1 call silently came back as a plain
			// unweighted 0/1 network regardless of weights(), no
			// warning or error.
			nwrandom `nodes', census(`census') name(`name'_`i') density(`density') prob(`prob') weights(`weights') `selfloop' `xvars' `undirected' labs(`labs')
		}
		qui nwset
		local newnetlist `r(nets)'
		local netlist : list newnetlist - oldnetlist
		mata: st_rclear()
		mata: st_global("r(netlist)", "`netlist'")
		exit
	}
	
	tempname __nwnew
	
	if ("`prob'" != "") {
		mata: `__nwnew' = get_random_prob(`nodes', `prob', ("`undirected'" != ""), "`selfloop'" != "")
	}
	if ("`density'" != "") {
		mata: `__nwnew' = get_random_density(`nodes', `density', ("`undirected'" != ""), "`selfloop'" != "")
	}
	if "`census'" != "" {
		local mutual : word 1 of `census'
		local asym : word 2 of `census'
		if "`asym'" == "" {
			local asym = 0	
		}
		local total = `mutual' + `asym'	
		if `total' > `=((`nodes' * (`nodes'-1)) / 2)' {
			// BUGFIX: was a bare `exit' (no return code) - the message
			// printed but the command returned rc==0 as if nothing were
			// wrong (same disguised-silent-failure class already fixed
			// elsewhere in this package, see nwevcent.ado's own header
			// comment). Also fixed a typo ("manny" -> "many") while
			// touching this line.
			di "{err}Too many dyads requested,"
			error 198
		}
		mata: `__nwnew' = dyadcensusGenerator(`nodes', `mutual', `asym')
	}
	
	if "`weights'" != "" {
		tempname w
		capture mata: `w' = (`weights') :/ sum((`weights')) 
		capture mata: `w' = rdiscrete(`nodes', `nodes',(`w')) 
		if _rc != 0 {
			// BUGFIX: this used to print the message and fall straight
			// through - the two `capture mata:' lines just below then
			// ALSO silently failed (operating on `w', left undefined by
			// this same failure), so `__nwnew' never actually got
			// multiplied by any weight at all and the command returned
			// rc==0 with a plain unweighted 0/1 network, silently
			// ignoring weights() entirely instead of erroring. Confirmed
			// directly (nwrandom 5, prob(1) weights(abc,def) printed the
			// message and still returned a "Valued: false" network).
			// Same fix applied identically to nwring.ado/nwsmall.ado/
			// nwpref.ado/nwdyadprob.ado, which all share this exact code.
			di "{err}Could not sample tie weights, check option {bf:weights()}.{txt}"
			error 198
		}

		if "`undirected'" != "" {
			mata: `w' = lowertriangle(`w',0)
			mata: `w' = `w' + `w''
		}
		capture mata: `__nwnew' = `__nwnew' :* `w'
	}
	
	if ("`prob'"=="" & "`density'"=="" & "`census'" == ""){
		// BUGFIX: was a bare `exit' (no return code) - the message
		// printed but the command returned rc==0 as if nothing were
		// wrong (same disguised-silent-failure class already fixed
		// elsewhere in this package, see nwevcent.ado's own header
		// comment, and nwsmall.ado's own identical "neither prob() nor
		// shortcuts() given" case).
		di "{err}either {it:prob}(), {it:density}() or {it:census()} missing"
		error 198
	}

	mata: st_rclear()
	nwset, mat(`__nwnew') name(`name') labs(`labs') `undirected' `selfloop'
	if "`xvars'" == "" {
		nwload, xvars
	}
	else {
		nwload
	}

	capture mata: mata drop `__nwnew'

	// r(netlist) is documented (Stored results, above) as always being
	// set to "list of new networks" - true for the ntimes()>1 branch's
	// own early exit above, but this single-network base case never set
	// it at all (found while dealing with xvars consistently project-
	// wide, which happened to route more calls through this exact final
	// stretch of the program).
	mata: st_global("r(netlist)", "`name'")
end


capture mata: mata drop tiesGenerator()
capture mata: mata drop correctDiagonal()
capture mata: mata drop dyadcensusGenerator()
capture mata: mata drop get_random_prob()
capture mata: mata drop get_random_density()

mata:
real matrix get_random_prob(real scalar nodes, real scalar prob, real scalar undirected, real scalar selfloop){
	real matrix adj 
	
	adj = floor(uniform(nodes,nodes) :+ prob)
	if (undirected == 1) {
		_makesymmetric(adj)
	}
	if (selfloop == 0){
		_diag(adj,0)
	}
	return(adj)
}

real matrix get_random_density(real scalar nodes, real scalar density, real scalar undirected, real scalar selfloop){
	real scalar ties, n2, tiesdiag
	real matrix adj
	
	ties = floor((nodes * (nodes -(1 - selfloop)) * density))
	n2 = nodes * nodes
		
	if (undirected == 0){
		adj=(1::n2)
		_jumble(adj)
		adj=colshape(adj, nodes)
		adj = (adj:<=ties)
		tiesdiag = sum(diagonal(adj))
		if (selfloop == 0){
			adj = correctDiagonal(adj,0, tiesdiag)
		}
	}
	else {
		adj = tiesGenerator(nodes, ties)
		tiesdiag = sum(diagonal(adj))
		if (selfloop == 0){
			adj = correctDiagonal(adj,1, tiesdiag)
		}
	}
	return(adj)
}

real matrix function tiesGenerator(real scalar nodes, real scalar ties)
{
	real matrix X
	real scalar temp
	
	ties = ties / 2
	temp = ((nodes * (nodes-1) / 2) + nodes)
	X = invvech(jumble((1::temp)))
	X = (X:<=ties)
	return(X)
}

real matrix function dyadcensusGenerator( scalar nodes, scalar mutual, scalar asym)
{
	real matrix X
	real scalar temp, ties, M, A, tiesdiag, T, R, Rlower, Rupper, Rboth
	
	ties = ties / 2
	temp = ((nodes * (nodes-1) / 2) + nodes)
	X = invvech(jumble((1::temp)))
	M = (X:<=mutual)
	A = (X:> mutual):*(X:<= (asym + mutual))
	
	tiesdiag = sum(diagonal(M))
	M = correctDiagonal(M,1, tiesdiag )
	_diag(M,0)
	
	T = M :+ A
	T = T :/ T
	_editmissing(T,0)
	_diag(T, 0)

	tiesdiag = (2 * (mutual + asym) - sum(T)) / 2	
	T = correctDiagonal(T,1, tiesdiag)
	T = T :/ T
	_editmissing(T,0)
	_diag(T, 0)

	A = T :- M
	R = round(runiform(nodes, nodes))
	
	Rlower = lowertriangle(R, 0)
	Rupper = uppertriangle(J(nodes, nodes, 1) - Rlower',0)
	Rboth = Rlower + Rupper
	A = A:* Rboth
	return(M :+ A)
}

real matrix function correctDiagonal(real matrix net, scalar undirected, scalar tiesdiag){
	real scalar nodes, i, found, ran, rrow, rcol
	
	nodes = rows(net)
	for (i = 1 ; i <= tiesdiag; i++ ) {
		found = 0
		while (found == 0) {
			ran = (ceil(runiform(1,2):* nodes))
			rrow = ran[1,1]
			rcol = ran[1,2]
			if ((net[rrow, rcol] == 0) & (rrow != rcol))  {
				found = 1
				net[rrow, rcol] = 1
				if (undirected == 1){
					net[rcol, rrow] = 1
				}
			}
		}
	}
	_diag(net, 0)
	return(net)
}
end

