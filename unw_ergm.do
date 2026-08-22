/*
	unw_ergm.do -- native ERGM estimation core for nwcommands (nwergm).

	Compiled into the same lnwcommands.mlib as unw_core.do (see lib/build.do,
	which `do`s this file immediately after unw_core.do, before creating the
	mlib) - kept as a SEPARATE source file rather than appended to
	unw_core.do (already 6000+ lines) because the ERGM subsystem is
	architecturally self-contained: it reads an observed network via the
	existing NWdef sparse accessors exactly once (at setup), then works
	entirely with its own graph representation (ErgmGraph, below) for the
	MCMC-heavy inner loop.

	This is a clean-room reimplementation against published statistical
	definitions (Hunter & Handcock 2006; Hunter 2007; Morris, Handcock &
	Hunter 2008; Hummel, Hunter & Handcock 2012; Geyer & Thompson 1992),
	using the public Statnet `ergm` R package purely as a behavioural/
	architectural reference and as a development-time certification target
	(never a runtime dependency). No `ergm` source code, comment, or
	identifier is copied here. See docs/ERGM_PROVENANCE.md for the full
	licensing/attribution account and docs/ERGM_STATNET_STUDY.md for the
	architecture study this implementation is based on. See
	docs/ERGM_ARCHITECTURE.md for the developer-facing design document
	(term API, extension guide, deliberate simplifications relative to
	Statnet's own, much larger implementation).

	Why not reuse NWdef's own CSR sparse index for the MCMC state: NWdef's
	build_sparse_index() rebuilds the ENTIRE index from scratch on every
	call (O(n+nnz)) - fine for a network that changes rarely, catastrophic
	for MCMC, which toggles a single edge millions of times. ErgmGraph
	below instead uses one Mata associative array (asarray()) per node as
	an O(1)-average adjacency set, supporting genuine incremental
	toggle/lookup - the same architectural lesson Statnet's own C
	`edgetree` (a per-node binary search tree) encodes for the same reason,
	confirmed directly from its source during the Part I study.
*/

set matastrict on

mata:

/* ===================================================================
   ErgmGraph: mutable, toggle-friendly binary graph state for MCMC.
   =================================================================== */

class ErgmGraph {
	real scalar n
	real scalar directed
	pointer rowvector adjout	// adjout[i]: asarray handle; keys = neighbors reachable via an outgoing tie from i (out-neighbors if directed, all neighbors if undirected); values unused (always 1)
	pointer rowvector adjin		// directed only; adjin[i]: asarray handle of in-neighbors of i
	real colvector dout		// out-degree (directed) or degree (undirected)
	real colvector din		// in-degree (directed only; unused/left at 0 for undirected)
	real scalar nties		// number of ties: arcs (directed) or edges (undirected)

	void init()
	real scalar has_edge()
	void toggle()
	real rowvector neighbors_out()
	real rowvector neighbors_in()
	real scalar degree_out()
	real scalar degree_in()
	real scalar degree_total()
	real scalar common_neighbors()
	real matrix all_ties()
}

void ErgmGraph::init(real scalar n0, real scalar directed0){
	real scalar i

	n = n0
	directed = directed0
	dout = J(n, 1, 0)
	din  = J(n, 1, 0)
	nties = 0

	adjout = J(1, n, NULL)
	for (i=1; i<=n; i++) adjout[i] = &(asarray_create("real", 1))

	if (directed) {
		adjin = J(1, n, NULL)
		for (i=1; i<=n; i++) adjin[i] = &(asarray_create("real", 1))
	}
	else {
		adjin = adjout	// undirected: a tie is stored symmetrically in both
				// endpoints' own adjout, so "in" and "out" coincide -
				// aliasing avoids a second, redundant set of arrays.
	}
}

real scalar ErgmGraph::has_edge(real scalar i, real scalar j){
	return(asarray_contains(*adjout[i], j))
}

void ErgmGraph::toggle(real scalar i, real scalar j){
	if (has_edge(i, j)) {
		asarray_remove(*adjout[i], j)
		dout[i] = dout[i] - 1
		if (directed) {
			asarray_remove(*adjin[j], i)
			din[j] = din[j] - 1
		}
		else {
			asarray_remove(*adjout[j], i)
			dout[j] = dout[j] - 1
		}
		nties = nties - 1
	}
	else {
		asarray(*adjout[i], j, 1)
		dout[i] = dout[i] + 1
		if (directed) {
			asarray(*adjin[j], i, 1)
			din[j] = din[j] + 1
		}
		else {
			asarray(*adjout[j], i, 1)
			dout[j] = dout[j] + 1
		}
		nties = nties + 1
	}
}

