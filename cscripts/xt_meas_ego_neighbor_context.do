* xt_meas_ego_neighbor_context.do -- extended tests for nwego, nwneighbor and nwcontext.
* Run with Stata 17; every check passes since the fixes of the measure suite (fixes-xt).
*
* Covers: ego-network size and density (star, triangle with a tail, an isolate, directed: union of in- and
* out-neighbours, density over ordered pairs); nwneighbor modes, isolate ego, r() (num_neighbors,
* neighbors, oneneighbor, egoid), generate(), subnet()/subreplace, error codes, the user's Mata variable
* __nb and the random-number state; nwcontext every stat() on a path with attribute (1, 10, 100), directed
* outgoing/incoming, mode(either) on undirected and reciprocated ties (each neighbour once), valued with
* and without noweight, a missing attribute value, mat(), error codes, the user's Mata variables.
* All numbers are hand-derived.
* Run from the repository root.

clear all
set more off
set graphics off
do unw_core.do
run cscripts/xt_meas_00_helpers.do
xt_minit xt_meas_ego_neighbor_context
nwclear

* ---------------------------------------------------------------- (1) nwego
nwclear
clear
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(star4) undirected
nwego star4, sizevar(sz) densvar(dn)
xa sz[1] == 3 & dn[1] == 0
xa sz[2] == 1 & dn[2] == .
* triangle 1-2-3 with tail 3-4 and an isolate 5
nwset, mat((0,1,1,0,0\1,0,1,0,0\1,1,0,1,0\0,0,1,0,0\0,0,0,0,0)) name(tti) undirected
nwego tti, sizevar(sz2) densvar(dn2)
xa sz2[1] == 2 & dn2[1] == 1
xa sz2[3] == 3 & reldif(dn2[3], 1/3) < 1e-7
xa sz2[4] == 1 & dn2[4] == .
xa sz2[5] == 0 & dn2[5] == .
* directed: 1 -> 2, 2 -> 3, 3 -> 1, 1 -> 3: alters of 1 are {2, 3}; among them 2 -> 3 only: 1 of 2 ordered pairs
nwset, mat((0,1,1\0,0,1\1,0,0)) name(d3) directed
nwego d3, sizevar(sz3) densvar(dn3)
xa sz3[1] == 2 & reldif(dn3[1], .5) < 1e-7
* valued ties count as ties
nwset, mat((0,2.5,.5\2.5,0,3\.5,3,0)) name(v3) undirected
nwego v3, sizevar(szv) densvar(dnv)
xa szv[1] == 2 & dnv[1] == 1
* errors
capture nwego star4, densvar(x)
xa _rc == 198
capture nwego star4, sizevar(x)
xa _rc == 198
capture nwego star4, sizevar(sz) densvar(newd)
xa _rc == 110
capture confirm variable newd
xa _rc != 0
* a list: suffix 1, 2
nwego star4 d3, sizevar(ls) densvar(ld)
confirm variable ls1 ls2 ld1 ld2, exact
xa ls1[1] == 3 & ls2[1] == 2
di "(1) nwego: ok"

