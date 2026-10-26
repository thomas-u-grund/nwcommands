/*
	test_kernels.c -- Stata-free test harness for the native kernels of nwcommands (core).

	It compiles native/nwgraph.c (the whole plugin) against a stand-in for Stata's plugin interface
	(stub/stplugin.h) and calls stata_call() exactly as Stata does: an argument string, ties in the
	columns v1..v3, node values in v4, results in static memory fetched with algorithm 99.  So the
	code under test is the shipped code, not a copy.

	What it checks (PASS / FAIL per line, exit status 1 if anything fails, 2 if a fixture is missing):
	  golden    fixtures/golden.txt: inputs and results recorded from the macOS plugin through Stata
	            (made by tools/make_golden_fixtures.do); every kernel, bit for bit for integer results,
	            1e-9 relative for floating-point results
	  igraph    fixtures made with R (igraph, bmotif) that the Stata cscripts also use, read from
	            ../cscripts: weighted PageRank, weighted betweenness, maximum-weight matching, weighted
	            Burt measures, bipartite motif positions
	  analytic  small graphs with textbook answers (star, path, ring, complete graph), and properties
	            that must hold for any input (Barber's Q of the Louvain result, degree-preserving swaps)
	  large     sparse graphs of 20,000 to 100,000 nodes with known answers, where products and sums
	            exceed 2^31 (a 32-bit `long' wraps there; see nwtypes.h).  Switch off with --small.

	It does NOT test Stata's plugin interface (SF_vdata and friends on Windows or Linux), the ado and
	Mata layers, the dialogs or the GUI.

	Build (from the repository root):
	  cc -O2 -I native/test/stub -I native native/test/test_kernels.c -o test_kernels -lm
	  cl /O2 /I native\test\stub /I native native\test\test_kernels.c         (MSVC)
	Run (from the repository root):
	  ./test_kernels [--small] [--stress N] [--only substring] [--fixtures dir] [--cscripts dir]

	This file uses only int, int64_t, size_t and double (never plain `long'), so that the same harness can be
	compiled against the old sources with -Dlong=int to emulate the 32-bit long of MSVC.
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include <stdint.h>
#include <stddef.h>
#include <stdarg.h>
#include <ctype.h>
#include <errno.h>
#include <limits.h>

#include "stplugin.h"

#ifdef NW_EMULATE_LONG32
#define long int
#endif

#include "../nwgraph.c"

#ifdef NW_EMULATE_LONG32
#undef long
#endif

/* ================================================================== */
/* stand-in for the plugin interface                                    */
/* ================================================================== */

#define MAXVAR 200
static double *T_col[MAXVAR + 1];
static int64_t T_rows = 0;
static int T_oob = 0;

#define MAXSCAL 64
static char T_sname[MAXSCAL][48];
static double T_sval[MAXSCAL];
static int T_ns = 0;

static void t_store_reset(int64_t rows) {
	int i;
	for (i = 0; i <= MAXVAR; i++) { free(T_col[i]); T_col[i] = NULL; }
	T_rows = rows;
	T_oob = 0;
}

static double *t_col(int i) {
	if (i < 1 || i > MAXVAR) return NULL;
	if (!T_col[i]) {
		int64_t k;
		T_col[i] = (double *)malloc((size_t)(T_rows > 0 ? T_rows : 1) * sizeof(double));
		if (!T_col[i]) { fprintf(stderr, "harness: out of memory\n"); exit(3); }
		for (k = 0; k < T_rows; k++) T_col[i][k] = SV_missval;
	}
	return T_col[i];
}

ST_retcode nwt_vdata(ST_int i, ST_int j, ST_double *d) {
	double *c = t_col(i);
	if (!c || j < 1 || (int64_t)j > T_rows) { T_oob++; return 3300; }
	*d = c[j - 1];
	return 0;
}

ST_retcode nwt_vstore(ST_int i, ST_int j, ST_double v) {
	double *c = t_col(i);
	if (!c || j < 1 || (int64_t)j > T_rows) { T_oob++; return 3300; }
	c[j - 1] = v;
	return 0;
}

ST_retcode nwt_scal_save(char *name, ST_double v) {
	int k;
	for (k = 0; k < T_ns; k++) if (strcmp(T_sname[k], name) == 0) { T_sval[k] = v; return 0; }
	if (T_ns >= MAXSCAL) return 1;
	strncpy(T_sname[T_ns], name, 47); T_sname[T_ns][47] = 0;
	T_sval[T_ns++] = v;
	return 0;
}

ST_retcode nwt_message(const char *s) {
	fprintf(stderr, "plugin message: %s", s);
	return 0;
}

static int t_scal(const char *name, double *v) {
	int k;
	for (k = 0; k < T_ns; k++) if (strcmp(T_sname[k], name) == 0) { *v = T_sval[k]; return 1; }
	return 0;
}

static void t_scal_clear(void) { T_ns = 0; }

/* ================================================================== */
/* reporting and comparison                                              */
/* ================================================================== */

static int g_pass = 0, g_fail = 0, g_skip = 0;
static const char *g_only = NULL;
static int g_small = 0;
static const char *g_fixdir = "native/test/fixtures";
static const char *g_csdir = "cscripts";
static int g_missing_fixture = 0;
static int g_stress = 0;

static int selected(const char *name) { return !g_only || strstr(name, g_only) != NULL; }

static void result(const char *name, int ok, const char *fmt, ...) {
	va_list ap;
	char msg[400];
	va_start(ap, fmt);
	vsnprintf(msg, sizeof msg, fmt, ap);
	va_end(ap);
	if (ok) { g_pass++; printf("PASS %s%s%s\n", name, msg[0] ? "  " : "", msg); }
	else { g_fail++; printf("FAIL %s  %s\n", name, msg); }
	fflush(stdout);
}

static int is_miss(double x) { return x != x || x >= 8.9e307; }

/* tol == 0: exact (both missing also equal); tol > 0: |a-b| <= tol * max(1, |b|) */
static int close_enough(double a, double b, double tol) {
	double d;
	if (is_miss(a) || is_miss(b)) return is_miss(a) && is_miss(b);
	if (tol < 0) return 1;
	if (tol == 0) return a == b;
	d = fabs(a - b);
	return d <= tol * (fabs(b) > 1.0 ? fabs(b) : 1.0);
}

static double now_s(void) { return (double)clock() / (double)CLOCKS_PER_SEC; }

/* ================================================================== */
/* calling a kernel                                                       */
/* ================================================================== */

/* one plugin call with the argument string; returns the plugin's return code */
static int call_plugin(const char *args) {
	char *argv[1];
	char *copy = (char *)malloc(strlen(args) + 1);
	int rc;
	strcpy(copy, args);
	argv[0] = copy;
	rc = (int)stata_call(1, argv);
	free(copy);
	return rc;
}

typedef struct {
	int rc;
	int status;
	int64_t rows, cols;
	double *res;      /* rows x cols, row-major; NULL if none */
	double a[5];      /* published a1..a4 (index 1..4), missing if not published */
} kres_t;

static void kres_free(kres_t *r) { free(r->res); r->res = NULL; }

/*
	Run one combinatorial kernel (algorithms 3..50): ties (ei, ej, ew) 1-based, nv = node values (or NULL),
	par = the parameters after nties as text ("" for none).
*/
static kres_t run_comb(int alg, int64_t n, int64_t m, const int64_t *ei, const int64_t *ej, const double *ew,
		const double *nv, const char *par) {
	kres_t r;
	char args[512];
	int64_t k, rows;
	double v;
	int c;

	memset(&r, 0, sizeof r);
	for (c = 0; c < 5; c++) r.a[c] = SV_missval;
	rows = n > m ? n : m;
	if (rows < 3) rows = 3;
	t_store_reset(rows);
	t_scal_clear();
	for (k = 0; k < m; k++) {
		t_col(1)[k] = (double)ei[k];
		t_col(2)[k] = (double)ej[k];
		t_col(3)[k] = ew ? ew[k] : 1.0;
	}
	if (nv) for (k = 0; k < n; k++) t_col(4)[k] = nv[k];
	snprintf(args, sizeof args, "%d %lld %lld %s", alg, (long long)n, (long long)m, par ? par : "");
	r.rc = call_plugin(args);
	r.status = t_scal("__nwg_status", &v) ? (int)v : -1;
	for (c = 1; c <= 4; c++) {
		char nm[16];
		snprintf(nm, sizeof nm, "__nwg_a%d", c);
		if (t_scal(nm, &v)) r.a[c] = v;
	}
	if (r.rc == 0 && r.status == 0 && t_scal("__nwg_rows", &v)) {
		r.rows = (int64_t)v;
		if (t_scal("__nwg_cols", &v)) r.cols = (int64_t)v;
		if (r.rows > 0 && r.cols > 0) {
			int64_t row;
			char fa[64];
			if (4 + r.cols > MAXVAR) { r.rc = -2; return r; }
			if (r.rows > T_rows) {
				/* the Mata caller adds observations before the FETCH call */
				int64_t old = T_rows;
				int i;
				for (i = 1; i <= MAXVAR; i++) if (T_col[i]) {
					int64_t q;
					T_col[i] = (double *)realloc(T_col[i], (size_t)r.rows * sizeof(double));
					for (q = old; q < r.rows; q++) T_col[i][q] = SV_missval;
				}
				T_rows = r.rows;
			}
			snprintf(fa, sizeof fa, "99 0 0 %lld", (long long)r.cols);
			if (call_plugin(fa) != 0) { r.rc = -3; return r; }
			r.res = (double *)malloc((size_t)r.rows * (size_t)r.cols * sizeof(double));
			for (row = 0; row < r.rows; row++)
				for (c = 0; c < (int)r.cols; c++) r.res[row * r.cols + c] = t_col(5 + c)[row];
		}
	}
	return r;
}

/* ================================================================== */
/* graph builders                                                         */
/* ================================================================== */

typedef struct { int64_t n, m; int64_t *ei, *ej; double *ew; } graph_t;

static void g_free(graph_t *g) { free(g->ei); free(g->ej); free(g->ew); memset(g, 0, sizeof *g); }

static void g_reserve(graph_t *g, int64_t cap) {
	g->ei = (int64_t *)malloc((size_t)cap * sizeof(int64_t));
	g->ej = (int64_t *)malloc((size_t)cap * sizeof(int64_t));
	g->ew = (double *)malloc((size_t)cap * sizeof(double));
	if (!g->ei || !g->ej || !g->ew) { fprintf(stderr, "harness: out of memory\n"); exit(3); }
}

static void g_arc(graph_t *g, int64_t i, int64_t j, double w) { g->ei[g->m] = i; g->ej[g->m] = j; g->ew[g->m] = w; g->m++; }
static void g_edge(graph_t *g, int64_t i, int64_t j) { g_arc(g, i, j, 1.0); g_arc(g, j, i, 1.0); }

