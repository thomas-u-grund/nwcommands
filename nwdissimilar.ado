capture program drop nwdissimilar
program nwdissimilar
	syntax [anything(name=netname)] [, type(string) labs(passthru) vars(passthru) name(string) context(string) xvars force]
	// _nwsyntax is a deprecated pure wrapper around _nwsyntax, kept here
	// only to resolve/default `netname' (_nwsyntax's own c_local export
	// re-populates it even when empty, meaning "use the current
	// network") - calling _nwsyntax directly here would ALSO export its
	// own `labs' (the network's own comma-separated node-label string),
	// silently clobbering this file's own `labs(passthru)' option value
	// (genuinely consumed below, at the nwset call) before it's ever
	// used. other() avoids that collision entirely.
	_nwsyntax `netname', other(other)
	local netname "`othernetname'"
	_nwdenseguard, command(nwdissimilar) nodes(`othernodes') copies(8) alternative(The result is a network with a tie for every pair of nodes. Compute it for a part of the network (nwsubset, nwego, nwkeepnodes) or take the ties with nwtoedge, compress into other software.) `force'
	
	if "`context'" == "" {
		local context = "both"
	}
	if "`type'" == "" {
		local type = "euclidean"
	}

	_opts_oneof "euclidean manhatten nonmatches jaccard hamming" "type" "`type'" 6556
	_opts_oneof "incoming outgoing both" "context" "`context'" 6556
	
	if "`name'" == "" {
		local name = "_dissimilar"
	}

	nwvalidate `name'
	local name = "`r(validname)'"
	
	local dtype = 0
	if "`context'" == "incoming" {
		local dtype = 1
	}
	if "`context'" == "outgoing" {
		local dtype = 2
	}
	
	nwtomatafast `netname'
	// r(mata) is captured into a local immediately - nwname below is
	// itself r-class and would otherwise overwrite it before it gets
	// used further down (the exact same r()-pollution bug class fixed
	// in nwqap.ado's harmonisation unit 19: r(Var) there, r(mata) here).
	local srcmata "`r(mata)'"
	// Default the dissimilarity network's own node labels to the
	// source network's labels (rather than nwset's generic n1/n2/...
	// fallback) when the caller didn't request specific labels - so a
	// derived dissimilarity network shares the same node identity as
	// its source by default. Without this, a caller like nwhierarchy
	// (which never passes labs()) ends up with a dissimilarity network
	// whose node labels don't match the source network's own - and
	// since nwcommands' master dataset keys rows by node label across
	// all currently-tracked networks, mismatched labels make the two
	// networks' node sets look like a disjoint union (e.g. 8 rows for
	// two differently-labeled 4-node networks instead of a shared 4),
	// which is exactly what broke nwhierarchy's default path.
	// The source network's node names go to nwset through a Mata variable, never through a Stata option
	// string: Stata's option parser inserts a blank every 5,292 characters of a long option value, which
	// corrupted the names of networks with more than about 900 nodes (see GOTCHA.md).
	tempname __nwdis_names
	local __nwdis_usenames 0
	if "`labs'" == "" {
		mata: `__nwdis_names' = `othernetobj'->get_nodenames()
		local __nwdis_usenames 1
	}
	// Mata functions defined in an ado-file's trailing mata: block are
	// private to that ado-file - visible only to mata code running
	// from *within this same file* (e.g. this program body calling
	// them directly). They are NOT visible to a *different* ado-file's
	// own mata: blocks, even when that file is invoked synchronously
	// from here (confirmed with a minimal two-ado-file repro: an
	// identical function, called from its own defining ado-file,
	// works; called from a second ado-file passed only the unevaluated
	// expression text, it fails "not found", r(3499)). nwset's own
	// mat() option evaluates whatever expression it is given inside
	// nwset.ado's *own* private mata scope - so passing an unevaluated
	// call to one of this file's private functions straight through to
	// nwset, as this used to do, could never work, regardless of
	// adopath/timing (previously investigated inconclusively - this is
	// the root cause). Interactive mata *workspace variables*, unlike
	// function definitions, persist across ado-files' private scopes -
	// fixed by evaluating the dissimilarity function here (within its
	// own defining file, where it is visible) into such a variable
	// first, then passing that already-computed matrix's *name* to
	// nwset instead of an unevaluated function call.
	// two-mode: a node is compared with the other nodes of its OWN mode, over the nodes of the other mode (see
	// nwsimilar); pairs of nodes from different modes are not compared (missing)
	if "`otheris2mode'" == "true" {
		local __t2 = cond("`type'" == "hamming", "dhamming", cond("`type'" == "jaccard", "djaccard", "`type'"))
		mata: __nwdissim = nw_twomode_profile(`srcmata', strtoreal(`othernetobj'->get_modes())', "`__t2'")
		if `__nwdis_usenames' {
			nwset, mat(__nwdissim) name(`name') selfloop undirected nodenames(`__nwdis_names') `vars'
			capture mata mata drop `__nwdis_names'
		}
		else {
			nwset, mat(__nwdissim) name(`name') selfloop undirected `labs' `vars'
		}
		capture mata mata drop __nwdissim
		if "`xvars'" != "" {
			nwload `name'
		}
		exit
	}
	// native kernel (plugin generation 12 or later): the same cells from the sparse tie lists; an older plugin leaves the Mata functions
	local __code = cond("`type'" == "euclidean", 6, cond("`type'" == "manhatten", 7, cond("`type'" == "nonmatches", 8, cond("`type'" == "jaccard", 9, 10))))
	mata: __nwdissim = nw_dissimnative(`othernetobj', `__code', `dtype')
	mata: st_local("__fast", strofreal(rows(__nwdissim) > 0))
	if !`__fast' & "`type'" == "euclidean" {
		mata: __nwdissim = euclidean_dissimilarity(`srcmata', `dtype')
	}
	if !`__fast' & "`type'" == "manhatten" {
		mata: __nwdissim = manhatten_dissimilarity(`srcmata', `dtype')
	}
	if !`__fast' & "`type'" == "nonmatches" {
		mata: __nwdissim = matches_dissimilarity(`srcmata', `dtype')
	}
	if !`__fast' & "`type'" == "jaccard" {
		mata: __nwdissim = jaccard_dissimilarity(`srcmata', `dtype')
	}
	if !`__fast' & "`type'" == "hamming" {
		mata: __nwdissim = hamming_dissimilarity(`srcmata', `dtype')
	}
	// selfloop: a (dis)similarity matrix has a genuine, meaningful
	// diagonal (0 - a node is never dissimilar from itself), unlike an
	// ordinary relational network's diagonal, which defaults to missing
	// (no self-ties) when selfloop is not given. Without this, the
	// diagonal came back missing on every retrieval (nwtomatafast,
	// nwhierarchy's clustermat call, etc.), even though the dissimilarity
	// functions above correctly compute 0 for the diagonal themselves -
	// confirmed via a direct nwset/nwtomatafast round-trip probe.
	if `__nwdis_usenames' {
		nwset, mat(__nwdissim) name(`name') selfloop nodenames(`__nwdis_names') `vars'
		capture mata mata drop `__nwdis_names'
	}
	else {
		nwset, mat(__nwdissim) name(`name') selfloop `labs' `vars'
	}
	capture mata mata drop __nwdissim
	if "`xvars'" != "" {
		nwload `name'
	}
end

capture mata mata drop euclidean_dissimilarity()
capture mata mata drop manhatten_dissimilarity()
capture mata mata drop matches_dissimilarity()
capture mata mata drop jaccard_dissimilarity()
capture mata mata drop hamming_dissimilarity()

/*
	PERFORMANCE FIX (euclidean/matches/jaccard/hamming - see
	nwsimilar.ado's identical fix for the full derivation and
	verification methodology this mirrors): each was an O(n^3)
	explicit-loop comparison of two full length-n vectors per (i,j)
	pair - confirmed as one of the nwtomata-dependent family excluded
	from the n=10,000 benchmark tier. `manhatten' (sum of ABSOLUTE
	differences over RAW, non-binarized tie values) has no equivalent
	O(1)-per-pair closed form the way squared-difference/match-count
	do (Euclidean reduces to dot products; Hamming/matches/jaccard
	reduce to a shared-neighbor count) - left as the original O(n^3)
	loop, a small, disclosed scope limit (one of five `type()' values,
	not the default).
*/
capture mata mata drop __nwdissim_outersum()
capture mata mata drop __nwdissim_binaryco()
mata:
real matrix __nwdissim_outersum(real matrix v, real scalar n){
	return(v*J(1,n,1) + J(n,1,1)*v')
}

// Shared binarized-tie primitives (identical construction to
// nwsimilar.ado's own __nwsim_binaryco - kept as a separate,
// file-private copy since Mata functions defined in one .ado file's
// own trailing mata: block are not visible to a different .ado
// file's mata code, confirmed elsewhere in this file's own comments).
void __nwdissim_binaryco(real matrix net, real matrix Bout, real matrix outdeg,
		real matrix indeg, real matrix COout, real matrix COin, real matrix sym){
	real matrix netcopy
	// nwtomata/nwtomatafast return the diagonal as missing (this
	// package's own no-self-loop convention), not 0 - `. != 0'
	// evaluates to true in Mata, so without zeroing the diagonal
	// first, every node would incorrectly register a tie to itself.
	netcopy = net
	_diag(netcopy, J(rows(netcopy),1,0))
	Bout = (netcopy :!= 0)
	outdeg = rowsum(Bout)
	indeg = colsum(Bout)'
	COout = Bout * Bout'
	COin = Bout' * Bout
	sym = Bout :+ Bout'
}

real matrix euclidean_dissimilarity(real matrix net, real scalar dtype){
	real matrix netcopy, sqout, sqin, DPout, DPin, sqcorr, msumout, msumin, S
	real scalar n

	n = rows(net)
	netcopy = net
	_diag(netcopy, J(n,1,0))
	sqout = rowsum(netcopy:^2)
	sqin = colsum(netcopy:^2)'
	DPout = netcopy * netcopy'
	DPin = netcopy' * netcopy
	sqcorr = (netcopy:^2) :+ (netcopy:^2)'

	if (dtype == 0 | dtype == 2) msumout = __nwdissim_outersum(sqout, n) :- 2:*DPout :- sqcorr
	if (dtype == 0 | dtype == 1) msumin  = __nwdissim_outersum(sqin, n)  :- 2:*DPin  :- sqcorr

	if (dtype == 0) S = sqrt(msumout :+ msumin)
	if (dtype == 1) S = sqrt(msumin)
	if (dtype == 2) S = sqrt(msumout)
	return(S)
}

real matrix manhatten_dissimilarity(real matrix net ,real scalar dtype){
	real matrix S, i_outvec, i_invec, j_outvec, j_invec
	real scalar i, j

	S = J(rows(net), cols(net), 0)
	for(i = 1; i<= rows(S); i++){
		for(j = 1; j<= cols(S); j++){
			i_outvec = net[i,.]
			i_invec = net[.,i]	
			j_outvec = net[j,.]
			j_invec = net[.,j]
			i_outvec[i] = 0
			i_outvec[j] = 0
			i_invec[i] = 0
			i_invec[j] = 0
			j_outvec[i] = 0
			j_outvec[j] = 0
			j_invec[i] = 0
			j_invec[j] = 0	
			if (dtype == 0 ) {
				S[i,j] = (sum(abs(i_outvec :- j_outvec))+ sum(abs(i_invec :- j_invec)))
			}
			if (dtype == 1 ) {
				S[i,j] = (sum(abs(i_invec :- j_invec)))
			}
			if (dtype == 2 ) {
				S[i,j] = (sum(abs(i_outvec :- j_outvec)))
			}
		}
	}
	return(S)
}

real matrix matches_dissimilarity(real matrix net,real scalar dtype){
	real matrix Bout, outdeg, indeg, COout, COin, sym, mmout, mmin, S
	real scalar n

	n = rows(net)
	__nwdissim_binaryco(net, Bout, outdeg, indeg, COout, COin, sym)

	if (dtype == 0 | dtype == 2) mmout = n :- __nwdissim_outersum(outdeg, n) :+ 2:*COout :+ sym
	if (dtype == 0 | dtype == 1) mmin  = n :- __nwdissim_outersum(indeg, n)  :+ 2:*COin  :+ sym

	if (dtype == 0) S = 1 :- (((mmout :- 2) :+ (mmin :- 2)) :/ (2*(n-2)))
	if (dtype == 1) S = 1 :- ((mmin :- 2) :/ (n-2))
	if (dtype == 2) S = 1 :- ((mmout :- 2) :/ (n-2))
	return(S)
}

real matrix jaccard_dissimilarity(real matrix net,real scalar dtype){
	real matrix Bout, outdeg, indeg, COout, COin, sym, S, denom
	real scalar n

	n = rows(net)
	__nwdissim_binaryco(net, Bout, outdeg, indeg, COout, COin, sym)

	// dtype 0's own denominator (matching the original loop exactly)
	// normalizes by i's own out+in totals only, NOT the union with j
	// - a genuinely asymmetric formula, not a bug introduced here
	// (see nwsimilar.ado's jaccard_similarity, the identical case).
	if (dtype == 0) {
		// union of the out- and in-neighbours of i and j, positions i and j left out
		denom = __nwdissim_outersum(outdeg, n) :+ __nwdissim_outersum(indeg, n) :- 2:*sym :- COout :- COin
		S = 1 :- ((COout :+ COin) :/ denom)
	}
	if (dtype == 1) {
		denom = __nwdissim_outersum(indeg, n) :- sym :- COin
		S = 1 :- (COin :/ denom)
	}
	if (dtype == 2) {
		denom = __nwdissim_outersum(outdeg, n) :- sym :- COout
		S = 1 :- (COout :/ denom)
	}
	return(S)
}

real matrix hamming_dissimilarity(real matrix net,real scalar dtype){
	real matrix Bout, outdeg, indeg, COout, COin, sym, mmout, mmin, S
	real scalar n

	n = rows(net)
	__nwdissim_binaryco(net, Bout, outdeg, indeg, COout, COin, sym)

	if (dtype == 0 | dtype == 2) mmout = n :- __nwdissim_outersum(outdeg, n) :+ 2:*COout :+ sym
	if (dtype == 0 | dtype == 1) mmin  = n :- __nwdissim_outersum(indeg, n)  :+ 2:*COin  :+ sym

	if (dtype == 0) S = (n :- mmout) :+ (n :- mmin)
	if (dtype == 1) S = n :- mmin
	if (dtype == 2) S = n :- mmout
	return(S)
}
end




capture mata: mata drop nw_dissimnative()
mata:
// Native node-by-node similarities (kernel 51 of the nwgraph plugin, plugin generation 12 or later): the base matrix of the
// pairs without a tie and without a shared neighbour from per-node vectors, the other cells from the sparse tie lists.  A 0 x 0
// matrix when the kernel is not available (older plugin, no plugin, a network with missing values, set NW_NOFASTKERNELS): the
// caller then keeps the Mata code.
real matrix nw_dissimnative(pointer(class nw_def scalar) scalar p, real scalar type, real scalar dtype)
{
	real matrix el, S, r, info
	real colvector a, u, ii, jj, vv, iso
	real rowvector aux
	real scalar n, st, start, cnt, blk, k

	if (st_global("NW_NOFASTKERNELS") != "") return(J(0, 0, .))
	if (nwg_comb_version() < 12) return(J(0, 0, .))
	n = p->get_nodes()
	if (n < 3) return(J(0, 0, .))
	// a tie of missing value is a tie in the Mata code but is not stored as one: only a network without such cells goes to the kernel
	if (p->is_dense_built()) {
		if (missing(*p->get_matrix()) > sum(diagonal(*p->get_matrix()) :>= .)) return(J(0, 0, .))
	}
	el = p->edgelist()
	if (rows(el) > 0) {
		if (any(el[., 3] :>= .)) return(J(0, 0, .))
		el = select(el, (el[., 1] :!= el[., 2]) :& (el[., 3] :!= 0))
	}
	r = nwg_comb(51, n, el, J(0, 1, .), (type, dtype, 0, 0, 2), aux, st)
	if (st != 0 | rows(r) != n | cols(r) != 4) return(J(0, 0, .))
	// (the global NW_SIMMODE = dense or sparse forces one of the two ways, for the tests)
	if (st_global("NW_SIMMODE") == "dense" | (st_global("NW_SIMMODE") != "sparse" & aux[1] > 0.3 * n * n)) {
		// dense graph: the cells are returned as blocks of columns
		S = J(n, n, .)
		blk = max((1, min((1000, floor(4e6 / n)))))
		for (start = 1; start <= n; start = start + blk) {
			cnt = min((blk, n - start + 1))
			r = nwg_comb(51, n, el, J(0, 1, .), (type, dtype, start, cnt, 0), aux, st)
			if (st != 0 | rows(r) != n | cols(r) != cnt) return(J(0, 0, .))
			S[., start::(start + cnt - 1)] = r
		}
		return(S)
	}
	a = r[., 1]
	u = r[., 2]
	if (type == 1) S = -(u * u')
	else if (type == 3 | type == 5) S = J(n, n, 0)
	else if (type == 9) S = J(n, n, 1)
	else {
		S = (a, J(n, 1, 1)) * (J(n, 1, 1), a)'
		if (type == 6) S = sqrt(S)
	}
	if (type == 3 | type == 9) {
		iso = selectindex(r[., 3] :!= 0)
		if (rows(iso) > 0) S[iso, iso] = J(rows(iso), rows(iso), .)
	}
	start = 1
	while (start <= n) {
		r = nwg_comb(51, n, el, J(0, 1, .), (type, dtype, start, 2000000, 1), aux, st)
		if (st != 0 | cols(r) != 3 | aux[1] <= start) return(J(0, 0, .))
		if (rows(r) > 0) {
			ii = r[., 1]
			jj = r[., 2]
			vv = r[., 3]
			info = panelsetup(jj, 1)
			for (k = 1; k <= rows(info); k++) S[ii[|info[k, 1] \ info[k, 2]|], jj[info[k, 1]]] = vv[|info[k, 1] \ info[k, 2]|]
		}
		start = aux[1]
	}
	return(S)
}
end

*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
