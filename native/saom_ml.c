/* ===================================================================
   saom_ml.c -- maximum likelihood estimation of a SAOM (nwsaom, option ml): the Robbins-Monro algorithm on the score
   function of the augmented data (the chain of ministeps), as RSiena's siena07(maxlike = TRUE) (Snijders, Koskinen &
   Schweinberger 2010; Siena algorithms, chapters 10 and 11). #included by saom_sim.c after saom_bayes.c, which provides the
   chain machinery (moves, cache of change statistics).

   Complete-data score for the objective-function effects: sum over ministeps of (statistic change of the chosen option -
   expected change under the choice probabilities); for a rate: R/rho - n (R = number of ministeps of the period, n actors).
   The complete-data information is the sum of the variances of the change statistic under the choice probabilities (R/rho^2 for
   a rate); the estimated information matrix is its mean minus the covariance matrix of the scores (Louis).
   Phase 1 estimates that information at the start values, phase 2 (nsub subphases of n2start*2.52^(k-1) iterations, gain
   halved every subphase) updates theta <- theta + gain * information^-1 * score after every iteration and averages theta over the
   last subphase, phase 3 (n3 iterations at the final values) gives the covariance matrix (mean information - covariance of
   the scores)^-1 and the convergence t-ratios (mean score / its standard deviation). The chain continues from iteration to iteration.
   =================================================================== */

#ifndef SAOM_ML_C_INCLUDED
#define SAOM_ML_C_INCLUDED

/* solve A x = b for a positive definite A (n x n, row major) by Cholesky; returns 0 if A is not positive definite */
static int bml_solve(const double *A, long n, const double *b, double *x) {
	double *L = (double *)malloc((size_t)(n * n) * sizeof(double)), *y = (double *)malloc((size_t)n * sizeof(double));
	long i, j;
	int ok = bchol(A, L, n);
	if (ok) {
		for (i = 0; i < n; i++) { double s = b[i]; for (j = 0; j < i; j++) s -= L[i * n + j] * y[j]; y[i] = s / L[i * n + i]; }
		for (i = n - 1; i >= 0; i--) { double s = y[i]; for (j = i + 1; j < n; j++) s -= L[j * n + i] * x[j]; x[i] = s / L[i * n + i]; }
	}
	free(L); free(y);
	return ok;
}
static int bml_inverse(const double *A, long n, double *Ainv) {
	long i, j;
	double *e = (double *)calloc((size_t)n, sizeof(double)), *x = (double *)calloc((size_t)n, sizeof(double));
	int ok = 1;
	for (j = 0; j < n && ok; j++) {
		e[j] = 1.0;
		ok = bml_solve(A, n, e, x);
		e[j] = 0.0;
		for (i = 0; i < n; i++) Ainv[i * n + j] = x[i];
	}
	free(e); free(x);
	return ok;
}

/* the score S (K effects, then one rate per period) and the complete-data information H ((K+P)^2) of the current chains at (th, rho);
   the cache of change statistics must be current */