static graph_t g_star(int64_t n) { graph_t g; int64_t k; memset(&g, 0, sizeof g); g.n = n; g_reserve(&g, 2 * (n - 1) + 1); for (k = 2; k <= n; k++) g_edge(&g, 1, k); return g; }
static graph_t g_path(int64_t n) { graph_t g; int64_t k; memset(&g, 0, sizeof g); g.n = n; g_reserve(&g, 2 * (n - 1) + 1); for (k = 1; k < n; k++) g_edge(&g, k, k + 1); return g; }
static graph_t g_ring(int64_t n) { graph_t g; int64_t k; memset(&g, 0, sizeof g); g.n = n; g_reserve(&g, 2 * n + 1); for (k = 1; k < n; k++) g_edge(&g, k, k + 1); g_edge(&g, n, 1); return g; }
static graph_t g_complete(int64_t n) { graph_t g; int64_t i, j; memset(&g, 0, sizeof g); g.n = n; g_reserve(&g, n * (n - 1) + 1); for (i = 1; i <= n; i++) for (j = 1; j <= n; j++) if (i != j) g_arc(&g, i, j, 1.0); return g; }
static graph_t g_empty(int64_t n) { graph_t g; memset(&g, 0, sizeof g); g.n = n; g_reserve(&g, 1); return g; }
/* directed cycle 1 -> 2 -> ... -> n -> 1 */
static graph_t g_dcycle(int64_t n) { graph_t g; int64_t k; memset(&g, 0, sizeof g); g.n = n; g_reserve(&g, n + 1); for (k = 1; k <= n; k++) g_arc(&g, k, k % n + 1, 1.0); return g; }

/* generator used for the property tests: SplitMix64 */
static uint64_t g_seed = 88172645463325252ULL;
static uint64_t rnd64(void) {
	uint64_t z = (g_seed += 0x9E3779B97F4A7C15ULL);
	z = (z ^ (z >> 30)) * 0xBF58476D1CE4E5B9ULL;
	z = (z ^ (z >> 27)) * 0x94D049BB133111EBULL;
	return z ^ (z >> 31);
}
static double rndu(void) { return (double)(rnd64() >> 11) / 9007199254740992.0; }

/* ================================================================== */
/* golden fixtures                                                        */
/* ================================================================== */

static char *slurp(const char *path, size_t *len) {
	FILE *f = fopen(path, "rb");
	char *b;
	long long sz;
	if (!f) return NULL;
	fseek(f, 0, SEEK_END);
	sz = (long long)ftell(f);
	fseek(f, 0, SEEK_SET);
	b = (char *)malloc((size_t)sz + 1);
	if (!b) { fclose(f); return NULL; }
	if (fread(b, 1, (size_t)sz, f) != (size_t)sz) { free(b); fclose(f); return NULL; }
	b[sz] = 0;
	fclose(f);
	if (len) *len = (size_t)sz;
	return b;
}

static char *g_p;   /* parse pointer */

static char *tok(void) {
	static char buf[256];
	size_t k = 0;
	while (*g_p && isspace((unsigned char)*g_p)) g_p++;
	if (!*g_p) return NULL;
	while (*g_p && !isspace((unsigned char)*g_p) && k < sizeof buf - 1) buf[k++] = *g_p++;
	buf[k] = 0;
	return buf;
}

static double parse_num(const char *s) {
	if (strcmp(s, ".") == 0 || strcmp(s, "NA") == 0 || strcmp(s, "nan") == 0 || strcmp(s, "NaN") == 0) return SV_missval;
	return strtod(s, NULL);
}

static double tnum(void) { char *t = tok(); return t ? parse_num(t) : SV_missval; }

typedef struct { int idx; int64_t n; double *x; } gvar_t;

static void run_golden(const char *path) {
	size_t len;
	char *buf = slurp(path, &len);
	int ncase = 0;
	if (!buf) { printf("FAIL golden  cannot read %s\n", path); g_fail++; g_missing_fixture = 1; return; }
	g_p = buf;
	for (;;) {
		char *t = tok();
		char name[100] = "", args[300] = "";
		gvar_t vars[16];
		int nv = 0, i, ok = 1, nxs = 0, nxv = 0, have_xr = 0;
		struct { char nm[48]; double v, tol; } xs[16];
		struct { int idx; int64_t n; double tol; double *x; } xv[8];
		int64_t xr_rows = 0, xr_cols = 0;
		double *xr = NULL, xr_tol[200];
		char why[300] = "";
		double t0;
		int rc;
		int64_t nobs, n_arg = 0;
		if (!t) break;
		if (strcmp(t, "case") != 0) { printf("FAIL golden  bad fixture file near '%s'\n", t); g_fail++; break; }
		strncpy(name, tok(), sizeof name - 1);
		/* args: rest of line */
		{
			char *q;
			t = tok();                       /* "args" */
			while (*g_p == ' ') g_p++;
			q = g_p;
			while (*g_p && *g_p != '\n') g_p++;
			{ size_t L = (size_t)(g_p - q); if (L > sizeof args - 1) L = sizeof args - 1; memcpy(args, q, L); args[L] = 0; }
			{ int ac = 0; double a1, a2, a3; ac = sscanf(args, "%lf %lf %lf", &a1, &a2, &a3); if (ac >= 2) n_arg = (int64_t)a2; }
		}
		for (;;) {
			t = tok();
			if (!t || strcmp(t, "end") == 0) break;
			if (strcmp(t, "var") == 0) {
				int64_t k;
				vars[nv].idx = (int)tnum();
				vars[nv].n = (int64_t)tnum();
				vars[nv].x = (double *)malloc((size_t)(vars[nv].n > 0 ? vars[nv].n : 1) * sizeof(double));
				for (k = 0; k < vars[nv].n; k++) vars[nv].x[k] = tnum();
				nv++;
			} else if (strcmp(t, "xs") == 0) {
				strncpy(xs[nxs].nm, tok(), 47); xs[nxs].nm[47] = 0;
				xs[nxs].v = tnum(); xs[nxs].tol = tnum(); nxs++;
			} else if (strcmp(t, "xv") == 0) {
				int64_t k;
				xv[nxv].idx = (int)tnum();
				xv[nxv].n = (int64_t)tnum();
				xv[nxv].tol = tnum();
				xv[nxv].x = (double *)malloc((size_t)(xv[nxv].n > 0 ? xv[nxv].n : 1) * sizeof(double));
				for (k = 0; k < xv[nxv].n; k++) xv[nxv].x[k] = tnum();
				nxv++;
			} else if (strcmp(t, "xr") == 0) {
				int64_t k;
				int c;
				have_xr = 1;
				xr_rows = (int64_t)tnum();
				xr_cols = (int64_t)tnum();
				for (c = 0; c < xr_cols && c < 200; c++) xr_tol[c] = tnum();
				xr = (double *)malloc((size_t)(xr_rows * xr_cols) * sizeof(double));
				for (k = 0; k < xr_rows * xr_cols; k++) xr[k] = tnum();
			} else { printf("FAIL golden %s  unknown record '%s'\n", name, t); ok = 0; break; }
		}
		ncase++;
		if (g_only && !strstr(name, g_only) && !strstr("golden", g_only)) { for (i = 0; i < nv; i++) free(vars[i].x); for (i = 0; i < nxv; i++) free(xv[i].x); free(xr); continue; }
		/* build the store */
		nobs = 3;
		if (n_arg > nobs) nobs = n_arg;
		for (i = 0; i < nv; i++) if (vars[i].n > nobs) nobs = vars[i].n;
		for (i = 0; i < nxv; i++) if (xv[i].n > nobs) nobs = xv[i].n;
		if (xr_rows > nobs) nobs = xr_rows;
		t_store_reset(nobs);
		t_scal_clear();
		for (i = 0; i < nv; i++) { int64_t k; for (k = 0; k < vars[i].n; k++) t_col(vars[i].idx)[k] = vars[i].x[k]; }
		t0 = now_s();
		rc = call_plugin(args);
		if (rc != 0) { ok = 0; snprintf(why, sizeof why, "plugin returned %d", rc); }
		if (T_oob) { ok = 0; snprintf(why, sizeof why, "%d out-of-range variable accesses", T_oob); }
		for (i = 0; ok && i < nxs; i++) {
			double v;
			if (!t_scal(xs[i].nm, &v)) { ok = 0; snprintf(why, sizeof why, "scalar %s not set", xs[i].nm); }
			else if (!close_enough(v, xs[i].v, xs[i].tol)) { ok = 0; snprintf(why, sizeof why, "scalar %s = %.17g, expected %.17g", xs[i].nm, v, xs[i].v); }
		}
		for (i = 0; ok && i < nxv; i++) {
			int64_t k;
			for (k = 0; k < xv[i].n; k++) {
				double v = t_col(xv[i].idx)[k];
				if (!close_enough(v, xv[i].x[k], xv[i].tol)) { ok = 0; snprintf(why, sizeof why, "variable %d row %lld = %.17g, expected %.17g", xv[i].idx, (long long)k + 1, v, xv[i].x[k]); break; }
			}
		}
		if (ok && have_xr) {
			double vr = 0, vc = 0;
			int64_t row;
			int c;
			char fa[64];
			if (!t_scal("__nwg_rows", &vr) || !t_scal("__nwg_cols", &vc) || (int64_t)vr != xr_rows || (int64_t)vc != xr_cols) {
				ok = 0; snprintf(why, sizeof why, "result is %g x %g, expected %lld x %lld", vr, vc, (long long)xr_rows, (long long)xr_cols);
			} else {
				snprintf(fa, sizeof fa, "99 0 0 %lld", (long long)xr_cols);
				if (call_plugin(fa) != 0) { ok = 0; snprintf(why, sizeof why, "FETCH failed"); }
				for (row = 0; ok && row < xr_rows; row++)
					for (c = 0; c < xr_cols; c++) {
						double v = t_col(5 + c)[row], e = xr[row * xr_cols + c];
						if (!close_enough(v, e, xr_tol[c])) { ok = 0; snprintf(why, sizeof why, "result[%lld,%d] = %.17g, expected %.17g", (long long)row + 1, c + 1, v, e); break; }
					}
			}
		}
		if (ok) result(name, 1, "(%.3fs)", now_s() - t0);
		else result(name, 0, "%s", why);
		for (i = 0; i < nv; i++) free(vars[i].x);
		for (i = 0; i < nxv; i++) free(xv[i].x);
		free(xr);
	}
	res_clear();
	free(buf);
	if (ncase == 0) { printf("FAIL golden  no cases in %s\n", path); g_fail++; }
}

/* ================================================================== */
/* fixtures made with R (igraph, bmotif), shared with the Stata cscripts */
/* ================================================================== */

#define CSV_MAXC 160
typedef struct { int nc; int64_t nr; char names[CSV_MAXC][24]; double *v; } csv_t;

