cscript

do unw_core.do

* nwreplacemat had zero test coverage before this session. Its
* same-size code path (the common case: replace a network's matrix
* with another of the same dimensions, e.g. as used internally by
* nwrecode) was fully non-functional: it wrote the new matrix to
* nw_mata`id' and the directed/undirected flag to $nwdirected_`id',
* both legacy pre-2016 globals that the modern netobj/NWdef Mata
* class architecture never reads from - the call appeared to
* succeed (no error) but silently did nothing to the network at all.
* Fixed by using the modern netobj->set_edge()/set_directed() methods
* instead (the same methods other commands fixed this session, e.g.
* nwkatz, already use for in-place matrix updates). Also fixed the
* deprecated _nwsyntax call (unexported `nodes', same bug class as
* nwqap/nwcloseness/nworder this session) and a literal "erorr 6082"
* typo in the invalid-dimensions guard.
*
* The size-CHANGING code path (used by nwdropnodes/nwkeepnodes to
* shrink a network) is NOT fixed here - it is entangled with further
* legacy globals ($nwsize_`id', $nw_`id', $nwlabs_`id') and is a
* separate, larger, not-yet-started item (see docs/CERTIFICATION.md's
* Pending table). This test covers only the same-size path.

nwclear
nwset, mat((0,1,1\1,0,0\1,0,0)) name(net1) undirected labs(A,B,C)
nwreplacemat net1, newmat((0,2,3\2,0,4\3,4,0))
nwtomata net1, mat(M)
mata: assert(M[1,2] == 2)
mata: assert(M[1,3] == 3)
mata: assert(M[2,3] == 4)

* the network must still be recognized as undirected (symmetric
* newmat) after the replace, and as directed after an asymmetric one
nwname net1
assert `"`r(directed)'"' == `"false"'

nwreplacemat net1, newmat((0,1,0\0,0,1\1,0,0))
nwname net1
assert `"`r(directed)'"' == `"true"'
nwtomata net1, mat(M2)
mata: assert(M2[1,2] == 1)
mata: assert(M2[2,1] == 0)
mata: assert(M2[2,3] == 1)
mata: assert(M2[3,1] == 1)

* invalid (non-square) matrix must still error cleanly, not crash on
* the "erorr" typo that used to make this guard itself invalid Stata
capture nwreplacemat net1, newmat((1,2,3\4,5,6))
assert _rc == 6082
