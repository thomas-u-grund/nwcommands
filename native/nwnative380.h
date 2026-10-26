/*
	nwnative380.h -- native (C) kernel for the bipartite motif counts of nw2motifs.

	#included by nwcomb.h after nwnative370.h (one plugin binary); NWCOMB_VERSION 11 announces it.  Wire protocol
	as in nwcomb.h: ties (ego, alter, weight) in variables 1..3, one value per node in variable 4, the result
	stays in static memory (g_res) and is copied out by the FETCH call (alg 99).  Status 2 = out of memory.

	50  bmotif  par: sixnode.  Node position counts of the bipartite motifs of Simmons et al. (2019), as
	            bmotif::node_positions (Baker et al. 2015; Stouffer 2012): for every node, the number of
	            induced connected subgraphs of 2..5 nodes (2..6 with sixnode) in which it holds each of the
	            46 (148) node positions of the dictionary of bmotif 2.0.2 (native/nwbmotif_dict.h, generated
	            by tools/gen_bmotif_dict.R).  Ties = the cross-mode ties with a value above zero (either
	            direction, repeated ties count once); variable 4 = the mode (1 or 2) of every node, mode 1 =
	            the rows of the biadjacency matrix of bmotif.  Result n x 46 (n x 148) in network order.
	            The motif frequencies are the column sums of the positions of a motif divided by its number
	            of nodes (done by the caller).

	Method.  An induced subgraph with k nodes on one side (the "S side") and t nodes on the other is described
	by its k S nodes and the way the t other nodes (the "T nodes") are tied to them: a T node has a pattern, a
	non-empty subset of the k S nodes.  For a k-set of S nodes the T nodes fall into 2^k - 1 classes of equal
	pattern with sizes n_p; the number of induced subgraphs with x_p T nodes of class p is the product of the
	binomials C(n_p, x_p), and each S node takes part in all of them, a T node of class p in the fraction x_p / n_p
	of them.  Which motif and which node position a (k, x) configuration is, comes from matching a small
	graph against the dictionary once at the start.  k = 1 for the shapes 1 x t and t x 1, k = 2 for 2 x t and
	t x 2 (only pairs with a common neighbour matter), k = 3 for 3 x 3 (six nodes; the three S nodes must be
	connected through the T side).  Every induced subgraph is counted exactly once (the shape fixes the side
	of the S nodes).  Counts are doubles (exact up to 2^53).
*/

#include "nwbmotif_dict.h"

#define ALG_BMOTIF 50

#define N380_MAXCLS 7
#define N380_MAXCFG 128

typedef struct {
	int t;                 /* number of T nodes */
	int x[N380_MAXCLS + 1];   /* x[p]: T nodes of class p (pattern p = 1..2^k-1) */
	int id;                /* motif id 1..44, 0 = disconnected (not counted) */
	int spos[3];           /* position id of the S nodes */
	int cpos[N380_MAXCLS + 1]; /* position id of a T node of class p */
} n380_cfg_t;

typedef struct {
	int ncfg;
	n380_cfg_t cfg[N380_MAXCFG];
} n380_cfglist_t;

/* all permutations of 0..m-1, m <= 5 */
static int n380_perms(int m, int out[120][5]) {
	int idx[5], used[5], cnt = 0, d;
	for (d = 0; d < 5; d++) { idx[d] = -1; used[d] = 0; }
	d = 0;
	while (d >= 0) {
		int v;
		if (d == m) {
			int i;
			for (i = 0; i < m; i++) out[cnt][i] = idx[i];
			cnt++;
			d--;
			if (d >= 0) used[idx[d]] = 0;
			continue;
		}
		for (v = idx[d] + 1; v < m; v++) if (!used[v]) break;
		if (v >= m) { idx[d] = -1; d--; if (d >= 0) used[idx[d]] = 0; continue; }
		idx[d] = v;
		used[v] = 1;
		d++;
	}
	return cnt;
}

