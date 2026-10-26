/*
	nwgraph.c -- native (C) graph-algorithm kernels for nwcommands
	(harmonisation unit 95, docs/CERTIFICATION.md; feasibility background
	in docs/NATIVE_GRAPH_LIBRARIES.md).

	WHY THIS EXISTS, AND WHY IT IS BESPOKE C RATHER THAN A THIRD-PARTY
	LIBRARY: the user's own directive asked for an evidence-based
	investigation of adopting an external native graph library (igraph,
	NetworKit, SuiteSparse:GraphBLAS/LAGraph, ...) as an optional
	performance backend for this package's existing Mata-implemented
	graph commands. docs/NATIVE_GRAPH_LIBRARIES.md is that investigation
	in full; the short version is that this project's OWN prior sparse-
	backend migration (docs/SPARSE_BACKEND.md) already delivers proven,
	adequate performance (100,000 nodes/1,000,000 edges) for every
	ALGORITHMICALLY cheap structural command (components, degree,
	clustering, neighbor traversal, unweighted BFS distances) - the
	obvious, general-purpose win a big external library would otherwise
	offer is already banked, in Mata, with zero new dependencies. What
	that migration did NOT fix is Mata's own per-operation INTERPRETER
	overhead on the handful of commands whose own algorithm does many
	small, tight-loop operations even after sparsity is accounted for -
	exactly the same profile that motivated nwergm's own native MCMC
	backend (docs/ERGM_ARCHITECTURE.md), and confirmed here the same way:
	a direct microbenchmark, not a guess (see NATIVE_GRAPH_LIBRARIES.md's
	own evidence section - betweenness centrality on a 1,000-node sparse
	network took 13.2 seconds in Mata, up from 0.94 seconds at 500 nodes,
	consistent with real per-operation overhead compounding on top of the
	algorithm's own O(V*(V+E)) complexity, not just the complexity itself).
	For a small number of specific, well-understood algorithms like this,
	a bespoke, purpose-built C kernel (this file) matching nwergm's own
	already-proven, working pattern is the lower-risk, lower-maintenance,
	licensing-clean choice versus vendoring and cross-platform-building an
	entire third-party graph library (which, per the same feasibility
	document's own licence audit, would in several candidates' cases -
	igraph is GPL-2.0-or-later - also impose real distribution
	constraints this package does not otherwise have) for a handful of
	functions this file implements directly in a few hundred lines.

	SCOPE (this unit): betweenness centrality (Brandes 2001,
	unweighted/dichotomized case - the DEFAULT nwbetween() mode, matching
	its own default `calculate_betweenness()` in unw_core.do exactly).

	SCOPE (follow-on unit): single-source unweighted BFS distances
	(ALG_BFS_DISTANCES), called once per source node from Mata
	(calculate_distances_bfs_native() in unw_core.do) rather than once
	for the whole all-pairs matrix - the classic Stata Plugin Interface
	has no channel to hand back an O(n^2) result directly, only the
	current dataset's own rows/columns, so an O(n) score-per-node column
	returned once per call (exactly betweenness's own existing shape,
	looped n times Mata-side) sidesteps that limit entirely rather than
	pre-expanding a working frame to n^2 rows. Feeds
	`calculate_distances()`'s own "brute" (unweighted) branch, which in
	turn feeds nwgeodesic (directly), nwbridges, nwpath, and
	nwcloseness/nwreach (both via nwgeodesic) - see
	NativeGraphAvailable()'s own dispatch in unw_core.do for the
	graceful pure-Mata fallback wherever no plugin binary is available
	for the running platform.

	The weighted (Dijkstra-based) distance mode remains Mata-only, a
	documented, scoped follow-on of its own (see docs/ERGM_ROADMAP.md's
	own "Native graph kernels" section) - not attempted here to keep
	this wave's own scope controlled, the same discipline nwergm's own
	term-expansion waves used throughout: a naive linear-scan extract-min
	(no built-in Mata priority queue) is already the identified
	bottleneck there, and porting that faithfully to C needs its own
	dedicated pass, not a rushed addition alongside this unit's own
	unweighted-BFS scope. Additional algorithm codes (k-core peeling,
	Louvain community detection - the other two candidates
	NATIVE_GRAPH_LIBRARIES.md's own profiling section flags as similarly
	interpreter-bound) can be added to this same plugin file later,
	following the `algcode' dispatch pattern below - this file is
	structured as a single shared native-graph plugin, not "one plugin
	per algorithm", exactly mirroring how ergm_mcmc.c hosts many TERM
	codes behind one plugin rather than one plugin per term.

	WIRE PROTOCOL: one `plugin call` per invocation (see unw_core.do's
	own `calculate_betweenness_native()`), args string
	"algcode n directed nties", then two input frame variables (v1=ego,
	v2=alter, one row per tie, 1-indexed node IDs - for an undirected
	network the caller passes each tie ONCE, this file builds the
	symmetric adjacency itself) and one output frame variable (v3,
	written with each node's own betweenness score, unstandardized -
	nwbetween.ado's own standardize()/`(N-1)*(N-2)`-family formulas are
	unchanged, applied identically regardless of which backend produced
	the raw scores).

	CERTIFICATION CONTRACT: betweenness centrality (unlike nwergm's own
	stochastic MCMC sampler) is a DETERMINISTIC, exact combinatorial
	quantity - the native and Mata implementations of the same
	Brandes-2001 algorithm on the same graph must agree EXACTLY (up to
	ordinary floating-point summation order effects, not a statistical
	tolerance) - see cscripts/test_nwbetween_native.do.
*/

