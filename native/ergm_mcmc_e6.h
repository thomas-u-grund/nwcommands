/* ===================================================================
   E6 block: sample-space constraints and Metropolis-Hastings proposals
   beyond uniform/TNT (direct C ports of R ergm 4.12.0's src/MHproposals.c,
   MHproposals_degree.c, MHproposals_dyadnoise.c and MHproposal_bd.c).

   This file is #included by ergm_mcmc.c right before stata_call(), so it
   sees graph_t, rng_t, toggle(), has_edge(), propose_uniform(),
   propose_tnt(), propose_uniform_masked(), propose_tnt_masked() etc.

   Wire format (appended to the end of the argument string, after the
   curved-MPLE decay start; an absent block means "no E6 constraint"):
       ncon_par  par[0..ncon_par-1]  ncon_cols
   par[]:  0 code (E6_* below)
           1 bdK         number of degree-bound attribute columns (0 = no bd)
           2 bd_maxonly  1 iff only maxout/maxin were given (R: BDStratTNT,
                         which refuses an initial network that violates them)
           3 dn_mode     dyadnoise: 0 none, 1 scalar probabilities, 2 matrices
           4..7          dyadnoise scalars: log-ratios o0s0 o0s1 o1s0 o1s1
           8 dn_nobs     number of observed ties of the dyadnoise reference
                         network (edge list in the 2 columns after the bd block)
           9 tnt10       reserved
   Extra dataset columns (after the mask block, before the outputs):
       bd:        att[K], maxout[K], maxin[K], minout[K], minin[K]   (n rows)
       dyadnoise: obs-edge columns v1,v2 (nobs rows); if dn_mode==2 also the
                  log-ratio matrices o0s0,o0s1,o1s0,o1s1 (n columns each)
   =================================================================== */

#define E6_TNT          10
#define E6_RANDOM       11
#define E6_CONSTEDGES   20
#define E6_CONDDEGREE   30
#define E6_CONDOUT      31
#define E6_CONDIN       32
#define E6_CONDB1       33
#define E6_CONDB2       34
#define E6_DEGDIST      35
#define E6_ODEGDIST     36
#define E6_IDEGDIST     37
#define E6_DYADNOISE    50
#define E6_DYADNOISETNT 51

#define E6_MAXTOG   8
#define E6_MAXTRIES 1000000   /* guard for rejection loops that R leaves unbounded */

typedef struct {
	long t[E6_MAXTOG], h[E6_MAXTOG];
	int m;
	double logratio;
} e6prop_t;

typedef struct {
	long code;
	long n;
	long bdK;
	int bd_maxonly;
	int *bd_att, *bd_maxout, *bd_maxin, *bd_minout, *bd_minin; /* [(i-1) + k*n] */
	int dn_mode;
	double dn_s[4];
	double *dn_m[4];          /* n*n, [(i-1) + (j-1)*n] */
	char *dn_obs;             /* dyadkey()-indexed observed tie indicator */
	long dn_nobs;
} e6con_t;

static void e6_init(e6con_t *c) { memset(c, 0, sizeof(*c)); }

static void e6_free(e6con_t *c) {
	int k;
	free(c->bd_att); free(c->bd_maxout); free(c->bd_maxin); free(c->bd_minout); free(c->bd_minin);
	for (k = 0; k < 4; k++) free(c->dn_m[k]);
	free(c->dn_obs);
	e6_init(c);
}

/* order a dyad as R's edge lists do: undirected tail<head; bipartite tail in mode 1 */
static void e6_orient(graph_t *g, long *i, long *j) {
	if (g->bipartite) {
		if (g->mode[*i] != 1) { long t = *i; *i = *j; *j = t; }
	}
	else if (!g->directed) {
		if (*i > *j) { long t = *i; *i = *j; *j = t; }
	}
}

