cscript

do unw_ergm.do

* Certifies ErgmGraph's incremental shared-partner cache
* (enable_sp_cache()/sp_adjust()/shared_partners() - Part XXV performance
* work, docs/CERTIFICATION.md harmonisation unit 82). NOT currently wired
* into nwergm.ado by default (see that file's own gwesp block for the
* full, measured account of why: a real head-to-head benchmark found it
* makes nwergm's own realistic sparse-network GWESP benchmarks SLOWER,
* not faster - TNT's own acceptance rate on a fitted model is very high,
* so toggle()'s own cache-maintenance cost dominates the cheaper lookup
* at low degree; only nets a win around degree ~30-40+). The machinery
* itself is fully correct and potentially useful for genuinely dense
* networks, so it is certified and kept, just not auto-enabled - this is
* the same "correct code kept but not adopted by default" precedent
* already established for the earlier prototyped-and-shelved GWESP cache
* (unit 68) and the batch-means variance estimator (unit 80).
*
* Two independent correctness checks:
* (1) Direct brute-force cross-check: for many random toggle sequences
*     on graphs of varying size, EVERY pair's cached shared_partners()
*     value must exactly match common_neighbors() (a genuinely separate
*     code path that never touches the cache) at every checkpoint.
* (2) End-to-end equivalence: stat_gwesp()/change_gwesp() (and the
*     ErgmCertifyChangeStat() brute-force change-statistic check) must
*     give IDENTICAL results whether the cache is enabled or not, on the
*     same network.

mata:
mata set matastrict off

void verify_sp_cache(real scalar n, real scalar ntoggles, real scalar seedbase) {
	class ErgmGraph scalar G
	real scalar t, i, j, a, b, cached, brute, mismatches

	rseed(seedbase)
	G = ErgmGraph()
	G.init(n, 0)
	G.enable_sp_cache()

	mismatches = 0
	for (t=1; t<=ntoggles; t++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i != j) G.toggle(i, j)

		if (mod(t,5) == 0) {
			for (a=1; a<=n-1; a++) {
				for (b=a+1; b<=n; b++) {
					cached = G.shared_partners(a,b)
					brute = G.common_neighbors(a,b)
					if (cached != brute) mismatches++
				}
			}
		}
	}
	printf("verify_sp_cache: n=%g ntoggles=%g seed=%g mismatches=%g (final nties=%g)\n", n, ntoggles, seedbase, mismatches, G.nties)
	assert(mismatches == 0)
}

verify_sp_cache(8, 300, 5001)
verify_sp_cache(10, 400, 5002)
verify_sp_cache(15, 500, 5003)
verify_sp_cache(20, 600, 5004)
verify_sp_cache(6, 200, 5005)

void test_equiv(real scalar n, real scalar nedges, real scalar seed) {
	class ErgmGraph scalar G1, G2
	class ErgmModel scalar M1, M2
	class ErgmTermData scalar td1, td2
	real scalar t, i, j, md1, md2

	rseed(seed)
	G1 = ErgmGraph()
	G1.init(n, 0)
	for (t=1; t<=nedges; t++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i!=j & !G1.has_edge(i,j)) G1.toggle(i,j)
	}
	M1 = ErgmModel()
	M1.init()
	td1 = ErgmTermData()
	td1.decay = 0.6
	M1.addterm("gwesp", 1, &stat_gwesp(), &change_gwesp(), td1, ("gwesp"))
	md1 = ErgmCertifyChangeStat(M1, G1)

	rseed(seed)
	G2 = ErgmGraph()
	G2.init(n, 0)
	for (t=1; t<=nedges; t++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i!=j & !G2.has_edge(i,j)) G2.toggle(i,j)
	}
	G2.enable_sp_cache()
	M2 = ErgmModel()
	M2.init()
	td2 = ErgmTermData()
	td2.decay = 0.6
	M2.addterm("gwesp", 1, &stat_gwesp(), &change_gwesp(), td2, ("gwesp"))
	md2 = ErgmCertifyChangeStat(M2, G2)

	printf("test_equiv: n=%g nedges=%g seed=%g: max diff no-cache=%9.2e, with-cache=%9.2e\n", n, nedges, seed, md1, md2)
	assert(md1 < 1e-8)
	assert(md2 < 1e-8)
	assert(reldif(stat_gwesp(G1, td1), stat_gwesp(G2, td2)) < 1e-10)
}

test_equiv(6, 8, 9001)
test_equiv(10, 15, 9002)
test_equiv(15, 25, 9003)

// forcing many capacity/count transitions via a fully-connected build
// (every pair gains shared partners as the graph densifies) still
// matches has_edge()-based common_neighbors() exactly.
void verify_sp_cache_dense(real scalar n, real scalar seedbase) {
	class ErgmGraph scalar G
	real scalar i, j, a, b, cached, brute, mismatches

	rseed(seedbase)
	G = ErgmGraph()
	G.init(n, 0)
	G.enable_sp_cache()
	for (i=1; i<n; i=i+1) {
		for (j=i+1; j<=n; j=j+1) {
			G.toggle(i, j)
		}
	}
	mismatches = 0
	for (a=1; a<=n-1; a++) {
		for (b=a+1; b<=n; b++) {
			cached = G.shared_partners(a,b)
			brute = G.common_neighbors(a,b)
			if (cached != brute) mismatches++
		}
	}
	printf("verify_sp_cache_dense: n=%g fully connected mismatches=%g\n", n, mismatches)
	assert(mismatches == 0)
}

verify_sp_cache_dense(15, 6001)
end
