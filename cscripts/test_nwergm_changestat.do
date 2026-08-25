cscript

do unw_ergm.do

* Certifies unw_ergm.do's change() implementations for all 8 v1 terms
* against brute-force full recomputation (statistic(after) -
* statistic(before)), via the built-in ErgmCertifyChangeStat() helper -
* the permanent certification methodology this package's own ERGM
* engine relies on before any MCMC/estimation code is trusted to consume
* a term's change() (see docs/ERGM_ARCHITECTURE.md's "Term API" section).
* Run across several random directed/undirected small networks and two
* full model specifications (all 6 undirected-compatible terms together;
* all 5 directed-only-relevant terms together) so every term is checked
* in combination with the others, not just in isolation.

mata:
mata set matastrict off

void test_build_undirected(class ErgmModel M, real scalar n) {
	class ErgmTermData scalar td1, td2, td3, td4, td5, td6
	real scalar i

	td1 = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), td1, ("edges"))

	td2 = ErgmTermData()
	td2.attr = J(n,1,0)
	for (i=1; i<=n; i++) td2.attr[i] = mod(i,3)
	M.addterm("nodematch", 1, &stat_nodematch(), &change_nodematch(), td2, ("nodematch"))

	td3 = ErgmTermData()
	td3.attr = J(n,1,0)
	for (i=1; i<=n; i++) td3.attr[i] = i*1.3 - 2
	M.addterm("nodecov", 1, &stat_nodecov(), &change_nodecov(), td3, ("nodecov"))

	td4 = ErgmTermData()
	td4.edgecovmat = J(n,n,0)
	for (i=1; i<=n; i++) td4.edgecovmat[i,.] = (1..n) :* (i/2)
	M.addterm("edgecov", 1, &stat_edgecov(), &change_edgecov(), td4, ("edgecov"))

	td5 = ErgmTermData()
	td5.decay = 0.6
	M.addterm("gwesp", 1, &stat_gwesp(), &change_gwesp(), td5, ("gwesp"))

	td6 = ErgmTermData()
	td6.decay = 0.7
	M.addterm("gwdegree", 1, &stat_gwdegree(), &change_gwdegree(), td6, ("gwdegree"))
}

void test_build_directed(class ErgmModel M, real scalar n) {
	class ErgmTermData scalar td1, td2, td3, td4, td5, td6
	real scalar i

	td1 = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), td1, ("edges"))

	td2 = ErgmTermData()
	M.addterm("mutual", 1, &stat_mutual(), &change_mutual(), td2, ("mutual"))

	td3 = ErgmTermData()
	td3.attr = J(n,1,0)
	for (i=1; i<=n; i++) td3.attr[i] = mod(i,3)
	M.addterm("nodematch", 1, &stat_nodematch(), &change_nodematch(), td3, ("nodematch"))

	td4 = ErgmTermData()
	td4.attr = J(n,1,0)
	for (i=1; i<=n; i++) td4.attr[i] = i*0.7 + 1
	M.addterm("nodeocov", 1, &stat_nodeocov(), &change_nodeocov(), td4, ("nodeocov"))

	td5 = ErgmTermData()
	td5.attr = td4.attr
	M.addterm("nodeicov", 1, &stat_nodeicov(), &change_nodeicov(), td5, ("nodeicov"))

	td6 = ErgmTermData()
	td6.decay = 0.5
	M.addterm("gwodegree", 1, &stat_gwodegree(), &change_gwodegree(), td6, ("gwodegree"))
}

void test_run_undirected(real scalar n, real scalar nedges, real scalar seed) {
	class ErgmGraph scalar G
	class ErgmModel scalar M
	real scalar t, i, j, md

	rseed(seed)
	G = ErgmGraph()
	G.init(n, 0)
	for (t=1; t<=nedges; t++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i!=j & !G.has_edge(i,j)) G.toggle(i,j)
	}
	M = ErgmModel()
	M.init()
	test_build_undirected(M, n)
	md = ErgmCertifyChangeStat(M, G)
	printf("undirected n=%g nedges=%g seed=%g: max|change-fullrecompute|=%9.2e\n", n, nedges, seed, md)
	assert(md < 1e-8)
}

void test_run_directed(real scalar n, real scalar nedges, real scalar seed) {
	class ErgmGraph scalar G
	class ErgmModel scalar M
	real scalar t, i, j, md

	rseed(seed)
	G = ErgmGraph()
	G.init(n, 1)
	for (t=1; t<=nedges; t++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i!=j & !G.has_edge(i,j)) G.toggle(i,j)
	}
	M = ErgmModel()
	M.init()
	test_build_directed(M, n)
	md = ErgmCertifyChangeStat(M, G)
	printf("directed n=%g nedges=%g seed=%g: max|change-fullrecompute|=%9.2e\n", n, nedges, seed, md)
	assert(md < 1e-8)
}

test_run_undirected(6, 8, 5001)
test_run_undirected(8, 12, 5002)
test_run_undirected(10, 15, 5003)
test_run_undirected(12, 20, 5004)
test_run_directed(6, 10, 6001)
test_run_directed(8, 15, 6002)
test_run_directed(10, 18, 6003)
end
