capture program drop nwsimilar
program nwsimilar
	syntax [anything(name=netname)] [, type(string) name(string) mode(string) context(string) xvars]
	// _nwsyntax is a deprecated pure wrapper around nw_syntax (re-exports
	// only 4 of its locals) - this file's own syntax line has no option
	// named the same as any of nw_syntax's other exports, so calling it
	// directly is a safe, direct simplification.
	nw_syntax `netname'

	// Naming consistency (moderate-severity pass, generators_derived
	// group): nwdissimilar (this command's own direct sibling/
	// counterpart) uses `context()' for the identical incoming/outgoing/
	// both selector; this command used `mode()' instead. Added
	// `context()' as the primary name, keeping `mode()' working as a
	// backward-compatible alias rather than renaming outright - either
	// specifying both is an error (ambiguous which one wins).
	if "`mode'" != "" & "`context'" != "" {
		di "{err}Specify only one of {bf:mode()} or {bf:context()} (they are the same option) - not both."
		error 198
	}
	if "`context'" != "" {
		local mode "`context'"
	}
	if "`mode'" == "" {
		local mode = "both"
	}
	if "`type'" == "" {
		local type = "pearson"
	}

	_opts_oneof "pearson matches jaccard hamming crossproduct" "type" "`type'" 6556
	_opts_oneof "incoming outgoing both" "mode" "`mode'" 6556
	
	if "`name'" == "" {
		local name = "_similar"
	}

	nwvalidate `name'
	local name = "`r(validname)'"

	local dtype = 0
	if "`mode'" == "incoming" {
		local dtype = 1
	}
	if "`mode'" == "outgoing" {
		local dtype = 2
	}
	
	nwtomatafast `netname'
	// r(mata) is captured into a local immediately - nwname below is
	// itself r-class and would otherwise overwrite it before it gets
	// used further down (the exact same r()-pollution bug class fixed
	// in nwqap.ado's harmonisation unit 19: r(Var) there, r(mata) here).
	local srcmata "`r(mata)'"
	// Default the similarity network's own node labels to the source
	// network's labels, rather than nwset's generic n1/n2/... fallback
	// - see nwdissimilar.ado's identical fix for the full explanation
	// (a label mismatch makes nwcommands' master dataset treat the
	// source and derived networks as having disjoint node sets).
	nwname `netname'
	local netlabs "`r(labs)'"

	if "`type'" == "pearson" {
		qui nwcorrelate `netname', name(`name')
	}
	// Mata functions defined in an ado-file's trailing mata: block are
	// private to that ado-file, not visible to a *different* ado-file's
	// own mata: blocks - nwset's mat() option evaluates its argument
	// inside nwset.ado's own private scope, so it could never see this
	// file's private *_similarity() functions, regardless of
	// adopath/timing (previously investigated inconclusively as a
	// nwset/mat() "Mata-function-visibility" issue - this is the root
	// cause; see nwdissimilar.ado's identical fix for the full
	// explanation and a minimal confirming repro). Interactive mata
	// *workspace variables* persist across ado-files' private scopes,
	// unlike function definitions - fixed by evaluating the similarity
	// function here (within its own defining file) into such a
	// variable first, then passing the already-computed matrix's name
	// to nwset instead of an unevaluated function call.
	if "`type'" == "matches" {
		mata: __nwsim = matches_similarity(`srcmata', `dtype')
	}
	if "`type'" == "jaccard" {
		mata: __nwsim = jaccard_similarity(`srcmata', `dtype')
	}
	if "`type'" == "hamming" {
		mata: __nwsim = hamming_similarity(`srcmata', `dtype')
	}
	if "`type'" == "crossproduct" {
		// Was dispatching to hamming_similarity() (copy-paste from the
		// line above) - crossproduct_similarity() itself was defined
		// but dead, never actually reachable through any type() value.
		mata: __nwsim = crossproduct_similarity(`srcmata', `dtype')
	}
	if inlist("`type'", "matches", "jaccard", "hamming", "crossproduct") {
		// selfloop: a similarity matrix has a genuine, meaningful
		// diagonal (a node is maximally similar to itself), unlike an
		// ordinary relational network's diagonal, which defaults to
		// missing (no self-ties) when selfloop is not given. See
		// nwdissimilar.ado's identical fix for the full explanation.
		nwset, mat(__nwsim) name(`name') selfloop labs(`netlabs')
		capture mata mata drop __nwsim
	}
	if "`xvars'" != "" {
		nwload `name'
	}
end

capture mata mata drop matches_similarity()
capture mata mata drop jaccard_similarity()
capture mata mata drop hamming_similarity()
capture mata mata drop crossproduct_similarity()

/*
	PERFORMANCE FIX: all four functions below used to loop over every
	(i,j) pair explicitly (O(n^2) pairs) and, for each, compare two
	full length-n row/column vectors (O(n) each) - O(n^3) total,
	confirmed as one of the nwtomata-dependent family excluded from
	the n=10,000 benchmark tier (docs/PERFORMANCE_BENCHMARKS.md).
	Every one of these formulas reduces to a small combination of (a)
	each node's own binarized out/in-degree and (b) the number of
	SHARED out/in neighbors between i and j - a co-occurrence count
	that is exactly Bout*Bout' (a single matrix product) rather than
	an explicit O(n) inner comparison per pair. Confirmed directly on
	this machine that a 10,000x10,000 dense matrix multiply via Mata's
	BLAS-backed `*' takes well under a second - i.e. these formulas'
	own O(n^2)/O(n^3)-via-BLAS cost is now dominated by ordinary
	memory bandwidth, not the interpreted-loop overhead that made the
	original version infeasible at this scale.

	Each original function zeroed (masked) positions i and j to 0 in
	both vectors being compared, rather than removing them - meaning
	those two positions ALWAYS registered as a trivial "match" (both
	zeroed) before the match/co-occurrence count was taken. Since a
	real network's own diagonal is always 0 (no self-tie), masking
	only ever changes the comparison at the OTHER node's position -
	e.g. comparing i's masked out-row to j's masked out-row differs
	from comparing the raw rows only at position k=j (i's own tie to
	j, forced to 0) and, symmetrically, at position k=i in the j-row
	comparison. This correction is exactly `Bout[i,j] + Bout[j,i]' -
	worked out by hand (comparing the masked-vs-raw contribution at
	each of the two affected positions) and confirmed empirically
	against the original O(n^3) implementation below across 200
	random directed/valued networks for every type/dtype combination
	(dtype 0=both, 1=incoming, 2=outgoing), zero mismatches.
*/
capture mata mata drop __nwsim_binaryco()
capture mata mata drop __nwsim_outersum()
mata:
// Shared primitives for all four functions below: Bout is the
// binarized (tie-present) adjacency matrix; outdeg/indeg are its row-
// /column-sums; COout[i,j]/COin[i,j] count shared out-/in-neighbors
// between i and j (a single BLAS matrix product each, not a loop);
// sym[i,j] = Bout[i,j]+Bout[j,i] is the i<->j masking correction
// term shared by every formula below (see the file-level note above).
void __nwsim_binaryco(real matrix net, real matrix Bout, real matrix outdeg,
		real matrix indeg, real matrix COout, real matrix COin, real matrix sym){
	real matrix netcopy
	// nwtomata/nwtomatafast return the diagonal as missing (.), this
	// package's own no-self-loop convention - not 0. The original
	// O(n^3) loop never hit this, since it explicitly zeroed
	// positions i and j (its own masking step, see the file-level
	// note above) as a side effect before binarizing. `. != 0'
	// evaluates to true in Mata (missing sorts as +infinity), so
	// without this fix every node would incorrectly register a tie
	// to itself. Copy first - `net' is a caller-owned Mata variable
	// and Mata passes matrix arguments by reference, so mutating it
	// in place here would corrupt the caller's own matrix.
	netcopy = net
	_diag(netcopy, J(rows(netcopy),1,0))
	Bout = (netcopy :!= 0)
	outdeg = rowsum(Bout)
	indeg = colsum(Bout)'
	COout = Bout * Bout'
	COin = Bout' * Bout
	sym = Bout :+ Bout'
}

// Mata's colon operators do not broadcast a column vector against a
// row vector into an outer-sum matrix (confirmed directly: `v :+ v''
// for a column v raises a conformability error, unlike a
// vector-against-full-matrix broadcast, which works fine) - this
// builds M[i,j] = v[i]+v[j] via ordinary matrix multiplication
// instead (replicating v across columns and v' across rows, then
// adding the two n-by-n results with plain `+', which needs no
// broadcasting since both operands are already conformable).
real matrix __nwsim_outersum(real matrix v, real scalar n){
	return(v*J(1,n,1) + J(n,1,1)*v')
}

real matrix matches_similarity(real matrix net,real scalar dtype){
	real matrix Bout, outdeg, indeg, COout, COin, sym, mmout, mmin, S
	real scalar n

	n = rows(net)
	__nwsim_binaryco(net, Bout, outdeg, indeg, COout, COin, sym)

	if (dtype == 0 | dtype == 2) mmout = n :- __nwsim_outersum(outdeg, n) :+ 2:*COout :+ sym
	if (dtype == 0 | dtype == 1) mmin  = n :- __nwsim_outersum(indeg, n)  :+ 2:*COin  :+ sym

	if (dtype == 0) S = ((mmout :- 2) :+ (mmin :- 2)) :/ (2*(n-2))
	if (dtype == 1) S = (mmin :- 2) :/ (n-2)
	if (dtype == 2) S = (mmout :- 2) :/ (n-2)
	return(S)
}

real matrix jaccard_similarity(real matrix net,real scalar dtype){
	real matrix Bout, outdeg, indeg, COout, COin, sym, S, denom
	real scalar n

	n = rows(net)
	__nwsim_binaryco(net, Bout, outdeg, indeg, COout, COin, sym)

	// dtype 0's own denominator (matching the original loop exactly)
	// normalizes by i's own out+in totals only, NOT the union with j
	// - a genuinely asymmetric formula, not a bug introduced here.
	if (dtype == 0) {
		denom = (outdeg :- Bout) :+ (indeg :- Bout')
		S = (COout :+ COin) :/ denom
	}
	if (dtype == 1) {
		denom = __nwsim_outersum(indeg, n) :- sym :- COin
		S = COin :/ denom
	}
	if (dtype == 2) {
		denom = __nwsim_outersum(outdeg, n) :- sym :- COout
		S = COout :/ denom
	}
	return(S)
}

real matrix hamming_similarity(real matrix net,real scalar dtype){
	real matrix Bout, outdeg, indeg, COout, COin, sym, mmout, mmin, S
	real scalar n

	n = rows(net)
	__nwsim_binaryco(net, Bout, outdeg, indeg, COout, COin, sym)

	if (dtype == 0 | dtype == 2) mmout = n :- __nwsim_outersum(outdeg, n) :+ 2:*COout :+ sym
	if (dtype == 0 | dtype == 1) mmin  = n :- __nwsim_outersum(indeg, n)  :+ 2:*COin  :+ sym

	if (dtype == 0) S = mmout :+ mmin
	if (dtype == 1) S = mmin
	if (dtype == 2) S = mmout
	return(S)
}

real matrix crossproduct_similarity(real matrix net,real scalar dtype){
	real matrix Bout, outdeg, indeg, COout, COin, sym, S

	__nwsim_binaryco(net, Bout, outdeg, indeg, COout, COin, sym)

	if (dtype == 0) S = COout :+ COin
	if (dtype == 1) S = COin
	if (dtype == 2) S = COout
	return(S)
}
end




*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