#include "stplugin.h"
#include "nwtypes.h"
#include <stdlib.h>
#include <string.h>
#include <math.h>

#define ALG_BETWEENNESS 1
#define ALG_BFS_DISTANCES 2
#define ALG_KCONN_SEARCH 20
#define ALG_KK_STRESS 21

/* algorithm codes 3..100: the combinatorial kernels (cohesion, factions, lambda, motifs,
   two-mode clustering, n-cliques/n-clans, k-plexes), in nwcomb.h / nwcomb2.h */
#include "nwcomb.h"

/* ===================================================================
   Betweenness centrality (Brandes 2001), unweighted/dichotomized.
   Direct, hand-verified port of `NWdef::calculate_betweenness()' in
   unw_core.do - same algorithm, same O(V*(V+E)) complexity, compiled
   instead of interpreted. `preds[w]' (predecessor list on a shortest
   path to w from the current source) is grown on demand and reused
   (not freed) across sources, exactly mirroring the dynamic adjacency
   list growth pattern already established in native/ergm_mcmc.c's own
   adjlist_t.
   =================================================================== */

static int betweenness_unweighted(nwint n, int directed, nwint *ei, nwint *ej, nwint nties) {
	nwint i, k, src;
	nwint *deg = NULL, *rowptr = NULL, *colidx = NULL, *cursor = NULL;
	nwint *stack = NULL, *queue = NULL, *dist = NULL;
	double *sigma = NULL, *delta = NULL, *Cb = NULL;
	nwint *predcount = NULL, *predcap = NULL;
	nwint **preds = NULL;
	int rc = 0;

	/* The caller (unw_core.do's own calculate_betweenness_native())
	   always hands over an already-fully-expanded arc list: for an
	   undirected network its own edgelist() stores each tie
	   SYMMETRICALLY (both (i,j) and (j,i) already present, per
	   docs/SPARSE_BACKEND.md), so no reverse edge is ever added here -
	   doing so would double every undirected tie. `directed' below is
	   used ONLY for the final halving step, matching
	   calculate_betweenness()'s own identical undirected halving in
	   unw_core.do. */
	deg = (nwint *)calloc((size_t)(n + 1), sizeof(nwint));
	for (i = 0; i < nties; i++) deg[ei[i]]++;
	rowptr = (nwint *)malloc((size_t)(n + 2) * sizeof(nwint));
	rowptr[1] = 0;
	for (i = 1; i <= n; i++) rowptr[i + 1] = rowptr[i] + deg[i];
	cursor = (nwint *)malloc((size_t)(n + 1) * sizeof(nwint));
	for (i = 1; i <= n; i++) cursor[i] = rowptr[i];
	colidx = (nwint *)malloc((size_t)(rowptr[n + 1] > 0 ? rowptr[n + 1] : 1) * sizeof(nwint));
	for (i = 0; i < nties; i++) colidx[cursor[ei[i]]++] = ej[i];
	free(cursor); cursor = NULL;
	free(deg); deg = NULL;

	Cb = (double *)calloc((size_t)(n + 1), sizeof(double));
	stack = (nwint *)malloc((size_t)n * sizeof(nwint));
	queue = (nwint *)malloc((size_t)n * sizeof(nwint));
	sigma = (double *)malloc((size_t)(n + 1) * sizeof(double));
	dist = (nwint *)malloc((size_t)(n + 1) * sizeof(nwint));
	delta = (double *)malloc((size_t)(n + 1) * sizeof(double));
	predcount = (nwint *)malloc((size_t)(n + 1) * sizeof(nwint));
	predcap = (nwint *)calloc((size_t)(n + 1), sizeof(nwint));
	preds = (nwint **)calloc((size_t)(n + 1), sizeof(nwint *));
	if (!Cb || !stack || !queue || !sigma || !dist || !delta || !predcount || !predcap || !preds) {
		rc = 909;
		goto cleanup;
	}

	for (src = 1; src <= n; src++) {
		nwint sp = 0, qh = 0, qt = 0;
		for (i = 1; i <= n; i++) { dist[i] = -1; sigma[i] = 0.0; delta[i] = 0.0; predcount[i] = 0; }
		dist[src] = 0;
		sigma[src] = 1.0;
		queue[qt++] = src;
		while (qh < qt) {
			nwint v = queue[qh++];
			stack[sp++] = v;
			for (k = rowptr[v]; k < rowptr[v + 1]; k++) {
				nwint w = colidx[k];
				if (dist[w] < 0) {
					dist[w] = dist[v] + 1;
					queue[qt++] = w;
				}
				if (dist[w] == dist[v] + 1) {
					sigma[w] += sigma[v];
					if (predcount[w] >= predcap[w]) {
						predcap[w] = predcap[w] ? predcap[w] * 2 : 4;
						preds[w] = (nwint *)realloc(preds[w], (size_t)predcap[w] * sizeof(nwint));
					}
					preds[w][predcount[w]++] = v;
				}
			}
		}
		while (sp > 0) {
			nwint w = stack[--sp];
			for (k = 0; k < predcount[w]; k++) {
				nwint v = preds[w][k];
				delta[v] += (sigma[v] / sigma[w]) * (1.0 + delta[w]);
			}
			if (w != src) Cb[w] += delta[w];
		}
	}

	if (!directed) {
		for (i = 1; i <= n; i++) Cb[i] /= 2.0;
	}

	for (i = 1; i <= n; i++) NW_VSTORE(3, i, Cb[i]);

cleanup:
	if (preds) {
		for (i = 1; i <= n; i++) free(preds[i]);
		free(preds);
	}
	free(predcap);
	free(predcount);
	free(delta);
	free(dist);
	free(sigma);
	free(queue);
	free(stack);
	free(Cb);
	free(rowptr);
	free(colidx);
	return rc;
}

