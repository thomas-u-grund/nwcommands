cscript

clear mata
do unw_core.do
set more off


nwclear
set obs 4
gen v1 = 0
gen v2 = (_n == 3)
gen v3 = (_n < 3)
gen v4 = 0
gen v5 = (_n < 3)

nwset v*, name(netfromvar)
nwneighbor netfromvar, ego(v3)

assert `"`r(ego)'"'         == `"v3"'

assert         r(num_neighbors) == 1
assert         r(egoid)         == 3

mat T_neighbors=                  2
matrix C_neighbors = r(neighbors)
assert mreldif( C_neighbors , T_neighbors ) < 1E-8
_assert_streq `"`: rowfullnames C_neighbors'"' `"r1"'
_assert_streq `"`: colfullnames C_neighbors'"' `"c1"'
mat drop C_neighbors T_neighbors


nwneighbor netfromvar, ego(v3) mode(either)
assert `"`r(ego)'"' == `"v3"'

assert         r(num_neighbors) == 2
assert         r(egoid)         == 3

qui {
mat T_neighbors = J(2,1,0)
mat T_neighbors[1,1] =                  1
mat T_neighbors[2,1] =                  2
}
matrix C_neighbors = r(neighbors)
assert mreldif( C_neighbors , T_neighbors ) < 1E-8
_assert_streq `"`: rowfullnames C_neighbors'"' `"r1 r2"'
_assert_streq `"`: colfullnames C_neighbors'"' `"c1"'
mat drop C_neighbors T_neighbors

nwneighbor netfromvar, ego(v3) mode(either) generate(x)
assert x[1] == 1


* mode(incoming): sparse-migration bugfix regression coverage. The prior
* dense-matrix implementation had a stray unbalanced paren in this exact
* branch - a genuine Mata syntax error, so "incoming" could never have
* actually run before. Directed: A->B, A->C, B->C (A=1,B=2,C=3).
nwclear
nwset, mat((0,1,1\0,0,1\0,0,0)) name(dirnet) directed labs(A,B,C)

* outgoing(A) = {B,C}
nwneighbor dirnet, ego(A)
assert r(num_neighbors) == 2
mat T_out = J(2,1,0)
mat T_out[1,1] = 2
mat T_out[2,1] = 3
matrix C_out = r(neighbors)
assert mreldif(C_out, T_out) < 1E-8
mat drop C_out T_out

* incoming(C) = {A,B} (both A and B point to C)
nwneighbor dirnet, ego(C) mode(incoming)
assert r(num_neighbors) == 2
mat T_in = J(2,1,0)
mat T_in[1,1] = 1
mat T_in[2,1] = 2
matrix C_in = r(neighbors)
assert mreldif(C_in, T_in) < 1E-8
mat drop C_in T_in

* incoming(A) = {} (nobody points to A)
nwneighbor dirnet, ego(A) mode(incoming)
assert r(num_neighbors) == 0

* either(B): outgoing {C}, incoming {A} -> union {A,C}
nwneighbor dirnet, ego(B) mode(either)
assert r(num_neighbors) == 2
mat T_eith = J(2,1,0)
mat T_eith[1,1] = 1
mat T_eith[2,1] = 3
matrix C_eith = r(neighbors)
assert mreldif(C_eith, T_eith) < 1E-8
mat drop C_eith T_eith

* generate() indicator variable, incoming mode
nwneighbor dirnet, ego(C) mode(incoming) generate(inc)
assert inc[1] == 1
assert inc[2] == 1
assert inc[3] == 0

* moderate-severity pass, paths_distance group: r(oneneighbor) was
* deterministically never a genuine random pick among multiple
* neighbors - jumble() shuffles MATRIX ROWS (name-row vs id-row), not
* which neighbor is selected, so it only ever returned "the first
* neighbor", with a coin-flip on whether that was its name or its id.
nwwebuse florentine, nwclear
local sawbarbadori = 0
local sawmedici = 0
forvalues i = 1/30 {
	nwneighbor flobusiness, ego(ginori)
	assert `"`r(oneneighbor)'"' == "barbadori" | `"`r(oneneighbor)'"' == "medici"
	if `"`r(oneneighbor)'"' == "barbadori" local sawbarbadori = 1
	if `"`r(oneneighbor)'"' == "medici" local sawmedici = 1
}
assert `sawbarbadori' == 1
assert `sawmedici' == 1

