/*
	dynam_sim.c -- native (C) DyNAM likelihood/gradient kernel for
	nwcommands (nwdynam).

	See docs/DYNAM_ROADMAP.md (scope/status) and unw_dynam.do's own
	header comment (Mata reference implementation, built and
	CORRECTNESS-VERIFIED against a real reference R implementation
	FIRST - dev/dynam_unit1_choice_crosscheck.do,
	dev/dynam_unit2_rate_crosscheck.do - matching this project's own
	established sequencing discipline, ergm_mcmc.c's own header: get the
	Mata reference right and crosschecked before writing
	performance-critical C, since a fast wrong answer is worse than a
	slow right one).

	WHAT THIS ACCELERATES: unlike ergm_mcmc.c (a full from-scratch MCMC
	sampler, since Mata's own optimize() has no equivalent) or
	saom_sim.c (a full ministep simulation loop), nwdynam fits via plain
	MLE - Mata's own optimize() (BFGS, with a Nelder-Mead fallback)
	already handles the outer optimization robustly and is NOT
	reimplemented here. This plugin accelerates only the HOT INNER LOOP:
	one log-likelihood + analytic-gradient evaluation at a given theta,
	called repeatedly (once per outer optimizer iteration - typically a
	few dozen calls per fit, not thousands) from Mata's own evaluator
	callback. Each such call still does the SAME O(n) per-event work the
	Mata engine does (dynam_choice_loglik_grad_unit1()/
	dynam_rate_loglik_grad_unit1() in unw_dynam.do) - the win is
	removing Mata's own per-operation interpreter overhead on that
	tight, compounding loop, the identical rationale nwgraph.c's own
	header already gives for betweenness centrality.

	ONE REAL ALGORITHMIC IMPROVEMENT OVER THE MATA REFERENCE, NOT JUST A
	COMPILED PORT: unw_dynam.do's own dynam_choice_loglik_grad_unit1()
	recomputes `indeg_i = colsum(tie)` - an O(n) reduction over an n x n
	MATRIX, i.e. genuinely O(n^2) work - AT EVERY EVENT, for both the
	choice sub-model's own indeg-alter effect and (implicitly, via the
	analogous call) the rate sub-model's indeg/outdeg-ego effects. Since
	`tie` only ever grows (a 0 cell flips to 1 exactly once, on the
	first tie between that ordered pair; a repeat contact leaves it at
	1), each actor's own in-degree and out-degree can instead be
	maintained as a genuinely O(1)-per-update running count (`indeg[]`/
	`outdeg[]` below), collapsing an O(n^2 * nevents) total cost down to
	O(n * nevents) - the same asymptotic class the row/column inertia/
	recip lookups already need per event regardless. This is a real,
	disclosed finding from porting the reference algorithm to C, not
	silently different behavior: both implementations compute
	MATHEMATICALLY IDENTICAL quantities (indeg[j] here always equals
	colsum(tie)[j] there, by construction - tie is monotonically
	non-decreasing and indeg[j] is incremented exactly once per 0->1
	flip in column j), so the CERTIFICATION CONTRACT below still holds
	exactly, not approximately.

	CERTIFICATION CONTRACT: like nwgraph.c's betweenness kernel (and
	unlike ergm_mcmc.c's stochastic MCMC sampler), this is a
	DETERMINISTIC, exact numerical computation - the native and Mata
	implementations of the same log-likelihood/gradient formula on the
	same event data and the same theta must agree EXACTLY (up to
	ordinary floating-point summation-order effects from the
	incremental-vs-colsum reformulation above, not a statistical
	tolerance) - see cscripts/test_nwdynam_native.do.

	WIRE PROTOCOL: one `plugin call' per OUTER OPTIMIZER ITERATION (not
	per event) - see unw_dynam.do's own DynamChoiceEvalNative()/
	DynamRateEvalNative(). Two input frame variables, set up ONCE before
	the optimizer loop begins and read fresh on every call (a plugin
	invocation carries no state across calls, same as nwgraph.c's own
	convention - the per-call CSR/tie-matrix rebuild is a real, accepted
	cost, small next to the loop it feeds and tiny next to Mata's own
	per-operation interpreter overhead this whole native path exists to
	avoid): v1=sender, v2=receiver (nevents rows, 1-indexed actor IDs,
	in chronological order - the CALLER is responsible for sorting, this
	file does not re-sort). One output frame variable (v3), used to
	return a small fixed-shape result: row 1 = log-likelihood, rows
	2..(nparams+1) = the analytic gradient, in the same effect order
	unw_dynam.do's own theta vectors use (choice: inertia, recip, indeg;
	rate: indeg, outdeg). Args string: "algcode n nevents theta1
	[theta2 [theta3]]" (theta values passed as text, since they are few
	in number and change on every call - cheaper than a frame column
	round-trip for 2-3 numbers).
*/

