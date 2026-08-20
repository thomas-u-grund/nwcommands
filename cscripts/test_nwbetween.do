cscript

do unw_core.do

/*
	nwbetween had zero test coverage before this session, and could not
	previously execute at all: calculate_betweenness() called dequeue(),
	which was never defined anywhere in the codebase, and nwbetween.ado had
	a stray extra closing brace causing a syntax error. Both were fixed
	this session, along with two further, separately-discovered issues,
	fixed at the user's explicit direction (not silently): betweenness was
	exactly double the standard/textbook value for undirected networks
	(classic Brandes'-algorithm double-counting, now halved in
	calculate_betweenness()), and the `nosym` option was checked via a
	local (`sym') that syntax never populated, so it had no effect (now
	fixed to check `nosym' as documented). Fixing `nosym' exposed a third,
	previously-unreachable bug: the temporary-network cleanup after
	symmetrizing referenced a local clobbered by an unprefixed nw_syntax
	call; also fixed (see the last test case below).
*/

// path graph A-B-C-D-E: standard unnormalized betweenness (i-1)*(n-i)
// A=0, B=3, C=4, D=3, E=0
nwclear
nwset, mat((0,1,0,0,0\1,0,1,0,0\0,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) name(pathnet) undirected labs(A,B,C,D,E)
nwbetween pathnet, generate(bc)
assert bc[1] == 0
assert bc[2] == 3
assert bc[3] == 4
assert bc[4] == 3
assert bc[5] == 0

// star graph: center touches every shortest path between the 4 leaves;
// standard betweenness for the center of a k-leaf star is C(k,2)
nwclear
nwset, mat((0,1,1,1,1\1,0,0,0,0\1,0,0,0,0\1,0,0,0,0\1,0,0,0,0)) name(starnet) undirected labs(Center,L1,L2,L3,L4)
nwbetween starnet, generate(bc2)
assert bc2[1] == 6
assert bc2[2] == 0
assert bc2[3] == 0
assert bc2[4] == 0
assert bc2[5] == 0

// nosym: on a directed path A->B->C->D->E, nosym should compute
// betweenness on the network as-given (no symmetrization first, no
// halving - the network stays directed throughout, so `_between'
// reflects directed shortest paths, not the undirected-equivalent values
// above), and must leave the original network (not a temp *_symmetrized
// copy) as current afterward.
nwclear
nwset, mat((0,1,0,0,0\0,0,1,0,0\0,0,0,1,0\0,0,0,0,1\0,0,0,0,0)) name(dirpath) directed labs(A,B,C,D,E)
nwbetween dirpath, generate(bc3) nosym
nwset, detail
assert `"`r(nets)'"' == `" dirpath"'
assert bc3[1] == 0
assert bc3[2] == 3
assert bc3[3] == 4
assert bc3[4] == 3
assert bc3[5] == 0

// same directed path, without nosym: nwbetween symmetrizes into a
// temporary *_symmetrized network, computes betweenness there, then must
// drop the temporary network and restore the original as current - this
// cleanup step used to reference a clobbered local (nw_syntax with no
// arguments overwrites the caller's `netname') and crashed the moment
// nosym was fixed to actually take the symmetrizing branch; both are
// fixed together here.
nwbetween dirpath, generate(bc4)
nwset, detail
assert `"`r(nets)'"' == `" dirpath"'
assert bc4[1] == 0
assert bc4[2] == 3
assert bc4[3] == 4
assert bc4[4] == 3
assert bc4[5] == 0
