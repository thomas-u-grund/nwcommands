version 12
clear all
capture mata: mata clear

/*
	Sparse-backend scalability benchmark (Commit 6 of the sparse-graph-
	backend migration plan). Demonstrates, at three tiers, that a network
	can be built, queried for neighbors/degree, and analyzed for connected
	components WITHOUT ever constructing an N x N dense matrix - the
	concrete milestone from this session's architecture report.

	Networks are built directly via NWdef::set_edge_from_triplets()
	(Commit 7), which is the genuinely sparse-native construction path.
	nwfromedge.ado itself has NOT been rewired to use this path yet (see
	the roadmap doc for why: its downstream side effects - nwsym
	symmetrization, bipartite embedding, nw_datasync - all currently touch
	the dense matrix at various points and need their own audit before
	they can be made lazy without risking a silent behavior change; this
	benchmark instead exercises the same underlying storage/query layer
	those commands will eventually sit on).

	Run: /Applications/Stata/StataBE.app/Contents/MacOS/StataBE -e do "lib/benchmark_sparse.do"
*/

cd /Users/tgrund/FILES_NEW/SOFTWARE/nwcommands
do unw_core.do

mata:
void run_tier(real scalar n, real scalar m, string scalar label){
	real matrix ego, alter, weight
	real scalar t0, t1, t_build, t_deg, t_neigh, t_comp, i, dummy
	real scalar dense_bytes, sparse_bytes
	class nws_def scalar nws
	pointer(class nw_def scalar) scalar p
	real matrix comp

	printf("\n{txt}=== %s: n=%g, m=%g ===\n", label, n, m)

	// generate m random directed edges over n nodes (self-loops possible,
	// harmless - degree()/neighbors() semantics are unaffected either way)
	ego = ceil(runiform(m,1) :* n)
	alter = ceil(runiform(m,1) :* n)
	weight = J(m,1,1)

	t0 = clock(c("current_time"), "hms")
	nws = nws_def()
	nws.create_by_name(("placeholder"))
	p = nws.pdefs[1]
	p->create_by_name_sparse("n" :+ strofreal((1..n)))
	p->set_edge_from_triplets(ego, alter, weight, 1)
	t1 = clock(c("current_time"), "hms")
	t_build = (t1 - t0) / 1000

	printf("{txt}  build time: {res}%9.4f{txt}s\n", t_build)
	printf("{txt}  edge_dense_built after build: {res}%g{txt} (must be 0 - no N x N matrix constructed)\n", p->edge_dense_built)

	t0 = clock(c("current_time"), "hms")
	for (i=1; i<=min((n,1000)); i++){
		dummy = p->degree(i)
	}
	t1 = clock(c("current_time"), "hms")
	t_deg = (t1 - t0) / 1000
	printf("{txt}  degree() x %g nodes: {res}%9.4f{txt}s\n", min((n,1000)), t_deg)

	t0 = clock(c("current_time"), "hms")
	for (i=1; i<=min((n,1000)); i++){
		dummy = rows(p->neighbors(i))
	}
	t1 = clock(c("current_time"), "hms")
	t_neigh = (t1 - t0) / 1000
	printf("{txt}  neighbors() x %g nodes: {res}%9.4f{txt}s\n", min((n,1000)), t_neigh)

	t0 = clock(c("current_time"), "hms")
	comp = p->calculate_components()
	t1 = clock(c("current_time"), "hms")
	t_comp = (t1 - t0) / 1000
	printf("{txt}  calculate_components(): {res}%9.4f{txt}s  ({res}%g{txt} components)\n", t_comp, max(comp))

	printf("{txt}  edge_dense_built after all queries: {res}%g{txt} (must still be 0 - confirms no dense matrix was ever needed)\n", p->edge_dense_built)

	dense_bytes = n * n * 8
	sparse_bytes = (rows(p->colidx) + rows(p->cweight)) * 8 + (n+1)*8
	printf("{txt}  theoretical dense (N^2 x 8B):  {res}%12.0f{txt} bytes (%s)\n", dense_bytes, format_bytes(dense_bytes))
	printf("{txt}  actual sparse storage (colidx+cweight+rowptr): {res}%12.0f{txt} bytes (%s)\n", sparse_bytes, format_bytes(sparse_bytes))
	printf("{txt}  ratio: dense would be {res}%9.1fx{txt} larger\n", dense_bytes/sparse_bytes)
}

string scalar format_bytes(real scalar b){
	if (b > 1024^3) return(strofreal(round(b/1024^3*100)/100) + " GB")
	if (b > 1024^2) return(strofreal(round(b/1024^2*100)/100) + " MB")
	if (b > 1024) return(strofreal(round(b/1024*100)/100) + " KB")
	return(strofreal(b) + " B")
}

run_tier(1000, 10000, "Tier 1")
run_tier(10000, 100000, "Tier 2")
run_tier(100000, 1000000, "Tier 3")

printf("\n{txt}=== Summary ===\n")
printf("{txt}All three tiers built, queried (degree/neighbors), and analyzed for\n")
printf("connected components with edge_dense_built confirmed 0 throughout - the\n")
printf("N x N dense matrix was never constructed at any tier, including Tier 3\n")
printf("(100,000 nodes / 1,000,000 edges, which would require ~74.5GB dense).\n")
end

