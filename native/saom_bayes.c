/* ===================================================================
   saom_bayes.c -- the chain machinery shared by the Bayesian sampler (nwsaom bayes) and the maximum likelihood
   estimator (nwsaom, ml; saom_ml.c). #included by saom_sim.c (just before stata_call()), so it is compiled into the same
   plugin and uses its model_t / graph_t / effect evaluators directly.

   Model: one directed one-mode network and optionally one co-evolving behavior, a constant rate per period and variable,
   the objective-function effects the plugin evaluates. Between two waves the unobserved sequence of ministeps
   c = ((k_1,i_1,j_1),...,(k_R,i_R,j_R)) has the density (Snijders, Koskinen & Schweinberger 2010, eq. 15-16; for two
   dependent variables the rate of the variable of every ministep enters)
       pi(c | theta, rho) = exp(-n sum_w rho_w) / R! * prod_r rho_{w_r} p_{w_r,i_r}(j_r | state before ministep r; theta).
   A ministep is a network ministep (k=0: actor i considers the tie to j; j = i: no change, "diagonal") or a behavior
   ministep (k=1: actor i changes its behavior by d = j in {-1,0,+1}; d = 0: diagonal).

   The Metropolis-Hastings steps on the chain are RSiena's maximum-likelihood chain moves (insert / cancel a diagonal
   ministep, permute, insert-permute and delete-permute of a consecutive cancelling pair; probabilities 0.05, 0.05, 0.2, 0.3, 0.3,
   the rest are the missing-data moves of RSiena, which do nothing without missing data), written from the description in the
   Siena algorithms document (chapters 9, 10); the acceptance probabilities were derived from the proposal densities
   and checked against exact enumeration. The Bayesian schedule follows multiSiena's multi_siena for one group.
   =================================================================== */

#ifndef SAOM_BAYES_C_INCLUDED
#define SAOM_BAYES_C_INCLUDED

typedef struct {
	long R, cap;
	int *ei, *ej;
	signed char *ek;		/* 0 network ministep, 1 behavior ministep */
	double *lp;			/* log p of the choice of each ministep under the current effects (without the rate) */
	size_t *off;			/* offset of the change statistics of each ministep in the cache */
} bchain_t;

typedef struct {
	graph_t g;
	double *bv, *behc;		/* the behavior (1..n) and the centred behavior; NULL without a behavior */
} bstate_t;

typedef struct {
	const model_t *M;
	long n, K, Kb, KT, nper, nvar;	/* network effects, behavior effects, their sum, periods, dependent variables (1 or 2) */
	simparams_t P;
	double *tt, *c3, *chg, *u;
	unsigned char *ijx;
	double chgD[MAXBEHTERMS], chgU[MAXBEHTERMS];
	int hasD, hasU;
	double *attrs[MAXATTR + 2];
	rng_t rng;
	bchain_t *ch;
	double *rho;			/* rate of variable w in period pd: rho[w * nper + pd] */
	double *c0;			/* current permutation length per period (RSiena: 20, bounded by 2 and 40, adaptive) */
	int adaptc0;
	bstate_t *st;			/* a persistent state per period at position ppos (the state before ministep ppos) */
	long *ppos;
	int *pvalid;
	double *cache;			/* change statistics of every ministep */
	size_t cachecap;
	int *tei, *tej;			/* work buffers */
	signed char *tek;
	double *tlp;
	long tcap;
	long *hk;
	int *hv, *nxt;
	long hcap;
	long *pl;
	long plcap;
	double *zend;			/* behavior at the end of each period, zend[pd * n + (i-1)] */
	double geo;			/* msb of an inserted pair: truncated geometric offset with this ratio (0: uniform, RSiena) */
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
	c->ek = (signed char *)realloc(c->ek, (size_t)c->cap * sizeof(signed char));
	c->lp = (double *)realloc(c->lp, (size_t)c->cap * sizeof(double));
	c->off = (size_t *)realloc(c->off, (size_t)c->cap * sizeof(size_t));
}
static void bwork_ensure(bctx_t *B, long need) {
	if (need <= B->tcap) return;
	B->tcap = B->tcap ? B->tcap * 2 : 128;
	if (B->tcap < need) B->tcap = need;
	B->tei = (int *)realloc(B->tei, (size_t)B->tcap * sizeof(int));
	B->tej = (int *)realloc(B->tej, (size_t)B->tcap * sizeof(int));
	B->tek = (signed char *)realloc(B->tek, (size_t)B->tcap * sizeof(signed char));
	B->tlp = (double *)realloc(B->tlp, (size_t)B->tcap * sizeof(double));
	B->nxt = (int *)realloc(B->nxt, (size_t)B->tcap * sizeof(int));
}

static int b_isdiag(int k, long i, long j) { return k == 0 ? (i == j) : (j == 0); }
static double bsumrho(const bctx_t *B, long pd) { double s = B->rho[pd]; if (B->nvar > 1) s += B->rho[B->nper + pd]; return s; }

/* ---- evaluation of the choice probabilities ------------------------------------------ */
static void bset_period(bctx_t *B, long pd) {
	const period_t *PD = &batch_cur->per[pd];
	const model_t *M = B->M;
	long k;
	int jc;
	for (k = 0; k < M->nattr; k++) B->attrs[k] = PD->xattr[k] ? PD->xattr[k] : M->attrs[k];
	B->attrs[M->nattr] = NULL;
	B->attrs[M->nattr + 1] = NULL;
	for (jc = 0; jc < 8; jc++) { saom_tl_cov[jc] = PD->bcov[jc]; saom_tl_bdy[jc] = PD->bdy[jc]; }
	saom_tl_beh0 = PD->beh0;
	saom_tl_behscale = (M->behrange > 0.0) ? 1.0 / M->behrange : 1.0;
	saom_tl_behvar = M->behVariance;
	saom_tl_g0 = NULL;
}

/* log of the normalising sum over all alternatives of a network ministep of `actor' (the diagonal has utility 0); fills B->u, B->chg */
static double beval_net(bctx_t *B, bstate_t *st, long actor) {
	const model_t *M = B->M;
	long n = B->n, j;
	double maxu, s;
	if (st->bv) { B->attrs[M->nattr] = st->bv; B->attrs[M->nattr + 1] = st->behc; }
	if (M->need_transtrip) { memset(B->tt, 0, (size_t)(n + 1) * sizeof(double)); batch_otp_plus_osp(&st->g, actor, B->tt); }
	if (M->need_cycle3) { memset(B->c3, 0, (size_t)(n + 1) * sizeof(double)); batch_otp_reverse(&st->g, actor, B->c3); }
	maxu = eval_network_alternatives(M, &B->P, &st->g, B->attrs, actor, NULL, B->tt, B->c3, B->chg, B->u, B->ijx);
	s = exp(-maxu);
	for (j = 1; j <= n; j++) if (j != actor) s += exp(B->u[j] - maxu);
	return maxu + log(s);
}
/* the behavior alternatives of `actor': fills B->chgD/chgU/hasD/hasU and returns log(1 + exp(uD) + exp(uU)) (available alternatives), uD/uU in *uD, *uU */
static double beval_beh(bctx_t *B, bstate_t *st, long actor, double *uD, double *uU) {
	const model_t *M = B->M;
	double cur = st->bv[actor], maxu = 0.0, s;
	long k;
	B->hasD = (cur > M->behminval); B->hasU = (cur < M->behmaxval);
	*uD = 0.0; *uU = 0.0;
	if (B->hasD) for (k = 0; k < B->Kb; k++) { B->chgD[k] = saom_beh_change_term(&st->g, st->bv, M->behtermcodes[k], M->behOverallMean, M->behrange, M->behSimMean, actor, -1.0); *uD += B->P.thetaBeh[k] * B->chgD[k]; }
	else for (k = 0; k < B->Kb; k++) B->chgD[k] = 0.0;
	if (B->hasU) for (k = 0; k < B->Kb; k++) { B->chgU[k] = saom_beh_change_term(&st->g, st->bv, M->behtermcodes[k], M->behOverallMean, M->behrange, M->behSimMean, actor, 1.0); *uU += B->P.thetaBeh[k] * B->chgU[k]; }
	else for (k = 0; k < B->Kb; k++) B->chgU[k] = 0.0;
	if (B->hasD && *uD > maxu) maxu = *uD;
	if (B->hasU && *uU > maxu) maxu = *uU;
	s = exp(-maxu);
	if (B->hasD) s += exp(*uD - maxu);
	if (B->hasU) s += exp(*uU - maxu);
	return maxu + log(s);
}
static int bstep_valid(bctx_t *B, const bstate_t *st, int k, long i, long j) {
	if (k == 0 || j == 0) return 1;
	return j < 0 ? (st->bv[i] > B->M->behminval) : (st->bv[i] < B->M->behmaxval);
}
/* log probability of the choice of a ministep (the step must be valid) */
static double bstep_lp(bctx_t *B, bstate_t *st, int k, long i, long j) {
	if (k == 0) {
		double lz = beval_net(B, st, i);
		return (j == i ? 0.0 : B->u[j]) - lz;
	}
	else {
		double uD, uU, lz = beval_beh(B, st, i, &uD, &uU);
		return (j == 0 ? 0.0 : (j < 0 ? uD : uU)) - lz;
	}
}

