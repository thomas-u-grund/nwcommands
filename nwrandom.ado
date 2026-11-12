
capture program drop nwrandom
program nwrandom
	// Trailing `*' wildcard removed - it was never referenced (`options''
	// does not appear anywhere in this file), so it only served to
	// silently accept and discard any misspelled/unrecognized option
	// instead of erroring, unlike every sibling generator in this group
	// (nwpref/nwlattice/nwring/nwsmall), none of which have this
	// wildcard and all of which correctly reject unknown options.
	syntax anything(name=nodes), [weights(string) selfloop ntimes(integer 1) Census(numlist integer min=1 max=3) Density(string) Prob(string) labs(string) NODENAMESmata(string) name(string) undirected directed xvars noreplace DEGree(string) OUTdegree(string) INdegree(string) SWAPS(integer -1)]
	unw_defs
	if "`directed'" != "" & "`undirected'" != "" {
		di "{err}Options {bf:directed} and {bf:undirected} cannot be combined."
		error 198
	}
	
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
			nwrandom `nodes', census(`census') name(`name'_`i') density(`density') prob(`prob') weights(`weights') `selfloop' `xvars' `undirected' `directed' `replace' labs(`labs') nodenamesmata(`nodenamesmata') degree(`degree') outdegree(`outdegree') indegree(`indegree') swaps(`swaps')
		}
		qui nwset
		local newnetlist `r(nets)'
		local netlist : list newnetlist - oldnetlist
		mata: st_rclear()
		mata: st_global("r(netlist)", "`netlist'")
		exit
	}
	
	// degree(), outdegree() indegree(): a random network with exactly these degrees, no loops and no pair twice. A network
	// with the degrees is built (Havel-Hakimi; directed: Kleitman-Wang) and then rewired by random tie swaps, which keep
	// the degrees (igraph::sample_degseq(method = "edge.switching.simple")); native kernel 55
	if `"`degree'`outdegree'`indegree'"' != "" {
		if `"`prob'`density'`census'`weights'"' != "" {
			di "{err}{p 0 0 2}Options {bf:degree()}, {bf:outdegree()} and {bf:indegree()} cannot be combined with {bf:prob()}, {bf:density()}, {bf:census()} or {bf:weights()}.{p_end}"
			error 198
		}
		if "`selfloop'" != "" {
			di "{err}{p 0 0 2}A network drawn from degrees has no self-loops; option {bf:selfloop} is not allowed.{p_end}"
			error 198
		}
		if `"`degree'"' != "" & `"`outdegree'`indegree'"' != "" {
			di "{err}{p 0 0 2}Give either {bf:degree()} (undirected network) or {bf:outdegree()} and {bf:indegree()} (directed network).{p_end}"
			error 198
		}
		if `"`degree'"' == "" & (`"`outdegree'"' == "" | `"`indegree'"' == "") {
			di "{err}A directed network needs both {bf:outdegree()} and {bf:indegree()}."
			error 198
		}
		if `"`degree'"' != "" & "`directed'" != "" {
			di "{err}{p 0 0 2}{bf:degree()} draws an undirected network; for a directed one give {bf:outdegree()} and {bf:indegree()}.{p_end}"
			error 198
		}
		if `swaps' == 0 | `swaps' < -1 {
			di "{err}Option {bf:swaps()} must be at least 1."
			error 198
		}
		mata: st_local("__ok", strofreal(nwg_comb_version() >= 13))
		if "`__ok'" != "1" {
			di "{err}{p 0 0 2}nwrandom with degrees needs the native plugin of nwcommands 3.17.0 or later; the plugin found for this platform is older or missing.{p_end}"
			di "{err}Update it: {stata nwinstall, all}"
			error 198
		}
		tempname __dv __din __trip
		local __dir = (`"`degree'"' == "")
		if !`__dir' {
			_nwrandom_degvec, spec(`"`degree'"') nodes(`nodes') mname(`__dv') opt(degree)
			local undirected undirected
		}
		else {
			_nwrandom_degvec, spec(`"`outdegree'"') nodes(`nodes') mname(`__dv') opt(outdegree)
			_nwrandom_degvec, spec(`"`indegree'"') nodes(`nodes') mname(`__din') opt(indegree)
			mata: `__dv' = `__dv' \ `__din'
			local undirected ""
		}
		mata: `__trip' = J(0, 3, .)
		mata: st_local("__st", strofreal(nw_random_degseq(`__dv', `nodes', `__dir', `swaps', `__trip')))
		capture mata: mata drop `__dv'
		capture mata: mata drop `__din'
		if "`__st'" == "3" {
			if `__dir' di "{err}{p 0 0 2}No directed network without loops and repeated ties has these out-degrees and in-degrees (they must have the same sum, and no node can send or receive more than `=`nodes'-1' ties).{p_end}"
			else di "{err}{p 0 0 2}No network without loops and repeated ties has these degrees (their sum must be even, and no degree can exceed `=`nodes'-1'; see the Erdos-Gallai conditions).{p_end}"
			error 198
		}
		if "`__st'" != "0" {
			di "{err}The native draw of the network failed (out of memory?)."
			error 198
		}
		mata: st_rclear()
		if "`nodenamesmata'" != "" {
			_nwsetsparse, triplets(`__trip') nodes(`nodes') name(`name') nodenames(`nodenamesmata') `undirected'
		}
		else {
			_nwsetsparse, triplets(`__trip') nodes(`nodes') name(`name') labs(`labs') `undirected'
		}
		capture mata: mata drop `__trip'
		if "`xvars'" == "" {
			nwload, xvars
		}
		else {
			nwload
		}
		mata: st_global("r(netlist)", "`name'")
		exit
	}

	// large networks without weights or a dyad census: the ties are drawn as a list (prob(): the same draws as the
	// matrix version, so the same seed gives the same network; density(): the positions of the ties are drawn
	// directly, which is a different stream than the shuffle of all n^2 cells)
	local __sparsegen 0
	if "`weights'" == "" & "`census'" == "" & `nodes' > 2000 {
		if "`prob'" != "" & "`density'" == "" {
			mata: st_local("__pv", strofreal(`prob', "%21.12g"))
			if `__pv' <= .2 {
				local __sparsegen 1
			}
		}
		else if "`density'" != "" & "`prob'" == "" & `nodes' > 5000 {
			mata: st_local("__dv", strofreal(`density', "%21.12g"))
			if `__dv' <= .2 {
				local __sparsegen 2
			}
		}
	}
	if `__sparsegen' > 0 {
		tempname __nwtrip
		if `__sparsegen' == 1 {
			mata: `__nwtrip' = nw_random_prob_triplets(`nodes', `prob', ("`undirected'" != ""), "`selfloop'" != "")
		}
		else {
			mata: `__nwtrip' = nw_random_density_triplets(`nodes', `density', ("`undirected'" != ""), "`selfloop'" != "")
		}
		mata: st_rclear()
		if "`nodenamesmata'" != "" {
			_nwsetsparse, triplets(`__nwtrip') nodes(`nodes') name(`name') nodenames(`nodenamesmata') `undirected' `selfloop'
		}
		else {
			_nwsetsparse, triplets(`__nwtrip') nodes(`nodes') name(`name') labs(`labs') `undirected' `selfloop'
		}
		capture mata: mata drop `__nwtrip'
	}
	else {
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
		// nodenamesmata(): name of a Mata string vector with the node names. Long node name lists must not travel
		// in a Stata option string (labs()): Stata inserts a blank every 5,292 characters of an option value.
		if "`nodenamesmata'" != "" {
			nwset, mat(`__nwnew') name(`name') nodenames(`nodenamesmata') `undirected' `selfloop'
		}
		else {
			nwset, mat(`__nwnew') name(`name') labs(`labs') `undirected' `selfloop'
		}
	}
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


capture program drop _nwrandom_degvec
program _nwrandom_degvec
	// the degrees of degree(), outdegree() or indegree() as a Mata column vector: a numeric variable (its first
	// `nodes' observations) or a list of numbers
	syntax , spec(string) nodes(integer) mname(string) opt(string)
	local spec = strtrim(`"`spec'"')
	capture confirm numeric variable `spec', exact
	if _rc == 0 & wordcount(`"`spec'"') == 1 {
		if _N < `nodes' {
			di "{err}{p 0 0 2}Variable {bf:`spec'} of {bf:`opt'()} has `=_N' observations; `nodes' degrees are needed.{p_end}"
			error 198
		}
		mata: `mname' = st_data((1::`nodes'), "`spec'")
		mata: st_local("__bad", strofreal(missing(`mname') > 0))
		if "`__bad'" == "1" {
			di "{err}{p 0 0 2}Variable {bf:`spec'} of {bf:`opt'()} has missing values among its first `nodes' observations.{p_end}"
			error 198
		}
	}
	else {
		capture numlist `"`spec'"', integer range(>=0)
		if _rc {
			di "{err}{p 0 0 2}{bf:`opt'()} takes a numeric variable or a list of whole numbers 0 or more.{p_end}"
			error 198
		}
		local L `r(numlist)'
		if wordcount("`L'") != `nodes' {
			di "{err}{bf:`opt'()} lists `=wordcount("`L'")' degrees for `nodes' nodes."
			error 198
		}
		mata: `mname' = strtoreal(tokens("`L'"))'
	}
end

capture mata: mata drop nw_random_degseq()
capture mata: mata drop tiesGenerator()
capture mata: mata drop correctDiagonal()
capture mata: mata drop dyadcensusGenerator()
capture mata: mata drop get_random_prob()
capture mata: mata drop get_random_density()

mata:
// A network with the degrees dv (undirected: n values; directed: n out-degrees, then n in-degrees), built and rewired
// by kernel 55 of the nwgraph plugin; the ties (both directions for an undirected network) go to trip.  Returns the
// kernel status: 0 = done, 3 = no network with these degrees, 2 = failure.
real scalar nw_random_degseq(real colvector dv, real scalar n, real scalar directed, real scalar nswap, transmorphic trip)
{
	real matrix R
	real rowvector aux
	real scalar st, m

	m = directed ? sum(dv[1::n]) : sum(dv) / 2
	if (nswap < 0) nswap = max((1, 10 * floor(m)))
	R = nwg_comb(55, rows(dv), J(0, 3, .), dv, (directed, floor(uniform(1, 1) * 2147483646) + 1, nswap, 1, n), aux, st)
	if (st != 0) return(st)
	if (rows(R) == 0) R = J(0, 3, .)
	if (directed) trip = R
	else trip = R \ (R[., 2], R[., 1], R[., 3])
	return(0)
}

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