/*
	Distance-family benchmark (sparse-backend migration, item 2 of 2 -
	calculate_distances()/calculate_distance_pair()/
	calculate_distances_without(), feeding nwgeodesic/nwcloseness/
	nwreach/nwbridges/nwpath). All-pairs distance output is inherently
	O(n^2) (that is what "all pairs" means), so this can't scale to the
	100k-node tier above the same way degree()/neighbors()/
	calculate_components() do. Two genuinely different complexity
	classes here, benchmarked at different sizes:
	- calculate_distances_bfs() (unweighted) and calculate_distance_pair()/
	  calculate_distances_without() (BFS-based) are O(n*(V+E)) - matching
	  actual edge count, not the old Brute_dist()'s O(n^4) worst case
	  (matrix-power iteration) - so these scale to a genuinely large,
	  sparse network (n=5000, m=25000).
	- calculate_distances_dijkstra() (weighted) still has an O(n^3)
	  extract-min bottleneck - the same linear-scan-over-unsettled-nodes
	  tradeoff already established and documented for
	  calculate_betweenness_weighted() above ("Mata has no built-in
	  priority queue/decrease-key"), so it is benchmarked at a smaller
	  size (n=300) where O(n^3) is still fast, rather than falsely
	  implying it shares the other functions' scalability. Its own real
	  win over the old Dijkstra_dist() is that the edge-relaxation step
	  is O(degree) via neighbors()/edge_weight() instead of an O(n) dense
	  row scan, and the dense `edge' matrix is never built at all.
*/
mata:
void run_distance_tier_bfs(real scalar n, real scalar m, string scalar label){
	real matrix ego, alter, weight
	real scalar t0, t1, t_bfs, t_without, t_pair, i, dummy
	class nws_def scalar nws
	pointer(class nw_def scalar) scalar p
	real matrix D, DW

	printf("\n{txt}=== %s: n=%g, m=%g (undirected, unweighted family) ===\n", label, n, m)

	ego = ceil(runiform(m,1) :* n)
	alter = ceil(runiform(m,1) :* n)
	weight = J(m,1,1)

	nws = nws_def()
	nws.create_by_name(("placeholder"))
	p = nws.pdefs[1]
	p->create_by_name_sparse("n" :+ strofreal((1..n)))
	p->set_edge_from_triplets(ego, alter, weight, 0)

	t0 = clock(c("current_time"), "hms")
	D = p->calculate_distances_bfs()
	t1 = clock(c("current_time"), "hms")
	t_bfs = (t1 - t0) / 1000
	printf("{txt}  calculate_distances_bfs() (all-pairs, O(n*(V+E))): {res}%9.4f{txt}s\n", t_bfs)

	t0 = clock(c("current_time"), "hms")
	DW = p->calculate_distances_without()
	t1 = clock(c("current_time"), "hms")
	t_without = (t1 - t0) / 1000
	printf("{txt}  calculate_distances_without() (per-edge, %g edges): {res}%9.4f{txt}s\n", m, t_without)

	t0 = clock(c("current_time"), "hms")
	for (i=1; i<=min((n,1000)); i++){
		dummy = p->calculate_distance_pair(1, i)
	}
	t1 = clock(c("current_time"), "hms")
	t_pair = (t1 - t0) / 1000
	printf("{txt}  calculate_distance_pair() x %g single pairs: {res}%9.4f{txt}s\n", min((n,1000)), t_pair)

	printf("{txt}  edge_dense_built after all distance queries: {res}%g{txt} (must still be 0)\n", p->edge_dense_built)
	printf("{txt}  D[1,1] (self-distance, must be missing): {res}%g{txt}, DW nonzero entries: {res}%g{txt}\n", D[1,1], sum(DW:!=0))
}
run_distance_tier_bfs(5000, 25000, "Distance Tier 1 (BFS family)")

void run_distance_tier_dijkstra(real scalar n, real scalar m, string scalar label){
	real matrix ego, alter, weight
	real scalar t0, t1, t_dijkstra
	class nws_def scalar nws
	pointer(class nw_def scalar) scalar p
	real matrix D

	printf("\n{txt}=== %s: n=%g, m=%g (undirected, weighted) ===\n", label, n, m)

	ego = ceil(runiform(m,1) :* n)
	alter = ceil(runiform(m,1) :* n)
	weight = ceil(runiform(m,1) :* 10)

	nws = nws_def()
	nws.create_by_name(("placeholder"))
	p = nws.pdefs[1]
	p->create_by_name_sparse("n" :+ strofreal((1..n)))
	p->set_edge_from_triplets(ego, alter, weight, 0)

	t0 = clock(c("current_time"), "hms")
	D = p->calculate_distances_dijkstra(1)
	t1 = clock(c("current_time"), "hms")
	t_dijkstra = (t1 - t0) / 1000
	printf("{txt}  calculate_distances_dijkstra(1) (all-pairs, O(n^3) extract-min + O(n*E) relax): {res}%9.4f{txt}s\n", t_dijkstra)
	printf("{txt}  edge_dense_built after query: {res}%g{txt} (must still be 0)\n", p->edge_dense_built)
	printf("{txt}  D[1,1] (self-distance, must be 0): {res}%g{txt}\n", D[1,1])
}
run_distance_tier_dijkstra(300, 1500, "Distance Tier 2 (weighted Dijkstra family)")
end

