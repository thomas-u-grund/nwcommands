cscript

do unw_ergm.do

/*
	Certifies term-expansion wave 2 (harmonisation unit 90,
	docs/CERTIFICATION.md - phase D, continuation of unit 88): degree(d),
	odegree(d), idegree(d), concurrent, triangle, ctriple, gwnsp. Same
	brute-force ErgmCertifyChangeStat() cross-check every existing term
	uses.
*/

mata:
mata set matastrict off

void build_net(class ErgmGraph G, real scalar n, real scalar p, real scalar directed, real scalar seed) {
	real scalar i, j
	rseed(seed)
	G.init(n, directed)
	for (i=1; i<=n; i++) {
		for (j=1; j<=n; j++) {
			if (i==j) continue
			if (!directed & j<i) continue
			if (runiform(1,1) < p) G.toggle(i,j)
		}
	}
}

void test_degree(){
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td
	real scalar n, md

	n = 14
	G = ErgmGraph()
	build_net(G, n, 0.2, 0, 6101)
	M = ErgmModel()
	M.init()
	td = ErgmTermData()
	td.levels = (0\1\2\3\4)
	M.addterm("degree", 5, &stat_degree(), &change_degree(), td, ("d0","d1","d2","d3","d4"))
	md = ErgmCertifyChangeStat(M, G)
	printf("test_degree: max diff = %9.2e\n", md)
	assert(md < 1e-8)
	printf("test_degree: OK\n")
}
test_degree()

void test_odegree_idegree(){
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar tdo, tdi
	real scalar n, md

	n = 13
	G = ErgmGraph()
	build_net(G, n, 0.2, 1, 6102)
	M = ErgmModel()
	M.init()
	tdo = ErgmTermData()
	tdo.levels = (0\1\2\3)
	M.addterm("odegree", 4, &stat_odegree(), &change_odegree(), tdo, ("od0","od1","od2","od3"))
	tdi = ErgmTermData()
	tdi.levels = (0\1\2\3)
	M.addterm("idegree", 4, &stat_idegree(), &change_idegree(), tdi, ("id0","id1","id2","id3"))
	md = ErgmCertifyChangeStat(M, G)
	printf("test_odegree_idegree: max diff = %9.2e\n", md)
	assert(md < 1e-8)
	printf("test_odegree_idegree: OK\n")
}
test_odegree_idegree()

void test_concurrent(){
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td
	real scalar n, md

	n = 15
	G = ErgmGraph()
	build_net(G, n, 0.15, 0, 6103)
	M = ErgmModel()
	M.init()
	td = ErgmTermData()
	M.addterm("concurrent", 1, &stat_concurrent(), &change_concurrent(), td, ("concurrent"))
	md = ErgmCertifyChangeStat(M, G)
	printf("test_concurrent: max diff = %9.2e\n", md)
	assert(md < 1e-8)
	printf("test_concurrent: OK\n")
}
test_concurrent()

void test_triangle(){
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td
	real scalar n, md

	n = 12
	G = ErgmGraph()
	build_net(G, n, 0.3, 0, 6104)
	M = ErgmModel()
	M.init()
	td = ErgmTermData()
	M.addterm("triangle", 1, &stat_triangle(), &change_triangle(), td, ("triangle"))
	md = ErgmCertifyChangeStat(M, G)
	printf("test_triangle: max diff = %9.2e\n", md)
	assert(md < 1e-8)
	printf("test_triangle: OK\n")
}
test_triangle()

void test_ctriple(){
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td
	real scalar n, md

	n = 12
	G = ErgmGraph()
	build_net(G, n, 0.25, 1, 6105)
	M = ErgmModel()
	M.init()
	td = ErgmTermData()
	M.addterm("ctriple", 1, &stat_ctriple(), &change_ctriple(), td, ("ctriple"))
	md = ErgmCertifyChangeStat(M, G)
	printf("test_ctriple: max diff = %9.2e\n", md)
	assert(md < 1e-8)
	printf("test_ctriple: OK\n")
}
test_ctriple()

void test_gwnsp(){
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td
	real scalar n, md

	n = 12
	G = ErgmGraph()
	build_net(G, n, 0.25, 0, 6106)
	M = ErgmModel()
	M.init()
	td = ErgmTermData()
	td.decay = 0.5
	M.addterm("gwnsp", 1, &stat_gwnsp(), &change_gwnsp(), td, ("gwnsp_0.5"))
	md = ErgmCertifyChangeStat(M, G)
	printf("test_gwnsp: max diff = %9.2e\n", md)
	assert(md < 1e-8)
	printf("test_gwnsp: OK\n")
}
test_gwnsp()

// --- direct check of the gwdsp = gwesp + gwnsp identity itself, not
//     just each term's own change-statistic correctness ---
void test_gwnsp_identity(){
	class ErgmGraph scalar G
	class ErgmTermData scalar td
	real scalar n, s_esp, s_dsp, s_nsp

	n = 20
	G = ErgmGraph()
	build_net(G, n, 0.2, 0, 6107)
	td = ErgmTermData()
	td.decay = 0.4

	s_esp = stat_gwesp(G, td)
	s_dsp = stat_gwdsp(G, td)
	s_nsp = stat_gwnsp(G, td)
	printf("test_gwnsp_identity: gwesp=%9.4f gwdsp=%9.4f gwnsp=%9.4f gwesp+gwnsp=%9.4f\n", s_esp, s_dsp, s_nsp, s_esp+s_nsp)
	assert(reldif(s_dsp, s_esp + s_nsp) < 1e-8)
	printf("test_gwnsp_identity: OK\n")
}
test_gwnsp_identity()

end