/* ---- the persistent state of a period -------------------------------------------------- */
static void bapply(bctx_t *B, bstate_t *st, int k, long i, long j) {		/* toggling / adding is its own inverse for the network; sign via j for the behavior */
	if (k == 0) { if (i != j) toggle(&st->g, i, j); }
	else if (j != 0) { st->bv[i] += (double)j; st->behc[i] = st->bv[i] - B->M->behOverallMean; }
}
static void bunapply(bctx_t *B, bstate_t *st, int k, long i, long j) { if (k == 0) bapply(B, st, k, i, j); else bapply(B, st, k, i, -j); }

static void bbuild_state(bctx_t *B, long pd, bstate_t *st) {
	const period_t *PD = &batch_cur->per[pd];
	long r, n = B->n;
	graph_init(&st->g, n, B->M->need_adj, PD->nties);
	for (r = 0; r < PD->nties; r++) toggle(&st->g, PD->ti[r], PD->tj[r]);
	if (B->Kb > 0) {
		st->bv = (double *)malloc((size_t)(n + 1) * sizeof(double));
		st->behc = (double *)calloc((size_t)(n + 1), sizeof(double));
		memcpy(st->bv, PD->beh0, (size_t)(n + 1) * sizeof(double));
		for (r = 1; r <= n; r++) st->behc[r] = st->bv[r] - B->M->behOverallMean;
	}
	else { st->bv = NULL; st->behc = NULL; }
}
static void bfree_state(bstate_t *st) { graph_free(&st->g); free(st->bv); free(st->behc); st->bv = st->behc = NULL; }
/* the persistent state of period pd, moved to the state before ministep pos */
static bstate_t *bgoto(bctx_t *B, long pd, long pos) {
	bchain_t *c = &B->ch[pd];
	bstate_t *st = &B->st[pd];
	long r;
	bset_period(B, pd);
	if (!B->pvalid[pd] || (pos < B->ppos[pd] && B->ppos[pd] - pos > pos)) {
		if (B->pvalid[pd]) bfree_state(st);
		bbuild_state(B, pd, st);
		B->ppos[pd] = 0;
		B->pvalid[pd] = 1;
	}
	if (pos > B->ppos[pd]) { for (r = B->ppos[pd]; r < pos; r++) bapply(B, st, c->ek[r], c->ei[r], c->ej[r]); }
	else { for (r = B->ppos[pd] - 1; r >= pos; r--) bunapply(B, st, c->ek[r], c->ei[r], c->ej[r]); }
	B->ppos[pd] = pos;
	return st;
}
static void binvalidate(bctx_t *B, long pd) {
	if (B->pvalid[pd]) { bfree_state(&B->st[pd]); B->pvalid[pd] = 0; }
}

/* ---- chain moves --------------------------------------------------------------- */
typedef struct { double tried[5], acc[5]; } bmoves_t;	/* 0 diagonal insert, 1 diagonal cancel, 2 permute, 3 insert-permute, 4 delete-permute */

/* the option of a ministep (for the consecutive cancelling pairs and the permuted blocks): a network tie (i,j), the behavior of an actor; -1 for a network diagonal */
static long bkey(const bctx_t *B, int k, long i, long j) {
	if (k == 0) return (i == j) ? -1 : i * (B->n + 1) + j;
	return (long)(B->n + 1) * (B->n + 1) + i;
}

/* the next ministep of the same option for every ministep (-1: none); returns the number of consecutive cancelling pairs: a non-diagonal
   ministep whose next ministep of the option exists, is not the next ministep of the chain and (behavior) changes the behavior the other way */
static long bccp(bctx_t *B, const signed char *ek, const int *ei, const int *ej, long R, int collect) {
	long cap = 16, r, cnt = 0;
	while (cap < 2 * (R + 1)) cap *= 2;
	if (cap > B->hcap) {
		B->hcap = cap;
		B->hk = (long *)realloc(B->hk, (size_t)cap * sizeof(long));
		B->hv = (int *)realloc(B->hv, (size_t)cap * sizeof(int));
	}
	{ long q; for (q = 0; q < cap; q++) B->hk[q] = -1; }
	if (collect && 2 * (R + 1) > B->plcap) { B->plcap = 2 * (R + 1) + 64; B->pl = (long *)realloc(B->pl, (size_t)B->plcap * sizeof(long)); }
	for (r = R - 1; r >= 0; r--) {
		long key = bkey(B, ek[r], ei[r], ej[r]), h;
		B->nxt[r] = -1;
		if (key < 0) continue;
		h = (key * 2654435761L) & (cap - 1);
		while (B->hk[h] != -1 && B->hk[h] != key) h = (h + 1) & (cap - 1);
		if (B->hk[h] == key) B->nxt[r] = B->hv[h];
		B->hk[h] = key; B->hv[h] = (int)r;
		if (!b_isdiag(ek[r], ei[r], ej[r]) && B->nxt[r] >= 0 && B->nxt[r] != r + 1 && (ek[r] == 0 || ej[r] == -ej[B->nxt[r]])) {
			if (collect) { B->pl[2 * cnt] = r; B->pl[2 * cnt + 1] = B->nxt[r]; }
			cnt++;
		}
	}
	return cnt;
}

/* RSiena's rule for the length of a permuted block: if two ministeps of the same option occur in the block, only the ministeps before the first
   repeated one are permuted */
