cscript

do unw_core.do

* nwnoderename had a SMCL doc header (and, per harmonisation unit 16's
* survey, no certification) but literally no cscripts/test_*.do file at
* all (a stray, wrongly-extensioned cscripts/test_nwnoderename.ado draft
* existed on disk, untracked, never actually run as part of the suite -
* superseded by this file). Found empirically correct as-is (no bugs
* found) via direct probing before writing these assertions - it already
* uses the modern _nwsyntax (not the deprecated _nwsyntax wrapper), so it
* was not part of the harmonisation-unit-9-13/unit-30 bug class affecting
* nwdropnodes/nwkeepnodes/nwreplacemat.

* --- basic rename: the target node's label changes in place (same row),
* and _nwdatasync leaves a second, _nwinclude==0 row behind holding the
* old label (the same shared-dataset-can-back-multiple-networks
* convention documented for nwdropnodes; not itself a bug).
nwclear
nwrandom 4, prob(1) name(mynet)
nwnoderename mynet, old(n1) new(x1)
assert r(success) == 1
assert _nwnode[1] == "x1"
assert _nwinclude[1] == 1
nwname mynet
assert `"`r(labs)'"' == `"x1,n2,n3,n4"'
assert r(nodes) == 4

* --- renaming to a label that already exists in the network must fail
* cleanly (r(success)==0, _rc==0 - a soft-fail flag, not a hard Stata
* error, confirmed via direct testing of the command's own design).
nwclear
nwrandom 4, prob(1) name(mynet2)
capture nwnoderename mynet2, old(n2) new(n3)
assert _rc == 0
assert r(success) == 0

* --- renaming a node that does not exist in the network must also fail
* cleanly the same way.
capture nwnoderename mynet2, old(zzz) new(y1)
assert _rc == 0
assert r(success) == 0

* --- directed, weighted network: the rename must only touch the label,
* leaving edge structure/weights and the directed flag untouched, and
* must work correctly even when the new label contains a space (the
* underlying _nwnode variable is a string value, not a Stata identifier,
* so this is a legitimate case - the command's own "capture rename
* `old' `new'" line, which only applies if a same-named Stata *variable*
* happens to exist, is expected to no-op harmlessly here).
nwclear
nwset, mat((0,2,0\0,0,3\1,0,0)) name(dnet) directed labs(A,B,C)
nwnoderename dnet, old(B) new(mr smith)
assert r(success) == 1
nwname dnet
assert `"`r(labs)'"' == `"A,mr smith,C"'
assert `"`r(directed)'"' == `"true"'
nwtomata dnet, mat(M2)
mata: assert(M2[1,2] == 2)
mata: assert(M2[2,3] == 3)
mata: assert(M2[3,1] == 1)
mata: assert(M2[2,1] == 0)