/* GetRandEdge: uniform over the current ties */
static void e6_rand_edge(graph_t *g, rng_t *rng, long *i, long *j) {
	long r = rng_below(rng, g->nties);
	*i = g->elist_i[r]; *j = g->elist_j[r];
	e6_orient(g, i, j);
}

static int e6_is_edge(graph_t *g, long i, long j) {   /* IS_OUTEDGE / IS_UNDIRECTED_EDGE */
	return has_edge(g, i, j);
}

/* --- degree bounds (CheckTogglesValid of MHproposal_bd.c) --- */
static int e6_bd_valid(graph_t *g, e6con_t *c, const e6prop_t *P) {
	long n = c->n, K = c->bdK, a, k;
	int ok = 1;
	long cnt_t[64], cnt_h[64];
	if (K <= 0) return 1;
	if (K > 64) K = 64;
	for (a = 0; a < P->m; a++) toggle(g, P->t[a], P->h[a]);
	for (a = 0; a < P->m && ok; a++) {
		long tl = P->t[a], hd = P->h[a], q;
		adjlist_t *lt, *lh;
		for (k = 0; k < K; k++) cnt_t[k] = cnt_h[k] = 0;
		if (g->directed) { lt = &g->outadj[tl]; lh = &g->inadj[hd]; }
		else { lt = &g->adj[tl]; lh = &g->adj[hd]; }
		for (q = 0; q < lt->len; q++) for (k = 0; k < K; k++) if (c->bd_att[(lt->nb[q]-1) + k*n]) cnt_t[k]++;
		for (q = 0; q < lh->len; q++) for (k = 0; k < K; k++) if (c->bd_att[(lh->nb[q]-1) + k*n]) cnt_h[k]++;
		for (k = 0; k < K && ok; k++) {
			if (g->directed) {
				if (cnt_t[k] > c->bd_maxout[(tl-1)+k*n] || cnt_t[k] < c->bd_minout[(tl-1)+k*n] ||
				    cnt_h[k] > c->bd_maxin[(hd-1)+k*n]  || cnt_h[k] < c->bd_minin[(hd-1)+k*n]) ok = 0;
			}
			else {
				if (cnt_t[k] > c->bd_maxout[(tl-1)+k*n] || cnt_t[k] < c->bd_minout[(tl-1)+k*n] ||
				    cnt_h[k] > c->bd_maxout[(hd-1)+k*n] || cnt_h[k] < c->bd_minout[(hd-1)+k*n]) ok = 0;
			}
		}
	}
	for (a = P->m - 1; a >= 0; a--) toggle(g, P->t[a], P->h[a]);
	return ok;
}

/* does the starting network satisfy the degree bounds? (ergm_bd_init's check) */
static int e6_bd_initial_ok(graph_t *g, e6con_t *c) {
	long n = c->n, K = c->bdK, i, k, q;
	for (i = 1; i <= n; i++) {
		for (k = 0; k < K; k++) {
			long co = 0, ci = 0;
			adjlist_t *lo = g->directed ? &g->outadj[i] : &g->adj[i];
			adjlist_t *li = g->directed ? &g->inadj[i] : NULL;
			for (q = 0; q < lo->len; q++) if (c->bd_att[(lo->nb[q]-1) + k*n]) co++;
			if (co > c->bd_maxout[(i-1)+k*n] || co < c->bd_minout[(i-1)+k*n]) return 0;
			if (g->directed) {
				for (q = 0; q < li->len; q++) if (c->bd_att[(li->nb[q]-1) + k*n]) ci++;
				if (ci > c->bd_maxin[(i-1)+k*n] || ci < c->bd_minin[(i-1)+k*n]) return 0;
			}
		}
	}
	return 1;
}

/* --- single-dyad proposals with optional dyad mask --- */
static int e6_p_tnt(graph_t *g, rng_t *rng, e6prop_t *P) {
	long i, j; double lr;
	int rc = g->has_mask ? propose_tnt_masked(g, rng, &i, &j, &lr) : (propose_tnt(g, rng, &i, &j, &lr), 0);
	if (rc) return 1;
	P->m = 1; P->t[0] = i; P->h[0] = j; P->logratio = lr;
	return 0;
}