nwset, mat((0,1,0\0,0,0\0,0,0)) name(onenbnet) directed labs(A,B,C)
nwneighbor onenbnet, ego(A)
assert `"`r(oneneighbor)'"' == "B"

nwset, mat((0,0,0\0,0,0\0,0,0)) name(isonet) directed labs(A,B,C)
nwneighbor isonet, ego(A)
assert `"`r(oneneighbor)'"' == ""
assert r(num_neighbors) == 0
di "=== r(oneneighbor) REGRESSION VERIFIED ==="

* --- subnet(): induced ego-network extraction as a genuine new named
* network (NWdef::copy_subgraph_into(), unw_core.do) - roadmap item
* "nwneighbor - sparse migration + add induced-subgraph output".
nwclear
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) name(subw1) labs(A,B,C,D,E)
nwneighbor subw1, ego(C) mode(either) subnet(subC)
assert r(num_neighbors) == 3
qui nwsummarize subC, matonly
assert r(nodes) == 4
* the induced subgraph is w1's own true induced structure on {A,B,C,D}:
* A-C tied, A-D not (A and D were never tied in the original network).
nw_syntax subC
mata: st_numscalar("__t_ac", (*`netobj'->get_matrix())[1,3])
mata: st_numscalar("__t_ad", (*`netobj'->get_matrix())[1,4])
assert __t_ac == 1
assert __t_ad == 0
scalar drop __t_ac __t_ad

* the ORIGINAL network (subw1) is left completely untouched - confirmed
* directly, not assumed, since copy_subgraph_into()'s own source
* network is only ever READ from (get_matrix_copy()/get_nodenames()),
* never mutated.
qui nwsummarize subw1, matonly
assert r(nodes) == 5

* an isolate ego's own induced subgraph is just itself, alone - no crash
* on the cols(k)==0-neighbors edge case.
nwclear
nwset, mat((0,0,0\0,0,0\0,0,0)) name(subiso) directed labs(A,B,C)
nwneighbor subiso, ego(A) subnet(subA)
qui nwsummarize subA, matonly
assert r(nodes) == 1

* collision without subreplace errors cleanly; subreplace overwrites.
capture nwneighbor subiso, ego(B) subnet(subA)
assert _rc == 99
nwneighbor subiso, ego(B) subnet(subA) subreplace
qui nwsummarize subA, matonly
assert r(nodes) == 1

* the CALLING program's own r()/netname state is unaffected by the
* subnet()-creation detour - a real bug found and fixed while building
* this (nw_syntax() sets `netname' as a side effect of resolving the
* NEW subnet network, silently redirecting every later line in
* nwneighbor.ado onto it unless explicitly restored via a SEPARATE
* saved local, not `netname' itself).
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(subw2) labs(A,B,C)
nwneighbor subw2, ego(A) mode(either) subnet(subA2)
assert r(num_neighbors) == 2
assert `"`r(ego)'"' == "A"

di "=== nwneighbor subnet() (induced-subgraph output) REGRESSION VERIFIED ==="

* --- failure paths: ego() is a required option (rejected by Stata's
* own syntax parser without it); a node that doesn't exist in the
* network is rejected (err 99, via nwnode's own -1 "not found" id);
* an invalid mode() value is rejected by _opts_oneof (error 6556); a
* name that isn't a loaded network is rejected via nw_syntax (482).
nwclear
nwset, mat((0,1\1,0)) name(failnet) labs(A,B)
capture noisily nwneighbor failnet
assert _rc != 0

capture noisily nwneighbor failnet, ego(Z)
assert _rc == 99

capture noisily nwneighbor failnet, ego(A) mode(sideways)
assert _rc == 6556

capture noisily nwneighbor nonexistent, ego(A)
assert _rc == 482