static long btrunc(const bctx_t *B, const signed char *ek, const int *ei, const int *ej, long start, long len, long c) {
	long a, b;
	for (b = 1; b < len; b++) {
		long kb = bkey(B, ek[start + b], ei[start + b], ej[start + b]);
		if (kb < 0) continue;
		for (a = 0; a < b; a++) if (bkey(B, ek[start + a], ei[start + a], ej[start + a]) == kb) return (c < b - 1) ? c : b - 1;
	}
	return c;
}
static void bshuffle(bctx_t *B, int *a, long c) {		/* random permutation of 0..c-1 into a */
	long i;
	for (i = 0; i < c; i++) a[i] = (int)i;
	for (i = c - 1; i > 0; i--) { long j = b_randint(B, i + 1); int t = a[i]; a[i] = a[j]; a[j] = t; }
}
static void bc0update(bctx_t *B, long pd, long cused, int accept) {
	double c0 = B->c0[pd];
	if (!B->adaptc0 || cused != (long)c0) return;
	c0 += accept ? 0.5 : -0.5;
	if (c0 > 40.0) c0 = 40.0;
	if (c0 < 2.0) c0 = 2.0;
	B->c0[pd] = c0;
}
/* offset o in 1..CL of the second ministep of an inserted pair: uniform (RSiena) or truncated geometric; *lw = -log(probability of o) */
static long bpickoffset(bctx_t *B, long CL, double *lw) {
	double g = B->geo;
	if (g <= 0.0 || g >= 1.0 || CL <= 1) { *lw = log((double)CL); return 1 + b_randint(B, CL); }
	{
		double gc = pow(g, (double)CL), u = b_unif(B), W = (1.0 - gc) / (1.0 - g);
		long o = 1 + (long)floor(log(1.0 - u * (1.0 - gc)) / log(g));
		if (o > CL) o = CL;
		if (o < 1) o = 1;
		*lw = log(W) - (double)(o - 1) * log(g);
		return o;
	}
}
static double blwoffset(const bctx_t *B, long CL, long o) {		/* -log(probability of offset o) */
	double g = B->geo;
	if (g <= 0.0 || g >= 1.0 || CL <= 1) return log((double)CL);
	return log((1.0 - pow(g, (double)CL)) / (1.0 - g)) - (double)(o - 1) * log(g);
}
static int bpickvar(bctx_t *B, long pd) {		/* the dependent variable of a proposed ministep, in proportion to the rates */
	if (B->nvar == 1) return 0;
	return (rng_unif(&B->rng) * bsumrho(B, pd) < B->rho[pd]) ? 0 : 1;
}

static void bmove_diag(bctx_t *B, long pd, bmoves_t *mv, int insert) {
	bchain_t *c = &B->ch[pd];
	long R = c->R, n = B->n, D = 0, r;
	double srho = bsumrho(B, pd);
	for (r = 0; r < R; r++) if (b_isdiag(c->ek[r], c->ei[r], c->ej[r])) D++;
	if (insert) {
		long g = b_randint(B, R + 1), i = 1 + b_randint(B, n);
		int k = bpickvar(B, pd);
		bstate_t *st = bgoto(B, pd, g);
		double lp = bstep_lp(B, st, k, i, k == 0 ? i : 0);
		double la = lp + log((double)n) + log(srho) - log((double)(D + 1));
		mv->tried[0] += 1.0;
		if (log(b_unif(B)) < la) {
			bchain_ensure(c, R + 1);
			memmove(c->ei + g + 1, c->ei + g, (size_t)(R - g) * sizeof(int));
			memmove(c->ej + g + 1, c->ej + g, (size_t)(R - g) * sizeof(int));
			memmove(c->ek + g + 1, c->ek + g, (size_t)(R - g) * sizeof(signed char));
			memmove(c->lp + g + 1, c->lp + g, (size_t)(R - g) * sizeof(double));
			c->ei[g] = (int)i; c->ej[g] = (int)(k == 0 ? i : 0); c->ek[g] = (signed char)k; c->lp[g] = lp;
			c->R = R + 1;
			mv->acc[0] += 1.0;
		}
	}
	else if (D > 0) {
		long t = b_randint(B, D), q = -1;
		double la;
		for (r = 0; r < R; r++) if (b_isdiag(c->ek[r], c->ei[r], c->ej[r])) { if (t-- == 0) { q = r; break; } }
		la = -c->lp[q] - log((double)n) - log(srho) + log((double)D);
		mv->tried[1] += 1.0;
		if (log(b_unif(B)) < la) {
			memmove(c->ei + q, c->ei + q + 1, (size_t)(R - q - 1) * sizeof(int));
			memmove(c->ej + q, c->ej + q + 1, (size_t)(R - q - 1) * sizeof(int));
			memmove(c->ek + q, c->ek + q + 1, (size_t)(R - q - 1) * sizeof(signed char));
			memmove(c->lp + q, c->lp + q + 1, (size_t)(R - q - 1) * sizeof(double));
			c->R = R - 1;
			if (B->ppos[pd] > q) B->ppos[pd] -= 1;
			mv->acc[1] += 1.0;
		}
	}
}

/* permute c consecutive ministeps starting at a random one (RSiena's MH Permute) */
static void bmove_permute(bctx_t *B, long pd, bmoves_t *mv) {
	bchain_t *c = &B->ch[pd];
	long R = c->R, msa, cc, s;
	long c0i = (long)B->c0[pd];
	int perm[64];
	bstate_t *st;
	double dl = 0.0;
	if (R < 2) return;
	msa = b_randint(B, R);
	cc = R - msa;
	if (cc > c0i) cc = c0i;
	if (cc > 40) cc = 40;
	if (cc < 2) return;
	bshuffle(B, perm, cc);
	bwork_ensure(B, R + 4);
	st = bgoto(B, pd, msa);
	for (s = 0; s < cc; s++) {
		long src = msa + perm[s];
		int k = c->ek[src], a = c->ei[src], b = c->ej[src];
		double l;
		if (!bstep_valid(B, st, k, a, b)) { binvalidate(B, pd); return; }
		l = bstep_lp(B, st, k, a, b);
		B->tlp[s] = l; B->tei[s] = a; B->tej[s] = b; B->tek[s] = (signed char)k;
		dl += l - c->lp[msa + s];
		bapply(B, st, k, a, b);
	}
	B->ppos[pd] = msa + cc;			/* the same set of ministeps has been applied */
	mv->tried[2] += 1.0;
	if (log(b_unif(B)) < dl) {
		for (s = 0; s < cc; s++) { c->ei[msa + s] = B->tei[s]; c->ej[msa + s] = B->tej[s]; c->ek[msa + s] = B->tek[s]; c->lp[msa + s] = B->tlp[s]; }
		mv->acc[2] += 1.0;
		bc0update(B, pd, cc, 1);
	}
	else bc0update(B, pd, cc, 0);
}

/* insert a pair of ministeps of one option before a random ministep msa and before msb (msb after msa, no ministep of the option in between),
   and permute the ministeps after msa (RSiena's MH InsPermute) */
