cscript

clear mata
do unw_core.do
set more off

* nwpagerank: Page & Brin's (1998) random-walk-based centrality, via
* NWdef::calculate_pagerank() (sparse power iteration on the network's
* own in-neighbor structure, no dense matrix materialized). Certified
* against 2 hand-computable properties: a fully symmetric directed
* cycle must give every node the identical score, and a dangling
* (zero-out-degree) node's own rank mass must be correctly redistributed
* (the scores must still sum to exactly 1, never NaN/missing).

* --- fully symmetric 3-node directed cycle A->B->C->A: by symmetry,
* every node must get the IDENTICAL PageRank score, regardless of the
* damping factor.
nwclear
nwset, mat((0,1,0\0,0,1\1,0,0)) name(cyc3) directed labs(A,B,C)
nwpagerank cyc3, generate(pr) silent
qui sum pr
assert reldif(r(sum), 1) < 1e-6
assert (r(max) - r(min)) < 1e-6
di "=== nwpagerank: symmetric-cycle case REGRESSION VERIFIED ==="

* --- dangling node (C has zero out-ties): scores must still sum to
* exactly 1 (real PageRank's own dangling-mass redistribution, not an
* approximation that silently loses probability mass). Deliberately NOT
* `nwclear'ing here - a real bug caught while writing this test, not in
* nwpagerank.ado itself: `nwclear' drops the WHOLE network registry, so
* an earlier version of this test destroyed `cyc3' before the
* error-handling block below tried to reuse it - both networks coexist
* fine without clearing (the same lesson this session's SAOM/nwneighbor/
* nwfactions work already hit more than once).
nwset, mat((0,1,0\0,0,1\0,0,0)) name(dangle3) directed labs(A,B,C)
nwpagerank dangle3, generate(pr2) silent
qui sum pr2
assert reldif(r(sum), 1) < 1e-6
assert r(N) == 3
di "=== nwpagerank: dangling-node case REGRESSION VERIFIED ==="

* --- error handling: damping() must be strictly between 0 and 1;
* maxiter() must be positive; generate() collision needs replace.
capture nwpagerank cyc3, damping(1)
assert _rc == 198
capture nwpagerank cyc3, damping(0)
assert _rc == 198
capture nwpagerank cyc3, maxiter(0)
assert _rc == 198
capture nwpagerank cyc3, generate(pr)
assert _rc == 99
nwpagerank cyc3, generate(pr) replace silent
assert _rc == 0
di "=== nwpagerank error handling REGRESSION VERIFIED ==="

* --- BUGFIX regression (adversarial-input pressure test): the active
* dataset was never synced to the target network before st_store() -
* a bare `clear' immediately before the call crashed with a raw
* "argument out of range" (r3300).
clear
capture noisily nwpagerank cyc3
assert _rc == 0
assert _N >= 3
di "=== nwpagerank: dataset-sync-after-clear REGRESSION VERIFIED ==="

* --- failure path: a name that isn't a loaded network is rejected via
* nw_syntax's own "Network X not found" check (error 482).
capture noisily nwpagerank nonexistent
assert _rc == 482