/* ===================================================================
   Single-source unweighted (hop-count) BFS distances - the compiled
   counterpart to unw_core.do's own `bfs_hopdist_from()'. Called once
   PER SOURCE NODE from Mata (calculate_distances_bfs_native() below),
   not once for the whole all-pairs matrix: the classic Stata Plugin
   Interface has no channel to hand back an O(n^2) result directly (only
   the current dataset's own rows/columns, via SF_vdata/SF_vstore), so
   an all-pairs kernel would need either a pre-expanded n^2-row working
   frame (real overhead of its own, before the algorithm even starts) or
   this design instead: each call does one O(n+m) traversal and returns
   one O(n) column, exactly the same shape betweenness_unweighted()
   above already uses successfully, called n times by the Mata-side
   loop. The CSR build (O(n+m)) is repeated on every call rather than
   cached across calls, since a plugin invocation has no state that
   survives between them - a real, accepted cost, small next to the
   O(n+m) traversal itself and tiny next to Mata's own per-operation
   interpreter overhead this whole native path exists to avoid.
   =================================================================== */

static int bfs_distances_from(nwint n, nwint *ei, nwint *ej, nwint nties, nwint source, nwint nblock) {
	nwint i, k, b, src;
	nwint *deg = NULL, *rowptr = NULL, *colidx = NULL, *cursor = NULL;
	nwint *queue = NULL, *dist = NULL;
	int rc = 0;

	deg = (nwint *)calloc((size_t)(n + 1), sizeof(nwint));
	for (i = 0; i < nties; i++) deg[ei[i]]++;
	rowptr = (nwint *)malloc((size_t)(n + 2) * sizeof(nwint));
	rowptr[1] = 0;
	for (i = 1; i <= n; i++) rowptr[i + 1] = rowptr[i] + deg[i];
	cursor = (nwint *)malloc((size_t)(n + 1) * sizeof(nwint));
	for (i = 1; i <= n; i++) cursor[i] = rowptr[i];
	colidx = (nwint *)malloc((size_t)(rowptr[n + 1] > 0 ? rowptr[n + 1] : 1) * sizeof(nwint));
	for (i = 0; i < nties; i++) colidx[cursor[ei[i]]++] = ej[i];
	free(cursor); cursor = NULL;
	free(deg); deg = NULL;

	dist = (nwint *)malloc((size_t)(n + 1) * sizeof(nwint));
	queue = (nwint *)malloc((size_t)n * sizeof(nwint));
	if (!dist || !queue) { rc = 909; goto cleanup; }

	/* nblock sources source, source+1, ... (the default is the one source): the graph is built once for all of them and
	   the distances of source+b go to output variable 3+b (variables 3.. of the call). */
	for (b = 0; b < nblock; b++) {
		src = source + b;
		if (src > n) break;
		for (i = 1; i <= n; i++) dist[i] = -1;
		dist[src] = 0;
		{
			nwint qh = 0, qt = 0;
			queue[qt++] = src;
			while (qh < qt) {
				nwint v = queue[qh++];
				for (k = rowptr[v]; k < rowptr[v + 1]; k++) {
					nwint w = colidx[k];
					if (dist[w] < 0) {
						dist[w] = dist[v] + 1;
						queue[qt++] = w;
					}
				}
			}
		}

		/* Matches bfs_hopdist_from()'s own convention exactly: the source
		   itself is left MISSING on return (Brute_dist()'s original
		   "_editvalue(dist,0,.)" behavior, which calculate_distances_bfs()
		   relies on), and any node BFS never reached also comes back
		   missing rather than a sentinel like -1 that could be mistaken for
		   a real distance. */
		for (i = 1; i <= n; i++) {
			if (i == src || dist[i] < 0) NW_VSTORE(3 + b, i, SV_missval);
			else NW_VSTORE(3 + b, i, (double)dist[i]);
		}
	}

cleanup:
	free(dist);
	free(queue);
	free(rowptr);
	free(colidx);
	return rc;
}

