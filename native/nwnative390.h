/*
	nwnative390.h -- native (C) kernels added in core 3.10.0 (plugin generation 12, kernel codes 51 and up):
	node-by-node similarities (nwsimilar, nwdissimilar, nwcorrelate), DIRT_LPA+ communities of two-mode networks
	(nwcommunity, algorithm(dirtlpa)) and the null-model draws of the two-mode nwcug.

	#included by nwcomb.h after nwnative380.h (one plugin binary); NWCOMB_VERSION 12 announces it.  Wire protocol as
	in nwcomb.h: ties (ego, alter, weight) in variables 1..3, one value per node in variable 4 (algorithms that need
	it), the result stays in static memory (g_res) and is copied out by the FETCH call (alg 99).  Status 2 = out of
	memory (the caller then keeps the Mata code).  All sizes and indices in this file are int64_t / size_t.

	51  simnodes  par: type dtype start count.  Columns start..start+count-1 (1-based) of the n x n matrix of a
	            node-by-node similarity or dissimilarity of nwsimilar / nwdissimilar / nwcorrelate: the matrix
	            function of unw_core.do / nwsimilar.ado / nwdissimilar.ado evaluated cell by cell from the sparse tie
	            lists (the Mata code forms 9 to 25 dense n x n matrices).  type: 1 pearson (correlate_nodes),
	            2 matches, 3 jaccard, 4 hamming, 5 crossproduct (nwsimilar); 6 euclidean, 7 manhatten, 8 nonmatches,
	            9 jaccard, 10 hamming (nwdissimilar).  dtype: 0 both, 1 incoming, 2 outgoing (for pearson 1 = outgoing,
	            2 = incoming, 3 = both as the argument of correlate_nodes).  Ties = edgelist() without the loops;
	            a tie is present when its value is not zero (the caller sends no missing values).  The cells use the
	            same formulas as the Mata code, in the same order of operations; the shared-neighbour sums are formed
	            from the sparse lists, so a sum of non-integer values can differ from the BLAS product in the last
	            bits.  Result n x count: column c = the cells (i, start+c) for i = 1..n; a result that is not finite
	            is a missing value (as in Mata).
*/

#define ALG_SIMNODES 51

/* ---------------------------------------------------------------- */
/* 51: node-by-node similarities                                      */
/* ---------------------------------------------------------------- */

typedef struct {
	int64_t n, m;
	int64_t *optr, *oidx, *iptr, *iidx;   /* CSR of the out-ties, CSR of the in-ties (i -> k: row i of out, row k of in) */
	double *ow, *iw;
} n390_g_t;

static void n390_gfree(n390_g_t *g) {
	free(g->optr); free(g->oidx); free(g->iptr); free(g->iidx); free(g->ow); free(g->iw);
	memset(g, 0, sizeof(*g));
}

/* ties (ego, alter, w), 1-based, loops and ties of value zero left out; returns 1 on out of memory */
static int n390_gbuild(n390_g_t *g, int64_t n, int64_t nties, const long *ei, const long *ej, const double *ew) {
	int64_t k, i, a, b, m = 0;
	int64_t *fill;
	memset(g, 0, sizeof(*g));
	g->n = n;
	g->optr = (int64_t *)calloc((size_t)n + 1, sizeof(int64_t));
	g->iptr = (int64_t *)calloc((size_t)n + 1, sizeof(int64_t));
	fill = (int64_t *)malloc(((size_t)n + 1) * sizeof(int64_t));
	if (!g->optr || !g->iptr || !fill) { free(fill); n390_gfree(g); return 1; }
	for (k = 0; k < nties; k++) {
		a = (int64_t)ei[k] - 1; b = (int64_t)ej[k] - 1;
		if (a < 0 || b < 0 || a >= n || b >= n || a == b || ew[k] == 0) continue;
		g->optr[a + 1]++; g->iptr[b + 1]++; m++;
	}
	for (i = 0; i < n; i++) { g->optr[i + 1] += g->optr[i]; g->iptr[i + 1] += g->iptr[i]; }
	g->m = m;
	g->oidx = (int64_t *)malloc(((size_t)m + 1) * sizeof(int64_t));
	g->iidx = (int64_t *)malloc(((size_t)m + 1) * sizeof(int64_t));
	g->ow = (double *)malloc(((size_t)m + 1) * sizeof(double));
	g->iw = (double *)malloc(((size_t)m + 1) * sizeof(double));
	if (!g->oidx || !g->iidx || !g->ow || !g->iw) { free(fill); n390_gfree(g); return 1; }
	for (i = 0; i < n; i++) fill[i] = g->optr[i];
	for (k = 0; k < nties; k++) {
		a = (int64_t)ei[k] - 1; b = (int64_t)ej[k] - 1;
		if (a < 0 || b < 0 || a >= n || b >= n || a == b || ew[k] == 0) continue;
		g->oidx[fill[a]] = b; g->ow[fill[a]] = ew[k]; fill[a]++;
	}
	for (i = 0; i < n; i++) fill[i] = g->iptr[i];
	for (k = 0; k < nties; k++) {
		a = (int64_t)ei[k] - 1; b = (int64_t)ej[k] - 1;
		if (a < 0 || b < 0 || a >= n || b >= n || a == b || ew[k] == 0) continue;
		g->iidx[fill[b]] = a; g->iw[fill[b]] = ew[k]; fill[b]++;
	}
	free(fill);
	return 0;
}

static double n390_fin(double v) { return (v - v == 0) ? v : SV_missval; }

/* per-node sums used by every cell */
typedef struct {
	double *odeg, *ideg;     /* binary degrees */
	double *osq, *isq;       /* sums of squares of the values */
	double *oabs, *iabs;     /* sums of the absolute values (pearson: of the values) */
} n390_stats_t;