static void bml_score(bctx_t *B, const double *th, double *S, double *H) {
	long pd, r, h, k, l, n = B->n, K = B->K, KP = K + B->nper;
	double *E = (double *)calloc((size_t)K, sizeof(double)), *EE = (double *)calloc((size_t)(K * K), sizeof(double)), *w = (double *)calloc((size_t)n, sizeof(double));
	for (k = 0; k < KP; k++) S[k] = 0.0;
	for (k = 0; k < KP * KP; k++) H[k] = 0.0;
	for (pd = 0; pd < B->nper; pd++) {
		bchain_t *c = &B->ch[pd];
		for (r = 0; r < c->R; r++) {
			const double *src = B->cache + ((size_t)(B->coff[pd] + r) * (size_t)n) * (size_t)K;
			double mx = -1e300, Z = 0.0;
			for (h = 0; h < n; h++) {
				double u = 0.0;
				for (k = 0; k < K; k++) u += th[k] * src[h * K + k];
				w[h] = u;
				if (u > mx) mx = u;
			}
			for (h = 0; h < n; h++) { w[h] = exp(w[h] - mx); Z += w[h]; }
			for (k = 0; k < K; k++) E[k] = 0.0;
			for (k = 0; k < K * K; k++) EE[k] = 0.0;
			for (h = 0; h < n; h++) {
				double p = w[h] / Z;
				const double *ch = src + h * K;
				for (k = 0; k < K; k++) {
					double pk = p * ch[k];
					if (pk == 0.0) continue;
					E[k] += pk;
					for (l = 0; l <= k; l++) EE[k * K + l] += pk * ch[l];
				}
			}
			{
				const double *cj = src + (size_t)(c->ej[r] - 1) * (size_t)K;
				for (k = 0; k < K; k++) S[k] += cj[k] - E[k];
			}
			for (k = 0; k < K; k++) for (l = 0; l <= k; l++) H[k * KP + l] += EE[k * K + l] - E[k] * E[l];
		}
		S[K + pd] = (double)c->R / B->rho[pd] - (double)n;
		H[(K + pd) * KP + (K + pd)] = (double)c->R / (B->rho[pd] * B->rho[pd]);
	}
	for (k = 0; k < KP; k++) for (l = k + 1; l < KP; l++) H[k * KP + l] = H[l * KP + k];
	free(E); free(EE); free(w);
}

typedef struct {
	long N;
	double *sS, *sSS, *sH, *sTh;
} bml_acc_t;
static void bml_acc_init(bml_acc_t *A, long KP) {
	A->N = 0;
	A->sS = (double *)calloc((size_t)KP, sizeof(double)); A->sSS = (double *)calloc((size_t)(KP * KP), sizeof(double));
	A->sH = (double *)calloc((size_t)(KP * KP), sizeof(double)); A->sTh = (double *)calloc((size_t)KP, sizeof(double));
}
static void bml_acc_reset(bml_acc_t *A, long KP) {
	A->N = 0;
	memset(A->sS, 0, (size_t)KP * sizeof(double)); memset(A->sSS, 0, (size_t)(KP * KP) * sizeof(double));
	memset(A->sH, 0, (size_t)(KP * KP) * sizeof(double)); memset(A->sTh, 0, (size_t)KP * sizeof(double));
}
static void bml_acc_free(bml_acc_t *A) { free(A->sS); free(A->sSS); free(A->sH); free(A->sTh); }
static void bml_acc_add(bml_acc_t *A, long KP, const double *S, const double *H, const double *x) {
	long k, l;
	A->N++;
	for (k = 0; k < KP; k++) {
		A->sS[k] += S[k]; A->sTh[k] += x[k];
		for (l = 0; l < KP; l++) { A->sSS[k * KP + l] += S[k] * S[l]; A->sH[k * KP + l] += H[k * KP + l]; }
	}
}
/* information estimate = mean complete information - covariance of the scores; returns 1 if positive definite */
static int bml_info(const bml_acc_t *A, long KP, double *I, double *Hbar, double *Cov) {
	long k, l;
	double nn = (double)A->N;
	for (k = 0; k < KP; k++) for (l = 0; l < KP; l++) {
		double m = (A->sSS[k * KP + l] - A->sS[k] * A->sS[l] / nn) / (nn - 1.0);
		Cov[k * KP + l] = m;
		Hbar[k * KP + l] = A->sH[k * KP + l] / nn;
		I[k * KP + l] = Hbar[k * KP + l] - m;
	}
	{ double *L = (double *)malloc((size_t)(KP * KP) * sizeof(double)); int ok = bchol(I, L, KP); free(L); return ok; }
}