static int csv_load(const char *path, csv_t *c) {
	char *buf = slurp(path, NULL), *p, *line;
	int64_t cap = 1024;
	memset(c, 0, sizeof *c);
	if (!buf) return 1;
	c->v = (double *)malloc((size_t)cap * CSV_MAXC * sizeof(double));
	p = buf;
	/* header */
	line = p; while (*p && *p != '\n') p++;
	{
		char *q = line, *e = p; int k = 0;
		while (q < e && k < CSV_MAXC) {
			size_t L = 0;
			while (q < e && *q != ',') { if (*q != '"' && *q != '\r' && L < 23) c->names[k][L++] = *q; q++; }
			c->names[k][L] = 0; k++;
			if (q < e) q++;
		}
		c->nc = k;
	}
	if (*p) p++;
	while (*p) {
		char *e = p; int k = 0;
		while (*e && *e != '\n') e++;
		if (e == p) { p = e + (*e ? 1 : 0); continue; }
		if (c->nr >= cap) { cap *= 2; c->v = (double *)realloc(c->v, (size_t)cap * CSV_MAXC * sizeof(double)); }
		{
			char *q = p;
			while (q < e && k < c->nc) {
				char fld[64]; size_t L = 0;
				while (q < e && *q != ',') { if (*q != '"' && *q != '\r' && L < 63) fld[L++] = *q; q++; }
				fld[L] = 0;
				c->v[c->nr * CSV_MAXC + k] = (L == 0) ? SV_missval : parse_num(fld);
				k++;
				if (q < e) q++;
			}
		}
		c->nr++;
		p = e + (*e ? 1 : 0);
	}
	free(buf);
	return 0;
}

static int csv_col(const csv_t *c, const char *nm) { int k; for (k = 0; k < c->nc; k++) if (strcmp(c->names[k], nm) == 0) return k; return -1; }
static double csv_at(const csv_t *c, int64_t r, int k) { return c->v[r * CSV_MAXC + k]; }
static void csv_free(csv_t *c) { free(c->v); c->v = NULL; }

static int path_join(char *out, size_t cap, const char *a, const char *b, const char *c) {
	snprintf(out, cap, "%s/%s/%s", a, b, c);
	return 0;
}

typedef struct { int64_t i, j, ord; double w; } arc_t;

static int cmp_arc(const void *a, const void *b) {
	const arc_t *x = (const arc_t *)a, *y = (const arc_t *)b;
	if (x->i != y->i) return x->i < y->i ? -1 : 1;
	if (x->j != y->j) return x->j < y->j ? -1 : 1;
	if (x->ord != y->ord) return x->ord < y->ord ? -1 : 1;
	return 0;
}

/*
	Arcs of network `net' of a cells table (columns net, i, j [, w]), as edgelist() hands them to a kernel: sorted by
	(i, j); an undirected network gets both directions; a pair given twice keeps its last value.
*/
static int64_t ext_arcs(const csv_t *cells, int cnet, int ci, int cj, int cw, int net, int directed, graph_t *g) {
	int64_t r, m = 0, q = 0, o = 0;
	arc_t *a;
	for (r = 0; r < cells->nr; r++) if ((int)csv_at(cells, r, cnet) == net) m++;
	a = (arc_t *)malloc((size_t)(2 * m + 1) * sizeof(arc_t));
	for (r = 0; r < cells->nr; r++) {
		int64_t i, j;
		double w;
		if ((int)csv_at(cells, r, cnet) != net) continue;
		i = (int64_t)csv_at(cells, r, ci); j = (int64_t)csv_at(cells, r, cj);
		w = cw >= 0 ? csv_at(cells, r, cw) : 1.0;
		a[q].i = i; a[q].j = j; a[q].ord = q; a[q].w = w; q++;
		if (!directed && i != j) { a[q].i = j; a[q].j = i; a[q].ord = q; a[q].w = w; q++; }
	}
	qsort(a, (size_t)q, sizeof(arc_t), cmp_arc);
	memset(g, 0, sizeof *g);
	g_reserve(g, q + 1);
	for (r = 0; r < q; r++) {
		if (r + 1 < q && a[r + 1].i == a[r].i && a[r + 1].j == a[r].j) continue;   /* the last copy wins */
		g_arc(g, a[r].i, a[r].j, a[r].w);
		o++;
	}
	free(a);
	return o;
}

static void test_ext_pagerankw(void) {
	char p1[512], p2[512], p3[512];
	csv_t cells, nets, ex;
	int net, nnets, worst_net = 0;
	double worst = 0;
	int ok = 1;
	if (!selected("pagerankw_igraph")) return;
	path_join(p1, sizeof p1, g_csdir, "native370_fixture", "pr_cells.csv");
	path_join(p2, sizeof p2, g_csdir, "native370_fixture", "pr_nets.csv");
	path_join(p3, sizeof p3, g_csdir, "native370_fixture", "pr_expected.csv");
	if (csv_load(p1, &cells) || csv_load(p2, &nets) || csv_load(p3, &ex)) { printf("FAIL pagerankw_igraph  fixture missing under %s\n", g_csdir); g_fail++; g_missing_fixture = 1; return; }
	nnets = (int)nets.nr;
	for (net = 1; net <= nnets && ok; net++) {
		graph_t g; kres_t r;
		int64_t n = (int64_t)csv_at(&nets, net - 1, csv_col(&nets, "n"));
		int dir = (int)csv_at(&nets, net - 1, csv_col(&nets, "directed"));
		int64_t k, row;
		ext_arcs(&cells, csv_col(&cells, "net"), csv_col(&cells, "i"), csv_col(&cells, "j"), csv_col(&cells, "w"), net, dir, &g);
		r = run_comb(44, n, g.m, g.ei, g.ej, g.ew, NULL, "0.85 20000 1e-14");
		if (r.rc != 0 || r.status != 0 || r.rows != n) { ok = 0; printf("FAIL pagerankw_igraph  net %d: rc %d status %d\n", net, r.rc, r.status); g_fail++; }
		else {
			for (row = 0; row < ex.nr; row++) {
				if ((int)csv_at(&ex, row, csv_col(&ex, "net")) != net) continue;
				k = (int64_t)csv_at(&ex, row, csv_col(&ex, "node")) - 1;
				{ double d = fabs(r.res[k] - csv_at(&ex, row, csv_col(&ex, "pr"))); if (d > worst) { worst = d; worst_net = net; } }
			}
		}
		kres_free(&r); g_free(&g);
	}
	if (ok) result("pagerankw_igraph", worst <= 1e-9, "(%d networks, max |native - igraph| = %.2e, network %d)", nnets, worst, worst_net);
	csv_free(&cells); csv_free(&nets); csv_free(&ex);
}

static void test_ext_betweenw(void) {
	char p1[512], p2[512], p3[512];
	csv_t cells, nets, ex;
	int net, nnets = 0, ok = 1;
	double worst = 0;
	if (!selected("betweenw_igraph")) return;
	path_join(p1, sizeof p1, g_csdir, "native370_fixture", "bt_cells.csv");
	path_join(p2, sizeof p2, g_csdir, "native370_fixture", "bt_nets.csv");
	path_join(p3, sizeof p3, g_csdir, "native370_fixture", "bt_expected.csv");
	if (csv_load(p1, &cells) || csv_load(p2, &nets) || csv_load(p3, &ex)) { printf("FAIL betweenw_igraph  fixture missing under %s\n", g_csdir); g_fail++; g_missing_fixture = 1; return; }
	for (net = 1; net <= (int)nets.nr && ok; net++) {
		graph_t g; kres_t r; char par[64]; int64_t row;
		int64_t n = (int64_t)csv_at(&nets, net - 1, csv_col(&nets, "n"));
		int dir = (int)csv_at(&nets, net - 1, csv_col(&nets, "directed"));
		ext_arcs(&cells, csv_col(&cells, "net"), csv_col(&cells, "i"), csv_col(&cells, "j"), csv_col(&cells, "w"), net, dir, &g);
		snprintf(par, sizeof par, "1 %d", dir);
		r = run_comb(47, n, g.m, g.ei, g.ej, g.ew, NULL, par);
		if (r.rc != 0 || r.status != 0 || r.rows != n) { ok = 0; printf("FAIL betweenw_igraph  net %d: rc %d status %d\n", net, r.rc, r.status); g_fail++; }
		else for (row = 0; row < ex.nr; row++) {
			double e, d;
			if ((int)csv_at(&ex, row, csv_col(&ex, "net")) != net) continue;
			e = csv_at(&ex, row, csv_col(&ex, "bt"));
			d = fabs(r.res[(int64_t)csv_at(&ex, row, csv_col(&ex, "node")) - 1] - e) / (1.0 + fabs(e));
			if (d > worst) worst = d;
		}
		nnets++;
		kres_free(&r); g_free(&g);
	}
	if (ok) result("betweenw_igraph", worst <= 1e-8, "(%d networks, max relative difference to igraph %.2e)", nnets, worst);
	csv_free(&cells); csv_free(&nets); csv_free(&ex);
}

static void test_ext_matchw(void) {
	char p1[512], p2[512], p3[512];
	csv_t cells, nets, ex;
	int net, nnets = 0, ok = 1;
	double worst = 0;
	if (!selected("matchw_igraph")) return;
	path_join(p1, sizeof p1, g_csdir, "native370_fixture", "mt_cells.csv");
	path_join(p2, sizeof p2, g_csdir, "native370_fixture", "mt_nets.csv");
	path_join(p3, sizeof p3, g_csdir, "native370_fixture", "mt_expected.csv");
	if (csv_load(p1, &cells) || csv_load(p2, &nets) || csv_load(p3, &ex)) { printf("FAIL matchw_igraph  fixture missing under %s\n", g_csdir); g_fail++; g_missing_fixture = 1; return; }
	for (net = 1; net <= (int)nets.nr && ok; net++) {
		graph_t g; kres_t r; double *md; int64_t k, i;
		int64_t n1 = (int64_t)csv_at(&nets, net - 1, csv_col(&nets, "n1")), n2 = (int64_t)csv_at(&nets, net - 1, csv_col(&nets, "n2"));
		int64_t n = n1 + n2;
		double total = 0, e = 0;
		ext_arcs(&cells, csv_col(&cells, "net"), csv_col(&cells, "i"), csv_col(&cells, "j"), csv_col(&cells, "w"), net, 0, &g);
		md = (double *)malloc((size_t)n * sizeof(double));
		for (k = 0; k < n; k++) md[k] = k < n1 ? 1.0 : 2.0;
		r = run_comb(45, n, g.m, g.ei, g.ej, g.ew, md, "");
		if (r.rc != 0 || r.status != 0 || r.rows != n) { ok = 0; printf("FAIL matchw_igraph  net %d: rc %d status %d\n", net, r.rc, r.status); g_fail++; }
		else {
			for (i = 1; i <= n1; i++) {
				int64_t p = (int64_t)r.res[i - 1];
				if (p > 0) for (k = 0; k < g.m; k++) if (g.ei[k] == i && g.ej[k] == p) total += g.ew[k];
			}
			for (k = 0; k < ex.nr; k++) if ((int)csv_at(&ex, k, csv_col(&ex, "net")) == net) e = csv_at(&ex, k, csv_col(&ex, "weight"));
			if (fabs(total - e) > worst) worst = fabs(total - e);
		}
		nnets++;
		free(md); kres_free(&r); g_free(&g);
	}
	if (ok) result("matchw_igraph", worst <= 1e-9, "(%d networks, total weight equals igraph::max_bipartite_match, max difference %.2e)", nnets, worst);
	csv_free(&cells); csv_free(&nets); csv_free(&ex);
}

