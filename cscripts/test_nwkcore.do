cscript

do unw_core.do

* --- Triangle {A,B,C} + pendant D attached only to A -> expect 2,2,2,1
nwclear
nwset, mat((0,1,1,1\1,0,1,0\1,1,0,0\1,0,0,0)) name(trinet) undirected labs(A,B,C,D)
nwkcore

assert r(maxcore) == 2
assert _kcore[1] == 2
assert _kcore[2] == 2
assert _kcore[3] == 2
assert _kcore[4] == 1

qui {
mat T_core_sizeid = J(2,3,0)
mat T_core_sizeid[1,1] =                  3
mat T_core_sizeid[1,2] =                  2
mat T_core_sizeid[1,3] =                 .75
mat T_core_sizeid[2,1] =                  1
mat T_core_sizeid[2,2] =                  1
mat T_core_sizeid[2,3] =                 .25
}
matrix C_core_sizeid = r(core_sizeid)
assert mreldif( C_core_sizeid , T_core_sizeid ) < 1E-6
mat drop C_core_sizeid T_core_sizeid


* --- Complete graph K5 -> expect all nodes = 4 (the (n-1)-core of Kn)
nwclear
nwset, mat((0,1,1,1,1\1,0,1,1,1\1,1,0,1,1\1,1,1,0,1\1,1,1,1,0)) name(k5net) undirected labs(A,B,C,D,E)
nwkcore, generate(k5core)

assert r(maxcore) == 4
forvalues i = 1/5 {
	assert k5core[`i'] == 4
}


* --- Empty network (no edges) -> expect all nodes = 0
nwclear
nwset, mat((0,0,0\0,0,0\0,0,0)) name(emptynet) undirected labs(A,B,C)
nwkcore, generate(emptycore)

assert r(maxcore) == 0
forvalues i = 1/3 {
	assert emptycore[`i'] == 0
}


* --- Path graph A-B-C-D-E (no cycles) -> expect all nodes = 1
nwclear
nwset, mat((0,1,0,0,0\1,0,1,0,0\0,1,0,1,0\0,0,1,0,1\0,0,0,1,0)) name(pathnet) undirected labs(A,B,C,D,E)
nwkcore, generate(pathcore)

assert r(maxcore) == 1
forvalues i = 1/5 {
	assert pathcore[`i'] == 1
}


* --- replace guard
capture nwkcore, generate(pathcore)
assert _rc != 0
nwkcore, generate(pathcore) replace
assert r(maxcore) == 1


* --- directed network: coreness computed on union of out/in neighbors
nwclear
nwset, mat((0,1,1\0,0,1\0,0,0)) name(dirnet) directed labs(A,B,C)
nwkcore, generate(dircore)

* undirected sense: A-B, A-C, B-C all present -> triangle, all coreness 2
assert dircore[1] == 2
assert dircore[2] == 2
assert dircore[3] == 2


* --- alpha-audit regression: netlist support was broken - the
* existing-variable collision guard checked the bare stem (`netgenerate')
* with no iteration suffix at all, so a call with 2+ networks and no
* replace() falsely errored on the second (and every later) network even
* though its own target variable (`netgenerate'`k') was never actually
* created. Matches the pattern every sibling command in this group
* already uses (nwclique/nwkcomponents/nwkplex/nwnclan/nwnclique/
* nwcohesion/nwcomponents).
nwclear
nwset, mat((0,1\1,0)) name(nA) undirected
nwset, mat((0,1\1,0)) name(nB) undirected
nwkcore nA nB
assert _rc == 0
capture confirm variable _kcore1, exact
assert _rc == 0
capture confirm variable _kcore2, exact
assert _rc == 0

* missing_test finding, cohesion_subgroups group: silent was never
* exercised.
nwclear
nwset, mat((0,1,1\1,0,1\1,1,0)) name(tri) undirected
nwkcore tri, silent
assert _rc == 0
assert r(maxcore) == 2
di "=== silent REGRESSION VERIFIED ==="
