cscript

do unw_core.do
nwclear
nwrandom 5, prob(1) name(mynet1)
nwevcent, generate(myev)
assert round(myev[1],0.001) == .447

nwclear
nwrandom 5, prob(0) name(mynet2)
nwevcent, generate(myev)
assert myev[1] == .


* --- weighted option
* Star network A tied to B,C,D with weights 1,1,10. Unweighted
* (dichotomized) eigenvector centrality treats B,C,D identically (all
* just "tied to A"); weighted centrality should make D (the heavily
* weighted leaf) clearly dominate B and C.
nwclear
nwset, mat((0,1,1,10\1,0,0,0\1,0,0,0\10,0,0,0)) name(starw) undirected labs(A,B,C,D)

nwevcent starw, generate(ev_unw)
assert reldif(ev_unw[2], ev_unw[3]) < 1E-6
assert reldif(ev_unw[2], ev_unw[4]) < 1E-6

nwevcent starw, generate(ev_w) weighted
assert reldif(ev_w[2], ev_w[3]) < 1E-6
assert ev_w[4] > ev_w[2] * 5

* weighted has no effect on an unvalued network
nwclear
nwset, mat((0,1,1,1\1,0,0,0\1,0,0,0\1,0,0,0)) name(starunval) undirected labs(A,B,C,D)
nwevcent starunval, generate(ev_a)
nwevcent starunval, generate(ev_b) weighted
mata: assert(max(abs(st_data(.,"ev_a") - st_data(.,"ev_b"))) < 1E-8)


* --- eigenvalue-search bugfix regression: K5 complete graph, all nodes
* must get an identical, correctly-nonzero eigenvector centrality score
* (the pre-fix search loop only ever checked the first eigenvalue slot;
* this happened to still work for every case above since Mata's
* symeigensystem() sorts descending, but this K5 case exercises the
* search logic directly as a permanent regression guard)
nwclear
nwset, mat((0,1,1,1,1\1,0,1,1,1\1,1,0,1,1\1,1,1,0,1\1,1,1,1,0)) name(k5net) undirected labs(A,B,C,D,E)
nwevcent k5net, generate(ev_k5)
forvalues i = 1/5 {
	assert reldif(ev_k5[`i'], ev_k5[1]) < 1E-6
}
assert ev_k5[1] > 0.4

* moderate-severity pass, centrality group: the "already exists" guard
* used a bare exit (no return code) - the message printed but rc stayed
* 0, so a caller checking _rc after a failed call incorrectly believed
* it succeeded.
capture noisily nwevcent k5net, generate(ev_k5)
assert _rc == 99
di "=== error-code coherence REGRESSION VERIFIED ==="