/* ===================================================================
   Vertex-connectivity search for nwkcomponents (ALG_KCONN_SEARCH): the
   compiled counterpart to `fast_min_cut_search_edges()' in unw_core.do
   called with its optional `target' (Esfahanian & Hakimi 1984 on the
   vertex-split flow graph, Even 1979).  Same query order as the Mata
   function (v0 to every non-neighbour in node order, then every
   non-adjacent pair of v0's neighbours), same early exit as soon as a
   query gives a flow below `target'.  Differences, none of which the
   caller can see: a query stops augmenting once its flow reaches
   `target' (so a flow >= target is reported as `target'), which saves
   the final failing breadth-first search that explores the whole
   residual graph.  Output (v3, rows 1-3): minflow, best_s, best_t.
   `ei'/`ej' are the symmetric arc list of the (loop-free) graph.
   =================================================================== */

typedef struct {
	nwint N;              /* flow-graph nodes: in(v)=v, out(v)=n+v, 1-indexed */
	nwint *head, *nxt, *to;
	nwint *cap, *res;     /* base capacity and residual capacity per arc */
	nwint nedge;
} flowgraph_t;

static void fg_add(flowgraph_t *g, nwint u, nwint v, nwint c) {
	nwint e = g->nedge;
	g->to[e] = v; g->cap[e] = c; g->nxt[e] = g->head[u]; g->head[u] = e;
	g->to[e + 1] = u; g->cap[e + 1] = 0; g->nxt[e + 1] = g->head[v]; g->head[v] = e + 1;
	g->nedge += 2;
}

