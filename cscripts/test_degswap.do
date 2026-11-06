* Degree-preserving null models of one-mode networks (native kernel 55, nwcommands 3.17.0):
* nwpermute, swap; nwcug, condition(degrees); nwrandom, degree() / outdegree() indegree().
* Reference values from R igraph 2.3.2 (rewire(g, keeping_degseq()), sample_degseq(method = "edge.switching.simple")).
* Run from the core folder.
cscript
clear all

* 1. nwpermute, swap: degrees kept, network changed (directed and undirected), values move with the ties
nwuse data/glasgow, nwclear
set seed 1
nwpermute glasgow1, swap generate(g1s)
qui nwdegree glasgow1, generate(o1 i1)
qui nwdegree g1s, generate(o2 i2)
assert o1 == o2 & i1 == i2
qui nwcorrelate glasgow1 g1s
assert r(corr) < 0.5
di "PASS nwpermute, swap on a directed network keeps out- and in-degrees"
nwuse data/florentine, nwclear
set seed 2
nwpermute flomarriage, swap generate(fs) swaps(5000)
qui nwdegree flomarriage, generate(d1)
qui nwdegree fs, generate(d2)
assert d1 == d2
nwissymmetric fs
di "PASS nwpermute, swap on an undirected network keeps the degrees"
* valued: the values are carried along
nwrandom 30, prob(.2) name(v) undirected weights(.3, .3, .4)
nwtomata v, mat(__v1)
nwpermute v, swap generate(vs)
nwtomata vs, mat(__v2)
mata: _editmissing(__v1, 0)
mata: _editmissing(__v2, 0)
mata: st_local("same", strofreal(sort(select(vec(__v1), vec(__v1) :!= 0), 1) == sort(select(vec(__v2), vec(__v2) :!= 0), 1)))
assert "`same'" == "1"
mata: mata drop __v1 __v2
di "PASS nwpermute, swap keeps the tie values"
* the same seed gives the same network
set seed 5
nwpermute flomarriage, swap generate(r1)
set seed 5
nwpermute flomarriage, swap generate(r2)
qui nwcorrelate r1 r2
assert reldif(r(corr), 1) < 1e-12
di "PASS set seed makes nwpermute, swap reproducible"

* 2. nwcug, condition(degrees) on a one-mode network: global clustering of the Florentine marriages,
*    igraph rewire chain: mean 0.162, sd 0.077 (4,000 draws)
nwuse data/florentine, nwclear
nwcug flomarriage, stat(nwclustering ##net##, generate(cc) replace) rname(cluster_global) condition(degrees) reps(2000) seed(3) silent
di r(mean_null) " " r(sd_null)
assert abs(r(mean_null) - 0.162) < 0.012
assert abs(r(sd_null) - 0.077) < 0.010
di "PASS nwcug, condition(degrees), undirected, agrees with igraph"
nwuse data/glasgow, nwclear
nwcug glasgow1, stat(nwdyads ##net##) rname(_100) condition(degrees) reps(500) seed(3) silent
assert r(obs) == 39
assert r(mean_null) > 2 & r(mean_null) < 5.5
di "PASS nwcug, condition(degrees), directed"
capture noisily nwcug glasgow1, stat(nwdyads ##net##) rname(_100) condition(mode1degree) reps(10)
assert _rc == 198
di "PASS mode1degree still refused for a one-mode network"

* 3. nwrandom from a degree sequence
set seed 7
nwrandom 8, degree(3 3 2 2 2 2 1 1) name(dd)
qui nwdegree dd, generate(dg)
assert dg[1] == 3 & dg[2] == 3 & dg[3] == 2 & dg[6] == 2 & dg[7] == 1 & dg[8] == 1
nwissymmetric dd
di "PASS nwrandom, degree() (list)"
capture noisily nwrandom 3, degree(1 1 1) name(bad)
assert _rc == 198
capture noisily nwrandom 4, degree(3 3 1 1) name(bad)
assert _rc == 198
capture noisily nwrandom 4, degree(1 1 1) name(bad)
assert _rc == 198
capture noisily nwrandom 3, outdegree(2 0 0) indegree(1 1 0) name(bad)
assert _rc == 198
capture noisily nwrandom 3, outdegree(1 1 1) name(bad)
assert _rc == 198
capture noisily nwrandom 3, degree(1 1 0) prob(.5) name(bad)
assert _rc == 198
capture noisily nwrandom 3, degree(1 1 0) directed name(bad)
assert _rc == 198
di "PASS impossible or conflicting degree() requests are refused"
nwuse data/glasgow, nwclear
qui nwdegree glasgow1, generate(od id)
set seed 9
nwrandom 50, outdegree(od) indegree(id) name(gd)
qui nwdegree gd, generate(od2 id2)
assert od == od2 & id == id2
di "PASS nwrandom, outdegree() indegree() (variables)"
nwrandom 50, outdegree(od) indegree(id) name(gr) ntimes(3)
assert "`r(netlist)'" == "gr_1 gr_2 gr_3"
di "PASS nwrandom, ntimes() with degrees"
* the Florentine degrees: global clustering 0.163 (sd 0.075) over sample_degseq draws in igraph
nwuse data/florentine, nwclear
qui nwdegree flomarriage, generate(d)
set seed 99
mata: __t = J(600, 1, .)
forvalues i = 1/600 {
	qui nwrandom 16, degree(d) name(fx) xvars
	qui nwclustering fx, generate(cc) replace
	mata: __t[`i'] = `r(cluster_global)'
	qui nwdrop fx
}
mata: st_local("m", strofreal(mean(__t)))
mata: mata drop __t
di "mean clustering `m'"
assert abs(`m' - 0.163) < 0.015
di "PASS nwrandom, degree() agrees with igraph sample_degseq"