static ST_retcode ml_run(char *arg) {
	bctx_t B;
	const model_t *M;
	long n, K, nper, KP, pd, k, l, it, nend, n1, nsub, n2start, n3, nmhfix, sub, nb, i;
	unsigned long long seed;
	double mult, gain, t0, *th, *rho0, *S, *H, *I, *Hbar, *Cov, *x, *step, *thavg, *tconv, *cov;
	long nmpd[64];
	bml_acc_t A;
	bmoves_t mv;
	int okinfo, okfinal;
	char *tok;
	if (!batch_cur->ready) { SF_error("saom_ml: no resident model (BATCHSETUP first)\n"); return 198; }
	M = &batch_cur->M;
	n = M->n; K = M->nterms; nper = batch_cur->P; KP = K + nper;
	if (M->nbehterms > 0 || M->nbeh > 0 || M->has_start || M->nstruct > 0 || batch_cur->nrc > 0 || batch_cur->symtype != 0) {
		SF_error("saom_ml: the model is outside the maximum likelihood estimator's scope (one directed one-mode network, no behavior, structural or rate covariates)\n");
		return 198;
	}
	if (nper > 64 || K > 60) { SF_error("saom_ml: too many periods or effects\n"); return 198; }
	for (pd = 0; pd < nper; pd++) if (batch_cur->per[pd].hasmiss || batch_cur->per[pd].haspresent) { SF_error("saom_ml: missing data / composition change are not supported\n"); return 198; }
	tok = strtok(arg, " \t");
	if (!tok) return 198;
	nend = (long)atof(tok);
	n1 = next_long(); nsub = next_long(); n2start = next_long(); n3 = next_long(); nmhfix = next_long();
	seed = (unsigned long long)next_double(); mult = next_double(); gain = next_double();
	if (next_long() != K || next_long() != nper) { SF_error("saom_ml: dimension mismatch\n"); return 198; }
	th = (double *)calloc((size_t)KP, sizeof(double)); rho0 = (double *)calloc((size_t)nper, sizeof(double));
	for (k = 0; k < K; k++) th[k] = next_double();
	for (pd = 0; pd < nper; pd++) { rho0[pd] = next_double(); th[K + pd] = rho0[pd]; }
	if (wire_parse_error) { SF_error("saom_ml: argument string too short\n"); return 198; }
	if ((long)SF_nvars() < 3 + 3 + KP || (long)SF_nobs() < (KP > nend ? KP : nend)) { SF_error("saom_ml: frame too small\n"); return 198; }
	if (!bctx_open(&B, M, nend, seed, th, rho0, mult, nmhfix, nmpd)) { SF_error("saom_ml: out of memory\n"); return 198; }
	S = (double *)calloc((size_t)KP, sizeof(double)); H = (double *)calloc((size_t)(KP * KP), sizeof(double));
	I = (double *)calloc((size_t)(KP * KP), sizeof(double)); Hbar = (double *)calloc((size_t)(KP * KP), sizeof(double)); Cov = (double *)calloc((size_t)(KP * KP), sizeof(double));
	x = (double *)calloc((size_t)KP, sizeof(double)); step = (double *)calloc((size_t)KP, sizeof(double)); thavg = (double *)calloc((size_t)KP, sizeof(double));
	tconv = (double *)calloc((size_t)KP, sizeof(double)); cov = (double *)calloc((size_t)(KP * KP), sizeof(double));
	bml_acc_init(&A, KP);
	memset(&mv, 0, sizeof(mv));
	t0 = (double)clock() / (double)CLOCKS_PER_SEC;
#define ML_ITER() do { \
		for (pd = 0; pd < nper; pd++) for (nb = 0; nb < nmpd[pd]; nb++) bmh_step(&B, pd, &mv); \
		if (!bcache_build(&B)) { SF_error("saom_ml: out of memory\n"); return 198; } \
		bml_score(&B, th, S, H); \
	} while (0)