/*
	The cell (i, j) of the matrix of `type' from the per-node sums (st) and the pair sums: wij = w[i][j], wji = w[j][i],
	co/ci = number of shared out-/in-neighbours, dp/dq = sum of w_ik w_jk (or, for manhatten, of |a| + |b| - |a - b|) over
	the shared out-/in-neighbours.  The formulas are those of the Mata functions, in the same order of operations.
*/
static double n390_cell(int type, int dtype, double nn, const n390_stats_t *st, int64_t i, int64_t j,
		double wij, double wji, double co, double ci, double dp, double dq) {
	double sym = (wij != 0) + (wji != 0), mmout, mmin, v = 0;
	switch (type) {
	case 1: {   /* correlate_nodes(outinboth = dtype) */
		double Sx, Sy, Sxx, Syy, Sxy, m, denom, zden, dsafe, cmax, cmin, FB, C;
		if (dtype == 1) {
			Sx = st->oabs[i] - wij; Sy = st->oabs[j] - wji; Sxx = st->osq[i] - wij * wij; Syy = st->osq[j] - wji * wji; Sxy = dp; m = nn - 2;
		} else if (dtype == 2) {
			Sx = st->iabs[i] - wji; Sy = st->iabs[j] - wij; Sxx = st->isq[i] - wji * wji; Syy = st->isq[j] - wij * wij; Sxy = dq; m = nn - 2;
		} else {
			Sx = (st->oabs[i] - wij) + (st->iabs[i] - wji); Sy = (st->oabs[j] - wji) + (st->iabs[j] - wij);
			Sxx = (st->osq[i] - wij * wij) + (st->isq[i] - wji * wji); Syy = (st->osq[j] - wji * wji) + (st->isq[j] - wij * wij);
			Sxy = dp + dq; m = 2 * (nn - 2);
		}
		denom = sqrt((m * Sxx - Sx * Sx) * (m * Syy - Sy * Sy));
		zden = (denom == 0);
		dsafe = denom + zden;
		cmax = ((Sx + Sy) + fabs(Sx - Sy)) / 2;
		cmin = ((Sx + Sy) - fabs(Sx - Sy)) / 2;
		FB = (cmin > 0) * (cmin / (cmax + (cmax == 0))) + (cmin == 0) * (cmax > 0) * (-1) + (cmin == 0) * (cmax == 0) * 1;
		C = (m * Sxy - Sx * Sy) / dsafe;
		v = C * (1 - zden) + FB * zden;
		break; }
	case 2: case 3: case 4: case 8: case 9: case 10: {
		double S = 0;
		mmout = (nn - (st->odeg[i] + st->odeg[j]) + 2 * co) + sym;
		mmin = (nn - (st->ideg[i] + st->ideg[j]) + 2 * ci) + sym;
		if (type == 2 || type == 8) {
			if (dtype == 0) S = ((mmout - 2) + (mmin - 2)) / (2 * (nn - 2));
			else if (dtype == 1) S = (mmin - 2) / (nn - 2);
			else S = (mmout - 2) / (nn - 2);
			v = (type == 8) ? 1 - S : S;
		} else if (type == 4 || type == 10) {
			if (dtype == 0) S = (type == 4) ? (mmout + mmin) : ((nn - mmout) + (nn - mmin));
			else if (dtype == 1) S = (type == 4) ? mmin : nn - mmin;
			else S = (type == 4) ? mmout : nn - mmout;
			v = S;
		} else {
			double denom;
			if (dtype == 0) {
				denom = (((st->odeg[i] + st->odeg[j]) + (st->ideg[i] + st->ideg[j])) - 2 * sym) - co - ci;
				S = (co + ci) / denom;
			} else if (dtype == 1) {
				denom = ((st->ideg[i] + st->ideg[j]) - sym) - ci;
				S = ci / denom;
			} else {
				denom = ((st->odeg[i] + st->odeg[j]) - sym) - co;
				S = co / denom;
			}
			v = (type == 9) ? 1 - S : S;
		}
		break; }
	case 5:
		v = (dtype == 0) ? dp + dq : (dtype == 1) ? dq : dp;
		break;
	case 6: {
		double sqcorr = wij * wij + wji * wji;
		mmout = ((st->osq[i] + st->osq[j]) - 2 * dp) - sqcorr;
		mmin = ((st->isq[i] + st->isq[j]) - 2 * dq) - sqcorr;
		v = sqrt(dtype == 0 ? mmout + mmin : dtype == 1 ? mmin : mmout);
		break; }
	case 7: {
		/* sums of |a - b| over the positions other than i and j */
		double so = (st->oabs[i] - fabs(wij)) + (st->oabs[j] - fabs(wji)) - dp;
		double si = (st->iabs[i] - fabs(wji)) + (st->iabs[j] - fabs(wij)) - dq;
		v = dtype == 0 ? so + si : dtype == 1 ? si : so;
		break; }
	default:
		v = SV_missval;
	}
	return n390_fin(v);
}