static void test_ext_burtw(void) {
	char p1[512], p2[512], p3[512];
	csv_t cells, nets, ex;
	int net, nnets = 0, ok = 1, nskip = 0;
	double worst = 0;
	if (!selected("burtw_igraph")) return;
	path_join(p1, sizeof p1, g_csdir, "burt_valued_fixture", "cells.csv");
	path_join(p2, sizeof p2, g_csdir, "burt_valued_fixture", "nets.csv");
	path_join(p3, sizeof p3, g_csdir, "burt_valued_fixture", "expected.csv");
	if (csv_load(p1, &cells) || csv_load(p2, &nets) || csv_load(p3, &ex)) { printf("FAIL burtw_igraph  fixture missing under %s\n", g_csdir); g_fail++; g_missing_fixture = 1; return; }
	for (net = 1; net <= (int)nets.nr && ok; net++) {
		graph_t g; kres_t r; int64_t row;
		int64_t n = (int64_t)csv_at(&nets, net - 1, csv_col(&nets, "n"));
		int dir = (int)csv_at(&nets, net - 1, csv_col(&nets, "directed"));
		ext_arcs(&cells, csv_col(&cells, "net"), csv_col(&cells, "i"), csv_col(&cells, "j"), csv_col(&cells, "w"), net, dir, &g);
		r = run_comb(40, n, g.m, g.ei, g.ej, g.ew, NULL, "");
		if (r.rc != 0 || r.status != 0 || r.rows != n || r.cols != 5) { ok = 0; printf("FAIL burtw_igraph  net %d: rc %d status %d\n", net, r.rc, r.status); g_fail++; }
		else for (row = 0; row < ex.nr; row++) {
			static const char *cn[4] = { "es", "eff", "con", "hier" };
			int64_t nd; int c;
			if ((int)csv_at(&ex, row, csv_col(&ex, "net")) != net) continue;
			nd = (int64_t)csv_at(&ex, row, csv_col(&ex, "node")) - 1;
			for (c = 0; c < 4; c++) {
				double e = csv_at(&ex, row, csv_col(&ex, cn[c])), v = r.res[nd * 5 + c];
				if (c == 3 && r.res[nd * 5 + 4] != 0) v = SV_missval;
				if (is_miss(e) || is_miss(v)) { if (is_miss(e) != is_miss(v)) worst = 1; }
				else { double d = fabs(v - e) / (1.0 + fabs(e)); if (d > worst) worst = d; }
			}
		}
		nnets++;
		kres_free(&r); g_free(&g);
	}
	(void)nskip;
	if (ok) result("burtw_igraph", worst <= 1e-9, "(%d networks, max relative difference to the R code %.2e)", nnets, worst);
	csv_free(&cells); csv_free(&nets); csv_free(&ex);
}

static void test_ext_bmotif(void) {
	char p1[512], p2[512], p3[512];
	csv_t cells, nets, pos;
	int net, nnets = 0, ok = 1;
	double t0 = now_s();
	if (!selected("bmotif_positions")) return;
	path_join(p1, sizeof p1, g_csdir, "native380_fixture", "cells.csv");
	path_join(p2, sizeof p2, g_csdir, "native380_fixture", "nets.csv");
	path_join(p3, sizeof p3, g_csdir, "native380_fixture", "pos.csv");
	if (csv_load(p1, &cells) || csv_load(p2, &nets) || csv_load(p3, &pos)) { printf("FAIL bmotif_positions  fixture missing under %s\n", g_csdir); g_fail++; g_missing_fixture = 1; return; }
	for (net = 1; net <= (int)nets.nr && ok; net++) {
		graph_t g; kres_t r; double *md; int64_t k, row, nrow = 0;
		int64_t n1 = (int64_t)csv_at(&nets, net - 1, csv_col(&nets, "n1")), n2 = (int64_t)csv_at(&nets, net - 1, csv_col(&nets, "n2"));
		int six = (int)csv_at(&nets, net - 1, csv_col(&nets, "six"));
		int64_t n = n1 + n2, P = six ? 148 : 46;
		int cn = csv_col(&cells, "net"), ci = csv_col(&cells, "i"), cj = csv_col(&cells, "j");
		int bad = 0;
		memset(&g, 0, sizeof g);
		for (k = 0; k < cells.nr; k++) if ((int)csv_at(&cells, k, cn) == net) nrow++;
		if (nrow > 0) {
			g_reserve(&g, nrow + 1);
			for (k = 0; k < cells.nr; k++) if ((int)csv_at(&cells, k, cn) == net) g_arc(&g, (int64_t)csv_at(&cells, k, ci), n1 + (int64_t)csv_at(&cells, k, cj), 1.0);
		} else if (net != 2 && net != 3) {
			g_reserve(&g, 1);   /* a network without ties */
		} else {
			/* networks 2 (davis) and 3 (ftdirectors_se) are kept in files of their own, without a net column */
			csv_t ec; char pe[512];
			path_join(pe, sizeof pe, g_csdir, "native380_fixture", net == 2 ? "davis_cells.csv" : "ftdirectors_se_cells.csv");
			if (csv_load(pe, &ec)) { ok = 0; printf("FAIL bmotif_positions  cannot read %s\n", pe); g_fail++; g_missing_fixture = 1; break; }
			g_reserve(&g, ec.nr + 1);
			for (k = 0; k < ec.nr; k++) g_arc(&g, (int64_t)csv_at(&ec, k, csv_col(&ec, "i")), n1 + (int64_t)csv_at(&ec, k, csv_col(&ec, "j")), 1.0);
			csv_free(&ec);
		}
		md = (double *)malloc((size_t)n * sizeof(double));
		for (k = 0; k < n; k++) md[k] = k < n1 ? 1.0 : 2.0;
		r = run_comb(50, n, g.m, g.ei, g.ej, g.ew, md, six ? "1" : "0");
		if (r.rc != 0 || r.status != 0 || r.rows != n || r.cols != P) { ok = 0; printf("FAIL bmotif_positions  net %d: rc %d status %d size %lld x %lld\n", net, r.rc, r.status, (long long)r.rows, (long long)r.cols); g_fail++; }
		else for (row = 0; row < pos.nr; row++) {
			int64_t nd; int c;
			if ((int)csv_at(&pos, row, csv_col(&pos, "net")) != net) continue;
			nd = (int64_t)csv_at(&pos, row, csv_col(&pos, "node")) - 1;
			for (c = 0; c < P; c++) {
				char nm[16];
				snprintf(nm, sizeof nm, "np%d", c + 1);
				if (csv_at(&pos, row, csv_col(&pos, nm)) != r.res[nd * P + c]) bad++;
			}
		}
		if (ok && bad) { ok = 0; printf("FAIL bmotif_positions  net %d: %d position counts differ from bmotif\n", net, bad); g_fail++; }
		nnets++;
		free(md); kres_free(&r); g_free(&g);
	}
	if (ok) result("bmotif_positions", 1, "(%d networks, all node-position counts equal to bmotif::node_positions; %.2fs)", nnets, now_s() - t0);
	csv_free(&cells); csv_free(&nets); csv_free(&pos);
}

/* ================================================================== */
/* analytic tests: small graphs with textbook answers                   */
/* ================================================================== */

/* compare got[0..k-1] with exp[0..k-1] */
static void check_vec(const char *name, const double *got, const double *exp, int64_t k, double tol, const char *extra) {
	int64_t i;
	for (i = 0; i < k; i++)
		if (!close_enough(got[i], exp[i], tol)) {
			result(name, 0, "element %lld = %.17g, expected %.17g", (long long)i + 1, got[i], exp[i]);
			return;
		}
	result(name, 1, "%s", extra ? extra : "");
}

static void legacy_call_betw(const char *name, graph_t g, int directed, const double *exp, double tol) {
	char args[128];
	int64_t k, rows = g.n > g.m ? g.n : g.m;
	double *got;
	if (!selected(name)) { g_free(&g); return; }
	if (rows < 3) rows = 3;
	t_store_reset(rows);
	t_scal_clear();
	for (k = 0; k < g.m; k++) { t_col(1)[k] = (double)g.ei[k]; t_col(2)[k] = (double)g.ej[k]; }
	t_col(3);
	snprintf(args, sizeof args, "1 %lld %d %lld", (long long)g.n, directed, (long long)g.m);
	if (call_plugin(args) != 0) { result(name, 0, "plugin returned an error"); g_free(&g); return; }
	got = (double *)malloc((size_t)g.n * sizeof(double));
	for (k = 0; k < g.n; k++) got[k] = t_col(3)[k];
	check_vec(name, got, exp, g.n, tol, NULL);
	free(got); g_free(&g);
}

static void legacy_call_bfs(const char *name, graph_t g, int64_t source, int nblock, const double *exp, double tol) {
	char args[128];
	int64_t k, rows = g.n > g.m ? g.n : g.m;
	int b;
	double *got;
	if (!selected(name)) { g_free(&g); return; }
	if (rows < 3) rows = 3;
	t_store_reset(rows);
	t_scal_clear();
	for (k = 0; k < g.m; k++) { t_col(1)[k] = (double)g.ei[k]; t_col(2)[k] = (double)g.ej[k]; }
	for (b = 0; b < nblock; b++) t_col(3 + b);
	snprintf(args, sizeof args, "2 %lld 0 %lld %lld %d", (long long)g.n, (long long)g.m, (long long)source, nblock);
	if (call_plugin(args) != 0) { result(name, 0, "plugin returned an error"); g_free(&g); return; }
	got = (double *)malloc((size_t)g.n * (size_t)nblock * sizeof(double));
	for (b = 0; b < nblock; b++) for (k = 0; k < g.n; k++) got[b * g.n + k] = t_col(3 + b)[k];
	check_vec(name, got, exp, g.n * nblock, tol, NULL);
	free(got); g_free(&g);
}