static int kconn_search(nwint n, nwint *ei, nwint *ej, nwint m, nwint target) {
	nwint i, j, e, delta, v0, minflow, best_s = 0, best_t = 0, big = n + 10;
	nwint *deg = NULL, *rowptr = NULL, *colidx = NULL, *cursor = NULL;
	char *isnb = NULL, *isnb2 = NULL;
	nwint *queue = NULL, *parent = NULL, *stamp = NULL, curstamp = 0;
	nwint *touched = NULL, ntouched = 0;
	flowgraph_t g;
	int rc = 0;
	nwint nv0 = 0, *nbv0 = NULL;

	memset(&g, 0, sizeof(g));
	deg = (nwint *)calloc((size_t)(n + 2), sizeof(nwint));
	for (e = 0; e < m; e++) deg[ei[e]]++;
	delta = deg[1]; v0 = 1;
	for (i = 2; i <= n; i++) if (deg[i] < delta) { delta = deg[i]; v0 = i; }
	minflow = delta;

	if (minflow < target) goto done;

	/* target 2 (nwkcomponents, k = 2): the answer of every flow query is known from the blocks of one
	   depth-first search (kconn2_search() in nwfast2.h); same queries in the same order, same result */
	if (target == 2) {
		nwint mf2, bs2, bt2;
		int h = kconn2_search(n, ei, ej, m, delta, v0, &mf2, &bs2, &bt2);
		if (h == 1) { minflow = mf2; best_s = bs2; best_t = bt2; goto done; }
		if (h == 2) { rc = 909; goto done; }
	}

	rowptr = (nwint *)malloc((size_t)(n + 2) * sizeof(nwint));
	rowptr[1] = 0;
	for (i = 1; i <= n; i++) rowptr[i + 1] = rowptr[i] + deg[i];
	cursor = (nwint *)malloc((size_t)(n + 1) * sizeof(nwint));
	for (i = 1; i <= n; i++) cursor[i] = rowptr[i];
	colidx = (nwint *)malloc((size_t)(m > 0 ? m : 1) * sizeof(nwint));
	for (e = 0; e < m; e++) colidx[cursor[ei[e]]++] = ej[e];

	g.N = 2 * n;
	g.nedge = 0;
	g.head = (nwint *)calloc((size_t)(g.N + 1), sizeof(nwint));      /* arcs are numbered from 1; 0 = none */
	{
		nwint total = 2 * (n + m) + 2;
		g.to = (nwint *)malloc((size_t)total * sizeof(nwint));
		g.nxt = (nwint *)malloc((size_t)total * sizeof(nwint));
		g.cap = (nwint *)malloc((size_t)total * sizeof(nwint));
		g.res = (nwint *)malloc((size_t)total * sizeof(nwint));
	}
	queue = (nwint *)malloc((size_t)(g.N + 1) * sizeof(nwint));
	parent = (nwint *)malloc((size_t)(g.N + 1) * sizeof(nwint));
	stamp = (nwint *)calloc((size_t)(g.N + 1), sizeof(nwint));
	isnb = (char *)calloc((size_t)(n + 1), 1);
	isnb2 = (char *)calloc((size_t)(n + 1), 1);
	touched = (nwint *)malloc(((size_t)target * (size_t)(2 * n + 2) + (size_t)(2 * (n + m) + 2)) * sizeof(nwint));
	if (!touched) { rc = 909; goto done; }
	if (!g.head || !g.to || !g.nxt || !g.cap || !g.res || !queue || !parent || !stamp || !isnb || !isnb2) { rc = 909; goto done; }
	/* arc index 0 is a dummy so that head[]==0 means "no arc" */
	g.nedge = 2;
	for (i = 1; i <= n; i++) fg_add(&g, i, n + i, 1);              /* split arc: arc 2i+... */
	for (e = 0; e < m; e++) fg_add(&g, n + ei[e], ej[e], big);

	nv0 = rowptr[v0 + 1] - rowptr[v0];
	nbv0 = colidx + rowptr[v0];
	for (i = 0; i < nv0; i++) isnb[nbv0[i]] = 1;
	memcpy(g.res, g.cap, (size_t)g.nedge * sizeof(nwint));

	/* the flow between s and t, stopping at `target' */
#define QUERY(S, T, OUT) do { \
	nwint s_ = (S), t_ = (T), maxf_ = 0; \
	nwint as_ = 2 + 2 * (s_ - 1), at_ = 2 + 2 * (t_ - 1); \
	ntouched = 0; \
	g.res[as_] = big; g.res[at_] = big; \
	while (maxf_ < target) { \
		nwint qh_ = 0, qt_ = 0, found_ = 0, u_, a_, v_, pf_; \
		curstamp++; \
		queue[qt_++] = n + s_; stamp[n + s_] = curstamp; \
		while (qh_ < qt_ && !found_) { \
			u_ = queue[qh_++]; \
			for (a_ = g.head[u_]; a_ != 0; a_ = g.nxt[a_]) { \
				if (g.res[a_] > 0) { \
					v_ = g.to[a_]; \
					if (stamp[v_] != curstamp) { \
						stamp[v_] = curstamp; parent[v_] = a_; \
						if (v_ == t_) { found_ = 1; break; } \
						queue[qt_++] = v_; \
					} \
				} \
			} \
		} \
		if (!found_) break; \
		pf_ = big; v_ = t_; \
		while (v_ != n + s_) { a_ = parent[v_]; if (g.res[a_] < pf_) pf_ = g.res[a_]; v_ = g.to[a_ ^ 1]; } \
		v_ = t_; \
		while (v_ != n + s_) { a_ = parent[v_]; g.res[a_] -= pf_; g.res[a_ ^ 1] += pf_; touched[ntouched++] = a_; v_ = g.to[a_ ^ 1]; } \
		maxf_ += pf_; \
	} \
	/* back to the base capacities: only the arcs the flow used */ \
	{ nwint q_; for (q_ = 0; q_ < ntouched; q_++) { g.res[touched[q_]] = g.cap[touched[q_]]; g.res[touched[q_] ^ 1] = g.cap[touched[q_] ^ 1]; } } \
	g.res[as_] = g.cap[as_]; g.res[at_] = g.cap[at_]; \
	(OUT) = maxf_; } while (0)

	/* (2) v0 to every vertex it is not adjacent to */
	for (i = 1; i <= n && !(minflow < target); i++) {
		if (i != v0 && !isnb[i]) {
			nwint f;
			QUERY(v0, i, f);
			if (f < minflow) { minflow = f; best_s = v0; best_t = i; }
		}
	}
	/* (3) every non-adjacent pair among v0's neighbours */
	for (i = 0; i < nv0 && !(minflow < target); i++) {
		nwint ni = nbv0[i];
		memset(isnb2, 0, (size_t)(n + 1));
		for (e = rowptr[ni]; e < rowptr[ni + 1]; e++) isnb2[colidx[e]] = 1;
		for (j = i + 1; j < nv0 && !(minflow < target); j++) {
			if (!isnb2[nbv0[j]]) {
				nwint f;
				QUERY(ni, nbv0[j], f);
				if (f < minflow) { minflow = f; best_s = ni; best_t = nbv0[j]; }
			}
		}
	}