/* match the configuration (side of the S nodes, k, class sizes x) against the dictionary; 0 = disconnected */
static void n380_classify(int side, int k, const int *x, n380_cfg_t *c) {
	int pat[6], t = 0, p, j, a, b, m, i;
	int adj[5];
	static int rp[120][5], cp[120][5];
	int nrp, ncp, ir, ic;

	for (p = 1; p < (1 << k); p++) for (j = 0; j < x[p]; j++) pat[t++] = p;
	c->t = t;
	c->id = 0;
	for (p = 1; p <= N380_MAXCLS; p++) { c->x[p] = (p < (1 << k)) ? x[p] : 0; c->cpos[p] = 0; }
	c->spos[0] = c->spos[1] = c->spos[2] = 0;
	if (side == 0) {
		a = k; b = t;
		for (i = 0; i < a; i++) { adj[i] = 0; for (j = 0; j < b; j++) if (pat[j] & (1 << i)) adj[i] |= 1 << j; }
	}
	else {
		a = t; b = k;
		for (i = 0; i < a; i++) adj[i] = pat[i];
	}
	for (m = 0; m < 44; m++) {
		const n380_proto_t *pr = &N380_PROTO[m];
		if (pr->a != a || pr->b != b) continue;
		nrp = n380_perms(a, rp);
		ncp = n380_perms(b, cp);
		for (ir = 0; ir < nrp; ir++) {
			for (ic = 0; ic < ncp; ic++) {
				int ok = 1;
				for (i = 0; i < a && ok; i++) {
					int mapped = 0;
					for (j = 0; j < b; j++) if (adj[i] & (1 << j)) mapped |= 1 << cp[ic][j];
					if (mapped != pr->adj[rp[ir][i]]) ok = 0;
				}
				if (!ok) continue;
				c->id = m + 1;
				if (side == 0) {
					for (i = 0; i < k; i++) c->spos[i] = pr->pos[rp[ir][i]];
					for (j = 0; j < t; j++) c->cpos[pat[j]] = pr->pos[a + cp[ic][j]];
				}
				else {
					for (i = 0; i < k; i++) c->spos[i] = pr->pos[a + cp[ic][i]];
					for (j = 0; j < t; j++) c->cpos[pat[j]] = pr->pos[rp[ir][j]];
				}
				return;
			}
		}
	}
}

static void n380_compose(int side, int k, int t, int p, int *x, int left, n380_cfglist_t *L) {
	int ncls = (1 << k) - 1;
	if (p == ncls) {
		n380_cfg_t c;
		x[p] = left;
		n380_classify(side, k, x, &c);
		if (c.id > 0 && L->ncfg < N380_MAXCFG) L->cfg[L->ncfg++] = c;
		return;
	}
	{
		int v;
		for (v = 0; v <= left; v++) { x[p] = v; n380_compose(side, k, t, p + 1, x, left - v, L); }
	}
}

static void n380_cfgs(int side, int k, int tmin, int tmax, n380_cfglist_t *L) {
	int t, x[N380_MAXCLS + 2];
	L->ncfg = 0;
	for (t = tmin; t <= tmax; t++) {
		int p;
		for (p = 0; p <= N380_MAXCLS + 1; p++) x[p] = 0;
		n380_compose(side, k, t, 1, x, t, L);
	}
}

static double n380_ch(double n, int r) {
	double res = 1.0;
	int i;
	if (r < 0 || n < (double)r) return 0.0;
	for (i = 0; i < r; i++) res = res * (n - (double)i) / (double)(i + 1);
	return res;
}

/* one side of the biadjacency structure */
typedef struct {
	nwint nS, nT;
	const nwint *sptr, *sidx;   /* S -> T */
	const nwint *tptr, *tidx;   /* T -> S */
	const nwint *snode, *tnode; /* network node (0-based) of S and T vertices */
} n380_side_t;

typedef struct { int cls; int pos; double val; } n380_ent_t;

