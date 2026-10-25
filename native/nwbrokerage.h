/*
	nwbrokerage.h -- native (C) kernels for nwburt (29), nwconstraint (30) and nwsimmelian (31).

	#included by nwcomb.h after nwfast.h (one plugin binary); NWCOMB_VERSION 7 announces them.
	Wire protocol as in nwcomb.h: ties (ego, alter, weight) in variables 1..3, the result stays in
	static memory (g_res) and is copied out by the FETCH call (alg 99).

	Every kernel reproduces the Mata routine it replaces, in the same order of summation:
	29  burt        par: none.  Ties = every stored tie of the network (edgelist(), in that order, weights
	                included, self-loops too).  Result n x 5: effective size, efficiency, constraint,
	                hierarchy, hierarchy-is-missing flag (calculate_burt()).
	30  constraint  par: none.  Same input.  Result m x 3: (ego, alter, value) of the cells of the dyadic
	                constraint network that are not zero, ego ascending, alter ascending
	                (calculate_constraint_triplets()).
	31  simmelian   par: none.  Ties = (ego, alter, 1) without loops and zero ties, each directed pair once.
	                Result m x 2: the mutual ties that have a mutual neighbour in common, ego ascending,
	                alter ascending (nw_simmelian_net()).
*/

#define ALG_BURT       29
#define ALG_CONSTRAINT 30
#define ALG_SIMMELIAN  31

/* ---------------------------------------------------------------- */
/* 29: Burt's measures                                               */
/* ---------------------------------------------------------------- */
static int comb_burt(long n, long nties, const long *ei, const long *ej, const double *ew) {
	csr_t G;
	double *od = NULL, *net2 = NULL, *p2 = NULL;
	long *mark = NULL, *posn = NULL;
	long i, k, kk, maxd = 0;
	int rc = 0;

	if (csr_from_edges(&G, n, nties, ei, ej, ew, 0, 0, 1)) return 2;
	od = (double *)calloc((size_t)(n > 0 ? n : 1), sizeof(double));
	mark = (long *)calloc((size_t)(n > 0 ? n : 1), sizeof(long));
	posn = (long *)calloc((size_t)(n > 0 ? n : 1), sizeof(long));
	for (i = 0; i < n; i++) {
		double s = 0;
		long d = G.ptr[i + 1] - G.ptr[i];
		for (k = G.ptr[i]; k < G.ptr[i + 1]; k++) s += G.w[k];
		od[i] = s;
		if (d > maxd) maxd = d;
	}
	net2 = (double *)malloc((size_t)(maxd > 0 ? maxd : 1) * sizeof(double));
	p2 = (double *)malloc((size_t)(maxd > 0 ? maxd : 1) * sizeof(double));
	if (!od || !mark || !posn || !net2 || !p2 || res_alloc(n, 5)) { rc = 2; goto done; }

	for (i = 0; i < n; i++) {
		long a = G.ptr[i], b = G.ptr[i + 1], d = b - a, j;
		double o = od[i], red = 0, con = 0, avgc, z = 0, den, h;
		long stamp = i + 1;
		double *r = g_res + i * 5;
		if (d == 0 || o == 0) {
			r[0] = o; r[1] = 0; r[2] = 0; r[3] = 0; r[4] = 1;
			continue;
		}
		for (k = a; k < b; k++) { mark[G.idx[k]] = stamp; posn[G.idx[k]] = k - a; net2[k - a] = 0; p2[k - a] = 0; }
		for (k = a; k < b; k++) {
			long q = G.idx[k];
			double wiq = G.w[k], oq = od[q];
			for (kk = G.ptr[q]; kk < G.ptr[q + 1]; kk++) {
				long jn = G.idx[kk];
				if (mark[jn] == stamp && jn != q) {
					long jp = posn[jn];
					double wqj = G.w[kk];
					net2[jp] = net2[jp] + wiq * wqj;
					if (oq > 0) p2[jp] = p2[jp] + (wiq / o) * (wqj / oq);
				}
			}
		}
		for (j = 0; j < d; j++) {
			double wij = G.w[a + j], pij = wij / o, c = pij + p2[j];
			red = red + wij * (net2[j] / o);
			con = con + wij * (c * c);
		}
		avgc = con / o;
		for (j = 0; j < d; j++) {
			double wij = G.w[a + j], pij = wij / o, c = wij * ((pij + p2[j]) * (pij + p2[j]));
			if (c > 0 && avgc > 0) z = z + wij * c * log(c / avgc) / avgc;
		}
		r[0] = o - red;
		r[1] = r[0] / o;
		r[2] = con;
		if (o < 0) { h = 1; }
		else {
			den = o * log(o);
			if (den == 0) h = 1;
			else {
				h = z / den;
				if (!(h == h) || h > 1e300 || h < -1e300) h = 1;
			}
		}
		r[3] = h;
		r[4] = 0;
	}
	pub_result(0, n, 5);
done:
	free(od); free(mark); free(posn); free(net2); free(p2);
	csr_free(&G);
	return rc;
}

/* ---------------------------------------------------------------- */
/* 30: dyadic constraint as a list of cells                           */
/* ---------------------------------------------------------------- */
static int brk_cmp_long(const void *x, const void *y) {
	long a = *(const long *)x, b = *(const long *)y;
	return (a > b) - (a < b);
}