* ---------------------------------------------------------------- (2) nwneighbor
nwclear
clear
nwset, mat((0,1,1,1,0\1,0,0,0,0\1,0,0,0,0\1,0,0,0,0\0,0,0,0,0)) name(s5) undirected labs(a,b,c,d,e)
nwneighbor s5, ego(a) generate(nb)
xa r(num_neighbors) == 3
xa "`r(ego)'" == "a" & r(egoid) == 1
matrix NB = r(neighbors)
xa rowsof(NB) == 3 & NB[1,1] == 2 & NB[2,1] == 3 & NB[3,1] == 4
xa nb[1] == 0 & nb[2] == 1 & nb[4] == 1 & nb[5] == 0
nwneighbor s5, ego(b)
xa r(num_neighbors) == 1 & "`r(oneneighbor)'" == "a"
* an isolate: no neighbours
nwneighbor s5, ego(e)
xa r(num_neighbors) == 0 & "`r(oneneighbor)'" == ""
* directed: 1 -> 2, 3 -> 1
nwset, mat((0,1,0\0,0,0\1,0,0)) name(d3) directed labs(x,y,z)
nwneighbor d3, ego(x)
xa r(num_neighbors) == 1
matrix NB = r(neighbors)
xa NB[1,1] == 2
nwneighbor d3, ego(x) mode(incoming)
matrix NB = r(neighbors)
xa r(num_neighbors) == 1 & NB[1,1] == 3
nwneighbor d3, ego(x) mode(either)
xa r(num_neighbors) == 2
* subnet: ego and its neighbours, induced
nwneighbor s5, ego(a) subnet(sa)
nwsummarize sa
xa r(nodes) == 4 & r(edges) == 3
capture nwneighbor s5, ego(a) subnet(sa)
xa _rc == 483
nwneighbor s5, ego(b) subnet(sa) subreplace
nwsummarize sa
xa r(nodes) == 2
* errors
capture nwneighbor s5, ego(a) mode(sideways)
xa _rc == 6556
capture nwneighbor s5, ego(zz)
xa _rc != 0
capture nwneighbor s5, ego(a) generate(nb)
xa _rc == 110
nwneighbor s5, ego(b) generate(nb) replace
xa nb[1] == 1 & nb[2] == 0
* SUSPECTED BUG: nwneighbor.ado uses the plain Mata global __nb (GOTCHA: tempname or __nw prefix)
mata: __nb = 42
nwneighbor s5, ego(a)
xm assert(__nb == 42)    // fixed: CONFIRMED BUG M10a
capture mata: mata drop __nb
* SUSPECTED BUG (minor): r(oneneighbor) is drawn with runiformint(), so a measure command moves the
* random-number stream.  Expected: the stream after nwneighbor is the stream before it.
set seed 5
local u0 = runiform()
set seed 5
nwneighbor s5, ego(a)
local u1 = runiform()
xa `u1' == `u0'    // fixed: CONFIRMED BUG M10b
di "(2) nwneighbor: ok"

* ---------------------------------------------------------------- (3) nwcontext: every stat on a path
nwclear
clear
nwset, mat((0,1,0\1,0,1\0,1,0)) name(p3) undirected
set obs 3
gen double a = cond(_n == 1, 1, cond(_n == 2, 10, 100))
nwcontext p3, attribute(a) generate(x_mean)
xa x_mean[1] == 10 & x_mean[2] == 50.5 & x_mean[3] == 10
nwcontext p3, attribute(a) generate(x_sum) stat(sum)
xa x_sum[1] == 10 & x_sum[2] == 101 & x_sum[3] == 10
nwcontext p3, attribute(a) generate(x_max) stat(max)
xa x_max[1] == 10 & x_max[2] == 100 & x_max[3] == 10
nwcontext p3, attribute(a) generate(x_min) stat(min)
xa x_min[1] == 10 & x_min[2] == 1 & x_min[3] == 10
* population sd over the neighbours: node 2 {1, 100} -> 49.5; one neighbour -> 0
nwcontext p3, attribute(a) generate(x_sd) stat(sd)
xa reldif(x_sd[2], 49.5) < 1e-6 & x_sd[1] == 0
nwcontext p3, attribute(a) generate(x_meanego) stat(meanego)
xa x_meanego[1] == 5.5 & x_meanego[2] == 37 & x_meanego[3] == 55
nwcontext p3, attribute(a) generate(x_sumego) stat(sumego)
xa x_sumego[1] == 11 & x_sumego[2] == 111 & x_sumego[3] == 110
nwcontext p3, attribute(a) generate(x_maxego) stat(maxego)
xa x_maxego[1] == 10 & x_maxego[2] == 100 & x_maxego[3] == 100
nwcontext p3, attribute(a) generate(x_minego) stat(minego)
xa x_minego[1] == 1 & x_minego[2] == 1 & x_minego[3] == 10
* mat(): the same numbers in a Mata vector
nwcontext p3, attribute(a) mat(CX)
xm assert(CX == (10 \ 50.5 \ 10))
mata: mata drop CX
di "(3) nwcontext stats: ok"

