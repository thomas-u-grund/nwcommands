/* ===================================================================
   saom_bayes.c -- Bayesian estimation of a SAOM (nwsaom bayes).

   This file is #included by saom_sim.c (just before stata_call()), so it is
   compiled into the same plugin and uses its model_t / graph_t / effect
   evaluators directly. It is not a separate translation unit.

   Model (one directed one-mode network, constant rate per period, the
   objective function effects the plugin already evaluates). Between wave m
   and m+1 the data are augmented by the unobserved sequence of ministeps
   c_m = ((i_1,j_1), ..., (i_R,j_R)): ministep r is "actor i_r considers the
   alternative j_r" (j_r = i_r: no change, a "diagonal" ministep; otherwise the
   tie i_r->j_r is toggled). The chain starts at x(t_m) and must end at the
   observed x(t_{m+1}). Its density is
       pi(c | theta, rho) = Poisson(R; n rho) * prod_r (1/n) p_{i_r}(j_r | x^{r-1}; theta)
                          = exp(-n rho) rho^R / R! * prod_r p_{i_r}(j_r | x^{r-1}; theta),
   p_i(j | x; theta) = exp(f_i(x^{(ij)})) / sum_h exp(f_i(x^{(ih)})) (the
   multinomial logit of the SAOM, including the diagonal alternative with
   utility 0). This is the data-augmentation (ML) chain of Snijders, Koskinen &
   Schweinberger (2010), Koskinen & Snijders (2007).

   Sampler (one iteration):
     1. Metropolis-Hastings moves on every period's chain, each a reversible move
        whose proposal probabilities are counted exactly (so the target is the
        exact conditional distribution of the chain):
          - insert / delete a diagonal ministep,
          - insert / delete a pair of identical ministeps (i,j),(i,j) (two
            toggles of the same tie; the end point is unchanged) at positions
            at most W apart,
          - swap two adjacent ministeps.
     2. theta: random-walk Metropolis (adaptive proposal covariance during the
        warm-up) given the chains; the log-likelihood given the chains is
        sum_r log p_{i_r}(j_r|x^{r-1};theta), evaluated from a cache of the
        change statistics of every ministep (linear in theta).
     3. rho_m: Gibbs step from the Gamma(a + R_m, b + n) full conditional
        (Gamma(a,b) prior on the rate of each period; a=1,b=0 flat).
   =================================================================== */

#ifndef SAOM_BAYES_C_INCLUDED
#define SAOM_BAYES_C_INCLUDED

typedef struct {
	long R, cap;
	int *ei, *ej;
	double *lp;			/* log p of each ministep under the current theta */
} bchain_t;

typedef struct {
	const model_t *M;
	long n, K, nper, W;
	simparams_t P;
	double *tt, *c3, *chg, *u;
	unsigned char *ijx;
	double *attrs[MAXATTR + 2];
	rng_t rng;
	bchain_t *ch;
	double *rho;
	graph_t *pg;			/* a persistent graph per period at position ppos (state before ministep ppos) */
	long *ppos;
	int *pvalid;
	double *cache;			/* change statistics of every ministep: ((off[pd] + r) * n + (h-1)) * K + k */
	size_t cachecap;
	long *coff;
	/* work buffers */
	int *tei, *tej;
	double *tlp;
	long tcap;
	long *pl;			/* list of deletable pairs (r1, r2) */
	long plcap;
} bctx_t;

static double b_unif(bctx_t *B) {
	double u = rng_unif(&B->rng);
	return u > 0.0 ? u : 1e-300;
}
static double b_norm(bctx_t *B) {
	double u1 = b_unif(B), u2 = rng_unif(&B->rng);
	return sqrt(-2.0 * log(u1)) * cos(6.283185307179586 * u2);
}
static double b_gamma(bctx_t *B, double a) {		/* Gamma(a, 1), Marsaglia-Tsang */
	double d, c, x, v, u;
	if (a < 1.0) return b_gamma(B, a + 1.0) * pow(b_unif(B), 1.0 / a);
	d = a - 1.0 / 3.0;
	c = 1.0 / sqrt(9.0 * d);
	for (;;) {
		do { x = b_norm(B); v = 1.0 + c * x; } while (v <= 0.0);
		v = v * v * v;
		u = b_unif(B);
		if (u < 1.0 - 0.0331 * x * x * x * x) return d * v;
		if (log(u) < 0.5 * x * x + d * (1.0 - v + log(v))) return d * v;
	}
}
static long b_randint(bctx_t *B, long m) {		/* 0 .. m-1 */
	long v = (long)(rng_unif(&B->rng) * (double)m);
	return v >= m ? m - 1 : v;
}

