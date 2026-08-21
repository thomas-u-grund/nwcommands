cscript

do unw_core.do

* _nwnodelab/_nwnodeid (internal node-id <-> node-label lookup
* helpers) had zero test coverage before this session, and were both
* broken:
*
* _nwnodelab crashed with r(198) "invalid name" on every call: it
* used the deprecated _nwsyntax wrapper, then referenced `nodes',
* which _nwsyntax never re-exports (same bug class found this
* session in nwqap/nwcloseness/nworder) - fixed by using r(nodes)
* from the nwname call already made on the previous line instead.
*
* Once that crash was fixed, a second, independent, unrelated bug
* surfaced in both _nwnodelab and _nwnodeid: nwname's r(labs) is
* comma-separated ("A,B,C" - see nw_name.ado's own invtokens with a
* comma delimiter), but both files fed it directly into constructs
* that expect a space-separated list ("word N of `labs''" in
* _nwnodelab, "foreach onelab in `labs''" in _nwnodeid) - the whole
* comma-joined string was treated as a single list item, so
* _nwnodelab silently returned an empty label for any nodeid past 1,
* and _nwnodeid reported every valid label as "not found" (r(6012)).
* Fixed by converting the comma-separated list to space-separated
* before use, in both files.

nwclear
nwset, mat((0,1,1\1,0,0\1,0,0)) name(net1) undirected labs(A,B,C)

* nodeid -> label, round trip for every node
_nwnodelab net1, nodeid(1)
assert `"`r(nodelab)'"' == `"A"'
_nwnodelab net1, nodeid(2)
assert `"`r(nodelab)'"' == `"B"'
_nwnodelab net1, nodeid(3)
assert `"`r(nodelab)'"' == `"C"'

* out-of-bounds nodeid must still error cleanly (the branch that was
* never reachable before the `nodes' crash fix)
capture _nwnodelab net1, nodeid(4)
* the literal "error 600022" call is pre-existing, untouched code;
* Stata's error-code handling truncates/maps it to 100000 - not
* something this fix changes, just confirming the guard still fires
* now that the crash blocking it is gone
assert _rc == 100000

* label -> nodeid, round trip for every node
_nwnodeid net1, nodelab(A)
assert r(nodeid) == 1
_nwnodeid net1, nodelab(B)
assert r(nodeid) == 2
_nwnodeid net1, nodelab(C)
assert r(nodeid) == 3

* a genuinely nonexistent label must still error cleanly (not every
* label being falsely reported as missing, as it was before the fix)
capture _nwnodeid net1, nodelab(Z)
assert _rc == 6012

* numeric nodelab: direct pass-through as a node id (separate code
* path, was not affected by either bug - regression-guarded here)
_nwnodeid net1, nodelab(2)
assert r(nodeid) == 2
