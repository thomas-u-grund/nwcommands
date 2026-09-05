cscript

do unw_core.do

nwclear
set obs 10
gen x = _n
gen y = 1
gen value = 1
nwset x y value, edgelist
nwcomponents, generate(_component)

assert         r(components) == 1

qui {
mat T_comp_sizeid = J(1,3,0)
mat T_comp_sizeid[1,1] =                 10
mat T_comp_sizeid[1,2] =                  1
mat T_comp_sizeid[1,3] =                  1
}
matrix C_comp_sizeid = r(comp_sizeid)
assert mreldif( C_comp_sizeid , T_comp_sizeid ) < 1E-8
_assert_streq `"`: rowfullnames C_comp_sizeid'"' `"comp1"'
_assert_streq `"`: colfullnames C_comp_sizeid'"' `"size compid share"'
mat drop C_comp_sizeid T_comp_sizeid


nwclear
set obs 10
gen x = _n
gen y = 1
gen value = 1
replace value = 0 in 4
nwset x y value, edgelist
nwcomponents, generate(_component) replace
assert         r(components) == 2

qui {
mat T_comp_sizeid = J(2,3,0)
mat T_comp_sizeid[1,1] =                  9
mat T_comp_sizeid[1,2] =                  1
mat T_comp_sizeid[1,3] =                 .9
mat T_comp_sizeid[2,1] =                  1
mat T_comp_sizeid[2,2] =                  2
mat T_comp_sizeid[2,3] =                 .1
}
matrix C_comp_sizeid = r(comp_sizeid)
assert mreldif( C_comp_sizeid , T_comp_sizeid ) < 1E-8
_assert_streq `"`: rowfullnames C_comp_sizeid'"' `"comp1 comp2"'
_assert_streq `"`: colfullnames C_comp_sizeid'"' `"size compid share"'
mat drop C_comp_sizeid T_comp_sizeid

nwcomponents, lgc generate(_lgc)
assert _lgc[1] == 1
assert _lgc[4] == 0

nwcomponents, lgc generate(mylgc)
assert mylgc[1] == 1
assert mylgc[4] == 0

nwcomponents,  generate(mycomp)
assert mycomp[4] == 2

capture nwcomponents,  generate(mycomp)
assert _rc != 0

* --- netlist regression: on a multi-network call, the second (and
* later) network's own already-exists check must look at its own
* suffixed variable name (e.g. mynetlistcomp2), not the bare stem
* (mynetlistcomp) - Stata's own variable-name abbreviation otherwise
* lets a bare-stem confirm match an already-existing mynetlistcomp1
* from the first iteration, falsely blocking every later iteration
* even though its own target name is still free. Found while building
* nwconcor.ado's netlist support (same copy-pasted pattern here).
nwclear
nwset, mat((0,1\1,0)) name(nA) undirected
nwset, mat((0,1\1,0)) name(nB) undirected
nwcomponents nA nB, generate(mynetlistcomp)
assert _rc == 0
capture confirm variable mynetlistcomp1, exact
assert _rc == 0
capture confirm variable mynetlistcomp2, exact
assert _rc == 0

* moderate-severity pass, cohesion_subgroups group: nwcomponents was the
* only command in this group without a silent option to suppress its
* display output, unlike every one of its 7 siblings.
nwclear
nwset, mat((0,1\1,0)) name(nn) undirected
capture noisily nwcomponents nn, generate(_component) silent
assert _rc == 0
di "=== silent option REGRESSION VERIFIED ==="

* --- failure path: a name that isn't a loaded network is rejected via
* _nwsyntax's own "Network X not found" check (error 482).
capture noisily nwcomponents nonexistent
assert _rc == 482




