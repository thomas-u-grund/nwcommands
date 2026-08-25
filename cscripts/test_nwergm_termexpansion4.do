cscript

do unw_ergm.do

/*
	Certifies term-expansion wave 4 (harmonisation unit 91 continuation,
	docs/CERTIFICATION.md - phase D): esp(d)/dsp(d), the fixed
	non-geometric shared-partner-count terms (undirected/UTP scope
	only, matching v1's existing GWESP/GWDSP). Same brute-force
	ErgmCertifyChangeStat() cross-check every existing term uses.
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

void test_esp(){
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td
	real scalar n, md

	n = 15
	G = ErgmGraph()
	build_net(G, n, 0.3, 0, 7201)
	M = ErgmModel()
	M.init()
	td = ErgmTermData()
	td.levels = (0\1\2)
	M.addterm("esp", 3, &stat_esp(), &change_esp(), td, ("esp0","esp1","esp2"))
	md = ErgmCertifyChangeStat(M, G)
	printf("test_esp: max diff = %9.2e\n", md)
	assert(md < 1e-8)
	printf("test_esp: OK\n")
}
test_esp()

void test_dsp(){
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td
	real scalar n, md

	n = 14
	G = ErgmGraph()
	build_net(G, n, 0.25, 0, 7202)
	M = ErgmModel()
	M.init()
	td = ErgmTermData()
	td.levels = (0\1\2\3)
	M.addterm("dsp", 4, &stat_dsp(), &change_dsp(), td, ("dsp0","dsp1","dsp2","dsp3"))
	md = ErgmCertifyChangeStat(M, G)
	printf("test_dsp: max diff = %9.2e\n", md)
	assert(md < 1e-8)
	printf("test_dsp: OK\n")
}
test_dsp()

// --- identity: sum over d of esp(d) must equal the total tie count
//     (every tied dyad has SOME shared-partner count, so partitioning
//     by exact count and summing back must recover the tie total) ---
void test_esp_sums_to_ties(){
	class ErgmGraph scalar G
	class ErgmTermData scalar td
	real scalar n, i, maxd
	real rowvector s

	n = 16
	G = ErgmGraph()
	build_net(G, n, 0.3, 0, 7203)
	maxd = n
	td = ErgmTermData()
	td.levels = J(maxd+1,1,0)
	for (i=0; i<=maxd; i++) td.levels[i+1] = i
	s = stat_esp(G, td)
	printf("test_esp_sums_to_ties: sum(esp)=%g ties=%g\n", sum(s), rows(G.all_ties()))
	assert(reldif(sum(s), rows(G.all_ties())) < 1e-8)
	printf("test_esp_sums_to_ties: OK\n")
}
test_esp_sums_to_ties()

// --- identity: dsp(d) summed over ALL d in [0,n-2] must equal the
//     total dyad count C(n,2) (every dyad has SOME shared-partner
//     count, tied or not) ---
void test_dsp_sums_to_dyads(){
	class ErgmGraph scalar G
	class ErgmTermData scalar td
	real scalar n, i, maxd
	real rowvector s

	n = 12
	G = ErgmGraph()
	build_net(G, n, 0.35, 0, 7204)
	maxd = n-2
	td = ErgmTermData()
	td.levels = J(maxd+1,1,0)
	for (i=0; i<=maxd; i++) td.levels[i+1] = i
	s = stat_dsp(G, td)
	printf("test_dsp_sums_to_dyads: sum(dsp)=%g dyads=%g\n", sum(s), n*(n-1)/2)
	assert(reldif(sum(s), n*(n-1)/2) < 1e-8)
	printf("test_dsp_sums_to_dyads: OK\n")
}
test_dsp_sums_to_dyads()

end