static void bchain_ensure(bchain_t *c, long need) {
	if (need <= c->cap) return;
	c->cap = c->cap ? c->cap * 2 : 64;
	if (c->cap < need) c->cap = need;
	c->ei = (int *)realloc(c->ei, (size_t)c->cap * sizeof(int));
	c->ej = (int *)realloc(c->ej, (size_t)c->cap * sizeof(int));
	c->lp = (double *)realloc(c->lp, (size_t)c->cap * sizeof(double));
}
static void bwork_ensure(bctx_t *B, long need) {
	if (need <= B->tcap) return;
	B->tcap = B->tcap ? B->tcap * 2 : 128;
	if (B->tcap < need) B->tcap = need;
	B->tei = (int *)realloc(B->tei, (size_t)B->tcap * sizeof(int));
	B->tej = (int *)realloc(B->tej, (size_t)B->tcap * sizeof(int));
	B->tlp = (double *)realloc(B->tlp, (size_t)B->tcap * sizeof(double));
}

static void bset_period(bctx_t *B, long pd) {
	const period_t *PD = &batch_cur->per[pd];
	const model_t *M = B->M;
	long k;
	int jc;
	for (k = 0; k < M->nattr; k++) B->attrs[k] = PD->xattr[k] ? PD->xattr[k] : M->attrs[k];
	B->attrs[M->nattr] = NULL;
	B->attrs[M->nattr + 1] = NULL;
	for (jc = 0; jc < 8; jc++) { saom_tl_cov[jc] = PD->bcov[jc]; saom_tl_bdy[jc] = PD->bdy[jc]; }
	saom_tl_beh0 = NULL;
	saom_tl_behscale = 1.0;
	saom_tl_behvar = 0.0;
	saom_tl_g0 = NULL;
}

/* log of the normalising sum over all alternatives (the diagonal has utility 0); fills B->u, B->chg for the actor */
static double beval_actor(bctx_t *B, graph_t *g, long actor) {
	const model_t *M = B->M;
	long n = B->n, j;
	double maxu, s;
	if (M->need_transtrip) { memset(B->tt, 0, (size_t)(n + 1) * sizeof(double)); batch_otp_plus_osp(g, actor, B->tt); }
	if (M->need_cycle3) { memset(B->c3, 0, (size_t)(n + 1) * sizeof(double)); batch_otp_reverse(g, actor, B->c3); }
	maxu = eval_network_alternatives(M, &B->P, g, B->attrs, actor, NULL, B->tt, B->c3, B->chg, B->u, B->ijx);
	s = exp(-maxu);
	for (j = 1; j <= n; j++) if (j != actor) s += exp(B->u[j] - maxu);
	return maxu + log(s);
}
static double bstep_lp(bctx_t *B, graph_t *g, long i, long j) {
	double lz = beval_actor(B, g, i);
	return (j == i ? 0.0 : B->u[j]) - lz;
}

static void bbuild_graph(bctx_t *B, long pd, graph_t *g) {
	const period_t *PD = &batch_cur->per[pd];
	long r;
	graph_init(g, B->n, B->M->need_adj, PD->nties);
	for (r = 0; r < PD->nties; r++) toggle(g, PD->ti[r], PD->tj[r]);
}
/* the persistent graph of period pd, moved to the state before ministep pos */
static graph_t *bgoto(bctx_t *B, long pd, long pos) {
	bchain_t *c = &B->ch[pd];
	graph_t *g = &B->pg[pd];
	long r;
	bset_period(B, pd);
	if (!B->pvalid[pd] || (pos < B->ppos[pd] && B->ppos[pd] - pos > pos)) {
		if (B->pvalid[pd]) graph_free(g);
		bbuild_graph(B, pd, g);
		B->ppos[pd] = 0;
		B->pvalid[pd] = 1;
	}
	if (pos > B->ppos[pd]) { for (r = B->ppos[pd]; r < pos; r++) if (c->ei[r] != c->ej[r]) toggle(g, c->ei[r], c->ej[r]); }
	else { for (r = pos; r < B->ppos[pd]; r++) if (c->ei[r] != c->ej[r]) toggle(g, c->ei[r], c->ej[r]); }
	B->ppos[pd] = pos;
	return g;
}
static void binvalidate(bctx_t *B, long pd) {
	if (B->pvalid[pd]) { graph_free(&B->pg[pd]); B->pvalid[pd] = 0; }
}

/* ---- chain moves --------------------------------------------------------------- */
typedef struct { double tried[4], acc[4]; } bmoves_t;

