cscript

do unw_ergm.do

/*
	Certifies term-expansion wave 6 (harmonisation unit 91 continuation,
	docs/CERTIFICATION.md - phase D): transitiveties/cyclicalties
	(directed only), built directly on wave 5's OTP shared-partner
	machinery. Same brute-force ErgmCertifyChangeStat() cross-check
	every existing term uses, PLUS a fully independent brute-force
	statistic recomputation (scanning every arc and every candidate k
	directly, with no reliance on shared_partners_otp() at all) to catch
	any error shared between the term's own statistic() and its
	dependency on OTP infrastructure.
*/

mata:
mata set matastrict off

void build_dir_net(class ErgmGraph G, real scalar n, real scalar p, real scalar seed) {
	real scalar i, j
	rseed(seed)
	G.init(n, 1)
	for (i=1; i<=n; i++) {
		for (j=1; j<=n; j++) {
			if (i==j) continue
			if (runiform(1,1) < p) G.toggle(i,j)
		}
	}
}

// fully independent brute-force recomputation of BOTH statistics,
// scanning every arc and every candidate k directly via has_edge() -
// no dependence whatsoever on shared_partners_otp().
real rowvector brute_ties(class ErgmGraph G, real scalar cyclical){
	real scalar i, j, k, n, tot, found
	n = G.n
	tot = 0
	for (i=1; i<=n; i++) {
		for (j=1; j<=n; j++) {
			if (i==j) continue
			if (!G.has_edge(i,j)) continue
			found = 0
			for (k=1; k<=n; k++) {
				if (k==i | k==j) continue
				if (!cyclical) {
					if (G.has_edge(i,k) & G.has_edge(k,j)) found = 1
				}
				else {
					if (G.has_edge(j,k) & G.has_edge(k,i)) found = 1
				}
			}
			tot = tot + found
		}
	}
	return(tot)
}

void test_ties_matches_bruteforce(){
	class ErgmGraph scalar G
	class ErgmTermData scalar td
	real scalar n, s_tt, s_ct, b_tt, b_ct

	n = 16
	G = ErgmGraph()
	build_dir_net(G, n, 0.22, 8401)
	td = ErgmTermData()
	s_tt = stat_transitiveties(G, td)[1]
	s_ct = stat_cyclicalties(G, td)[1]
	b_tt = brute_ties(G, 0)
	b_ct = brute_ties(G, 1)
	printf("test_ties_matches_bruteforce: tt=%g(brute %g) ct=%g(brute %g)\n", s_tt, b_tt, s_ct, b_ct)
	assert(s_tt == b_tt)
	assert(s_ct == b_ct)
	printf("test_ties_matches_bruteforce: OK\n")
}
test_ties_matches_bruteforce()

void test_transitiveties_changestat(){
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td
	real scalar n, md

	n = 14
	G = ErgmGraph()
	build_dir_net(G, n, 0.22, 8402)
	M = ErgmModel()
	M.init()
	td = ErgmTermData()
	M.addterm("transitiveties", 1, &stat_transitiveties(), &change_transitiveties(), td, ("transitiveties"))
	md = ErgmCertifyChangeStat(M, G)
	printf("test_transitiveties_changestat: max diff = %9.2e\n", md)
	assert(md < 1e-8)
	printf("test_transitiveties_changestat: OK\n")
}
test_transitiveties_changestat()

void test_cyclicalties_changestat(){
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td
	real scalar n, md

	n = 14
	G = ErgmGraph()
	build_dir_net(G, n, 0.22, 8403)
	M = ErgmModel()
	M.init()
	td = ErgmTermData()
	M.addterm("cyclicalties", 1, &stat_cyclicalties(), &change_cyclicalties(), td, ("cyclicalties"))
	md = ErgmCertifyChangeStat(M, G)
	printf("test_cyclicalties_changestat: max diff = %9.2e\n", md)
	assert(md < 1e-8)
	printf("test_cyclicalties_changestat: OK\n")
}
test_cyclicalties_changestat()

// --- combined model: both terms together (change stats must remain
//     correct in each other's presence - no shared mutable state) ---
void test_ties_combined(){
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td1, td2
	real scalar n, md

	n = 13
	G = ErgmGraph()
	build_dir_net(G, n, 0.25, 8404)
	M = ErgmModel()
	M.init()
	td1 = ErgmTermData()
	M.addterm("transitiveties", 1, &stat_transitiveties(), &change_transitiveties(), td1, ("transitiveties"))
	td2 = ErgmTermData()
	M.addterm("cyclicalties", 1, &stat_cyclicalties(), &change_cyclicalties(), td2, ("cyclicalties"))
	md = ErgmCertifyChangeStat(M, G)
	printf("test_ties_combined: max diff = %9.2e\n", md)
	assert(md < 1e-8)
	printf("test_ties_combined: OK\n")
}
test_ties_combined()

end