static void test_analytic(void) {
	int64_t i, n;
	{ /* star of 10 */
		double e[10]; for (i = 0; i < 10; i++) e[i] = 0; e[0] = 36;
		legacy_call_betw("betweenness_star10", g_star(10), 0, e, 0);
	}
	{ /* path of 7 */
		double e[7] = {0, 5, 8, 9, 8, 5, 0};
		legacy_call_betw("betweenness_path7", g_path(7), 0, e, 0);
	}
	{ /* ring of 9: (n-1)(n-3)/8 = 6 for every node */
		double e[9]; for (i = 0; i < 9; i++) e[i] = 6;
		legacy_call_betw("betweenness_ring9", g_ring(9), 0, e, 0);
	}
	{ /* directed cycle of 6: node k lies on all shortest paths between the others that pass it: (n-1)(n-2)/2 = 10 */
		double e[6]; for (i = 0; i < 6; i++) e[i] = 10;
		legacy_call_betw("betweenness_dcycle6", g_dcycle(6), 1, e, 0);
	}
	{ /* BFS on a path of 7 from node 4 (missing at the source) */
		double e[7] = {3, 2, 1, SV_missval, 1, 2, 3};
		legacy_call_bfs("bfs_path7_source4", g_path(7), 4, 1, e, 0);
	}
	{ /* two sources at once */
		double e[14] = {SV_missval, 1, 2, 3, 4, 5, 6, 1, SV_missval, 1, 2, 3, 4, 5};
		legacy_call_bfs("bfs_path7_block2", g_path(7), 1, 2, e, 0);
	}
	{ /* clustering (26): complete graph of 6, ring of 8, star of 10 */
		graph_t g = g_complete(6); kres_t r; double e[12];
		if (selected("clustering_complete6")) {
			for (i = 0; i < 6; i++) { e[2 * i] = 20; e[2 * i + 1] = 20; }
			r = run_comb(26, g.n, g.m, g.ei, g.ej, g.ew, NULL, "0");
			if (r.status != 0 || r.rows != 6) result("clustering_complete6", 0, "status %d", r.status); else check_vec("clustering_complete6", r.res, e, 12, 0, NULL);
			kres_free(&r);
		}
		g_free(&g);
		g = g_ring(8);
		if (selected("clustering_ring8")) {
			double e8[16]; for (i = 0; i < 8; i++) { e8[2 * i] = 0; e8[2 * i + 1] = 2; }
			r = run_comb(26, g.n, g.m, g.ei, g.ej, g.ew, NULL, "0");
			if (r.status != 0) result("clustering_ring8", 0, "status %d", r.status); else check_vec("clustering_ring8", r.res, e8, 16, 0, NULL);
			kres_free(&r);
		}
		g_free(&g);
		g = g_star(10);
		if (selected("clustering_star10")) {
			double e10[20]; for (i = 0; i < 10; i++) { e10[2 * i] = 0; e10[2 * i + 1] = 0; } e10[1] = 72;
			r = run_comb(26, g.n, g.m, g.ei, g.ej, g.ew, NULL, "0");
			if (r.status != 0) result("clustering_star10", 0, "status %d", r.status); else check_vec("clustering_star10", r.res, e10, 20, 0, NULL);
			kres_free(&r);
		}
		g_free(&g);
	}
	{ /* triad census (27): empty graph of 6, complete graph of 5, star of 7 */
		graph_t g; kres_t r; double e[16];
		if (selected("triads_empty6")) {
			g = g_empty(6); for (i = 0; i < 16; i++) e[i] = 0; e[0] = 20;
			r = run_comb(27, g.n, 0, g.ei, g.ej, g.ew, NULL, "");
			if (r.status != 0) result("triads_empty6", 0, "status %d", r.status); else check_vec("triads_empty6", r.res, e, 16, 0, NULL);
			kres_free(&r); g_free(&g);
		}
		if (selected("triads_complete5")) {
			g = g_complete(5); for (i = 0; i < 16; i++) e[i] = 0; e[15] = 10;
			r = run_comb(27, g.n, g.m, g.ei, g.ej, g.ew, NULL, "");
			if (r.status != 0) result("triads_complete5", 0, "status %d", r.status); else check_vec("triads_complete5", r.res, e, 16, 0, NULL);
			kres_free(&r); g_free(&g);
		}
		if (selected("triads_star7")) {
			g = g_star(7); for (i = 0; i < 16; i++) e[i] = 0; e[14] = 15; e[0] = 20;
			r = run_comb(27, g.n, g.m, g.ei, g.ej, g.ew, NULL, "");
			if (r.status != 0) result("triads_star7", 0, "status %d", r.status); else check_vec("triads_star7", r.res, e, 16, 0, NULL);
			kres_free(&r); g_free(&g);
		}
	}
	{ /* PageRank of a directed cycle (34) */
		graph_t g = g_dcycle(10); kres_t r; double e[10];
		if (selected("pagerank_dcycle10")) {
			for (i = 0; i < 10; i++) e[i] = 0.1;
			r = run_comb(34, g.n, g.m, g.ei, g.ej, g.ew, NULL, "0.85 100 1e-14");
			if (r.status != 0) result("pagerank_dcycle10", 0, "status %d", r.status); else check_vec("pagerank_dcycle10", r.res, e, 10, 1e-12, NULL);
			kres_free(&r);
		}
		g_free(&g);
	}
	{ /* maximal cliques (35): complete graph of 5 is one clique of 5; a ring of 6 has 6 cliques of 2 */
		graph_t g = g_complete(5); kres_t r;
		if (selected("cliques_complete5")) {
			r = run_comb(35, g.n, g.m, g.ei, g.ej, g.ew, NULL, "1");
			if (r.status != 0 || r.rows != 5 || r.cols != 2) result("cliques_complete5", 0, "status %d rows %lld", r.status, (long long)r.rows);
			else { int ok = 1; for (i = 0; i < 5; i++) if (r.res[2 * i] != 1) ok = 0; result("cliques_complete5", ok, "%s", ok ? "" : "clique numbers wrong"); }
			kres_free(&r);
		}
		g_free(&g);
		g = g_ring(6);
		if (selected("cliques_ring6")) {
			r = run_comb(35, g.n, g.m, g.ei, g.ej, g.ew, NULL, "1");
			result("cliques_ring6", r.status == 0 && r.rows == 12, "(%lld member rows)", (long long)r.rows);
			kres_free(&r);
		}
		g_free(&g);
	}
	{ /* cohesive blocks (3) of a complete graph of 5: one block of connectivity 4 */
		graph_t g = g_complete(5); kres_t r;
		if (selected("cohesion_complete5")) {
			r = run_comb(3, g.n, g.m, g.ei, g.ej, g.ew, NULL, "0");
			if (r.status != 0 || r.rows != 5 || r.cols != 3) result("cohesion_complete5", 0, "status %d size %lld x %lld", r.status, (long long)r.rows, (long long)r.cols);
			else { int ok = 1; for (i = 0; i < 5; i++) if (r.res[3 * i] != 1 || r.res[3 * i + 1] != (double)(i + 1) || r.res[3 * i + 2] != 4) ok = 0; result("cohesion_complete5", ok, "%s", ok ? "" : "wrong block"); }
			kres_free(&r);
		}
		g_free(&g);
	}
	{ /* Louvain (24): two complete graphs of 5 joined by one tie */
		graph_t g; kres_t r; int64_t a, b, m = 0;
		if (selected("louvain_two_cliques")) {
			int64_t ei[21], ej[21]; double ew[21];
			for (a = 1; a <= 10; a++) for (b = a + 1; b <= 10; b++) {
				if ((a <= 5 && b <= 5) || (a > 5 && b > 5)) { ei[m] = a; ej[m] = b; ew[m] = 1; m++; }
			}
			ei[m] = 5; ej[m] = 6; ew[m] = 1; m++;
			r = run_comb(24, 10, m, ei, ej, ew, NULL, "1");
			if (r.status != 0 || r.rows != 10) result("louvain_two_cliques", 0, "status %d", r.status);
			else {
				int ok = 1;
				for (i = 1; i < 5; i++) if (r.res[i] != r.res[0]) ok = 0;
				for (i = 6; i < 10; i++) if (r.res[i] != r.res[5]) ok = 0;
				if (r.res[0] == r.res[5]) ok = 0;
				result("louvain_two_cliques", ok, "(two communities)");
			}
			kres_free(&r);
		}
		(void)g;
	}
	(void)n;
}

/* ================================================================== */
/* property tests on random bipartite graphs                             */
/* ================================================================== */