/* credit one tuple of S nodes (k, network nodes sn[]) with class sizes np[] and class members cl[p] (T vertex numbers) */
static void n380_apply(double *out, nwint P, const n380_side_t *G, int k, const nwint *sn, const nwint *np,
		nwint *const *cl, const n380_cfglist_t *L) {
	n380_ent_t ent[1024];
	int nent = 0, ic, p, e;
	nwint q;
	for (ic = 0; ic < L->ncfg; ic++) {
		const n380_cfg_t *c = &L->cfg[ic];
		double tot = 1.0, per[N380_MAXCLS + 1];
		int ncls = (1 << k) - 1, i;
		for (p = 1; p <= ncls; p++) {
			if (c->x[p] > 0) {
				if ((double)np[p] < (double)c->x[p]) { tot = 0; break; }
			}
		}
		if (tot == 0) continue;
		for (p = 1; p <= ncls; p++) per[p] = n380_ch((double)np[p], c->x[p]);
		for (p = 1; p <= ncls; p++) tot *= per[p];
		if (tot == 0) continue;
		for (i = 0; i < k; i++) out[sn[i] * P + c->spos[i] - 1] += tot;
		for (p = 1; p <= ncls; p++) {
			double val;
			int q2;
			if (c->x[p] == 0) continue;
			val = n380_ch((double)np[p] - 1.0, c->x[p] - 1);
			for (q2 = 1; q2 <= ncls; q2++) if (q2 != p) val *= per[q2];
			for (e = 0; e < nent; e++) if (ent[e].cls == p && ent[e].pos == c->cpos[p]) break;
			if (e == nent) { ent[nent].cls = p; ent[nent].pos = c->cpos[p]; ent[nent].val = 0; nent++; }
			ent[e].val += val;
		}
	}
	for (e = 0; e < nent; e++) {
		const nwint *m = cl[ent[e].cls];
		nwint cnt = np[ent[e].cls];
		for (q = 0; q < cnt; q++) out[G->tnode[m[q]] * P + ent[e].pos - 1] += ent[e].val;
	}
}

static void n380_k1(double *out, nwint P, const n380_side_t *G, const n380_cfglist_t *L) {
	nwint u;
	for (u = 0; u < G->nS; u++) {
		nwint np[N380_MAXCLS + 1], sn[3];
		nwint *cl[N380_MAXCLS + 1];
		nwint d = G->sptr[u + 1] - G->sptr[u];
		if (d == 0) continue;
		np[1] = d;
		cl[1] = (nwint *)(G->sidx + G->sptr[u]);
		sn[0] = G->snode[u];
		n380_apply(out, P, G, 1, sn, np, cl, L);
	}
}

/* class buckets of the T nodes of the S nodes sv[0..k-1]; returns 0, or 1 when out of memory (scratch given) */
static void n380_classes(const n380_side_t *G, int k, const nwint *sv, unsigned char *msk, nwint *touched, nwint *buf,
		nwint *np, nwint **cl) {
	nwint nt = 0, i, w;
	int j, p, ncls = (1 << k) - 1;
	nwint off[N380_MAXCLS + 2], fill[N380_MAXCLS + 2];
	for (j = 0; j < k; j++) {
		for (i = G->sptr[sv[j]]; i < G->sptr[sv[j] + 1]; i++) {
			w = G->sidx[i];
			if (msk[w] == 0) touched[nt++] = w;
			msk[w] |= (unsigned char)(1 << j);
		}
	}
	for (p = 1; p <= ncls; p++) np[p] = 0;
	for (i = 0; i < nt; i++) np[msk[touched[i]]]++;
	off[1] = 0;
	for (p = 1; p <= ncls; p++) { cl[p] = buf + off[p]; fill[p] = 0; off[p + 1] = off[p] + np[p]; }
	for (i = 0; i < nt; i++) {
		p = msk[touched[i]];
		cl[p][fill[p]++] = touched[i];
		msk[touched[i]] = 0;
	}
}