#undef QUERY

done:
	NW_VSTORE(3, 1, (double)minflow);
	NW_VSTORE(3, 2, (double)best_s);
	NW_VSTORE(3, 3, (double)best_t);
	free(deg); free(rowptr); free(colidx); free(cursor);
	free(g.head); free(g.to); free(g.nxt); free(g.cap); free(g.res);
	free(queue); free(parent); free(stamp); free(isnb); free(isnb2); free(touched);
	return rc;
}

/* ===================================================================
   Kamada-Kawai layout by stress majorization (ALG_KK_STRESS): the
   compiled counterpart to `kklayout()' (and the `distance()' it calls) in
   unw_core.do, which spends O(n^3) time on matrix powers for the graph
   distances and then Iter sweeps of n^2 interpreted steps.  Same
   quantities, same arithmetic, same order of the sums:
     distances   shortest-path hop counts by breadth-first search from every
                 node (what the matrix-power loop of distance() finds), with
                 distance() 's two quirks kept: a pair in different
                 components gets maxdist + 1, where maxdist is the largest
                 entry of the distance matrix INCLUDING its diagonal (the
                 diagonal holds 2 for a node that has a neighbour, 1 for a
                 node with a loop, because the loop over walk lengths also
                 fills the diagonal; only when n >= 3);
     weights     w_ij = 1 / d_ij^2, computed when used;
     sweeps      Gauss-Seidel: node i moves to
                 sum_j w_ij (x_j + d_ij (x_i - x_j)/|x_i - x_j|) / sum_j w_ij
                 using the positions already updated in this sweep.
   Two nodes closer than 1e-8 would make the Mata function draw random
   numbers; the plugin cannot, so it stops and reports status 1 (v5, row 1)
   and the Mata caller runs the interpreted loop instead.
   Input: v1, v2 the arcs of the symmetrised 0/1 matrix (loops included),
   v3, v4 the start coordinates; output: v3, v4 the coordinates, v5 the
   status.  Distances are kept as 16-bit integers (n up to 60,000).
   =================================================================== */