static void test_properties(void) {
	/* Barber's bipartite modularity: the Q the kernel publishes (a1) must equal Q computed here from the labels it returns */
	if (selected("louvain_bip_Q")) {
		int rep, ok = 1;
		double worst = 0;
		for (rep = 0; rep < 6 && ok; rep++) {
			int64_t n1 = 25 + rep * 7, n2 = 30 + rep * 5, n = n1 + n2, i, j, m = 0, cap = n1 * n2 + 1, k;
			int64_t *ei = (int64_t *)malloc((size_t)cap * sizeof(int64_t)), *ej = (int64_t *)malloc((size_t)cap * sizeof(int64_t));
			double *ew = (double *)malloc((size_t)cap * sizeof(double)), *md = (double *)malloc((size_t)n * sizeof(double));
			kres_t r;
			double mt = 0, *K1, *K2, *inw, Q = 0;
			for (k = 0; k < n; k++) md[k] = k < n1 ? 1 : 2;
			for (i = 1; i <= n1; i++) for (j = 1; j <= n2; j++) if (rndu() < 0.12 + 0.02 * rep) { ei[m] = i; ej[m] = n1 + j; ew[m] = 1 + (double)(rnd64() % 4); m++; }
			r = run_comb(43, n, m, ei, ej, ew, md, "1 3 12345");
			if (r.status != 0 || r.rows != n) { ok = 0; result("louvain_bip_Q", 0, "status %d", r.status); }
			else {
				int64_t nc = 0;
				for (k = 0; k < n; k++) if ((int64_t)r.res[k] > nc) nc = (int64_t)r.res[k];
				K1 = (double *)calloc((size_t)nc + 2, sizeof(double)); K2 = (double *)calloc((size_t)nc + 2, sizeof(double)); inw = (double *)calloc((size_t)nc + 2, sizeof(double));
				for (k = 0; k < m; k++) {
					int64_t ci = (int64_t)r.res[ei[k] - 1], cj = (int64_t)r.res[ej[k] - 1];
					mt += ew[k]; K1[ci] += ew[k]; K2[cj] += ew[k];
					if (ci == cj) inw[ci] += ew[k];
				}
				{ int64_t c; double sinw = 0, sk = 0; for (c = 1; c <= nc; c++) { sinw += inw[c]; sk += K1[c] * K2[c]; } Q = (sinw - sk / mt) / mt; }
				if (fabs(Q - r.a[1]) > worst) worst = fabs(Q - r.a[1]);
				free(K1); free(K2); free(inw);
			}
			kres_free(&r); free(ei); free(ej); free(ew); free(md);
		}
		if (ok) result("louvain_bip_Q", worst <= 1e-9, "(6 graphs, max |Q published - Q recomputed| = %.2e)", worst);
	}
	/* tie swapping keeps the number of ties per node, the multiset of values and never creates a repeated tie */
	if (selected("swap_invariants")) {
		int rep, ok = 1;
		for (rep = 0; rep < 4 && ok; rep++) {
			int64_t n1 = 30 + 5 * rep, n2 = 40, n = n1 + n2, i, j, m = 0, cap = n1 * n2 + 1, k;
			int64_t *ei = (int64_t *)malloc((size_t)cap * sizeof(int64_t)), *ej = (int64_t *)malloc((size_t)cap * sizeof(int64_t));
			double *ew = (double *)malloc((size_t)cap * sizeof(double));
			int64_t *d0 = (int64_t *)calloc((size_t)n + 1, sizeof(int64_t)), *d1 = (int64_t *)calloc((size_t)n + 1, sizeof(int64_t));
			kres_t r;
			double s0 = 0, s1 = 0;
			for (i = 1; i <= n1; i++) for (j = 1; j <= n2; j++) if (rndu() < 0.2) { ei[m] = i; ej[m] = n1 + j; ew[m] = 1 + (double)(rnd64() % 3); m++; d0[i]++; d0[n1 + j]++; s0 += ew[m - 1] * (double)m; }
			r = run_comb(46, n, m, ei, ej, ew, NULL, "200 777");
			if (r.status != 0 || r.rows != m || r.cols != 3) { ok = 0; result("swap_invariants", 0, "status %d size %lld x %lld", r.status, (long long)r.rows, (long long)r.cols); }
			else {
				double sw0 = 0, sw1 = 0;
				for (k = 0; k < m; k++) { sw0 += ew[k]; sw1 += r.res[3 * k + 2]; d1[(int64_t)r.res[3 * k]]++; d1[(int64_t)r.res[3 * k + 1]]++; }
				for (k = 0; k <= n; k++) if (d0[k] != d1[k]) ok = 0;
				if (sw0 != sw1) ok = 0;
				/* no repeated pair */
				for (k = 0; ok && k < m; k++) { int64_t q; for (q = k + 1; q < m; q++) if (r.res[3 * k] == r.res[3 * q] && r.res[3 * k + 1] == r.res[3 * q + 1]) { ok = 0; break; } }
				if (!ok) result("swap_invariants", 0, "degree sequence, values or distinctness changed (graph %d)", rep);
			}
			(void)s0; (void)s1;
			kres_free(&r); free(ei); free(ej); free(ew); free(d0); free(d1);
		}
		if (ok) result("swap_invariants", 1, "(4 graphs, 200 swap attempts each)");
	}
}


/* ================================================================== */
/* kernels 51 to 54 (plugin generation 12): properties and large cases    */
/* ================================================================== */

static int cmp_i64(const void *a, const void *b) { int64_t x = *(const int64_t *)a, y = *(const int64_t *)b; return x < y ? -1 : x > y; }

/*
	Null-model draw (53) on a random two-mode network: the number of ties is kept by every condition; the degrees of mode 1
	(condition 2), of mode 2 (condition 3) or of both (condition 4) are kept exactly; no tie is repeated; every tie joins
	the two modes.  n1 x n2 nodes, density p; ntrades = the curveball trades of condition 4.
*/
static int check_nullbip(const char *name, int64_t n1, int64_t n2, double p, int model, int64_t ntrades, char *why, size_t whylen) {
	int64_t n = n1 + n2, i, j, m = 0, cap, k, *d1a, *d2a, *d1b, *d2b, *key;
	int64_t *ei, *ej;
	double *md, *ew;
	kres_t r;
	char par[80];
	int ok = 1;
	cap = (int64_t)(p * (double)n1 * (double)n2 * 1.2) + 1000;
	ei = (int64_t *)malloc((size_t)cap * sizeof(int64_t)); ej = (int64_t *)malloc((size_t)cap * sizeof(int64_t));
	ew = (double *)malloc((size_t)cap * sizeof(double)); md = (double *)malloc((size_t)n * sizeof(double));
	d1a = (int64_t *)calloc((size_t)n1 + 1, sizeof(int64_t)); d1b = (int64_t *)calloc((size_t)n1 + 1, sizeof(int64_t));
	d2a = (int64_t *)calloc((size_t)n2 + 1, sizeof(int64_t)); d2b = (int64_t *)calloc((size_t)n2 + 1, sizeof(int64_t));
	for (k = 0; k < n; k++) md[k] = k < n1 ? 1 : 2;
	if (p * (double)n1 * (double)n2 < 5e6) {
		for (i = 1; i <= n1; i++) for (j = 1; j <= n2; j++) if (rndu() < p && m < cap) { ei[m] = i; ej[m] = n1 + j; ew[m] = 1; d1a[i]++; d2a[j]++; m++; }
	} else {
		/* a large sparse network: draw the ties one by one (a repeated pair is skipped) */
		int64_t target = (int64_t)(p * (double)n1 * (double)n2), t;
		for (t = 0; t < target && m < cap; t++) { i = 1 + (int64_t)(rnd64() % (uint64_t)n1); j = 1 + (int64_t)(rnd64() % (uint64_t)n2); ei[m] = i; ej[m] = n1 + j; ew[m] = 1; m++; }
		{ /* remove repeated pairs */
			int64_t *kk2 = (int64_t *)malloc((size_t)m * sizeof(int64_t)), q = 0;
			for (k = 0; k < m; k++) kk2[k] = (ei[k] - 1) * n2 + (ej[k] - n1 - 1);
			qsort(kk2, (size_t)m, sizeof(int64_t), cmp_i64);
			for (k = 0; k < m; k++) if (k == 0 || kk2[k] != kk2[k - 1]) { ei[q] = kk2[k] / n2 + 1; ej[q] = n1 + kk2[k] % n2 + 1; q++; }
			m = q; free(kk2);
			for (k = 0; k < m; k++) { d1a[ei[k]]++; d2a[ej[k] - n1]++; }
		}
	}
	snprintf(par, sizeof par, "%d %d %lld", model, 12345 + model, (long long)ntrades);
	r = run_comb(53, n, m, ei, ej, ew, md, par);
	why[0] = 0;
	if (r.rc != 0 || r.status != 0 || r.rows != m || r.cols != 3) { ok = 0; snprintf(why, whylen, "%s model %d: status %d rc %d size %lld x %lld, expected %lld x 3", name, model, r.status, r.rc, (long long)r.rows, (long long)r.cols, (long long)m); }
	else {
		key = (int64_t *)malloc((size_t)m * sizeof(int64_t));
		for (k = 0; k < m && ok; k++) {
			int64_t a = (int64_t)r.res[3 * k], b = (int64_t)r.res[3 * k + 1];
			if (a < 1 || a > n1 || b < n1 + 1 || b > n) { ok = 0; snprintf(why, whylen, "%s model %d: tie %lld joins %lld and %lld, not mode 1 and mode 2", name, model, (long long)k + 1, (long long)a, (long long)b); break; }
			d1b[a]++; d2b[b - n1]++;
			key[k] = (a - 1) * n2 + (b - n1 - 1);
		}
		if (ok) {
			qsort(key, (size_t)m, sizeof(int64_t), cmp_i64);
			for (k = 1; k < m; k++) if (key[k] == key[k - 1]) { ok = 0; snprintf(why, whylen, "%s model %d: a tie is repeated", name, model); break; }
		}
		if (ok && (model == 2 || model == 4)) for (i = 1; i <= n1; i++) if (d1a[i] != d1b[i]) { ok = 0; snprintf(why, whylen, "%s model %d: degree of mode 1 node %lld changed", name, model, (long long)i); break; }
		if (ok && (model == 3 || model == 4)) for (j = 1; j <= n2; j++) if (d2a[j] != d2b[j]) { ok = 0; snprintf(why, whylen, "%s model %d: degree of mode 2 node %lld changed", name, model, (long long)j); break; }
		free(key);
	}
	kres_free(&r);
	free(ei); free(ej); free(ew); free(md); free(d1a); free(d1b); free(d2a); free(d2b);
	return ok;
}

