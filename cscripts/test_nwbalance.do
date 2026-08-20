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
	KNOWN LIMITATION, documented rather than silently worked around: a
	network with zero closed triads (e.g. a path graph, no triangles)
	causes nwbalance to error (r(2000), "no observations") instead of
	gracefully reporting zero balanced/unbalanced triads. This is a
	pre-existing gap in the command's Stata-reshape-based triad
	enumeration pipeline (not something introduced or changed in this
	session's documentation/bugfix pass) - fixing it properly means
	auditing the multi-stage reshape/merge chain for empty-result
	handling, out of scope for a documentation-and-quick-bugfix pass.
	Recorded here as a regression-aware test so this limitation is
	visible (and can be turned into a real assertion) whenever someone
	does take on that larger fix - see docs/ROADMAP.md.
*/
nwclear
nwset, mat((0,1,0\1,0,1\0,1,0)) name(pathnet) undirected labs(A,B,C)
capture nwbalance pathnet
assert _rc == 2000
di "=== NO-TRIADS CASE: known limitation (errors rather than reporting zero), documented ==="

* custom generate() names
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(customnames) undirected labs(A,B,C)
nwbalance customnames, generate(myB myBal myClo)
assert myB[1] == 1
assert myBal[1] == 1
assert myClo[1] == 1
di "=== CUSTOM generate() NAMES VERIFIED ==="
