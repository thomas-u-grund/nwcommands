cscript

do unw_core.do

/*
	nwbalance had zero documentation and zero test coverage before this
	session, despite being a real, correct implementation of Cartwright
	and Harary's (1956) strong structural balance criterion. A genuine
	bug was found and fixed along the way: the command wrote an unwanted
	"test.dta" file directly into the current working directory on every
	call (a debug leftover, `save test, replace`, never reloaded or used
	again afterward) - removed.

	Test network: K4 {A,B,C,D} with signed ties A-B=+1, A-C=+1, A-D=-1,
	B-C=+1, B-D=-1, C-D=+1. By hand: triad ABC (0 negatives) balanced;
	ABD (2 negatives) balanced; ACD (1 negative) unbalanced; BCD
	(1 negative) unbalanced. 4 closed triads, 2 balanced, 2 unbalanced.
*/

nwclear
nwset, mat((0,1,1,-1\1,0,1,-1\1,1,0,1\-1,-1,1,0)) name(signednet) undirected labs(A,B,C,D)
nwbalance signednet

assert r(closed_triad) == 4
assert r(balanced_triad) == 2
assert r(unbalanced_triad) == 2
assert reldif(r(balance), 0.5) < 1e-6

* per-node breakdown: A is in {ABC,ABD,ACD} = 3 closed, 2 balanced (ABC,ABD)
assert _clotriad[1] == 3
assert _baltriad[1] == 2
assert reldif(_balance[1], 2/3) < 1e-6

* C is in {ABC,ACD,BCD} = 3 closed, 1 balanced (ABC only)
assert _clotriad[3] == 3
assert _baltriad[3] == 1
assert reldif(_balance[3], 1/3) < 1e-6

di "=== SIGNED K4 NETWORK: closed/balanced/unbalanced triad counts and per-node ratios VERIFIED ==="

* all-positive network: every closed triad must be balanced (0 negatives, even)
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(allpos) undirected labs(A,B,C)
nwbalance allpos
assert r(closed_triad) == 1
assert r(balanced_triad) == 1
assert r(unbalanced_triad) == 0
assert r(balance) == 1
di "=== ALL-POSITIVE TRIAD: fully balanced, VERIFIED ==="

* single negative tie: the one closed triad must be unbalanced (1 negative, odd)
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(onenega) undirected labs(A,B,C)
nwreplace onenega[1,3] = -1
nwreplace onenega[3,1] = -1
nwbalance onenega
assert r(closed_triad) == 1
assert r(balanced_triad) == 0
assert r(unbalanced_triad) == 1
assert r(balance) == 0
di "=== SINGLE-NEGATIVE-TIE TRIAD: fully unbalanced, VERIFIED ==="

/*
	Previously a real bug, now fixed: a network with zero closed
	triads (e.g. a path graph, no triangles) caused nwbalance to error
	(r(2000), "no observations") because the command's Stata-reshape-
	based triad enumeration pipeline fed a completely empty dataset
	into Stata's own collapse command, which errors on zero
	observations regardless of what it's collapsing. Fixed with an
	explicit empty-result guard: every node genuinely has 0 closed
	triads in this case (not an undefined count), built directly from
	the network's own node list rather than collapsed from the (empty)
	triad-level data. The per-node balance ratio (0/0) is correctly
	left missing, not silently reported as 0 or 1.
*/
nwclear
nwset, mat((0,1,0\1,0,1\0,1,0)) name(pathnet) undirected labs(A,B,C)
nwbalance pathnet
assert r(closed_triad) == 0
assert r(balanced_triad) == 0
assert r(unbalanced_triad) == 0
assert r(balance) == .
assert _clotriad[1] == 0
assert _baltriad[1] == 0
assert _balance[1] == .
di "=== NO-TRIADS CASE: correctly reports zero (not an error), per-node ratio left missing, VERIFIED ==="

* custom generate() names
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(customnames) undirected labs(A,B,C)
nwbalance customnames, generate(myB myBal myClo)
assert myB[1] == 1
assert myBal[1] == 1
assert myClo[1] == 1
di "=== CUSTOM generate() NAMES VERIFIED ==="


* --- alpha-audit regression: generate()'s 2nd/3rd word positions were
* swapped relative to the documented namelist order (ratio, balanced
* count, closed count) - a user-supplied 3-name generate() list put the
* closed-triad count into the "balanced" variable and vice versa. The
* symmetric triangle case above (balanced==closed==1) can't catch this;
* need a network where the two counts genuinely differ.
nwclear
nwset, mat((0,1,1,-1\1,0,1,-1\1,1,0,1\-1,-1,1,0)) name(signednet) undirected labs(A,B,C,D)
nwbalance signednet, generate(myB2 myBal2 myClo2)
assert r(closed_triad) == 4
assert r(balanced_triad) == 2
assert myClo2[1] != myBal2[1]
qui sum myBal2
assert r(sum) == 2 * 3
qui sum myClo2
assert r(sum) == 4 * 3
di "=== generate() WORD-POSITION REGRESSION VERIFIED ==="


* --- alpha-audit regression: directed triad enumeration was broken -
* silently missed obviously-closed triads in some structures (e.g. a
* pure directed cycle), and produced non-integer counts in others (e.g.
* a complete tournament), with no error either way. A pair of nodes now
* counts as tied when EITHER direction has a tie, matching this
* command's own documented convention.
nwclear
nwset, mat((0,1,0\0,0,1\1,0,0)) name(dircycle) directed labs(A,B,C)
nwbalance dircycle
assert r(closed_triad) == 1
assert r(balanced_triad) == 1

nwclear
nwset, mat((0,1,1,1\0,0,1,1\0,0,0,1\0,0,0,0)) name(dirtourn) directed labs(A,B,C,D)
nwbalance dirtourn
assert r(closed_triad) == 4
assert r(balanced_triad) == 4
di "=== DIRECTED TRIAD ENUMERATION REGRESSION VERIFIED ==="


* --- alpha-audit regression: a network with zero ties at all (single
* isolated node, or a fully edgeless multi-node network) used to crash
* with a raw internal Stata error ("n not found -- data already wide",
* r(111)) instead of the graceful all-zero result the command already
* provided for the related but distinct "has ties, but no closed
* triads" case (the path-graph case above).
nwclear
nwset, mat((0)) name(singlenode) undirected labs(A)
nwbalance singlenode
assert _rc == 0
assert r(closed_triad) == 0
assert r(balanced_triad) == 0

nwclear
nwset, mat((0,0\0,0)) name(emptynet) undirected labs(A,B)
nwbalance emptynet
assert _rc == 0
assert r(closed_triad) == 0
assert r(balanced_triad) == 0
di "=== ZERO-TIE NETWORK REGRESSION VERIFIED ==="

* --- failure path: a name that isn't a loaded network is rejected via
* nw_syntax's own "Network X not found" check (error 482).
capture noisily nwbalance nonexistent
assert _rc == 482
