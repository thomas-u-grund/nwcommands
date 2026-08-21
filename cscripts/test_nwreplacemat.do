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
* shrink a network) was fixed in a later harmonisation unit (see
* docs/CERTIFICATION.md): its default (non-netonly) recreate-via-
* nwdrop+nwrandom+recursive-nwreplacemat approach turned out to
* already produce the right *network structure* once the same-size
* path above was fixed (since it bottoms out there recursively) -
* but a second, independent bug meant its own labs() option never
* actually worked at all: nw_syntax itself exports a local called
* `labs' (the *current* network's own labels, via its own bare
* c_local labs "..." with no other() prefix), which silently clobbered
* nwreplacemat's own labs() option value immediately after nw_syntax
* ran at the top of the file, before this file ever used it - found
* by tracing `labs' immediately after that call and finding it held
* the *original* (pre-resize) network's labels rather than whatever
* the caller had actually passed. Fixed by capturing the caller's
* labs() value into a differently-named local before calling
* nw_syntax. This is the same "nw_syntax's own c_local exports can
* silently shadow a caller's identically-named option local" bug
* class already found once this session for `nodes' (nwdropnodes/
* nwkeepnodes's own fix, see those files' test coverage) - `labs' is
* a second instance of it, not previously recognized as the same
* underlying pattern.

nwclear
nwset, mat((0,1,0\1,0,1\0,1,0)) name(sizenet) undirected labs(A,B,C)
mata: newmat4 = (0,1,1,0\1,0,1,0\1,1,0,1\0,0,1,0)
mata: st_matrix("newmat4", newmat4)
nwreplacemat sizenet, newmat(newmat4) labs(A,B,C,D) vars(A B C D)
assert _rc == 0
nwname sizenet
assert r(nodes) == 4
assert `"`r(labs)'"' == `"A,B,C,D"'
nwtomata sizenet, mat(M3)
mata: assert(M3[1,4] == 0)
mata: assert(M3[3,4] == 1)

* labs() with a genuinely different label set (not just adding one) -
* the specific case that was silently broken: nw_syntax's own clobber
* of `labs' meant this always silently reverted to the *original*
* network's own labels no matter what was passed.
nwclear
nwset, mat((0,1,0\1,0,1\0,1,0)) name(sizenet2) undirected labs(X,Y,Z)
mata: newmat2 = (0,1\1,0)
mata: st_matrix("newmat2", newmat2)
nwreplacemat sizenet2, newmat(newmat2) labs(P,Q) vars(P Q)
assert _rc == 0
nwname sizenet2
assert r(nodes) == 2
assert `"`r(labs)'"' == `"P,Q"'

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