static void test_native390(void) {
	int model;
	double t0;

	/* null-model draws: margins exact, counts kept */
	if (selected("nullbip_margins")) {
		int ok = 1;
		char why[300];
		for (model = 1; model <= 4 && ok; model++) {
			ok = check_nullbip("40 x 60, p = 0.15", 40, 60, 0.15, model, 400, why, sizeof why);
			if (ok) ok = check_nullbip("90 x 25, p = 0.30", 90, 25, 0.30, model, 400, why, sizeof why);
			if (ok) ok = check_nullbip("7 x 5, p = 0.60", 7, 5, 0.60, model, 50, why, sizeof why);
		}
		if (ok) result("nullbip_margins", 1, "(3 networks, conditions 1 to 4: counts, degrees, no repeated tie)");
		else result("nullbip_margins", 0, "%s", why);
	}

	/* similarity of a star (51): a leaf's column and the centre's column have closed forms; the formulas are calibrated on
	   a star of 10 nodes and must scale with n (the cells are doubles, but sums over 2n ties and the n-by-n dimensions are not) */
	if (selected("simnodes_star") && !g_small) {
		int64_t ns = 10, nl = 100000, k;
		int types[3] = {7, 5, 3}, q, ok = 1;
		char why[300] = "";
		t0 = now_s();
		for (q = 0; q < 3 && ok; q++) {
			graph_t gs = g_star(ns), gl = g_star(nl);
			kres_t rs, rl;
			char par[64];
			double cs, cl, ls, ll;
			snprintf(par, sizeof par, "%d 0 2 1 0", types[q]);   /* column 2 = a leaf; cells (i,2) for every i */
			rs = run_comb(51, ns, gs.m, gs.ei, gs.ej, gs.ew, NULL, par);
			rl = run_comb(51, nl, gl.m, gl.ei, gl.ej, gl.ew, NULL, par);
			if (rs.status != 0 || rl.status != 0 || rs.rows != ns || rl.rows != nl || rs.cols != 1 || rl.cols != 1) { ok = 0; snprintf(why, sizeof why, "type %d: status %d / %d size %lld / %lld", types[q], rs.status, rl.status, (long long)rs.rows, (long long)rl.rows); }
			else {
				cs = rs.res[0]; cl = rl.res[0];            /* cell (centre, leaf) */
				ls = rs.res[2]; ll = rl.res[2];            /* cell (another leaf, leaf) */
				if (types[q] == 7) {                       /* manhatten: differs in every other leaf, in and out: linear in n - 2 */
					if (cl / (double)(nl - 2) != cs / (double)(ns - 2) || ll != ls) { ok = 0; snprintf(why, sizeof why, "type 7: centre-leaf %.17g (n=%lld) vs %.17g (n=%lld)", cl, (long long)nl, cs, (long long)ns); }
				} else if (cl != cs || ll != ls) { ok = 0; snprintf(why, sizeof why, "type %d: cells depend on n: %.17g %.17g / %.17g %.17g", types[q], cs, cl, ls, ll); }
				for (k = 3; k < nl && ok; k += 997) if (rl.res[k] != ll) { ok = 0; snprintf(why, sizeof why, "type %d: leaf cell %lld = %.17g, expected %.17g", types[q], (long long)k + 1, rl.res[k], ll); }
			}
			kres_free(&rs); kres_free(&rl); g_free(&gs); g_free(&gl);
		}
		if (ok) result("simnodes_star", 1, "(star of 100,000 nodes: cells of a leaf column as on a star of 10; %.1fs)", now_s() - t0);
		else result("simnodes_star", 0, "%s", why);
	}

	/* null-model draws where n1 * n2 exceeds 2^31 (gnm samples cell numbers up to 2.5e9) and the degree-preserving draws on 100,000 nodes */
	if (selected("nullbip_large") && !g_small) {
		int ok = 1;
		char why[300] = "";
		t0 = now_s();
		for (model = 1; model <= 4 && ok; model++) ok = check_nullbip("50,000 x 50,000, 120,000 ties", 50000, 50000, 120000.0 / 2.5e9, model, 100000, why, sizeof why);
		if (ok) result("nullbip_large", 1, "(50,000 x 50,000 = 2.5e9 cells > 2^31, conditions 1 to 4; %.1fs)", now_s() - t0);
		else result("nullbip_large", 0, "%s", why);
	}

	/* DIRT_LPA+ (52) on disjoint complete two-mode blocks: the right answer is one module per block (Barber's Q = 1 - 1/blocks) */
	if (selected("dirtlpa_blocks")) {
		int64_t nb = g_small ? 40 : 500, bs = 4, n = nb * 2 * bs, m = 0, b, i, j;
		int64_t *ei = (int64_t *)malloc((size_t)(nb * bs * bs + 1) * sizeof(int64_t)), *ej = (int64_t *)malloc((size_t)(nb * bs * bs + 1) * sizeof(int64_t));
		double *ew = (double *)malloc((size_t)(nb * bs * bs + 1) * sizeof(double)), *md = (double *)malloc((size_t)n * sizeof(double));
		kres_t r;
		double expq = 1.0 - 1.0 / (double)nb;
		t0 = now_s();
		for (b = 0; b < nb; b++) {
			for (i = 0; i < bs; i++) { md[b * 2 * bs + i] = 1; md[b * 2 * bs + bs + i] = 2; }
			for (i = 0; i < bs; i++) for (j = 0; j < bs; j++) { ei[m] = b * 2 * bs + i + 1; ej[m] = b * 2 * bs + bs + j + 1; ew[m] = 1; m++; }
		}
		r = run_comb(52, n, m, ei, ej, ew, md, "4 3 99");
		result("dirtlpa_blocks", r.status == 0 && r.rows == n && fabs(r.a[1] - expq) < 1e-9, "(%lld blocks of 4 x 4: Q = %.6f, expected %.6f; %.1fs)", (long long)nb, r.a[1], expq, now_s() - t0);
		kres_free(&r); free(ei); free(ej); free(ew); free(md);
	}

	/* weighted Kamada-Kawai (54): every coordinate is finite, the layout is not the start, ties of larger value end up closer */
	if (selected("kkw_properties")) {
		int64_t n = g_small ? 300 : 1500, i, k, m = 0, cap = n * 12;
		int64_t *ei = (int64_t *)malloc((size_t)cap * sizeof(int64_t)), *ej = (int64_t *)malloc((size_t)cap * sizeof(int64_t));
		double *ew = (double *)malloc((size_t)cap * sizeof(double)), *nv = (double *)malloc((size_t)(2 * n) * sizeof(double));
		int ok = 1;
		double moved = 0, dlo = 0, dhi = 0, nlo = 0, nhi = 0;
		char par[64];
		t0 = now_s();
		for (i = 1; i <= n; i++) for (k = 1; k <= 5; k++) {   /* a ring with chords; values 1 or 8 */
			int64_t j = (i + k * k * 7 - 1) % n + 1;
			double w = (k == 1) ? 8.0 : 1.0;
			if (j == i) continue;
			ei[m] = i; ej[m] = j; ew[m] = w; m++; ei[m] = j; ej[m] = i; ew[m] = w; m++;
		}
		for (i = 0; i < n; i++) { nv[i] = cos(6.283185307179586 * (double)i / (double)n) * 5 + 0.01 * (double)(i % 7); nv[n + i] = sin(6.283185307179586 * (double)i / (double)n) * 5 + 0.01 * (double)(i % 5); }
		snprintf(par, sizeof par, "10");
		{
			char args[128];
			(void)par;
			/* the kernel takes the start coordinates in variable 4 (2n values) */
			{
				int64_t rows = 2 * n > m ? 2 * n : m, q;
				double v;
				t_store_reset(rows); t_scal_clear();
				for (q = 0; q < m; q++) { t_col(1)[q] = (double)ei[q]; t_col(2)[q] = (double)ej[q]; t_col(3)[q] = ew[q]; }
				for (q = 0; q < 2 * n; q++) t_col(4)[q] = nv[q];
				snprintf(args, sizeof args, "54 %lld %lld 10", (long long)n, (long long)m);
				ok = call_plugin(args) == 0 && t_scal("__nwg_status", &v) && v == 0;
				if (ok) {
					int64_t row;
					if (call_plugin("99 0 0 2") != 0) ok = 0;
					else for (row = 0; row < n; row++) {
						double x = t_col(5)[row], y = t_col(6)[row];
						if (!(fabs(x) < 1e6) || !(fabs(y) < 1e6)) { ok = 0; break; }
						moved += fabs(x - nv[row]) + fabs(y - nv[n + row]);
					}
					if (ok) for (q = 0; q < m; q++) {
						double dx = t_col(5)[ei[q] - 1] - t_col(5)[ej[q] - 1], dy = t_col(6)[ei[q] - 1] - t_col(6)[ej[q] - 1], d = sqrt(dx * dx + dy * dy);
						if (ew[q] > 4) { dhi += d; nhi += 1; } else { dlo += d; nlo += 1; }
					}
				}
				res_clear();
			}
		}
		result("kkw_properties", ok && moved > 1 && nlo > 0 && nhi > 0 && dhi / nhi < dlo / nlo, "(%lld nodes: mean length of ties of value 8 = %.3f, of value 1 = %.3f; %.1fs)", (long long)n, nhi > 0 ? dhi / nhi : -1.0, nlo > 0 ? dlo / nlo : -1.0, now_s() - t0);
		free(ei); free(ej); free(ew); free(nv);
	}
}

/* ================================================================== */
/* large synthetic cases: values above 2^31, known answers                */
/* ================================================================== */

static int64_t choose2(int64_t k) { return k * (k - 1) / 2; }
static int64_t choose3(int64_t k) { return k * (k - 1) * (k - 2) / 6; }