static int comb_constraint(long n, long nties, const long *ei, const long *ej, const double *ew) {
	csr_t G;
	double *od = NULL, *acc = NULL;
	long *mark = NULL, *touched = NULL;
	long i, k, kk, t, pos = 0, bound = 0, maxt = 0;
	int rc = 0;

	if (csr_from_edges(&G, n, nties, ei, ej, ew, 0, 0, 1)) return 2;
	od = (double *)calloc((size_t)(n > 0 ? n : 1), sizeof(double));
	acc = (double *)calloc((size_t)(n > 0 ? n : 1), sizeof(double));
	mark = (long *)calloc((size_t)(n > 0 ? n : 1), sizeof(long));
	if (!od || !acc || !mark) { rc = 2; goto done; }
	for (i = 0; i < n; i++) {
		double s = 0;
		long d = G.ptr[i + 1] - G.ptr[i], tot = d;
		for (k = G.ptr[i]; k < G.ptr[i + 1]; k++) { s += G.w[k]; tot += G.ptr[G.idx[k] + 1] - G.ptr[G.idx[k]]; }
		od[i] = s;
		if (d > 0) { bound += tot; if (tot > maxt) maxt = tot; }
	}
	if (maxt > n) maxt = n;
	touched = (long *)malloc((size_t)(maxt > 0 ? maxt : 1) * sizeof(long));
	if (!touched || res_alloc(bound, 3)) { rc = 2; goto done; }

	for (i = 0; i < n; i++) {
		long a = G.ptr[i], b = G.ptr[i + 1], nt = 0, stamp = i + 1;
		double o = od[i];
		if (b == a || o == 0) continue;
		for (k = a; k < b; k++) {
			long c = G.idx[k];
			double v = G.w[k] / o;
			if (mark[c] != stamp) { mark[c] = stamp; acc[c] = 0; touched[nt++] = c; }
			acc[c] = acc[c] + v;
		}
		for (k = a; k < b; k++) {
			long q = G.idx[k];
			double f;
			if (od[q] == 0 || G.ptr[q + 1] == G.ptr[q]) continue;
			f = G.w[k] / o;
			for (kk = G.ptr[q]; kk < G.ptr[q + 1]; kk++) {
				long c = G.idx[kk];
				double v = f * G.w[kk] / od[q];
				if (mark[c] != stamp) { mark[c] = stamp; acc[c] = 0; touched[nt++] = c; }
				acc[c] = acc[c] + v;
			}
		}
		qsort(touched, (size_t)nt, sizeof(long), brk_cmp_long);
		for (t = 0; t < nt; t++) {
			long c = touched[t];
			if (c != i && acc[c] != 0) {
				g_res[pos * 3] = (double)(i + 1);
				g_res[pos * 3 + 1] = (double)(c + 1);
				g_res[pos * 3 + 2] = acc[c] * acc[c];
				pos++;
			}
		}
	}
	g_res_rows = pos;
	pub_result(0, pos, 3);
done:
	free(od); free(acc); free(mark); free(touched);
	csr_free(&G);
	return rc;
}

/* ---------------------------------------------------------------- */
/* 31: Simmelian ties                                                 */
/* ---------------------------------------------------------------- */
static int comb_simmelian(long n, long nties, const long *ei, const long *ej) {
	long *perm = NULL, *ptr = NULL, *idx = NULL, *mptr = NULL, *midx = NULL, *mark = NULL;
	long i, k, kk, mm = 0, pos = 0, run;
	int rc = 0;

	ptr = (long *)calloc((size_t)(n + 2), sizeof(long));
	mptr = (long *)calloc((size_t)(n + 2), sizeof(long));
	mark = (long *)calloc((size_t)(n > 0 ? n : 1), sizeof(long));
	idx = (long *)malloc((size_t)(nties > 0 ? nties : 1) * sizeof(long));
	midx = (long *)malloc((size_t)(nties > 0 ? nties : 1) * sizeof(long));
	if (!ptr || !mptr || !mark || !idx || !midx) { rc = 2; goto done; }
	if (nties > 0) {
		perm = fast_sort_rc(n, nties, ei, ej);
		if (!perm) { rc = 2; goto done; }
	}
	for (k = 0; k < nties; k++) ptr[ei[k]]++;
	run = 0;
	for (i = 0; i < n; i++) { long c = ptr[i + 1]; ptr[i] = run; run += c; }
	ptr[n] = run;
	for (k = 0; k < nties; k++) idx[k] = ej[perm[k]] - 1;
	/* mutual neighbours: the reverse tie (v,u) is a tie as well */
	for (i = 0; i < n; i++) {
		mptr[i] = mm;
		for (k = ptr[i]; k < ptr[i + 1]; k++) {
			long v = idx[k], lo = ptr[v], hi = ptr[v + 1] - 1;
			int found = 0;
			while (lo <= hi) {
				long mid = (lo + hi) / 2;
				if (idx[mid] == i) { found = 1; break; }
				if (idx[mid] < i) lo = mid + 1; else hi = mid - 1;
			}
			if (found) midx[mm++] = v;
		}
	}
	mptr[n] = mm;
	if (res_alloc(mm, 2)) { rc = 2; goto done; }
	for (i = 0; i < n; i++) {
		long stamp = i + 1;
		for (k = mptr[i]; k < mptr[i + 1]; k++) mark[midx[k]] = stamp;
		for (k = mptr[i]; k < mptr[i + 1]; k++) {
			long v = midx[k];
			for (kk = mptr[v]; kk < mptr[v + 1]; kk++) {
				if (mark[midx[kk]] == stamp) {
					g_res[pos * 2] = (double)(i + 1);
					g_res[pos * 2 + 1] = (double)(v + 1);
					pos++;
					break;
				}
			}
		}
	}
	g_res_rows = pos;
	pub_result(0, pos, 2);
done:
	free(perm); free(ptr); free(idx); free(mptr); free(midx); free(mark);
	return rc;
}