/*
	mode 0: dense block, the columns start..start+count-1 (count = par 6), result n x count.
	mode 1: the cells that differ from the "base" matrix of the caller (see comb_simnodes), for the columns start,
	        start+1, ... until at least `count' cells have been written, result L x 3 = (row, column, value) 1-based,
	        sorted by column; a1 = the next column to do (n + 1 when all are done).
	mode 2: the vectors from which the caller forms the base matrix, result n x 4, a1 = an upper bound for the number of
	        cells of mode 1.
*/
static int comb_simnodes(int64_t n, int64_t nties, const long *ei, const long *ej, const double *ew,
		int type, int dtype, int64_t start, int64_t count, int mode) {
	n390_g_t g;
	n390_stats_t st;
	double *wrow, *wcol, *co, *dp, *ci, *dq, *zflag = NULL, *ubase = NULL, *abase = NULL;
	int64_t *stamp = NULL, *touched = NULL, *zlist = NULL;
	int64_t i, j, k, p, q, c, nz = 0, nt, L = 0, cap = 0;
	double nn = (double)n;
	int rc = 0;

	if (n390_gbuild(&g, n, nties, ei, ej, ew)) return 2;
	memset(&st, 0, sizeof(st));
	st.odeg = (double *)calloc((size_t)n, sizeof(double)); st.ideg = (double *)calloc((size_t)n, sizeof(double));
	st.osq = (double *)calloc((size_t)n, sizeof(double)); st.isq = (double *)calloc((size_t)n, sizeof(double));
	st.oabs = (double *)calloc((size_t)n, sizeof(double)); st.iabs = (double *)calloc((size_t)n, sizeof(double));
	wrow = (double *)calloc((size_t)n, sizeof(double)); wcol = (double *)calloc((size_t)n, sizeof(double));
	co = (double *)calloc((size_t)n, sizeof(double)); dp = (double *)calloc((size_t)n, sizeof(double));
	ci = (double *)calloc((size_t)n, sizeof(double)); dq = (double *)calloc((size_t)n, sizeof(double));
	zflag = (double *)calloc((size_t)n, sizeof(double)); ubase = (double *)calloc((size_t)n, sizeof(double)); abase = (double *)calloc((size_t)n, sizeof(double));
	stamp = (int64_t *)malloc((size_t)n * sizeof(int64_t)); touched = (int64_t *)malloc((size_t)n * sizeof(int64_t));
	zlist = (int64_t *)malloc((size_t)n * sizeof(int64_t));
	if (!st.odeg || !st.ideg || !st.osq || !st.isq || !st.oabs || !st.iabs || !wrow || !wcol || !co || !dp || !ci || !dq
			|| !zflag || !ubase || !abase || !stamp || !touched || !zlist) { rc = 2; goto done; }
	for (i = 0; i < n; i++) stamp[i] = -1;

	/* per node: binary degree, sum of the values (pearson) or of their absolute values (manhatten), sum of squares */
	for (i = 0; i < n; i++) {
		double s = 0, s2 = 0, sa = 0;
		for (p = g.optr[i]; p < g.optr[i + 1]; p++) { s += g.ow[p]; s2 += g.ow[p] * g.ow[p]; sa += fabs(g.ow[p]); }
		st.odeg[i] = (double)(g.optr[i + 1] - g.optr[i]); st.osq[i] = s2; st.oabs[i] = (type == 1) ? s : sa;
		s = 0; s2 = 0; sa = 0;
		for (p = g.iptr[i]; p < g.iptr[i + 1]; p++) { s += g.iw[p]; s2 += g.iw[p] * g.iw[p]; sa += fabs(g.iw[p]); }
		st.ideg[i] = (double)(g.iptr[i + 1] - g.iptr[i]); st.isq[i] = s2; st.iabs[i] = (type == 1) ? s : sa;
	}

	/* the base matrix of the caller: cells without a tie between the two nodes and without a shared neighbour */
	for (i = 0; i < n; i++) {
		double od = st.odeg[i], id = st.ideg[i], a = 0, u = 0, z = 0;
		switch (type) {
		case 1: {
			double Sx, Sxx, m, dx;
			if (dtype == 1) { Sx = st.oabs[i]; Sxx = st.osq[i]; m = nn - 2; }
			else if (dtype == 2) { Sx = st.iabs[i]; Sxx = st.isq[i]; m = nn - 2; }
			else { Sx = st.oabs[i] + st.iabs[i]; Sxx = st.osq[i] + st.isq[i]; m = 2 * (nn - 2); }
			dx = m * Sxx - Sx * Sx;
			if (dx > 0 && dx - dx == 0) u = Sx / sqrt(dx); else z = 1;   /* the base cell is -u_i u_j */
			break; }
		case 2: case 8: {
			a = dtype == 0 ? ((nn - 2) - od - id) / (2 * (nn - 2)) : dtype == 1 ? 0.5 - id / (nn - 2) : 0.5 - od / (nn - 2);
			if (type == 8) a = 0.5 - a;
			break; }
		case 4: a = dtype == 0 ? nn - od - id : dtype == 1 ? nn / 2 - id : nn / 2 - od; break;
		case 10: a = dtype == 0 ? od + id : dtype == 1 ? id : od; break;
		case 3: case 9: z = (dtype == 0 ? (od == 0 && id == 0) : dtype == 1 ? (id == 0) : (od == 0)); break;
		case 6: a = dtype == 0 ? st.osq[i] + st.isq[i] : dtype == 1 ? st.isq[i] : st.osq[i]; break;
		case 7: a = dtype == 0 ? st.oabs[i] + st.iabs[i] : dtype == 1 ? st.iabs[i] : st.oabs[i]; break;
		default: break;
		}
		abase[i] = a; ubase[i] = u; zflag[i] = z;
		if (type == 1 && z) zlist[nz++] = i;
	}

	if (mode == 2) {
		double est = 0;
		if (res_alloc((long)n, 4)) { rc = 2; goto done; }
		for (i = 0; i < n; i++) {
			g_res[i * 4] = abase[i]; g_res[i * 4 + 1] = ubase[i]; g_res[i * 4 + 2] = zflag[i]; g_res[i * 4 + 3] = 0;
			est += (double)(g.optr[i + 1] - g.optr[i]) * (double)(g.optr[i + 1] - g.optr[i]) + (double)(g.iptr[i + 1] - g.iptr[i]) * (double)(g.iptr[i + 1] - g.iptr[i])
				+ (double)(g.optr[i + 1] - g.optr[i]) + (double)(g.iptr[i + 1] - g.iptr[i]);
		}
		est += (double)nz * (double)n * 2 + nn;
		pub_a(1, est);
		pub_result(0, (long)n, 4);
		goto done;
	}
	if (start < 1 || count < 1 || start > n) { rc = 198; goto done; }
	if (mode == 0) {
		if (start + count - 1 > n) { rc = 198; goto done; }
		if (res_alloc((long)n, (long)count)) { rc = 2; goto done; }
	} else {
		cap = count + n + 1;
		if (res_alloc((long)cap, 3)) { rc = 2; goto done; }
	}

	for (j = start - 1; j < n; j++) {
		/* the ties of j to and from every node */
		nt = 0;
		for (p = g.optr[j]; p < g.optr[j + 1]; p++) { i = g.oidx[p]; wrow[i] = g.ow[p]; if (stamp[i] != j) { stamp[i] = j; touched[nt++] = i; } }
		for (p = g.iptr[j]; p < g.iptr[j + 1]; p++) { i = g.iidx[p]; wcol[i] = g.iw[p]; if (stamp[i] != j) { stamp[i] = j; touched[nt++] = i; } }
		/* shared out-neighbours k of i and j: i -> k and j -> k; shared in-neighbours: k -> i and k -> j */
		for (p = g.optr[j]; p < g.optr[j + 1]; p++) {
			double b = g.ow[p];
			k = g.oidx[p];
			for (q = g.iptr[k]; q < g.iptr[k + 1]; q++) {
				double a = g.iw[q];
				i = g.iidx[q];
				if (stamp[i] != j) { stamp[i] = j; touched[nt++] = i; }
				co[i] += 1;
				if (type == 7) dp[i] += fabs(a) + fabs(b) - fabs(a - b); else dp[i] += a * b;
			}
		}
		for (p = g.iptr[j]; p < g.iptr[j + 1]; p++) {
			double b = g.iw[p];
			k = g.iidx[p];
			for (q = g.optr[k]; q < g.optr[k + 1]; q++) {
				double a = g.ow[q];
				i = g.oidx[q];
				if (stamp[i] != j) { stamp[i] = j; touched[nt++] = i; }
				ci[i] += 1;
				if (type == 7) dq[i] += fabs(a) + fabs(b) - fabs(a - b); else dq[i] += a * b;
			}
		}
		if (mode == 0) {
			c = j - (start - 1);
			if (c >= count) break;
			for (i = 0; i < n; i++)
				g_res[i * count + c] = n390_cell(type, dtype, nn, &st, i, j, wcol[i], wrow[i], co[i], ci[i], dp[i], dq[i]);
			memset(co, 0, (size_t)n * sizeof(double)); memset(dp, 0, (size_t)n * sizeof(double));
			memset(ci, 0, (size_t)n * sizeof(double)); memset(dq, 0, (size_t)n * sizeof(double));
		} else {
			if (type == 1 && zflag[j]) {
				/* a node without variance: every cell of its column differs from the base */
				for (i = 0; i < n; i++) {
					g_res[L * 3] = (double)(i + 1); g_res[L * 3 + 1] = (double)(j + 1);
					g_res[L * 3 + 2] = n390_cell(type, dtype, nn, &st, i, j, wcol[i], wrow[i], co[i], ci[i], dp[i], dq[i]);
					L++;
				}
			} else {
				if (type == 1) for (q = 0; q < nz; q++) { i = zlist[q]; if (stamp[i] != j) { stamp[i] = j; touched[nt++] = i; } }
				for (q = 0; q < nt; q++) {
					i = touched[q];
					g_res[L * 3] = (double)(i + 1); g_res[L * 3 + 1] = (double)(j + 1);
					g_res[L * 3 + 2] = n390_cell(type, dtype, nn, &st, i, j, wcol[i], wrow[i], co[i], ci[i], dp[i], dq[i]);
					L++;
				}
			}
			for (q = 0; q < nt; q++) { i = touched[q]; co[i] = 0; dp[i] = 0; ci[i] = 0; dq[i] = 0; }
		}
		for (p = g.optr[j]; p < g.optr[j + 1]; p++) wrow[g.oidx[p]] = 0;
		for (p = g.iptr[j]; p < g.iptr[j + 1]; p++) wcol[g.iidx[p]] = 0;
		if (mode == 1 && L >= count) { j++; break; }
	}
	if (mode == 0) { pub_result(0, (long)n, (long)count); }
	else {
		/* the rows beyond L are not read: the result is L x 3 */
		g_res_rows = (long)L;
		pub_a(1, (double)(j + 1));
		pub_result(0, (long)L, 3);
	}
done:
	free(st.odeg); free(st.ideg); free(st.osq); free(st.isq); free(st.oabs); free(st.iabs); free(wrow); free(wcol);
	free(co); free(dp); free(ci); free(dq); free(zflag); free(ubase); free(abase); free(stamp); free(touched); free(zlist);
	n390_gfree(&g);
	return rc;
}


