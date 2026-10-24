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
#include <stdlib.h>
#include <string.h>

#define ALG_BETWEENNESS 1
#define ALG_BFS_DISTANCES 2
#define ALG_KCONN_SEARCH 20

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

static int betweenness_unweighted(long n, int directed, long *ei, long *ej, long nties) {
	long i, k, src;
	long *deg = NULL, *rowptr = NULL, *colidx = NULL, *cursor = NULL;
	long *stack = NULL, *queue = NULL, *dist = NULL;
	double *sigma = NULL, *delta = NULL, *Cb = NULL;
	long *predcount = NULL, *predcap = NULL;
	long **preds = NULL;
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
	deg = (long *)calloc((size_t)(n + 1), sizeof(long));
	for (i = 0; i < nties; i++) deg[ei[i]]++;
	rowptr = (long *)malloc((size_t)(n + 2) * sizeof(long));
	rowptr[1] = 0;
	for (i = 1; i <= n; i++) rowptr[i + 1] = rowptr[i] + deg[i];
	cursor = (long *)malloc((size_t)(n + 1) * sizeof(long));
	for (i = 1; i <= n; i++) cursor[i] = rowptr[i];
	colidx = (long *)malloc((size_t)(rowptr[n + 1] > 0 ? rowptr[n + 1] : 1) * sizeof(long));
	for (i = 0; i < nties; i++) colidx[cursor[ei[i]]++] = ej[i];
	free(cursor); cursor = NULL;
	free(deg); deg = NULL;

	Cb = (double *)calloc((size_t)(n + 1), sizeof(double));
	stack = (long *)malloc((size_t)n * sizeof(long));
	queue = (long *)malloc((size_t)n * sizeof(long));
	sigma = (double *)malloc((size_t)(n + 1) * sizeof(double));
	dist = (long *)malloc((size_t)(n + 1) * sizeof(long));
	delta = (double *)malloc((size_t)(n + 1) * sizeof(double));
	predcount = (long *)malloc((size_t)(n + 1) * sizeof(long));
	predcap = (long *)calloc((size_t)(n + 1), sizeof(long));
	preds = (long **)calloc((size_t)(n + 1), sizeof(long *));
	if (!Cb || !stack || !queue || !sigma || !dist || !delta || !predcount || !predcap || !preds) {
		rc = 909;
		goto cleanup;
	}

	for (src = 1; src <= n; src++) {
		long sp = 0, qh = 0, qt = 0;
		for (i = 1; i <= n; i++) { dist[i] = -1; sigma[i] = 0.0; delta[i] = 0.0; predcount[i] = 0; }
		dist[src] = 0;
		sigma[src] = 1.0;
		queue[qt++] = src;
		while (qh < qt) {
			long v = queue[qh++];
			stack[sp++] = v;
			for (k = rowptr[v]; k < rowptr[v + 1]; k++) {
				long w = colidx[k];
				if (dist[w] < 0) {
					dist[w] = dist[v] + 1;
					queue[qt++] = w;
				}
				if (dist[w] == dist[v] + 1) {
					sigma[w] += sigma[v];
					if (predcount[w] >= predcap[w]) {
						predcap[w] = predcap[w] ? predcap[w] * 2 : 4;
						preds[w] = (long *)realloc(preds[w], (size_t)predcap[w] * sizeof(long));
					}
					preds[w][predcount[w]++] = v;
				}
			}
		}
		while (sp > 0) {
			long w = stack[--sp];
			for (k = 0; k < predcount[w]; k++) {
				long v = preds[w][k];
				delta[v] += (sigma[v] / sigma[w]) * (1.0 + delta[w]);
			}
			if (w != src) Cb[w] += delta[w];
		}
	}

	if (!directed) {
		for (i = 1; i <= n; i++) Cb[i] /= 2.0;
	}

	for (i = 1; i <= n; i++) SF_vstore(3, i, Cb[i]);

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

static int bfs_distances_from(long n, long *ei, long *ej, long nties, long source) {
	long i, k;
	long *deg = NULL, *rowptr = NULL, *colidx = NULL, *cursor = NULL;
	long *queue = NULL, *dist = NULL;
	int rc = 0;

	deg = (long *)calloc((size_t)(n + 1), sizeof(long));
	for (i = 0; i < nties; i++) deg[ei[i]]++;
	rowptr = (long *)malloc((size_t)(n + 2) * sizeof(long));
	rowptr[1] = 0;
	for (i = 1; i <= n; i++) rowptr[i + 1] = rowptr[i] + deg[i];
	cursor = (long *)malloc((size_t)(n + 1) * sizeof(long));
	for (i = 1; i <= n; i++) cursor[i] = rowptr[i];
	colidx = (long *)malloc((size_t)(rowptr[n + 1] > 0 ? rowptr[n + 1] : 1) * sizeof(long));
	for (i = 0; i < nties; i++) colidx[cursor[ei[i]]++] = ej[i];
	free(cursor); cursor = NULL;
	free(deg); deg = NULL;

	dist = (long *)malloc((size_t)(n + 1) * sizeof(long));
	queue = (long *)malloc((size_t)n * sizeof(long));
	if (!dist || !queue) { rc = 909; goto cleanup; }

	for (i = 1; i <= n; i++) dist[i] = -1;
	dist[source] = 0;
	{
		long qh = 0, qt = 0;
		queue[qt++] = source;
		while (qh < qt) {
			long v = queue[qh++];
			for (k = rowptr[v]; k < rowptr[v + 1]; k++) {
				long w = colidx[k];
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
		if (i == source || dist[i] < 0) SF_vstore(3, i, SV_missval);
		else SF_vstore(3, i, (double)dist[i]);
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
	long N;              /* flow-graph nodes: in(v)=v, out(v)=n+v, 1-indexed */
	long *head, *nxt, *to;
	long *cap, *res;     /* base capacity and residual capacity per arc */
	long nedge;
} flowgraph_t;

static void fg_add(flowgraph_t *g, long u, long v, long c) {
	long e = g->nedge;
	g->to[e] = v; g->cap[e] = c; g->nxt[e] = g->head[u]; g->head[u] = e;
	g->to[e + 1] = u; g->cap[e + 1] = 0; g->nxt[e + 1] = g->head[v]; g->head[v] = e + 1;
	g->nedge += 2;
}

static int kconn_search(long n, long *ei, long *ej, long m, long target) {
	long i, j, e, delta, v0, minflow, best_s = 0, best_t = 0, big = n + 10;
	long *deg = NULL, *rowptr = NULL, *colidx = NULL, *cursor = NULL;
	char *isnb = NULL, *isnb2 = NULL;
	long *queue = NULL, *parent = NULL, *stamp = NULL, curstamp = 0;
	flowgraph_t g;
	int rc = 0;
	long nv0 = 0, *nbv0 = NULL;

	memset(&g, 0, sizeof(g));
	deg = (long *)calloc((size_t)(n + 2), sizeof(long));
	for (e = 0; e < m; e++) deg[ei[e]]++;
	delta = deg[1]; v0 = 1;
	for (i = 2; i <= n; i++) if (deg[i] < delta) { delta = deg[i]; v0 = i; }
	minflow = delta;

	if (minflow < target) goto done;

	rowptr = (long *)malloc((size_t)(n + 2) * sizeof(long));
	rowptr[1] = 0;
	for (i = 1; i <= n; i++) rowptr[i + 1] = rowptr[i] + deg[i];
	cursor = (long *)malloc((size_t)(n + 1) * sizeof(long));
	for (i = 1; i <= n; i++) cursor[i] = rowptr[i];
	colidx = (long *)malloc((size_t)(m > 0 ? m : 1) * sizeof(long));
	for (e = 0; e < m; e++) colidx[cursor[ei[e]]++] = ej[e];

	g.N = 2 * n;
	g.nedge = 0;
	g.head = (long *)calloc((size_t)(g.N + 1), sizeof(long));      /* arcs are numbered from 1; 0 = none */
	{
		long total = 2 * (n + m) + 2;
		g.to = (long *)malloc((size_t)total * sizeof(long));
		g.nxt = (long *)malloc((size_t)total * sizeof(long));
		g.cap = (long *)malloc((size_t)total * sizeof(long));
		g.res = (long *)malloc((size_t)total * sizeof(long));
	}
	queue = (long *)malloc((size_t)(g.N + 1) * sizeof(long));
	parent = (long *)malloc((size_t)(g.N + 1) * sizeof(long));
	stamp = (long *)calloc((size_t)(g.N + 1), sizeof(long));
	isnb = (char *)calloc((size_t)(n + 1), 1);
	isnb2 = (char *)calloc((size_t)(n + 1), 1);
	if (!g.head || !g.to || !g.nxt || !g.cap || !g.res || !queue || !parent || !stamp || !isnb || !isnb2) { rc = 909; goto done; }
	/* arc index 0 is a dummy so that head[]==0 means "no arc" */
	g.nedge = 2;
	for (i = 1; i <= n; i++) fg_add(&g, i, n + i, 1);              /* split arc: arc 2i+... */
	for (e = 0; e < m; e++) fg_add(&g, n + ei[e], ej[e], big);

	nv0 = rowptr[v0 + 1] - rowptr[v0];
	nbv0 = colidx + rowptr[v0];
	for (i = 0; i < nv0; i++) isnb[nbv0[i]] = 1;

	/* the flow between s and t, stopping at `target' */
#define QUERY(S, T, OUT) do { \
	long s_ = (S), t_ = (T), maxf_ = 0; \
	long as_ = 2 + 2 * (s_ - 1), at_ = 2 + 2 * (t_ - 1); \
	memcpy(g.res, g.cap, (size_t)g.nedge * sizeof(long)); \
	g.res[as_] = big; g.res[at_] = big; \
	while (maxf_ < target) { \
		long qh_ = 0, qt_ = 0, found_ = 0, u_, a_, v_, pf_; \
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
		while (v_ != n + s_) { a_ = parent[v_]; g.res[a_] -= pf_; g.res[a_ ^ 1] += pf_; v_ = g.to[a_ ^ 1]; } \
		maxf_ += pf_; \
	} \
	(OUT) = maxf_; } while (0)

	/* (2) v0 to every vertex it is not adjacent to */
	for (i = 1; i <= n && !(minflow < target); i++) {
		if (i != v0 && !isnb[i]) {
			long f;
			QUERY(v0, i, f);
			if (f < minflow) { minflow = f; best_s = v0; best_t = i; }
		}
	}
	/* (3) every non-adjacent pair among v0's neighbours */
	for (i = 0; i < nv0 && !(minflow < target); i++) {
		long ni = nbv0[i];
		memset(isnb2, 0, (size_t)(n + 1));
		for (e = rowptr[ni]; e < rowptr[ni + 1]; e++) isnb2[colidx[e]] = 1;
		for (j = i + 1; j < nv0 && !(minflow < target); j++) {
			if (!isnb2[nbv0[j]]) {
				long f;
				QUERY(ni, nbv0[j], f);
				if (f < minflow) { minflow = f; best_s = ni; best_t = nbv0[j]; }
			}
		}
	}
#undef QUERY

done:
	SF_vstore(3, 1, (double)minflow);
	SF_vstore(3, 2, (double)best_s);
	SF_vstore(3, 3, (double)best_t);
	free(deg); free(rowptr); free(colidx); free(cursor);
	free(g.head); free(g.to); free(g.nxt); free(g.cap); free(g.res);
	free(queue); free(parent); free(stamp); free(isnb); free(isnb2);
	return rc;
}

/* ===================================================================
   Plugin entry point
   =================================================================== */

static long next_long(void) {
	return (long)atof(strtok(NULL, " \t"));
}

STDLL stata_call(int argc, char *argv[]) {
	char *argbuf;
	long algcode, n, directed, nties, source, target = 0, i;
	long *ei = NULL, *ej = NULL;
	int rc = 0;

	if (argc < 1) { SF_error("nwgraph: missing argument string\n"); return(198); }

	argbuf = (char *)malloc(strlen(argv[0]) + 1);
	strcpy(argbuf, argv[0]);
	algcode  = (long)atof(strtok(argbuf, " \t"));
	n        = next_long();
	directed = next_long();
	nties    = next_long();
	/* ALG_BFS_DISTANCES carries one further argument (source), read
	   before freeing argbuf - strtok() state lives inside it. */
	source   = (algcode == ALG_BFS_DISTANCES) ? next_long() : 0;
	if (algcode == ALG_KCONN_SEARCH) target = next_long();
	free(argbuf);

	if (nties > 0) {
		ei = (long *)malloc((size_t)nties * sizeof(long));
		ej = (long *)malloc((size_t)nties * sizeof(long));
		for (i = 0; i < nties; i++) {
			ST_double v;
			SF_vdata(1, i + 1, &v); ei[i] = (long)v;
			SF_vdata(2, i + 1, &v); ej[i] = (long)v;
		}
	}

	switch (algcode) {
		case ALG_BETWEENNESS:
			rc = betweenness_unweighted(n, (int)directed, ei, ej, nties);
			break;
		case ALG_BFS_DISTANCES:
			rc = bfs_distances_from(n, ei, ej, nties, source);
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
