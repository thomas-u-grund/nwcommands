
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
		mata: `c' = `netobj'->calculate_constraint_triplets()
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
	mata: `c' = `netobj'->calculate_constraint_dyadic()
	if "`name'" != "" local options `"name(`name') `options'"'
	if "`replace'" != "" local options `"replace `options'"'
	nwset, mat(`c') `options'
	capture mata: mata drop `c'
end

capture mata mata drop constraint()
mata: 
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
