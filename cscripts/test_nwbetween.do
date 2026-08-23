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

* --- netlist (multi-network) support: harmonisation-phase fix. This
* command's own doc has always described this behavior ("In case,
* betweenness centrality is calculated for z networks at the same
* time... the command generates the variables varname_z, one for
* each network"), but the code never actually implemented it - fixed
* here to do what it always claimed to do (same fix already made to
* nwdegree). Uses the same two path graphs as above (A-B-C-D-E,
* known betweenness 0/3/4/3/0) under two different network names, so
* each half can be checked against the same hand-verified values.
nwclear
nwset, mat((0,1,0,0,0\1,0,1,0,0\0,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) name(pnet1) undirected labs(A,B,C,D,E)
nwset, mat((0,1,0,0,0\1,0,1,0,0\0,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) name(pnet2) undirected labs(A,B,C,D,E)

nwbetween pnet1 pnet2, generate(mbc) silent
* multi-network default output naming: basevar_<netname>
confirm variable mbc_pnet1
confirm variable mbc_pnet2
assert mbc_pnet1[1] == 0
assert mbc_pnet1[2] == 3
assert mbc_pnet1[3] == 4
assert mbc_pnet1[4] == 3
assert mbc_pnet1[5] == 0
assert mbc_pnet2[1] == 0
assert mbc_pnet2[2] == 3
assert mbc_pnet2[3] == 4
assert mbc_pnet2[4] == 3
assert mbc_pnet2[5] == 0

* single-network call remains completely unaffected: default names
* have no suffix
nwclear
nwset, mat((0,1,0,0,0\1,0,1,0,0\0,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) name(pnet1) undirected labs(A,B,C,D,E)
nwbetween pnet1, silent
assert _between[2] == 3

* replace guard: previously dead code ("capture drop `generate'*"
* unconditionally deleted any matching variable before the "already
* exists" check ran, and there was no actual replace option in
* syntax) - the guard now genuinely blocks an accidental second call
* and genuinely permits a deliberate one via replace.
nwclear
nwset, mat((0,1,0,0,0\1,0,1,0,0\0,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) name(pnet1) undirected labs(A,B,C,D,E)
nwset, mat((0,1,0,0,0\1,0,1,0,0\0,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) name(pnet2) undirected labs(A,B,C,D,E)
nwbetween pnet1 pnet2, generate(mbc2) silent
capture nwbetween pnet1 pnet2, generate(mbc2) silent
assert _rc != 0
nwbetween pnet1 pnet2, generate(mbc2) silent replace
assert _rc == 0

* --- weighted betweenness: genuine Dijkstra-based variant (previously
* a real gap - the command always dichotomized, silently ignoring tie
* strength), on Opsahl, Agneessens and Skvoretz's (2010) own weighted-
* distance definition (see nwbetween.ado's own References section):
* edge cost is (1/weight)^alpha, so a STRONGER tie is a SHORTER
* effective distance, not a longer one. A-B=1, A-C=4, B-C=2, C-D=1
* (undirected): at alpha=1, cost(A,B) direct = 1/1 = 1, but cost(A,B)
* via C = 1/4 + 1/2 = 0.75 - CHEAPER, so the true shortest A-B path
* runs through C; likewise cost(A,D) via C = 1/4 + 1/1 = 1.25, cheaper
* than any path through B, and cost(B,D) via C = 1/2 + 1/1 = 1.5,
* cheaper than via A. C therefore sits on all three of these shortest
* paths (A-B, A-D, B-D) and nothing else does. Hand-verified: A=0,
* B=0, C=3, D=0 (worked out by hand, confirmed against
* calculate_betweenness_weighted() directly before being written here
* as a permanent regression value - this exact test previously
* asserted A=0,B=2,C=2,D=0, computed under a genuine, since-fixed bug
* where edge cost was weight^alpha with NO negation, the mathematical
* inverse of Opsahl's own definition, silently favoring a network's
* direct ties over cheaper indirect ones through a stronger
* intermediary). Also confirmed alpha(0) reduces the weighted
* algorithm to the exact same result as the unweighted one (see below)
* - a strong internal-consistency check on the Dijkstra generalization
* of the existing, already-verified BFS algorithm; this check is
* insensitive to the sign-of-alpha bug above, since w^0 == w^(-0) == 1
* regardless, which is exactly why it did not itself catch the bug.
nwclear
nwset, mat((0,1,4,0\1,0,2,0\4,2,0,1\0,0,1,0)) name(wnet) undirected labs(A,B,C,D)
nwbetween wnet, weighted alpha(1) silent
assert _between[1] == 0
assert _between[2] == 0
assert _between[3] == 3
assert _between[4] == 0

nwclear
nwset, mat((0,1,4,0\1,0,2,0\4,2,0,1\0,0,1,0)) name(wnet) undirected labs(A,B,C,D)
nwbetween wnet, weighted alpha(0) generate(_wa0) silent
nwbetween wnet, generate(_wu) silent
assert _wa0[1] == _wu[1]
assert _wa0[2] == _wu[2]
assert _wa0[3] == _wu[3]
assert _wa0[4] == _wu[4]