static int kk_stress(nwint n, nwint *ei, nwint *ej, nwint m, nwint iter) {
	nwint i, j, k, t, e, maxfinite = 0, maxdist, maxdiag = 0;
	nwint *deg = NULL, *rowptr = NULL, *colidx = NULL, *cursor = NULL, *queue = NULL;
	unsigned short *D = NULL;
	char *loop = NULL;
	double *px = NULL, *py = NULL;
	int rc = 0, status = 0;

	if (n > 60000) { SF_error("nwgraph: too many nodes for the layout\n"); return 198; }
	deg = (nwint *)calloc((size_t)(n + 2), sizeof(nwint));
	loop = (char *)calloc((size_t)(n + 1), 1);
	for (e = 0; e < m; e++) { if (ei[e] == ej[e]) loop[ei[e]] = 1; else deg[ei[e]]++; }
	rowptr = (nwint *)malloc((size_t)(n + 2) * sizeof(nwint));
	rowptr[1] = 0;
	for (i = 1; i <= n; i++) rowptr[i + 1] = rowptr[i] + deg[i];
	cursor = (nwint *)malloc((size_t)(n + 1) * sizeof(nwint));
	for (i = 1; i <= n; i++) cursor[i] = rowptr[i];
	colidx = (nwint *)malloc((size_t)(rowptr[n + 1] > 0 ? rowptr[n + 1] : 1) * sizeof(nwint));
	for (e = 0; e < m; e++) if (ei[e] != ej[e]) colidx[cursor[ei[e]]++] = ej[e];
	queue = (nwint *)malloc((size_t)(n + 1) * sizeof(nwint));
	D = (unsigned short *)malloc((size_t)n * (size_t)n * sizeof(unsigned short));
	px = (double *)malloc((size_t)(n + 1) * sizeof(double));
	py = (double *)malloc((size_t)(n + 1) * sizeof(double));
	if (!deg || !loop || !rowptr || !cursor || !colidx || !queue || !D || !px || !py) { rc = 909; goto cleanup; }

	for (i = 1; i <= n; i++) {
		unsigned short *Di = D + (size_t)(i - 1) * (size_t)n;
		nwint qh = 0, qt = 0;
		for (j = 0; j < n; j++) Di[j] = 0xFFFF;
		Di[i - 1] = 0;
		queue[qt++] = i;
		while (qh < qt) {
			nwint v = queue[qh++];
			for (k = rowptr[v]; k < rowptr[v + 1]; k++) {
				nwint w = colidx[k];
				if (Di[w - 1] == 0xFFFF) {
					Di[w - 1] = (unsigned short)(Di[v - 1] + 1);
					if ((nwint)Di[w - 1] > maxfinite) maxfinite = Di[w - 1];
					queue[qt++] = w;
				}
			}
		}
		if (n >= 3) {
			if (loop[i]) { if (maxdiag < 1) maxdiag = 1; }
			else if (deg[i] > 0) { if (maxdiag < 2) maxdiag = 2; }
		} else if (loop[i] && maxdiag < 1) maxdiag = 1;
	}
	maxdist = maxfinite > maxdiag ? maxfinite : maxdiag;

	for (i = 1; i <= n; i++) { ST_double v; NW_VDATA(3, i, &v); px[i] = v; NW_VDATA(4, i, &v); py[i] = v; }

	for (t = 1; t <= iter && !status; t++) {
		for (i = 1; i <= n; i++) {
			unsigned short *Di = D + (size_t)(i - 1) * (size_t)n;
			double nx = 0.0, ny = 0.0, wsum = 0.0, xi = px[i], yi = py[i];
			for (j = 1; j <= n; j++) {
				double dx, dy, dij, d, w;
				if (j == i) continue;
				dx = xi - px[j]; dy = yi - py[j];
				dij = sqrt(dx * dx + dy * dy);
				if (dij < 1e-8) { status = 1; break; }
				d = (Di[j - 1] == 0xFFFF) ? (double)(maxdist + 1) : (double)Di[j - 1];
				w = 1.0 / (d * d);
				nx = nx + w * (px[j] + d * (dx / dij));
				ny = ny + w * (py[j] + d * (dy / dij));
				wsum = wsum + w;
			}
			if (status) break;
			px[i] = nx / wsum;
			py[i] = ny / wsum;
		}
	}

	if (!status) for (i = 1; i <= n; i++) { NW_VSTORE(3, i, px[i]); NW_VSTORE(4, i, py[i]); }
	NW_VSTORE(5, 1, (double)status);

cleanup:
	free(deg); free(loop); free(rowptr); free(cursor); free(colidx); free(queue); free(D); free(px); free(py);
	return rc;
}

