
capture program drop nwconstraint
program nwconstraint
	syntax [anything(name=netname)] [, *]
	// _nwsyntax is a deprecated pure wrapper around nw_syntax (re-exports
	// only 4 of its locals) - this file's own syntax line has no option
	// named the same as any of nw_syntax's other exports, so calling it
	// directly is a safe, direct simplification.
	nw_syntax `netname'

	// PERFORMANCE FIX: used to materialize the full dense n-by-n
	// matrix via nwtomata, then compute constraint() via two dense
	// O(n^3) matrix products - confirmed as one of the
	// nwtomata-dependent family excluded from the n=10,000 benchmark
	// tier (docs/PERFORMANCE_BENCHMARKS.md). calculate_constraint_dyadic()
	// (unw_core.do) computes the identical dense n-by-n result directly
	// from the sparse edge list, O(sum of degree^2) instead of O(n^3) -
	// the output itself is still a dense matrix (this command's own
	// documented return shape), only the compute cost is fixed.
	tempname c
	mata: `c' = `netobj'->calculate_constraint_dyadic()
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