static void bmove_diag(bctx_t *B, long pd, bmoves_t *mv) {
	bchain_t *c = &B->ch[pd];
	long R = c->R, n = B->n, D = 0, r;
	double rho = B->rho[pd];
	for (r = 0; r < R; r++) if (c->ei[r] == c->ej[r]) D++;
	if (b_unif(B) < 0.5) {
		long g = b_randint(B, R + 1), i = 1 + b_randint(B, n);
		graph_t *gr = bgoto(B, pd, g);
		double lp = bstep_lp(B, gr, i, i);
		double la = lp + log(rho) + log((double)n) - log((double)(D + 1));
		mv->tried[0] += 1.0;
		if (log(b_unif(B)) < la) {
			bchain_ensure(c, R + 1);
			memmove(c->ei + g + 1, c->ei + g, (size_t)(R - g) * sizeof(int));
			memmove(c->ej + g + 1, c->ej + g, (size_t)(R - g) * sizeof(int));
			memmove(c->lp + g + 1, c->lp + g, (size_t)(R - g) * sizeof(double));
			c->ei[g] = (int)i; c->ej[g] = (int)i; c->lp[g] = lp;
			c->R = R + 1;
			B->ppos[pd] = (B->ppos[pd] > g) ? B->ppos[pd] + 1 : B->ppos[pd];	/* diagonal: no state change; the position index shifts */
			mv->acc[0] += 1.0;
		}
	}
	else if (D > 0) {
		long t = b_randint(B, D), q = -1;
		double la;
		for (r = 0; r < R; r++) if (c->ei[r] == c->ej[r]) { if (t-- == 0) { q = r; break; } }
		la = -c->lp[q] - log(rho) - log((double)n) + log((double)D);
		mv->tried[0] += 1.0;
		if (log(b_unif(B)) < la) {
			memmove(c->ei + q, c->ei + q + 1, (size_t)(R - q - 1) * sizeof(int));
			memmove(c->ej + q, c->ej + q + 1, (size_t)(R - q - 1) * sizeof(int));
			memmove(c->lp + q, c->lp + q + 1, (size_t)(R - q - 1) * sizeof(double));
			c->R = R - 1;
			if (B->ppos[pd] > q) B->ppos[pd] -= 1;
			mv->acc[0] += 1.0;
		}
	}
}

/* the number of pairs of identical non-diagonal ministeps at most W positions apart */
static long bcount_pairs(bctx_t *B, const int *ei, const int *ej, long R, int collect) {
	long r1, r2, cnt = 0, W = B->W;
	for (r1 = 0; r1 < R; r1++) {
		long hi = r1 + W < R - 1 ? r1 + W : R - 1;
		if (ei[r1] == ej[r1]) continue;
		for (r2 = r1 + 1; r2 <= hi; r2++) {
			if (ei[r2] == ei[r1] && ej[r2] == ej[r1]) {
				if (collect) {
					if (2 * (cnt + 1) > B->plcap) { B->plcap = B->plcap ? B->plcap * 2 : 256; if (B->plcap < 2 * (cnt + 1)) B->plcap = 2 * (cnt + 1); B->pl = (long *)realloc(B->pl, (size_t)B->plcap * sizeof(long)); }
					B->pl[2 * cnt] = r1; B->pl[2 * cnt + 1] = r2;
				}
				cnt++;
			}
		}
	}
	return cnt;
}