#include "stplugin.h"
#include <stdlib.h>
#include <string.h>
#include <math.h>

#define ALG_DYNAM_CHOICE 1
#define ALG_DYNAM_RATE 2

/* ===================================================================
   Choice sub-model: inertia + recip + indeg(alter). Direct port of
   dynam_choice_loglik_grad_unit1() (unw_dynam.do), with indeg tracked
   incrementally (see this file's own header) instead of a fresh
   colsum() every event.
   =================================================================== */

static int dynam_choice_loglik_grad(long n, long nevents, long *sender, long *receiver,
		double theta1, double theta2, double theta3,
		double *out_ll, double out_grad[3]) {
	char *tie = NULL;      /* n x n, 0/1, row-major: tie[(s-1)*n + (j-1)] */
	double *indeg = NULL;  /* n, running in-degree (distinct senders so far) */
	double *lp = NULL, *P = NULL;
	long i, j, s, r;
	double ll = 0.0, grad1 = 0.0, grad2 = 0.0, grad3 = 0.0;
	double mx, sumP, lrsum, inertia_r, recip_r, indeg_r;
	int rc = 0;

	tie = (char *)calloc((size_t)n * (size_t)n, sizeof(char));
	indeg = (double *)calloc((size_t)n, sizeof(double));
	lp = (double *)malloc((size_t)n * sizeof(double));
	P = (double *)malloc((size_t)n * sizeof(double));
	if (!tie || !indeg || !lp || !P) { rc = 909; goto cleanup; }

	for (i = 0; i < nevents; i++) {
		s = sender[i];
		r = receiver[i];

		mx = -1e300;
		for (j = 1; j <= n; j++) {
			if (j == s) { lp[j - 1] = -1e300; continue; }
			{
				double inertia_j = tie[(s - 1) * n + (j - 1)] ? 1.0 : 0.0;
				double recip_j = tie[(j - 1) * n + (s - 1)] ? 1.0 : 0.0;
				double indeg_j = indeg[j - 1];
				lp[j - 1] = theta1 * inertia_j + theta2 * recip_j + theta3 * indeg_j;
			}
			if (lp[j - 1] > mx) mx = lp[j - 1];
		}

		sumP = 0.0;
		for (j = 1; j <= n; j++) {
			P[j - 1] = exp(lp[j - 1] - mx);
			sumP += P[j - 1];
		}
		lrsum = mx + log(sumP);
		ll += (lp[r - 1] - lrsum);

		{
			double sum_inertia_P = 0.0, sum_recip_P = 0.0, sum_indeg_P = 0.0;
			for (j = 1; j <= n; j++) {
				double pj = P[j - 1] / sumP;
				double inertia_j = (j == s) ? 0.0 : (tie[(s - 1) * n + (j - 1)] ? 1.0 : 0.0);
				double recip_j = (j == s) ? 0.0 : (tie[(j - 1) * n + (s - 1)] ? 1.0 : 0.0);
				double indeg_j = (j == s) ? 0.0 : indeg[j - 1];
				sum_inertia_P += inertia_j * pj;
				sum_recip_P += recip_j * pj;
				sum_indeg_P += indeg_j * pj;
			}
			inertia_r = tie[(s - 1) * n + (r - 1)] ? 1.0 : 0.0;
			recip_r = tie[(r - 1) * n + (s - 1)] ? 1.0 : 0.0;
			indeg_r = indeg[r - 1];
			grad1 += (inertia_r - sum_inertia_P);
			grad2 += (recip_r - sum_recip_P);
			grad3 += (indeg_r - sum_indeg_P);
		}

		if (!tie[(s - 1) * n + (r - 1)]) {
			tie[(s - 1) * n + (r - 1)] = 1;
			indeg[r - 1] += 1.0;
		}
	}

	*out_ll = ll;
	out_grad[0] = grad1;
	out_grad[1] = grad2;
	out_grad[2] = grad3;

cleanup:
	free(tie);
	free(indeg);
	free(lp);
	free(P);
	return rc;
}

/* ===================================================================
   Rate sub-model (no intercept): indeg + outdeg, both ego type. Direct
   port of dynam_rate_loglik_grad_unit1() (unw_dynam.do) - risk set is
   ALL n actors (no self-exclusion; the realized sender IS one of the n
   candidates, unlike the choice sub-model's n-1). Both indeg and
   outdeg tracked incrementally throughout, same reasoning as the
   choice kernel above.
   =================================================================== */