static void test_large(void) {
	double t0;
	if (g_small) { printf("SKIP large cases (--small)\n"); g_skip++; return; }

	/* distance sums (25) on a path of 66,000 nodes: the far sum of node 1 is n(n-1)/2 = 2.18e9 > 2^31 */
	if (selected("large_distsum_path66000")) {
		int64_t n = 66000, k;
		graph_t g = g_path(n);
		kres_t r;
		int ok = 1;
		t0 = now_s();
		r = run_comb(25, n, g.m, g.ei, g.ej, g.ew, NULL, "0 1");
		if (r.status != 0 || r.rows != n || r.cols != 3) { ok = 0; result("large_distsum_path66000", 0, "status %d size %lld x %lld", r.status, (long long)r.rows, (long long)r.cols); }
		else for (k = 1; k <= n && ok; k++) {
			double far = (double)(choose2(k) + choose2(n - k + 1));   /* (k-1)k/2 + (n-k)(n-k+1)/2 */
			if (r.res[3 * (k - 1)] != far || r.res[3 * (k - 1) + 1] != (double)(n - 1) || r.res[3 * (k - 1) + 2] != (double)(n - 1)) {
				ok = 0; result("large_distsum_path66000", 0, "node %lld: far %.17g expected %.17g", (long long)k, r.res[3 * (k - 1)], far);
			}
		}
		if (ok) result("large_distsum_path66000", 1, "(far(1) = %.0f > 2^31; %.1fs)", (double)choose2(n), now_s() - t0);
		kres_free(&r); g_free(&g);
	}

	/* clustering (26) of a star with 66,000 nodes: potential triples of the centre (n-1)(n-2) = 4.4e9 > 2^32 */
	if (selected("large_clustering_star66000")) {
		int64_t n = 66000, k;
		graph_t g = g_star(n);
		kres_t r;
		int ok = 1;
		t0 = now_s();
		r = run_comb(26, n, g.m, g.ei, g.ej, g.ew, NULL, "0");
		if (r.status != 0 || r.rows != n) { ok = 0; result("large_clustering_star66000", 0, "status %d", r.status); }
		else {
			double e = (double)(n - 1) * (double)(n - 2);
			if (r.res[0] != 0 || r.res[1] != e) { ok = 0; result("large_clustering_star66000", 0, "centre: closed %.17g potential %.17g, expected 0 and %.17g", r.res[0], r.res[1], e); }
			for (k = 2; k <= n && ok; k++) if (r.res[2 * (k - 1)] != 0 || r.res[2 * (k - 1) + 1] != 0) { ok = 0; result("large_clustering_star66000", 0, "leaf %lld wrong", (long long)k); }
			if (ok) result("large_clustering_star66000", 1, "(centre potential %.0f > 2^32; %.1fs)", e, now_s() - t0);
		}
		kres_free(&r); g_free(&g);
	}

	/* triad census (27) of a star with 66,000 nodes: 201 triads C(n-1,2) = 2.18e9 > 2^31, 003 triads C(n-1,3) = 4.7e13 */
	if (selected("large_triads_star66000")) {
		int64_t n = 66000, k;
		graph_t g = g_star(n);
		kres_t r;
		int ok = 1;
		t0 = now_s();
		r = run_comb(27, n, g.m, g.ei, g.ej, g.ew, NULL, "");
		if (r.status != 0 || r.rows != 1 || r.cols != 16) { ok = 0; result("large_triads_star66000", 0, "status %d", r.status); }
		else {
			for (k = 0; k < 16; k++) {
				double e = k == 0 ? (double)choose3(n - 1) : (k == 14 ? (double)choose2(n - 1) : 0.0);
				if (r.res[k] != e) { ok = 0; result("large_triads_star66000", 0, "type %lld = %.17g, expected %.17g", (long long)k, r.res[k], e); break; }
			}
			if (ok) result("large_triads_star66000", 1, "(201: %.0f, 003: %.0f; %.1fs)", (double)choose2(n - 1), (double)choose3(n - 1), now_s() - t0);
		}
		kres_free(&r); g_free(&g);
	}

	/* motif census (6) of a star with 40,000 nodes: C(n-1,3) = 1.07e13 induced 3-stars */
	if (selected("large_motif4_star40000")) {
		int64_t n = 40000, k;
		graph_t g = g_star(n);
		kres_t r;
		t0 = now_s();
		r = run_comb(6, n, g.m, g.ei, g.ej, g.ew, NULL, "");
		if (r.status != 0 || r.rows != 1 || r.cols < 6) result("large_motif4_star40000", 0, "status %d", r.status);
		else {
			double e[7] = {0, 0, 0, 0, 0, 0, 0};
			int64_t ci = -1;
			for (k = 0; k < r.cols; k++) if (r.res[k] == (double)choose3(n - 1)) ci = k;
			/* one of the first six counts is the star; everything else is zero (the 7th is the total of 4-node subgraphs) */
			e[0] = 0;
			if (ci < 0) result("large_motif4_star40000", 0, "no entry equals C(n-1,3) = %.0f", (double)choose3(n - 1));
			else {
				int ok = 1;
				for (k = 0; k < 6; k++) if (k != ci && r.res[k] != 0) ok = 0;
				result("large_motif4_star40000", ok, "(induced 3-stars %.0f > 2^31; %.1fs)", (double)choose3(n - 1), now_s() - t0);
			}
		}
		kres_free(&r); g_free(&g);
	}

	/* maximal cliques (35) of a ring with 100,000 nodes: 100,000 cliques of 2 nodes */
	if (selected("large_cliques_ring100000")) {
		int64_t n = 100000;
		graph_t g = g_ring(n);
		kres_t r;
		t0 = now_s();
		r = run_comb(35, n, g.m, g.ei, g.ej, g.ew, NULL, "1");
		result("large_cliques_ring100000", r.status == 0 && r.rows == 2 * n && r.cols == 2 && r.res[2 * (2 * n - 1)] == (double)n, "(%lld member rows; %.1fs)", (long long)r.rows, now_s() - t0);
		kres_free(&r); g_free(&g);
	}

	/* PageRank (34) of a directed cycle with 100,000 nodes: 1/n for every node */
	if (selected("large_pagerank_dcycle100000")) {
		int64_t n = 100000, k;
		graph_t g = g_dcycle(n);
		kres_t r;
		int ok = 1;
		t0 = now_s();
		r = run_comb(34, n, g.m, g.ei, g.ej, g.ew, NULL, "0.85 100 1e-14");
		if (r.status != 0 || r.rows != n) { ok = 0; result("large_pagerank_dcycle100000", 0, "status %d", r.status); }
		else for (k = 0; k < n; k++) if (fabs(r.res[k] - 1.0 / (double)n) > 1e-15) { ok = 0; result("large_pagerank_dcycle100000", 0, "node %lld = %.17g", (long long)k + 1, r.res[k]); break; }
		if (ok) result("large_pagerank_dcycle100000", 1, "(%.1fs)", now_s() - t0);
		kres_free(&r); g_free(&g);
	}

	/* breadth-first distances (2) on a path with 100,000 nodes, three sources at once */
	if (selected("large_bfs_path100000")) {
		int64_t n = 100000, k, rows;
		graph_t g = g_path(n);
		char args[128];
		int ok = 1, b;
		int64_t src[3] = {1, 50000, 100000};
		t0 = now_s();
		rows = g.m;
		t_store_reset(rows);
		t_scal_clear();
		for (k = 0; k < g.m; k++) { t_col(1)[k] = (double)g.ei[k]; t_col(2)[k] = (double)g.ej[k]; }
		for (b = 0; b < 3; b++) t_col(3 + b);
		/* sources 1, 2, 3 as a block; then the other two checked with single calls */
		snprintf(args, sizeof args, "2 %lld 0 %lld 1 3", (long long)n, (long long)g.m);
		if (call_plugin(args) != 0) { ok = 0; result("large_bfs_path100000", 0, "plugin error"); }
		else for (b = 0; b < 3 && ok; b++) for (k = 1; k <= n; k++) {
			double e = (k == 1 + b) ? SV_missval : (double)(k > 1 + b ? k - 1 - b : 1 + b - k);
			if (!close_enough(t_col(3 + b)[k - 1], e, 0)) { ok = 0; result("large_bfs_path100000", 0, "source %d node %lld: %.17g, expected %.17g", b + 1, (long long)k, t_col(3 + b)[k - 1], e); break; }
		}
		(void)src;
		if (ok) result("large_bfs_path100000", 1, "(%.1fs)", now_s() - t0);
		g_free(&g);
	}

	/* bipartite motif positions (50) of a star with one node in mode 1 and 20,000 in mode 2:
	   the centre takes part in sum_{t=1..4} C(N,t) = 6.7e15 connected induced subgraphs of 2..5 nodes, a leaf in 1 + sum_{t=1..3} C(N-1,t) */
	if (selected("large_bmotif_star20000")) {
		int64_t N = 20000, n = N + 1, k;
		graph_t g; kres_t r; double *md;
		double ec, el;
		memset(&g, 0, sizeof g);
		g_reserve(&g, N + 1);
		for (k = 1; k <= N; k++) g_arc(&g, 1, 1 + k, 1.0);
		md = (double *)malloc((size_t)n * sizeof(double));
		for (k = 0; k < n; k++) md[k] = k == 0 ? 1.0 : 2.0;
		t0 = now_s();
		r = run_comb(50, n, g.m, g.ei, g.ej, g.ew, md, "0");
		if (r.status != 0 || r.rows != n || r.cols != 46) { result("large_bmotif_star20000", 0, "status %d size %lld x %lld", r.status, (long long)r.rows, (long long)r.cols); }
		else {
			double dN = (double)N;
			double c1 = dN, c2 = dN * (dN - 1) / 2, c3 = dN * (dN - 1) * (dN - 2) / 6, c4 = dN * (dN - 1) * (dN - 2) * (dN - 3) / 24;
			double d1 = dN - 1, d2 = (dN - 1) * (dN - 2) / 2, d3 = (dN - 1) * (dN - 2) * (dN - 3) / 6;
			double sc = 0, sl = 0;
			int c;
			ec = c1 + c2 + c3 + c4;
			el = 1 + d1 + d2 + d3;
			for (c = 0; c < 46; c++) { sc += r.res[c]; sl += r.res[46 * 5 + c]; }
			if (fabs(sc - ec) > 1e-12 * ec) { result("large_bmotif_star20000", 0, "centre in %.17g subgraphs, expected %.17g", sc, ec); }
			else if (fabs(sl - el) > 1e-12 * el) { result("large_bmotif_star20000", 0, "leaf in %.17g subgraphs, expected %.17g", sl, el); }
			else result("large_bmotif_star20000", 1, "(centre in %.0f subgraphs > 2^31; %.1fs)", ec, now_s() - t0);
		}
		free(md); kres_free(&r); g_free(&g);
	}
}


/* ================================================================== */
/* --stress N: dense random graph, every counting kernel; meant for the sanitizer builds */
/* ================================================================== */

static void test_stress(int64_t n, double p) {
	graph_t g;
	int64_t i, j, cap = (int64_t)(p * (double)n * (double)n * 1.3) + 1000;
	static const int algs[] = {6, 22, 25, 26, 27, 28, 29, 30, 31, 34, 44, 24};
	int a;
	memset(&g, 0, sizeof g);
	g_reserve(&g, 2 * cap);
	for (i = 1; i <= n; i++) for (j = i + 1; j <= n; j++) if (rndu() < p) { double w = 1 + (double)(rnd64() % 5); g_arc(&g, i, j, w); g_arc(&g, j, i, w); }
	printf("stress: %lld nodes, %lld arcs\n", (long long)n, (long long)g.m);
	for (a = 0; a < (int)(sizeof algs / sizeof algs[0]); a++) {
		kres_t r;
		const char *par = "";
		double t0 = now_s();
		char nm[64];
		if (algs[a] == 34 || algs[a] == 44) par = "0.85 50 1e-12";
		if (algs[a] == 25) par = "0 1";
		if (algs[a] == 26 || algs[a] == 28) par = "0 0";
		if (algs[a] == 24) par = "1";
		snprintf(nm, sizeof nm, "stress_alg%d", algs[a]);
		r = run_comb(algs[a], n, g.m, g.ei, g.ej, g.ew, NULL, par);
		result(nm, r.rc == 0 && (r.status == 0 || r.status == 3), "(status %d, %lld x %lld, %.2fs)", r.status, (long long)r.rows, (long long)r.cols, now_s() - t0);
		kres_free(&r);
	}
	g_free(&g);
}

/* ================================================================== */
/* main                                                                   */
/* ================================================================== */

int main(int argc, char **argv) {
	int a;
	char path[512];
	double t0 = now_s();
	for (a = 1; a < argc; a++) {
		if (strcmp(argv[a], "--small") == 0) g_small = 1;
		else if (strcmp(argv[a], "--only") == 0 && a + 1 < argc) g_only = argv[++a];
		else if (strcmp(argv[a], "--stress") == 0 && a + 1 < argc) g_stress = atoi(argv[++a]);
		else if (strcmp(argv[a], "--fixtures") == 0 && a + 1 < argc) g_fixdir = argv[++a];
		else if (strcmp(argv[a], "--cscripts") == 0 && a + 1 < argc) g_csdir = argv[++a];
		else { fprintf(stderr, "usage: %s [--small] [--only substring] [--fixtures dir] [--cscripts dir]\n", argv[0]); return 64; }
	}
	printf("nwcommands native kernel tests: sizeof(long)=%d sizeof(void*)=%d sizeof(long double)=%d\n", (int)sizeof(int64_t) == 8 ? (int)sizeof(long) : 0, (int)sizeof(void *), (int)sizeof(long double));
	printf("plugin generation (NWCOMB_VERSION) %d\n", NWCOMB_VERSION);
	snprintf(path, sizeof path, "%s/golden.txt", g_fixdir);
	if (!g_only || strstr("golden", g_only) || 1) run_golden(path);
	test_ext_pagerankw();
	test_ext_betweenw();
	test_ext_matchw();
	test_ext_burtw();
	test_ext_bmotif();
	test_analytic();
	test_properties();
	test_native390();
	test_large();
	if (g_stress > 0) test_stress(g_stress, 0.2);
	res_clear();
	printf("\n%d passed, %d failed, %d skipped  (%.1f s)\n", g_pass, g_fail, g_skip, now_s() - t0);
	if (g_fail) return g_missing_fixture ? 2 : 1;
	return 0;
}
