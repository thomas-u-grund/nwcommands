capture program drop nwpermute	
program nwpermute
	version 9.0
	syntax [anything(name=netname)], [ xvars replace nwreplace generate(string) SWAP SWAPS(integer -1)]
	if "`replace'" == "" & "`generate'" == "" {
		// Error-code coherence pass: was `999' (this package's own
		// convention for "loading would discard unsaved data" - an
		// unrelated situation this option-requirement check had
		// nothing to do with, reused here only by coincidence).
		// A missing required option is exactly what Stata's own 198
		// already means package-wide.
		di "{err}Either option {bf:replace} or {bf:generate} required."
		error 198
	}
	_nwsyntax `netname', max(1)
	// a two-mode network is permuted within its modes (the labels of the mode-1 nodes among themselves, the mode-2
	// labels among themselves); swap instead exchanges the partners of two ties at random (Maslov-Sneppen) and keeps
	// both degree sequences (R: bipartite::swap.web, tnet::rg_reshuffling_tm)
	if "`swaps'" != "-1" & "`swap'" == "" local swap swap
	if "`swap'" != "" & "`is2mode'" != "true" {
		di "{err}Option {bf:swap} needs a two-mode network."
		error 198
	}
	if "`swap'" != "" {
		if `swaps' == -1 {
			mata: st_local("swaps", strofreal(10 * sum(`netobj'->edgelist()[., 3] :!= 0) / 2))
		}
		if `swaps' < 1 {
			di "{err}Option {bf:swaps()} must be at least 1."
			error 198
		}
	}
	if "`generate'" == "" & "`replace'" != "" {
		if "`swap'" != "" {
			// native tie swapping (plugin generation 10 or later) on the stored ties; an older plugin or a failure leaves the Mata routine
			mata: st_local("__done", strofreal(nw2_swap(`netobj', `swaps')))
			if "`__done'" != "1" mata: `netobj'->permute_swap(`swaps')
		}
		else {
			mata: `netobj'->permute()
		}
	}
	if "`generate'" != "" {
		capture _nwsyntax `generate', other(_chk)
		if _rc == 0 & "`nwreplace'" == "" & "`replace'" == "" {
			di "{err}Network {bf:`generate'} already exists; use {bf:nwreplace} or specify another name in {bf:generate()}"
			error 99
		}
		capture nwdrop `generate'
		nwduplicate `netname', name(`generate')
		_nwsyntax `generate'
		if "`swap'" != "" {
			// native tie swapping (plugin generation 10 or later) on the stored ties; an older plugin or a failure leaves the Mata routine
			mata: st_local("__done", strofreal(nw2_swap(`netobj', `swaps')))
			if "`__done'" != "1" mata: `netobj'->permute_swap(`swaps')
		}
		else {
			mata: `netobj'->permute()
		}
	}
	if "`xvars'" != "" {
		nwload `netname'
	}
end

capture mata: mata drop nw2_swap()
mata:
// Native tie swapping (kernel 46 of the nwgraph plugin): the cross-mode ties are swapped on the list of ties, no
// n x n matrix is built.  Returns 1 when the network has been changed (or has nothing to swap), 0 when the kernel is
// not available.  The generator is seeded from uniform(), so set seed makes the result reproducible.
real scalar nw2_swap(pointer(class nw_def scalar) scalar p, real scalar nswap)
{
	real matrix el, T, R, keep
	real colvector md, cross
	real rowvector aux
	real scalar st, n, wasvalued

	if (st_global("NW_NOFASTKERNELS") != "") return(0)
	if (nwg_comb_version() < 10) return(0)
	n = p->get_nodes()
	md = strtoreal(p->get_modes())'
	el = p->edgelist()
	if (rows(el) == 0) return(1)
	cross = ((md[el[., 1]] :== 1) :& (md[el[., 2]] :== 2)) :| ((md[el[., 1]] :== 2) :& (md[el[., 2]] :== 1))
	cross = cross :& (el[., 3] :< .) :& (el[., 3] :!= 0)
	T = select(el, cross :& (md[el[., 1]] :== 1))
	if (rows(T) < 2) return(1)
	R = nwg_comb(46, n, T, J(0, 1, .), (nswap, floor(uniform(1, 1) * 2147483646) + 1), aux, st)
	if (st != 0 | rows(R) != rows(T) | cols(R) != 3) return(0)
	keep = select(el, !cross)
	el = keep \ R \ (R[., 2], R[., 1], R[., 3])
	wasvalued = p->isvalued
	p->set_edge_from_triplets(el[., 1], el[., 2], el[., 3], p->isdirect)
	p->isvalued = wasvalued
	return(1)
}
end