static int dynam_rate_loglik_grad(long n, long nevents, long *sender, long *receiver,
		double theta1, double theta2,
		double *out_ll, double out_grad[2]) {
	char *tie = NULL;
	double *indeg = NULL, *outdeg = NULL;
	double *lp = NULL, *P = NULL;
	long i, j, s, r;
	double ll = 0.0, grad1 = 0.0, grad2 = 0.0;
	double mx, sumP, lrsum;
	int rc = 0;

	tie = (char *)calloc((size_t)n * (size_t)n, sizeof(char));
	indeg = (double *)calloc((size_t)n, sizeof(double));
	outdeg = (double *)calloc((size_t)n, sizeof(double));
	lp = (double *)malloc((size_t)n * sizeof(double));
	P = (double *)malloc((size_t)n * sizeof(double));
	if (!tie || !indeg || !outdeg || !lp || !P) { rc = 909; goto cleanup; }

	for (i = 0; i < nevents; i++) {
		s = sender[i];
		r = receiver[i];

		mx = -1e300;
		for (j = 1; j <= n; j++) {
			lp[j - 1] = theta1 * indeg[j - 1] + theta2 * outdeg[j - 1];
			if (lp[j - 1] > mx) mx = lp[j - 1];
		}

		sumP = 0.0;
		for (j = 1; j <= n; j++) {
			P[j - 1] = exp(lp[j - 1] - mx);
			sumP += P[j - 1];
		}
		lrsum = mx + log(sumP);
		ll += (lp[s - 1] - lrsum);

		{
			double sum_indeg_P = 0.0, sum_outdeg_P = 0.0;
			for (j = 1; j <= n; j++) {
				double pj = P[j - 1] / sumP;
				sum_indeg_P += indeg[j - 1] * pj;
				sum_outdeg_P += outdeg[j - 1] * pj;
			}
			grad1 += (indeg[s - 1] - sum_indeg_P);
			grad2 += (outdeg[s - 1] - sum_outdeg_P);
		}

		if (!tie[(s - 1) * n + (r - 1)]) {
			tie[(s - 1) * n + (r - 1)] = 1;
			indeg[r - 1] += 1.0;
			outdeg[s - 1] += 1.0;
		}
	}

	*out_ll = ll;
	out_grad[0] = grad1;
	out_grad[1] = grad2;

cleanup:
	free(tie);
	free(indeg);
	free(outdeg);
	free(lp);
	free(P);
	return rc;
}

/* ===================================================================
   Plugin entry point
   =================================================================== */

static double next_double(void) {
	return atof(strtok(NULL, " \t"));
}

STDLL stata_call(int argc, char *argv[]) {
	char *argbuf;
	long algcode, n, nevents, i;
	double theta1 = 0.0, theta2 = 0.0, theta3 = 0.0;
	long *sender = NULL, *receiver = NULL;
	double ll = 0.0, grad[3];
	int rc = 0;

	if (argc < 1) { SF_error("dynam_sim: missing argument string\n"); return(198); }

	argbuf = (char *)malloc(strlen(argv[0]) + 1);
	strcpy(argbuf, argv[0]);
	algcode = (long)atof(strtok(argbuf, " \t"));
	n       = (long)next_double();
	nevents = (long)next_double();
	theta1  = next_double();
	if (algcode == ALG_DYNAM_CHOICE) {
		theta2 = next_double();
		theta3 = next_double();
	}
	else if (algcode == ALG_DYNAM_RATE) {
		theta2 = next_double();
	}
	free(argbuf);

	if (nevents > 0) {
		sender = (long *)malloc((size_t)nevents * sizeof(long));
		receiver = (long *)malloc((size_t)nevents * sizeof(long));
		for (i = 0; i < nevents; i++) {
			ST_double v;
			SF_vdata(1, i + 1, &v); sender[i] = (long)v;
			SF_vdata(2, i + 1, &v); receiver[i] = (long)v;
		}
	}

	switch (algcode) {
		case ALG_DYNAM_CHOICE:
			rc = dynam_choice_loglik_grad(n, nevents, sender, receiver, theta1, theta2, theta3, &ll, grad);
			if (rc == 0) {
				SF_vstore(3, 1, ll);
				SF_vstore(3, 2, grad[0]);
				SF_vstore(3, 3, grad[1]);
				SF_vstore(3, 4, grad[2]);
			}
			break;
		case ALG_DYNAM_RATE:
			rc = dynam_rate_loglik_grad(n, nevents, sender, receiver, theta1, theta2, &ll, grad);
			if (rc == 0) {
				SF_vstore(3, 1, ll);
				SF_vstore(3, 2, grad[0]);
				SF_vstore(3, 3, grad[1]);
			}
			break;
		default:
			SF_error("dynam_sim: unknown algorithm code\n");
			rc = 198;
	}

	free(sender);
	free(receiver);
	return rc;
}