static void bmove_insperm(bctx_t *B, long pd, bmoves_t *mv) {
	bchain_t *c = &B->ch[pd];
	long R = c->R, n = B->n, msa, i0, j0 = 0, msd, CL, msb, TL, cc, rl, s, h, Kp;
	long c0i = (long)B->c0[pd];
	int perm[64], k0;
	bstate_t *st;
	double lz, uu, acc, lpX1, lpX2, dl, la, rho = 0.0, srho = bsumrho(B, pd), lwoff = 0.0;
	if (R < 1 || n < 2) return;
	msa = b_randint(B, R);
	k0 = bpickvar(B, pd);
	i0 = 1 + b_randint(B, n);
	if (k0 == c->ek[msa] && i0 == c->ei[msa]) return;
	rho = B->rho[k0 * B->nper + pd];
	st = bgoto(B, pd, msa);
	uu = b_unif(B); acc = 0.0;
	if (k0 == 0) {
		lz = beval_net(B, st, i0);
		for (h = 1; h <= n; h++) {
			double p = (h == i0) ? exp(-lz) : exp(B->u[h] - lz);
			acc += p;
			if (uu <= acc) { j0 = h; break; }
		}
		if (j0 == 0 || j0 == i0) return;			/* diagonal (or rounding): no proposal */
		lpX1 = B->u[j0] - lz;
	}
	else {
		double uD, uU, p0;
		lz = beval_beh(B, st, i0, &uD, &uU);
		p0 = exp(-lz);
		if (uu <= p0) return;
		if (B->hasD && uu <= p0 + exp(uD - lz)) { j0 = -1; lpX1 = uD - lz; }
		else if (B->hasU) { j0 = 1; lpX1 = uU - lz; }
		else return;
	}
	/* msd: the first ministep after msa of the option (or the end of the chain) */
	msd = R;
	for (s = msa + 1; s < R; s++) if (bkey(B, c->ek[s], c->ei[s], c->ej[s]) == bkey(B, k0, i0, j0)) { msd = s; break; }
	CL = msd - msa;
	{ double lwo; msb = msa + bpickoffset(B, CL, &lwo); lwoff = lwo; }
	TL = msb - msa;
	cc = (TL < c0i) ? TL : c0i;
	if (cc > 40) cc = 40;
	rl = (TL <= c0i) ? TL : cc + 1;
	cc = btrunc(B, c->ek, c->ei, c->ej, msa, rl, cc);
	if (cc >= 2) bshuffle(B, perm, cc);
	else cc = (cc < 1) ? 0 : 1;
	bwork_ensure(B, R + 4);
	/* the proposed chain */
	memcpy(B->tei, c->ei, (size_t)msa * sizeof(int)); memcpy(B->tej, c->ej, (size_t)msa * sizeof(int)); memcpy(B->tek, c->ek, (size_t)msa * sizeof(signed char));
	B->tei[msa] = (int)i0; B->tej[msa] = (int)j0; B->tek[msa] = (signed char)k0;
	for (s = 0; s < TL; s++) {
		long src = (s < cc && cc >= 2) ? perm[s] : s;
		B->tei[msa + 1 + s] = c->ei[msa + src]; B->tej[msa + 1 + s] = c->ej[msa + src]; B->tek[msa + 1 + s] = c->ek[msa + src];
	}
	B->tei[msb + 1] = (int)i0; B->tej[msb + 1] = (int)(k0 == 0 ? j0 : -j0); B->tek[msb + 1] = (signed char)k0;
	memcpy(B->tei + msb + 2, c->ei + msb, (size_t)(R - msb) * sizeof(int)); memcpy(B->tej + msb + 2, c->ej + msb, (size_t)(R - msb) * sizeof(int));
	memcpy(B->tek + msb + 2, c->ek + msb, (size_t)(R - msb) * sizeof(signed char));
	/* the new log probabilities of the changed block */
	B->tlp[0] = lpX1;
	bapply(B, st, k0, i0, j0);
	dl = 0.0;
	for (s = 0; s < TL; s++) {
		int a = B->tei[msa + 1 + s], b = B->tej[msa + 1 + s], k = B->tek[msa + 1 + s];
		double l;
		if (!bstep_valid(B, st, k, a, b)) { binvalidate(B, pd); return; }
		l = bstep_lp(B, st, k, a, b);
		B->tlp[1 + s] = l;
		dl += l - c->lp[msa + s];
		bapply(B, st, k, a, b);
	}
	{
		long j2 = (k0 == 0 ? j0 : -j0);
		if (!bstep_valid(B, st, k0, i0, j2)) { binvalidate(B, pd); return; }
		lpX2 = bstep_lp(B, st, k0, i0, j2);
	}
	B->tlp[TL + 1] = lpX2;
	dl += lpX2;
	/* back to the state before ministep msb of the original chain: undo the first inserted ministep (the others have been applied in the original chain's order) */
	bunapply(B, st, k0, i0, j0);
	B->ppos[pd] = msb;
	Kp = bccp(B, B->tek, B->tei, B->tej, R + 2, 0);
	if (Kp < 1) Kp = 1;
	la = dl + log(rho) + log(srho) + log((double)n) + log((double)R) + lwoff - log((double)(R + 1)) - log((double)(R + 2)) - log((double)Kp);
	mv->tried[3] += 1.0;
	if (log(b_unif(B)) < la) {
		bchain_ensure(c, R + 2);
		memmove(c->lp + msb + 2, c->lp + msb, (size_t)(R - msb) * sizeof(double));
		memcpy(c->lp + msa, B->tlp, (size_t)(TL + 2) * sizeof(double));
		memcpy(c->ei, B->tei, (size_t)(R + 2) * sizeof(int));
		memcpy(c->ej, B->tej, (size_t)(R + 2) * sizeof(int));
		memcpy(c->ek, B->tek, (size_t)(R + 2) * sizeof(signed char));
		c->R = R + 2;
		binvalidate(B, pd);
		mv->acc[3] += 1.0;
		bc0update(B, pd, (TL < c0i ? TL : c0i), 1);
	}
	else bc0update(B, pd, (TL < c0i ? TL : c0i), 0);
}

/* delete a consecutive cancelling pair msa, msb and permute the ministeps in between (RSiena's MH DelPermute) */
static void bmove_delperm(bctx_t *B, long pd, bmoves_t *mv) {
	bchain_t *c = &B->ch[pd];
	long R = c->R, n = B->n, K, t, msa, msb, m, cc, rl, s, msd, CL, Rc, i0, j0;
	long c0i = (long)B->c0[pd];
	int perm[64], k0;
	bstate_t *st;
	double dl, la, rho, srho = bsumrho(B, pd);
	if (R < 3) return;
	bwork_ensure(B, R + 4);
	K = bccp(B, c->ek, c->ei, c->ej, R, 1);
	if (K == 0) return;
	t = b_randint(B, K);
	msa = B->pl[2 * t]; msb = B->pl[2 * t + 1];
	k0 = c->ek[msa]; i0 = c->ei[msa]; j0 = c->ej[msa];
	rho = B->rho[k0 * B->nper + pd];
	m = msb - msa - 1;
	cc = (m < c0i) ? m : c0i;
	if (cc > 40) cc = 40;
	rl = (m <= c0i) ? m : cc + 1;
	cc = btrunc(B, c->ek, c->ei, c->ej, msa + 1, rl, cc);
	if (cc >= 2) bshuffle(B, perm, cc);
	else cc = (cc < 1) ? 0 : 1;
	for (s = 0; s < m; s++) {
		long src = (s < cc && cc >= 2) ? perm[s] : s;
		B->tei[s] = c->ei[msa + 1 + src]; B->tej[s] = c->ej[msa + 1 + src]; B->tek[s] = c->ek[msa + 1 + src];
	}
	if (B->tek[0] == k0 && B->tei[0] == i0) return;			/* the inverse proposal (insertion) would not be possible */
	st = bgoto(B, pd, msa);
	dl = 0.0;
	for (s = 0; s < m; s++) {
		double l;
		if (!bstep_valid(B, st, B->tek[s], B->tei[s], B->tej[s])) { binvalidate(B, pd); return; }
		l = bstep_lp(B, st, B->tek[s], B->tei[s], B->tej[s]);
		B->tlp[s] = l;
		dl += l - c->lp[msa + 1 + s];
		bapply(B, st, B->tek[s], B->tei[s], B->tej[s]);
	}
	bapply(B, st, k0, i0, j0);			/* the state before ministep msb of the current chain */
	B->ppos[pd] = msb;
	/* ChoiceLength of the inverse proposal: the first ministep of the option after msb */
	msd = R;
	{ long key0 = bkey(B, k0, i0, j0); for (s = msb + 1; s < R; s++) if (bkey(B, c->ek[s], c->ei[s], c->ej[s]) == key0) { msd = s; break; } }
	CL = (msd - 2) - msa;
	Rc = R - 2;
	if (CL < 1) CL = 1;
	/* the inverse insertion has Delta = lp(X2) - dl */
	la = -(c->lp[msb] - dl) - log(rho) - log(srho) - log((double)n) - log((double)Rc) - blwoffset(B, CL, m) + log((double)(Rc + 1)) + log((double)(Rc + 2)) + log((double)K);
	mv->tried[4] += 1.0;
	if (log(b_unif(B)) < la) {
		for (s = 0; s < m; s++) { c->ei[msa + s] = B->tei[s]; c->ej[msa + s] = B->tej[s]; c->ek[msa + s] = B->tek[s]; c->lp[msa + s] = B->tlp[s]; }
		memmove(c->ei + msb - 1, c->ei + msb + 1, (size_t)(R - msb - 1) * sizeof(int));
		memmove(c->ej + msb - 1, c->ej + msb + 1, (size_t)(R - msb - 1) * sizeof(int));
		memmove(c->ek + msb - 1, c->ek + msb + 1, (size_t)(R - msb - 1) * sizeof(signed char));
		memmove(c->lp + msb - 1, c->lp + msb + 1, (size_t)(R - msb - 1) * sizeof(double));
		c->R = R - 2;
		binvalidate(B, pd);
		mv->acc[4] += 1.0;
		bc0update(B, pd, (m < c0i ? m : c0i), 1);
	}
	else bc0update(B, pd, (m < c0i ? m : c0i), 0);
}

