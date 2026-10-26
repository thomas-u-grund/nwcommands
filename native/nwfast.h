/*
	nwfast.h -- native (C) kernels for nwclustering (26), nwtriads (27) and nwevcent (28).

	#included by nwcomb.h after nwcomb2.h (one plugin binary); NWCOMB_VERSION 6 announces them.
	Wire protocol as in nwcomb.h: ties (ego, alter, weight) in variables 1..3, the result stays in
	static memory (g_res) and is copied out by the FETCH call (alg 99).

	Every kernel reproduces the Mata routine it replaces, including its treatment of stored ties:
	a tie is any stored entry of the sparse index (non-zero, non-missing), an undirected network
	arrives symmetrically (both (i,j) and (j,i)), and the counts are exact integers in doubles.

	26  clustering   par: directed.  Result n x 2: closed triples, potential triples per node
	                 (calculate_clustering(0): in-neighbour a, out-neighbour b, a != b, a -> b closes).
	                 O(sum of out-degree^2), no sorting needed.
	27  triads       par: none.  Result 1 x 16 in the order 003 012 021D 021U 021C 030T 030C 102 111D 111U
	                 120D 120U 120C 210 201 300 (the order of calculate_triadcensus()).  Batagelj and Mrvar:
	                 triads with one tied dyad by inclusion-exclusion over tied pairs, connected triads
	                 (two or three tied dyads) by enumeration of the pairs of connected neighbours of a hub,
	                 a triad with three tied dyads counted once, at its smallest vertex; 003 by subtraction.
	                 The caller must not hand over networks with self-loops (the Mata code is not defined there).
	28  eigenvector  par: nosym valued.  Result n x 1.  Power iteration on A + c*I exactly as
	                 nw_evcentrality() in nwevcent.ado (same shift, tolerance 1e-10, cap 1000, sign rule).
*/

#define ALG_CLUSTERING 26
#define ALG_TRIADS     27
#define ALG_EVCENT     28

/* stable sort of m entries by (r, c), both 1-based in 1..n; returns the permutation or NULL */
static nwint *fast_sort_rc(nwint n, nwint m, const nwint *r, const nwint *c) {
	nwint *cnt = (nwint *)calloc((size_t)(n + 2), sizeof(nwint));
	nwint *p1 = (nwint *)malloc((size_t)(m > 0 ? m : 1) * sizeof(nwint));
	nwint *p2 = (nwint *)malloc((size_t)(m > 0 ? m : 1) * sizeof(nwint));
	nwint k, i, run;
	if (!cnt || !p1 || !p2) { free(cnt); free(p1); free(p2); return NULL; }
	for (k = 0; k < m; k++) cnt[c[k]]++;
	run = 0;
	for (i = 1; i <= n; i++) { nwint t = cnt[i]; cnt[i] = run; run += t; }
	for (k = 0; k < m; k++) p1[cnt[c[k]]++] = k;
	memset(cnt, 0, (size_t)(n + 2) * sizeof(nwint));
	for (k = 0; k < m; k++) cnt[r[k]]++;
	run = 0;
	for (i = 1; i <= n; i++) { nwint t = cnt[i]; cnt[i] = run; run += t; }
	for (k = 0; k < m; k++) { nwint q = p1[k]; p2[cnt[r[q]]++] = q; }
	free(cnt); free(p1);
	return p2;
}