#define ML_SET(newth) do { \
		for (k = 0; k < K; k++) B.P.theta[k] = th[k]; \
		for (pd = 0; pd < nper; pd++) B.rho[pd] = th[K + pd]; \
		(void)bcache_ll(&B, th, 1); \
	} while (0)
	/* burn-in and phase 1 */
	for (it = 0; it < 20; it++) ML_ITER();
	for (it = 0; it < n1; it++) { ML_ITER(); bml_acc_add(&A, KP, S, H, th); }
	okinfo = bml_info(&A, KP, I, Hbar, Cov);
	if (!okinfo) { memcpy(I, Hbar, (size_t)(KP * KP) * sizeof(double)); for (k = 0; k < KP * KP; k++) I[k] *= 0.5; }
	/* phase 2 */
	{
		double len = (double)n2start;
		for (sub = 1; sub <= nsub; sub++) {
			long n2 = (long)(len + 0.5);
			double a = gain / pow(2.0, (double)(sub - 1));
			bml_acc_reset(&A, KP);
			for (it = 0; it < n2; it++) {
				ML_ITER();
				bml_acc_add(&A, KP, S, H, th);
				if (!bml_solve(I, KP, S, step)) for (k = 0; k < KP; k++) step[k] = S[k] / (I[k * KP + k] > 1e-8 ? I[k * KP + k] : 1.0);
				for (k = 0; k < KP; k++) {
					double d = a * step[k];
					if (d > 1.0) d = 1.0;
					if (d < -1.0) d = -1.0;
					if (k >= K && fabs(d) > 0.3 * th[k]) d = (d > 0 ? 0.3 : -0.3) * th[k];
					th[k] += d;
				}
				for (pd = 0; pd < nper; pd++) if (th[K + pd] < 0.01) th[K + pd] = 0.01;
				ML_SET();
			}
			{ /* the averaged values start the next subphase; the information is refreshed from this subphase */
				double nn = (double)A.N;
				for (k = 0; k < KP; k++) thavg[k] = A.sTh[k] / nn;
				if (bml_info(&A, KP, I, Hbar, Cov)) okinfo = 1;
				else { memcpy(I, Hbar, (size_t)(KP * KP) * sizeof(double)); for (k = 0; k < KP * KP; k++) I[k] *= 0.5; }
				for (k = 0; k < KP; k++) th[k] = thavg[k];
				ML_SET();
			}
			len *= 2.52;
		}
	}
	/* phase 3 */
	for (it = 0; it < 10; it++) ML_ITER();
	bml_acc_reset(&A, KP);
	for (it = 0; it < n3; it++) { ML_ITER(); bml_acc_add(&A, KP, S, H, th); }
	okfinal = bml_info(&A, KP, I, Hbar, Cov);
	for (k = 0; k < KP; k++) {
		double nn = (double)A.N, m = A.sS[k] / nn, sd = sqrt(Cov[k * KP + k]);
		tconv[k] = sd > 0.0 ? m / sd : 0.0;
	}
	if (okfinal) okfinal = bml_inverse(I, KP, cov);
	if (!okfinal) { /* not positive definite: fall back on the inverse of the complete-data information */
		if (!bml_inverse(Hbar, KP, cov)) for (k = 0; k < KP * KP; k++) cov[k] = SV_missval;
	}
	for (k = 0; k < KP; k++) {
		SF_vstore(4, (ST_int)(k + 1), th[k]);
		SF_vstore(5, (ST_int)(k + 1), tconv[k]);
		for (l = 0; l < KP; l++) SF_vstore((ST_int)(6 + l), (ST_int)(k + 1), cov[k * KP + l]);
		SF_vstore((ST_int)(6 + KP), (ST_int)(k + 1), A.sS[k] / (double)A.N);
	}
	SF_scal_save("__saom_ml_okinfo", (ST_double)okfinal);
	SF_scal_save("__saom_ml_secs", (double)clock() / (double)CLOCKS_PER_SEC - t0);
	SF_scal_save("__saom_ml_meanR", 0.0);
	{ double sr = 0.0; for (pd = 0; pd < nper; pd++) sr += (double)B.ch[pd].R; SF_scal_save("__saom_ml_meanR", sr); }
	(void)i;
	bml_acc_free(&A);
	bctx_close(&B);
	free(th); free(rho0); free(S); free(H); free(I); free(Hbar); free(Cov); free(x); free(step); free(thavg); free(tconv); free(cov);
	return 0;
}

#endif
