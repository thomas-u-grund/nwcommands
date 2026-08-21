cscript

do unw_core.do

* --- Two disjoint K5 cliques (10 nodes, 20 edges, density=20/45=.4444)
* -> 2 components. At this density, random ER graphs on 10 nodes should
* essentially always be a single connected component (well above the
* ln(n)/n connectivity threshold), so the observed value is provably more
* fragmented than any random draw at the same density - a fully
* deterministic certification case (sd_null=0 at 500 reps).
mata: A = J(10,10,0)
mata: A[1::5,1::5] = J(5,5,1) - I(5)
mata: A[6::10,6::10] = J(5,5,1) - I(5)
nwclear
nwset, mat(A)
nwname, newname(twoclique)

qui nwcomponents twoclique
assert r(components) == 2

nwcug twoclique, stat(nwcomponents ##net##, replace) rname(components) reps(500) seed(20260821)
assert r(obs) == 2
assert r(reps) == 500
assert r(mean_null) == 1
assert r(sd_null) == 0
assert r(p_greater) == 0
assert r(p_less) == 1
assert r(p) == 0

* reproducibility: identical seed -> identical results
nwcug twoclique, stat(nwcomponents ##net##, replace) rname(components) reps(500) seed(20260821)
assert r(p_greater) == 0
assert r(mean_null) == 1


* --- sanity bounds: p-values must lie in [0,1] and reps must match request,
* on a milder, less deterministic case (5 disjoint pairs, 10 nodes, 5
* edges, density=5/45=.1111 - well below the connectivity threshold, so
* both observed and random draws are typically fragmented; not expected
* to be "significant" either way, just well-behaved)
nwclear
nwset, mat((0,1,0,0,0,0,0,0,0,0\1,0,0,0,0,0,0,0,0,0\0,0,0,1,0,0,0,0,0,0\0,0,1,0,0,0,0,0,0,0\0,0,0,0,0,1,0,0,0,0\0,0,0,0,1,0,0,0,0,0\0,0,0,0,0,0,0,1,0,0\0,0,0,0,0,0,1,0,0,0\0,0,0,0,0,0,0,0,0,1\0,0,0,0,0,0,0,0,1,0)) name(fragnet) undirected

qui nwcomponents fragnet
assert r(components) == 5

nwcug fragnet, stat(nwcomponents ##net##, replace) rname(components) reps(200) seed(20260821) silent
assert r(obs) == 5
assert r(reps) == 200
assert r(p_greater) >= 0 & r(p_greater) <= 1
assert r(p_less) >= 0 & r(p_less) <= 1
assert r(p) >= 0 & r(p) <= 1
assert r(mean_null) > 0
assert r(sd_null) >= 0


* --- tail() option validity
capture nwcug fragnet, stat(nwcomponents ##net##, replace) rname(components) reps(10) tail(bogus)
assert _rc != 0

nwcug fragnet, stat(nwcomponents ##net##, replace) rname(components) reps(50) seed(1) tail(upper) silent
assert r(p_greater) >= 0 & r(p_greater) <= 1

nwcug fragnet, stat(nwcomponents ##net##, replace) rname(components) reps(50) seed(1) tail(lower) silent
assert r(p_less) >= 0 & r(p_less) <= 1


* --- invalid rname() errors cleanly (stat() ran but never returned r(bogusname))
capture nwcug fragnet, stat(nwcomponents ##net##, replace) rname(bogusname) reps(10)
assert _rc != 0
