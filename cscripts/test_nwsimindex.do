cscript

do unw_core.do

* --- Network: A-B, A-C, A-D, B-C (undirected, unweighted)
* N(A)={B,C,D}, N(B)={A,C}, N(C)={A,B}, N(D)={A}
* Hand-computed:
*   common(B,C)=1, jaccard(B,C)=1/3, dice(B,C)=0.5, cosine(B,C)=0.5,
*   aa(B,C)=1/ln(3) (shared neighbor A has degree 3)
*   common(A,D)=0, jaccard(A,D)=0
*   dice(A,B)=2*1/(3+2)=0.4, cosine(A,B)=1/sqrt(3*2)=.4082482905
*   dice(B,D)=2*1/(2+1)=.6666666667, cosine(B,D)=1/sqrt(2*1)=.7071067812
*   aa(A,B)=1/ln(2)=1.442695041 (shared neighbor C has degree 2)
nwclear
nwset, mat((0,1,1,1\1,0,1,0\1,1,0,0\1,0,0,0)) name(simnet) undirected labs(A,B,C,D)

nwsimindex simnet, measure(jaccard)
assert `"`r(measure)'"' == `"jaccard"'
assert `"`r(netname)'"' == `"simindex"'
assert r(nodes) == 4
nwtomata simindex, mat(J1)
mata: assert(J1[2,3] == 1/3)
mata: assert(J1[1,4] == 0)
mata: assert(J1[1,1] == .)

nwsimindex simnet, measure(common) name(mycommon)
nwtomata mycommon, mat(J2)
mata: assert(J2[2,3] == 1)
mata: assert(J2[1,4] == 0)

nwsimindex simnet, measure(dice) name(mydice)
nwtomata mydice, mat(J3)
mata: assert(J3[2,3] == .5)
mata: assert(reldif(J3[1,2], 0.4) < 1E-8)
mata: assert(reldif(J3[2,4], 2/3) < 1E-8)

nwsimindex simnet, measure(cosine) name(mycos)
nwtomata mycos, mat(J4)
mata: assert(J4[2,3] == .5)
mata: assert(reldif(J4[1,2], 1/sqrt(6)) < 1E-8)
mata: assert(reldif(J4[2,4], 1/sqrt(2)) < 1E-8)

nwsimindex simnet, measure(adamicadar) name(myaa)
nwtomata myaa, mat(J5)
mata: assert(reldif(J5[2,3], 1/ln(3)) < 1E-8)
mata: assert(reldif(J5[1,2], 1/ln(2)) < 1E-8)
mata: assert(J5[1,4] == 0)


* --- edge cases: isolates
* Two isolates: jaccard/dice/cosine all 0/0 -> missing
nwclear
nwset, mat((0,0,0\0,0,0\0,0,0)) name(isonet) undirected labs(A,B,C)
nwsimindex isonet, measure(jaccard) name(isosim)
nwtomata isosim, mat(J6)
mata: assert(J6[1,2] == .)

* Isolate vs non-isolate: jaccard=0 (well-defined), cosine=missing (0/0)
nwclear
nwset, mat((0,1,0\1,0,0\0,0,0)) name(mixnet) undirected labs(A,B,C)
nwsimindex mixnet, measure(jaccard) name(mixj)
nwsimindex mixnet, measure(cosine) name(mixc)
nwtomata mixj, mat(J7)
nwtomata mixc, mat(J8)
mata: assert(J7[1,3] == 0)
mata: assert(J8[1,3] == .)


* --- directed network: union-of-both-directions neighbor convention
* A->B, A->C, B->C: undirected sense N(A)={B,C}, N(B)={A,C}, N(C)={A,B}
* -> this is a triangle in the undirected sense, all pairs share exactly
* 1 common neighbor
nwclear
nwset, mat((0,1,1\0,0,1\0,0,0)) name(dirnet) directed labs(A,B,C)
nwsimindex dirnet, measure(common) name(dirsim)
nwtomata dirsim, mat(J9)
mata: assert(J9[1,2] == 1)
mata: assert(J9[1,3] == 1)
mata: assert(J9[2,3] == 1)


* --- name collision / replace semantics
nwclear
nwset, mat((0,1\1,0)) name(tinynet)
nwsimindex tinynet, name(collidenet)
nwsimindex tinynet, name(collidenet)
assert `"`r(netname)'"' == `"collidenet_1"'
nwsimindex tinynet, name(collidenet) replace
assert `"`r(netname)'"' == `"collidenet"'


* --- invalid measure errors cleanly
* (kept before the end of the file, not after: nw_helpwriter's doc
* certification checks _rc following `do cscripts/test_X.do`, but a
* successful `assert` does not itself reset _rc back to 0 - if this were
* the LAST thing the file did, _rc would still read the deliberately-
* triggered error code and the file would be silently left uncertified.
* Not a bug in this test; see docs/ROADMAP.md for the underlying
* nw_helpwriter fragility this surfaced.)
capture nwsimindex tinynet, measure(bogus)
assert _rc != 0

nwsimindex tinynet, measure(jaccard)
assert r(nodes) == 2