static void bmove_pair(bctx_t *B, long pd, bmoves_t *mv) {
	bchain_t *c = &B->ch[pd];
	long R = c->R, n = B->n, W = B->W, r;
	double rho = B->rho[pd];
	if (b_unif(B) < 0.5) {
		long g1 = b_randint(B, R + 1), d = b_randint(B, W), g2 = g1 + d, i, j, Kp;
		graph_t *gr;
		double lpa, lpb, dl = 0.0, la;
		if (g2 > R) return;
		mv->tried[1] += 1.0;
		i = 1 + b_randint(B, n);
		j = 1 + b_randint(B, n - 1); if (j >= i) j++;
		bwork_ensure(B, R + 2);
		gr = bgoto(B, pd, g1);
		lpa = bstep_lp(B, gr, i, j);
		toggle(gr, i, j);
		for (r = g1; r < g2; r++) {
			double l = bstep_lp(B, gr, c->ei[r], c->ej[r]);
			B->tlp[r - g1] = l;
			dl += l - c->lp[r];
			if (c->ei[r] != c->ej[r]) toggle(gr, c->ei[r], c->ej[r]);
		}
		lpb = bstep_lp(B, gr, i, j);
		toggle(gr, i, j);			/* the graph is now the original state before ministep g2 */
		B->ppos[pd] = g2;
		dl += lpa + lpb;
		/* proposed chain */
		memcpy(B->tei, c->ei, (size_t)g1 * sizeof(int)); memcpy(B->tej, c->ej, (size_t)g1 * sizeof(int));
		B->tei[g1] = (int)i; B->tej[g1] = (int)j;
		memcpy(B->tei + g1 + 1, c->ei + g1, (size_t)(g2 - g1) * sizeof(int)); memcpy(B->tej + g1 + 1, c->ej + g1, (size_t)(g2 - g1) * sizeof(int));
		B->tei[g2 + 1] = (int)i; B->tej[g2 + 1] = (int)j;
		memcpy(B->tei + g2 + 2, c->ei + g2, (size_t)(R - g2) * sizeof(int)); memcpy(B->tej + g2 + 2, c->ej + g2, (size_t)(R - g2) * sizeof(int));
		Kp = bcount_pairs(B, B->tei, B->tej, R + 2, 0);
		la = dl + 2.0 * log(rho) - log((double)(R + 2)) + log((double)W) + log((double)n * (double)(n - 1)) - log((double)Kp);
		if (log(b_unif(B)) < la) {
			bchain_ensure(c, R + 2);
			/* lp: [0,g1) , lpa, new[g1..g2) , lpb, [g2,R) */
			memmove(c->lp + g2 + 2, c->lp + g2, (size_t)(R - g2) * sizeof(double));
			memmove(c->lp + g1 + 1, c->lp + g1, (size_t)(g2 - g1) * sizeof(double));	/* placeholder shift, overwritten below */
			for (r = g1; r < g2; r++) c->lp[g1 + 1 + (r - g1)] = B->tlp[r - g1];
			c->lp[g1] = lpa;
			c->lp[g2 + 1] = lpb;
			memcpy(c->ei, B->tei, (size_t)(R + 2) * sizeof(int));
			memcpy(c->ej, B->tej, (size_t)(R + 2) * sizeof(int));
			c->R = R + 2;
			binvalidate(B, pd);
			mv->acc[1] += 1.0;
		}
	}
	else {
		long K, t, r1, r2;
		double dl = 0.0, la;
		graph_t *gr;
		if (R < 2) return;
		K = bcount_pairs(B, c->ei, c->ej, R, 1);
		if (K == 0) return;
		mv->tried[1] += 1.0;
		t = b_randint(B, K);
		r1 = B->pl[2 * t]; r2 = B->pl[2 * t + 1];
		bwork_ensure(B, R);
		gr = bgoto(B, pd, r1);
		dl = -(c->lp[r1] + c->lp[r2]);
		for (r = r1 + 1; r < r2; r++) {
			double l = bstep_lp(B, gr, c->ei[r], c->ej[r]);
			B->tlp[r - r1 - 1] = l;
			dl += l - c->lp[r];
			if (c->ei[r] != c->ej[r]) toggle(gr, c->ei[r], c->ej[r]);
		}
		toggle(gr, c->ei[r1], c->ej[r1]);	/* graph = state before ministep r2 (original chain) */
		B->ppos[pd] = r2;
		la = dl - 2.0 * log(rho) + log((double)R) - log((double)W) - log((double)n * (double)(n - 1)) + log((double)K);
		if (log(b_unif(B)) < la) {
			for (r = r1 + 1; r < r2; r++) c->lp[r - 1] = B->tlp[r - r1 - 1];
			memmove(c->ei + r1, c->ei + r1 + 1, (size_t)(r2 - r1 - 1) * sizeof(int));
			memmove(c->ej + r1, c->ej + r1 + 1, (size_t)(r2 - r1 - 1) * sizeof(int));
			memmove(c->ei + r2 - 1, c->ei + r2 + 1, (size_t)(R - r2 - 1) * sizeof(int));
			memmove(c->ej + r2 - 1, c->ej + r2 + 1, (size_t)(R - r2 - 1) * sizeof(int));
			memmove(c->lp + r2 - 1, c->lp + r2 + 1, (size_t)(R - r2 - 1) * sizeof(double));
			c->R = R - 2;
			binvalidate(B, pd);
			mv->acc[1] += 1.0;
		}
	}
}

static void bmove_swap(bctx_t *B, long pd, bmoves_t *mv) {
	bchain_t *c = &B->ch[pd];
	long R = c->R, r;
	graph_t *gr;
	double la, l1, l2;
	int a, b, a2, b2;
	if (R < 2) return;
	r = b_randint(B, R - 1);
	a = c->ei[r]; b = c->ej[r]; a2 = c->ei[r + 1]; b2 = c->ej[r + 1];
	if (a == a2 && b == b2) return;
	mv->tried[2] += 1.0;
	gr = bgoto(B, pd, r);
	l1 = bstep_lp(B, gr, a2, b2);
	if (a2 != b2) toggle(gr, a2, b2);
	l2 = bstep_lp(B, gr, a, b);
	if (a != b) toggle(gr, a, b);
	B->ppos[pd] = r + 2;			/* both ministeps applied: the state before ministep r+2 */
	la = l1 + l2 - c->lp[r] - c->lp[r + 1];
	if (log(b_unif(B)) < la) {
		c->ei[r] = a2; c->ej[r] = b2; c->ei[r + 1] = a; c->ej[r + 1] = b;
		c->lp[r] = l1; c->lp[r + 1] = l2;
		mv->acc[2] += 1.0;
		/* the state before ministep r+1 changed, the one before r+2 did not; the persistent graph is at r+2: still valid */
	}
}

