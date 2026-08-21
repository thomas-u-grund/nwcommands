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
* nw_syntax directly (nw_syntax's own other() option gives the exact
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
