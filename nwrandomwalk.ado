
capture program drop nwrandomwalk
program nwrandomwalk, rclass
	version 12
	syntax [anything(name=netname)], TARGET(string) [GENerate(string) replace silent BINary ONEmode SYMmetrize]

	_nwsyntax `netname'
	_nw2guard `netname', cmd(nwrandomwalk) allowone `onemode'
	local __nw1m = r(copied)
	local __origname "`netname'"
	local netname "`r(net)'"
	_nwsyntax `netname'
	// a valued network: the walk steps along a tie with probability proportional to its value; binary ignores the values
	local __wtd = ("`valued'" == "true" & "`binary'" == "")
	// a directed network is walked as it is (the walk follows the direction of the ties, as igraph::random_walk does);
	// sym walks on the symmetrized network (the larger of the two directions of a tie)
	local __symdo = ("`symmetrize'" != "" & "`directed'" == "true")
	local __dirdo = ("`directed'" == "true" & !`__symdo')

	qui nwnode `netname', ego(`target')
	local tid `r(nodeid)'
	if `tid' == -1 {
		di "{err}Node {bf:`target'} does not exist in network {bf:`netname'}"
		exit 485
	}

	if "`generate'" == "" {
		di "{err}option {bf:generate()} required."
		exit 198
	}
	capture confirm variable `generate', exact
	if _rc == 0 & "`replace'" == "" {
		di "{err}Variable {bf:`generate'} already exists; specify {bf:replace}"
		exit 110
	}

	// BUGFIX: the active dataset was never synced to the target network
	// before st_store() below - see nwpagerank.ado's identical fix and
	// comment for the full account; confirmed to crash the same way
	// here via the same adversarial-input probe.
	_nwsetobs `netname'
	tempvar __nw_ht_included
	_nwdatasync `netname', generate(`__nw_ht_included')

	tempname __nw_ht
	if `__dirdo' {
		_nwdenseguard, command(nwrandomwalk) nodes(`nodes') copies(3) alternative(A random walk on a directed network needs the dense transition matrix. Use sym for the symmetrized network, which is solved on the stored ties, or look at a part of the network (nwsubset).)
		capture noisily mata: `__nw_ht' = nw_hitting_directed(`netobj', `tid', `__wtd')
	}
	else {
		capture noisily mata: `__nw_ht' = `netobj'->calculate_randomwalk_hitting(`tid', `__wtd')
	}
	if _rc != 0 {
		exit _rc
	}
	capture confirm new variable `generate'
	if _rc capture drop `generate'
	gen double `generate' = .
	mata: st_store((1::`nodes'), "`generate'", `__nw_ht')
	mata: mata drop `__nw_ht'

	return local target "`target'"
	return local directed = cond(`__dirdo', "true", cond(`__symdo', "symmetrized", "false"))
	return local generate "`generate'"

	if `__nw1m' local netname "`__origname'"
	if "`silent'" == "" {
		di "{hline 40}"
		di "{txt}  Network: {res}`netname'"
		di "{txt}  Target: {res}`target'"
		if `__wtd' di "{txt}{p 2 2 2}(valued network: steps in proportion to the tie values; {bf:binary} ignores the values){p_end}"
		di "{hline 40}"
		if `__dirdo' {
			di "{txt}{p 2 2 2}(directed network: the walk follows the direction of the ties; the hitting time is missing for a node from which the target is not reached with certainty){p_end}"
		}
		else if `__symdo' {
			di "{txt}{p 2 2 2}(directed network symmetrized: the larger of the two directions of a tie){p_end}"
		}
		else {
			di "{txt}{p 2 2 2}(undirected network){p_end}"
		}
		summarize `generate'
	}
	if `__nw1m' capture nwdrop __nw1m
end

capture mata: mata drop nw_hitting_directed()
capture mata: mata drop nw_backreach()
mata:
// 1 for every node from which a node of the set S can be reached along the arcs of A, 0 otherwise
real colvector nw_backreach(real matrix A, real colvector S)
{
	real scalar n, head, tail, u
	real colvector seen, queue, pre

	n = rows(A)
	seen = J(n, 1, 0)
	queue = J(n, 1, 0)
	tail = 0
	for (head = 1; head <= rows(S); head++) {
		tail = tail + 1
		queue[tail] = S[head]
		seen[S[head]] = 1
	}
	head = 1
	while (head <= tail) {
		u = queue[head]
		head = head + 1
		pre = selectindex((A[., u] :> 0) :& (seen :== 0))
		if (rows(pre) > 0) {
			seen[pre] = J(rows(pre), 1, 1)
			queue[|tail + 1 \ tail + rows(pre)|] = pre
			tail = tail + rows(pre)
		}
	}
	return(seen)
}

// mean hitting time to node t of a random walk that follows the direction of the ties (step probability w_ij / s_i,
// s_i the out-strength); missing for a node from which the target is not reached with certainty (a node that can
// reach a dead end or a part of the network without a way to the target)
real colvector nw_hitting_directed(pointer(class nw_def scalar) scalar p, real scalar t, real scalar wtd)
{
	real matrix A, P
	real scalar n
	real colvector deg, reach, bad, h, keep, ix
	real matrix M

	n = p->get_nodes()
	A = *p->get_matrix()
	_editmissing(A, 0)
	_diag(A, 0)
	if (wtd) A = A :* (A :> 0)
	else A = (A :!= 0)
	if (min(rowsum(A) :+ colsum(A)') == 0) {
		errprintf("{p 0 2 2}nwrandomwalk: every node must have at least one tie (an isolate has no well-defined hitting time) - remove isolates first.{p_end}\n")
		exit(error(6556))
	}
	A[t, .] = J(1, n, 0)
	// nodes that can reach the target (backward search), then the nodes from which a node that cannot reach the
	// target can be reached (backward search from those): they are bad
	reach = nw_backreach(A, t)
	bad = nw_backreach(A, selectindex(reach :== 0))
	h = J(n, 1, .)
	h[t] = 0
	keep = selectindex((bad :== 0) :& ((1::n) :!= t))
	if (rows(keep) == 0) return(h)
	deg = rowsum(A)
	P = A[keep, keep] :/ deg[keep]
	M = I(rows(keep)) - P
	ix = lusolve(M, J(rows(keep), 1, 1))
	h[keep] = ix
	return(h)
}
end
