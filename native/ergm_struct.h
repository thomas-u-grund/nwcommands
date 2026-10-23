/* ergm_struct.h - change statistics for the non-bipartite structural ergm
   terms (term codes 1000-1999), included by ergm_mcmc.c right before
   change_term().  Every function is a port of the corresponding change
   statistic in R ergm 4.12.0 (src/changestats.c, changestats_concurrentties.c,
   cpp_changestats.cpp); see the comments for the quirks that are copied on
   purpose.  `edgestate' in R is `tied' here (1 iff the dyad is currently
   tied); `delta' is +1 / -1 for adding / removing it.

   Directed graphs: outadj[]/inadj[] hold the out-/in-neighbour lists.
   Undirected graphs: adj[] holds all neighbours (R's STEP_THROUGH_OUTEDGES
   plus STEP_THROUGH_INEDGES together visit every neighbour once, which is
   what a pass over adj[] does).  ergm_mcmc.c allocates all of these whenever
   a term code in 1000-1999 is present.

   Slot convention (see ErgmNativeSetup() in unw_ergm.do): p1/p2 are the two
   generic numeric parameters of the slot, `attr' the node attribute array
   (NULL if none), `cm' the dense n x n covariate matrix (localtriangle). */

#define STC_DENSITY         1001
#define STC_MEANDEG         1002
#define STC_M2STAR          1003
#define STC_ISOLATES        1004
#define STC_ISOLATEDEDGES   1005
#define STC_DEGPOP          1006  /* degree1.5 (undirected) */
#define STC_ODEGPOP         1007
#define STC_IDEGPOP         1008
#define STC_DEGCROSSPROD    1009
#define STC_DEGCOR          1010  /* p1 = sigma2 */
#define STC_CONCTIES        1011  /* concurrentties; with attr: p1 = level */
#define STC_ALTKSTAR        1012  /* p1 = lambda */
#define STC_ASYMMETRIC      1013
#define STC_TRANSITIVE      1014
#define STC_INTRANSITIVE    1015
#define STC_CYCLE           1016  /* p1 = k, p2 = semi */
#define STC_TTRIPLE         1017
#define STC_CTRIPLE         1018
#define STC_TRIANGLE        1019
#define STC_TRIPERCENT      1020
#define STC_OPENTRIAD       1021
#define STC_THREETRAIL      1022  /* p1 = type 1..4 (directed) */
#define STC_NEARSIMMELIAN   1023
#define STC_SIMMELIAN       1024
#define STC_SIMMELIANTIES   1025
#define STC_LOCALTRIANGLE   1026
#define STC_TRIADCENSUS     1027  /* p1 = type index 1..16 (directed) / 1..4 (undirected) */
#define STC_MUTUAL          1028  /* with attr: same (p2=0) / same,diff (p2=1, p1=level) */
#define STC_MUTUALBY        1029  /* mutual(by=): p1 = level */
#define STC_CONCURRENT_BY   1030  /* concurrent(by=): p1 = level */
#define STC_DEGR_BY         1031  /* degree/degrange by attribute, undirected: p1 = from, p2 = to + level * 1e6 */
#define STC_ODEGR_BY        1032
#define STC_IDEGR_BY        1033
#define STC_DEGR_HOM        1034  /* degree/degrange with homophily: p1 = from, p2 = to */
#define STC_ODEGR_HOM       1035
#define STC_IDEGR_HOM       1036
#define STC_KSTAR_ATTR      1037  /* kstar/ostar/istar with attr: p1 = k */
#define STC_OSTAR_ATTR      1038
#define STC_ISTAR_ATTR      1039

#define S_OUT(g, v) ((g)->directed ? &(g)->outadj[(v)] : &(g)->adj[(v)])
#define S_IN(g, v)  ((g)->directed ? &(g)->inadj[(v)] : (adjlist_t *)NULL)
/* visit every neighbour k of v: out list then (directed only) in list.  A
   node that is both an out- and an in-neighbour is visited twice, exactly as
   R's STEP_THROUGH_OUTEDGES + STEP_THROUGH_INEDGES and ergm's C++
   neighbors() do.  Do not use `break' inside the body. */
