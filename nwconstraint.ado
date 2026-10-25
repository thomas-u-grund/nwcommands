
capture program drop nwconstraint
program nwconstraint
	syntax [anything(name=netname)] [, name(string) replace *]
	// _nwsyntax is a deprecated pure wrapper around _nwsyntax (re-exports
	// only 4 of its locals) - this file's own syntax line has no option
	// named the same as any of _nwsyntax's other exports, so calling it
	// directly is a safe, direct simplification.
	_nwsyntax `netname'

	// A network held as stored ties (large networks) gets the constraint network from the list of its non-zero cells
	// (direct ties and two-step paths, about sum(degree^2) of them), without the n x n matrix.
	mata: st_local("__sparse", strofreal(`nodes' > 2000 & !`netobj'->is_dense_built() & `netobj'->is_2mode_boolean() != 1))
	if `__sparse' {
		if `"`options'"' != "" {
			di "{err}Option(s) {bf:`options'} are not available for a network of more than 2,000 nodes; only {bf:name()} and {bf:replace}."
			error 198
		}
		if "`name'" == "" local name "network"
		nwvalidate `name'
		if "`r(exists)'" == "true" {
			if "`replace'" == "" {
				di "{err}Network `name' already exists. Specify option {bf:replace} to overwrite it."
				error 483
			}
			nwdrop `name'
			_nwsyntax `netname'
		}
		tempname c nm
		// native kernel 30 (plugin generation 7 or later); a result that is not n x 3 leaves the Mata method
		mata: `c' = nw_fastconstraint(`netobj', 0)
		mata: st_local("__fast", strofreal(cols(`c') == 3))
		if !`__fast' {
			mata: `c' = `netobj'->calculate_constraint_triplets()
		}
		mata: `nm' = `netobj'->get_nodenames()
		_nwsetsparse, triplets(`c') nodes(`nodes') name(`name') nodenames(`nm')
		capture mata: mata drop `c' `nm'
		exit
	}

	// PERFORMANCE FIX: used to materialize the full dense n-by-n
	// matrix via nwtomata, then compute constraint() via two dense
	// O(n^3) matrix products - confirmed as one of the
	// nwtomata-dependent family excluded from the n=10,000 benchmark
	// tier (docs/PERFORMANCE_BENCHMARKS.md). calculate_constraint_dyadic()
	// (unw_core.do) computes the identical dense n-by-n result directly
	// from the sparse edge list, O(sum of degree^2) instead of O(n^3).
	tempname c
	// small networks: the same native kernel, its cells put into the n x n matrix (only when the matrix is not large)
	local __fast 0
	if `nodes' <= 4000 {
		mata: `c' = nw_fastconstraint(`netobj', 1)
		mata: st_local("__fast", strofreal(rows(`c') == `nodes' & cols(`c') == `nodes'))
	}
	if !`__fast' {
		mata: `c' = `netobj'->calculate_constraint_dyadic()
	}
	if "`name'" != "" local options `"name(`name') `options'"'
	if "`replace'" != "" local options `"replace `options'"'
	nwset, mat(`c') `options'
	capture mata: mata drop `c'
end

capture mata mata drop nw_fastconstraint()
capture mata mata drop constraint()
mata: 
// Native dyadic constraint (kernel 30 of the nwgraph plugin). dense = 0: the (ego, alter, value) list of
// calculate_constraint_triplets(); dense = 1: the n x n matrix of calculate_constraint_dyadic() (the two sum the
// terms in a different order, a difference of 1e-16). A 0 x 0 matrix when the kernel is not available or the network
// is a two-mode network. The global NW_NOFASTKERNELS forces the Mata methods.
real matrix nw_fastconstraint(pointer (class nw_def scalar) scalar p, real scalar dense)
{
	real rowvector aux
	real scalar st, n
	real matrix r, c
	real colvector v

	if (st_global("NW_NOFASTKERNELS") != "") return(J(0, 0, .))
	if (nwg_comb_version() < 7) return(J(0, 0, .))
	if (p->is_2mode_boolean() == 1) return(J(0, 0, .))
	n = p->get_nodes()
	r = nwg_comb(30, n, p->edgelist(), J(0, 1, .), J(1, 0, .), aux, st)
	if (st != 0 | cols(r) != 3) return(J(0, 0, .))
	if (!dense) return(r)
	v = J(n * n, 1, 0)
	if (rows(r) > 0) v[(r[., 1] :- 1) :* n :+ r[., 2]] = r[., 3]
	c = colshape(v', n)
	return(c)
}

real matrix constraint(real matrix net)
{
	p = net :/ rowsum(net)
	_editmissing(p,0)
	p2 = p * p
	_diag(p2, 0)
	return((p + p2):*(p + p2))
}
end

*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