/* ---------------------------------------------------------------- */
/* 52: DIRT_LPA+ (Beckett 2016) modules of a two-mode network         */
/* ---------------------------------------------------------------- */
/*
	52  dirtlpa  par: mini reps seed.  Beckett's (2016) label propagation for Barber's modularity in weighted bipartite
	            networks, LPAwb+ with the repeated starts of DIRT_LPA+, as bipartite::DIRT_LPA_wb_plus (R package bipartite
	            2.24; computeModules(method = "Beckett")): the smaller mode is the "red" side.  LPAwb+ starts with a label per
	            red node, then alternates the update of the blue labels (every blue node takes the label of the red modules
	            that maximises the sum of its tie weights to the module minus the expected weight, ties between equal
	            maxima are broken at random) and of the red labels until Barber's Q no longer rises (stage one), merges
	            pairs of modules that raise Q (stage two) and repeats both until no merge is made.  DIRT_LPA+ runs LPAwb+
	            once, then for every number of starting modules a = mini..(modules found) `reps' further runs from random
	            labels 1..a+1 and keeps the best Q.  Differences from the R code, which evaluates Q in the merge stage with a
	            matrix trace whose columns are matched to the rows by position and not by label: here Q is Barber's Q of the
	            labels every time (the R code and this one agree whenever the two sets of labels appear in the same order); the
	            Q returned is that of the returned labels.  Ties = the symmetric pairs (i, j, w), i < j, variable 4 = the mode
	            (1 or 2) of every node.  Result n x 1 (module 1..k, as the other community kernels); a1 = Q, a2 = number
	            of LPAwb+ runs.  The random choices come from the generator seeded with `seed'.
*/
#define ALG_DIRTLPA 52

typedef struct {
	int64_t R, C, m_;
	int64_t *rp, *ri, *cp, *ci;
	double *rw, *cw, *rk, *ck;
	double m;
	int64_t *rl, *bl;                  /* labels, -1 = not yet assigned */
	int64_t LM;                        /* labels are 0..LM-1 */
	double *TR, *TB;                   /* total degree of the red / blue nodes of every label */
	n370_rng_t *rng;
	/* work */
	int64_t *chl, *pos, *tie;
	double *acc;
	int64_t *o_rl, *o_bl;
	double *o_TR, *o_TB;
} n390_dl_t;

static double n390_dl_q(const n390_dl_t *d) {
	/* Barber's Q of the labels: (sum of the tie weights inside the modules - sum_c TR_c TB_c / m) / m */
	int64_t r, p, c;
	double within = 0, ex = 0;
	if (d->R == 0 || d->bl[0] < 0) return 0.0;
	for (r = 0; r < d->R; r++)
		for (p = d->rp[r]; p < d->rp[r + 1]; p++) if (d->rl[r] == d->bl[d->ri[p]]) within += d->rw[p];
	for (c = 0; c < d->LM; c++) ex += d->TR[c] * d->TB[c];
	return (within - ex / d->m) / d->m;
}

static void n390_dl_totals(n390_dl_t *d) {
	int64_t r, c;
	memset(d->TR, 0, (size_t)d->LM * sizeof(double));
	memset(d->TB, 0, (size_t)d->LM * sizeof(double));
	for (r = 0; r < d->R; r++) d->TR[d->rl[r]] += d->rk[r];
	for (c = 0; c < d->C; c++) if (d->bl[c] >= 0) d->TB[d->bl[c]] += d->ck[c];
}

/* the labels of the vector in order of first appearance; returns their number, d->pos[label] = index in chl */
static int64_t n390_dl_unique(n390_dl_t *d, const int64_t *lab, int64_t cnt) {
	int64_t i, k = 0;
	for (i = 0; i < d->LM; i++) d->pos[i] = -1;
	for (i = 0; i < cnt; i++) if (lab[i] >= 0 && d->pos[lab[i]] < 0) { d->pos[lab[i]] = k; d->chl[k++] = lab[i]; }
	return k;
}

/* one choice among the labels with the largest value (ties at random, as sample() in the R code) */
static int64_t n390_dl_pick(n390_dl_t *d, const double *val, int64_t k) {
	int64_t i, nt = 0;
	double mx = -1e300;
	for (i = 0; i < k; i++) if (val[i] > mx) mx = val[i];
	for (i = 0; i < k; i++) if (val[i] == mx) d->tie[nt++] = i;
	if (nt == 1) return d->tie[0];
	return d->tie[n370_below(d->rng, (long)nt)];
}

/* stage one: alternate updates of the blue and the red labels while Q rises; returns Q */
static double n390_dl_stage1(n390_dl_t *d) {
	double qbefore, qafter;
	int64_t i, j, p, k, first = 1;
	int na_start = (d->bl[0] < 0);
	n390_dl_totals(d);
	qafter = n390_dl_q(d);
	for (;;) {
		qbefore = qafter;
		memcpy(d->o_rl, d->rl, (size_t)d->R * sizeof(int64_t));
		memcpy(d->o_bl, d->bl, (size_t)d->C * sizeof(int64_t));
		memcpy(d->o_TR, d->TR, (size_t)d->LM * sizeof(double));
		memcpy(d->o_TB, d->TB, (size_t)d->LM * sizeof(double));
		k = n390_dl_unique(d, d->rl, d->R);
		for (j = 0; j < d->C; j++) {
			for (i = 0; i < k; i++) d->acc[i] = 0;
			if (d->bl[j] >= 0) d->TB[d->bl[j]] -= d->ck[j];
			for (p = d->cp[j]; p < d->cp[j + 1]; p++) d->acc[d->pos[d->rl[d->ci[p]]]] += d->cw[p];
			for (i = 0; i < k; i++) d->acc[i] = d->acc[i] - d->ck[j] * d->TR[d->chl[i]] / d->m;
			i = n390_dl_pick(d, d->acc, k);
			d->bl[j] = d->chl[i];
			d->TB[d->bl[j]] += d->ck[j];
		}
		k = n390_dl_unique(d, d->bl, d->C);
		for (i = 0; i < d->R; i++) {
			int64_t a = i;
			int64_t q;
			for (q = 0; q < k; q++) d->acc[q] = 0;
			d->TR[d->rl[a]] -= d->rk[a];
			for (p = d->rp[a]; p < d->rp[a + 1]; p++) d->acc[d->pos[d->bl[d->ri[p]]]] += d->rw[p];
			for (q = 0; q < k; q++) d->acc[q] = d->acc[q] - d->rk[a] * d->TB[d->chl[q]] / d->m;
			q = n390_dl_pick(d, d->acc, k);
			d->rl[a] = d->chl[q];
			d->TR[d->rl[a]] += d->rk[a];
		}
		qafter = n390_dl_q(d);
		if (qafter <= qbefore) {
			if (first && na_start) break;   /* nothing to go back to: the first pass is kept */
			memcpy(d->rl, d->o_rl, (size_t)d->R * sizeof(int64_t));
			memcpy(d->bl, d->o_bl, (size_t)d->C * sizeof(int64_t));
			memcpy(d->TR, d->o_TR, (size_t)d->LM * sizeof(double));
			memcpy(d->TB, d->o_TB, (size_t)d->LM * sizeof(double));
			qafter = n390_dl_q(d);
			break;
		}
		first = 0;
	}
	return qafter;
}

