/*
	nwburtw.h -- native (C) kernel for the WEIGHTED Burt measures of nwburt.

	#included by nwcomb.h after nwfast2.h (one plugin binary); NWCOMB_VERSION 9 announces it.
	Wire protocol as in nwcomb.h: ties (ego, alter, weight) in variables 1..3, the result stays in
	static memory (g_res) and is copied out by the FETCH call (alg 99).

	40  burtw       par: none.  Ties = every stored tie of the network (edgelist()).  Self-loops, zero and
	                negative or missing weights are dropped.  Burt (1992) with valued ties, in the form used by
	                igraph::constraint(): the strength of the relation between i and j is the SUM of both
	                directions, a(i,j) = z(i,j) + z(j,i) (for an undirected network every stored pair adds twice,
	                which changes none of the ratios below).
	                  p(i,j)  = a(i,j) / sum_k a(i,k)                       proportional strength
	                  m(j,q)  = a(j,q) / max_k a(j,k)                       marginal strength
	                  ES(i)   = sum_{j} ( 1 - sum_{q != i,j} p(i,q) m(j,q) ) effective size
	                  C(i)    = sum_{j} ( p(i,j) + sum_{q != i,j} p(i,q) p(q,j) )^2   constraint
	                  eff(i)  = ES(i) / number of contacts of i
	                  H(i)    = sum_j (c_ij / (C/N)) ln(c_ij / (C/N)) / (N ln N), N = number of contacts, c_ij the
	                            term of C for j.
	                j runs over the contacts of i (a(i,j) > 0), q over the contacts of i too.
	                Result n x 5 as kernel 29: ES, efficiency, constraint, hierarchy, hierarchy-is-missing flag.
	                A node without contacts has ES = efficiency = constraint = 0 and a missing hierarchy; a node
	                with exactly one contact has hierarchy 1 (the same conventions as kernel 29).
	41, 42  reserved.
*/

#define ALG_BURTW 40

typedef struct { nwint r, c; double w; } bw_tie_t;

static int bw_cmp(const void *x, const void *y) {
	const bw_tie_t *a = (const bw_tie_t *)x, *b = (const bw_tie_t *)y;
	if (a->r != b->r) return (a->r > b->r) - (a->r < b->r);
	return (a->c > b->c) - (a->c < b->c);
}

static int comb_burtw(nwint n, nwint nties, const nwint *ei, const nwint *ej, const double *ew) {
	bw_tie_t *t = NULL;
	nwint *ptr = NULL, *idx = NULL, *mark = NULL, *posn = NULL;
	double *aw = NULL, *s = NULL, *mx = NULL, *ind = NULL, *red = NULL;
	nwint m = 0, u = 0, k, kk, i, maxd = 0;
	int rc = 0;

	t = (bw_tie_t *)malloc((size_t)(2 * nties + 1) * sizeof(bw_tie_t));
	if (!t) return 2;
	for (k = 0; k < nties; k++) {
		double w = ew[k];
		if (ei[k] == ej[k] || !(w > 0) || ei[k] < 1 || ej[k] < 1 || ei[k] > n || ej[k] > n) continue;
		t[m].r = ei[k] - 1; t[m].c = ej[k] - 1; t[m].w = w; m++;
		t[m].r = ej[k] - 1; t[m].c = ei[k] - 1; t[m].w = w; m++;
	}
	if (m > 1) qsort(t, (size_t)m, sizeof(bw_tie_t), bw_cmp);
	/* merge the duplicates (the two directions of a pair, repeated ties) */
	for (k = 0; k < m; k++) {
		if (u > 0 && t[u - 1].r == t[k].r && t[u - 1].c == t[k].c) t[u - 1].w += t[k].w;
		else { t[u] = t[k]; u++; }
	}
	ptr = (nwint *)calloc((size_t)(n + 2), sizeof(nwint));
	idx = (nwint *)malloc((size_t)(u > 0 ? u : 1) * sizeof(nwint));
	aw = (double *)malloc((size_t)(u > 0 ? u : 1) * sizeof(double));
	s = (double *)calloc((size_t)(n > 0 ? n : 1), sizeof(double));
	mx = (double *)calloc((size_t)(n > 0 ? n : 1), sizeof(double));
	mark = (nwint *)calloc((size_t)(n > 0 ? n : 1), sizeof(nwint));
	posn = (nwint *)calloc((size_t)(n > 0 ? n : 1), sizeof(nwint));
	if (!ptr || !idx || !aw || !s || !mx || !mark || !posn) { rc = 2; goto done; }
	for (k = 0; k < u; k++) {
		ptr[t[k].r + 1]++;
		idx[k] = t[k].c; aw[k] = t[k].w;
		s[t[k].r] += t[k].w;
		if (t[k].w > mx[t[k].r]) mx[t[k].r] = t[k].w;
	}
	for (i = 0; i < n; i++) { ptr[i + 1] += ptr[i]; if (ptr[i + 1] - ptr[i] > maxd) maxd = ptr[i + 1] - ptr[i]; }
	ind = (double *)malloc((size_t)(maxd > 0 ? maxd : 1) * sizeof(double));
	red = (double *)malloc((size_t)(maxd > 0 ? maxd : 1) * sizeof(double));
	if (!ind || !red || res_alloc(n, 5)) { rc = 2; goto done; }

	for (i = 0; i < n; i++) {
		nwint a = ptr[i], b = ptr[i + 1], d = b - a, j;
		double o = s[i], es = 0, con = 0, avgc, z = 0, h;
		nwint stamp = i + 1;
		double *r = g_res + i * 5;
		if (d == 0) {
			r[0] = 0; r[1] = 0; r[2] = 0; r[3] = 0; r[4] = 1;
			continue;
		}
		for (k = a; k < b; k++) { mark[idx[k]] = stamp; posn[idx[k]] = k - a; ind[k - a] = 0; red[k - a] = 0; }
		for (k = a; k < b; k++) {
			nwint q = idx[k];
			double piq = aw[k] / o, sq = s[q];
			for (kk = ptr[q]; kk < ptr[q + 1]; kk++) {
				nwint jn = idx[kk];
				if (mark[jn] == stamp) {
					nwint jp = posn[jn];
					ind[jp] += piq * (aw[kk] / sq);      /* p(i,q) p(q,j) */
					red[jp] += piq * (aw[kk] / mx[jn]);  /* p(i,q) m(j,q), a(j,q) = a(q,j) */
				}
			}
		}
		for (j = 0; j < d; j++) {
			double c = aw[a + j] / o + ind[j];
			es += 1.0 - red[j];
			con += c * c;
		}
		avgc = con / (double)d;
		for (j = 0; j < d; j++) {
			double c = aw[a + j] / o + ind[j], q;
			c = c * c;
			q = c / avgc;
			z += q * log(q);
		}
		r[0] = es;
		r[1] = es / (double)d;
		r[2] = con;
		if (d == 1) h = 1;
		else {
			h = z / ((double)d * log((double)d));
			if (!(h == h) || h > 1e300 || h < -1e300) h = 1;
		}
		r[3] = h;
		r[4] = 0;
	}
	pub_result(0, n, 5);
done:
	free(t); free(ptr); free(idx); free(aw); free(s); free(mx); free(mark); free(posn); free(ind); free(red);
	return rc;
}