static int n380_k2(double *out, nwint P, const n380_side_t *G, const n380_cfglist_t *L) {
	nwint *cnt = (nwint *)calloc((size_t)(G->nS > 0 ? G->nS : 1), sizeof(nwint));
	nwint *tch = (nwint *)malloc((size_t)(G->nS > 0 ? G->nS : 1) * sizeof(nwint));
	unsigned char *msk = (unsigned char *)calloc((size_t)(G->nT > 0 ? G->nT : 1), 1);
	nwint *touched = (nwint *)malloc((size_t)(G->nT > 0 ? G->nT : 1) * sizeof(nwint));
	nwint *buf = (nwint *)malloc((size_t)(G->nT > 0 ? G->nT : 1) * sizeof(nwint));
	nwint u, i, j, ntc;
	if (!cnt || !tch || !msk || !touched || !buf) { free(cnt); free(tch); free(msk); free(touched); free(buf); return 2; }
	for (u = 0; u < G->nS; u++) {
		ntc = 0;
		for (i = G->sptr[u]; i < G->sptr[u + 1]; i++) {
			nwint w = G->sidx[i];
			for (j = G->tptr[w]; j < G->tptr[w + 1]; j++) {
				nwint v = G->tidx[j];
				if (v <= u) continue;
				if (cnt[v] == 0) tch[ntc++] = v;
				cnt[v]++;
			}
		}
		for (i = 0; i < ntc; i++) {
			nwint v = tch[i], sv[2], np[N380_MAXCLS + 1], sn[3];
			nwint *cl[N380_MAXCLS + 1];
			cnt[v] = 0;
			sv[0] = u; sv[1] = v;
			n380_classes(G, 2, sv, msk, touched, buf, np, cl);
			sn[0] = G->snode[u]; sn[1] = G->snode[v];
			n380_apply(out, P, G, 2, sn, np, cl, L);
		}
	}
	free(cnt); free(tch); free(msk); free(touched); free(buf);
	return 0;
}

/* common neighbour of two S nodes by merging the sorted lists */
static int n380_common(const n380_side_t *G, nwint a, nwint b) {
	nwint i = G->sptr[a], ie = G->sptr[a + 1], j = G->sptr[b], je = G->sptr[b + 1];
	while (i < ie && j < je) {
		if (G->sidx[i] == G->sidx[j]) return 1;
		if (G->sidx[i] < G->sidx[j]) i++; else j++;
	}
	return 0;
}

static int n380_k3(double *out, nwint P, const n380_side_t *G, const n380_cfglist_t *L) {
	nwint nS = G->nS;
	unsigned char *bits = NULL;
	nwint words = (nS + 7) / 8;
	nwint *cnt = (nwint *)calloc((size_t)(nS > 0 ? nS : 1), sizeof(nwint));
	nwint *nh = (nwint *)malloc((size_t)(nS > 0 ? nS : 1) * sizeof(nwint));
	unsigned char *msk = (unsigned char *)calloc((size_t)(G->nT > 0 ? G->nT : 1), 1);
	nwint *touched = (nwint *)malloc((size_t)(G->nT > 0 ? G->nT : 1) * sizeof(nwint));
	nwint *buf = (nwint *)malloc((size_t)(G->nT > 0 ? G->nT : 1) * sizeof(nwint));
	nwint b, i, j, ia, ic;
	int usebits = (nS <= 8192);
	if (!cnt || !nh || !msk || !touched || !buf) { free(cnt); free(nh); free(msk); free(touched); free(buf); return 2; }
	if (usebits) {
		bits = (unsigned char *)calloc((size_t)(nS > 0 ? nS : 1) * (size_t)(words > 0 ? words : 1), 1);
		if (!bits) { free(cnt); free(nh); free(msk); free(touched); free(buf); return 2; }
		for (b = 0; b < nS; b++) {
			for (i = G->sptr[b]; i < G->sptr[b + 1]; i++) {
				nwint w = G->sidx[i];
				for (j = G->tptr[w]; j < G->tptr[w + 1]; j++) {
					nwint v = G->tidx[j];
					if (v != b) bits[b * words + (v >> 3)] |= (unsigned char)(1 << (v & 7));
				}
			}
		}
	}
	for (b = 0; b < nS; b++) {
		nwint nn = 0;
		for (i = G->sptr[b]; i < G->sptr[b + 1]; i++) {
			nwint w = G->sidx[i];
			for (j = G->tptr[w]; j < G->tptr[w + 1]; j++) {
				nwint v = G->tidx[j];
				if (v == b) continue;
				if (cnt[v] == 0) nh[nn++] = v;
				cnt[v]++;
			}
		}
		for (i = 0; i < nn; i++) cnt[nh[i]] = 0;
		for (ia = 0; ia < nn; ia++) {
			for (ic = ia + 1; ic < nn; ic++) {
				nwint a = nh[ia], c = nh[ic], sv[3], np[N380_MAXCLS + 1], sn[3];
				nwint *cl[N380_MAXCLS + 1];
				int adjac;
				adjac = usebits ? ((bits[a * words + (c >> 3)] >> (c & 7)) & 1) : n380_common(G, a, c);
				if (adjac && !(b < a && b < c)) continue;
				sv[0] = a; sv[1] = b; sv[2] = c;
				n380_classes(G, 3, sv, msk, touched, buf, np, cl);
				sn[0] = G->snode[a]; sn[1] = G->snode[b]; sn[2] = G->snode[c];
				n380_apply(out, P, G, 3, sn, np, cl, L);
			}
		}
	}
	free(bits); free(cnt); free(nh); free(msk); free(touched); free(buf);
	return 0;
}