/* one Metropolis-Hastings step on the chain of period pd: RSiena's mixture (0.05 insert diagonal, 0.05 cancel diagonal, 0.2 permute,
   0.3 insert-permute, 0.3 delete-permute, 0.1 moves for missing data = nothing here) */
static void bmh_step(bctx_t *B, long pd, bmoves_t *mv) {
	double u = rng_unif(&B->rng);
	if (u < 0.05) bmove_diag(B, pd, mv, 1);
	else if (u < 0.10) bmove_diag(B, pd, mv, 0);
	else if (u < 0.30) bmove_permute(B, pd, mv);
	else if (u < 0.60) bmove_insperm(B, pd, mv);
	else if (u < 0.90) bmove_delperm(B, pd, mv);
}


/* ---- the effects: cache of the change statistics and the log-likelihood given the chains ---------- */
/* network ministep: n alternatives x K statistics (the diagonal 0); behavior ministep: down (Kb), up (Kb), available down, available up */
static int bcache_build(bctx_t *B) {
	long pd, r, h, k, n = B->n, K = B->K, Kb = B->Kb, stride = n + 1;
	size_t tot = 0, pos;
	for (pd = 0; pd < B->nper; pd++) {
		bchain_t *c = &B->ch[pd];
		for (r = 0; r < c->R; r++) { c->off[r] = tot; tot += (c->ek[r] == 0) ? (size_t)n * (size_t)K : (size_t)(2 * Kb + 2); }
	}
	if (tot > B->cachecap) {
		double *nc = (double *)realloc(B->cache, tot * sizeof(double));
		if (!nc) return 0;
		B->cache = nc; B->cachecap = tot;
	}
	(void)pos;
	for (pd = 0; pd < B->nper; pd++) {
		bchain_t *c = &B->ch[pd];
		bstate_t *st = bgoto(B, pd, 0);
		for (r = 0; r < c->R; r++) {
			long a = c->ei[r];
			double *dst = B->cache + c->off[r];
			if (c->ek[r] == 0) {
				(void)beval_net(B, st, a);
				for (h = 1; h <= n; h++) for (k = 0; k < K; k++) dst[(h - 1) * K + k] = (h == a) ? 0.0 : B->chg[k * stride + h];
			}
			else {
				double uD, uU;
				(void)beval_beh(B, st, a, &uD, &uU);
				for (k = 0; k < Kb; k++) { dst[k] = B->chgD[k]; dst[Kb + k] = B->chgU[k]; }
				dst[2 * Kb] = B->hasD; dst[2 * Kb + 1] = B->hasU;
			}
			bapply(B, st, c->ek[r], c->ei[r], c->ej[r]);
		}
		B->ppos[pd] = c->R;
	}
	return 1;
}
/* log-likelihood of the chains given the effects th (K network effects, then Kb behavior effects) */
static double bcache_ll(bctx_t *B, const double *th, int storelp) {
	long pd, r, h, k, n = B->n, K = B->K, Kb = B->Kb;
	double ll = 0.0;
	const double *thB = th + K;
	for (pd = 0; pd < B->nper; pd++) {
		bchain_t *c = &B->ch[pd];
		for (r = 0; r < c->R; r++) {
			const double *src = B->cache + c->off[r];
			double lp;
			if (c->ek[r] == 0) {
				double mx = -1e300, s = 0.0, uj;
				for (h = 0; h < n; h++) {
					double u = 0.0;
					for (k = 0; k < K; k++) u += th[k] * src[h * K + k];
					B->u[h + 1] = u;
					if (u > mx) mx = u;
				}
				for (h = 1; h <= n; h++) s += exp(B->u[h] - mx);
				uj = B->u[c->ej[r]];
				lp = uj - (mx + log(s));
			}
			else {
				double uD = 0.0, uU = 0.0, mx = 0.0, s, uj;
				int hd = src[2 * Kb] != 0.0, hu = src[2 * Kb + 1] != 0.0;
				for (k = 0; k < Kb; k++) { uD += thB[k] * src[k]; uU += thB[k] * src[Kb + k]; }
				if (hd && uD > mx) mx = uD;
				if (hu && uU > mx) mx = uU;
				s = exp(-mx);
				if (hd) s += exp(uD - mx);
				if (hu) s += exp(uU - mx);
				uj = (c->ej[r] == 0) ? 0.0 : (c->ej[r] < 0 ? uD : uU);
				lp = uj - (mx + log(s));
			}
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

/* ---- common setup: scratch buffers, the minimal chains, the steps per batch, pre-burn-in ------------------- */
/* The end ties are in the current frame's columns 1-3 (period, i, j; rows 1..nend), the end behavior in columns 4-6 (period, actor, value; rows 1..nbend). */
static int bctx_open(bctx_t *B, const model_t *M, long nend, long nbend, unsigned long long seed, const double *th0, const double *rho0, double mult, long nmhfix, long *nmpd) {
	long n = M->n, K = M->nterms, Kb = (M->nbehterms > 0) ? M->nbehterms : 0, nper = batch_cur->P, pd, i, k;
	long **ei_end, **ej_end, *nend_pd;
	bmoves_t mv;
	memset(B, 0, sizeof(*B));
	B->M = M; B->n = n; B->K = K; B->Kb = Kb; B->KT = K + Kb; B->nper = nper; B->nvar = (Kb > 0) ? 2 : 1;
	rng_seed(&B->rng, seed);
	B->tt = M->need_transtrip ? (double *)calloc((size_t)(n + 1), sizeof(double)) : NULL;
	B->c3 = M->need_cycle3 ? (double *)calloc((size_t)(n + 1), sizeof(double)) : NULL;
	B->chg = (double *)calloc((size_t)(n + 1) * (size_t)(K > 0 ? K : 1), sizeof(double));
	B->u = (double *)calloc((size_t)(n + 1), sizeof(double));
	B->ijx = (unsigned char *)malloc((size_t)(n + 1));
	B->ch = (bchain_t *)calloc((size_t)nper, sizeof(bchain_t));
	B->rho = (double *)calloc((size_t)(nper * B->nvar), sizeof(double));
	B->c0 = (double *)calloc((size_t)nper, sizeof(double));
	B->st = (bstate_t *)calloc((size_t)nper, sizeof(bstate_t));
	B->ppos = (long *)calloc((size_t)nper, sizeof(long));
	B->pvalid = (int *)calloc((size_t)nper, sizeof(int));
	B->zend = (double *)calloc((size_t)(nper * n), sizeof(double));
	B->adaptc0 = 1;
	for (k = 0; k < K; k++) B->P.theta[k] = th0[k];
	for (k = 0; k < Kb; k++) B->P.thetaBeh[k] = th0[K + k];
	for (pd = 0; pd < nper * B->nvar; pd++) B->rho[pd] = rho0[pd];
	for (pd = 0; pd < nper; pd++) B->c0[pd] = 20.0;
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
	for (i = 1; i <= nbend; i++) {
		ST_double a, b, c;
		long p, ac;
		SF_vdata(4, (ST_int)i, &a); SF_vdata(5, (ST_int)i, &b); SF_vdata(6, (ST_int)i, &c);
		p = (long)a - 1; ac = (long)b;
		if (p < 0 || p >= nper || ac < 1 || ac > n) continue;
		B->zend[p * n + (ac - 1)] = (double)c;
	}
	for (pd = 0; pd < nper; pd++) {
		const period_t *PD = &batch_cur->per[pd];
		graph_t gs, ge;
		bchain_t *c = &B->ch[pd];
		long r, m;
		graph_init(&gs, n, 1, PD->nties); graph_init(&ge, n, 1, nend_pd[pd]);
		for (r = 0; r < PD->nties; r++) toggle(&gs, PD->ti[r], PD->tj[r]);
		for (r = 0; r < nend_pd[pd]; r++) toggle(&ge, ei_end[pd][r], ej_end[pd][r]);
		bchain_ensure(c, PD->nties + nend_pd[pd] + 16);
		c->R = 0;
		for (r = 0; r < PD->nties; r++) if (!has_edge(&ge, PD->ti[r], PD->tj[r])) { c->ei[c->R] = (int)PD->ti[r]; c->ej[c->R] = (int)PD->tj[r]; c->ek[c->R] = 0; c->R++; }
		for (r = 0; r < nend_pd[pd]; r++) if (!has_edge(&gs, ei_end[pd][r], ej_end[pd][r])) { c->ei[c->R] = (int)ei_end[pd][r]; c->ej[c->R] = (int)ej_end[pd][r]; c->ek[c->R] = 0; c->R++; }
		if (Kb > 0) {
			long a;
			for (a = 1; a <= n; a++) {
				long dz = (long)floor(B->zend[pd * n + (a - 1)] - PD->beh0[a] + 0.5), q, sg = dz > 0 ? 1 : -1;
				bchain_ensure(c, c->R + labs(dz) + 1);
				for (q = 0; q < labs(dz); q++) { c->ei[c->R] = (int)a; c->ej[c->R] = (int)sg; c->ek[c->R] = 1; c->R++; }
			}
		}
		for (r = c->R - 1; r > 0; r--) {
			m = b_randint(B, r + 1);
			{ int t1 = c->ei[r], t2 = c->ej[r]; signed char t3 = c->ek[r]; c->ei[r] = c->ei[m]; c->ej[r] = c->ej[m]; c->ek[r] = c->ek[m]; c->ei[m] = t1; c->ej[m] = t2; c->ek[m] = t3; }
		}
		graph_free(&gs); graph_free(&ge);
		bwork_ensure(B, c->R + 16);
		/* the number of Metropolis-Hastings steps per batch: mult times the observed distance (RSiena), rounded to hundreds when above 100 */
		nmpd[pd] = nmhfix > 0 ? nmhfix : (long)floor(mult * (double)c->R);
		if (nmpd[pd] > 100) nmpd[pd] = (long)(floor((double)nmpd[pd] / 100.0 + 0.5) * 100.0);
		if (nmpd[pd] < 1) nmpd[pd] = 1;
	}
	for (pd = 0; pd < nper; pd++) { free(ei_end[pd]); free(ej_end[pd]); }
	free(ei_end); free(ej_end); free(nend_pd);
	if (!bcache_build(B)) return 0;
	(void)bcache_ll(B, th0, 1);
	memset(&mv, 0, sizeof(mv));
	/* pre-burn-in (RSiena's preburnin(): insert diagonal ministeps, then pairs, until 50 rejections each) */
	for (pd = 0; pd < nper; pd++) {
		long rej = 0, guard = 0;
		double save = B->c0[pd];
		while (rej < 50 && guard++ < 20000) { double a0 = mv.acc[0]; bmove_diag(B, pd, &mv, 1); if (mv.acc[0] == a0) rej++; }
		rej = 0; guard = 0; B->c0[pd] = 1.0; B->adaptc0 = 0;
		while (rej < 50 && guard++ < 20000) { double a3 = mv.acc[3]; bmove_insperm(B, pd, &mv); if (mv.acc[3] == a3) rej++; }
		B->c0[pd] = save; B->adaptc0 = 1;
	}
	if (!bcache_build(B)) return 0;
	(void)bcache_ll(B, th0, 1);
	return 1;
}
static void bctx_close(bctx_t *B) {
	long pd;
	for (pd = 0; pd < B->nper; pd++) { binvalidate(B, pd); free(B->ch[pd].ei); free(B->ch[pd].ej); free(B->ch[pd].ek); free(B->ch[pd].lp); free(B->ch[pd].off); }
	free(B->ch); free(B->rho); free(B->c0); free(B->st); free(B->ppos); free(B->pvalid); free(B->cache); free(B->tei); free(B->tej); free(B->tek); free(B->tlp); free(B->pl); free(B->hk); free(B->hv); free(B->nxt); free(B->zend);
	free(B->tt); free(B->c3); free(B->chg); free(B->u); free(B->ijx);
}

/* the model is within the scope of the chain machinery */
static int bmodel_ok(const model_t *M, const char *who) {
	long pd;
	char msg[200];
	if (M->nbeh > 1 || M->has_start || M->nstruct > 0 || batch_cur->nrc > 0 || batch_cur->symtype != 0 || M->hasfntype) {
		sprintf(msg, "%s: the model is outside the scope (one directed one-mode network with at most one behavior; no structural, rate-covariate or endowment/creation terms)\n", who);
		SF_error(msg); return 0;
	}
	if (batch_cur->P > 64 || M->nterms > 60 || M->nbehterms > 60) { SF_error("too many periods or effects\n"); return 0; }
	for (pd = 0; pd < batch_cur->P; pd++) if (batch_cur->per[pd].hasmiss || batch_cur->per[pd].haspresent) { sprintf(msg, "%s: missing data / composition change are not supported\n", who); SF_error(msg); return 0; }
	return 1;
}

static void bsettheta(bctx_t *B, const double *th) {
	long k;
	for (k = 0; k < B->K; k++) B->P.theta[k] = th[k];
	for (k = 0; k < B->Kb; k++) B->P.thetaBeh[k] = th[B->K + k];
}
static void bcount(const bctx_t *B, long pd, double *RN, double *RB) {
	const bchain_t *c = &B->ch[pd];
	long r;
	double nb = 0.0;
	for (r = 0; r < c->R; r++) if (c->ek[r]) nb += 1.0;
	*RB = nb; *RN = (double)c->R - nb;
}

/* ---- the Bayesian sampler: batches, improveMH, the schedule of multi_siena -------------------- */
typedef struct {
	long KT, nper, NR;
	double *th, *thp, *Sig, *L, *z, *pmean, *psd;
	double scaleEta, scaleRate, scale0;
	double *rsd, *rpm, *rps, *gshape, *grate;
	int ratemode;			/* 0 Metropolis with a normal prior (multi_siena), 1 Gibbs with a gamma prior, 2 fixed */
	long nsampconst, nsamprates;
	long *nmpd;
	double llcur;
	double sumRateAcc, sumEtaAcc, nRateProp, nEtaProp;	/* acceptances of the main run */
} bst_t;

static double bnormlp(double x, double m, double sd) { return -0.5 * (x - m) * (x - m) / (sd * sd); }

/* one proposal for the rates of all periods and variables (multi_siena's sampleVaryingParameters); returns the acceptance probability */
static double brate_prop(bctx_t *B, bst_t *S, int change, int *accepted) {
	long pd, w, q, n = B->n;
	double la = 0.0, newr[128];
	*accepted = 0;
	for (w = 0; w < B->nvar; w++) for (pd = 0; pd < B->nper; pd++) {
		double RN, RB, Rw;
		bcount(B, pd, &RN, &RB);
		Rw = w == 0 ? RN : RB;
		q = w * B->nper + pd;
		{
			double r0 = B->rho[q], r1 = r0 + sqrt(S->scaleRate) * S->rsd[q] * b_norm(B);
			if (r1 < 0.01) r1 = r0;
			newr[q] = r1;
			la += (-(double)n * r1 + Rw * log(r1)) - (-(double)n * r0 + Rw * log(r0));
			if (S->rps[q] > 0.0) la += bnormlp(r1, S->rpm[q], S->rps[q]) - bnormlp(r0, S->rpm[q], S->rps[q]);
		}
	}
	if (change) {
		if (log(b_unif(B)) < la) { for (q = 0; q < S->NR; q++) B->rho[q] = newr[q]; *accepted = 1; }
		else (void)b_unif(B);
	}
	{ double lq = la > 0.0 ? 0.0 : (la < -100.0 ? -100.0 : la); return exp(lq); }
}
/* one proposal for the effects (sampleConstantParameters); the cache and S->llcur must be current */
static double beta_prop(bctx_t *B, bst_t *S, int change, int *accepted) {
	long k, K = S->KT;
	double lprin = 0.0, lpri = 0.0, llnew, la, sc = sqrt(S->scaleEta);
	*accepted = 0;
	for (k = 0; k < K; k++) S->z[k] = b_norm(B);
	for (k = 0; k < K; k++) { double s2 = 0.0; long q; for (q = 0; q <= k; q++) s2 += S->L[k * K + q] * S->z[q]; S->thp[k] = S->th[k] + sc * s2; }
	for (k = 0; k < K; k++) if (S->psd[k] > 0.0) { lpri += bnormlp(S->th[k], S->pmean[k], S->psd[k]); lprin += bnormlp(S->thp[k], S->pmean[k], S->psd[k]); }
	llnew = bcache_ll(B, S->thp, 0);
	la = llnew + lprin - S->llcur - lpri;
	if (change) {
		if (log(b_unif(B)) < la) {
			memcpy(S->th, S->thp, (size_t)K * sizeof(double));
			S->llcur = llnew; *accepted = 1;
			bsettheta(B, S->th);
			(void)bcache_ll(B, S->th, 1);
		}
		else (void)b_unif(B);
	}
	{ double lq = la > 0.0 ? 0.0 : (la < -100.0 ? -100.0 : la); return exp(lq); }
}

/* one batch: Metropolis-Hastings steps on the chains, then the proposals for the rates and the effects */
static double b_prof[4];
static int bbatch(bctx_t *B, bst_t *S, bmoves_t *mv, int change, double *prate, double *peta) {
	long pd, q, i, w;
	int acc, anyacc = 0;
	double tt0 = (double)clock();
	for (pd = 0; pd < S->nper; pd++) for (q = 0; q < S->nmpd[pd]; q++) bmh_step(B, pd, mv);
	b_prof[0] += (double)clock() - tt0; tt0 = (double)clock();
	if (!bcache_build(B)) return -1;
	b_prof[1] += (double)clock() - tt0;
	S->llcur = bcache_ll(B, S->th, 0);
	*prate = 0.0; *peta = 0.0;
	if (S->ratemode == 0) {
		*prate = brate_prop(B, S, change, &acc); anyacc += acc; if (change) { S->nRateProp += 1.0; S->sumRateAcc += acc; }
		for (i = 0; i < S->nsamprates; i++) { (void)brate_prop(B, S, change, &acc); anyacc += acc; }
	}
	else if (S->ratemode == 1 && change) {
		for (w = 0; w < B->nvar; w++) for (pd = 0; pd < B->nper; pd++) {
			double RN, RB;
			bcount(B, pd, &RN, &RB);
			q = w * B->nper + pd;
			B->rho[q] = b_gamma(B, S->gshape[q] + (w == 0 ? RN : RB)) / (S->grate[q] + (double)B->n);
		}
	}
	for (i = 0; i < S->nsampconst; i++) { *peta = beta_prop(B, S, change, &acc); anyacc += acc; if (change) { S->nEtaProp += 1.0; S->sumEtaAcc += acc; } }
	return anyacc;
}

/* multi_siena's improveMH: tune the scale factors with batches that do not change the parameters */
static int bimprove(bctx_t *B, bst_t *S, bmoves_t *mv, long totruns, double target) {
	double desired = target * (double)totruns, tol = (double)totruns / 20.0, actual[3], prev[3] = {0, 0, 0}, mult[3];
	int nearGoal[3] = {0, 0, 0}, far[3] = {1, 1, 1}, past[3] = {0, 0, 0};
	long iter = 0, b, j;
	if (totruns <= 0) return 0;
	for (;;) {
		iter++;
		actual[0] = actual[1] = actual[2] = 0.0;
		for (b = 1; b <= totruns; b++) {
			double pr, pe;
			if (bbatch(B, S, mv, 0, &pr, &pe) < 0) return -1;
			actual[0] += pr;
			if (b % 2 == 0) actual[1] += pe; else actual[2] += pe;
		}
		if (S->ratemode != 0) actual[0] = desired;
		for (j = 0; j < 3; j++) {
			double farm;
			if (nearGoal[j]) actual[j] = (actual[j] + prev[j]) / 2.0;
			if (fabs(actual[j] - desired) < tol) nearGoal[j] = 1;
			if (fabs(actual[j] - desired) < 2.0 * tol) far[j] = 0;
			farm = actual[j] > desired ? 2.0 : 0.5;
			if (actual[j] > 5.0 * desired) farm = 5.0;
			if (5.0 * actual[j] < desired) farm = 0.2;
			prev[j] = actual[j];
			if (fabs(actual[j] - desired) <= tol) past[j]++;
			mult[j] = far[j] ? farm : 1.0 + (actual[j] - desired) / sqrt(sqrt((double)iter) * desired * ((double)totruns - desired));
			if (mult[j] < 0.1) mult[j] = 0.1;
			if (mult[j] > 10.0) mult[j] = 10.0;
		}
		S->scaleRate *= mult[0]; S->scale0 *= mult[1]; S->scaleEta *= mult[2];
		if ((past[0] >= 2 && past[1] >= 2 && past[2] >= 2) || iter == 20) break;
		if (S->scaleRate < 1e-15 || S->scaleEta < 1e-15) break;
	}
	return (int)iter;
}

static ST_retcode bayes_run(char *arg) {
	bctx_t B;
	bst_t S;
	const model_t *M;
	long n, K, Kb, KT, nper, NR, nvar, pd, i, k, it, nend, nbend, nprewarm, nwarm, nmain, nrunmh, nimprove, nmhfix, nsampconst, nsamprates, nsave = 0, nout, batch, w;
	unsigned long long seed;
	double mult, targetmh, *rho0, t0, sumR = 0.0, accepts_earlier = 10.0, geo;
	bmoves_t mv;
	char *tok;
	int ratemode;
	long nmpd[64];

	if (!batch_cur->ready) { SF_error("saom_bayes: no resident model (BATCHSETUP first)\n"); return 198; }
	M = &batch_cur->M;
	if (!bmodel_ok(M, "saom_bayes")) return 198;
	n = M->n; K = M->nterms; Kb = M->nbehterms > 0 ? M->nbehterms : 0; KT = K + Kb; nper = batch_cur->P; nvar = Kb > 0 ? 2 : 1; NR = nper * nvar;
	memset(&S, 0, sizeof(S));
	tok = strtok(arg, " \t");
	if (!tok) return 198;
	nend = (long)atof(tok);
	nbend = next_long();
	nprewarm = next_long(); nwarm = next_long(); nmain = next_long(); nrunmh = next_long(); nimprove = next_long(); nmhfix = next_long();
	nsampconst = next_long(); nsamprates = next_long();
	seed = (unsigned long long)next_double(); mult = next_double(); targetmh = next_double(); ratemode = (int)next_long(); geo = next_double();
	if (next_long() != K || next_long() != Kb || next_long() != nper) { SF_error("saom_bayes: dimension mismatch\n"); return 198; }
	S.KT = KT; S.nper = nper; S.NR = NR; S.ratemode = ratemode; S.nsampconst = nsampconst; S.nsamprates = nsamprates;
	S.th = (double *)calloc((size_t)KT, sizeof(double)); S.thp = (double *)calloc((size_t)KT, sizeof(double));
	S.pmean = (double *)calloc((size_t)KT, sizeof(double)); S.psd = (double *)calloc((size_t)KT, sizeof(double));
	S.Sig = (double *)calloc((size_t)(KT * KT), sizeof(double)); S.L = (double *)calloc((size_t)(KT * KT), sizeof(double)); S.z = (double *)calloc((size_t)KT, sizeof(double));
	S.rsd = (double *)calloc((size_t)NR, sizeof(double)); S.rpm = (double *)calloc((size_t)NR, sizeof(double)); S.rps = (double *)calloc((size_t)NR, sizeof(double));
	S.gshape = (double *)calloc((size_t)NR, sizeof(double)); S.grate = (double *)calloc((size_t)NR, sizeof(double));
	S.nmpd = nmpd;
	rho0 = (double *)calloc((size_t)NR, sizeof(double));
	for (k = 0; k < KT; k++) S.th[k] = next_double();
	for (k = 0; k < KT; k++) S.pmean[k] = next_double();
	for (k = 0; k < KT; k++) S.psd[k] = next_double();
	for (pd = 0; pd < NR; pd++) rho0[pd] = next_double();
	for (pd = 0; pd < NR; pd++) S.rpm[pd] = next_double();
	for (pd = 0; pd < NR; pd++) S.rps[pd] = next_double();
	for (pd = 0; pd < NR; pd++) S.gshape[pd] = next_double();
	for (pd = 0; pd < NR; pd++) S.grate[pd] = next_double();
	for (pd = 0; pd < NR; pd++) S.rsd[pd] = next_double();
	for (k = 0; k < KT * KT; k++) S.Sig[k] = next_double();
	if (wire_parse_error) { SF_error("saom_bayes: argument string too short\n"); return 198; }
	if (nrunmh < 1) nrunmh = 1;
	nout = KT + NR + 2;
	if ((long)SF_nvars() < 6 + nout || (long)SF_nobs() < (nmain > nend ? (nmain > nbend ? nmain : nbend) : (nend > nbend ? nend : nbend))) { SF_error("saom_bayes: frame too small\n"); return 198; }
	if (!bctx_open(&B, M, nend, nbend, seed, S.th, rho0, mult, nmhfix, nmpd)) { SF_error("saom_bayes: out of memory\n"); return 198; }
	B.geo = geo;
	t0 = (double)clock() / (double)CLOCKS_PER_SEC;
	S.scaleEta = 2.38 * 2.38 / (double)(KT > 0 ? KT : 1); S.scale0 = S.scaleEta; S.scaleRate = 2.38 * 2.38 / (double)(KT + NR);
	if (!bchol(S.Sig, S.L, KT)) { for (k = 0; k < KT * KT; k++) S.Sig[k] = (k % (KT + 1) == 0) ? 0.01 : 0.0; bchol(S.Sig, S.L, KT); }
	S.llcur = bcache_ll(&B, S.th, 1);
	memset(&mv, 0, sizeof(mv));
	{
		long iters_improve1 = 0, iters_improve2 = 0;
		/* pre-warming */
		for (it = 1; it <= nprewarm; it++) {
			double accepts = 0.0, pr, pe;
			for (batch = 0; batch < nrunmh; batch++) { int a = bbatch(&B, &S, &mv, 1, &pr, &pe); if (a < 0) { SF_error("saom_bayes: out of memory\n"); return 198; } accepts += a; }
			if ((accepts > accepts_earlier ? accepts : accepts_earlier) <= 0.0) break;
			accepts_earlier = accepts;
		}
		iters_improve1 = bimprove(&B, &S, &mv, nimprove, targetmh);
		for (it = 1; it <= nwarm; it++) {
			double pr, pe;
			for (batch = 0; batch < nrunmh; batch++) { if (bbatch(&B, &S, &mv, 1, &pr, &pe) < 0) { SF_error("saom_bayes: out of memory\n"); return 198; } }
		}
		iters_improve2 = bimprove(&B, &S, &mv, nimprove, targetmh);
		B.adaptc0 = 0;			/* the permutation lengths are kept fixed in the main run */
		memset(&mv, 0, sizeof(mv));
		S.nRateProp = S.sumRateAcc = S.nEtaProp = S.sumEtaAcc = 0.0;
		for (it = 1; it <= nmain; it++) {
			double sr = 0.0, pr, pe;
			for (batch = 0; batch < nrunmh; batch++) {
				if (bbatch(&B, &S, &mv, 1, &pr, &pe) < 0) { SF_error("saom_bayes: out of memory\n"); return 198; }
			}
			nsave++;
			for (k = 0; k < KT; k++) SF_vstore((ST_int)(7 + k), (ST_int)nsave, S.th[k]);
			for (w = 0; w < nvar; w++) for (pd = 0; pd < nper; pd++) SF_vstore((ST_int)(7 + KT + w * nper + pd), (ST_int)nsave, B.rho[w * nper + pd]);
			for (pd = 0; pd < nper; pd++) sr += (double)B.ch[pd].R;
			SF_vstore((ST_int)(7 + KT + NR), (ST_int)nsave, sr);
			SF_vstore((ST_int)(7 + KT + NR + 1), (ST_int)nsave, S.llcur);
			sumR += sr;
		}
		SF_scal_save("__saom_bayes_improve1", (ST_double)iters_improve1);
		SF_scal_save("__saom_bayes_improve2", (ST_double)iters_improve2);
	}
	SF_scal_save("__saom_bayes_prof_steps", b_prof[0] / (double)CLOCKS_PER_SEC);
	SF_scal_save("__saom_bayes_prof_cache", b_prof[1] / (double)CLOCKS_PER_SEC);
	SF_scal_save("__saom_bayes_nsave", (ST_double)nsave);
	SF_scal_save("__saom_bayes_acc_rates", S.nRateProp > 0 ? S.sumRateAcc / S.nRateProp : 0.0);
	SF_scal_save("__saom_bayes_acc_theta", S.nEtaProp > 0 ? S.sumEtaAcc / S.nEtaProp : 0.0);
	SF_scal_save("__saom_bayes_scale_eta", S.scaleEta);
	SF_scal_save("__saom_bayes_scale_rate", S.scaleRate);
	SF_scal_save("__saom_bayes_acc_diag", mv.tried[0] + mv.tried[1] > 0 ? (mv.acc[0] + mv.acc[1]) / (mv.tried[0] + mv.tried[1]) : 0.0);
	SF_scal_save("__saom_bayes_acc_permute", mv.tried[2] > 0 ? mv.acc[2] / mv.tried[2] : 0.0);
	SF_scal_save("__saom_bayes_acc_insperm", mv.tried[3] > 0 ? mv.acc[3] / mv.tried[3] : 0.0);
	SF_scal_save("__saom_bayes_acc_delperm", mv.tried[4] > 0 ? mv.acc[4] / mv.tried[4] : 0.0);
	SF_scal_save("__saom_bayes_c0", B.c0[0]);
	SF_scal_save("__saom_bayes_meanR", nsave > 0 ? sumR / (double)nsave : 0.0);
	SF_scal_save("__saom_bayes_secs", (double)clock() / (double)CLOCKS_PER_SEC - t0);
	bctx_close(&B);
	free(S.th); free(S.thp); free(S.pmean); free(S.psd); free(S.Sig); free(S.L); free(S.z); free(S.rsd); free(S.rpm); free(S.rps); free(S.gshape); free(S.grate);
	free(rho0);
	(void)i; (void)n;
	return 0;
}

#endif
