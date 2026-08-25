cscript

do unw_ergm.do

/*
	Certifies term-expansion wave 5 (harmonisation unit 91 continuation,
	docs/CERTIFICATION.md - phase D): the directed "outgoing two-path"
	(OTP) shared-partner definition for gwesp/gwdsp/gwnsp/esp/dsp
	(td.sptype == "OTP"), R ergm's own default `type=' for directed
	shared-partner terms. Same brute-force ErgmCertifyChangeStat()
	cross-check every existing term uses, PLUS a direct comparison of
	shared_partners_otp() against a slow, obviously-correct O(n) brute-
	force definition (independent of ErgmGraph's own neighbor-list
	machinery), and the same "sums to a known total" identities wave 4
	used for the undirected esp/dsp.
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

// brute-force OTP count, independent of ErgmGraph's own neighbor lists -
// scans every possible k directly against has_edge().
real scalar brute_otp(class ErgmGraph G, real scalar i, real scalar j){
	real scalar k, cnt
	cnt = 0
	for (k=1; k<=G.n; k++) {
		if (k==i | k==j) continue
		if (G.has_edge(i,k) & G.has_edge(k,j)) cnt++
	}
	return(cnt)
}

void test_otp_matches_bruteforce(){
	class ErgmGraph scalar G
	real scalar n, i, j, maxdiff, d

	n = 18
	G = ErgmGraph()
	build_dir_net(G, n, 0.25, 8301)
	maxdiff = 0
	for (i=1; i<=n; i++) {
		for (j=1; j<=n; j++) {
			if (i==j) continue
			d = abs(G.shared_partners_otp(i,j) - brute_otp(G,i,j))
			if (d > maxdiff) maxdiff = d
		}
	}
	printf("test_otp_matches_bruteforce: maxdiff=%g\n", maxdiff)
	assert(maxdiff == 0)
	printf("test_otp_matches_bruteforce: OK\n")
}
test_otp_matches_bruteforce()

void test_gwesp_otp(){
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td
	real scalar n, md

	n = 14
	G = ErgmGraph()
	build_dir_net(G, n, 0.2, 8302)
	M = ErgmModel()
	M.init()
	td = ErgmTermData()
	td.decay = 0.6
	td.sptype = "OTP"
	M.addterm("gwesp", 1, &stat_gwesp(), &change_gwesp(), td, ("gwesp"))
	md = ErgmCertifyChangeStat(M, G)
	printf("test_gwesp_otp: max diff = %9.2e\n", md)
	assert(md < 1e-6)
	printf("test_gwesp_otp: OK\n")
}
test_gwesp_otp()

void test_gwdsp_otp(){
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td
	real scalar n, md

	n = 13
	G = ErgmGraph()
	build_dir_net(G, n, 0.25, 8303)
	M = ErgmModel()
	M.init()
	td = ErgmTermData()
	td.decay = 0.5
	td.sptype = "OTP"
	M.addterm("gwdsp", 1, &stat_gwdsp(), &change_gwdsp(), td, ("gwdsp"))
	md = ErgmCertifyChangeStat(M, G)
	printf("test_gwdsp_otp: max diff = %9.2e\n", md)
	assert(md < 1e-6)
	printf("test_gwdsp_otp: OK\n")
}
test_gwdsp_otp()

void test_gwnsp_otp(){
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td
	real scalar n, md

	n = 13
	G = ErgmGraph()
	build_dir_net(G, n, 0.22, 8304)
	M = ErgmModel()
	M.init()
	td = ErgmTermData()
	td.decay = 0.55
	td.sptype = "OTP"
	M.addterm("gwnsp", 1, &stat_gwnsp(), &change_gwnsp(), td, ("gwnsp"))
	md = ErgmCertifyChangeStat(M, G)
	printf("test_gwnsp_otp: max diff = %9.2e\n", md)
	assert(md < 1e-6)
	printf("test_gwnsp_otp: OK\n")
}
test_gwnsp_otp()

void test_esp_otp(){
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td
	real scalar n, md

	n = 14
	G = ErgmGraph()
	build_dir_net(G, n, 0.25, 8305)
	M = ErgmModel()
	M.init()
	td = ErgmTermData()
	td.levels = (0\1\2)
	td.sptype = "OTP"
	M.addterm("esp", 3, &stat_esp(), &change_esp(), td, ("esp0","esp1","esp2"))
	md = ErgmCertifyChangeStat(M, G)
	printf("test_esp_otp: max diff = %9.2e\n", md)
	assert(md < 1e-8)
	printf("test_esp_otp: OK\n")
}
test_esp_otp()

void test_dsp_otp(){
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td
	real scalar n, md

	n = 13
	G = ErgmGraph()
	build_dir_net(G, n, 0.2, 8306)
	M = ErgmModel()
	M.init()
	td = ErgmTermData()
	td.levels = (1)
	td.sptype = "OTP"
	M.addterm("dsp", 1, &stat_dsp(), &change_dsp(), td, ("dsp1"))
	md = ErgmCertifyChangeStat(M, G)
	printf("test_dsp_otp: max diff = %9.2e\n", md)
	assert(md < 1e-8)
	printf("test_dsp_otp: OK\n")
}
test_dsp_otp()

// --- identity: sum over d of esp_otp(d) must equal the ARC count
//     (every existing arc has some OTP shared-partner count) ---
void test_esp_otp_sums_to_arcs(){
	class ErgmGraph scalar G
	class ErgmTermData scalar td
	real scalar n, i, maxd
	real rowvector s

	n = 15
	G = ErgmGraph()
	build_dir_net(G, n, 0.3, 8307)
	maxd = n
	td = ErgmTermData()
	td.levels = J(maxd+1,1,0)
	for (i=0; i<=maxd; i++) td.levels[i+1] = i
	td.sptype = "OTP"
	s = stat_esp(G, td)
	printf("test_esp_otp_sums_to_arcs: sum(esp)=%g arcs=%g\n", sum(s), rows(G.all_ties()))
	assert(reldif(sum(s), rows(G.all_ties())) < 1e-8)
	printf("test_esp_otp_sums_to_arcs: OK\n")
}
test_esp_otp_sums_to_arcs()

// --- identity: sum over d of dsp_otp(d) must equal n*(n-1), the total
//     number of ORDERED pairs (every ordered pair has some OTP count,
//     tied or not) ---
void test_dsp_otp_sums_to_pairs(){
	class ErgmGraph scalar G
	class ErgmTermData scalar td
	real scalar n, i, maxd
	real rowvector s

	n = 11
	G = ErgmGraph()
	build_dir_net(G, n, 0.3, 8308)
	maxd = n-2
	td = ErgmTermData()
	td.levels = J(maxd+1,1,0)
	for (i=0; i<=maxd; i++) td.levels[i+1] = i
	td.sptype = "OTP"
	s = stat_dsp(G, td)
	printf("test_dsp_otp_sums_to_pairs: sum(dsp)=%g pairs=%g\n", sum(s), n*(n-1))
	assert(reldif(sum(s), n*(n-1)) < 1e-8)
	printf("test_dsp_otp_sums_to_pairs: OK\n")
}
test_dsp_otp_sums_to_pairs()

end