static int e6_p_random(graph_t *g, rng_t *rng, e6prop_t *P) {
	long i, j; double lr;
	int rc = g->has_mask ? propose_uniform_masked(g, rng, &i, &j, &lr) : (propose_uniform(g, rng, &i, &j, &lr), 0);
	if (rc) return 1;
	P->m = 1; P->t[0] = i; P->h[0] = j; P->logratio = 0.0;
	return 0;
}

/* ConstantEdges: a random (free) tie and a random (free) non-tie */
static int e6_p_constedges(graph_t *g, rng_t *rng, e6prop_t *P) {
	double nedges = g->has_mask ? (double)g->n_free_ties : (double)g->nties;
	double ndyads = g->has_mask ? g->n_free_dyads : total_dyads(g);
	long i, j, tries; double lr;
	if (!(nedges > 0 && nedges < ndyads && ndyads >= 2)) return 1;
	if (g->has_mask) {
		long r = rng_below(rng, g->n_free_ties);
		i = g->free_elist_i[r]; j = g->free_elist_j[r];
	}
	else { long r = rng_below(rng, g->nties); i = g->elist_i[r]; j = g->elist_j[r]; }
	e6_orient(g, &i, &j);
	P->t[0] = i; P->h[0] = j;
	for (tries = 0; tries < E6_MAXTRIES; tries++) {
		if (g->has_mask) { if (propose_uniform_masked(g, rng, &i, &j, &lr)) return 1; }
		else propose_uniform(g, rng, &i, &j, &lr);
		if (!has_edge(g, i, j)) break;
	}
	if (tries >= E6_MAXTRIES) return 1;
	P->t[1] = i; P->h[1] = j; P->m = 2; P->logratio = 0.0;
	return 0;
}

/* CondDegree: tetrad (all networks) / hexad (directed, 10%) */
static int e6_p_condegree(graph_t *g, rng_t *rng, e6prop_t *P) {
	long A1, A2, B1, B2, C1, C2, tries;
	if (g->nties < 2) { P->m = 0; P->logratio = 0; return 0; }
	P->logratio = 0.0;
	if (g->directed && rng_unif(rng) > 0.9) {
		/* hexad */
		long cnt;
		for (tries = 0; tries < E6_MAXTRIES; tries++) {
			e6_rand_edge(g, rng, &A1, &A2);
			for (cnt = 0; cnt < 1000; cnt++) {
				e6_rand_edge(g, rng, &B1, &B2);
				if (!(B1==A1 || B2==A1 || B2==A2 || e6_is_edge(g, A1, B2))) break;
			}
			if (cnt >= 1000) continue;
			for (cnt = 0; cnt < 1000; cnt++) {
				e6_rand_edge(g, rng, &C1, &C2);
				if (!(C1==A1 || C1==B1 || C1==A2 || C2==A2 || C2==B2 || C2==B1 || e6_is_edge(g, B1, C2) || e6_is_edge(g, C1, A2))) break;
			}
			if (cnt >= 1000) continue;
			break;
		}
		if (tries >= E6_MAXTRIES) { P->m = 0; return 0; }
		P->t[0]=A1; P->h[0]=A2; P->t[1]=A1; P->h[1]=B2; P->t[2]=B1; P->h[2]=B2;
		P->t[3]=B1; P->h[3]=C2; P->t[4]=C1; P->h[4]=C2; P->t[5]=C1; P->h[5]=A2;
		P->m = 6;
		return 0;
	}
	for (tries = 0; tries < E6_MAXTRIES; tries++) {
		if (!g->directed && !g->bipartite && rng_unif(rng) < 0.5) { e6_rand_edge(g, rng, &A2, &A1); }
		else e6_rand_edge(g, rng, &A1, &A2);
		e6_rand_edge(g, rng, &B1, &B2);
		if (A1==B1 || A1==B2 || A2==B1 || A2==B2) continue;
		if (e6_is_edge(g, A1, B2) || e6_is_edge(g, B1, A2)) continue;
		break;
	}
	if (tries >= E6_MAXTRIES) { P->m = 0; return 0; }
	P->t[0]=A1; P->h[0]=A2; P->t[1]=A1; P->h[1]=B2; P->t[2]=B1; P->h[2]=B2; P->t[3]=B1; P->h[3]=A2;
	P->m = 4;
	return 0;
}

