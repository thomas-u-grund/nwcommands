capture program drop nwissymmetric
program nwissymmetric
	syntax [anything(name=netname)]
	// _nwsyntax is a deprecated pure wrapper around nw_syntax (re-exports
	// only 4 of its locals) - this file's own syntax line has no option
	// named the same as any of nw_syntax's other exports, so calling it
	// directly is a safe, direct simplification.
	nw_syntax `netname'
	// PERFORMANCE FIX: used to materialize the full dense n-by-n matrix
	// via nwtomata just to run issymmetric() on it - O(n^2) regardless
	// of how sparse the actual network is, confirmed as one of the
	// nwtomata-dependent family excluded from the n=10,000 benchmark
	// tier (docs/PERFORMANCE_BENCHMARKS.md). check_issymmetric() checks
	// the same condition directly from the sparse edge list, O(m) in
	// the network's own tie count instead of O(n^2).
	mata: st_numscalar("r(issymmetric)", `netobj'->check_issymmetric())
end
*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
