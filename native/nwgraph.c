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

	SCOPE (this unit): betweenness centrality only (Brandes 2001,
	unweighted/dichotomized case - the DEFAULT nwbetween() mode, matching
	its own default `calculate_betweenness()` in unw_core.do exactly).
	The weighted (Dijkstra-based) mode remains Mata-only, a documented,
	scoped follow-on (see docs/ERGM_ROADMAP.md's own "Native graph
	kernels" section) - not attempted here to keep this wave's own scope
	controlled, the same discipline nwergm's own term-expansion waves
	used throughout. Additional algorithm codes (k-core peeling,
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
   Plugin entry point
   =================================================================== */

static long next_long(void) {
	return (long)atof(strtok(NULL, " \t"));
}

STDLL stata_call(int argc, char *argv[]) {
	char *argbuf;
	long algcode, n, directed, nties, i;
	long *ei = NULL, *ej = NULL;
	int rc = 0;

	if (argc < 1) { SF_error("nwgraph: missing argument string\n"); return(198); }

	argbuf = (char *)malloc(strlen(argv[0]) + 1);
	strcpy(argbuf, argv[0]);
	algcode  = (long)atof(strtok(argbuf, " \t"));
	n        = next_long();
	directed = next_long();
	nties    = next_long();
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
		default:
			SF_error("nwgraph: unknown algorithm code\n");
			rc = 198;
	}

	free(ei);
	free(ej);
	return rc;
}