#define S_NB_FOR(g, v, k) \
	{ int _pass; for (_pass = 0; _pass < 2; _pass++) { \
		adjlist_t *_L = _pass ? S_IN(g, v) : S_OUT(g, v); long _m; \
		if (!_L) continue; \
		for (_m = 0; _m < _L->len; _m++) { long k = _L->nb[_m];
#define S_NB_END }}}


/* match test shared by the "both endpoints must carry the same attribute
   value" terms: returns 0 if the slot does not apply to this dyad */
static int s_match(double *attr, double p1, double p2, long i, long j) {
	if (!attr) return 1;
	if (attr[i] != attr[j]) return 0;
	if (p2 != 0.0) return attr[i] == p1;
	return 1;
}

static int s_inr(double d, double from, double to) { return (d >= from && d < to) ? 1 : 0; }
/* number of neighbours of v (out list, plus in list when directed) carrying attribute value a */
static long s_nbcount(graph_t *g, long v, double *attr, double a, int which) {
	long cnt = 0;
	if (which == 0) { S_NB_FOR(g, v, k) if (attr[k] == a) cnt++; S_NB_END }
	else if (which == 1) { adjlist_t *L = S_OUT(g, v); long m; for (m = 0; m < L->len; m++) if (attr[L->nb[m]] == a) cnt++; }
	else { adjlist_t *L = g->directed ? &g->inadj[v] : &g->adj[v]; long m; for (m = 0; m < L->len; m++) if (attr[L->nb[m]] == a) cnt++; }
	return cnt;
}

static double s_f15(double d) { return d * sqrt(d); }

/* ---- isolatededges (R d_isolatededges, undirected only) ---- */
static double s_isolatededges(graph_t *g, long i, long j, int tied) {
	double chg = 0.0;
	long taild = g->deg[i], headd = g->deg[j];
	adjlist_t *L;
	long m;
	if (tied) {
		if (taild == 1 && headd == 1) chg -= 1.0;
		if (taild == 2) {
			L = &g->adj[i];
			for (m = 0; m < L->len; m++) if (g->deg[L->nb[m]] == 1 && L->nb[m] != j) chg += 1.0;
		}
		if (headd == 2) {
			L = &g->adj[j];
			for (m = 0; m < L->len; m++) if (g->deg[L->nb[m]] == 1 && L->nb[m] != i) chg += 1.0;
		}
	}
	else {
		if (taild == 0 && headd == 0) chg += 1.0;
		if (taild == 1) {
			L = &g->adj[i];
			for (m = 0; m < L->len; m++) if (g->deg[L->nb[m]] == 1) chg -= 1.0;
		}
		if (headd == 1) {
			L = &g->adj[j];
			for (m = 0; m < L->len; m++) if (g->deg[L->nb[m]] == 1) chg -= 1.0;
		}
	}
	return chg;
}

/* ---- degcrossprod / degcor (R c_degcrossprod / c_degcor): the neighbour
   sums run over the lists of the CURRENT graph; degcrossprod excludes tail/
   head from the sums in the add case as well, degcor does not (a no-op,
   since tail is not a neighbour of head when the dyad is untied) ---- */
static double s_degcross_core(graph_t *g, long i, long j, int tied, int excl_on_add) {
	double chg = 0.0;
	long taildeg = g->deg[i], headdeg = g->deg[j];
	if (!tied) {
		chg += (double)(taildeg + 1) * (double)(headdeg + 1);
		S_NB_FOR(g, j, k) if (!excl_on_add || k != i) chg += (double)g->deg[k]; S_NB_END
		S_NB_FOR(g, i, k) if (!excl_on_add || k != j) chg += (double)g->deg[k]; S_NB_END
	}
	else {
		chg -= (double)taildeg * (double)headdeg;
		S_NB_FOR(g, j, k) if (k != i) chg -= (double)g->deg[k]; S_NB_END
		S_NB_FOR(g, i, k) if (k != j) chg -= (double)g->deg[k]; S_NB_END
	}
	return chg;
}

/* ---- cycle(k, semi) (R cpp_changestats.cpp d_cycle) ---- */
#define STC_MAXCYC 128
static void s_path_recurse(graph_t *g, long dest, long cur, long *visited, long curlen, long *countv, long maxlen, int semi) {
	long i;
	if (g->directed) {
		if (!semi) countv[curlen] += has_edge(g, cur, dest) ? 1 : 0;
		else countv[curlen] += (has_edge(g, cur, dest) || has_edge(g, dest, cur)) ? 1 : 0;
	}
	else countv[curlen] += has_edge(g, cur, dest) ? 1 : 0;
	if (curlen < maxlen - 2) {
		adjlist_t *L;
		long m;
		visited[curlen + 1] = cur;
		L = S_OUT(g, cur);
		for (m = 0; m < L->len; m++) {
			long v = L->nb[m];
			int rflag = 1;
			for (i = 0; i <= curlen && rflag; i++) rflag = (v != visited[i]);
			if (rflag) s_path_recurse(g, dest, v, visited, curlen + 1, countv, maxlen, semi);
		}
		if (semi && g->directed) {
			L = S_IN(g, cur);
			for (m = 0; m < L->len; m++) {
				long v = L->nb[m];
				int rflag = !has_edge(g, cur, v);
				for (i = 0; i <= curlen && rflag; i++) rflag = (v != visited[i]);
				if (rflag) s_path_recurse(g, dest, v, visited, curlen + 1, countv, maxlen, semi);
			}
		}
	}
}
static double s_cycle(graph_t *g, long tail, long head, int tied, long maxlen, int semi) {
	long buf[2 * STC_MAXCYC];
	long *countv = buf, *visited = buf + maxlen;
	adjlist_t *L;
	long m;
	if (maxlen < 2 || maxlen > STC_MAXCYC) return 0.0;
	if (semi && g->directed && has_edge(g, head, tail)) return 0.0;
	memset(buf, 0, sizeof(long) * (size_t)(2 * maxlen));
	if (g->directed && !semi && has_edge(g, head, tail)) countv[0]++;
	if (g->n > 2) {
		visited[0] = tail; visited[1] = head;
		L = S_OUT(g, head);
		for (m = 0; m < L->len; m++) {
			long v = L->nb[m];
			if (v != tail) s_path_recurse(g, tail, v, visited, 1, countv, maxlen, semi);
		}
		if (semi && g->directed) {
			L = S_IN(g, head);
			for (m = 0; m < L->len; m++) {
				long v = L->nb[m];
				if (v != tail && !has_edge(g, head, v)) s_path_recurse(g, tail, v, visited, 1, countv, maxlen, semi);
			}
		}
	}
	return (tied ? -1.0 : 1.0) * (double)countv[maxlen - 2];
}

/* ---- triad census: lookup of the R triad class of a 3-node digraph.  The
   6-bit code is a12 + 2 a21 + 4 a13 + 8 a31 + 16 a23 + 32 a32; the entry is
   the 0-based position in R's list 003 012 102 021D 021U 021C 111D 111U 030T
   030C 201 120D 120U 120C 210 300 (generated with R's own summary()). ---- */
static const unsigned char s_tri_tab[64] = {
	0,1,1,2,1,3,5,7,1,5,4,6,2,7,6,10,1,5,3,7,4,8,8,12,5,9,8,13,6,13,11,14,
	1,4,5,6,5,8,9,13,3,8,8,11,7,12,13,14,2,6,7,10,6,11,13,14,7,13,12,14,10,14,14,15 };

static double s_triadcensus(graph_t *g, long i, long j, int tied, long type) {
	long k;
	double chg = 0.0;
	long n = g->n;
	for (k = 1; k <= n; k++) {
		int before, after;
		if (k == i || k == j) continue;
		if (g->directed) {
			int a12 = has_edge(g, i, j), a21 = has_edge(g, j, i);
			int a13 = has_edge(g, i, k), a31 = has_edge(g, k, i);
			int a23 = has_edge(g, j, k), a32 = has_edge(g, k, j);
			int code = a12 + 2 * a21 + 4 * a13 + 8 * a31 + 16 * a23 + 32 * a32;
			before = s_tri_tab[code];
			code = (tied ? code - 1 : code + 1);
			after = s_tri_tab[code];
		}
		else {
			int ne = (has_edge(g, i, k) ? 1 : 0) + (has_edge(g, j, k) ? 1 : 0) + (tied ? 1 : 0);
			before = ne;
			after = tied ? ne - 1 : ne + 1;
		}
		if (before == type - 1) chg -= 1.0;
		if (after == type - 1) chg += 1.0;
	}
	return chg;
}

/* ---- tripercent (R d_tripercent, undirected): temporarily adds the dyad
   when it is absent and removes it again, as R does, so the edge list is
   left exactly as found.  The `float' arithmetic is R's. ---- */
static double s_tripercent(graph_t *g, long tail, long head, int tied, double *attr, double p1, double p2) {
	long triwith = 0, triwithout = 0, twostarwith = 0, twostarwithout = 0;
	long n1, m2, m3;
	int matching = (attr != NULL);
	int diff = (p2 != 0.0);
	float ratiowith, ratiowithout;
	if (!tied) toggle(g, tail, head);
	for (n1 = 1; n1 <= g->n; n1++) {
		long degwith = 0, degwithout = 0;
		if (!(matching && diff) || attr[n1] == p1) {
			adjlist_t *L1 = &g->adj[n1];
			for (m2 = 0; m2 < L1->len; m2++) {
				long node2 = L1->nb[m2];
				if (!matching || attr[n1] == attr[node2]) {
					degwith++;
					if (!((n1 == tail && node2 == head) || (n1 == head && node2 == tail))) degwithout++;
					if (node2 > n1) {
						adjlist_t *L2 = &g->adj[node2];
						for (m3 = 0; m3 < L2->len; m3++) {
							long node3 = L2->nb[m3];
							if (node3 > node2 && (!matching || attr[node2] == attr[node3])) {
								if (has_edge(g, n1, node3)) {
									triwith++;
									if (!(((tail == n1 && head == node2) || (tail == node2 && head == n1)) ||
									      ((tail == node2 && head == node3) || (tail == node3 && head == node2)) ||
									      ((tail == n1 && head == node3) || (tail == node3 && head == n1))))
										triwithout++;
								}
							}
						}
					}
				}
			}
		}
		twostarwith += (degwith * (degwith - 1)) / 2;
		twostarwithout += (degwithout * (degwithout - 1)) / 2;
	}
	twostarwith -= 3 * triwith;
	twostarwithout -= 3 * triwithout;
	ratiowith = triwith == 0 ? 0.0f : ((float)triwith) / (float)(triwith + twostarwith);
	ratiowithout = triwith == 0 ? 0.0f : ((float)triwithout) / (float)(triwithout + twostarwithout);
	if (!tied) toggle(g, tail, head);
	return (double)(ratiowith - ratiowithout) * (tied ? -100.0 : 100.0);
}

static double change_struct(graph_t *g, int code, double p1, double p2, double *attr, double *cm, long n, double delta, long i, long j) {
	int tied = (delta < 0.0);
	double chg = 0.0;
	switch (code) {
		case STC_DENSITY:
			return delta / (g->directed ? (double)n * (double)(n - 1) : (double)n * (double)(n - 1) / 2.0);
		case STC_MEANDEG:
			return delta * (g->directed ? 1.0 : 2.0) / (double)n;
		case STC_M2STAR: {
			double back = has_edge(g, j, i) ? 1.0 : 0.0;
			double c = (double)g->indeg[i] + (double)g->outdeg[j] - 2.0 * back;
			return delta * c;
		}
		case STC_ISOLATES: {
			long di = g->deg[i], dj = g->deg[j];
			int e = (int)delta;
			chg += (double)((di + e == 0) - (di == 0));
			chg += (double)((dj + e == 0) - (dj == 0));
			return chg;
		}
		case STC_ISOLATEDEDGES:
			return s_isolatededges(g, i, j, tied);
		case STC_DEGPOP:
			return (s_f15((double)g->deg[i] + delta) - s_f15((double)g->deg[i])) + (s_f15((double)g->deg[j] + delta) - s_f15((double)g->deg[j]));
		case STC_ODEGPOP:
			return s_f15((double)g->outdeg[i] + delta) - s_f15((double)g->outdeg[i]);
		case STC_IDEGPOP:
			return s_f15((double)g->indeg[j] + delta) - s_f15((double)g->indeg[j]);
		case STC_DEGCROSSPROD:
			return s_degcross_core(g, i, j, tied, 1) / p1;
		case STC_DEGCOR:
			return s_degcross_core(g, i, j, tied, 0) * (2.0 / p1);
		case STC_CONCTIES: {
			long di = g->deg[i], dj = g->deg[j];
			if (!attr) {
				if (!tied) { if (di >= 1) chg += 1.0; if (dj >= 1) chg += 1.0; }
				else { if (di >= 2) chg -= 1.0; if (dj >= 2) chg -= 1.0; }
			}
			else {
				if (!tied) { if (attr[i] == p1 && di >= 1) chg += 1.0; if (attr[j] == p1 && dj >= 1) chg += 1.0; }
				else { if (attr[i] == p1 && di >= 2) chg -= 1.0; if (attr[j] == p1 && dj >= 2) chg -= 1.0; }
			}
			return chg;
		}
		case STC_CONCURRENT_BY: {
			long di = g->deg[i], dj = g->deg[j];
			int e = (int)delta;
			if (attr[i] == p1) chg += (double)((di + e > 1) - (di > 1));
			if (attr[j] == p1) chg += (double)((dj + e > 1) - (dj > 1));
			return chg;
		}
		case STC_ALTKSTAR: {
			double oneexpl = 1.0 - 1.0 / p1;
			double taild = (double)g->deg[i] - (tied ? 1.0 : 0.0);
			double headd = (double)g->deg[j] - (tied ? 1.0 : 0.0);
			if (taild != 0.0) chg += delta * (1.0 - pow(oneexpl, taild));
			if (headd != 0.0) chg += delta * (1.0 - pow(oneexpl, headd));
			return chg * p1;
		}
		case STC_ASYMMETRIC: {
			double c = ((tied ? 1 : 0) == (has_edge(g, j, i) ? 1 : 0)) ? 1.0 : -1.0;
			if (!s_match(attr, p1, p2, i, j)) return 0.0;
			return c;
		}
		case STC_MUTUAL: {
			if (!has_edge(g, j, i)) return 0.0;
			if (!s_match(attr, p1, p2, i, j)) return 0.0;
			return delta;
		}
		case STC_MUTUALBY: {
			if (!has_edge(g, j, i)) return 0.0;
			if (attr[i] == p1) chg += delta;
			if (attr[j] == p1) chg += delta;
			return chg;
		}
		case STC_TRANSITIVE: {
			double c = 0.0;
			S_NB_FOR(g, j, k)
				/* out-neighbours of head first (pass 0), then in-neighbours (pass 1) */
				if (_pass == 0) { if (i != k && has_edge(g, i, k)) c += 1.0; }
				else { if (i != k) c += (has_edge(g, i, k) ? 1.0 : 0.0) + (has_edge(g, k, i) ? 1.0 : 0.0); }
			S_NB_END
			return delta * c;
		}
		case STC_INTRANSITIVE: {
			double c = 0.0;
			adjlist_t *L;
			long m;
			L = &g->outadj[j];
			for (m = 0; m < L->len; m++) { long k = L->nb[m]; if (k != i && !has_edge(g, i, k)) c += 1.0; }
			L = &g->inadj[j];
			for (m = 0; m < L->len; m++) { long k = L->nb[m]; if (k != i && has_edge(g, i, k)) c -= 1.0; }
			L = &g->inadj[i];
			for (m = 0; m < L->len; m++) { long k = L->nb[m]; if (k != j && !has_edge(g, k, j)) c += 1.0; }
			return tied ? -c : c;
		}
		case STC_CYCLE:
			return s_cycle(g, i, j, tied, (long)p1, (int)p2);
		case STC_TTRIPLE: {
			double c = 0.0;
			if (!attr) {
				S_NB_FOR(g, j, k)
					if (_pass == 0) c += has_edge(g, i, k) ? 1.0 : 0.0;           /* IS_INEDGE(node3,tail) = tail->node3 */
					else c += (has_edge(g, k, i) ? 1.0 : 0.0) + (has_edge(g, i, k) ? 1.0 : 0.0);
				S_NB_END
				return delta * c;
			}
			if (attr[i] != attr[j]) return 0.0;
			if (p2 != 0.0 && attr[i] != p1) return 0.0;
			S_NB_FOR(g, j, k)
				if (attr[i] == attr[k]) {
					if (_pass == 0) c += has_edge(g, i, k) ? 1.0 : 0.0;
					else c += (has_edge(g, k, i) ? 1.0 : 0.0) + (has_edge(g, i, k) ? 1.0 : 0.0);
				}
			S_NB_END
			return delta * c;
		}
		case STC_CTRIPLE: {
			double c = 0.0;
			if (attr) {
				if (attr[i] != attr[j]) return 0.0;
				if (p2 != 0.0 && attr[i] != p1) return 0.0;
			}
			{
				adjlist_t *L = &g->outadj[j];
				long m;
				for (m = 0; m < L->len; m++) {
					long k = L->nb[m];
					if (attr && attr[i] != attr[k]) continue;
					if (has_edge(g, k, i)) c += 1.0;
				}
			}
			return delta * c;
		}
		case STC_TRIANGLE: {
			double c = 0.0;
			if (attr) {
				if (attr[i] == 0.0 || attr[i] != attr[j]) return 0.0;
				if (p2 != 0.0 && attr[i] != p1) return 0.0;
			}
			S_NB_FOR(g, j, k)
				if (!attr || attr[i] == attr[k]) {
					if (g->directed) c += (has_edge(g, k, i) ? 1.0 : 0.0) + (has_edge(g, i, k) ? 1.0 : 0.0);
					else c += has_edge(g, k, i) ? 1.0 : 0.0;
				}
			S_NB_END
			return delta * c;
		}
		case STC_TRIPERCENT:
			return s_tripercent(g, i, j, tied, attr, p1, p2);
		case STC_OPENTRIAD: {
			double c = 0.0, c2;
			S_NB_FOR(g, j, k) if (has_edge(g, k, i)) c += 1.0; S_NB_END
			chg = c * (tied ? 3.0 : -3.0);
			c2 = ((double)g->deg[i] - (tied ? 1.0 : 0.0)) + ((double)g->deg[j] - (tied ? 1.0 : 0.0));
			return chg + (tied ? -c2 : c2);
		}
		case STC_THREETRAIL: {
			if (!g->directed) {
				double es = tied ? 1.0 : 0.0, c = 0.0;
				c = ((double)g->deg[i] - es) * ((double)g->deg[j] - es);
				{
					adjlist_t *L = &g->adj[j];
					long m;
					for (m = 0; m < L->len; m++) { long k = L->nb[m]; if (k != i) c += (double)g->deg[k] - 1.0; }
					L = &g->adj[i];
					for (m = 0; m < L->len; m++) { long k = L->nb[m]; if (k != j) c += (double)g->deg[k] - 1.0; }
				}
				return tied ? -c : c;
			}
			else {
				long es = tied ? 1 : 0;
				long d[4];
				adjlist_t *L;
				long m;
				d[0] = g->indeg[i] * g->outdeg[j];
				d[1] = g->indeg[i] * (g->indeg[j] - es);
				d[2] = (g->outdeg[i] - es) * g->outdeg[j];
				d[3] = (g->outdeg[i] - es) * (g->indeg[j] - es);
				L = &g->outadj[j];
				for (m = 0; m < L->len; m++) { long k = L->nb[m]; d[1] += g->indeg[k] - 1; d[0] += g->outdeg[k]; }
				L = &g->inadj[j];
				for (m = 0; m < L->len; m++) { long k = L->nb[m]; if (k != i) { d[3] += g->outdeg[k] - 1; d[1] += g->indeg[k]; } }
				L = &g->inadj[i];
				for (m = 0; m < L->len; m++) { long k = L->nb[m]; d[2] += g->outdeg[k] - 1; d[0] += g->indeg[k]; }
				L = &g->outadj[i];
				for (m = 0; m < L->len; m++) { long k = L->nb[m]; if (k != j) { d[3] += g->indeg[k] - 1; d[2] += g->outdeg[k]; } }
				d[0] -= (has_edge(g, j, i) ? 1 : 0) * (1 + 2 * es);
				{
					long t = (long)p1;
					return tied ? -(double)d[t - 1] : (double)d[t - 1];
				}
			}
		}
		case STC_NEARSIMMELIAN: {
			long k;
			int edgestateth = !has_edge(g, j, i);
			for (k = 1; k <= n; k++) {
				if (k != i && k != j) {
					int sc = edgestateth + (!has_edge(g, k, i));
					if (sc < 2) {
						sc += (!has_edge(g, i, k));
						if (sc < 2) {
							sc += (!has_edge(g, k, j));
							if (sc < 2) {
								sc += (!has_edge(g, j, k));
								if (sc < 2) {
									double c = 0.0;
									if (sc == 0 && !tied) c -= 1.0;
									if (sc == 0 && tied) c += 1.0;
									if (sc == 1 && !tied) c += 1.0;
									if (sc == 1 && tied) c -= 1.0;
									chg += c;
								}
							}
						}
					}
				}
			}
			return chg;
		}
		case STC_SIMMELIAN: {
			double c = 0.0;
			if (has_edge(g, j, i)) {
				adjlist_t *L = &g->outadj[j];
				long m;
				for (m = 0; m < L->len; m++) {
					long k = L->nb[m];
					if (k != i && has_edge(g, k, i) && has_edge(g, i, k) && has_edge(g, k, j)) c += 1.0;
				}
				return tied ? -c : c;
			}
			return 0.0;
		}
		case STC_SIMMELIANTIES: {
			if (has_edge(g, j, i)) {
				long change = 0, htflag = 0;
				adjlist_t *L = &g->outadj[j];
				long m, m2;
				for (m = 0; m < L->len; m++) {
					long k = L->nb[m];
					if (k != i && has_edge(g, k, i) && has_edge(g, i, k) && has_edge(g, k, j)) {
						int first = 1;
						adjlist_t *L2;
						htflag = 1;
						L2 = &g->outadj[i];
						for (m2 = 0; m2 < L2->len; m2++) {
							long k4 = L2->nb[m2];
							if (k4 != j && k4 != k && has_edge(g, k4, i) && has_edge(g, k4, k) && has_edge(g, k, k4)) first = 0;
						}
						if (first) change++;
						first = 1;
						L2 = &g->outadj[j];
						for (m2 = 0; m2 < L2->len; m2++) {
							long k4 = L2->nb[m2];
							if (k4 != i && k4 != k && has_edge(g, k4, j) && has_edge(g, k4, k) && has_edge(g, k, k4)) first = 0;
						}
						if (first) change++;
					}
				}
				change += htflag;
				change = 2 * change;
				return tied ? -(double)change : (double)change;
			}
			return 0.0;
		}
		case STC_LOCALTRIANGLE: {
			double c = 0.0;
			if (cm[(i - 1) * n + (j - 1)] == 1.0) {
				S_NB_FOR(g, j, k)
					if (cm[(i - 1) * n + (k - 1)] == 1.0 && cm[(j - 1) * n + (k - 1)] == 1.0) {
						if (g->directed) {
							if (has_edge(g, i, k)) c += 1.0;
							if (has_edge(g, k, i)) c += 1.0;
						}
						else if (has_edge(g, k, i)) c += 1.0;
					}
				S_NB_END
				return tied ? -c : c;
			}
			return 0.0;
		}
		case STC_TRIADCENSUS:
			return s_triadcensus(g, i, j, tied, (long)p1);
		case STC_DEGR_BY: case STC_ODEGR_BY: case STC_IDEGR_BY: {
			double lev = floor(p2 / 1e6), to = p2 - lev * 1e6;
			double e = delta;
			if (code == STC_DEGR_BY) {
				if (attr[i] == lev) chg += s_inr((double)g->deg[i] + e, p1, to) - s_inr((double)g->deg[i], p1, to);
				if (attr[j] == lev) chg += s_inr((double)g->deg[j] + e, p1, to) - s_inr((double)g->deg[j], p1, to);
			}
			else if (code == STC_ODEGR_BY) {
				if (attr[i] == lev) chg += s_inr((double)g->outdeg[i] + e, p1, to) - s_inr((double)g->outdeg[i], p1, to);
			}
			else {
				if (attr[j] == lev) chg += s_inr((double)g->indeg[j] + e, p1, to) - s_inr((double)g->indeg[j], p1, to);
			}
			return chg;
		}
		case STC_DEGR_HOM: case STC_ODEGR_HOM: case STC_IDEGR_HOM: {
			if (attr[i] != attr[j]) return 0.0;
			if (code == STC_DEGR_HOM) {
				double ti = (double)s_nbcount(g, i, attr, attr[i], 0), tj = (double)s_nbcount(g, j, attr, attr[j], 0);
				chg += s_inr(ti + delta, p1, p2) - s_inr(ti, p1, p2);
				chg += s_inr(tj + delta, p1, p2) - s_inr(tj, p1, p2);
			}
			else if (code == STC_ODEGR_HOM) {
				double ti = (double)s_nbcount(g, i, attr, attr[i], 1);
				chg += s_inr(ti + delta, p1, p2) - s_inr(ti, p1, p2);
			}
			else {
				double tj = (double)s_nbcount(g, j, attr, attr[j], 2);
				chg += s_inr(tj + delta, p1, p2) - s_inr(tj, p1, p2);
			}
			return chg;
		}
		case STC_KSTAR_ATTR: {
			double es = tied ? 1.0 : 0.0, ti, tj, c;
			if (attr[i] != attr[j]) return 0.0;
			ti = (double)s_nbcount(g, i, attr, attr[i], 0) - es;
			tj = (double)s_nbcount(g, j, attr, attr[i], 0) - es;
			c = ergm_choose(ti, p1 - 1.0) + ergm_choose(tj, p1 - 1.0);
			return tied ? -c : c;
		}
		case STC_OSTAR_ATTR: {
			double es = tied ? 1.0 : 0.0, hd, c;
			if (attr[i] != attr[j]) return 0.0;
			hd = (double)s_nbcount(g, i, attr, attr[j], 1) - es;
			c = ergm_choose(hd, p1 - 1.0);
			return tied ? -c : c;
		}
		case STC_ISTAR_ATTR: {
			double es = tied ? 1.0 : 0.0, hd, c;
			if (attr[i] != attr[j]) return 0.0;
			hd = (double)s_nbcount(g, j, attr, attr[i], 2) - es;
			c = ergm_choose(hd, p1 - 1.0);
			return tied ? -c : c;
		}
	}
	return 0.0;
}
