cscript

do unw_ergm.do

/*
	Certifies term-expansion wave 7 (harmonisation unit 91 continuation,
	docs/CERTIFICATION.md - phase D): hamming(netname) (Hamming distance
	to a reference network) and sender()/receiver() (per-node out-/
	in-degree fixed effects, base=1 omitted, implemented as a THIN
	convenience wrapper around the already-certified stat_nodeofactor()/
	stat_nodeifactor() with the node's own identity as the "attribute" -
	no new Mata statistic/change functions needed for those two). Same
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

void test_hamming_undirected(){
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td
	real scalar n, i, j, md
	real matrix ref

	n = 14
	G = ErgmGraph()
	build_net(G, n, 0.25, 0, 8501)
	ref = J(n,n,0)
	rseed(9001)
	for (i=1; i<=n-1; i++) {
		for (j=i+1; j<=n; j++) {
			if (runiform(1,1) < 0.25) {
				ref[i,j] = 1
				ref[j,i] = 1
			}
		}
	}
	M = ErgmModel()
	M.init()
	td = ErgmTermData()
	td.edgecovmat = ref
	M.addterm("hamming", 1, &stat_hamming(), &change_hamming(), td, ("hamming"))
	md = ErgmCertifyChangeStat(M, G)
	printf("test_hamming_undirected: max diff = %9.2e\n", md)
	assert(md < 1e-8)
	printf("test_hamming_undirected: OK\n")
}
test_hamming_undirected()

void test_hamming_directed(){
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td
	real scalar n, i, j, md
	real matrix ref

	n = 13
	G = ErgmGraph()
	build_net(G, n, 0.2, 1, 8502)
	ref = J(n,n,0)
	rseed(9002)
	for (i=1; i<=n; i++) {
		for (j=1; j<=n; j++) {
			if (i==j) continue
			if (runiform(1,1) < 0.2) ref[i,j] = 1
		}
	}
	M = ErgmModel()
	M.init()
	td = ErgmTermData()
	td.edgecovmat = ref
	M.addterm("hamming", 1, &stat_hamming(), &change_hamming(), td, ("hamming"))
	md = ErgmCertifyChangeStat(M, G)
	printf("test_hamming_directed: max diff = %9.2e\n", md)
	assert(md < 1e-8)
	printf("test_hamming_directed: OK\n")
}
test_hamming_directed()

// --- identity: hamming distance to G ITSELF (the reference network
//     equal to G's own current tie state) must be exactly 0 ---
void test_hamming_self_is_zero(){
	class ErgmGraph scalar G
	class ErgmTermData scalar td
	real scalar n, dist

	n = 12
	G = ErgmGraph()
	build_net(G, n, 0.3, 0, 8503)
	td = ErgmTermData()
	td.edgecovmat = G.to_dense()
	dist = stat_hamming(G, td)[1]
	printf("test_hamming_self_is_zero: dist=%g\n", dist)
	assert(dist == 0)
	printf("test_hamming_self_is_zero: OK\n")
}
test_hamming_self_is_zero()

void test_sender_matches_nodeofactor(){
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td
	real scalar n, md

	n = 12
	G = ErgmGraph()
	build_net(G, n, 0.25, 1, 8504)
	M = ErgmModel()
	M.init()
	td = ErgmTermData()
	td.attr = (1::n)
	td.levels = (2::n)
	M.addterm("sender", n-1, &stat_nodeofactor(), &change_nodeofactor(), td, ("sender"))
	md = ErgmCertifyChangeStat(M, G)
	printf("test_sender_matches_nodeofactor: max diff = %9.2e\n", md)
	assert(md < 1e-8)
	printf("test_sender_matches_nodeofactor: OK\n")
}
test_sender_matches_nodeofactor()

void test_receiver_matches_nif(){
	class ErgmGraph scalar G
	class ErgmModel scalar M
	class ErgmTermData scalar td
	real scalar n, md

	n = 12
	G = ErgmGraph()
	build_net(G, n, 0.25, 1, 8505)
	M = ErgmModel()
	M.init()
	td = ErgmTermData()
	td.attr = (1::n)
	td.levels = (2::n)
	M.addterm("receiver", n-1, &stat_nodeifactor(), &change_nodeifactor(), td, ("receiver"))
	md = ErgmCertifyChangeStat(M, G)
	printf("test_receiver_matches_nif: max diff = %9.2e\n", md)
	assert(md < 1e-8)
	printf("test_receiver_matches_nif: OK\n")
}
test_receiver_matches_nif()

// --- identity: sum of sender_k over all included nodes (2..n) equals
//     total arc count MINUS node 1's own out-degree (node 1's own
//     out-degree is the omitted base level) ---
void test_sender_sums_minus_base(){
	class ErgmGraph scalar G
	class ErgmTermData scalar td
	real scalar n
	real rowvector s

	n = 15
	G = ErgmGraph()
	build_net(G, n, 0.2, 1, 8506)
	td = ErgmTermData()
	td.attr = (1::n)
	td.levels = (2::n)
	s = stat_nodeofactor(G, td)
	printf("test_sender_sums_minus_base: sum=%g arcs-base1out=%g\n", sum(s), rows(G.all_ties()) - G.degree_out(1))
	assert(reldif(sum(s), rows(G.all_ties()) - G.degree_out(1)) < 1e-8)
	printf("test_sender_sums_minus_base: OK\n")
}
test_sender_sums_minus_base()

end