/* CondOutDegree / CondInDegree / CondB1Degree / CondB2Degree */
static int e6_p_cond2(graph_t *g, rng_t *rng, long code, e6prop_t *P) {
	long A1, A2, X, tries;
	if (g->nties < 1) { P->m = 0; P->logratio = 0; return 0; }
	for (tries = 0; tries < E6_MAXTRIES; tries++) {
		e6_rand_edge(g, rng, &A1, &A2);
		if (code == E6_CONDOUT) { X = 1 + rng_below(rng, g->n); if (A1==X || A2==X || e6_is_edge(g, A1, X)) continue; break; }
		if (code == E6_CONDIN)  { X = 1 + rng_below(rng, g->n); if (A1==X || A2==X || e6_is_edge(g, X, A2)) continue; break; }
		if (code == E6_CONDB1)  { X = g->mode2nodes[1 + rng_below(rng, g->n2)]; if (A2==X || e6_is_edge(g, A1, X)) continue; break; }
		X = g->mode1nodes[1 + rng_below(rng, g->n1)];             /* CondB2 */
		if (A1==X || A2==X || e6_is_edge(g, X, A2)) continue;
		break;
	}
	if (tries >= E6_MAXTRIES) { P->m = 0; P->logratio = 0; return 0; }
	P->t[0] = A1; P->h[0] = A2;
	if (code == E6_CONDOUT || code == E6_CONDB1) { P->t[1] = A1; P->h[1] = X; }
	else { P->t[1] = X; P->h[1] = A2; }
	P->m = 2; P->logratio = 0.0;
	return 0;
}

/* neighbour lists by role */
static adjlist_t *e6_outlist(graph_t *g, long i) { return g->directed ? &g->outadj[i] : &g->adj[i]; }
static adjlist_t *e6_inlist(graph_t *g, long i)  { return g->directed ? &g->inadj[i]  : &g->adj[i]; }

/* CondDegreeDist (any of: undirected/directed both, out-only, in-only).
   kind 0: MH_CondDegreeDist, 1: MH_CondOutDegreeDist, 2: MH_CondInDegreeDist.
   Faithful to the sticky-tail quirk of R's loops (the chosen tail is kept
   across retries). */