/* ===================================================================
   Plugin entry point
   =================================================================== */

static nwint next_long(void) {
	char *tk = strtok(NULL, " \t");
	return tk ? (nwint)atof(tk) : 0;
}

STDLL stata_call(int argc, char *argv[]) {
	char *argbuf;
	nwint algcode, n, directed, nties, source, nblock = 1, target = 0, i;
	nwint *ei = NULL, *ej = NULL;
	int rc = 0;

	if (argc < 1) { SF_error("nwgraph: missing argument string\n"); return(198); }
	if (comb_handles(argv[0])) return comb_call(argc, argv);

	argbuf = (char *)malloc(strlen(argv[0]) + 1);
	strcpy(argbuf, argv[0]);
	algcode  = (nwint)atof(strtok(argbuf, " \t"));
	n        = next_long();
	directed = next_long();
	nties    = next_long();
	/* ALG_BFS_DISTANCES carries one further argument (source), read
	   before freeing argbuf - strtok() state lives inside it. */
	source   = (algcode == ALG_BFS_DISTANCES) ? next_long() : 0;
	/* an optional number of consecutive sources (plugin kernel version 5): one call, one graph, nblock columns of distances */
	if (algcode == ALG_BFS_DISTANCES) { char *tk = strtok(NULL, " \t"); if (tk) nblock = (nwint)atof(tk); if (nblock < 1) nblock = 1; }
	if (algcode == ALG_KCONN_SEARCH || algcode == ALG_KK_STRESS) target = next_long();
	free(argbuf);

	if (nties > 0) {
		ei = (nwint *)malloc((size_t)nties * sizeof(nwint));
		ej = (nwint *)malloc((size_t)nties * sizeof(nwint));
		for (i = 0; i < nties; i++) {
			ST_double v;
			NW_VDATA(1, i + 1, &v); ei[i] = (nwint)v;
			NW_VDATA(2, i + 1, &v); ej[i] = (nwint)v;
		}
	}

	switch (algcode) {
		case ALG_BETWEENNESS:
			rc = betweenness_unweighted(n, (int)directed, ei, ej, nties);
			break;
		case ALG_BFS_DISTANCES:
			rc = bfs_distances_from(n, ei, ej, nties, source, nblock);
			break;
		case ALG_KK_STRESS:
			rc = kk_stress(n, ei, ej, nties, target);
			break;
		case ALG_KCONN_SEARCH:
			rc = kconn_search(n, ei, ej, nties, target);
			break;
		default:
			SF_error("nwgraph: unknown algorithm code\n");
			rc = 198;
	}

	free(ei);
	free(ej);
	return rc;
}