/* ---------------------------------------------------------------- */
/* 26: clustering                                                    */
/* ---------------------------------------------------------------- */
static int comb_clustering(nwint n, nwint nties, const nwint *ei, const nwint *ej, int directed) {
	csr_t O, I;
	nwint i, k, q, a;
	nwint *mark;
	int have_in = 0;
	if (csr_from_edges(&O, n, nties, ei, ej, NULL, 0, 0, 0)) return 2;
	if (directed) {
		if (csr_from_edges(&I, n, nties, ej, ei, NULL, 0, 0, 0)) { csr_free(&O); return 2; }
		have_in = 1;
	}
	mark = (nwint *)calloc((size_t)(n > 0 ? n : 1), sizeof(nwint));
	if (!mark || res_alloc(n, 2)) { free(mark); csr_free(&O); if (have_in) csr_free(&I); return 2; }
	for (i = 0; i < n; i++) {
		const csr_t *In = have_in ? &I : &O;
		nwint stamp = i + 1;
		nwint nout = O.ptr[i + 1] - O.ptr[i], nin = In->ptr[i + 1] - In->ptr[i];
		double pot, closed = 0;
		nwint overlap = 0;
		for (k = O.ptr[i]; k < O.ptr[i + 1]; k++) mark[O.idx[k]] = stamp;
		for (q = In->ptr[i]; q < In->ptr[i + 1]; q++) {
			a = In->idx[q];
			if (mark[a] == stamp) overlap++;
			for (k = O.ptr[a]; k < O.ptr[a + 1]; k++) {
				nwint b = O.idx[k];
				if (b != a && mark[b] == stamp) closed += 1.0;
			}
		}
		pot = (double)nin * (double)nout - (double)overlap;
		g_res[i * 2] = closed;
		g_res[i * 2 + 1] = pot;
	}
	free(mark);
	csr_free(&O);
	if (have_in) csr_free(&I);
	pub_result(0, n, 2);
	return 0;
}

/* ---------------------------------------------------------------- */
/* 27: triad census                                                  */
/* ---------------------------------------------------------------- */
static int tri_swap(int x) { return ((x & 1) << 1) | ((x >> 1) & 1); }

/* state of the dyad (u, w) seen from row u: bit 0 u->w, bit 1 w->u; 0 when not adjacent */
static int tri_lookup(const nwint *ptr, const nwint *idx, const unsigned char *bits, nwint u, nwint w) {
	nwint lo = ptr[u], hi = ptr[u + 1] - 1;
	while (lo <= hi) {
		nwint mid = (lo + hi) / 2;
		if (idx[mid] == w) return bits[mid];
		if (idx[mid] < w) lo = mid + 1; else hi = mid - 1;
	}
	return 0;
}