static int e6_p_degdist(graph_t *g, rng_t *rng, int kind, e6prop_t *P) {
	long noutedge = 0, ninedge = 0, k0, k1, trynode = 0, tail = 0, head = 0, alter = 0, q;
	int fvalid = 0, dir = g->directed;
	long maxtry = (kind == 0) ? 500 : 1500;
	P->logratio = 0.0; P->m = 2;
	while (fvalid == 0 && trynode < maxtry) {
		adjlist_t *lo, *li;
		trynode++;
		if (kind == 0) {
			while (noutedge + ninedge == 0) {
				tail = 1 + rng_below(rng, g->n);
				ninedge = dir ? g->inadj[tail].len : 0;
				noutedge = dir ? g->outadj[tail].len : g->adj[tail].len;
			}
		}
		else if (kind == 1) {
			while (noutedge == 0) { tail = 1 + rng_below(rng, g->n); noutedge = g->outadj[tail].len; }
		}
		else {
			while (ninedge == 0) { tail = 1 + rng_below(rng, g->n); ninedge = g->inadj[tail].len; }
		}
		lo = e6_outlist(g, tail); li = e6_inlist(g, tail);
		if (kind == 0) {
			k0 = rng_below(rng, noutedge + ninedge);
			if (k0 < noutedge) head = lo->nb[k0]; else head = li->nb[k0 - noutedge];
			if ((!dir && tail > head) || (dir && k0 >= noutedge)) { P->t[0] = head; P->h[0] = tail; }
			else { P->t[0] = tail; P->h[0] = head; }
		}
		else if (kind == 1) {
			k0 = rng_below(rng, noutedge);
			head = lo->nb[k0];
			P->t[0] = tail; P->h[0] = head;
		}
		else {
			k0 = rng_below(rng, ninedge);
			head = li->nb[k0];
			P->t[0] = head; P->h[0] = tail;
		}
		k1 = 0; fvalid = 0;
		while (fvalid == 0 && k1 < 100) {
			do { alter = 1 + rng_below(rng, g->n); } while (alter == tail);
			fvalid = 1;
			if (alter == head) fvalid = 0;
			if (kind == 0) {
				if (k0 < noutedge || !dir) for (q = 0; q < lo->len; q++) if (alter == lo->nb[q]) fvalid = 0;
				if (k0 >= noutedge || !dir) { if (dir) for (q = 0; q < li->len; q++) if (alter == li->nb[q]) fvalid = 0; }
			}
			else if (kind == 1) { for (q = 0; q < lo->len; q++) if (alter == lo->nb[q]) fvalid = 0; }
			else { for (q = 0; q < li->len; q++) if (alter == li->nb[q]) fvalid = 0; }
			k1++;
		}
		if (k1 == 100) { fvalid = 0; continue; }
		if (kind == 0) {
			if ((!dir && alter > tail) || (dir && k0 < noutedge)) { P->t[1] = tail; P->h[1] = alter; }
			else { P->t[1] = alter; P->h[1] = tail; }
			if (!dir) {
				long j0h = g->deg[head], j1h = g->deg[alter];
				fvalid = ((j0h - 1) == j1h && (j1h + 1) == j0h);
			}
			else {
				long j0h, j1h;
				if (k0 < noutedge) { j0h = g->inadj[head].len;  j1h = g->inadj[alter].len; }
				else               { j0h = g->outadj[head].len; j1h = g->outadj[alter].len; }
				fvalid = ((j0h - 1) == j1h && (j1h + 1) == j0h);
			}
		}
		else if (kind == 1) { P->t[1] = tail; P->h[1] = alter; }
		else { P->t[1] = alter; P->h[1] = tail; }
	}
	if (kind == 0) {
		if (trynode == 500) { P->t[1] = P->t[0]; P->h[1] = P->h[0]; }
	}
	else if (trynode == 1500) { P->t[0] = 1; P->h[0] = 2; P->t[1] = 1; P->h[1] = 2; }
	return 0;
}

/* dyadnoise: independent per-dyad observation noise folded into the MH ratio */
static double e6_dn_term(graph_t *g, e6con_t *c, long i, long j, int state, int obs) {
	int idx = (obs ? 2 : 0) + (state ? 1 : 0);   /* o0s0=0 o0s1=1 o1s0=2 o1s1=3 */
	if (c->dn_mode == 2) {
		return c->dn_m[idx][(i-1) + (j-1)*c->n];
	}
	return c->dn_s[idx];
}