static int n380_cmp_long(const void *a, const void *b) {
	nwint x = *(const nwint *)a, y = *(const nwint *)b;
	return x < y ? -1 : (x > y ? 1 : 0);
}

static int comb_bmotif(nwint n, nwint nties, const nwint *ei, const nwint *ej, const double *ew, const double *nv, int six) {
	nwint P = six ? 148 : 46;
	int maxn = six ? 6 : 5;
	nwint *rid = NULL, *cid = NULL, *rnode = NULL, *cnode = NULL;
	nwint nR = 0, nC = 0, k, r, c, e;
	nwint *rp = NULL, *ri = NULL, *cp = NULL, *ci = NULL, *rdeg = NULL, *cdeg = NULL, *pr = NULL, *pc = NULL;
	nwint nm = 0;
	double *out;
	n380_side_t GR, GC;
	n380_cfglist_t *L = NULL;
	int rc = 0;

	if (n < 0) n = 0;
	if (res_alloc(n, P)) return 2;
	out = g_res;
	memset(out, 0, (size_t)(n > 0 ? n * P : 1) * sizeof(double));
	rid = (nwint *)malloc((size_t)(n > 0 ? n : 1) * sizeof(nwint));
	cid = (nwint *)malloc((size_t)(n > 0 ? n : 1) * sizeof(nwint));
	rnode = (nwint *)malloc((size_t)(n > 0 ? n : 1) * sizeof(nwint));
	cnode = (nwint *)malloc((size_t)(n > 0 ? n : 1) * sizeof(nwint));
	if (!rid || !cid || !rnode || !cnode) { rc = 2; goto done; }
	for (k = 0; k < n; k++) {
		rid[k] = cid[k] = -1;
		if (nv[k] == 1) { rid[k] = nR; rnode[nR++] = k; }
		else if (nv[k] == 2) { cid[k] = nC; cnode[nC++] = k; }
	}
	/* cross-mode ties as (row, column) pairs */
	pr = (nwint *)malloc((size_t)(nties > 0 ? nties : 1) * sizeof(nwint));
	pc = (nwint *)malloc((size_t)(nties > 0 ? nties : 1) * sizeof(nwint));
	if (!pr || !pc) { rc = 2; goto done; }
	for (e = 0; e < nties; e++) {
		nwint a = ei[e] - 1, b = ej[e] - 1;
		if (a < 0 || b < 0 || a >= n || b >= n) continue;
		if (!(ew[e] > 0)) continue;
		if (rid[a] >= 0 && cid[b] >= 0) { pr[nm] = rid[a]; pc[nm] = cid[b]; nm++; }
		else if (rid[b] >= 0 && cid[a] >= 0) { pr[nm] = rid[b]; pc[nm] = cid[a]; nm++; }
	}
	rdeg = (nwint *)calloc((size_t)nR + 1, sizeof(nwint));
	rp = (nwint *)calloc((size_t)nR + 2, sizeof(nwint));
	ri = (nwint *)malloc((size_t)(nm > 0 ? nm : 1) * sizeof(nwint));
	cdeg = (nwint *)calloc((size_t)nC + 1, sizeof(nwint));
	cp = (nwint *)calloc((size_t)nC + 2, sizeof(nwint));
	ci = (nwint *)malloc((size_t)(nm > 0 ? nm : 1) * sizeof(nwint));
	if (!rdeg || !rp || !ri || !cdeg || !cp || !ci) { rc = 2; goto done; }
	for (e = 0; e < nm; e++) rdeg[pr[e]]++;
	for (r = 0; r < nR; r++) rp[r + 1] = rp[r] + rdeg[r];
	{
		nwint *fill = (nwint *)calloc((size_t)nR + 1, sizeof(nwint));
		nwint w = 0;
		if (!fill) { rc = 2; goto done; }
		for (e = 0; e < nm; e++) ri[rp[pr[e]] + fill[pr[e]]++] = pc[e];
		free(fill);
		/* sort and unique every row, compact */
		for (r = 0; r < nR; r++) {
			nwint s = rp[r], t2 = rp[r + 1], u, last = -1, startw = w;
			qsort(ri + s, (size_t)(t2 - s), sizeof(nwint), n380_cmp_long);
			for (u = s; u < t2; u++) if (ri[u] != last) { last = ri[u]; ri[w++] = last; }
			rdeg[r] = w - startw;
		}
		rp[0] = 0;
		for (r = 0; r < nR; r++) rp[r + 1] = rp[r] + rdeg[r];
		nm = w;
	}
	for (e = 0; e < nm; e++) cdeg[ri[e]]++;
	for (c = 0; c < nC; c++) cp[c + 1] = cp[c] + cdeg[c];
	{
		nwint *fill = (nwint *)calloc((size_t)nC + 1, sizeof(nwint));
		if (!fill) { rc = 2; goto done; }
		for (r = 0; r < nR; r++) for (e = rp[r]; e < rp[r + 1]; e++) ci[cp[ri[e]] + fill[ri[e]]++] = r;
		free(fill);
	}
	GR.nS = nR; GR.nT = nC; GR.sptr = rp; GR.sidx = ri; GR.tptr = cp; GR.tidx = ci; GR.snode = rnode; GR.tnode = cnode;
	GC.nS = nC; GC.nT = nR; GC.sptr = cp; GC.sidx = ci; GC.tptr = rp; GC.tidx = ri; GC.snode = cnode; GC.tnode = rnode;

	L = (n380_cfglist_t *)malloc(sizeof(n380_cfglist_t));
	if (!L) { rc = 2; goto done; }
	/* shapes 1 x t (S = the row) and t x 1 (S = the column) */
	n380_cfgs(0, 1, 1, maxn - 1, L); n380_k1(out, P, &GR, L);
	n380_cfgs(1, 1, 2, maxn - 1, L); n380_k1(out, P, &GC, L);
	/* shapes 2 x t (S = the pair of rows) and t x 2 */
	n380_cfgs(0, 2, 2, maxn - 2, L); if ((rc = n380_k2(out, P, &GR, L)) != 0) goto done;
	n380_cfgs(1, 2, 3, maxn - 2, L); if ((rc = n380_k2(out, P, &GC, L)) != 0) goto done;
	/* shape 3 x 3: triples of the smaller mode */
	if (six) {
		if (nR <= nC) { n380_cfgs(0, 3, 3, 3, L); if ((rc = n380_k3(out, P, &GR, L)) != 0) goto done; }
		else          { n380_cfgs(1, 3, 3, 3, L); if ((rc = n380_k3(out, P, &GC, L)) != 0) goto done; }
	}
	pub_result(0, n, P);
done:
	free(rid); free(cid); free(rnode); free(cnode); free(pr); free(pc);
	free(rdeg); free(rp); free(ri); free(cdeg); free(cp); free(ci); free(L);
	return rc;
}