/* merge of the pairs of modules that raise Q; returns 1 on out of memory */
static int n390_dl_stage2(n390_dl_t *d, double *q) {
	for (;;) {
		int64_t D, a, b, x, y, p, r, c, aa, comb = 0;
		int64_t *div, *dix;
		double *M, qcur, qstale;
		double mm = d->m;
		int64_t *tmp = d->chl;
		n390_dl_totals(d);
		/* divisions: labels of both sides, in the order of the red labels */
		div = (int64_t *)malloc((size_t)d->LM * sizeof(int64_t));
		dix = (int64_t *)malloc((size_t)d->LM * sizeof(int64_t));
		if (!div || !dix) { free(div); free(dix); return 1; }
		for (x = 0; x < d->LM; x++) dix[x] = -1;
		{
			int64_t *seenb = (int64_t *)calloc((size_t)d->LM, sizeof(int64_t));
			if (!seenb) { free(div); free(dix); return 1; }
			for (c = 0; c < d->C; c++) if (d->bl[c] >= 0) seenb[d->bl[c]] = 1;
			D = 0;
			for (r = 0; r < d->R; r++) if (seenb[d->rl[r]] && dix[d->rl[r]] < 0) { dix[d->rl[r]] = D; div[D++] = d->rl[r]; }
			free(seenb);
		}
		(void)tmp;
		if (D < 2 || D > 3000) { free(div); free(dix); break; }
		M = (double *)calloc((size_t)D * (size_t)D, sizeof(double));
		if (!M) { free(div); free(dix); return 1; }
		for (r = 0; r < d->R; r++) {
			x = dix[d->rl[r]];
			if (x < 0) continue;
			for (p = d->rp[r]; p < d->rp[r + 1]; p++) {
				int64_t bl = d->bl[d->ri[p]];
				y = bl >= 0 ? dix[bl] : -1;
				if (y >= 0) M[x * D + y] += d->rw[p];
			}
		}
		qcur = n390_dl_q(d);
		qstale = qcur;
		/* delta(x, y): the change of Q when the divisions x and y are joined */
		#define N390_DELTA(X, Y) (((X) == (Y)) ? 0.0 : ((M[(X) * D + (Y)] + M[(Y) * D + (X)] - (d->TR[div[X]] * d->TB[div[Y]] + d->TR[div[Y]] * d->TB[div[X]]) / mm) / mm))
		for (a = 0; a < D - 1; a++) {
			for (b = a + 1; b < D; b++) {
				double qq = qcur + N390_DELTA(a, b);
				if (qq > qstale) {
					int better = 0;
					for (aa = 0; aa < D && !better; aa++) {
						if (qcur + N390_DELTA(aa, a) > qq) better = 1;
						if (qcur + N390_DELTA(aa, b) > qq) better = 1;
					}
					if (!better) {
						/* a joins b: the labels of a become the labels of b */
						for (r = 0; r < d->R; r++) if (d->rl[r] == div[a]) d->rl[r] = div[b];
						for (c = 0; c < d->C; c++) if (d->bl[c] == div[a]) d->bl[c] = div[b];
						for (x = 0; x < D; x++) { M[b * D + x] += M[a * D + x]; M[a * D + x] = 0; }
						for (x = 0; x < D; x++) { M[x * D + b] += M[x * D + a]; M[x * D + a] = 0; }
						d->TR[div[b]] += d->TR[div[a]]; d->TR[div[a]] = 0;
						d->TB[div[b]] += d->TB[div[a]]; d->TB[div[a]] = 0;
						qcur = qq;
						comb++;
					}
				}
			}
		}
		#undef N390_DELTA
		free(M); free(div); free(dix);
		*q = n390_dl_stage1(d);
		if (comb == 0) break;
	}
	*q = n390_dl_q(d);
	return 0;
}

/* LPAwb+ from the given starting number of modules (0 = a module per red node); returns 0 or 1 (out of memory) */
static int n390_dl_run(n390_dl_t *d, int64_t init, double *q) {
	int64_t r, c;
	for (c = 0; c < d->C; c++) d->bl[c] = -1;
	if (init <= 0) for (r = 0; r < d->R; r++) d->rl[r] = r;
	else for (r = 0; r < d->R; r++) d->rl[r] = n370_below(d->rng, (long)(init + 1));
	*q = n390_dl_stage1(d);
	if (n390_dl_stage2(d, q)) return 1;
	return 0;
}

