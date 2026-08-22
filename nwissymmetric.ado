capture program drop nwissymmetric
program nwissymmetric
	syntax [anything(name=netname)]
	// _nwsyntax is a deprecated pure wrapper around nw_syntax (re-exports
	// only 4 of its locals) - this file's own syntax line has no option
	// named the same as any of nw_syntax's other exports, so calling it
	// directly is a safe, direct simplification.
	nw_syntax `netname'
	nwtomata `netname', mat(onenet)
	mata: st_numscalar("r(issymmetric)", issymmetric(onenet))
	mata: mata drop onenet
end
*! v1.5.0 __ 17 Sep 2015 __ 13:09:53
*! v1.5.1 __ 17 Sep 2015 __ 14:54:23
