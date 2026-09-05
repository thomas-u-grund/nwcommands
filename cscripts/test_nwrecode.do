cscript

do unw_core.do

* nwrecode had zero test coverage before this session, and crashed
* immediately on every call: it called _nwsyntax_other, incompatible
* with the modern network storage architecture (same bug already
* found and fixed in nwcloseness this session), and separately, its
* own per-network loop called _nwsyntax and referenced `directed' -
* which _nwsyntax never re-exports at all (only netobj/id/netname/
* networks), a gap that survived this session's own earlier
* _nwsyntax.ado root-cause fix (that fix corrected the one broken
* netname re-export _nwsyntax does attempt; it never widened what
* _nwsyntax exports in the first place). Fixed both by switching to
* _nwsyntax directly (_nwsyntax's own other() option gives the exact
* othernetname/othernodes/etc. naming convention _nwsyntax_other used,
* a direct drop-in).
*
* Fixing those crashes exposed three more, independent bugs:
*   - "nwtoedge `onenet', forcedirected" - nwtoedge has no such
*     option; the real one that forces both (i,j) and (j,i) into the
*     edgelist is "full".
*   - "nwfromedge _fromid _toid `onenet', ..." - _fromid/_toid never
*     existed; nwtoedge's actual default output variables are
*     _ego/_alter.
*   - every code path in nwrecode ends by calling nwreplacemat, which
*     was itself completely non-functional for the same-size case
*     (wrote to a legacy Mata global the modern architecture never
*     reads) - fixed separately this session (see
*     cscripts/test_nwreplacemat.do); nwrecode never changes a
*     network's size, so it only needed that same-size fix, not
*     nwreplacemat's still-broken resize path.

nwclear
nwset, mat((0,1,2,0\1,0,3,0\2,3,0,4\0,0,4,0)) name(net1) undirected labs(A,B,C,D)
nwrecode net1(1/2=1)(3/max=2)
nwtomata net1, mat(M)
* original 1,2 -> 1; original 3,4 -> 2
mata: assert(M[1,2] == 1)
mata: assert(M[1,3] == 1)
mata: assert(M[2,3] == 2)
mata: assert(M[3,4] == 2)

* replace-in-place is the default (no generate()/prefix()); the
* network keeps its own name and remains undirected
nwname net1
assert `"`r(directed)'"' == `"false"'

* generate(): recode into a *new*, separate network, leaving the
* original untouched
nwclear
nwset, mat((0,1,2,0\1,0,3,0\2,3,0,4\0,0,4,0)) name(net2) undirected labs(A,B,C,D)
nwrecode net2(1/2=10)(3/max=20), generate(net2recoded)
nwtomata net2, mat(Morig)
mata: assert(Morig[1,2] == 1)
nwtomata net2recoded, mat(Mnew)
mata: assert(Mnew[1,2] == 10)
mata: assert(Mnew[2,3] == 20)

* --- alpha-audit regression: generate()/prefix() used to silently
* corrupt an unrelated, pre-existing network of the same target name
* (nwduplicate's own silent auto-rename on collision was never
* accounted for - nwreplacemat kept operating on the literal requested
* name, which still resolved to the pre-existing network). Confirmed
* fixed: the unrelated network is untouched, and the actual recoded
* result lands under nwduplicate's own auto-incremented name.
nwclear
nwset, mat((0,1,2,0\1,0,3,0\2,3,0,4\0,0,4,0)) name(reccoll1) undirected labs(A,B,C,D)
nwset, mat((0,1\1,0)) name(reccoll2)
nwrecode reccoll1(1/2=1)(3/max=2), generate(reccoll2)
nwtomata reccoll2, mat(Munrelated)
mata: assert(Munrelated[2,1] == 1)
mata: assert(rows(Munrelated) == 2)
nwtomata reccoll2_1, mat(Mrecoded)
mata: assert(Mrecoded[2,1] == 1)
mata: assert(Mrecoded[3,1] == 1)
mata: assert(Mrecoded[4,3] == 2)
di "=== generate() collision REGRESSION VERIFIED ==="

* moderate-severity pass, manipulation_transform group: prefix()'s own
* collision case, specifically (as opposed to generate()'s, already
* covered above) - same underlying nwvalidate-before-nwduplicate
* pattern, different code path.
nwclear
nwset, mat((0,1\1,0)) name(net3)
nwset, mat((0,1\1,0)) name(recoded_net3)
nwrecode net3(1=5), prefix(recoded_)
nwtomata recoded_net3, mat(Munrel2)
mata: assert(Munrel2[1,2] == 1)
nwtomata recoded_net3_1, mat(Mrec2)
mata: assert(Mrec2[1,2] == 5)
di "=== prefix() collision REGRESSION VERIFIED ==="

* --- failure paths: a network name that isn't loaded is rejected via
* _nwsyntax's own "Network X not found" check (error 482); calling
* with no argument at all is rejected by Stata's own syntax parser
* (`arg' is a required positional argument).
nwclear
nwset, mat((0,1\1,0)) name(recnet)
capture noisily nwrecode nonexistent(1=1)
assert _rc == 482

capture noisily nwrecode
assert _rc != 0