static int e6_p_dyadnoise(graph_t *g, rng_t *rng, e6con_t *c, int tnt, e6prop_t *P) {
	long i, j; double lr = 0.0;
	if (tnt) {
		const double comp = 0.5, odds = 1.0, ndy = total_dyads(g);
		double E = (double)g->nties;
		if (rng_unif(rng) < comp && g->nties > 0) {
			e6_rand_edge(g, rng, &i, &j);
			lr += log(E == 1 ? 1.0 / (comp * ndy + (1.0 - comp)) : E / (odds * ndy + E));
			lr += e6_dn_term(g, c, i, j, 1, c->dn_obs[dyadkey(g, i, j)]);
		}
		else {
			double l0;
			propose_uniform(g, rng, &i, &j, &l0);
			if (has_edge(g, i, j)) {
				lr += log(E == 1 ? 1.0 / (comp * ndy + (1.0 - comp)) : E / (odds * ndy + E));
				lr += e6_dn_term(g, c, i, j, 1, c->dn_obs[dyadkey(g, i, j)]);
			}
			else {
				lr += log(E == 0 ? comp * ndy + (1.0 - comp) : 1.0 + (odds * ndy) / (E + 1.0));
				lr += e6_dn_term(g, c, i, j, 0, c->dn_obs[dyadkey(g, i, j)]);
			}
		}
	}
	else {
		double l0;
		propose_uniform(g, rng, &i, &j, &l0);
		lr += e6_dn_term(g, c, i, j, has_edge(g, i, j), c->dn_obs[dyadkey(g, i, j)]);
	}
	P->m = 1; P->t[0] = i; P->h[0] = j; P->logratio = lr;
	return 0;
}

/* returns 0 ok, 1 proposal impossible (fatal, R: MH_FAILED at initialisation) */
static int e6_propose(graph_t *g, rng_t *rng, e6con_t *c, e6prop_t *P) {
	P->m = 0; P->logratio = 0.0;
	switch (c->code) {
		case E6_TNT:          return e6_p_tnt(g, rng, P);
		case E6_RANDOM:       return e6_p_random(g, rng, P);
		case E6_CONSTEDGES:   return e6_p_constedges(g, rng, P);
		case E6_CONDDEGREE:   return e6_p_condegree(g, rng, P);
		case E6_CONDOUT: case E6_CONDIN: case E6_CONDB1: case E6_CONDB2:
			return e6_p_cond2(g, rng, c->code, P);
		case E6_DEGDIST:      return e6_p_degdist(g, rng, 0, P);
		case E6_ODEGDIST:     return e6_p_degdist(g, rng, 1, P);
		case E6_IDEGDIST:     return e6_p_degdist(g, rng, 2, P);
		case E6_DYADNOISE:    return e6_p_dyadnoise(g, rng, c, 0, P);
		case E6_DYADNOISETNT: return e6_p_dyadnoise(g, rng, c, 1, P);
	}
	return 1;
}

/* One Metropolis-Hastings step; returns 1 if accepted, 0 if rejected, -1 on a fatal error. */
static int e6_step(graph_t *g, rng_t *rng, e6con_t *c, long nterms, const int *termcodes, const int *attridx,
		const double *p1, const double *p2, const int *covidx, double **attrs, double **covmats, long n,
		const double *theta, double *cur) {
	e6prop_t P;
	double chg[MAXTERMS], cutoff;
	long a, k;
	if (e6_propose(g, rng, c, &P)) return -1;
	if (P.m == 0) return 0;
	if (c->bdK > 0 && !e6_bd_valid(g, c, &P)) return 0;
	for (k = 0; k < nterms; k++) chg[k] = 0.0;
	for (a = 0; a < P.m; a++) {
		double delta = has_edge(g, P.t[a], P.h[a]) ? -1.0 : 1.0;
		for (k = 0; k < nterms; k++) {
			double *at = (attridx[k] > 0) ? attrs[attridx[k] - 1] : NULL;
			double *cmk = (covidx[k] > 0) ? covmats[covidx[k] - 1] : NULL;
			chg[k] += change_term(g, termcodes[k], p1[k], p2[k], at, cmk, n, delta, P.t[a], P.h[a]);
		}
		toggle(g, P.t[a], P.h[a]);
	}
	cutoff = P.logratio;
	for (k = 0; k < nterms; k++) cutoff += theta[k] * chg[k];
	if (cutoff >= 0.0 || log(rng_unif(rng)) < cutoff) {
		for (k = 0; k < nterms; k++) cur[k] += chg[k];
		return 1;
	}
	for (a = P.m - 1; a >= 0; a--) toggle(g, P.t[a], P.h[a]);
	return 0;
}