static int comb_dirtlpa(int64_t n, int64_t nties, const long *ei, const long *ej, const double *ew, const double *nv,
		int64_t mini, int64_t reps, double seed) {
	int64_t i, k, nr = 0, nc = 0, np = 0, mods, a, b, runs = 0, p;
	int64_t *side = NULL, *idx = NULL, *rnode = NULL, *cnode = NULL, *ps = NULL, *pd = NULL;
	double *pw = NULL, qa, qb;
	int64_t *bestr = NULL, *bestb = NULL, *seen = NULL;
	int red_mode;
	n390_dl_t d;
	n370_rng_t rng;
	int rc = 0;

	memset(&d, 0, sizeof(d));
	if (n <= 0) { if (res_alloc(0, 1)) return 2; pub_result(0, 0, 1); return 0; }
	n370_seed(&rng, seed);
	d.rng = &rng;
	side = (int64_t *)malloc((size_t)n * sizeof(int64_t));
	idx = (int64_t *)malloc((size_t)n * sizeof(int64_t));
	ps = (int64_t *)malloc(((size_t)nties + 1) * sizeof(int64_t));
	pd = (int64_t *)malloc(((size_t)nties + 1) * sizeof(int64_t));
	pw = (double *)malloc(((size_t)nties + 1) * sizeof(double));
	if (!side || !idx || !ps || !pd || !pw) { rc = 2; goto done; }
	for (i = 0; i < n; i++) side[i] = (nv[i] == 1) ? 1 : 2;
	for (i = 0; i < n; i++) { if (side[i] == 1) nr++; else nc++; }
	/* the smaller mode is the red side (mode 1 when they are equal) */
	red_mode = (nr <= nc) ? 1 : 2;
	if (red_mode == 2) { int64_t t = nr; nr = nc; nc = t; }
	{
		int64_t ir = 0, ic = 0;
		rnode = (int64_t *)malloc(((size_t)nr + 1) * sizeof(int64_t));
		cnode = (int64_t *)malloc(((size_t)nc + 1) * sizeof(int64_t));
		if (!rnode || !cnode) { rc = 2; goto done; }
		for (i = 0; i < n; i++) {
			if (side[i] == red_mode) { idx[i] = ir; rnode[ir++] = i; }
			else { idx[i] = ic; cnode[ic++] = i; }
		}
	}
	for (k = 0; k < nties; k++) {
		int64_t x = (int64_t)ei[k] - 1, y = (int64_t)ej[k] - 1, t;
		if (x < 0 || y < 0 || x >= n || y >= n) continue;
		if (side[x] == side[y] || !(ew[k] > 0)) continue;
		if (side[x] != red_mode) { t = x; x = y; y = t; }
		ps[np] = idx[x]; pd[np] = idx[y]; pw[np] = ew[k]; np++;   /* (red, blue, w) */
	}
	d.R = nr; d.C = nc;
	if (np == 0 || nr == 0 || nc == 0) {
		if (res_alloc((long)n, 1)) { rc = 2; goto done; }
		for (i = 0; i < n; i++) g_res[i] = (double)(i + 1);
		pub_a(1, 0.0); pub_a(2, 0.0);
		pub_result(0, (long)n, 1);
		goto done;
	}
	/* the number of labels never exceeds the largest starting number: red nodes, or `a + 1' with a up to the modules found (<= nr) */
	d.LM = nr + 3;
	d.rp = (int64_t *)calloc((size_t)nr + 1, sizeof(int64_t)); d.cp = (int64_t *)calloc((size_t)nc + 1, sizeof(int64_t));
	d.ri = (int64_t *)malloc(((size_t)np + 1) * sizeof(int64_t)); d.ci = (int64_t *)malloc(((size_t)np + 1) * sizeof(int64_t));
	d.rw = (double *)malloc(((size_t)np + 1) * sizeof(double)); d.cw = (double *)malloc(((size_t)np + 1) * sizeof(double));
	d.rk = (double *)calloc((size_t)nr + 1, sizeof(double)); d.ck = (double *)calloc((size_t)nc + 1, sizeof(double));
	d.rl = (int64_t *)malloc(((size_t)nr + 1) * sizeof(int64_t)); d.bl = (int64_t *)malloc(((size_t)nc + 1) * sizeof(int64_t));
	d.TR = (double *)calloc((size_t)d.LM, sizeof(double)); d.TB = (double *)calloc((size_t)d.LM, sizeof(double));
	d.chl = (int64_t *)malloc((size_t)d.LM * sizeof(int64_t)); d.pos = (int64_t *)malloc((size_t)d.LM * sizeof(int64_t));
	d.tie = (int64_t *)malloc((size_t)d.LM * sizeof(int64_t)); d.acc = (double *)malloc((size_t)d.LM * sizeof(double));
	d.o_rl = (int64_t *)malloc(((size_t)nr + 1) * sizeof(int64_t)); d.o_bl = (int64_t *)malloc(((size_t)nc + 1) * sizeof(int64_t));
	d.o_TR = (double *)malloc((size_t)d.LM * sizeof(double)); d.o_TB = (double *)malloc((size_t)d.LM * sizeof(double));
	bestr = (int64_t *)malloc(((size_t)nr + 1) * sizeof(int64_t)); bestb = (int64_t *)malloc(((size_t)nc + 1) * sizeof(int64_t));
	if (!d.rp || !d.cp || !d.ri || !d.ci || !d.rw || !d.cw || !d.rk || !d.ck || !d.rl || !d.bl || !d.TR || !d.TB || !d.chl || !d.pos
			|| !d.tie || !d.acc || !d.o_rl || !d.o_bl || !d.o_TR || !d.o_TB || !bestr || !bestb) { rc = 2; goto done; }
	/* CSR in both directions (the pairs are sorted by neither, a counting sort puts them in order) */
	d.m = 0;
	for (k = 0; k < np; k++) { d.rp[ps[k] + 1]++; d.cp[pd[k] + 1]++; d.rk[ps[k]] += pw[k]; d.ck[pd[k]] += pw[k]; d.m += pw[k]; }
	for (i = 0; i < nr; i++) d.rp[i + 1] += d.rp[i];
	for (i = 0; i < nc; i++) d.cp[i + 1] += d.cp[i];
	{
		int64_t *fr = (int64_t *)malloc(((size_t)nr + 1) * sizeof(int64_t)), *fc = (int64_t *)malloc(((size_t)nc + 1) * sizeof(int64_t));
		if (!fr || !fc) { free(fr); free(fc); rc = 2; goto done; }
		for (i = 0; i < nr; i++) fr[i] = d.rp[i];
		for (i = 0; i < nc; i++) fc[i] = d.cp[i];
		for (k = 0; k < np; k++) {
			d.ri[fr[ps[k]]] = pd[k]; d.rw[fr[ps[k]]] = pw[k]; fr[ps[k]]++;
			d.ci[fc[pd[k]]] = ps[k]; d.cw[fc[pd[k]]] = pw[k]; fc[pd[k]]++;
		}
		free(fr); free(fc);
	}
	/* DIRT_LPA+ */
	if (n390_dl_run(&d, 0, &qa)) { rc = 2; goto done; }
	runs = 1;
	memcpy(bestr, d.rl, (size_t)nr * sizeof(int64_t)); memcpy(bestb, d.bl, (size_t)nc * sizeof(int64_t));
	seen = (int64_t *)calloc((size_t)d.LM, sizeof(int64_t));
	if (!seen) { rc = 2; goto done; }
	mods = 0;
	for (i = 0; i < nr; i++) if (!seen[bestr[i]]) { seen[bestr[i]] = 1; mods++; }
	if (mods - mini > 0) {
		for (a = mini; a <= mods; a++) {
			for (b = 1; b <= reps; b++) {
				/* labels a + 1 can exceed the label range of the arrays when a = nr: the range is nr + 3 */
				if (n390_dl_run(&d, a, &qb)) { rc = 2; goto done; }
				runs++;
				if (qb > qa) { qa = qb; memcpy(bestr, d.rl, (size_t)nr * sizeof(int64_t)); memcpy(bestb, d.bl, (size_t)nc * sizeof(int64_t)); }
			}
		}
	}
	/* result: node labels, dense 1..k */
	if (res_alloc((long)n, 1)) { rc = 2; goto done; }
	{
		int64_t *lab = (int64_t *)malloc((size_t)n * sizeof(int64_t));
		int64_t *rk2 = (int64_t *)calloc((size_t)d.LM + 1, sizeof(int64_t)), cnt = 0;
		if (!lab || !rk2) { free(lab); free(rk2); rc = 2; goto done; }
		for (i = 0; i < nr; i++) lab[rnode[i]] = bestr[i];
		for (i = 0; i < nc; i++) lab[cnode[i]] = bestb[i];
		for (i = 0; i < n; i++) rk2[lab[i]] = 1;
		for (i = 0; i <= d.LM; i++) if (rk2[i]) rk2[i] = ++cnt;
		for (i = 0; i < n; i++) g_res[i] = (double)rk2[lab[i]];
		free(lab); free(rk2);
	}
	(void)p;
	pub_a(1, qa); pub_a(2, (double)runs);
	pub_result(0, (long)n, 1);
done:
	free(side); free(idx); free(ps); free(pd); free(pw); free(rnode); free(cnode);
	free(d.rp); free(d.ri); free(d.cp); free(d.ci); free(d.rw); free(d.cw); free(d.rk); free(d.ck); free(d.rl); free(d.bl);
	free(d.TR); free(d.TB); free(d.chl); free(d.pos); free(d.tie); free(d.acc); free(d.o_rl); free(d.o_bl); free(d.o_TR); free(d.o_TB);
	free(bestr); free(bestb); free(seen);
	return rc;
}


/* ---------------------------------------------------------------- */
/* 53: null-model draws for the two-mode nwcug                        */
/* ---------------------------------------------------------------- */
/*
	53  nullbip  par: model seed ntrades.  One random two-mode network with the number of ties, or the degrees, of the
	            given one.  Ties = the cross-mode ties (mode 1, mode 2, value) once each, variable 4 = the mode (1 or 2)
	            of every node.  model 1: the same number of ties between random pairs (a mode-1 node, a mode-2 node), no pair
	            twice (igraph::sample_bipartite(type = "gnm"); vegan r00); 2: every mode-1 node keeps its degree and takes its
	            partners at random among all mode-2 nodes (vegan r0); 3: the same for the mode-2 nodes (vegan c0); 4: both degree
	            sequences stay (curveball trades of Strona et al. 2014, as vegan::nullmodel(method = "curveball"): the chain
	            starts from the ties given, ntrades trades are made per call, so the caller sends the ties of the previous draw
	            back).  The values of the ties are shuffled over the drawn ties.  Result m x 3 = (mode-1 node, mode-2 node,
	            value) of the new network, the nodes as 1-based network ids.  The random choices come from the generator
	            seeded with `seed'.
*/
#define ALG_NULLBIP 53

typedef struct { int64_t *key; int64_t cap, used; } n390_hs_t;

static uint64_t n390_hh(int64_t k) { uint64_t x = (uint64_t)k * 0x9E3779B97F4A7C15ULL; x ^= x >> 29; return x; }

static int n390_hs_has(const n390_hs_t *h, int64_t k) {
	uint64_t i = n390_hh(k) & (uint64_t)(h->cap - 1);
	while (h->key[i] != -1) { if (h->key[i] == k) return 1; i = (i + 1) & (uint64_t)(h->cap - 1); }
	return 0;
}

static void n390_hs_add(n390_hs_t *h, int64_t k) {
	uint64_t i = n390_hh(k) & (uint64_t)(h->cap - 1);
	while (h->key[i] != -1) i = (i + 1) & (uint64_t)(h->cap - 1);
	h->key[i] = k; h->used++;
}