static int comb_triads(nwint n, nwint nties, const nwint *ei, const nwint *ej) {
	static const int LU[64] = {1,2,2,8,2,4,5,9,2,5,3,10,8,9,10,15,2,5,4,9,3,6,6,11,5,7,6,13,10,13,12,14,
		2,3,5,10,5,6,7,13,4,6,6,12,9,11,13,14,8,10,9,15,10,12,13,14,9,13,11,14,15,14,14,16};
	nwint m2 = 2 * nties, k, i, o, a, b, j;
	nwint *R = NULL, *C = NULL, *perm = NULL, *ptr = NULL, *idx = NULL, *mark = NULL;
	unsigned char *B = NULL, *bits = NULL;
	double tally[17];
	int rc = 0;

	R = (nwint *)malloc((size_t)(m2 > 0 ? m2 : 1) * sizeof(nwint));
	C = (nwint *)malloc((size_t)(m2 > 0 ? m2 : 1) * sizeof(nwint));
	B = (unsigned char *)malloc((size_t)(m2 > 0 ? m2 : 1));
	if (!R || !C || !B) { rc = 2; goto done; }
	for (k = 0; k < nties; k++) {
		R[2 * k] = ei[k]; C[2 * k] = ej[k]; B[2 * k] = 1;
		R[2 * k + 1] = ej[k]; C[2 * k + 1] = ei[k]; B[2 * k + 1] = 2;
	}
	perm = fast_sort_rc(n, m2, R, C);
	if (!perm) { rc = 2; goto done; }
	ptr = (nwint *)calloc((size_t)(n + 2), sizeof(nwint));
	idx = (nwint *)malloc((size_t)(m2 > 0 ? m2 : 1) * sizeof(nwint));
	bits = (unsigned char *)malloc((size_t)(m2 > 0 ? m2 : 1));
	mark = (nwint *)calloc((size_t)(n + 2), sizeof(nwint));
	if (!ptr || !idx || !bits || !mark) { rc = 2; goto done; }
	/* merge parallel entries (OR the direction bits); ptr is 1-based by node: row v = ptr[v]..ptr[v+1]-1 */
	o = 0;
	{
		nwint cur = 1;
		ptr[1] = 0;
		for (k = 0; k < m2; k++) {
			nwint q = perm[k];
			while (cur < R[q]) { cur++; ptr[cur] = o; }
			if (o > ptr[cur] && idx[o - 1] == C[q]) bits[o - 1] |= B[q];
			else { idx[o] = C[q]; bits[o] = B[q]; o++; }
		}
		while (cur <= n) { cur++; ptr[cur] = o; }
	}
	for (i = 0; i < 17; i++) tally[i] = 0;

	/* pass A: exactly one tied dyad */
	for (i = 1; i <= n; i++) {
		for (k = ptr[i]; k < ptr[i + 1]; k++) mark[idx[k]] = i;
		for (k = ptr[i]; k < ptr[i + 1]; k++) {
			nwint coij = 0, q;
			double countA;
			j = idx[k];
			if (j <= i) continue;
			for (q = ptr[j]; q < ptr[j + 1]; q++) if (mark[idx[q]] == i) coij++;
			countA = (double)n - (double)(ptr[i + 1] - ptr[i]) - (double)(ptr[j + 1] - ptr[j]) + (double)coij;
			if (bits[k] == 3) tally[8] += countA; else tally[2] += countA;
		}
	}
	/* pass B: two or three tied dyads */
	for (i = 1; i <= n; i++) {
		nwint v = i;
		for (a = ptr[v]; a < ptr[v + 1]; a++) {
			nwint u = idx[a];
			int bvu = bits[a];
			for (b = a + 1; b < ptr[v + 1]; b++) {
				nwint w = idx[b];
				int bvw = bits[b], suw, sij, sik, sjk, key;
				suw = tri_lookup(ptr, idx, bits, u, w);
				if (suw && v > u) continue;      /* a triangle is counted once, at its smallest vertex */
				if (v < u) { sij = bvu; sik = bvw; sjk = suw; }
				else if (v < w) { sij = tri_swap(bvu); sik = suw; sjk = bvw; }
				else { sij = suw; sik = tri_swap(bvu); sjk = tri_swap(bvw); }
				key = sij * 16 + sik * 4 + sjk;
				tally[LU[key]] += 1.0;
			}
		}
	}
	{
		double s = 0, nn = (double)n;
		for (i = 2; i <= 16; i++) s += tally[i];
		tally[1] = (nn * (nn - 1) * (nn - 2) / 6) - s;
	}
	if (res_alloc(1, 16)) { rc = 2; goto done; }
	for (i = 1; i <= 16; i++) g_res[i - 1] = tally[i];
	pub_result(0, 1, 16);
done:
	free(R); free(C); free(B); free(perm); free(ptr); free(idx); free(bits); free(mark);
	return rc;
}

/* ---------------------------------------------------------------- */
/* 28: eigenvector centrality                                         */
/* ---------------------------------------------------------------- */
static void ev_matvec(nwint n, const nwint *ptr, const nwint *col, const double *w, const double *v, double *out) {
	nwint i, k;
	for (i = 0; i < n; i++) {
		double s = 0;
		for (k = ptr[i]; k < ptr[i + 1]; k++) s += w[k] * v[col[k]];
		out[i] = s;
	}
}

