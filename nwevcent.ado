capture program drop nwevcent
program nwevcent
	version 9
	syntax [anything(name=netname)] , [nosym weighted GENerate(string) replace]
	nw_syntax `netname'
	nw_datasync `netname'

	if "`generate'" == "" {
		local generate "_evcent"
	}
	// Per Stata's own [P] syntax convention for a "no"-prefixed toggle:
	// declaring `nosym' in the option list makes Stata define a local
	// named after the STEM - `sym', not `nosym' - set to the literal
	// string "nosym" when the caller passes the option, empty
	// otherwise. `nosym' itself is never populated at all. (Confirmed
	// directly against a minimal, isolated test program before touching
	// this file - this is genuine, general `syntax' behavior, not
	// specific to this command.) This is therefore already correct as
	// originally written; left exactly as-is (`sym' empty -> symmetrize
	// by default, `sym' == "nosym" -> skip symmetrizing).
	local nosym = ("`sym'" != "")

	local getvalued = 0
	if "`weighted'" != "" & "`valued'" == "true" {
		local getvalued = 1
	}

	capture confirm variable `generate'
	if _rc == 0 & "`replace'" == "" {
		di "{err}Variable {it:`generate'} already exists. Use option {bf:replace}.{txt}"
		// BUGFIX: was a bare `exit' (no return code) - the message
		// printed but the command returned rc=0 to its caller, so any
		// script checking _rc after a failed nwevcent call incorrectly
		// believed it succeeded, with the target variable silently kept
		// at its stale old values. Error-code coherence: standardized
		// onto 99 (this package's own standard "Stata variable already
		// exists" code, nw_errorcodes.sthlp), matching nwdegree/
		// nwbetween/nw2degree's own convention for the identical
		// situation in this same group.
		err 99
	}
	else {
		capture generate `generate' = .
	}

	mata: st_store((1::`nodes'),"`generate'", nw_evcentrality(`netobj',`nosym',`getvalued'))

	di "{hline 40}"
	di "{txt}  Network name: {res}`netname'"
	di "{hline 40}"
	di "{txt}    Eigenvector centrality"
	if `nosym' == 0 {
		di "{txt}.   (calculated on symmetrized network)"
	}
	if `getvalued' == 1 {
		di "{txt}.   (calculated on tie values, not dichotomized)"
	}
	mata: st_rclear()
	sum `generate'

end

capture mata: mata drop nw_evcentrality()
capture mata: mata drop nw_evcentrality_matvec()
mata:
/*
	Eigenvector centrality via sparse-native power iteration - the
	dominant (largest-magnitude) eigenvalue/eigenvector of the network's
	own (optionally max-symmetrized, optionally dichotomized) adjacency
	matrix, computed via repeated sparse matrix-vector products
	(x <- A*x, normalized) rather than a full dense eigendecomposition.
	Previously built the ENTIRE dense N x N matrix via get_matrix_mod()
	purely to hand it to Mata's own symeigensystem() (an O(N^3) full
	eigendecomposition, needing O(N^2) memory) just to extract the
	single dominant eigenpair - gated by nw_max_dense_nodes (20,000
	nodes) and slow well before that. Power iteration needs only O(nnz)
	work per iteration and no dense matrix at all, scaling with the rest
	of this project's own sparse-migrated commands
	(docs/SPARSE_BACKEND.md) rather than being a deliberate, permanent
	dense holdout the way it used to be documented as (see that file's
	own "Status" section, now updated).

	Symmetrization (nosym==0, the default) uses the SAME "max" rule
	get_matrix_mod() itself documents: dyad (i,j)'s effective weight is
	max(edge_weight(i,j), edge_weight(j,i)), each treated as 0 if that
	direction has no tie at all - computed here via the union of node
	i's own out- and in-neighbors rather than by materializing a
	symmetrized copy of the network. For an already-undirected network
	this union is trivially just neighbors(i) (out- and in-neighbors are
	identical by construction, per neighbors_in()'s own fallback), so no
	extra cost is paid there.

	Convergence: plain power iteration (x <- A*x, normalized, repeat)
	does NOT converge for every graph - any graph whose adjacency matrix
	has its second-largest eigenvalue EQUAL IN MAGNITUDE to the dominant
	one but opposite in sign (the "spectral bipartite symmetry" that any
	tree or bipartite graph has - confirmed directly: a plain 3-node
	path graph A-B-C, adjacency eigenvalues +sqrt(2)/0/-sqrt(2), makes
	plain power iteration oscillate FOREVER between two different
	vectors rather than settle on one) never settles into a single fixed
	vector at all, only an oscillation between two states neither of
	which is a simple sign-flip of the other - caught directly via this
	exact test case before shipping, not merely a theoretical concern.

	Squaring the matrix (y <- A*(A*x), the fix igraph/NetworkX use for
	plain oscillation) was tried FIRST here and rejected: A^2's own
	eigenvalues are the SQUARES of A's, so +lambda and -lambda - exactly
	the pair causing the oscillation above - land on the SAME squared
	eigenvalue and become a single DEGENERATE 2-dimensional eigenspace of
	A^2, not two distinct ones. Power iteration on A^2 then converges to
	WHATEVER mixture of the original +lambda/-lambda eigenvectors the
	starting vector happens to project onto - for the symmetric all-ones
	starting vector this exact path graph uses, that mixture came out
	uniform (.577,.577,.577), not the true +sqrt(2) eigenvector
	(.5,.707,.5) - confirmed by hand: (1,1,1) is itself an exact
	eigenvector of A^2 here (A^2*(1,1,1) = (2,2,2)), so squaring doesn't
	merely slow convergence toward the right answer, it converges
	EXACTLY to a wrong one, stably. Caught by hand-deriving the expected
	answer for this test case rather than trusting a plausible-looking
	converged number.

	The fix used instead is a spectral shift: iterate on B = A + cI
	rather than on A or A^2. B shares A's exact eigenVECTORS (only
	eigenVALUES shift, by +c each), so recovering B's dominant
	eigenvector is exactly recovering A's. Choosing c >= the largest
	possible |eigenvalue| of A (a standard Gershgorin bound: no
	eigenvalue of a nonnegative-weight adjacency matrix can exceed its
	largest row sum) makes every shifted eigenvalue strictly positive,
	so the ORIGINAL dominant eigenvalue - whatever its own sign - is now
	unambiguously the single largest value (not just largest magnitude),
	breaking the +lambda/-lambda tie without merging their eigenspaces
	the way squaring does. Computed here as one extra matvec call on the
	all-ones vector (the row-sum bound, reused directly - the weighted
	generalization of "largest degree", correct for both the
	dichotomized and {opt weighted} cases) plus a +1 safety margin, so
	the shift itself is still just O(nnz), not a separate O(n) degree
	pass. y <- A*x + c*x is one matrix-vector product per iteration,
	same cost as the naive (broken) approach, with none of A^2's
	eigenspace-merging failure mode.

	A fixed iteration cap (1,000) and a tight absolute tolerance (1e-10)
	on the largest per-node change is checked against BOTH y and -y (an
	overall sign is still arbitrary, depending on the starting vector and
	rounding - the same ambiguity the prior dense implementation's own
	final "EC[1,index] < 0 ? flip" step already had to handle, resolved
	the identical way below). An all-isolates (or entirely empty)
	network makes every iteration's own matrix-vector product exactly
	zero - detected directly (norm==0) and reported as missing for every
	node, matching the prior dense implementation's own "maxEV==0"
	contract exactly.
*/
real colvector nw_evcentrality_matvec(pointer (class nw_def scalar) scalar thisnw, real colvector v, real scalar nosym, real scalar getvalued)
{
	real scalar n, i, k, wij, wji, w, j
	real colvector out
	real matrix nbout, nbin, allnb

	n = thisnw->get_nodes()
	out = J(n, 1, 0)
	for (i = 1; i <= n; i++) {
		if (nosym) {
			nbout = thisnw->neighbors(i)
			for (k = 1; k <= rows(nbout); k++) {
				j = nbout[k,1]
				if (j == i) continue
				w = getvalued ? thisnw->edge_weight(i,j) : 1
				if (w <= 0) continue
				out[i] = out[i] + w * v[j]
			}
		}
		else {
			nbout = thisnw->neighbors(i)
			nbin  = thisnw->neighbors_in(i)
			allnb = uniqrows((nbout \ nbin))
			for (k = 1; k <= rows(allnb); k++) {
				j = allnb[k,1]
				if (j == i) continue
				wij = thisnw->has_edge(i,j) ? thisnw->edge_weight(i,j) : 0
				wji = thisnw->has_edge(j,i) ? thisnw->edge_weight(j,i) : 0
				w = max((wij, wji))
				if (w <= 0) continue
				out[i] = out[i] + (getvalued ? w : 1) * v[j]
			}
		}
	}
	return(out)
}

real matrix function nw_evcentrality(pointer (class nw_def scalar) scalar thisnw, real scalar nosym, real scalar getvalued)
{
	real scalar n, iter, maxiter, tol, norm, shift
	real colvector x, y

	n = thisnw->get_nodes()
	x = J(n, 1, 1) :/ sqrt(n)

	// An all-isolates (or entirely empty, or all-non-positive-weight)
	// network makes this matvec exactly 0 for ANY input, not just this
	// starting vector - no amount of iteration can recover a meaningful
	// direction from that, so report missing immediately, matching the
	// prior dense implementation's own exact "maxEV==0 -> missing"
	// contract for this case. (A directed-acyclic "as-is" network under
	// nosym is a different, genuinely-nilpotent-but-not-all-zero case -
	// not specially detected here, same as this command's own
	// documented "only defined for connected networks" caveat already
	// covers any other not-strongly-connected input.)
	if (max(abs(nw_evcentrality_matvec(thisnw, x, nosym, getvalued))) == 0) {
		return(J(n, 1, .))
	}

	// Gershgorin-style shift: no eigenvalue of a nonnegative-weight
	// adjacency matrix can exceed its largest row sum in magnitude, so
	// this (plus a +1 margin) is always large enough to make every
	// shifted eigenvalue strictly positive - see the header comment
	// above for why that's needed instead of squaring.
	shift = max(nw_evcentrality_matvec(thisnw, J(n, 1, 1), nosym, getvalued)) + 1

	maxiter = 1000
	tol = 1e-10

	for (iter = 1; iter <= maxiter; iter++) {
		y = nw_evcentrality_matvec(thisnw, x, nosym, getvalued) :+ shift :* x
		norm = sqrt(sum(y:^2))
		y = y :/ norm
		if (max(abs(y - x)) < tol | max(abs(y + x)) < tol) {
			x = y
			break
		}
		x = y
	}

	if (x[1] < 0) x = x :* -1
	return(x)
}
end