static int64_t n390_below(n370_rng_t *r, int64_t k) {
	uint64_t lim = (UINT64_MAX / (uint64_t)k) * (uint64_t)k, x;
	do { x = n370_next(r); } while (x >= lim);
	return (int64_t)(x % (uint64_t)k);
}

/* k distinct integers of 0..N-1 into out (Floyd's algorithm with a hash set of the chosen ones) */
static int n390_choose(n370_rng_t *rng, int64_t N, int64_t k, int64_t *out) {
	n390_hs_t h;
	int64_t j, t, c = 0, i;
	h.cap = 16; h.used = 0;
	while (h.cap < 2 * k + 4) h.cap *= 2;
	h.key = (int64_t *)malloc((size_t)h.cap * sizeof(int64_t));
	if (!h.key) return 1;
	for (i = 0; i < h.cap; i++) h.key[i] = -1;
	for (j = N - k; j < N; j++) {
		t = n390_below(rng, j + 1);
		if (n390_hs_has(&h, t)) t = j;
		n390_hs_add(&h, t);
		out[c++] = t;
	}
	free(h.key);
	return 0;
}

static int comb_nullbip(int64_t n, int64_t nties, const long *ei, const long *ej, const double *ew, const double *nv,
		int model, double seed, int64_t ntrades) {
	int64_t i, k, n1 = 0, n2 = 0, m = 0, c, t;
	int64_t *id1 = NULL, *id2 = NULL, *ix = NULL, *deg1 = NULL, *deg2 = NULL, *pa = NULL, *pb = NULL, *sel = NULL;
	double *wt = NULL;
	n370_rng_t rng;
	int rc = 0;

	n370_seed(&rng, seed);
	id1 = (int64_t *)malloc(((size_t)n + 1) * sizeof(int64_t));
	id2 = (int64_t *)malloc(((size_t)n + 1) * sizeof(int64_t));
	ix = (int64_t *)malloc(((size_t)n + 1) * sizeof(int64_t));
	pa = (int64_t *)malloc(((size_t)nties + 1) * sizeof(int64_t));
	pb = (int64_t *)malloc(((size_t)nties + 1) * sizeof(int64_t));
	wt = (double *)malloc(((size_t)nties + 1) * sizeof(double));
	if (!id1 || !id2 || !ix || !pa || !pb || !wt) { rc = 2; goto done; }
	for (i = 0; i < n; i++) { if (nv[i] == 1) { ix[i] = n1; id1[n1++] = i + 1; } else { ix[i] = n2; id2[n2++] = i + 1; } }
	deg1 = (int64_t *)calloc((size_t)n1 + 1, sizeof(int64_t));
	deg2 = (int64_t *)calloc((size_t)n2 + 1, sizeof(int64_t));
	if (!deg1 || !deg2) { rc = 2; goto done; }
	for (k = 0; k < nties; k++) {
		int64_t x = (int64_t)ei[k] - 1, y = (int64_t)ej[k] - 1;
		if (x < 0 || y < 0 || x >= n || y >= n || ew[k] == 0) continue;
		if (nv[x] == nv[y]) continue;
		if (nv[x] != 1) { int64_t u = x; x = y; y = u; }
		pa[m] = ix[x]; pb[m] = ix[y]; wt[m] = ew[k]; deg1[ix[x]]++; deg2[ix[y]]++; m++;
	}
	if (m > 0 && (n1 == 0 || n2 == 0)) { rc = 198; goto done; }
	/* the new ties in pa / pb */
	if (m > 0) {
		if (model == 1) {
			sel = (int64_t *)malloc(((size_t)m + 1) * sizeof(int64_t));
			if (!sel) { rc = 2; goto done; }
			if (n390_choose(&rng, n1 * n2, m, sel)) { rc = 2; goto done; }
			for (k = 0; k < m; k++) { pa[k] = sel[k] / n2; pb[k] = sel[k] % n2; }
		} else if (model == 2 || model == 3) {
			int64_t na = (model == 2) ? n1 : n2, nb = (model == 2) ? n2 : n1;
			int64_t *dg = (model == 2) ? deg1 : deg2;
			int64_t *perm = (int64_t *)malloc(((size_t)nb + 1) * sizeof(int64_t));
			if (!perm) { rc = 2; goto done; }
			for (i = 0; i < nb; i++) perm[i] = i;
			c = 0;
			for (i = 0; i < na; i++) {
				int64_t j;
				for (j = 0; j < dg[i]; j++) {   /* partial Fisher-Yates on perm */
					int64_t r = j + n390_below(&rng, nb - j), u = perm[j];
					perm[j] = perm[r]; perm[r] = u;
					if (model == 2) { pa[c] = i; pb[c] = perm[j]; } else { pa[c] = perm[j]; pb[c] = i; }
					c++;
				}
			}
			free(perm);
		} else if (model == 4) {
			/* curveball: rows = the mode with fewer nodes */
			int rowmode1 = (n1 <= n2);
			int64_t nr = rowmode1 ? n1 : n2, nc = rowmode1 ? n2 : n1;
			int64_t *rdeg = rowmode1 ? deg1 : deg2, *rstart, *cells, *mA, *mB, *ex, *fill;
			rstart = (int64_t *)calloc((size_t)nr + 1, sizeof(int64_t));
			cells = (int64_t *)malloc(((size_t)m + 1) * sizeof(int64_t));
			mA = (int64_t *)calloc((size_t)nc + 1, sizeof(int64_t));
			mB = (int64_t *)calloc((size_t)nc + 1, sizeof(int64_t));
			ex = (int64_t *)malloc(((size_t)(nc > 0 ? nc : 1) + 1) * sizeof(int64_t));
			fill = (int64_t *)malloc(((size_t)nr + 1) * sizeof(int64_t));
			if (!rstart || !cells || !mA || !mB || !ex || !fill) { free(rstart); free(cells); free(mA); free(mB); free(ex); free(fill); rc = 2; goto done; }
			for (i = 0; i < nr; i++) rstart[i + 1] = rstart[i] + rdeg[i];
			for (i = 0; i < nr; i++) fill[i] = rstart[i];
			for (k = 0; k < m; k++) { int64_t r = rowmode1 ? pa[k] : pb[k], cc = rowmode1 ? pb[k] : pa[k]; cells[fill[r]++] = cc; }
			if (nr >= 2) {
				for (t = 1; t <= ntrades; t++) {
					int64_t a = n390_below(&rng, nr), b = n390_below(&rng, nr - 1), da, db, nea = 0, neb = 0, q, tot;
					if (b >= a) b++;
					da = rdeg[a]; db = rdeg[b];
					if (da == 0 || db == 0) continue;
					for (q = 0; q < da; q++) mA[cells[rstart[a] + q]] = t;
					for (q = 0; q < db; q++) mB[cells[rstart[b] + q]] = t;
					/* exclusive cells of a first, then of b */
					for (q = 0; q < da; q++) if (mB[cells[rstart[a] + q]] != t) ex[nea++] = cells[rstart[a] + q];
					for (q = 0; q < db; q++) if (mA[cells[rstart[b] + q]] != t) ex[nea + neb++] = cells[rstart[b] + q];
					tot = nea + neb;
					if (nea == 0 || neb == 0) continue;
					for (q = tot - 1; q > 0; q--) { int64_t r = n390_below(&rng, q + 1), u = ex[q]; ex[q] = ex[r]; ex[r] = u; }
					/* common cells stay, the exclusive ones are dealt anew: a gets nea of them, b the rest */
					{
						int64_t ca = 0, cb = 0;
						for (q = 0; q < da; q++) { int64_t cc = cells[rstart[a] + q]; if (mB[cc] == t) cells[rstart[a] + ca++] = cc; }
						for (q = 0; q < db; q++) { int64_t cc = cells[rstart[b] + q]; if (mA[cc] == t) cells[rstart[b] + cb++] = cc; }
						for (q = 0; q < nea; q++) cells[rstart[a] + ca++] = ex[q];
						for (q = nea; q < tot; q++) cells[rstart[b] + cb++] = ex[q];
					}
				}
			}
			c = 0;
			for (i = 0; i < nr; i++) {
				int64_t q;
				for (q = rstart[i]; q < rstart[i + 1]; q++) {
					if (rowmode1) { pa[c] = i; pb[c] = cells[q]; } else { pa[c] = cells[q]; pb[c] = i; }
					c++;
				}
			}
			free(rstart); free(cells); free(mA); free(mB); free(ex); free(fill);
		} else { rc = 198; goto done; }
		/* the values are shuffled over the new ties */
		for (k = m - 1; k > 0; k--) { int64_t r = n390_below(&rng, k + 1); double u = wt[k]; wt[k] = wt[r]; wt[r] = u; }
	}
	if (res_alloc((long)m, 3)) { rc = 2; goto done; }
	for (k = 0; k < m; k++) { g_res[3 * k] = (double)id1[pa[k]]; g_res[3 * k + 1] = (double)id2[pb[k]]; g_res[3 * k + 2] = wt[k]; }
	pub_result(0, (long)m, 3);
done:
	free(id1); free(id2); free(ix); free(pa); free(pb); free(wt); free(deg1); free(deg2); free(sel);
	return rc;
}