static int comb_evcent(nwint n, nwint nties, const nwint *ei, const nwint *ej, const double *ew, int nosym, int getvalued) {
	nwint *R = NULL, *C = NULL, *perm = NULL, *ptr = NULL, *col = NULL;
	double *W = NULL, *w = NULL, *x = NULL, *y = NULL, *t = NULL;
	nwint m = 0, k, i, o, iter;
	double shift, mx, norm;
	int rc = 0, allzero;

	R = (nwint *)malloc((size_t)(2 * nties + 1) * sizeof(nwint));
	C = (nwint *)malloc((size_t)(2 * nties + 1) * sizeof(nwint));
	W = (double *)malloc((size_t)(2 * nties + 1) * sizeof(double));
	if (!R || !C || !W) { rc = 2; goto done; }
	for (k = 0; k < nties; k++) {
		if (ei[k] == ej[k]) continue;
		R[m] = ei[k]; C[m] = ej[k]; W[m] = ew[k]; m++;
		if (!nosym) { R[m] = ej[k]; C[m] = ei[k]; W[m] = ew[k]; m++; }
	}
	perm = fast_sort_rc(n, m, R, C);
	if (!perm) { rc = 2; goto done; }
	ptr = (nwint *)calloc((size_t)(n + 2), sizeof(nwint));
	col = (nwint *)malloc((size_t)(m > 0 ? m : 1) * sizeof(nwint));
	w = (double *)malloc((size_t)(m > 0 ? m : 1) * sizeof(double));
	x = (double *)malloc((size_t)(n + 1) * sizeof(double));
	y = (double *)malloc((size_t)(n + 1) * sizeof(double));
	t = (double *)malloc((size_t)(n + 1) * sizeof(double));
	if (!ptr || !col || !w || !x || !y || !t) { rc = 2; goto done; }
	/* group by (row, col): the largest weight of a dyad's copies; keep it when > 0 (symmetrised) or
	   as nw_evcentrality_edges() does: nosym keeps the tie when its weight (1 if unvalued) is > 0 */
	{
		nwint cnt_row = 0;
		o = 0;
		k = 0;
		while (k < m) {
			nwint q = perm[k], r = R[q], c = C[q];
			double mxw = W[q];
			k++;
			while (k < m && R[perm[k]] == r && C[perm[k]] == c) {
				if (W[perm[k]] > mxw) mxw = W[perm[k]];
				k++;
			}
			if (nosym) {
				double ww = getvalued ? mxw : 1.0;
				if (!(ww > 0)) continue;
				col[o] = c - 1; w[o] = ww; ptr[r]++;
				o++;
			}
			else {
				if (!(mxw > 0)) continue;
				col[o] = c - 1; w[o] = getvalued ? mxw : 1.0; ptr[r]++;
				o++;
			}
		}
		(void)cnt_row;
		/* ptr[r] now holds the count of row r (1-based); turn into 0-based starts */
		{
			nwint run = 0;
			for (i = 1; i <= n; i++) { nwint c = ptr[i]; ptr[i - 1] = run; run += c; }
			ptr[n] = run;
		}
	}
	if (res_alloc(n, 1)) { rc = 2; goto done; }
	for (i = 0; i < n; i++) x[i] = 1.0 / sqrt((double)n);
	ev_matvec(n, ptr, col, w, x, t);
	mx = 0; for (i = 0; i < n; i++) if (fabs(t[i]) > mx) mx = fabs(t[i]);
	allzero = (mx == 0);
	if (allzero) {
		for (i = 0; i < n; i++) g_res[i] = SV_missval;
		pub_result(0, n, 1);
		goto done;
	}
	for (i = 0; i < n; i++) y[i] = 1.0;
	ev_matvec(n, ptr, col, w, y, t);
	shift = 0; for (i = 0; i < n; i++) if (i == 0 || t[i] > shift) shift = t[i];
	shift += 1.0;
	for (iter = 1; iter <= 1000; iter++) {
		double d1 = 0, d2 = 0, ss = 0;
		nwint conv;
		ev_matvec(n, ptr, col, w, x, y);
		for (i = 0; i < n; i++) { y[i] += shift * x[i]; ss += y[i] * y[i]; }
		norm = sqrt(ss);
		for (i = 0; i < n; i++) y[i] /= norm;
		for (i = 0; i < n; i++) {
			double a1 = fabs(y[i] - x[i]), a2 = fabs(y[i] + x[i]);
			if (a1 > d1) d1 = a1;
			if (a2 > d2) d2 = a2;
		}
		conv = (d1 < 1e-10 || d2 < 1e-10);
		{ double *sw = x; x = y; y = sw; }   /* x = y */
		if (conv) break;
	}
	if (x[0] < 0) for (i = 0; i < n; i++) x[i] = -x[i];
	for (i = 0; i < n; i++) g_res[i] = x[i];
	pub_result(0, n, 1);
done:
	free(R); free(C); free(W); free(perm); free(ptr); free(col); free(w); free(x); free(y); free(t);
	return rc;
}
