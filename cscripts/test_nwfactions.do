cscript

clear mata
do unw_core.do
set more off

* nwfactions: UCINET's own classical "factions" technique - partition
* nodes into a specified number of groups maximizing correlation with
* the ideal "same group tied, different group not" block pattern.
* Certified against 2 hand-computable cases (disjoint triangles, where
* the correct partition is unambiguous and achieves perfect fitness),
* matching this project's own established certification discipline for
* every other block-model/cohesive-subgroup command.

* --- two fully disjoint triangles (zero between-group ties): a
* "perfect" factions structure - groups(2) must recover exactly
* {A,B,C}/{D,E,F} with fitness == 1 (perfect correlation with the ideal
* block pattern).
nwclear
nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,0,0,0\0,0,0,0,1,1\0,0,0,1,0,1\0,0,0,1,1,0)) name(twotri) labs(A,B,C,D,E,F)
nwfactions twotri, groups(2) generate(fac) silent
assert reldif(r(fitness), 1) < 1e-6

qui sum fac if _n<=3
local g1 = r(mean)
local sd1 = r(sd)
qui sum fac if _n>3
local g2 = r(mean)
local sd2 = r(sd)
assert `g1' != `g2'
assert `sd1' == 0
assert `sd2' == 0
di "=== nwfactions: perfect two-triangle case REGRESSION VERIFIED ==="

* --- three fully disjoint triangles: groups(3) must recover all three
* groups exactly, again at fitness == 1. Deliberately NOT `nwclear'ing
* here (a real bug caught while writing this test, not in nwfactions.ado
* itself: `nwclear' drops the WHOLE network registry, so an earlier
* version of this test that did `nwclear' here silently destroyed
* `twotri' too, before the error-handling block below tried to reuse
* it - both networks coexist fine without clearing).
nwset, mat((0,1,1,0,0,0,0,0,0\1,0,1,0,0,0,0,0,0\1,1,0,0,0,0,0,0,0\0,0,0,0,1,1,0,0,0\0,0,0,1,0,1,0,0,0\0,0,0,1,1,0,0,0,0\0,0,0,0,0,0,0,1,1\0,0,0,0,0,0,1,0,1\0,0,0,0,0,0,1,1,0)) name(threetri) labs(A,B,C,D,E,F,G,H,I)
nwfactions threetri, groups(3) generate(fac3) silent
assert reldif(r(fitness), 1) < 1e-6
qui tab fac3
assert r(r) == 3
di "=== nwfactions: three-group perfect case REGRESSION VERIFIED ==="

* --- error handling: groups() out of [2,nodes], maxiter() must be
* positive, generate() collision needs replace.
capture nwfactions twotri, groups(1)
assert _rc == 198
capture nwfactions twotri, groups(100)
assert _rc == 198
capture nwfactions twotri, groups(2) maxiter(0)
assert _rc == 198
capture nwfactions twotri, groups(2) generate(fac)
assert _rc == 99
nwfactions twotri, groups(2) generate(fac) replace silent
assert _rc == 0
di "=== nwfactions error handling REGRESSION VERIFIED ==="

* --- BUGFIX regression (adversarial-input pressure test): the active
* dataset was never synced to the target network before st_store() -
* a bare `clear' immediately before the call crashed with a raw
* "argument out of range" (r3300).
clear
capture noisily nwfactions twotri, groups(2) generate(fac)
assert _rc == 0
assert _N >= 6
di "=== nwfactions: dataset-sync-after-clear REGRESSION VERIFIED ==="

* --- failure path: a name that isn't a loaded network is rejected via
* _nwsyntax's own "Network X not found" check (error 482).
capture noisily nwfactions nonexistent
assert _rc == 482
