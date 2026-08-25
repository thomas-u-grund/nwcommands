cscript

do unw_ergm.do

* Certifies `istar2` (undirected 2-star count, sum_i C(deg(i),2)) - the
* deliberately minimal, clearly-marked DEMONSTRATION term in unw_ergm.do
* (see its own header comment there, and docs/ERGM_ARCHITECTURE.md's "How
* to add a new term" section, which this test is the worked example for).
* It exists purely to prove that a new term can be added and certified
* through the documented process WITHOUT touching ErgmModel, the MCMC
* sampler, the MPLE design builder, or ErgmMCMLE - none of those are
* referenced here beyond ErgmModel itself (needed only to register and
* combine terms), and none needed any change to add istar2.
*
* istar2 is NOT wired into nwergm.ado's real option surface (2-star
* family terms are a docs/ERGM_ROADMAP.md item, not v1 scope) - this test
* exercises unw_ergm.do's Mata layer directly, exactly like
* test_nwergm_statistics.do/changestat.do do for the real v1 terms.

mata:
mata set matastrict off

// --- exact hand-computable case: a 4-node undirected star (node 1
// connected to 2,3,4; nodes 2/3/4 mutually non-adjacent). Degrees:
// deg(1)=3, deg(2)=deg(3)=deg(4)=1. istar2 = C(3,2)+3*C(1,2) = 3+0 = 3.
G1 = ErgmGraph()
G1.init(4, 0)
G1.toggle(1,2)
G1.toggle(1,3)
G1.toggle(1,4)

td1 = ErgmTermData()
st1 = stat_istar2(G1, td1)
printf("star(4) istar2 statistic = %g (expect 3)\n", st1)
assert(reldif(st1, 3) < 1e-10)

// --- a triangle (3 nodes, all pairwise tied): deg=2 each,
// istar2 = 3*C(2,2) = 3*1 = 3.
G2 = ErgmGraph()
G2.init(3, 0)
G2.toggle(1,2)
G2.toggle(2,3)
G2.toggle(1,3)
td2 = ErgmTermData()
st2 = stat_istar2(G2, td2)
printf("triangle istar2 statistic = %g (expect 3)\n", st2)
assert(reldif(st2, 3) < 1e-10)

// --- change-statistic certification, via the SAME ErgmCertifyChangeStat()
// helper the real v1 terms are certified with, combined alongside two
// other already-certified terms (proving istar2 composes correctly
// inside a multi-term ErgmModel, not just in isolation) across several
// random small undirected networks.
void test_build_with_istar2(class ErgmModel M, real scalar n) {
	class ErgmTermData scalar td1, td2, td3
	real scalar i

	td1 = ErgmTermData()
	M.addterm("edges", 1, &stat_edges(), &change_edges(), td1, ("edges"))

	td2 = ErgmTermData()
	td2.decay = 0.6
	M.addterm("gwdegree", 1, &stat_gwdegree(), &change_gwdegree(), td2, ("gwdegree"))

	td3 = ErgmTermData()
	M.addterm("istar2", 1, &stat_istar2(), &change_istar2(), td3, ("istar2"))
}

void test_run_istar2(real scalar n, real scalar nedges, real scalar seed) {
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
	test_build_with_istar2(M, n)
	md = ErgmCertifyChangeStat(M, G)
	printf("istar2 combo n=%g nedges=%g seed=%g: max|change-fullrecompute|=%9.2e\n", n, nedges, seed, md)
	assert(md < 1e-8)
}

test_run_istar2(6, 8, 7001)
test_run_istar2(8, 12, 7002)
test_run_istar2(10, 16, 7003)
test_run_istar2(12, 22, 7004)
end