real rowvector ErgmGraph::neighbors_out(real scalar i){
	return(asarray_keys(*adjout[i])')
}

real rowvector ErgmGraph::neighbors_in(real scalar i){
	if (directed) return(asarray_keys(*adjin[i])')
	return(asarray_keys(*adjout[i])')
}

real scalar ErgmGraph::degree_out(real scalar i){
	return(dout[i])
}

real scalar ErgmGraph::degree_in(real scalar i){
	if (directed) return(din[i])
	return(dout[i])
}

real scalar ErgmGraph::degree_total(real scalar i){
	if (directed) return(dout[i] + din[i])
	return(dout[i])
}

/*
	Number of nodes k that are neighbors of BOTH i and j (undirected
	sense: k s.t. has_edge(i,k) and has_edge(j,k)) - the "shared
	partner" count GWESP needs. Iterates whichever of i/j has the
	smaller neighbor set, checking membership in the other's set -
	O(min(deg_i,deg_j)), not O(n).
*/
real scalar ErgmGraph::common_neighbors(real scalar i, real scalar j){
	real rowvector nb
	real scalar k, cnt, a, b

	if (degree_out(i) <= degree_out(j)) {
		a = i; b = j
	}
	else {
		a = j; b = i
	}
	nb = neighbors_out(a)
	cnt = 0
	for (k=1; k<=cols(nb); k++) {
		if (nb[k] != b && has_edge(b, nb[k])) cnt++
	}
	return(cnt)
}

/*
	All current ties as an nties x 2 matrix of (i,j) pairs. Directed:
	one row per arc. Undirected: one row per edge, canonicalized i<j
	(each undirected tie is stored in both endpoints' adjout, so
	without this canonicalization every edge would appear twice).
	O(n + nties); only ever called once per model-statistic evaluation
	(model setup, certification), never inside the MCMC inner loop.
*/
real matrix ErgmGraph::all_ties(){
	real matrix out
	real rowvector nb
	real scalar i, k, pos

	out = J(nties, 2, 0)
	pos = 1
	for (i=1; i<=n; i++) {
		nb = neighbors_out(i)
		for (k=1; k<=cols(nb); k++) {
			if (directed || nb[k] > i) {
				out[pos,1] = i
				out[pos,2] = nb[k]
				pos++
			}
		}
	}
	return(out)
}

/* ===================================================================
   ErgmTermData: generic per-term-instance parameter container.

   One instance per term appearing in a fitted model. Rather than a
   distinct Mata class per term (impossible to dispatch polymorphically
   in Mata anyway - see the function-pointer design below), every term
   instance carries the same, small set of possible auxiliary fields;
   each term's own statistic()/change() function reads only the fields
   it actually needs. This is the "C struct" alternative the design
   brief explicitly permits in place of C++ virtual classes.
   =================================================================== */

class ErgmTermData {
	real scalar decay		// gwesp/gwdegree/gwodegree/gwidegree
	real colvector attr		// nodematch/nodecov/nodeicov/nodeocov: node-indexed covariate (already numeric-coded)
	real matrix edgecovmat		// edgecov: dense n x n dyadic covariate
}

/* ===================================================================
   Term API: each term is a pair of Mata functions with a fixed
   signature, registered by name (see ErgmTermRegistry below). Adding a
   new term means writing one such pair (plus a short registry entry
   and Stata-side argument parsing in nwergm.ado) - the sampler, MPLE
   builder, and MCMLE controller never reference a term by name and
   never need to change.

     statistic:  real rowvector fn(class ErgmGraph scalar G,
                                    class ErgmTermData scalar td)
                 -> current value of this term's statistic(s) (length
                    = this term's own npar) on the whole graph G.

     change:     real rowvector fn(class ErgmGraph scalar G,
                                    real scalar i, real scalar j,
                                    class ErgmTermData scalar td)
                 -> the signed effect on this term's statistic(s) of
                    toggling dyad (i,j) on graph G (G is NOT yet
                    toggled when this is called - has_edge(i,j) still
                    reflects the pre-toggle state).
   =================================================================== */

real rowvector stat_edges(class ErgmGraph scalar G, class ErgmTermData scalar td){
	return(G.nties)
}
real rowvector change_edges(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	return(G.has_edge(i,j) ? -1 : 1)
}

/*
	Reciprocated-tie count (directed only). Toggling (i,j) can only
	affect the mutual count if the reverse tie (j,i) already exists;
	otherwise the toggle is change=0 for this term, exactly as
	confirmed from ergm's own c_mutual (src/changestats.c:2239) during
	the Part I study.
*/
real rowvector stat_mutual(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real scalar i, j, cnt
	real rowvector nb

	cnt = 0
	for (i=1; i<=G.n; i++) {
		nb = G.neighbors_out(i)
		for (j=1; j<=cols(nb); j++) {
			if (nb[j] > i && G.has_edge(nb[j], i)) cnt++
		}
	}
	return(cnt)
}
real rowvector change_mutual(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	if (!G.has_edge(j,i)) return(0)
	return(G.has_edge(i,j) ? -1 : 1)
}

/*
	Homophily on a single categorical node attribute (exact match,
	v1 scope - see docs/ERGM_ARCHITECTURE.md for the diff=/levels
	extension already anticipated by this same td.attr field). Counts
	ties whose two endpoints share the same (already numeric-coded)
	attribute value.
*/
real rowvector stat_nodematch(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, cnt

	ties = G.all_ties()
	cnt = 0
	for (k=1; k<=rows(ties); k++) {
		if (td.attr[ties[k,1]] == td.attr[ties[k,2]]) cnt++
	}
	return(cnt)
}
real rowvector change_nodematch(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	if (td.attr[i] != td.attr[j]) return(0)
	return(G.has_edge(i,j) ? -1 : 1)
}

/*
	Continuous node covariate (main effect): sum over ties of
	attr[i]+attr[j] - the same symmetric-sum definition Statnet's own
	nodecov uses for both directed and undirected networks (directional
	decomposition is nodeicov/nodeocov below, not a variant of plain
	nodecov itself - confirmed from the Part I study).
*/
real rowvector stat_nodecov(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, tot

	ties = G.all_ties()
	tot = 0
	for (k=1; k<=rows(ties); k++) tot = tot + td.attr[ties[k,1]] + td.attr[ties[k,2]]
	return(tot)
}
real rowvector change_nodecov(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar v
	v = td.attr[i] + td.attr[j]
	return(G.has_edge(i,j) ? -v : v)
}

/*
	Directed sender covariate: sum over arcs of the SENDER's covariate
	value (attr[tail]) - equivalently attr . outdegree. Directed only.
*/
real rowvector stat_nodeocov(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real scalar i, tot
	tot = 0
	for (i=1; i<=G.n; i++) tot = tot + td.attr[i]*G.degree_out(i)
	return(tot)
}
real rowvector change_nodeocov(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	return(G.has_edge(i,j) ? -td.attr[i] : td.attr[i])
}

/*
	Directed receiver covariate: sum over arcs of the RECEIVER's
	covariate value (attr[head]) - equivalently attr . indegree.
	Directed only.
*/
real rowvector stat_nodeicov(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real scalar i, tot
	tot = 0
	for (i=1; i<=G.n; i++) tot = tot + td.attr[i]*G.degree_in(i)
	return(tot)
}
real rowvector change_nodeicov(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	return(G.has_edge(i,j) ? -td.attr[j] : td.attr[j])
}

/*
	Dyadic covariate: sum over ties of covmat[i,j]. v1 takes a dense
	n x n matrix (docs/ERGM_ROADMAP.md records sparse-input edgecov as
	a follow-on - the term interface itself does not care how
	td.edgecovmat was populated).
*/
real rowvector stat_edgecov(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, tot

	ties = G.all_ties()
	tot = 0
	for (k=1; k<=rows(ties); k++) tot = tot + td.edgecovmat[ties[k,1], ties[k,2]]
	return(tot)
}
real rowvector change_edgecov(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar v
	v = td.edgecovmat[i,j]
	return(G.has_edge(i,j) ? -v : v)
}

/*
	Shared weighting kernel used by both the GWESP and GW(o/i)degree
	families (Hunter 2007): w(d) = exp(decay)*(1-(1-exp(-decay))^d),
	the contribution a single node/edge with "local count" d (a degree
	or a shared-partner count) makes to the sum. Both families are
	exactly "sum of w(local count) over some set of graph elements" -
	they differ only in which elements and which local count, which is
	exactly what makes k-star-family fixed-decay terms cheap additions
	once one of them exists (Stage 6/7 of the roadmap).
*/
real scalar gw_kernel(real scalar d, real scalar decay){
	return(exp(decay) * (1 - (1-exp(-decay))^d))
}

/*
	Geometrically weighted degree (Hunter 2007): sum_i w(deg(i)).
	td.decay holds the (fixed, v1 scope - curved/free decay is a
	roadmap item) decay parameter. Toggling (i,j) changes only i's and
	j's OWN degree (unlike GWESP below, no third node is affected),
	giving a much simpler two-term change statistic - useful as an
	architecturally-contrasting second nonlocal term, exactly as the
	design brief asks for.
*/
real rowvector stat_gwdegree(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real scalar i, tot
	tot = 0
	for (i=1; i<=G.n; i++) tot = tot + gw_kernel(G.degree_total(i), td.decay)
	return(tot)
}
real rowvector change_gwdegree(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, di, dj, chg

	delta = G.has_edge(i,j) ? -1 : 1
	di = G.degree_total(i)
	dj = G.degree_total(j)
	chg = (gw_kernel(di+delta, td.decay) - gw_kernel(di, td.decay))
	chg = chg + (gw_kernel(dj+delta, td.decay) - gw_kernel(dj, td.decay))
	return(chg)
}

/*
	Geometrically weighted OUT-degree (directed only): sum_i
	w(outdegree(i)). Toggling (i,j) only changes i's own out-degree.
*/
real rowvector stat_gwodegree(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real scalar i, tot
	tot = 0
	for (i=1; i<=G.n; i++) tot = tot + gw_kernel(G.degree_out(i), td.decay)
	return(tot)
}
real rowvector change_gwodegree(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, di
	delta = G.has_edge(i,j) ? -1 : 1
	di = G.degree_out(i)
	return(gw_kernel(di+delta, td.decay) - gw_kernel(di, td.decay))
}

/*
	Geometrically weighted IN-degree (directed only): sum_i
	w(indegree(i)). Toggling (i,j) only changes j's own in-degree.
*/
real rowvector stat_gwidegree(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real scalar i, tot
	tot = 0
	for (i=1; i<=G.n; i++) tot = tot + gw_kernel(G.degree_in(i), td.decay)
	return(tot)
}
real rowvector change_gwidegree(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, dj
	delta = G.has_edge(i,j) ? -1 : 1
	dj = G.degree_in(j)
	return(gw_kernel(dj+delta, td.decay) - gw_kernel(dj, td.decay))
}

/*
	Geometrically weighted edgewise shared partners (GWESP; Hunter
	2007). Undirected only in v1 (directed OTP/ITP/OSP/ISP variants -
	see the Part I study - are a roadmap item, not a cheap extension of
	this one: they need a directed common-neighbor definition this
	term does not compute). Statistic: exp(decay) * sum over edges
	(i,j) of [1-(1-exp(-decay))^p_ij], p_ij = number of shared
	partners of the tied dyad (i,j) - i.e. sum of gw_kernel(p_ij,decay)
	over edges, same kernel as GWdegree, applied to shared-partner
	counts instead of degrees.

	Change statistic for toggling (i,j) has TWO parts, computed on the
	graph BEFORE the toggle (has_edge/common_neighbors both read
	pre-toggle state, matching every other change() function's own
	contract):
	  (1) the toggled dyad's own contribution, evaluated at its current
	      shared-partner count p_ij (this does not depend on whether
	      (i,j) itself is tied - shared partners are common neighbors,
	      unrelated to the direct tie).
	  (2) for every node k that is CURRENTLY a common neighbor of both
	      i and j, the two edges (i,k) and (j,k) already exist and each
	      have their own shared-partner count shift by +-1 (matching
	      the sign of the (i,j) toggle) - their contribution to the sum
	      changes accordingly. No other edge in the graph is affected.
	This is the standard published GWESP change-statistic construction
	(confirmed against ergm's own espOTP_change macro structure during
	the Part I study, though that C code additionally maintains a
	shared-partner cache for performance - not replicated here, since
	common_neighbors() is already O(min(deg_i,deg_j)) and v1's target
	scale does not need the extra caching layer; see
	docs/ERGM_ROADMAP.md).
*/
real rowvector stat_gwesp(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, tot, p

	ties = G.all_ties()
	tot = 0
	for (k=1; k<=rows(ties); k++) {
		p = G.common_neighbors(ties[k,1], ties[k,2])
		tot = tot + gw_kernel(p, td.decay)
	}
	return(tot)
}
real rowvector change_gwesp(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, pij, chg, k, m, pik, pjk
	real rowvector nb

	delta = G.has_edge(i,j) ? -1 : 1

	pij = G.common_neighbors(i,j)
	chg = delta * gw_kernel(pij, td.decay)

	nb = G.neighbors_out(i)
	for (m=1; m<=cols(nb); m++) {
		k = nb[m]
		if (k==j) continue
		if (!G.has_edge(j,k)) continue	// k must be a common neighbor of i and j
		pik = G.common_neighbors(i,k)
		chg = chg + (gw_kernel(pik+delta, td.decay) - gw_kernel(pik, td.decay))
		pjk = G.common_neighbors(j,k)
		chg = chg + (gw_kernel(pjk+delta, td.decay) - gw_kernel(pjk, td.decay))
	}
	return(chg)
}

/* ===================================================================
   ErgmModel: an ordered list of term instances (name, npar, function
   pointers, ErgmTermData). This is the ONLY place that knows a model
   is "a list of terms" - the sampler, MPLE builder and MCMLE
   controller (below) only ever call full_statistic()/full_change(),
   never a term by name, so adding a term to the registry (see
   nwergm.ado's own Stata-side dispatch) never requires touching them.
   =================================================================== */

class ErgmModel {
	real scalar nterms
	string rowvector names		// one entry per term INSTANCE (not per coefficient)
	real rowvector npar		// coefficients contributed by each term instance
	pointer rowvector statfn	// pointer(real rowvector function) scalar, one per instance
	pointer rowvector chgfn	// pointer(real rowvector function) scalar, one per instance
	pointer rowvector td		// pointer(class ErgmTermData scalar) scalar, one per instance
	string rowvector coefnames	// flat, length = sum(npar)

	void init()
	void addterm()
	real scalar nparam()
	real rowvector full_statistic()
	real rowvector full_change()
	real rowvector change_toward_one()
	real matrix build_mple_data()
}

void ErgmModel::init(){
	nterms = 0
	names = J(1, 0, "")
	npar = J(1, 0, .)
	statfn = J(1, 0, NULL)
	chgfn = J(1, 0, NULL)
	td = J(1, 0, NULL)
	coefnames = J(1, 0, "")
}

/*
	Register one term instance. `cnames' must have length `npar' -
	the caller (nwergm.ado's term-dispatch code) is responsible for
	generating the right coefficient name(s) for this instance (e.g.
	"nodematch_sex" for a single-category match, or multiple names for
	a future diff=TRUE expansion) - the model object itself is
	agnostic to what a term "means", only how many numbers it produces.
*/
void ErgmModel::addterm(string scalar name, real scalar npar0,
	pointer(real rowvector function) scalar sfn,
	pointer(real rowvector function) scalar cfn,
	class ErgmTermData scalar td0,
	string rowvector cnames){

	nterms++
	names = (names, name)
	npar = (npar, npar0)
	statfn = (statfn, sfn)
	chgfn = (chgfn, cfn)
	td = (td, &td0)
	coefnames = (coefnames, cnames)
}

real scalar ErgmModel::nparam(){
	return(sum(npar))
}

real rowvector ErgmModel::full_statistic(class ErgmGraph scalar G){
	real rowvector out, part
	real scalar t, pos, k

	out = J(1, nparam(), 0)
	pos = 1
	for (t=1; t<=nterms; t++) {
		part = (*statfn[t])(G, *td[t])
		for (k=1; k<=npar[t]; k++) {
			out[pos] = part[k]
			pos++
		}
	}
	return(out)
}

real rowvector ErgmModel::full_change(class ErgmGraph scalar G, real scalar i, real scalar j){
	real rowvector out, part
	real scalar t, pos, k

	out = J(1, nparam(), 0)
	pos = 1
	for (t=1; t<=nterms; t++) {
		part = (*chgfn[t])(G, i, j, *td[t])
		for (k=1; k<=npar[t]; k++) {
			out[pos] = part[k]
			pos++
		}
	}
	return(out)
}

/* ===================================================================
   Certification helper (Part IX of the design brief): compares the
   model's own change() output against brute-force full recomputation
   (statistic() before, toggle, statistic() after, difference) - the
   permanent contract every term must satisfy. Returns the maximum
   absolute discrepancy across all toggles tried; a caller (see
   cscripts/test_nwergm_changestat.do) asserts this is ~0 across many
   random small networks and every registered term, before any MCMC or
   estimation code is ever trusted to consume that term's change().
   =================================================================== */
real scalar ErgmCertifyChangeStat(class ErgmModel scalar M, class ErgmGraph scalar G){
	real scalar i, j, maxdiff
	real rowvector s0, s1, chg, diff

	maxdiff = 0
	for (i=1; i<=G.n; i++) {
		for (j=1; j<=G.n; j++) {
			if (i==j) continue
			if (!G.directed && j<i) continue
			s0 = M.full_statistic(G)
			chg = M.full_change(G, i, j)
			G.toggle(i,j)
			s1 = M.full_statistic(G)
			G.toggle(i,j)	// restore
			diff = abs((s1 - s0) - chg)
			if (max(diff) > maxdiff) maxdiff = max(diff)
		}
	}
	return(maxdiff)
}

/* ===================================================================
   MPLE (maximum pseudolikelihood estimation; Hunter & Handcock 2006 -
   see docs/ERGM_STATNET_STUDY.md Appendix A section 5). For every dyad
   (i,j), the change statistic "toward tie present" (NOT the raw
   change() value, which is signed by the dyad's CURRENT state - a tied
   dyad's own change() returns the REMOVAL effect, the negative of the
   addition effect) is used as a row of covariates; the observed tie
   indicator is the response. Fitting
       logit P(Y_ij=1 | Y_-ij) = theta' * covariates_ij
   by ordinary logistic regression on this design (done in Stata, via
   nwergm.ado, not here - see Part XII of the governing task brief: use
   Stata's own logit rather than reimplementing IRLS) recovers the MPLE
   theta. This is exactly the MLE when every term is dyad-independent
   AND the sample space itself is unconstrained (the "MPLE_is_MLE"
   shortcut Statnet itself also takes - see docs/ERGM_STATNET_STUDY.md
   section 1 step 5); it is the STARTING VALUE for MCMLE otherwise.
   =================================================================== */

/*
	Change statistic for dyad (i,j) in the "toward tie present"
	direction, regardless of the dyad's current state - i.e. Δg_ij
	always means "value of g if Y_ij were set to 1", not "value of g if
	the CURRENT tie were toggled". change() itself is antisymmetric in
	the toggle direction (removing an existing tie is exactly the
	negative of adding it back), so this is simply change() negated
	when the dyad is currently tied.
*/
real rowvector ErgmModel::change_toward_one(class ErgmGraph scalar G, real scalar i, real scalar j){
	real rowvector chg

	chg = full_change(G, i, j)
	if (G.has_edge(i,j)) return(-chg)
	return(chg)
}

/*
	Build the MPLE design: one row per dyad (ordered pairs for a
	directed graph, i<j unordered pairs for undirected), columns =
	change_toward_one()'s own nparam() covariates, final column = the
	observed tie indicator (the response). Returned as a single real
	matrix - nwergm.ado splits it into a Stata dataset (covariates +
	response variable) and calls `logit ..., noconstant` (noconstant:
	the edges term already plays the role of an intercept; adding a
	second, redundant constant would make the design rank-deficient).
*/
real matrix ErgmModel::build_mple_data(class ErgmGraph scalar G){
	real matrix out
	real scalar i, j, ndyads, pos, p

	p = nparam()
	if (G.directed) ndyads = G.n * (G.n - 1)
	else ndyads = G.n * (G.n - 1) / 2

	out = J(ndyads, p+1, 0)
	pos = 1
	for (i=1; i<=G.n; i++) {
		for (j=1; j<=G.n; j++) {
			if (i==j) continue
			if (!G.directed && j<i) continue
			out[pos, (1..p)] = change_toward_one(G, i, j)
			out[pos, p+1] = G.has_edge(i,j)
			pos++
		}
	}
	return(out)
}

end

mata:

/* ===================================================================
   MCMC engine: Metropolis-Hastings simulation over binary graph space
   (Part X of the governing task brief). A proposal is a plain Mata
   function with the fixed signature

       real rowvector fn(class ErgmGraph scalar G)
           -> (tail, head, logratio)

   returning the proposed dyad and the log Hastings-ratio correction for
   its own selection asymmetry (0 for a symmetric proposal). Proposals
   know NOTHING about terms/change statistics, and terms know NOTHING
   about how a toggle was chosen - the same separation Statnet's own
   MHProposal/ModelTerm split enforces (docs/ERGM_STATNET_STUDY.md
   Appendix B §6), confirmed as the right design rather than reinvented.
   Adding a future proposal (e.g. a degree-constrained or block-
   restricted one) means writing one such function; the sampler loop
   below never changes.
   =================================================================== */

real scalar ergm_total_dyads(class ErgmGraph scalar G){
	if (G.directed) return(G.n * (G.n - 1))
	return(G.n * (G.n - 1) / 2)
}

/*
	Uniform-random-dyad proposal: pick any of the D possible dyads with
	equal probability, tie or not. Symmetric (logratio=0) - the
	simplest possible correct MH proposal, and the natural fallback/
	baseline `nwergm` ships alongside TNT.
*/
real rowvector ergm_propose_uniform(class ErgmGraph scalar G){
	real scalar i, j, pick, row, col

	pick = ceil(runiform(1,1) * ergm_total_dyads(G))
	if (G.directed) {
		// linear index -> (i,j), i != j, over the n x (n-1) directed dyad space
		row = ceil(pick / (G.n - 1))
		col = mod(pick - 1, G.n - 1) + 1
		i = row
		j = (col < row) ? col : col + 1
	}
	else {
		// linear index -> unordered pair (i,j), i<j, row-major over the
		// upper triangle
		i = 1
		while (pick > G.n - i) {
			pick = pick - (G.n - i)
			i++
		}
		j = i + pick
	}
	return((i, j, 0))
}

/*
	TNT ("tie/no-tie") proposal (Morris, Handcock & Hunter 2008 - see
	docs/ERGM_STATNET_STUDY.md Appendix B §6 for the exact formulas this
	reproduces, re-derived from the published construction, independently
	confirmed against the actual shipped Statnet constants during the
	Part I study). With probability P=0.5, propose removing a uniformly
	random EXISTING tie; otherwise (Q=1-P=0.5) propose toggling a
	uniformly random dyad from the FULL dyad space (which may or may not
	already be a tie). This dramatically improves mixing on sparse
	networks relative to the uniform proposal above, whose vast majority
	of draws land on non-ties and therefore almost never propose removing
	anything - without TNT's own Hastings-ratio correction below, this
	deliberately non-uniform proposal density would target the WRONG
	stationary distribution.

	Picking "a uniformly random existing edge" is done here by
	materializing the current tie list (ErgmGraph::all_ties(),
	O(n+nties)) and indexing into it - correct, and a documented,
	deliberate v1 simplification (see docs/ERGM_ROADMAP.md's own
	"maintain a live edge list for O(1) TNT edge-picks" performance
	item) rather than the O(1) live-edge-list Statnet's own C
	implementation maintains.
*/
real rowvector ergm_propose_tnt(class ErgmGraph scalar G){
	real scalar Dtot, E, P, Q, DP, DO, i, j, logratio, pickedge, erow
	real matrix ties
	real rowvector uprop

	Dtot = ergm_total_dyads(G)
	E = G.nties
	P = 0.5
	Q = 0.5
	DP = P * Dtot
	DO = DP / Q

	pickedge = 0
	if (runiform(1,1) < P & E > 0) pickedge = 1

	if (pickedge) {
		ties = G.all_ties()
		erow = ceil(runiform(1,1)*E)
		i = ties[erow, 1]
		j = ties[erow, 2]
	}
	else {
		uprop = ergm_propose_uniform(G)
		i = uprop[1]
		j = uprop[2]
	}

	if (G.has_edge(i,j)) {
		// removal proposal, regardless of which branch produced it
		logratio = (E==1) ? -ln(DP+Q) : ln(E :/ (DO+E))
	}
	else {
		// addition proposal
		logratio = (E==0) ? ln(DP+Q) : ln(1 + DO :/ (E+1))
	}
	return((i, j, logratio))
}

/*
	Metropolis-Hastings simulation. `proposalfn' has the fixed
	`ergm_propose_*' signature above. Mutates G in place (its final
	state is the last accepted network in the chain - callers that need
	the ORIGINAL observed network preserved must pass a copy, e.g. via
	ErgmGraph's own field-by-field duplication, matching how nwqap's own
	permutation loop protects the observed network). Returns a
   (samplesize x nparam) matrix of the model's sufficient statistics,
   one row per post-interval draw, starting the running total from G's
   own CURRENT statistic() (not from zero) so the returned rows are
   statistic LEVELS, not deviations - matching Statnet's own convention
   (docs/ERGM_STATNET_STUDY.md Appendix B §5) and letting a caller
   compare them directly against the observed network's own statistic.
*/
real matrix ErgmMCMCSample(class ErgmModel scalar M, class ErgmGraph scalar G,
	real rowvector theta, real scalar burnin, real scalar interval,
	real scalar samplesize, pointer(real rowvector function) scalar proposalfn){

	real rowvector cur, prop, chg
	real scalar step, draw, tail, head, logratio, cutoff
	real matrix out

	cur = M.full_statistic(G)
	out = J(samplesize, cols(cur), 0)

	for (step=1; step<=burnin; step++) {
		prop = (*proposalfn)(G)
		tail = prop[1]
		head = prop[2]
		logratio = prop[3]
		chg = M.full_change(G, tail, head)
		cutoff = (theta * chg') + logratio
		if (cutoff >= 0 | ln(runiform(1,1)) < cutoff) {
			G.toggle(tail, head)
			cur = cur + chg
		}
	}

	for (draw=1; draw<=samplesize; draw++) {
		for (step=1; step<=interval; step++) {
			prop = (*proposalfn)(G)
			tail = prop[1]
			head = prop[2]
			logratio = prop[3]
			chg = M.full_change(G, tail, head)
			cutoff = (theta * chg') + logratio
			if (cutoff >= 0 | ln(runiform(1,1)) < cutoff) {
				G.toggle(tail, head)
				cur = cur + chg
			}
		}
		out[draw, .] = cur
	}
	return(out)
}

end

mata:

/* ===================================================================
   MCMLE (Monte Carlo maximum likelihood; Geyer & Thompson 1992,
   Hummel/Hunter/Handcock 2012 - see docs/ERGM_STATNET_STUDY.md
   Appendix A §6 for the full algorithm this is a deliberately
   simplified version of). Outer loop: simulate at the current theta,
   take a Newton step on the "naive" (non-lognormal) importance-
   sampling surrogate log-likelihood using the simulated sample's own
   mean/covariance of the CENTERED statistics (centered on the observed
   network's own statistic - the target is exactly Dbar=0), continuing
   sequentially (MCMLE.sequential=TRUE, Statnet's own default: the
   network carries over between iterations rather than restarting from
   the observed network every time - docs/ERGM_STATNET_STUDY.md
   Appendix A §9).

   Step length: rather than Hummel's own convex-hull linear program
   (no general LP solver is available in Mata - see
   docs/ERGM_STATNET_STUDY.md Appendix A §6a's own explicit
   recommendation), v1 uses a trust-region-style cap on the Newton
   step's own Mahalanobis norm (in the metric of the simulated sample's
   covariance) - a simpler, well-understood damping device serving the
   same purpose (never trust a Newton step further than the region the
   current MC sample actually informs), disclosed here as a deliberate
   simplification rather than a reproduction of Hummel's own exact
   procedure. Convergence: stop when every component of the centered
   sample mean is small relative to its own Monte Carlo standard error
   AND the last step was untruncated (gamma==1) - a simplified stand-in
   for Statnet's own default "confidence" (Hotelling T²) test, disclosed
   the same way.

   Final variance-covariance: `Bread' = the covariance of the
   sufficient statistics from a FRESH simulation at the final theta
   (not reused from a step-shrunk intermediate sample);
   `e(V) = Bread^-1', with a simple lag-1-autocorrelation inflation
   factor `(1+rho)/(1-rho)' applied per statistic dimension before
   inverting - a basic, disclosed stand-in for Statnet's own spectral/
   HAC long-run-variance correction (docs/ERGM_STATNET_STUDY.md
   Appendix A §7's own explicit finding that skipping this correction
   entirely would give systematically too-small standard errors).
   =================================================================== */

struct ErgmMCMLEFit {
	real rowvector coef
	real matrix vcov
	real scalar converged
	real scalar niter
	real matrix coefhist
}

/*
	Lag-1 autocorrelation of each column of `samp' (one row per
	MCMC draw, already thinned by `interval' - so this is the
	draw-to-draw autocorrelation of the RECORDED chain, not of every
	raw MCMC step). Returns a row vector, one value per column.
*/
real rowvector ergm_lag1_autocorr(real matrix samp){
	real scalar ndraw, k, ncol
	real matrix x0, x1
	real rowvector out

	ndraw = rows(samp)
	ncol = cols(samp)
	out = J(1, ncol, 0)
	if (ndraw < 3) return(out)
	x0 = samp[1::(ndraw-1), .]
	x1 = samp[2::ndraw, .]
	for (k=1; k<=ncol; k++) {
		if (variance(x0[.,k])==0 | variance(x1[.,k])==0) {
			out[k] = 0
		}
		else {
			out[k] = correlation((x0[.,k], x1[.,k]))[1,2]
		}
	}
	return(out)
}

struct ErgmMCMLEFit scalar ErgmMCMLE(class ErgmModel scalar M, class ErgmGraph scalar G,
	real rowvector theta0, real scalar maxit, real scalar burnin, real scalar interval,
	real scalar samplesize, pointer(real rowvector function) scalar proposalfn,
	real scalar verbose){

	struct ErgmMCMLEFit scalar res
	real rowvector obs, theta, Dbar, delta, se, rho, infl
	real matrix samp, D, V, Vinv, coefhist
	real scalar iter, p, mahal, gamma, converged, k

	obs = M.full_statistic(G)
	theta = theta0
	p = cols(theta)
	coefhist = J(0, p, 0)
	converged = 0

	for (iter=1; iter<=maxit; iter++) {
		samp = ErgmMCMCSample(M, G, theta, burnin, interval, samplesize, proposalfn)
		D = samp :- obs
		Dbar = mean(D)
		V = variance(D)
		Vinv = invsym(V)
		delta = -Dbar * Vinv

		mahal = sqrt(delta * V * delta')
		gamma = (mahal > 2 ? 2/mahal : 1)

		theta = theta + gamma*delta
		coefhist = coefhist \ theta

		se = sqrt(diagonal(V)/samplesize)'
		if (verbose) {
			printf("MCMLE iter %g: steplen=%5.3f theta=", iter, gamma)
			for (k=1; k<=p; k++) printf("%9.5f ", theta[k])
			printf(" max|Dbar/se|=%6.3f\n", max(abs(Dbar :/ se)))
		}
		if (all(abs(Dbar) :< 0.5*se) & gamma==1) {
			converged = 1
			break
		}
	}

	// Final variance-covariance from a fresh simulation at the
	// converged (or last-tried) theta.
	samp = ErgmMCMCSample(M, G, theta, burnin, interval, samplesize, proposalfn)
	V = variance(samp)
	rho = ergm_lag1_autocorr(samp)
	infl = (1 :+ rho) :/ (1 :- rho)
	for (k=1; k<=p; k++) V[k,k] = V[k,k] * infl[k]

	res.coef = theta
	res.vcov = invsym(V)
	res.converged = converged
	res.niter = iter <= maxit ? iter : maxit
	res.coefhist = coefhist
	return(res)
}

end
