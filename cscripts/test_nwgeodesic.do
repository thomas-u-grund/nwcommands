cscript

do unw_core.do

nwclear
nwset, mat((1,1,0,2\0,0,0,0\1,4,0,0\0,2,0,0)) name(mynet)
nwgeodesic mynet, unconnected(99) xvars generate(_eccentricity)
assert `"`r(symmetrized)'"' == `"false"'
assert `"`r(geodesic)'"'    == `"_geodesic"'
assert `"`r(netname)'"'     == `"mynet"'
assert `"`r(netlist)'"'     == `"_geodesic"'
assert `"`r(networks)'"'    == `"1"'

assert         r(diameter)    == 99
assert reldif( r(avgpath)      , 50.08333333333334 ) <  1E-8
assert         r(numpaths)    == 12
assert         r(nodes)       == 4
assert         r(unconnected) == 6
assert         r(id)          == 2

* eccentricity/radius (added alongside diameter/avgpath - same distance
* matrix, same unconnected(99) replacement already applied above)
assert         r(radius)      == 2
assert _eccentricity[1] == 99
assert _eccentricity[2] == 99
assert _eccentricity[3] == 2
assert _eccentricity[4] == 99


nwgeodesic mynet, sym unconnected(max) nwreplace xvars generate(_eccentricity)
assert `"`r(symmetrized)'"' == `"true"'
assert `"`r(geodesic)'"'    == `"_geodesic"'
assert `"`r(netname)'"'     == `"mynet"'
assert `"`r(netlist)'"'     == `"_geodesic"'
assert `"`r(networks)'"'    == `"1"'

assert         r(diameter)    == 2
assert         r(unconnected) == 0
assert reldif( r(avgpath)      , 1.166666666666667 ) <  1E-8
assert         r(numpaths)    == 6
assert         r(nodes)       == 4
assert         r(id)          == 3

assert         r(radius)      == 1
assert _eccentricity[1] == 1
assert _eccentricity[2] == 1
assert _eccentricity[3] == 2
assert _eccentricity[4] == 2


nwgeodesic mynet, nwreplace xvars generate(_eccentricity)
assert `"`r(symmetrized)'"' == `"false"'
assert `"`r(geodesic)'"'    == `"_geodesic"'
assert `"`r(netname)'"'     == `"mynet"'
assert `"`r(netlist)'"'     == `"_geodesic"'
assert `"`r(networks)'"'    == `"1"'

assert         r(diameter)    == -1
assert         r(avgpath)     == -1
assert         r(numpaths)    == 12
assert         r(nodes)       == 4
assert         r(unconnected) == 6
assert         r(id)          == 2

assert         r(radius)      == -1
assert _eccentricity[1] == 1
assert _eccentricity[2] == .
assert _eccentricity[3] == 2
assert _eccentricity[4] == 1

nwclear
set obs 6
gen x = "A"
gen y = "B"
gen value = 0

replace y = "C" in 2
replace value = 2 in 2

replace y = "D" in 3
replace value = 3 in 3

replace x = "C" in 4
replace value = 2 in 4

replace x = "E" in 5
replace value = 3 in 5

replace x = "D" in 6
replace y = "E" in 6
replace value = 0 in 6

nwset x y value, edgelist undirected name(network)
nwgeodesic network, alpha(0) xvars
assert B[1] == 2

nwgeodesic network, alpha(0.5) nwreplace xvars
assert B[1] > 1.4 & B[1] < 1.5

nwgeodesic network, alpha(1) nwreplace xvars
assert B[1] == 1

nwgeodesic network, alpha(1.5) nwreplace xvars
assert B[1] >= 0.7 & B[1] < 0.8


* --- eccentricity/radius: hand-computable cases

* Path graph A-B-C-D-E (undirected, unweighted): ecc = 4,3,2,3,4; radius=2
nwclear
nwset, mat((0,1,0,0,0\1,0,1,0,0\0,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) name(pathnet2) undirected labs(A,B,C,D,E)
nwgeodesic pathnet2, xvars generate(_eccentricity)
assert r(radius) == 2
assert r(diameter) == 4
assert _eccentricity[1] == 4
assert _eccentricity[2] == 3
assert _eccentricity[3] == 2
assert _eccentricity[4] == 3
assert _eccentricity[5] == 4

* K4 complete graph: every node has eccentricity 1, radius = diameter = 1
nwclear
nwset, mat((0,1,1,1\1,0,1,1\1,1,0,1\1,1,1,0)) name(k4net2) undirected labs(A,B,C,D)
nwgeodesic k4net2, xvars generate(_eccentricity)
assert r(radius) == 1
assert r(diameter) == 1
forvalues i = 1/4 {
	assert _eccentricity[`i'] == 1
}

