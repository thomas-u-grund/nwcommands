cscript

do unw_core.do

* vertex_connectivity()/min_vertex_cutset() (shared primitives behind
* nwkcomponents/nwcohesion) used to search every non-adjacent pair in
* the graph - O(n^2) max-flow calls - to find the global vertex
* connectivity. Found via direct benchmarking to be catastrophically
* slow even at moderate scale (66 SECONDS for a mere 100-node,
* average-degree-10 random graph - see docs/CERTIFICATION.md). Fixed
* with the Esfahanian & Hakimi (1984) refinement of Even's algorithm
* (fast_min_cut_search()), which needs only O(delta^2) max-flow calls
* (delta = minimum degree) - independent of n, a large win for the
* sparse graphs this package's own commands are typically used on -
* plus two further fixes to maxflow_vertex_split() itself (vectorized
* capacity-matrix construction instead of an interpreted double loop;
* a single shared base capacity matrix reused across every query in
* one fast_min_cut_search() call instead of rebuilt from scratch each
* time). Net effect measured directly: nwkcomponents on the same
* 100-node test network dropped from 66 seconds to under 0.03 seconds.
*
* This is a nontrivial graph-theory algorithm rewrite, so this file's
* main job is a genuine correctness cross-check against the exact
* pre-fix brute-force algorithm (kept here ONLY for this comparison,
* not used anywhere else), across many random graphs of varying size
* and density, plus edge cases (complete graphs, empty graphs,
* disconnected graphs) - not just a couple of hand-picked examples.

mata:
real scalar vertex_connectivity_bruteforce(real matrix adj){
	real scalar n, s, t, minflow, f
	real scalar any_nonadjacent

	n = rows(adj)
	if (n <= 1) return(0)

	any_nonadjacent = 0
	minflow = n
	for (s=1; s<=n; s++) {
		for (t=s+1; t<=n; t++) {
			if (adj[s,t] == 0) {
				any_nonadjacent = 1
				f = maxflow_vertex_split(adj, s, t)
				if (f < minflow) minflow = f
			}
		}
	}
	if (any_nonadjacent == 0) return(n-1)
	return(minflow)
}

void run_vc_crosscheck(){
	real scalar n, i, j, trial, kfast, kslow, nmismatch, ntested, half
	real matrix adj
	real scalar p

	nmismatch = 0
	ntested = 0

	for (n = 4; n <= 30; n++) {
		for (trial = 1; trial <= 15; trial++) {
			p = 0.15 + 0.6 * runiform(1,1)
			adj = J(n, n, 0)
			for (i = 1; i <= n; i++) {
				for (j = i+1; j <= n; j++) {
					if (runiform(1,1)[1,1] < p) {
						adj[i,j] = 1
						adj[j,i] = 1
					}
				}
			}
			kfast = vertex_connectivity(adj)
			kslow = vertex_connectivity_bruteforce(adj)
			ntested++
			if (kfast != kslow) nmismatch++
		}
	}

	// complete graphs and empty graphs at several sizes
	for (n = 2; n <= 15; n++) {
		adj = J(n,n,1) - I(n)
		kfast = vertex_connectivity(adj)
		kslow = vertex_connectivity_bruteforce(adj)
		ntested++
		if (kfast != kslow) nmismatch++

		adj = J(n,n,0)
		kfast = vertex_connectivity(adj)
		kslow = vertex_connectivity_bruteforce(adj)
		ntested++
		if (kfast != kslow) nmismatch++
	}

	// two disjoint cliques (guaranteed disconnected, kappa=0)
	for (n = 4; n <= 20; n=n+2) {
		adj = J(n,n,0)
		half = n/2
		for (i=1;i<=half;i++) {
			for (j=i+1;j<=half;j++) {
				adj[i,j]=1
				adj[j,i]=1
			}
		}
		for (i=half+1;i<=n;i++) {
			for (j=i+1;j<=n;j++) {
				adj[i,j]=1
				adj[j,i]=1
			}
		}
		kfast = vertex_connectivity(adj)
		kslow = vertex_connectivity_bruteforce(adj)
		ntested++
		if (kfast != kslow) nmismatch++
	}

	st_numscalar("r(ntested)", ntested)
	st_numscalar("r(nmismatch)", nmismatch)
}
end

mata: run_vc_crosscheck()
assert r(nmismatch) == 0
assert r(ntested) > 400

* --- direct, hand-verifiable sanity checks on named graphs ---
mata: printf("K5 (complete, 5 nodes): kappa = %f (expect 4)\n", vertex_connectivity((J(5,5,1)-I(5))))
mata: assert(vertex_connectivity((J(5,5,1)-I(5))) == 4)

* path graph A-B-C-D-E: kappa = 1 (any single internal node disconnects it)
mata: path5 = (0,1,0,0,0 \ 1,0,1,0,0 \ 0,1,0,1,0 \ 0,0,1,0,1 \ 0,0,0,1,0)
mata: assert(vertex_connectivity(path5) == 1)

* cycle graph (5-cycle): kappa = 2
mata: cyc5 = (0,1,0,0,1 \ 1,0,1,0,0 \ 0,1,0,1,0 \ 0,0,1,0,1 \ 1,0,0,1,0)
mata: assert(vertex_connectivity(cyc5) == 2)

* two disjoint edges (disconnected): kappa = 0
mata: assert(vertex_connectivity((0,1,0,0 \ 1,0,0,0 \ 0,0,0,1 \ 0,0,1,0)) == 0)