/* ---- theta: cache and log-likelihood ------------------------------------------- */
static int bcache_build(bctx_t *B) {
	long pd, r, h, k, n = B->n, K = B->K, stride = n + 1, tot = 0;
	size_t need;
	for (pd = 0; pd < B->nper; pd++) { B->coff[pd] = tot; tot += B->ch[pd].R; }
	need = (size_t)tot * (size_t)n * (size_t)K;
	if (need > B->cachecap) {
		double *nc = (double *)realloc(B->cache, need * sizeof(double) * 1);
		if (!nc) return 0;
		B->cache = nc; B->cachecap = need;
	}
	for (pd = 0; pd < B->nper; pd++) {
		bchain_t *c = &B->ch[pd];
		graph_t *g = bgoto(B, pd, 0);
		for (r = 0; r < c->R; r++) {
			long a = c->ei[r];
			double *dst = B->cache + ((size_t)(B->coff[pd] + r) * (size_t)n) * (size_t)K;
			(void)beval_actor(B, g, a);
			for (h = 1; h <= n; h++) for (k = 0; k < K; k++) dst[(h - 1) * K + k] = (h == a) ? 0.0 : B->chg[k * stride + h];
			if (c->ei[r] != c->ej[r]) toggle(g, c->ei[r], c->ej[r]);
		}
		B->ppos[pd] = c->R;
	}
	return 1;
}
static double bcache_ll(bctx_t *B, const double *th, int storelp) {
	long pd, r, h, k, n = B->n, K = B->K;
	double ll = 0.0;
	for (pd = 0; pd < B->nper; pd++) {
		bchain_t *c = &B->ch[pd];
		for (r = 0; r < c->R; r++) {
			const double *src = B->cache + ((size_t)(B->coff[pd] + r) * (size_t)n) * (size_t)K;
			double mx = -1e300, s = 0.0, uj = 0.0, lp;
			for (h = 0; h < n; h++) {
				double u = 0.0;
				for (k = 0; k < K; k++) u += th[k] * src[h * K + k];
				B->u[h + 1] = u;
				if (u > mx) mx = u;
			}
			for (h = 1; h <= n; h++) s += exp(B->u[h] - mx);
			uj = B->u[c->ej[r]];
			lp = uj - (mx + log(s));
			if (storelp) c->lp[r] = lp;
			ll += lp;
		}
	}
	return ll;
}

static int bchol(const double *A, double *L, long K) {
	long i, j, k;
	for (i = 0; i < K; i++) for (j = 0; j < K; j++) L[i * K + j] = 0.0;
	for (i = 0; i < K; i++) {
		for (j = 0; j <= i; j++) {
			double s = A[i * K + j];
			for (k = 0; k < j; k++) s -= L[i * K + k] * L[j * K + k];
			if (i == j) { if (s <= 1e-14) return 0; L[i * K + i] = sqrt(s); }
			else L[i * K + j] = s / L[j * K + j];
		}
	}
	return 1;
}