* generate()/nwreplace guard on the eccentricity variable specifically
* (no separate replace() option - see the in-code note in nwgeodesic.ado on
* why it deliberately reuses nwreplace instead)
capture nwgeodesic k4net2, generate(_eccentricity)
assert _rc != 0
nwgeodesic k4net2, generate(_eccentricity) nwreplace xvars
assert _rc == 0
nwgeodesic k4net2, generate(myecc) nwreplace
assert r(radius) == 1








* --- generate() regression: a real bug (found while writing the Paths
* & Ego Networks tutorial) had eccentricity generation silently gated
* behind `xvars', so a plain `nwgeodesic ..., generate(ecc)' (no xvars)
* never created `ecc' at all. Fixed properly per the suite-wide
* generate()-required style decision (2026-09-05): nwgeodesic is
* dual-purpose (its PRIMARY output is the distance network via name(),
* eccentricity is a secondary bonus output) so - unlike a single-purpose
* command, where omitting generate() now errors - omitting generate()
* here means "skip eccentricity entirely" (no variable, no error, no
* default name at all). This also means nwreach.ado's own internal call
* (which only ever wanted the reachability network) needs no opt-out
* option whatsoever anymore - simply not passing generate() already does
* the right thing.
nwclear
nwset, mat((1,1,0,2\0,0,0,0\1,4,0,0\0,2,0,0)) name(mynet)
capture drop ecc
nwgeodesic mynet, generate(ecc)
assert _rc == 0
capture confirm variable ecc
assert _rc == 0

* a second call naming the SAME variable must require nwreplace, exactly
* like every other nwcommands generate() target.
capture noisily nwgeodesic mynet, name(_geo2) generate(ecc)
assert _rc == 99
nwgeodesic mynet, name(_geo2) generate(ecc) nwreplace
assert _rc == 0

* omitting generate() entirely never creates ANY eccentricity variable,
* under any name, default or otherwise.
capture drop _eccentricity
nwgeodesic mynet, name(_geo3)
assert _rc == 0
capture confirm variable _eccentricity
assert _rc != 0
di "=== generate()-required/optional-eccentricity REGRESSION VERIFIED ==="

* moderate-severity pass, paths_distance group: an ordinary, fully
* successful call (no sym, no xvars) used to leave a stale nonzero _rc
* (e.g. 3301) with nothing to do with the actual outcome - three
* separate unconditional captures (an existence-check nwdrop, a
* symmetrized-copy nwdrop, and _return drop on a first-ever-held name)
* each swallowed their own expected-failure case with nothing afterward
* to reset _rc.
nwclear
nwset, mat((1,1,0,2\0,0,0,0\1,4,0,0\0,2,0,0)) name(mynet)
nwgeodesic mynet
assert _rc == 0
nwclear
nwset, mat((1,1,0,2\0,0,0,0\1,4,0,0\0,2,0,0)) name(mynet)
nwgeodesic mynet, sym
assert _rc == 0
di "=== stale _rc leak REGRESSION VERIFIED ==="

* --- failure path: a name that isn't a loaded network is rejected via
* _nwsyntax's own "Network X not found" check (error 482).
capture noisily nwgeodesic nonexistent
assert _rc == 482