* ---------------------------------------------------------------- (4) nwcontext: modes, values, missing
nwclear
clear
set obs 3
gen double a = cond(_n == 1, 1, cond(_n == 2, 10, 100))
* directed 1 -> 2 -> 3
nwset, mat((0,1,0\0,0,1\0,0,0)) name(dp3) directed
nwcontext dp3, attribute(a) generate(mo)
xa mo[1] == 10 & mo[2] == 100 & mo[3] == .
nwcontext dp3, attribute(a) generate(mi) mode(incoming)
xa mi[1] == . & mi[2] == 1 & mi[3] == 10
* mode(either) on an undirected network: each neighbour once (help: "either send a tie to i or receive a tie
* from i").  SUSPECTED BUG: the code adds A' + A, so every undirected tie counts twice in sum and max.
nwset, mat((0,1,0\1,0,1\0,1,0)) name(p3) undirected
nwcontext p3, attribute(a) generate(se) stat(sum) mode(either)
xa se[2] == 101    // fixed: CONFIRMED BUG M11a
nwcontext p3, attribute(a) generate(xe) stat(max) mode(either)
xa xe[2] == 100    // fixed: CONFIRMED BUG M11a
nwcontext p3, attribute(a) generate(me) mode(either)
xa me[2] == 50.5
* the same with a reciprocated directed tie: 1 <-> 2, 2 -> 3; neighbours of 2 are {1, 3}
nwset, mat((0,1,0\1,0,1\0,0,0)) name(rec) directed
nwcontext rec, attribute(a) generate(sr) stat(sum) mode(either)
xa sr[2] == 101    // fixed: CONFIRMED BUG M11a
* the mean weights the reciprocated neighbour 1 twice: (2 x 1 + 100) / 3 instead of (1 + 100) / 2
nwcontext rec, attribute(a) generate(mr) mode(either)
xa mr[2] == 50.5    // fixed: CONFIRMED BUG M11a
* valued path 1-2 (2), 2-3 (4): the mean is weighted by default, (2 x 1 + 4 x 100) / 6 = 67
nwset, mat((0,2,0\2,0,4\0,4,0)) name(vp) undirected
nwcontext vp, attribute(a) generate(vm)
xa reldif(vm[2], 67) < 1e-9
nwcontext vp, attribute(a) generate(vmn) noweight
xa vmn[2] == 50.5
* a missing attribute value: the neighbour is left out; no neighbour left -> missing
gen double am = cond(_n == 2, ., a)
nwcontext p3, attribute(am) generate(mm)
xa mm[1] == . & mm[3] == .
xa mm[2] == 50.5
di "(4) nwcontext modes and values: ok"

* ---------------------------------------------------------------- (5) nwcontext: errors and user objects
nwclear
clear
set obs 3
gen double a = _n
nwset, mat((0,1,0\1,0,1\0,1,0)) name(p3) undirected
nwcontext p3, attribute(a) generate(c1)
capture nwcontext p3, attribute(a)
xa _rc == 198
capture nwcontext p3, attribute(a) generate(c2) stat(median)
xa _rc == 6556
capture nwcontext p3, attribute(a) generate(c2) mode(sideways)
xa _rc == 6556
capture nwcontext p3, attribute(a) generate(c1)
xa _rc == 110
nwcontext p3, attribute(a) generate(c1) replace stat(sum)
xa c1[2] == 4
* CONFIRMED BUG N4: confirm variable without exact (nwcontext.ado:34): c3long makes generate(c3) stop with r(99)
gen c3long = 1
capture noisily nwcontext p3, attribute(a) generate(c3x)
xa _rc == 0
drop c3x
capture noisily nwcontext p3, attribute(a) generate(c3)
xa _rc == 0    // fixed: CONFIRMED BUG N4
* (a plain `capture drop c3' here would itself drop c3long by abbreviation)
drop c3long
* SUSPECTED BUG: nwcontext.ado uses the plain Mata globals __attr, __context and __contextNet and drops them
mata: __attr = 42
mata: __context = 43
nwcontext p3, attribute(a) generate(c4)
xm assert(__attr == 42 & __context == 43)    // fixed: CONFIRMED BUG M11c
capture mata: mata drop __attr
capture mata: mata drop __context
di "(5) nwcontext errors: ok"

nwclear
xt_mend
di "ALL PASS"