/* ---------------------------------------------------------------- */
/* 54: weighted Kamada-Kawai sweeps                                   */
/* ---------------------------------------------------------------- */
/*
	54  kkw  par: iterations.  The sweeps of nw_wkklayout() in _nwwlayout.ado (Kamada-Kawai by stress majorization with the
	         weighted shortest paths as target distances).  Ties = the symmetric strengths (both directions, value > 0; the
	         caller has divided them by their mean), length of a tie 1/strength; variable 4 = the start coordinates, x for
	         nodes 1..n, y for nodes n+1..2n.  Pairs in different components get the distance (longest finite distance +
	         mean tie length), as in the Mata code.  Result n x 2 = the coordinates after the sweeps (unchanged when two nodes
	         coincide); a1 = 0 done, 1 two nodes coincided (the caller runs its interpreted loop, which draws random numbers).
*/
#define ALG_KKW 54

static int comb_kkw(int64_t n, int64_t nties, const long *ei, const long *ej, const double *ew, const double *nv, int64_t iter) {
	dj_t g;
	double *D = NULL, *wsum = NULL, *px = NULL, *py = NULL, *row = NULL;
	bw_hn_t *heap = NULL;
	unsigned char *settled = NULL;
	int64_t i, j, t, k, ne = 0;
	double mx = 0, mu = 0, big;
	int status = 0, rc = 0;

	memset(&g, 0, sizeof(g));
	if (n < 2) return 198;
	if (dj_build(&g, (long)n, (long)nties, ei, ej, ew, 1.0)) return 2;
	D = (double *)malloc((size_t)n * (size_t)n * sizeof(double));
	wsum = (double *)malloc((size_t)n * sizeof(double));
	px = (double *)malloc((size_t)n * sizeof(double)); py = (double *)malloc((size_t)n * sizeof(double));
	row = (double *)malloc((size_t)n * sizeof(double));
	heap = (bw_hn_t *)malloc(((size_t)g.ptr[n] + 2) * sizeof(bw_hn_t));
	settled = (unsigned char *)malloc((size_t)n);
	if (!D || !wsum || !px || !py || !row || !heap || !settled) { rc = 2; goto done; }
	for (k = 0; k < nties; k++) if (ei[k] >= 1 && ej[k] >= 1 && ei[k] <= n && ej[k] <= n && ei[k] != ej[k] && ew[k] > 0) { mu += 1.0 / ew[k]; ne++; }
	mu = ne > 0 ? mu / (double)ne : 0;
	for (i = 0; i < n; i++) {
		dj_run(&g, (long)i, D + i * n, heap, settled);
		for (j = 0; j < n; j++) if (D[i * n + j] >= 0 && D[i * n + j] > mx) mx = D[i * n + j];
	}
	big = mx + mu;
	for (i = 0; i < n * n; i++) if (D[i] < 0) D[i] = big;
	/* D becomes 1/D (0 on the diagonal); wsum[i] = sum_j (1/D_ji)^2 */
	for (i = 0; i < n; i++) {
		double ws = 0;
		for (j = 0; j < n; j++) {
			double wi = (i == j) ? 0.0 : 1.0 / D[j * n + i];
			ws += wi * wi;
		}
		wsum[i] = ws;
	}
	for (i = 0; i < n * n; i++) D[i] = (D[i] == 0) ? 0.0 : 1.0 / D[i];
	for (i = 0; i < n; i++) D[i * n + i] = 0.0;
	for (i = 0; i < n; i++) { px[i] = nv[i]; py[i] = nv[n + i]; }
	for (t = 1; t <= iter && !status; t++) {
		for (i = 0; i < n; i++) {
			double a1 = 0, a2 = 0, b1 = 0, b2 = 0, xi = px[i], yi = py[i];
			const double *Wi = D + i * n;
			for (j = 0; j < n; j++) {
				double dx = xi - px[j], dy = yi - py[j], d, w, q;
				if (j == i) continue;
				d = sqrt(dx * dx + dy * dy);
				if (d < 1e-8) { status = 1; break; }
				w = Wi[j] * Wi[j];
				q = Wi[j] / d;
				a1 += w * px[j]; a2 += w * py[j];
				b1 += q * dx; b2 += q * dy;
			}
			if (status) break;
			px[i] = (a1 + b1) / wsum[i];
			py[i] = (a2 + b2) / wsum[i];
		}
	}
	if (res_alloc((long)n, 2)) { rc = 2; goto done; }
	for (i = 0; i < n; i++) { g_res[2 * i] = status ? nv[i] : px[i]; g_res[2 * i + 1] = status ? nv[n + i] : py[i]; }
	pub_a(1, (double)status);
	pub_result(0, (long)n, 2);
done:
	free(D); free(wsum); free(px); free(py); free(row); free(heap); free(settled); dj_free(&g);
	return rc;
}

/* called by comb_call() for the codes 51..60 */
static int comb_n390(long alg, long n, long nties, const long *ei, const long *ej, const double *ew, const double *nv, const double *p) {
	switch (alg) {
		case ALG_DIRTLPA:   return comb_dirtlpa((int64_t)n, (int64_t)nties, ei, ej, ew, nv, (int64_t)p[3], (int64_t)p[4], p[5]);
		case ALG_NULLBIP:   return comb_nullbip((int64_t)n, (int64_t)nties, ei, ej, ew, nv, (int)p[3], p[4], (int64_t)p[5]);
		case ALG_KKW:       return comb_kkw((int64_t)n, (int64_t)nties, ei, ej, ew, nv, (int64_t)p[3]);
		case ALG_SIMNODES:  return comb_simnodes((int64_t)n, (int64_t)nties, ei, ej, ew, (int)p[3], (int)p[4], (int64_t)p[5], (int64_t)p[6], (int)p[7]);
		default: SF_error("nwgraph: unknown algorithm code\n"); return 198;
	}
}
