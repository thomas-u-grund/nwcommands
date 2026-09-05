cscript

do unw_core.do

* nwproject is a pure alias for nw2project (harmonisation phase, naming
* convention: no nw2 prefix needed, since a one-mode nwproject could
* never exist). Confirms it forwards arguments/options and stored
* results identically - not a re-implementation, so this mirrors (a
* subset of) test_nw2project.do's own worked Peter/Thomas example.

nwclear
set obs 4
gen ego = "Peter"
gen alter = "LiU"
gen value = 1
replace ego = "Thomas" in 2
replace alter = "LiU" in 2
replace value = 1 in 2
replace ego = "Peter" in 3
replace alter = "Oxford" in 3
replace value = 7 in 3
replace ego = "Thomas" in 4
replace alter = "Oxford" in 4
replace value = 5 in 4
nw2fromedge ego alter value, name(mynet)

nwproject mynet, project(1) name(proj1) stat(minmax)
assert _rc == 0
assert r(nodes) == 2
assert r(ties) == 2
nwtomata proj1, mat(M)
mata: assert(M[1,2] == 5)

* replace/xvars options forward through, and r(nodes)/r(ties) are
* readable immediately after the call, matching nw2project's own
* documented behavior.
nwproject mynet, project(1) name(proj1) replace stat(max)
assert _rc == 0
nwtomata proj1, mat(M2)
mata: assert(M2[1,2] == 7)

di "=== nwproject alias VERIFIED ==="

* --- failure path: a name that isn't a loaded network is rejected via
* nw2project's own _nwsyntax passthrough (error 482).
capture noisily nwproject nonexistent, project(1)
assert _rc == 482