/* ---- the driver ------------------------------------------------------------------- */
static ST_retcode bayes_run(char *arg) {
	bctx_t B;
	const model_t *M;
	long n, K, nper, pd, i, k, it, nend, nprewarm, nwarm, nmain, nrunmh, nimprove, nmhfix, ntheta, W, nsave = 0, nout;
	double mult, targetmh;
	unsigned long long seed;
	double *th, *th_new, *pmean, *psd, *pshape, *prate, *Sig, *L, *z, *mu, *Cv, *rho0, *thprop, *draws;
	double accT = 0.0, trT = 0.0, llcur, lpri;
	bmoves_t mv;
	long **ei_end, **ej_end, *nend_pd;
	double t0;
	char *tok;
	int chol_ok;
	long wcount = 0;

	if (!batch_cur->ready) { SF_error("saom_bayes: no resident model (BATCHSETUP first)\n"); return 198; }
	M = &batch_cur->M;
	memset(&B, 0, sizeof(B));
	B.M = M; B.n = n = M->n; B.K = K = M->nterms; B.nper = nper = batch_cur->P;
	if (M->nbehterms > 0 || M->nbeh > 0 || M->has_start || M->nstruct > 0 || batch_cur->nrc > 0 || batch_cur->symtype != 0) {
		SF_error("saom_bayes: the model is outside the Bayesian sampler's scope (one directed one-mode network, no behavior, structural or rate covariates)\n");
		return 198;
	}
	for (pd = 0; pd < nper; pd++) if (batch_cur->per[pd].hasmiss || batch_cur->per[pd].haspresent) { SF_error("saom_bayes: missing data / composition change are not supported\n"); return 198; }
	tok = strtok(arg, " \t");
	if (!tok) return 198;
	nend = (long)atof(tok);
	nprewarm = next_long(); nwarm = next_long(); nmain = next_long(); nrunmh = next_long(); nimprove = next_long(); nmhfix = next_long(); ntheta = next_long(); W = next_long();
	seed = (unsigned long long)next_double(); mult = next_double(); targetmh = next_double();
	if (next_long() != K || next_long() != nper) { SF_error("saom_bayes: dimension mismatch\n"); return 198; }
	th = (double *)calloc((size_t)K, sizeof(double)); th_new = (double *)calloc((size_t)K, sizeof(double)); thprop = (double *)calloc((size_t)K, sizeof(double));
	pmean = (double *)calloc((size_t)K, sizeof(double)); psd = (double *)calloc((size_t)K, sizeof(double));
	pshape = (double *)calloc((size_t)nper, sizeof(double)); prate = (double *)calloc((size_t)nper, sizeof(double)); rho0 = (double *)calloc((size_t)nper, sizeof(double));
	Sig = (double *)calloc((size_t)(K * K), sizeof(double)); L = (double *)calloc((size_t)(K * K), sizeof(double));
	z = (double *)calloc((size_t)K, sizeof(double)); mu = (double *)calloc((size_t)K, sizeof(double)); Cv = (double *)calloc((size_t)(K * K), sizeof(double));
	for (k = 0; k < K; k++) th[k] = next_double();
	for (k = 0; k < K; k++) pmean[k] = next_double();
	for (k = 0; k < K; k++) psd[k] = next_double();
	for (pd = 0; pd < nper; pd++) rho0[pd] = next_double();
	for (pd = 0; pd < nper; pd++) pshape[pd] = next_double();
	for (pd = 0; pd < nper; pd++) prate[pd] = next_double();
	for (k = 0; k < K * K; k++) Sig[k] = next_double();
	if (wire_parse_error) { SF_error("saom_bayes: argument string too short\n"); return 198; }
	if (W < 1) W = 1;
	if (nrunmh < 1) nrunmh = 1;
	if (nimprove < 0) nimprove = 0;
	if (ntheta < 0) ntheta = 0;
	nout = K + nper + 2;
	if ((long)SF_nvars() < 3 + nout || (long)SF_nobs() < (nmain > nend ? nmain : nend)) { SF_error("saom_bayes: frame too small\n"); return 198; }
	B.W = W;
	rng_seed(&B.rng, seed);
	memset(&B.P, 0, sizeof(B.P));
	B.tt = M->need_transtrip ? (double *)calloc((size_t)(n + 1), sizeof(double)) : NULL;
	B.c3 = M->need_cycle3 ? (double *)calloc((size_t)(n + 1), sizeof(double)) : NULL;
	B.chg = (double *)calloc((size_t)(n + 1) * (size_t)(K > 0 ? K : 1), sizeof(double));
	B.u = (double *)calloc((size_t)(n + 1), sizeof(double));
	B.ijx = (unsigned char *)malloc((size_t)(n + 1));
	B.ch = (bchain_t *)calloc((size_t)nper, sizeof(bchain_t));
	B.rho = (double *)calloc((size_t)nper, sizeof(double));
	B.pg = (graph_t *)calloc((size_t)nper, sizeof(graph_t));
	B.ppos = (long *)calloc((size_t)nper, sizeof(long));
	B.pvalid = (int *)calloc((size_t)nper, sizeof(int));
	B.coff = (long *)calloc((size_t)nper, sizeof(long));
	for (k = 0; k < K; k++) B.P.theta[k] = th[k];
	for (pd = 0; pd < nper; pd++) B.rho[pd] = rho0[pd];
	nend_pd = (long *)calloc((size_t)nper, sizeof(long));
	ei_end = (long **)calloc((size_t)nper, sizeof(long *)); ej_end = (long **)calloc((size_t)nper, sizeof(long *));
	for (i = 1; i <= nend; i++) {
		ST_double a, b, c;
		long p;
		SF_vdata(1, (ST_int)i, &a); SF_vdata(2, (ST_int)i, &b); SF_vdata(3, (ST_int)i, &c);
		p = (long)a - 1;
		if (p < 0 || p >= nper) continue;
		ei_end[p] = (long *)realloc(ei_end[p], (size_t)(nend_pd[p] + 1) * sizeof(long));
		ej_end[p] = (long *)realloc(ej_end[p], (size_t)(nend_pd[p] + 1) * sizeof(long));
		ei_end[p][nend_pd[p]] = (long)b; ej_end[p][nend_pd[p]] = (long)c; nend_pd[p]++;
	}
	/* initial chains: the differences between the waves in random order */
	for (pd = 0; pd < nper; pd++) {
		const period_t *PD = &batch_cur->per[pd];
		graph_t gs, ge;
		bchain_t *c = &B.ch[pd];
		long r, m;
		graph_init(&gs, n, 1, PD->nties); graph_init(&ge, n, 1, nend_pd[pd]);
		for (r = 0; r < PD->nties; r++) toggle(&gs, PD->ti[r], PD->tj[r]);
		for (r = 0; r < nend_pd[pd]; r++) toggle(&ge, ei_end[pd][r], ej_end[pd][r]);
		bchain_ensure(c, PD->nties + nend_pd[pd] + 16);
		c->R = 0;
		for (r = 0; r < PD->nties; r++) if (!has_edge(&ge, PD->ti[r], PD->tj[r])) { c->ei[c->R] = (int)PD->ti[r]; c->ej[c->R] = (int)PD->tj[r]; c->R++; }
		for (r = 0; r < nend_pd[pd]; r++) if (!has_edge(&gs, ei_end[pd][r], ej_end[pd][r])) { c->ei[c->R] = (int)ei_end[pd][r]; c->ej[c->R] = (int)ej_end[pd][r]; c->R++; }
		for (r = c->R - 1; r > 0; r--) {
			m = b_randint(&B, r + 1);
			{ int t1 = c->ei[r], t2 = c->ej[r]; c->ei[r] = c->ei[m]; c->ej[r] = c->ej[m]; c->ei[m] = t1; c->ej[m] = t2; }
		}
		graph_free(&gs); graph_free(&ge);
		bwork_ensure(&B, c->R + 16);
	}
	t0 = (double)clock() / (double)CLOCKS_PER_SEC;
	/* initial lp's */
	if (!bcache_build(&B)) { SF_error("saom_bayes: out of memory\n"); return 198; }
	llcur = bcache_ll(&B, th, 1);
	draws = NULL;
	{
		/* adaptive proposal: Sig is the starting covariance of the random walk (already scaled by the caller) */
		double *mean_run = (double *)calloc((size_t)K, sizeof(double)), *cov_run = (double *)calloc((size_t)(K * K), sizeof(double));
		long nrun = 0;
		double nacc_chain[4] = {0, 0, 0, 0}, ntr_chain[4] = {0, 0, 0, 0}, sumR = 0.0;
		chol_ok = bchol(Sig, L, K);
		if (!chol_ok) { for (k = 0; k < K * K; k++) Sig[k] = (k % (K + 1) == 0) ? 0.01 : 0.0; bchol(Sig, L, K); }
		memset(&mv, 0, sizeof(mv));
		long totit = nprewarm + nwarm + nmain + nimprove, batch, nrunning = 0;
		double lscale = 0.0;		/* log of the scale factor of the proposal covariance (tuned towards the target acceptance) */
		long nmpd[64];
		if (nper > 64) { SF_error("saom_bayes: too many periods\n"); return 198; }
		for (pd = 0; pd < nper; pd++) {
			/* the number of Metropolis-Hastings steps on the chain is fixed (mult times the observed distance, as RSiena's ML), never state dependent */
			long dist = B.ch[pd].R;
			nmpd[pd] = nmhfix > 0 ? nmhfix : (long)floor(mult * (double)dist);
			if (nmpd[pd] > 100) nmpd[pd] = (long)(floor((double)nmpd[pd] / 100.0 + 0.5) * 100.0);
			if (nmpd[pd] < 10) nmpd[pd] = 10;
		}
		for (it = 1; it <= totit; it++) {
			int phase = (it <= nprewarm) ? 0 : (it <= nprewarm + nwarm ? 1 : (it <= nprewarm + nwarm + nimprove ? 2 : 3));
			/* phase 0 pre-warm, 1 warm-up, 2 re-tuning of the proposal after the warm-up, 3 main run (draws saved) */
			long nb = (phase == 2) ? 1 : nrunmh;
			for (batch = 0; batch < nb; batch++) {
				/* 1. Metropolis-Hastings steps on the chains */
				for (pd = 0; pd < nper; pd++) {
					long q;
					for (q = 0; q < nmpd[pd]; q++) {
						double u = rng_unif(&B.rng);
						if (u < 0.3) bmove_diag(&B, pd, &mv);
						else if (u < 0.7) bmove_pair(&B, pd, &mv);
						else bmove_swap(&B, pd, &mv);
					}
				}
				/* 2. the effects given the chains */
				if (!bcache_build(&B)) { SF_error("saom_bayes: out of memory\n"); return 198; }
				llcur = bcache_ll(&B, th, 0);
				lpri = 0.0;
				for (k = 0; k < K; k++) if (psd[k] > 0.0) lpri += -0.5 * (th[k] - pmean[k]) * (th[k] - pmean[k]) / (psd[k] * psd[k]);
				for (i = 0; i < ntheta; i++) {
					double llnew, lprin = 0.0, la, sc = exp(0.5 * lscale);
					for (k = 0; k < K; k++) z[k] = b_norm(&B);
					for (k = 0; k < K; k++) { double s2 = 0.0; long q; for (q = 0; q <= k; q++) s2 += L[k * K + q] * z[q]; thprop[k] = th[k] + sc * s2; }
					for (k = 0; k < K; k++) if (psd[k] > 0.0) lprin += -0.5 * (thprop[k] - pmean[k]) * (thprop[k] - pmean[k]) / (psd[k] * psd[k]);
					llnew = bcache_ll(&B, thprop, 0);
					la = llnew + lprin - llcur - lpri;
					if (phase <= 2 && targetmh > 0.0) {
						/* Robbins-Monro tuning of the scale factor towards the target acceptance probability */
						double pa = la >= 0.0 ? 1.0 : exp(la);
						nrunning++;
						lscale += 2.0 * (pa - targetmh) / sqrt((double)nrunning + 10.0);
						if (lscale > 6.0) lscale = 6.0;
						if (lscale < -12.0) lscale = -12.0;
					}
					if (phase == 3) trT += 1.0;
					if (log(b_unif(&B)) < la) {
						memcpy(th, thprop, (size_t)K * sizeof(double));
						llcur = llnew; lpri = lprin; if (phase == 3) accT += 1.0;
					}
				}
				for (k = 0; k < K; k++) B.P.theta[k] = th[k];
				(void)bcache_ll(&B, th, 1);
				/* 3. the rates (full conditional given the chain lengths) */
				for (pd = 0; pd < nper; pd++) if (pshape[pd] >= 0.0) B.rho[pd] = b_gamma(&B, pshape[pd] + (double)B.ch[pd].R) / (prate[pd] + (double)n);
			}
			if (phase == 1) {
				long a, b2;
				nrun++;
				for (a = 0; a < K; a++) {
					double d = th[a] - mean_run[a];
					mean_run[a] += d / (double)nrun;
					for (b2 = 0; b2 <= a; b2++) cov_run[a * K + b2] += d * (th[b2] - mean_run[b2]);
				}
			}
			if (it == nprewarm + nwarm && nrun >= 20 && K > 0) {
				/* proposal covariance from the warm-up draws (robustified as multiSiena's covtrob()) */
				long a, b2;
				double f = 2.38 * 2.38 / (double)K;
				for (a = 0; a < K; a++) for (b2 = 0; b2 <= a; b2++) {
					double v = cov_run[a * K + b2] / (double)(nrun - 1);
					Sig[a * K + b2] = v; Sig[b2 * K + a] = v;
				}
				for (a = 0; a < K; a++) Sig[a * K + a] *= 1.05;
				for (a = 0; a < K; a++) for (b2 = 0; b2 < K; b2++) Sig[a * K + b2] *= f;
				if (bchol(Sig, L, K)) { wcount++; lscale = 0.0; nrunning = 0; }
			}
			if (phase == 3) {
				double sr = 0.0;
				nsave++;
				for (k = 0; k < K; k++) SF_vstore((ST_int)(4 + k), (ST_int)nsave, th[k]);
				for (pd = 0; pd < nper; pd++) { SF_vstore((ST_int)(4 + K + pd), (ST_int)nsave, B.rho[pd]); sr += (double)B.ch[pd].R; }
				SF_vstore((ST_int)(4 + K + nper), (ST_int)nsave, sr);
				SF_vstore((ST_int)(4 + K + nper + 1), (ST_int)nsave, llcur);
				sumR += sr;
			}
			else if (it == nprewarm + nwarm + nimprove) memset(&mv, 0, sizeof(mv));
		}
		for (k = 0; k < 4; k++) { nacc_chain[k] = mv.acc[k]; ntr_chain[k] = mv.tried[k]; }
		SF_scal_save("__saom_bayes_nsave", (ST_double)nsave);
		SF_scal_save("__saom_bayes_acc_theta", trT > 0 ? accT / trT : 0.0);
		SF_scal_save("__saom_bayes_acc_diag", ntr_chain[0] > 0 ? nacc_chain[0] / ntr_chain[0] : 0.0);
		SF_scal_save("__saom_bayes_acc_pair", ntr_chain[1] > 0 ? nacc_chain[1] / ntr_chain[1] : 0.0);
		SF_scal_save("__saom_bayes_acc_swap", ntr_chain[2] > 0 ? nacc_chain[2] / ntr_chain[2] : 0.0);
		SF_scal_save("__saom_bayes_meanR", nsave > 0 ? sumR / (double)nsave : 0.0);
		SF_scal_save("__saom_bayes_adapt", (ST_double)wcount);
		SF_scal_save("__saom_bayes_secs", (double)clock() / (double)CLOCKS_PER_SEC - t0);
		free(mean_run); free(cov_run);
	}
	for (pd = 0; pd < nper; pd++) { binvalidate(&B, pd); free(B.ch[pd].ei); free(B.ch[pd].ej); free(B.ch[pd].lp); free(ei_end[pd]); free(ej_end[pd]); }
	free(B.ch); free(B.rho); free(B.pg); free(B.ppos); free(B.pvalid); free(B.coff); free(B.cache); free(B.tei); free(B.tej); free(B.tlp); free(B.pl);
	free(B.tt); free(B.c3); free(B.chg); free(B.u); free(B.ijx);
	free(th); free(th_new); free(thprop); free(pmean); free(psd); free(pshape); free(prate); free(rho0); free(Sig); free(L); free(z); free(mu); free(Cv);
	free(ei_end); free(ej_end); free(nend_pd);
	(void)draws;
	return 0;
}

#endif
