cscript

do unw_ergm.do

* Certifies ErgmGraph's live edge array (elist/edgepos - harmonisation
* unit 80, Part XXV performance work), the incremental data structure
* that replaced all_ties()'s own O(n+nties) neighbor-set reconstruction
* with an O(nties) direct slice, and made TNT's own tie-pick O(1)
* (measured 129x faster - see docs/CERTIFICATION.md's own unit 80 entry
* and dev/ergm_benchmark.do). Since toggle() now maintains elist/edgepos
* incrementally (amortized O(1) append via capacity doubling, O(1)
* removal via swap-with-last), this is a genuinely new, previously-
* untested code path that needs its own direct certification, not just
* indirect coverage via terms that happen to call all_ties().
*
* Independent brute-force cross-check: for many random toggle sequences
* on both directed and undirected graphs, all_ties() (now backed by
* elist/edgepos) must exactly match a from-scratch dyad scan using
* has_edge() - a genuinely separate code path that never touches
* elist/edgepos at all. Compared as SETS (not row order, which is
* expected to differ - elist's own order is insertion/swap order, not
* all_ties()'s old neighbor-iteration order).

mata:
mata set matastrict off

void verify_elist(real scalar n, real scalar directed, real scalar ntoggles, real scalar seedbase) {
	class ErgmGraph scalar G
	real scalar t, i, j, k, found, mismatches
	real matrix at, brute

	rseed(seedbase)
	G = ErgmGraph()
	G.init(n, directed)
	for (t=1; t<=ntoggles; t++) {
		i = ceil(runiform(1,1)*n)
		j = ceil(runiform(1,1)*n)
		if (i != j) G.toggle(i, j)

		if (mod(t,7) == 0) {
			brute = J(0, 2, 0)
			for (i=1; i<=n; i++) {
				for (j=1; j<=n; j++) {
					if (i==j) continue
					if (!directed & j<i) continue
					if (G.has_edge(i,j)) brute = brute \ (i,j)
				}
			}
			at = G.all_ties()
			assert(rows(at) == G.nties)
			assert(rows(at) == rows(brute))
			mismatches = 0
			for (k=1; k<=rows(at); k++) {
				found = 0
				for (i=1; i<=rows(brute); i++) {
					if (at[k,1]==brute[i,1] & at[k,2]==brute[i,2]) found = 1
				}
				if (!found) mismatches++
			}
			assert(mismatches == 0)
		}
	}
	printf("verify_elist: n=%g directed=%g ntoggles=%g seed=%g OK (final nties=%g)\n", n, directed, ntoggles, seedbase, G.nties)
}

verify_elist(8, 0, 300, 3001)
verify_elist(10, 1, 300, 3002)
verify_elist(15, 0, 500, 3003)
verify_elist(15, 1, 500, 3004)
verify_elist(5, 0, 100, 3005)

// --- forcing many capacity-doubling events (repeated add-only growth
// past the initial small capacity) still matches has_edge() exactly.
void verify_elist_growth(real scalar n, real scalar seedbase) {
	class ErgmGraph scalar G
	real scalar i, j, k
	real matrix at

	rseed(seedbase)
	G = ErgmGraph()
	G.init(n, 0)
	for (i=1; i<n; i=i+1) {
		for (j=i+1; j<=n; j=j+1) {
			G.toggle(i, j)
		}
	}
	assert(G.nties == n*(n-1)/2)
	at = G.all_ties()
	assert(rows(at) == n*(n-1)/2)
	for (k=1; k<=rows(at); k++) {
		assert(G.has_edge(at[k,1], at[k,2]))
	}
	printf("verify_elist_growth: n=%g fully connected, nties=%g OK\n", n, G.nties)
}

verify_elist_growth(20, 4001)
end
