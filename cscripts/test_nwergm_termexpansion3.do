cscript

do unw_ergm.do

/*
	Certifies term-expansion wave 3 (harmonisation unit 91,
	docs/CERTIFICATION.md - phase D): nodeifactor, nodeofactor,
	kstar(k)/istar(k)/ostar(k), degrange/idegrange/odegrange. Same
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

void test_nodeofactor_nodeifactor(){
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar tdo, tdi
	real colvector attr
	real scalar n, i, md

	n = 14
	G = ErgmGraph()
	build_net(G, n, 0.2, 1, 7101)
	attr = J(n,1,0)
	for (i=1; i<=n; i++) attr[i] = mod(i,3)+1

	M = ErgmModel()
	M.init()
	tdo = ErgmTermData()
	tdo.attr = attr
	tdo.levels = (1\2\3)
	M.addterm("nodeofactor", 3, &stat_nodeofactor(), &change_nodeofactor(), tdo, ("of1","of2","of3"))
	tdi = ErgmTermData()
	tdi.attr = attr
	tdi.levels = (1\2\3)
	M.addterm("nodeifactor", 3, &stat_nodeifactor(), &change_nodeifactor(), tdi, ("if1","if2","if3"))
	md = ErgmCertifyChangeStat(M, G)
	printf("test_nodeofactor_nodeifactor: max diff = %9.2e\n", md)
	assert(md < 1e-8)
	printf("test_nodeofactor_nodeifactor: OK\n")
}
test_nodeofactor_nodeifactor()

void test_kstar(){
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td
	real scalar n, md

	n = 13
	G = ErgmGraph()
	build_net(G, n, 0.3, 0, 7102)
	M = ErgmModel()
	M.init()
	td = ErgmTermData()
	td.levels = (2\3\4)
	M.addterm("kstar", 3, &stat_kstar(), &change_kstar(), td, ("k2","k3","k4"))
	md = ErgmCertifyChangeStat(M, G)
	printf("test_kstar: max diff = %9.2e\n", md)
	assert(md < 1e-8)
	printf("test_kstar: OK\n")
}
test_kstar()

void test_ostar_istar(){
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar tdo, tdi
	real scalar n, md

	n = 13
	G = ErgmGraph()
	build_net(G, n, 0.25, 1, 7103)
	M = ErgmModel()
	M.init()
	tdo = ErgmTermData()
	tdo.levels = (2\3)
	M.addterm("ostar", 2, &stat_ostar(), &change_ostar(), tdo, ("os2","os3"))
	tdi = ErgmTermData()
	tdi.levels = (2\3)
	M.addterm("istar", 2, &stat_istar(), &change_istar(), tdi, ("is2","is3"))
	md = ErgmCertifyChangeStat(M, G)
	printf("test_ostar_istar: max diff = %9.2e\n", md)
	assert(md < 1e-8)
	printf("test_ostar_istar: OK\n")
}
test_ostar_istar()

void test_degrange(){
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td
	real scalar n, md

	n = 14
	G = ErgmGraph()
	build_net(G, n, 0.25, 0, 7104)
	M = ErgmModel()
	M.init()
	td = ErgmTermData()
	td.levelpairs = (0,2 \ 2,4 \ 4,.)
	M.addterm("degrange", 3, &stat_degrange(), &change_degrange(), td, ("dr1","dr2","dr3"))
	md = ErgmCertifyChangeStat(M, G)
	printf("test_degrange: max diff = %9.2e\n", md)
	assert(md < 1e-8)
	printf("test_degrange: OK\n")
}
test_degrange()

void test_odegrange_idegrange(){
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar tdo, tdi
	real scalar n, md

	n = 13
	G = ErgmGraph()
	build_net(G, n, 0.2, 1, 7105)
	M = ErgmModel()
	M.init()
	tdo = ErgmTermData()
	tdo.levelpairs = (0,1 \ 1,.)
	M.addterm("odegrange", 2, &stat_odegrange(), &change_odegrange(), tdo, ("odr1","odr2"))
	tdi = ErgmTermData()
	tdi.levelpairs = (0,1 \ 1,.)
	M.addterm("idegrange", 2, &stat_idegrange(), &change_idegrange(), tdi, ("idr1","idr2"))
	md = ErgmCertifyChangeStat(M, G)
	printf("test_odegrange_idegrange: max diff = %9.2e\n", md)
	assert(md < 1e-8)
	printf("test_odegrange_idegrange: OK\n")
}
test_odegrange_idegrange()

// --- sanity: kstar(2) must equal 2*istar2 (the demo term) exactly,
//     since both count 2-stars, just via different code paths ---
void test_kstar2_matches_istar2(){
	class ErgmGraph scalar G
	class ErgmTermData scalar td
	real scalar n, s_kstar2, s_istar2

	n = 20
	G = ErgmGraph()
	build_net(G, n, 0.15, 0, 7106)
	td = ErgmTermData()
	td.levels = (2)
	s_kstar2 = stat_kstar(G, td)[1]
	s_istar2 = stat_istar2(G, td)
	printf("test_kstar2_matches_istar2: kstar(2)=%9.4f istar2=%9.4f\n", s_kstar2, s_istar2)
	assert(reldif(s_kstar2, s_istar2) < 1e-8)
	printf("test_kstar2_matches_istar2: OK\n")
}
test_kstar2_matches_istar2()

end
