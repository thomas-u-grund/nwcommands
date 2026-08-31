cscript

clear mata
do unw_core.do
set more off

* nwrandomwalk: mean hitting time from every node to a specified target,
* via NWdef::calculate_randomwalk_hitting() (an exact linear-system
* solve, not a simulation - the same "solve directly" discipline
* nwkatz's own walk-counting Katz centrality already established for an
* analogous exact random-walk quantity). Certified against a fully
* hand-derived 3-node path example (a clean, independently-solvable
* 2-equation system, not a black-box formula lookup).

* --- 3-node undirected path A-B-C, target C. Hand-derived exact
* values (h(B) = 1 + 0.5*0 + 0.5*h(A); h(A) = 1 + h(B); solving:
* h(B)=3, h(A)=4, h(C)=0 by definition).
nwclear
nwset, mat((0,1,0\1,0,1\0,1,0)) name(path3rw) labs(A,B,C)
nwrandomwalk path3rw, target(C) generate(ht) silent
assert reldif(ht[1], 4) < 1e-6
assert reldif(ht[2], 3) < 1e-6
assert ht[3] == 0
di "=== nwrandomwalk: hand-derived 3-node path REGRESSION VERIFIED ==="

* --- symmetric check: on a triangle, hitting time to any target from
* either OTHER node must be identical (both other nodes are structurally
* equivalent with respect to the target). Deliberately NOT `nwclear'ing
* here - `path3rw' is reused for the error-handling check below, and
* `nwclear' drops the whole network registry (the same lesson this
* session's SAOM/nwneighbor/nwfactions/nwpagerank work already hit).
nwset, mat((0,1,1\1,0,1\1,1,0)) name(tri3rw) labs(A,B,C)
nwrandomwalk tri3rw, target(C) generate(ht3) silent
assert reldif(ht3[1], ht3[2]) < 1e-6
assert ht3[3] == 0
di "=== nwrandomwalk: triangle symmetry REGRESSION VERIFIED ==="

* --- error handling: unknown target node; a network containing an
* isolate has no well-defined hitting time.
capture nwrandomwalk path3rw, target(bogus)
assert _rc == 99

nwclear
nwset, mat((0,1,0\1,0,0\0,0,0)) name(withisolate) labs(A,B,C)
capture nwrandomwalk withisolate, target(A)
assert _rc == 6556
di "=== nwrandomwalk error handling REGRESSION VERIFIED ==="
