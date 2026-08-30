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
	real matrix elist		// live-edge array: rows 1..nties hold canonical (i,j)
					// pairs for every current tie (directed: (tail,head)
					// as toggled; undirected: (min,max)); rows beyond
					// nties are stale capacity, never read. Maintained
					// incrementally by toggle() (O(1)-amortized append
					// via capacity doubling, O(1) removal via swap-
					// with-last) so TNT's own tie-pick never has to
					// rebuild the tie list from scratch - see
					// ergm_propose_tnt()'s own header comment and
					// docs/CERTIFICATION.md's harmonisation-unit-80
					// entry for the benchmarked payoff (this replaced
					// an O(n+nties)-per-proposal cost measured at
					// ~185x the uniform proposal's own cost).
	pointer scalar edgepos		// asarray("real",2): canonical (i,j) -> row
					// index (1..nties) in elist, for O(1) removal.
	real scalar sp_cache_enabled	// 0 unless enable_sp_cache() has been
					// called (opt-in - see that method's own
					// header comment for why); toggle() checks
					// this once (a single boolean test) before
					// doing any shared-partner bookkeeping, so
					// models that never use gwesp pay nothing.
	pointer scalar sp_counts	// asarray("real",2), only allocated when
					// sp_cache_enabled: canonical (a,b) -> current
					// shared-partner count. Sparse - pairs with a
					// count of 0 are simply absent, never stored.
	real scalar bipartite		// 0 (default, one-mode) or 1 - set once via
					// set_bipartite(), never touched by init()
					// itself, mirroring sp_cache_enabled's own
					// "opt-in, called once after init" contract.
	real colvector mode		// n x 1, 1/2 per node - only meaningful when
					// bipartite==1. Deliberately NOT the R/Statnet
					// convention of "mode-1 nodes are a contiguous
					// 1..bipartite prefix" - every other part of
					// this package (nodecov/nodematch/edgecov/...)
					// already assumes node index i is exactly
					// nwset's own row/label order with no
					// reordering anywhere, so this field is a
					// general, non-contiguous per-node label
					// instead (see docs/ERGM_ROADMAP.md's own
					// bipartite-terms planning note for the full
					// reasoning).
	real colvector mode1nodes	// cached node indices with mode==1, built
	real colvector mode2nodes	// once by set_bipartite() - every bipartite
					// dyad-space computation (proposal, MPLE
					// design matrix, brute-force certification)
					// works off these two lists, never re-scans
					// `mode` itself.
	real scalar has_dyadmask	// 0 (default) or 1 - set once via
					// set_dyadmask() (constraints, first piece -
					// docs/ERGM_ROADMAP.md's "Constraints beyond
					// v1's free binary dyad space" row), mirroring
					// bipartite/sp_cache_enabled's own "opt-in flag,
					// never touched by init() again" contract.
					// Read ONLY by the proposal layer
					// (ergm_propose_uniform_masked(),
					// ErgmNativeSetup()'s own native-ineligibility
					// check) - full_statistic()/MPLE's own design-
					// matrix build never consult it, deliberately:
					// a "fixed" dyad still contributes its true
					// observed state to every term's sufficient
					// statistic, only the MCMC proposal is barred
					// from ever touching it.
	real matrix freedyadmat		// n x n boolean (1 = eligible/free, 0 =
					// fixed at its current observed value);
					// only meaningful when has_dyadmask==1.
	real scalar nfreedyads		// total FREE dyad count over the canonical
					// dyad space (bipartite/directed/undirected,
					// same walk _ergm_count_free_onemode()/
					// _ergm_count_free_bipartite() use) - a
					// constant, computed once by set_dyadmask()
					// (dyad ELIGIBILITY never changes mid-fit,
					// only which free dyads are currently tied
					// does) - ergm_propose_tnt_masked()'s own D.
	real matrix freeelist		// live list of CURRENTLY TIED dyads that
					// are ALSO free, same (i,j)-canonical/
					// O(1)-amortized-append/O(1)-swap-removal
					// contract as elist above, restricted to
					// the free subspace - only meaningful when
					// has_dyadmask==1, maintained by
					// set_dyadmask() (initial population from
					// the observed network) and toggle() (kept
					// current thereafter, gated on
					// freedyadmat[.] so a toggle on a fixed
					// dyad - never proposed during masked MCMC,
					// but not assumed impossible - cannot
					// corrupt it). ergm_propose_tnt_masked()'s
					// own "pick a random existing FREE tie"
					// branch needs this: G.elist also holds
					// FIXED ties, which must never be proposed
					// for removal.
	pointer scalar freeedgepos	// asarray("real",2): canonical (i,j) -> row
					// index (1..nfreeties) in freeelist, for
					// O(1) removal - the freeelist analogue of
					// edgepos above.
	real scalar nfreeties		// current count of live rows in freeelist
					// (<=nties always, since every free tie is
					// also a tie) - ergm_propose_tnt_masked()'s
					// own E.

	void init()
	void set_bipartite()
	void set_dyadmask()
	real scalar has_edge()
	void toggle()
	real rowvector neighbors_out()
	real rowvector neighbors_in()
	real scalar degree_out()
	real scalar degree_in()
	real scalar degree_total()
	real scalar common_neighbors()
	real matrix all_ties()
	real matrix to_dense()
	void enable_sp_cache()
	void sp_adjust()
	real scalar shared_partners()
	real scalar shared_partners_otp()
	real scalar shared_partners_itp()
	real scalar shared_partners_osp()
	real scalar shared_partners_isp()
	real scalar common_neighbors_in()
	real scalar shared_partners_rtp()
	real rowvector mutual_neighbors()
}

void ErgmGraph::init(real scalar n0, real scalar directed0){
	real scalar i

	n = n0
	directed = directed0
	dout = J(n, 1, 0)
	din  = J(n, 1, 0)
	nties = 0
	elist = J(8, 2, 0)
	edgepos = &(asarray_create("real", 2))
	sp_cache_enabled = 0
	bipartite = 0
	has_dyadmask = 0
	nfreedyads = 0
	nfreeties = 0

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

/*
	Opt-in bipartite marking (harmonisation unit 155 - see
	docs/ERGM_ROADMAP.md's own bipartite-terms plan), called once
	right after init(), mirroring enable_sp_cache()'s own contract.
	Deliberately does NOT reorder nodes or touch `directed` - a
	bipartite network is always undirected (nwergm.ado's own caller
	enforces this before ever reaching here, matching a real hard
	limit in R ergm itself, not a v1 simplification) - this method
	only records which of the two modes each existing node index
	belongs to. `modevec' is a real colvector, one entry per node,
	each either 1 or 2 - the exact numeric form nwergm.ado builds from
	NWdef::get_modes()'s own "1"/"2" string vector. Every downstream
	bipartite dyad-space computation (ergm_total_dyads(),
	ergm_propose_uniform(), ErgmModel::build_mple_data(),
	ErgmCertifyChangeStat()) reads mode1nodes/mode2nodes, built once
	here via selectindex(), never modevec directly.
*/
void ErgmGraph::set_bipartite(real colvector modevec){
	bipartite = 1
	mode = modevec
	// BUGFIX (harmonisation unit 155): selectindex() PRESERVES its
	// input's own orientation (a colvector argument returns a
	// colvector of indices, not a rowvector) - confirmed directly via
	// a standalone Mata repro, since this is easy to get backwards.
	// The original code here transposed the (already-correct) colvector
	// result, silently turning mode1nodes/mode2nodes into ROW vectors;
	// every caller's own rows(G.mode1nodes)/rows(G.mode2nodes) (the
	// mode-1/mode-2 node COUNT) then read as 1 regardless of the true
	// node counts, collapsing ergm_total_dyads()'s own bipartite branch
	// to always report 1 total dyad - caught via a real end-to-end
	// smoke test on an actual bipartite network (6x4 nodes), not by
	// inspection.
	mode1nodes = selectindex(modevec :== 1)
	mode2nodes = selectindex(modevec :== 2)
}

/*
	Opt-in dyad-eligibility mask (constraints, first piece -
	docs/ERGM_ROADMAP.md's "Constraints beyond v1's free binary dyad
	space" row - R ergm's own `constraints=~fixallbut(free)`), called
	once right after init()/set_bipartite(), mirroring their own
	"opt-in flag, never touched again by init()" contract. `freemat' is
	a dense n x n binary matrix (1 = this dyad may be toggled by the MCMC
	proposal; 0 = permanently fixed at its current/observed value) - the
	SAME dense-matrix shape edgecov()/hamming() already use for a
	dyadic-covariate argument (nwergm.ado builds it identically, via
	get_matrix_mod(0,...) on a second network whose own ties mark the
	free dyads), reused here as a boolean mask rather than a covariate
	weight.

	Deliberately does nothing beyond recording the mask - it does NOT
	touch any of `netname''s own current ties. Fixed dyads keep
	contributing their true observed state to every term's sufficient
	statistic for the rest of this fit (ErgmModel::full_statistic()/MPLE
	design-matrix construction never consult has_dyadmask/freedyadmat at
	all); only ergm_propose_uniform_masked() (and ErgmNativeSetup()'s own
	native-ineligibility check, since the native backend has no wire-
	protocol field for this yet - a disclosed v1 follow-on) ever reads
	these two fields. Errors out on an all-fixed mask (zero free dyads) -
	a degenerate constraint no MCMC proposal could ever satisfy - rather
	than let ergm_propose_uniform_masked()'s own rejection loop spin
	forever.
*/
/*
	blockdiag(attr) (constraints, second piece - docs/ERGM_ROADMAP.md's
	"Constraints beyond v1's free binary dyad space" row): R ergm's own
	`constraints=~blockdiag(attr)` - "Only dyads (i,j) for which
	attr(i)==attr(j) can have edges" (R ergm's own real Rd doc,
	blockdiag-ergmConstraint, fetched fresh via tools::Rd_db("ergm"), not
	guessed). This is nothing more than a DIFFERENT way to build the exact
	same dense n x n eligibility mask set_dyadmask() already consumes for
	freedyads() - a dyad is free iff its two endpoints share the same
	attribute value, full stop, no new proposal/native machinery needed.
	Builds the n x n outer-product expansion of `attr' against itself via
	explicit matrix multiplication (`attr * J(1,n,1)' broadcasts attr
	across columns, `J(n,1,1) * attr'' broadcasts it across rows), THEN
	compares elementwise - NOT `attr :== attr'' directly, which looks
	like it should work (an n x 1 colvector against its own 1 x n
	transpose, one dimension matching per axis) but does not: confirmed
	directly (empirically, not from documentation alone) that Mata's
	colon operators require an EXACT dimension match or a genuine 1x1
	scalar operand on one side - they do NOT perform outer-product-style
	broadcasting between an n x 1 and a 1 x n operand the way e.g. numpy
	does (`J(3,1,1) :+ J(1,3,1)' itself throws the identical conformability
	error, isolating this as a general colon-operator property, not
	something specific to `:=='' or to this one call). The diagonal comes
	out `true' too (attr[i]==attr[i] always), but that is never consulted
	by anything downstream (no dyad ever has i==j).
*/
real matrix _ergm_blockdiag_mask(real colvector attr){
	real scalar n
	n = rows(attr)
	return((attr * J(1,n,1)) :== (J(n,1,1) * attr'))
}

void ErgmGraph::set_dyadmask(real matrix freemat){
	real scalar i, j, a, b
	real matrix obs

	has_dyadmask = 1
	freedyadmat = freemat
	if (sum(freemat) == 0) {
		errprintf("freedyads()/blockdiag(): the given dyad-eligibility mask leaves no free dyad at all (freedyads(): an all-untied network; blockdiag(): every node in its own singleton block) - every dyad would be fixed, leaving no dyad for the MCMC proposal to ever toggle.\n")
		exit(error(198))
	}

	// nfreedyads: total free-dyad count over the SAME canonical dyad-space
	// walk _ergm_count_free_onemode()/_ergm_count_free_bipartite() already
	// use for build_mple_data()'s own preallocation - inlined here rather
	// than called (those two are free functions taking G as a parameter;
	// a method has no "self" handle to pass itself as one) rather than
	// duplicated logic drifting from theirs, since both walks are the
	// exact same canonical-dyad enumeration this file already establishes
	// elsewhere (ergm_total_dyads(), all_ties(), build_mple_data()).
	nfreedyads = 0
	if (bipartite) {
		for (a=1; a<=rows(mode1nodes); a++) {
			for (b=1; b<=rows(mode2nodes); b++) {
				if (freedyadmat[mode1nodes[a], mode2nodes[b]]) nfreedyads++
			}
		}
	}
	else {
		for (i=1; i<=n; i++) {
			for (j=1; j<=n; j++) {
				if (i==j) continue
				if (!directed && j<i) continue
				if (freedyadmat[i,j]) nfreedyads++
			}
		}
	}

	// Live free-tie list (ergm_propose_tnt_masked()'s own "pick a random
	// existing FREE tie" branch) - populated from the network's CURRENT
	// ties, which at this point are exactly the OBSERVED ties (this
	// method is always called immediately after the graph is built from
	// the observed network, before any MCMC toggle ever runs).
	freeelist = J(8, 2, 0)
	freeedgepos = &(asarray_create("real", 2))
	nfreeties = 0
	obs = all_ties()
	for (i=1; i<=rows(obs); i++) {
		if (freedyadmat[obs[i,1], obs[i,2]]) {
			nfreeties++
			if (nfreeties > rows(freeelist)) freeelist = freeelist \ J(rows(freeelist), 2, 0)
			freeelist[nfreeties, .] = obs[i, .]
			asarray(*freeedgepos, (obs[i,1], obs[i,2]), nfreeties)
		}
	}
}

real scalar ErgmGraph::has_edge(real scalar i, real scalar j){
	return(asarray_contains(*adjout[i], j))
}

void ErgmGraph::toggle(real scalar i, real scalar j){
	real scalar ci, cj, k, was_edge, m, x
	real rowvector nbi, nbj

	ci = directed ? i : min((i,j))
	cj = directed ? j : max((i,j))
	was_edge = has_edge(i, j)

	// Shared-partner cache bookkeeping needs i's and j's own neighbor
	// sets exactly as they stand BEFORE this toggle mutates anything
	// below - captured here, once, regardless of add/remove, then
	// applied after the normal adjacency/elist bookkeeping (see
	// enable_sp_cache()'s own header comment for why this update is
	// correct and why it is a SEPARATE derivation from that method's
	// own from-scratch initialization formula).
	if (sp_cache_enabled) {
		nbi = neighbors_out(i)
		nbj = neighbors_out(j)
	}

	if (was_edge) {
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
		// O(1) removal from the live edge list: move the CURRENT LAST
		// live row into the removed edge's own slot (unless it already
		// IS the last row), then shrink the live count - never shifts
		// or rebuilds the rest of the array.
		k = asarray(*edgepos, (ci,cj))
		if (k != nties) {
			elist[k, .] = elist[nties, .]
			asarray(*edgepos, (elist[k,1], elist[k,2]), k)
		}
		asarray_remove(*edgepos, (ci,cj))
		nties = nties - 1
		// freedyads() follow-on (masked TNT, docs/ERGM_ROADMAP.md's
		// "Constraints beyond v1's free binary dyad space" row): mirror
		// the SAME O(1) swap-removal into freeelist/freeedgepos, but
		// ONLY for a free dyad - gated on has_dyadmask (a single cheap
		// flag check, mirroring sp_cache_enabled's own "pay nothing when
		// unused" contract) and freedyadmat[ci,cj] (masked MCMC only
		// ever toggles free dyads, but this method has no way to assume
		// that of every caller - e.g. a future code path calling
		// toggle() directly on a fixed dyad must never corrupt this
		// list, so the check stays explicit rather than assumed).
		if (has_dyadmask) if (freedyadmat[ci,cj]) {
			k = asarray(*freeedgepos, (ci,cj))
			if (k != nfreeties) {
				freeelist[k, .] = freeelist[nfreeties, .]
				asarray(*freeedgepos, (freeelist[k,1], freeelist[k,2]), k)
			}
			asarray_remove(*freeedgepos, (ci,cj))
			nfreeties = nfreeties - 1
		}
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
		// O(1)-amortized append: double elist's own capacity only when
		// the live count would exceed it (standard dynamic-array
		// doubling - each doubling costs O(current capacity) but
		// happens only log2(nties) times in total), rather than
		// reallocating on every single toggle.
		if (nties > rows(elist)) elist = elist \ J(rows(elist), 2, 0)
		elist[nties, .] = (ci, cj)
		asarray(*edgepos, (ci,cj), nties)
		if (has_dyadmask) if (freedyadmat[ci,cj]) {
			nfreeties = nfreeties + 1
			if (nfreeties > rows(freeelist)) freeelist = freeelist \ J(rows(freeelist), 2, 0)
			freeelist[nfreeties, .] = (ci, cj)
			asarray(*freeedgepos, (ci,cj), nfreeties)
		}
	}

	// Adding tie (i,j) makes j a NEW shared-partner contributor for
	// every pair (i,x) where x is (already) a neighbor of j - and
	// symmetrically i for every pair (j,x); removing (i,j) undoes
	// exactly that. O(deg_i + deg_j) per toggle, not O(min(deg_i,deg_j))
	// per LOOKUP the way on-demand common_neighbors() costs when this
	// cache is not enabled.
	if (sp_cache_enabled) {
		m = was_edge ? -1 : 1
		for (x=1; x<=cols(nbj); x++) {
			if (nbj[x] != i) sp_adjust(i, nbj[x], m)
		}
		for (x=1; x<=cols(nbi); x++) {
			if (nbi[x] != j) sp_adjust(j, nbi[x], m)
		}
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
	Harmonisation unit 145: the safe, data-driven per-count-basis upper
	bound the curved-MPLE registration sites in nwergm.ado use in place
	of the theoretical worst case (`nodes-2`/`nodes-1`) - see
	ErgmCurvedMPLEFit()'s own header comment (below) for why the
	registered basis width matters so much for curved-MPLE performance,
	and docs/CERTIFICATION.md unit 145 for the real-network profiling
	that motivated this (a 418-node network's own true maximum
	edgewise-shared-partner value was 10, not the 416 the unconditional
	`nodes-2` bound registered).

	`mode' selects which degree notion bounds the caller's own curved
	term: `"total"' for the shared-partner-count family (gwespfree()/
	gwdspfree() - a toggled or hypothetically-toggled dyad's own
	shared-partner count is |N(i) intersect N(j)|, never exceeding
	min(deg(i),deg(j)), so the network's own overall MAXIMUM total
	degree is a safe - if not perfectly tight - upper bound across every
	dyad); `"out"'/`"in"' for the directed degree-count family
	(gwodegreefree()/gwidegreefree() - a single dyad toggle changes
	exactly one node's own out-/in-degree by +-1, so the highest
	reachable value across every dyad's own change statistic is that
	network's own current maximum out-/in-degree, PLUS ONE for the
	toggle-on case, added by the caller, not here - matching
	gwdegreefree()'s own undirected "total" case, which needs the same
	+1 treatment at its own call site). Always O(n) - one pass over
	every node's own already-materialized degree - not the true tightest
	possible bound (that would need an O(sum deg^2) common-neighbor scan
	for the shared-partner family specifically), a deliberate, safe,
	cheap-to-certify simplification: NEVER too tight (so never wrong),
	simply not always the smallest correct answer.
*/
real scalar ergm_graph_maxdegree(class ErgmGraph scalar G, string scalar mode){
	real scalar n, i, best, d

	n = G.n
	best = 0
	for (i=1; i<=n; i++) {
		if (mode == "out") d = G.degree_out(i)
		else if (mode == "in") d = G.degree_in(i)
		else d = G.degree_total(i)
		if (d > best) best = d
	}
	return(best)
}

/*
	The TRUE tightest per-count-basis bound for the shared-partner
	curved-term family (gwespfree()/gwdspfree()) - the real maximum
	edgewise-shared-partner value over any dyad in the network, not the
	cheaper, structurally-safe-but-looser max_degree bound
	ergm_graph_maxdegree() above provides (harmonisation unit 145's own
	first pass). Computed via the IDENTICAL O(sum_i deg_i^2) algorithm
	`ErgmGraph::enable_sp_cache()' already uses and this codebase already
	certified there (for each node, every unordered pair of its own
	neighbors shares that node as one common neighbor) - deliberately
	NOT calling enable_sp_cache() itself, since that mutates the graph's
	own persistent cache state (`sp_counts'/`sp_cache_enabled') for
	later toggle-time maintenance, a real side effect this function has
	no business causing at term-registration time; this is a one-time,
	read-only snapshot maximum via a local, transient counter instead.
	On `ecoli2' (harmonisation unit 145's own real-network motivation)
	this returns 10, against ergm_graph_maxdegree()'s own 72 - a real,
	further 7.2x reduction in the registered per-count basis width, and
	up to that squared in the Newton-Raphson loop's own dominant
	O(ncol^2) Fisher-information step.

	CALLERS MUST ADD 1 to this function's own return value before using
	it as a basis width, exactly as ergm_graph_maxdegree()'s own callers
	already do for the degree-count family - a first version of this
	function's caller omitted that +1 and broke a real certification
	network (`estimates post: matrix has missing values' on the 15-node
	network test_nwergm_ado.do uses to certify gwespfree() against R),
	root-caused after reverting: THIS function correctly returns the
	network's own CURRENT true maximum common-neighbor count, but a
	single dyad's own toggle can raise a DIFFERENT, already-adjacent
	dyad's shared-partner count by exactly one (toggling i-j on adds j
	as a new common neighbor to every dyad (i,k) where k is already a
	neighbor of j, and vice versa) - the same "+1 for what one toggle
	can reach beyond the network's own current state" property
	ergm_graph_maxdegree()'s own callers already account for, this
	function's own callers must too.
*/
real scalar ergm_graph_max_shared_partners(class ErgmGraph scalar G){
	real scalar n, i, j1, j2, m, best, cur
	real rowvector nb
	transmorphic scalar counts_aa

	n = G.n
	best = 0
	counts_aa = asarray_create("real", 2)
	for (i=1; i<=n; i++) {
		nb = G.neighbors_out(i)
		m = cols(nb)
		for (j1=1; j1<=m-1; j1++) {
			for (j2=j1+1; j2<=m; j2++) {
				if (asarray_contains(counts_aa, (min((nb[j1],nb[j2])), max((nb[j1],nb[j2]))))) {
					cur = asarray(counts_aa, (min((nb[j1],nb[j2])), max((nb[j1],nb[j2])))) + 1
				}
				else {
					cur = 1
				}
				asarray(counts_aa, (min((nb[j1],nb[j2])), max((nb[j1],nb[j2]))), cur)
				if (cur > best) best = cur
			}
		}
	}
	return(best)
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
	Enables the incremental shared-partner cache (Part XXV performance
	work, docs/CERTIFICATION.md harmonisation unit 82): builds
	`sp_counts' from scratch in O(sum_i deg_i^2) = O(m*davg) - for each
	node i, every UNORDERED PAIR of i's own neighbors gains i as exactly
	one shared partner. This specific "iterate pairs of one node's own
	neighbors" formulation is deliberate, not incidental: an earlier,
	independently-prototyped version of this same cache (during this
	project's own initial development, before v1 shipped) instead tried
	to build it by iterating over EDGES ("for edge (i,j), for every
	other neighbor k of i: sp(j,k)+=1; for every other neighbor k of j:
	sp(i,k)+=1") and that formulation DOUBLE-COUNTS every pair of a
	shared node's own two edges - confirmed by direct comparison against
	brute-force common_neighbors() at the time, which is exactly why v1
	shipped with the on-demand version instead of this cache. Opt-in
	(never called automatically by init()) because it costs real memory
	and one-time setup work that only pays off for models that actually
	use gwesp - `nwergm.ado' calls this only when a gwesp() term is
	requested, immediately after bridging the graph and before any MCMC
	runs. Once enabled, toggle() maintains `sp_counts' incrementally
	forever after (see its own comment) - this method is meant to be
	called exactly once, right after the graph's own initial ties are in
	place, not repeatedly.
*/
void ErgmGraph::enable_sp_cache(){
	real scalar i, j1, j2, m
	real rowvector nb

	sp_counts = &(asarray_create("real", 2))
	for (i=1; i<=n; i++) {
		nb = neighbors_out(i)
		m = cols(nb)
		for (j1=1; j1<=m-1; j1++) {
			for (j2=j1+1; j2<=m; j2++) {
				sp_adjust(nb[j1], nb[j2], 1)
			}
		}
	}
	sp_cache_enabled = 1
}

/*
	Adds `delta' to the cached shared-partner count for canonical pair
	(a,b), keeping `sp_counts' sparse (a pair whose count reaches exactly
	0 is removed rather than stored as an explicit zero - `nties' itself
	can reach into the hundreds of thousands, and most dyads never share
	a partner at all, so this matters for memory at scale).
*/
void ErgmGraph::sp_adjust(real scalar a, real scalar b, real scalar delta){
	real scalar ca, cb, cur

	ca = min((a,b))
	cb = max((a,b))
	if (asarray_contains(*sp_counts, (ca,cb))) {
		cur = asarray(*sp_counts, (ca,cb)) + delta
	}
	else {
		cur = delta
	}
	if (cur == 0) asarray_remove(*sp_counts, (ca,cb))
	else asarray(*sp_counts, (ca,cb), cur)
}

/*
	O(1) shared-partner count when the cache is enabled; otherwise falls
	back to on-demand common_neighbors() (O(min(deg_i,deg_j))) - the
	exact same value either way, just a different cost. stat_gwesp()/
	change_gwesp() call this instead of common_neighbors() directly so
	they automatically benefit once a caller enables the cache, with zero
	change needed to either function.
*/
real scalar ErgmGraph::shared_partners(real scalar a, real scalar b){
	real scalar ca, cb

	if (!sp_cache_enabled) return(common_neighbors(a,b))
	ca = min((a,b))
	cb = max((a,b))
	if (asarray_contains(*sp_counts, (ca,cb))) return(asarray(*sp_counts, (ca,cb)))
	return(0)
}

/*
	Directed "outgoing two-path" (OTP) shared-partner count for the
	ORDERED pair (i,j): #{k : i->k and k->j} - i.e. the number of nodes
	k such that i-k-j forms a two-step directed path FROM i TO j
	(harmonisation unit 91, term-expansion wave 5). This is R ergm's own
	default shared-partner definition for directed networks (fresh-
	checked against `R/InitErgmTerm.dgw_sp.R`'s own `type="OTP"`
	default) - NOT symmetric in (i,j) the way the undirected
	`shared_partners()' above is (SP_OTP(i,j) != SP_OTP(j,i) in
	general), so it deliberately gets its own dedicated function rather
	than trying to generalize the existing one in place. No incremental
	cache (unlike `shared_partners()' above) - matches this session's
	own "decide term by term through profiling" discipline (unit 82's
	UTP cache was added only after evidence, not preemptively; the same
	standard applies here until evidence says otherwise). ITP/OSP/ISP/RTP
	(the other four directed shared-partner definitions R ergm supports
	via the same `type=' argument) are implemented in their own dedicated
	functions below (`shared_partners_itp()'/`_osp()'/`_isp()'/`_rtp()').
*/
real scalar ErgmGraph::shared_partners_otp(real scalar i, real scalar j){
	real rowvector nb
	real scalar k, m, cnt

	nb = neighbors_out(i)
	cnt = 0
	for (m=1; m<=cols(nb); m++) {
		k = nb[m]
		if (k==j) continue
		if (has_edge(k,j)) cnt++
	}
	return(cnt)
}

/*
	Directed "incoming two-path" (ITP) shared-partner count for the
	ORDERED pair (i,j): #{k : j->k and k->i} - i.e. the mirror image of
	shared_partners_otp() above (fresh-checked against the real
	`statnet/ergm` C source, `src/changestats_dgw_sp.h`'s own type
	comment "ITP - Incoming two-path (i<-k<-j)", which reads exactly as
	`j->k->i`): ITP(i,j) = OTP(j,i) by construction, so this is a one-
	line reuse of the already-certified OTP function with its arguments
	swapped, not a second independent traversal.
*/
real scalar ErgmGraph::shared_partners_itp(real scalar i, real scalar j){
	return(shared_partners_otp(j, i))
}

/*
	Directed "outgoing shared partner" (OSP) count for (i,j): #{k :
	i->k and j->k} - fresh-checked against the real `statnet/ergm` C
	source's type comment "OSP - Outgoing shared partner (i->k<-j)".
	UNLIKE OTP/ITP, this is SYMMETRIC in (i,j) (swapping i and j leaves
	the defining set unchanged) - and turns out to be EXACTLY what
	common_neighbors() above already computes when called on a directed
	graph (it always traverses via neighbors_out()/has_edge() in the
	"out" direction, regardless of `directed`), so this is a pure alias,
	not new traversal code.
*/
real scalar ErgmGraph::shared_partners_osp(real scalar i, real scalar j){
	return(common_neighbors(i, j))
}

/*
	Directed "incoming shared partner" (ISP) count for (i,j): #{k :
	k->i and k->j} - fresh-checked against the real `statnet/ergm` C
	source's type comment "ISP - Incoming shared partner (i<-k->j)".
	Also symmetric in (i,j), like OSP, but needs its own traversal
	(common_neighbors_in(), below) since it walks IN-neighbors/checks
	arcs INTO the candidate k, the mirror image of common_neighbors()'s
	own out-neighbor/has_edge(b,k) discipline.
*/
real scalar ErgmGraph::shared_partners_isp(real scalar i, real scalar j){
	return(common_neighbors_in(i, j))
}

/*
	Number of nodes k that point to BOTH i and j (k s.t. has_edge(k,i)
	and has_edge(k,j)) - the in-neighbor mirror of common_neighbors()
	above, needed for shared_partners_isp(). Same "iterate the smaller
	in-neighbor set, test membership in the other's" discipline,
	O(min(indeg_i,indeg_j)).
*/
real scalar ErgmGraph::common_neighbors_in(real scalar i, real scalar j){
	real rowvector nb
	real scalar k, cnt, a, b

	if (degree_in(i) <= degree_in(j)) {
		a = i; b = j
	}
	else {
		a = j; b = i
	}
	nb = neighbors_in(a)
	cnt = 0
	for (k=1; k<=cols(nb); k++) {
		if (nb[k] != b && has_edge(nb[k], b)) cnt++
	}
	return(cnt)
}

/*
	Directed "reciprocated two-path" (RTP) count for (i,j): #{k : i<->k
	and k<->j} (k != j), where a<->b means BOTH has_edge(a,b) and
	has_edge(b,a) - i.e. k is a shared partner only through a MUTUAL tie
	on each leg, not a bare one-directional arc. This is R ergm's fifth
	and last directed shared-partner definition, fresh-checked against
	the real `statnet/ergm` C source's own `espRTP_change` comment
	("configurations for edge i->j such that i<->k and j<->k (with
	k!=j)", `src/changestats_dgw_sp.h`) - deliberately NOT derived from
	the type comment alone, same standard OTP/ITP/OSP/ISP were held to.
	SYMMETRIC in (i,j) like OSP/ISP (mutual() is itself symmetric), so
	RTP(i,j) == RTP(j,i) always - confirmed by construction, not just
	assumed, since both legs are mutual-tie tests with no directional
	asymmetry between i and j.
*/
real scalar ErgmGraph::shared_partners_rtp(real scalar i, real scalar j){
	real rowvector nb
	real scalar k, m, cnt

	nb = neighbors_out(i)
	cnt = 0
	for (m=1; m<=cols(nb); m++) {
		k = nb[m]
		if (k==j) continue
		if (!has_edge(k,i)) continue		// require i<->k (mutual)
		if (has_edge(k,j) & has_edge(j,k)) cnt++	// require k<->j (mutual)
	}
	return(cnt)
}

/*
	Nodes with a MUTUAL (reciprocated) tie to x: #{k : x<->k}, as a row
	vector - the RTP analogue of `neighbors_out()'/`neighbors_in()',
	needed by `change_gwesp_rtp()'/`change_gwdsp_rtp()'/
	`change_esp_rtp()'/`change_dsp_rtp()' below to enumerate the dyads
	RTP-based statistics changed by an (i,j) toggle without rescanning
	every node in the graph. O(degree_out(x)), same cost class as
	`common_neighbors()'.
*/
real rowvector ErgmGraph::mutual_neighbors(real scalar x){
	real rowvector nb, out
	real scalar m, k, cnt

	nb = neighbors_out(x)
	out = J(1, cols(nb), 0)
	cnt = 0
	for (m=1; m<=cols(nb); m++) {
		k = nb[m]
		if (has_edge(k,x)) {
			cnt++
			out[cnt] = k
		}
	}
	return(cnt ? out[1..cnt] : J(1,0,0))
}

/*
	All current ties as an nties x 2 matrix of (i,j) pairs. Directed:
	one row per arc. Undirected: one row per edge, canonicalized i<j.
	O(nties) - a direct slice of the live edge array toggle() already
	maintains incrementally (elist rows 1..nties); this used to be an
	O(n+nties) neighbor-set reconstruction (iterating every node's own
	adjacency to rebuild the list from scratch) before elist existed.
*/
real matrix ErgmGraph::all_ties(){
	if (nties == 0) return(J(0, 2, 0))
	return(elist[1::nties, .])
}

/*
	Dense n x n 0/1 adjacency matrix (1 = tie present), matching the
	shape `nwset, mat(...)' expects - used only by nwergm's own `estat
	gof' (Part XX) to materialize a simulated network back into a real
	nw_def object so the package's own already-tested nwgeodesic/nwtriads
	commands can compute genuine goodness-of-fit comparison statistics on
	it, rather than reimplementing geodesic distance/triad census a
	second time. Not used anywhere in the MCMC inner loop itself - O(n +
	nties), called at most `nsim' times per `estat gof' call, the same
	"materialize outside the hot loop" discipline all_ties() already
	follows.
*/
real matrix ErgmGraph::to_dense(){
	real matrix out
	real rowvector nb
	real scalar i, k

	out = J(n, n, 0)
	for (i=1; i<=n; i++) {
		nb = neighbors_out(i)
		for (k=1; k<=cols(nb); k++) out[i, nb[k]] = 1
	}
	return(out)
}

/*
	Renders a real matrix as a literal Stata matrix-expression string,
	e.g. "(0,1,0\1,0,1\0,1,0)" - used by `estat gof' (nwergm_estat.ado)
	to hand a simulated network to `nwset, mat(...)' as a LITERAL
	expression rather than an existing Stata matrix's bare NAME.
	`nwset.ado' line 651 (`mata: mode1 = cols(`mat')') resolves its own
	`mat()' argument as a bare Mata expression - a literal expression like
	this one parses directly as an anonymous Mata matrix constant, but a
	bare NAME referring to an existing Stata matrix does NOT auto-import
	(confirmed by direct, isolated repro, independent of matastrict or of
	this package's own ERGM code entirely: `matrix define X = (...)' then
	`nwset, mat(X)' fails with "X not found" in a bare, freshly-started
	Stata session using only the compiled lnwcommands.mlib) - a genuine,
	previously-undiscovered bug in `nwset.ado' itself, recorded in
	docs/CERTIFICATION.md's own Pending list rather than fixed here (out
	of this subsystem's scope; every OTHER `nwset, mat(...)' call in this
	package's own existing tests happens to always pass a literal
	expression, which is why this had never previously surfaced). This
	function exists so `estat gof' avoids that landmine entirely rather
	than depending on a fix to unrelated, foundational code.
*/
string scalar ErgmMatToLiteral(real matrix X){
	string scalar out
	real scalar i, j, nr, nc

	nr = rows(X)
	nc = cols(X)
	out = "("
	for (i=1; i<=nr; i++) {
		for (j=1; j<=nc; j++) {
			out = out + strofreal(X[i,j])
			if (j<nc) out = out + ","
		}
		if (i<nr) out = out + "\"
	}
	out = out + ")"
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
	real scalar decay		// gwesp/gwdegree/gwodegree/gwidegree/gwdsp
	real colvector attr		// nodematch/nodecov/nodeicov/nodeocov/absdist/nodefactor/nodemix: node-indexed covariate (already numeric-coded)
	real matrix edgecovmat		// edgecov: dense n x n dyadic covariate
	real colvector levels		// nodematch(diff=TRUE)/nodefactor: distinct attribute levels present, one per output statistic (index k <-> levels[k])
	real matrix levelpairs		// nodemix: distinct UNORDERED level-pairs present, one row (a,b), a<=b, per output statistic
	string scalar sptype		// gwesp/gwdsp/gwnsp/esp/dsp: shared-partner definition on a DIRECTED network - "" (default) means the undirected/UTP definition (used as-is for undirected networks); one of "OTP"/"ITP"/"OSP"/"ISP"/"RTP" selects the corresponding directed definition (harmonisation unit 91 wave 5 added OTP; a later wave added ITP/OSP/ISP; RTP (reciprocated two-path) added last - all five of R ergm's own directed shared-partner types are now implemented).
	pointer(class ErgmGraph scalar) scalar xnet	// nwsaom multiplex's crprod (unw_saom.do): a LIVE pointer to the OTHER co-evolving network's own current ErgmGraph, re-pointed by SaomEstimateRMCoevNetNet()/SaomSimulateIntervalCoevNetNet() every time a fresh working copy of that other network is created (a fresh G1work/G2work per Robbins-Monro replicate) - addterm() stores &td0 (a POINTER into the caller's own td0 storage, not a copy), so mutating td.xnet through that same pointer from inside the estimator is visible to the registered term instance immediately, no re-registration needed. NULL/unused by every other term (nwergm never sets or reads it).
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
	hamming(netname) (harmonisation unit 91, term-expansion wave 7):
	Hamming distance to a reference network - the number of dyads whose
	tie state DISAGREES with the same dyad's state in `td.edgecovmat'
	(reused here as a plain 0/1 reference adjacency, not a continuous
	covariate weight the way `edgecov()' above uses the same field -
	each `ErgmTermData' instance only ever serves one term's own
	purpose, so sharing the field is safe). Fresh-checked against R
	ergm's own current `InitErgmTerm.hamming()`: the unweighted base
	case (no `cov=' argument) is exactly this - a plain disagreement
	count. Genuinely dyad-independent (each dyad's own contribution
	depends only on that dyad's own current state and its own
	reference value, never on any other dyad) - the SAME architectural
	family as `edgecov'/`nodecov' above, not the nonlocal GWESP family.
	Unlike `edgecov()', `stat_hamming()' needs a genuine ALL-DYADS scan
	(not an `all_ties()' shortcut): an untied dyad in G can still
	contribute to the mismatch count if the reference network has it
	tied, so untied dyads cannot be skipped the way `edgecov()' safely
	skips them (a covariate WEIGHT contributes exactly 0 through an
	untied dyad; a mismatch INDICATOR does not).

	Change statistic derivation: toggling (i,j) always flips its own
	state (old_state -> 1-old_state). If the OLD state already agreed
	with the reference, toggling necessarily creates a NEW mismatch
	(+1, since old_state==ref forces new_state==1-ref!=ref). If the OLD
	state already disagreed, toggling necessarily FIXES it (-1, by the
	same reasoning in reverse). So the change is simply +1 if the dyad
	currently agrees with the reference, -1 if it currently disagrees -
	an O(1) toggle cost with no third-party/neighbor effects at all.
*/
real rowvector stat_hamming(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real scalar i, j, tot

	tot = 0
	if (G.directed) {
		for (i=1; i<=G.n; i++) {
			for (j=1; j<=G.n; j++) {
				if (i==j) continue
				if (G.has_edge(i,j) != td.edgecovmat[i,j]) tot++
			}
		}
	}
	else {
		for (i=1; i<=G.n-1; i++) {
			for (j=i+1; j<=G.n; j++) {
				if (G.has_edge(i,j) != td.edgecovmat[i,j]) tot++
			}
		}
	}
	return(tot)
}
real rowvector change_hamming(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	return(G.has_edge(i,j) == td.edgecovmat[i,j] ? 1 : -1)
}

/* ===================================================================
   Term-expansion wave 1 (harmonisation unit 88, docs/CERTIFICATION.md -
   phase D): absdist, nodematch(diff=TRUE), nodefactor, nodemix. All four
   are dyad-independent (their own change statistic depends only on the
   toggled dyad's own endpoints' covariate values, never on the rest of
   the graph) - the same architectural family as nodecov/nodeicov/
   nodeocov/edgecov above, not the nonlocal GWESP/GW-degree family below.
   =================================================================== */

/*
	Absolute difference (Hunter et al.'s "absdiff" in Statnet's own
	terminology - named `absdist' here to match this project's own
	existing `nodecov'-family naming convention rather than copying
	Statnet's identifier verbatim): sum over ties of |attr[i] - attr[j]|.
	A natural companion to `nodecov' (which sums attr[i]+attr[j]) for
	continuous covariates where DISSIMILARITY, not combined level, is the
	hypothesized mechanism (e.g. age heterophily/homophily strength).
*/
real rowvector stat_absdist(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, tot

	ties = G.all_ties()
	tot = 0
	for (k=1; k<=rows(ties); k++) tot = tot + abs(td.attr[ties[k,1]] - td.attr[ties[k,2]])
	return(tot)
}
real rowvector change_absdist(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar v
	v = abs(td.attr[i] - td.attr[j])
	return(G.has_edge(i,j) ? -v : v)
}

/*
	Differential nodematch (R ergm's `nodematch(attr, diff=TRUE)'): one
	statistic PER DISTINCT LEVEL of a categorical attribute, each
	counting ties whose two endpoints both carry THAT SPECIFIC level -
	generalizing the existing single-parameter `stat_nodematch()' (pooled
	homophily across all levels) to differential homophily (a separate
	coefficient per level, since same-level ties among level A need not
	behave like same-level ties among level B). `td.levels' (populated
	once, in `nwergm.ado', from the distinct values actually present in
	the attribute variable) fixes the level -> output-column mapping;
	both functions below use `_ergm_level_index()' - a tiny linear scan,
	fine here since the number of DISTINCT LEVELS is always small (this
	is a per-toggle O(nlevels) cost, not O(n)).
*/
/*
	_ergm_drop_base_level(): drops the lowest-sorted (base) level from a
	distinct-levels colvector, used by nodefactor()/nodeofactor()/
	nodeifactor() to match R ergm's own base=1 convention (harmonisation
	unit 90). Deliberately a plain, control-flow-free-at-the-call-site
	function rather than an inline `nwergm.ado' one-liner: `mata: if
	(cond) stmt' invoked as a single Stata-side "mata:" prefix command
	(not inside a `mata\...\end' block) is NOT reliably parseable by
	Mata's interactive/one-line reader - even the most trivial case
	(`mata: if (1>0) x=x') fails with "unexpected end of line"/"<istmt>
	incomplete", confirmed by direct isolated repro (unit 91 follow-up).
	Wrapping the `if' in `{ }' does not fix it either ("invalid
	expression"/still incomplete depending on exact form) - the `if'
	construct itself is simply unsafe as a bare `nwergm.ado' one-liner.
	A real, previously-undetected bug for exactly this reason (no
	.ado-level wiring test existed for nodefactor() before unit 91's own
	wave-3 wiring smoke test happened to exercise it). Fixed at all
	three call sites (nodefactor/nodeofactor/nodeifactor in
	`nwergm.ado') by replacing the inline `if' with a single assignment
	to this ordinary function, which is safe since it contains no
	control flow at the Stata-inline call site - only inside the
	function body, which compiles normally like every other Mata
	function in this file.
*/
real colvector _ergm_drop_base_level(real colvector levels){
	if (rows(levels) > 1) return(levels[2::rows(levels)])
	return(levels)
}
real scalar _ergm_level_index(real colvector levels, real scalar v){
	real scalar k
	for (k=1; k<=rows(levels); k++) if (levels[k] == v) return(k)
	return(0)
}
real rowvector stat_nodematch_diff(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real rowvector out
	real scalar k, idx

	out = J(1, rows(td.levels), 0)
	ties = G.all_ties()
	for (k=1; k<=rows(ties); k++) {
		if (td.attr[ties[k,1]] == td.attr[ties[k,2]]) {
			idx = _ergm_level_index(td.levels, td.attr[ties[k,1]])
			if (idx) out[idx] = out[idx] + 1
		}
	}
	return(out)
}
real rowvector change_nodematch_diff(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real rowvector out
	real scalar idx

	out = J(1, rows(td.levels), 0)
	if (td.attr[i] != td.attr[j]) return(out)
	idx = _ergm_level_index(td.levels, td.attr[i])
	if (idx) out[idx] = G.has_edge(i,j) ? -1 : 1
	return(out)
}

/*
	Nodefactor (R ergm's `nodefactor(attr)'): one statistic per distinct
	(non-baseline, in Statnet's own convention - v1 here includes every
	observed level, leaving the usual `base' redundant-parameter
	adjustment to the caller/MPLE design, exactly as this project already
	does for `nodematch') level L of a categorical attribute, each
	counting SUM OF DEGREE over nodes carrying that level - equivalently,
	each tie (i,j) contributes 1 to level attr[i]'s own statistic AND 1
	to level attr[j]'s own statistic (both endpoints' own levels get
	credit, matching the standard "half the degree sum per level"
	definition). Toggling (i,j) therefore touches exactly the two
	(possibly equal) level-columns for attr[i] and attr[j].
*/
real rowvector stat_nodefactor(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real rowvector out
	real scalar k, idx

	out = J(1, rows(td.levels), 0)
	ties = G.all_ties()
	for (k=1; k<=rows(ties); k++) {
		idx = _ergm_level_index(td.levels, td.attr[ties[k,1]])
		if (idx) out[idx] = out[idx] + 1
		idx = _ergm_level_index(td.levels, td.attr[ties[k,2]])
		if (idx) out[idx] = out[idx] + 1
	}
	return(out)
}
real rowvector change_nodefactor(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real rowvector out
	real scalar delta, idx

	out = J(1, rows(td.levels), 0)
	delta = G.has_edge(i,j) ? -1 : 1
	idx = _ergm_level_index(td.levels, td.attr[i])
	if (idx) out[idx] = out[idx] + delta
	idx = _ergm_level_index(td.levels, td.attr[j])
	if (idx) out[idx] = out[idx] + delta
	return(out)
}

/*
	Nodemix (R ergm's `nodemix(attr)'): one statistic per distinct
	UNORDERED pair of levels {a,b} (including a==b, "within-level" ties -
	v1 scope is undirected only, matching this project's own existing
	`nodematch'/`nodecov' treatment of level pairs; directed's own
	ordered-pair mixing matrix is a natural future extension using the
	same `_ergm_levelpair_index()' lookup with an ordered rather than
	canonicalized key), each counting ties whose two endpoints' levels
	are EXACTLY that pair - the full categorical mixing matrix
	`nodematch(diff=TRUE)' only shows the diagonal of. `td.levelpairs'
	(populated once in `nwergm.ado' from the distinct pairs actually
	observed) fixes the pair -> output-column mapping.
*/
real scalar _ergm_levelpair_index(real matrix levelpairs, real scalar a, real scalar b){
	real scalar k, lo, hi
	lo = min((a,b))
	hi = max((a,b))
	for (k=1; k<=rows(levelpairs); k++) {
		if (levelpairs[k,1]==lo & levelpairs[k,2]==hi) return(k)
	}
	return(0)
}
real rowvector stat_nodemix(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real rowvector out
	real scalar k, idx

	out = J(1, rows(td.levelpairs), 0)
	ties = G.all_ties()
	for (k=1; k<=rows(ties); k++) {
		idx = _ergm_levelpair_index(td.levelpairs, td.attr[ties[k,1]], td.attr[ties[k,2]])
		if (idx) out[idx] = out[idx] + 1
	}
	return(out)
}
real rowvector change_nodemix(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real rowvector out
	real scalar idx

	out = J(1, rows(td.levelpairs), 0)
	idx = _ergm_levelpair_index(td.levelpairs, td.attr[i], td.attr[j])
	if (idx) out[idx] = G.has_edge(i,j) ? -1 : 1
	return(out)
}

/* ===================================================================
   Bipartite (two-mode) Stage 2 terms (harmonisation unit 156,
   docs/ERGM_ROADMAP.md/docs/CERTIFICATION.md): the first bipartite-
   family terms beyond `edges' (Stage 1, unit 155). Definitions taken
   directly from R ergm 4.12.0's own current Rd docs (`b1cov`, `b2cov`,
   `b1factor`, `b2factor` - `tools::Rd_db("ergm")`), not guessed from the
   term names:
     b1cov(attr):    "the total value of attr(i) for all edges (i,j)",
                      i the mode-1 endpoint - a mode-restricted nodecov.
     b2cov(attr):    the same, with j (mode-2) the restricted endpoint.
     b1factor(attr): "the number of times a node with that attribute in
                      the first mode... appears in an edge" - a mode-
                      restricted nodefactor (one coefficient per level,
                      credit only to the mode-1 endpoint's own level,
                      never both endpoints the way plain nodefactor
                      does).
     b2factor(attr): the same, restricted to the mode-2 endpoint.
   All four are genuinely dyad-independent (each tie's own contribution
   depends only on that tie's two endpoints), so all are MPLE-eligible
   immediately - no MCMLE/native work needed for this stage.

   Critical correctness point, worth stating explicitly: a bipartite
   dyad (i,j) passed to a change() function is NOT guaranteed to have
   the mode-1 endpoint in position i. Every CALLER internal to this
   package's own bipartite dyad-space code (build_mple_data(),
   ErgmCertifyChangeStat(), ergm_propose_uniform()) does happen to pass
   mode-1 first (iterating mode1nodes x mode2nodes) - but G.all_ties()
   (used by every stat_*() function below) canonicalizes ties by RAW
   NUMERIC node index (i<j), not by mode (see its own header comment:
   "Undirected: one row per edge, canonicalized i<j"), and this
   package's own deliberate "no node reordering" architecture decision
   (unw_ergm.do's set_bipartite() header) means mode-1 node indices are
   not guaranteed smaller than mode-2 ones. Every function below
   therefore checks G.mode[.] explicitly to find the mode-1 (or mode-2)
   endpoint, rather than assuming positional order - the one new pitfall
   Stage 1's own edges-only term never had to face (a tie count needs no
   endpoint distinction at all).
   =================================================================== */
real rowvector stat_b1cov(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, tot, a, b

	ties = G.all_ties()
	tot = 0
	for (k=1; k<=rows(ties); k++) {
		a = ties[k,1]; b = ties[k,2]
		tot = tot + (G.mode[a]==1 ? td.attr[a] : td.attr[b])
	}
	return(tot)
}
real rowvector change_b1cov(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar v
	v = (G.mode[i]==1 ? td.attr[i] : td.attr[j])
	return(G.has_edge(i,j) ? -v : v)
}

real rowvector stat_b2cov(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, tot, a, b

	ties = G.all_ties()
	tot = 0
	for (k=1; k<=rows(ties); k++) {
		a = ties[k,1]; b = ties[k,2]
		tot = tot + (G.mode[a]==2 ? td.attr[a] : td.attr[b])
	}
	return(tot)
}
real rowvector change_b2cov(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar v
	v = (G.mode[i]==2 ? td.attr[i] : td.attr[j])
	return(G.has_edge(i,j) ? -v : v)
}

real rowvector stat_b1factor(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real rowvector out
	real scalar k, idx, a, b, node1

	out = J(1, rows(td.levels), 0)
	ties = G.all_ties()
	for (k=1; k<=rows(ties); k++) {
		a = ties[k,1]; b = ties[k,2]
		node1 = (G.mode[a]==1 ? a : b)
		idx = _ergm_level_index(td.levels, td.attr[node1])
		if (idx) out[idx] = out[idx] + 1
	}
	return(out)
}
real rowvector change_b1factor(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real rowvector out
	real scalar delta, idx, node1

	out = J(1, rows(td.levels), 0)
	delta = G.has_edge(i,j) ? -1 : 1
	node1 = (G.mode[i]==1 ? i : j)
	idx = _ergm_level_index(td.levels, td.attr[node1])
	if (idx) out[idx] = out[idx] + delta
	return(out)
}

real rowvector stat_b2factor(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real rowvector out
	real scalar k, idx, a, b, node2

	out = J(1, rows(td.levels), 0)
	ties = G.all_ties()
	for (k=1; k<=rows(ties); k++) {
		a = ties[k,1]; b = ties[k,2]
		node2 = (G.mode[a]==2 ? a : b)
		idx = _ergm_level_index(td.levels, td.attr[node2])
		if (idx) out[idx] = out[idx] + 1
	}
	return(out)
}
real rowvector change_b2factor(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real rowvector out
	real scalar delta, idx, node2

	out = J(1, rows(td.levels), 0)
	delta = G.has_edge(i,j) ? -1 : 1
	node2 = (G.mode[i]==2 ? i : j)
	idx = _ergm_level_index(td.levels, td.attr[node2])
	if (idx) out[idx] = out[idx] + delta
	return(out)
}

/* ===================================================================
   Term-expansion wave 2 (harmonisation unit 90, docs/CERTIFICATION.md -
   phase D, continuation of unit 88): degree(d)/idegree(d)/odegree(d),
   concurrent, triangle, ctriple, gwnsp. Fresh verification against R
   ergm's own current source (R/InitErgmTerm.R, R/InitErgmTerm.dgw_sp.R)
   informed every definition below, not memory alone - in particular:
   R's own `degree(d)' takes `d' as a VECTOR (multiple simultaneous
   degree-value statistics in one term instance, reusing the same
   `td.levels' multi-parameter machinery unit 88 already built for
   `nodematchdiff'/`nodefactor'), R's own `isolates' term appears to have
   been REMOVED from current ergm in favor of `degree(0)' (confirmed by
   its absence from the current term-listing file, not merely assumed -
   `degree()' already subsumes it, so no separate isolates term is added
   here), and `gwnsp' is confirmed to satisfy the exact identity
   gwdsp = gwesp + gwnsp (both count shared-partner kernel sums over
   disjoint dyad sets - tied dyads for gwesp, untied dyads for gwnsp -
   that partition every dyad exactly once), letting it be implemented as
   a thin composition of the two already-certified terms rather than a
   third independent shared-partner traversal.
   =================================================================== */

/*
	degree(d)/idegree(d)/odegree(d): one statistic per requested degree
	value d[m] (`td.levels' holds the d-vector here, reusing the exact
	same multi-parameter field `nodematchdiff'/`nodefactor' already use -
	the field's own name is generic on purpose), each counting the number
	of NODES whose (total/in/out) degree equals that value exactly.
	Toggling (i,j) can move at most one node's degree away from some
	d[m] and into some (possibly different) d[m'] per endpoint affected -
	undirected `degree' touches BOTH endpoints (each endpoint's own total
	degree changes by the same delta); directed `odegree'/`idegree' touch
	only ONE endpoint each (only i's out-degree changes for `odegree';
	only j's in-degree changes for `idegree'), matching arc semantics.
*/
real rowvector stat_degree(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real rowvector out
	real scalar i, idx
	out = J(1, rows(td.levels), 0)
	for (i=1; i<=G.n; i++) {
		idx = _ergm_level_index(td.levels, G.degree_total(i))
		if (idx) out[idx] = out[idx] + 1
	}
	return(out)
}
real rowvector _ergm_degree_change(real colvector levels, real scalar olddeg, real scalar delta){
	real rowvector out
	real scalar idx
	out = J(1, rows(levels), 0)
	idx = _ergm_level_index(levels, olddeg)
	if (idx) out[idx] = out[idx] - 1
	idx = _ergm_level_index(levels, olddeg + delta)
	if (idx) out[idx] = out[idx] + 1
	return(out)
}
real rowvector change_degree(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta
	delta = G.has_edge(i,j) ? -1 : 1
	return(_ergm_degree_change(td.levels, G.degree_total(i), delta) + _ergm_degree_change(td.levels, G.degree_total(j), delta))
}

real rowvector stat_odegree(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real rowvector out
	real scalar i, idx
	out = J(1, rows(td.levels), 0)
	for (i=1; i<=G.n; i++) {
		idx = _ergm_level_index(td.levels, G.degree_out(i))
		if (idx) out[idx] = out[idx] + 1
	}
	return(out)
}
real rowvector change_odegree(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta
	delta = G.has_edge(i,j) ? -1 : 1
	return(_ergm_degree_change(td.levels, G.degree_out(i), delta))
}

real rowvector stat_idegree(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real rowvector out
	real scalar i, idx
	out = J(1, rows(td.levels), 0)
	for (i=1; i<=G.n; i++) {
		idx = _ergm_level_index(td.levels, G.degree_in(i))
		if (idx) out[idx] = out[idx] + 1
	}
	return(out)
}
real rowvector change_idegree(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta
	delta = G.has_edge(i,j) ? -1 : 1
	return(_ergm_degree_change(td.levels, G.degree_in(j), delta))
}

/*
	Concurrent (R ergm's `concurrent'): number of nodes with (total)
	degree >= 2, undirected. A single-statistic special case of the same
	"has this node's degree crossed a threshold" reasoning `degree()'
	above uses, kept as its own term (rather than requiring users to
	spell out a range) purely for convenience, matching R's own
	convention of shipping it as a named term despite the overlap with
	`degrange(2,.)' (not itself implemented - `concurrent' is the
	single, by far most commonly used instance of that family, per the
	prioritized survey in docs/ERGM_ROADMAP.md).
*/
real rowvector stat_concurrent(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real scalar i, tot
	tot = 0
	for (i=1; i<=G.n; i++) if (G.degree_total(i) >= 2) tot++
	return(tot)
}
real rowvector change_concurrent(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, di, dj, chg
	delta = G.has_edge(i,j) ? -1 : 1
	di = G.degree_total(i)
	dj = G.degree_total(j)
	chg = (((di+delta)>=2) - (di>=2)) + (((dj+delta)>=2) - (dj>=2))
	return(chg)
}

/*
	Triangle (undirected): number of triangles (unordered triples of
	pairwise-tied nodes). Uses the identity triangle_count =
	(1/3) * sum over TIED dyads (i,j) of shared_partners(i,j) - each
	triangle {a,b,c} contributes exactly 1 to each of its own 3 edges'
	own shared-partner count, so summing over edges counts every
	triangle exactly 3 times. The CHANGE statistic is dramatically
	simpler than GWESP's own (no neighbor-loop/kernel-reweighting term
	at all): toggling (i,j) with p pre-existing shared partners creates
	or destroys EXACTLY p triangles (one per shared partner k, since
	{i,j,k} either becomes or stops being a triangle) - unlike GWESP,
	there is no "kernel value shifts for k's own other triangles" term to
	add, because the un-weighted count of "is k a shared partner of
	(i,j)" doesn't change for OTHER dyads when (i,j) itself toggles (only
	whether i-j is tied, not whether i/j are each other's neighbors,
	changes) - the same reasoning gwesp's own decay-kernel version needs
	the extra neighbor loop for precisely because the KERNEL's shape
	means k's own shared-partner-count-of-OTHER-dyads term shifts too;
	the unweighted "count" kernel's own marginal contribution per triangle
	is exactly 1 regardless of context, so no such adjustment is needed.
*/
real rowvector stat_triangle(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, tot
	ties = G.all_ties()
	tot = 0
	for (k=1; k<=rows(ties); k++) tot = tot + G.shared_partners(ties[k,1], ties[k,2])
	return(tot/3)
}
real rowvector change_triangle(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta
	delta = G.has_edge(i,j) ? -1 : 1
	return(delta * G.shared_partners(i,j))
}

/*
	Ctriple (R ergm's `ctriple', directed only): number of CYCLIC
	triples - sets of arcs {(i->j),(j->k),(k->i)}. Same "sum over arcs,
	divide by 3" structure as `triangle' above, but the "local count" for
	arc (i,j) is the number of k such that j->k AND k->i BOTH already
	hold (not a symmetric shared-partner count, since direction matters
	for which two-path closes the cycle back to i). Toggling arc (i,j)
	creates/destroys exactly that many cyclic triples.
*/
real scalar _ergm_cyclic_partners(class ErgmGraph scalar G, real scalar i, real scalar j){
	real rowvector nb
	real scalar m, k, cnt
	nb = G.neighbors_out(j)
	cnt = 0
	for (m=1; m<=cols(nb); m++) {
		k = nb[m]
		if (k != i && G.has_edge(k,i)) cnt++
	}
	return(cnt)
}
real rowvector stat_ctriple(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, tot
	ties = G.all_ties()
	tot = 0
	for (k=1; k<=rows(ties); k++) tot = tot + _ergm_cyclic_partners(G, ties[k,1], ties[k,2])
	return(tot/3)
}
real rowvector change_ctriple(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta
	delta = G.has_edge(i,j) ? -1 : 1
	return(delta * _ergm_cyclic_partners(G, i, j))
}

/*
	Gwnsp (geometrically weighted NONedgewise shared partners): satisfies
	gwdsp = gwesp + gwnsp exactly (every dyad is either tied - counted by
	gwesp - or untied - counted by gwnsp - so the two sums partition
	gwdsp's own "every dyad" sum with no overlap or gap) - confirmed
	directly against R ergm's own current source
	(R/InitErgmTerm.dgw_sp.R) before relying on it. Implemented as a
	thin composition of the two already-certified terms above rather
	than a third independent shared-partner traversal - both must be
	called with the SAME decay (`td.decay', shared).
*/
real rowvector stat_gwnsp(class ErgmGraph scalar G, class ErgmTermData scalar td){
	return(stat_gwdsp(G, td) - stat_gwesp(G, td))
}
real rowvector change_gwnsp(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	return(change_gwdsp(G, i, j, td) - change_gwesp(G, i, j, td))
}

/* ===================================================================
   Term-expansion wave 3 (harmonisation unit 91, docs/CERTIFICATION.md -
   phase D, continuation of units 88/90): nodeifactor/nodeofactor
   (directed analogues of nodefactor - unit 90's own base-level-omission
   fix applies identically, done in nwergm.ado at construction time, not
   here), kstar(k)/istar(k)/ostar(k) (a general k-star family - `td.levels'
   holds the requested k-values, generalizing the existing `istar2'
   DEMONSTRATION term's own C(d,2) special case to arbitrary k, without
   touching that demonstration term itself), and degrange(from,to)/
   idegrange/odegrange (semi-open-interval degree counts - `td.levelpairs'
   holds (from,to) pairs, reusing the exact field `nodemix' already uses
   for a different purpose, since both need "one statistic per requested
   pair" bookkeeping). All cross-checked against R ergm's own current
   source (`R/InitErgmTerm.R') before implementation, not assumed from
   the existing `nodefactor'/`degree' analogues alone.
   =================================================================== */

/*
	Nodeifactor/nodeofactor (R ergm's directed analogues of `nodefactor'):
	exactly the categorical-indicator version of the already-implemented
	`nodeicov'/`nodeocov' (continuous covariate sender/receiver effects),
	the same relationship `nodefactor' has to `nodecov'. Each arc (i,j)
	credits ONLY the sender i's own level (`nodeofactor') or ONLY the
	receiver j's own level (`nodeifactor') - unlike undirected
	`nodefactor', which credits BOTH endpoints per tie.
*/
real rowvector stat_nodeofactor(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real rowvector out
	real scalar k, idx
	out = J(1, rows(td.levels), 0)
	ties = G.all_ties()
	for (k=1; k<=rows(ties); k++) {
		idx = _ergm_level_index(td.levels, td.attr[ties[k,1]])
		if (idx) out[idx] = out[idx] + 1
	}
	return(out)
}
real rowvector change_nodeofactor(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real rowvector out
	real scalar idx
	out = J(1, rows(td.levels), 0)
	idx = _ergm_level_index(td.levels, td.attr[i])
	if (idx) out[idx] = G.has_edge(i,j) ? -1 : 1
	return(out)
}
real rowvector stat_nodeifactor(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real rowvector out
	real scalar k, idx
	out = J(1, rows(td.levels), 0)
	ties = G.all_ties()
	for (k=1; k<=rows(ties); k++) {
		idx = _ergm_level_index(td.levels, td.attr[ties[k,2]])
		if (idx) out[idx] = out[idx] + 1
	}
	return(out)
}
real rowvector change_nodeifactor(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real rowvector out
	real scalar idx
	out = J(1, rows(td.levels), 0)
	idx = _ergm_level_index(td.levels, td.attr[j])
	if (idx) out[idx] = G.has_edge(i,j) ? -1 : 1
	return(out)
}

/*
	General k-star family: kstar(k)/istar(k)/ostar(k), `td.levels' holding
	the requested (possibly multiple) k values - generalizes the
	`istar2' DEMONSTRATION term's own hardcoded C(d,2) to arbitrary k via
	`_ergm_choose()' (a direct product-formula binomial coefficient,
	returning 0 when d<k since C(d,k) is 0 there by convention - no
	special-casing needed elsewhere). `kstar' is undirected (total
	degree); `istar'/`ostar' are directed analogues of `idegree'/
	`odegree' the same way `kstar' relates to `degree' - a star COUNT
	rather than an exact-degree INDICATOR.
*/
real scalar _ergm_choose(real scalar d, real scalar k){
	real scalar m, out
	if (d < k) return(0)
	if (k == 0) return(1)
	out = 1
	for (m=0; m<=k-1; m++) out = out * (d-m)
	for (m=1; m<=k; m++) out = out / m
	return(out)
}
real rowvector stat_kstar(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real rowvector out
	real scalar i, m
	out = J(1, rows(td.levels), 0)
	for (i=1; i<=G.n; i++) {
		for (m=1; m<=rows(td.levels); m++) out[m] = out[m] + _ergm_choose(G.degree_total(i), td.levels[m])
	}
	return(out)
}
real rowvector change_kstar(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real rowvector out
	real scalar delta, di, dj, m, kk
	out = J(1, rows(td.levels), 0)
	delta = G.has_edge(i,j) ? -1 : 1
	di = G.degree_total(i)
	dj = G.degree_total(j)
	for (m=1; m<=rows(td.levels); m++) {
		kk = td.levels[m]
		out[m] = (_ergm_choose(di+delta,kk) - _ergm_choose(di,kk)) + (_ergm_choose(dj+delta,kk) - _ergm_choose(dj,kk))
	}
	return(out)
}
real rowvector stat_ostar(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real rowvector out
	real scalar i, m
	out = J(1, rows(td.levels), 0)
	for (i=1; i<=G.n; i++) {
		for (m=1; m<=rows(td.levels); m++) out[m] = out[m] + _ergm_choose(G.degree_out(i), td.levels[m])
	}
	return(out)
}
real rowvector change_ostar(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real rowvector out
	real scalar delta, di, m, kk
	out = J(1, rows(td.levels), 0)
	delta = G.has_edge(i,j) ? -1 : 1
	di = G.degree_out(i)
	for (m=1; m<=rows(td.levels); m++) {
		kk = td.levels[m]
		out[m] = _ergm_choose(di+delta,kk) - _ergm_choose(di,kk)
	}
	return(out)
}
real rowvector stat_istar(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real rowvector out
	real scalar i, m
	out = J(1, rows(td.levels), 0)
	for (i=1; i<=G.n; i++) {
		for (m=1; m<=rows(td.levels); m++) out[m] = out[m] + _ergm_choose(G.degree_in(i), td.levels[m])
	}
	return(out)
}
real rowvector change_istar(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real rowvector out
	real scalar delta, dj, m, kk
	out = J(1, rows(td.levels), 0)
	delta = G.has_edge(i,j) ? -1 : 1
	dj = G.degree_in(j)
	for (m=1; m<=rows(td.levels); m++) {
		kk = td.levels[m]
		out[m] = _ergm_choose(dj+delta,kk) - _ergm_choose(dj,kk)
	}
	return(out)
}

/* ===================================================================
   Bipartite (two-mode) Stage 3 terms (harmonisation unit 157,
   docs/ERGM_ROADMAP.md/docs/CERTIFICATION.md): the dyad-DEPENDENT
   bipartite family, mode-restricted analogues of the degree() and
   kstar() families just above (reusing their own already-certified
   `_ergm_level_index()'/`_ergm_degree_change()'/`_ergm_choose()'
   helpers directly, unchanged). Definitions taken from R ergm 4.12.0's
   own current Rd docs (`tools::Rd_db("ergm")`, `b1degree`, `b1star`),
   not guessed:
     b1degree(d): "the ith such statistic equals the number of nodes of
                   degree d[i] in the FIRST MODE of a bipartite
                   network" - a mode-restricted degree(d).
     b2degree(d): the mode-2 mirror.
     b1star(k):   "the ith such statistic counts the number of distinct
                   k[i]-stars whose center node is in the FIRST MODE" -
                   a mode-restricted kstar(k). R's own note "b1star(1)
                   is equal to b2star(1) and to edges" is a real,
                   checkable identity (used directly in this unit's own
                   certification below, not just quoted).
     b2star(k):   the mode-2 mirror.
   Unlike Stage 2 (dyad-independent, MPLE-eligible), these are genuinely
   dyad-DEPENDENT - a k-star statistic depends on the FULL degree
   sequence, not just the toggled dyad's own two endpoints' attributes -
   so `method(mcmle)' is required, exactly like plain `degree()'/
   `kstar()' already are, and these are the first bipartite terms to
   exercise the Stage-1 bipartite MCMC proposal
   (ergm_propose_uniform()/ergm_propose_tnt()) for real, not merely
   MPLE's own closed-form/enumerated dyad space.

   Change-statistic derivation: toggling a bipartite dyad (i,j) always
   has EXACTLY ONE mode-1 endpoint and one mode-2 endpoint (Stage 1's
   own dyad-space guarantee - no same-mode dyad is ever toggled). A
   mode-restricted degree/star statistic's own value at a node depends
   ONLY on that node's own degree - never on its neighbor's - so
   b1degree()/b1star() react to the MODE-1 endpoint's own degree change
   alone (never the mode-2 endpoint's, unlike plain degree()/kstar(),
   which react to BOTH endpoints since every one-mode node is itself
   eligible to be counted). This is the exact same `G.mode[.]'-based
   endpoint-detection discipline Stage 2's own b1cov()/b1factor() used,
   for the identical underlying reason (a bipartite dyad's mode-1
   endpoint is not guaranteed to arrive in position `i' - see their own
   header comment above).
   =================================================================== */
real rowvector stat_b1degree(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real rowvector out
	real scalar a, idx
	out = J(1, rows(td.levels), 0)
	for (a=1; a<=rows(G.mode1nodes); a++) {
		idx = _ergm_level_index(td.levels, G.degree_total(G.mode1nodes[a]))
		if (idx) out[idx] = out[idx] + 1
	}
	return(out)
}
real rowvector change_b1degree(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, node1
	delta = G.has_edge(i,j) ? -1 : 1
	node1 = (G.mode[i]==1 ? i : j)
	return(_ergm_degree_change(td.levels, G.degree_total(node1), delta))
}

real rowvector stat_b2degree(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real rowvector out
	real scalar a, idx
	out = J(1, rows(td.levels), 0)
	for (a=1; a<=rows(G.mode2nodes); a++) {
		idx = _ergm_level_index(td.levels, G.degree_total(G.mode2nodes[a]))
		if (idx) out[idx] = out[idx] + 1
	}
	return(out)
}
real rowvector change_b2degree(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, node2
	delta = G.has_edge(i,j) ? -1 : 1
	node2 = (G.mode[i]==2 ? i : j)
	return(_ergm_degree_change(td.levels, G.degree_total(node2), delta))
}

real rowvector stat_b1star(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real rowvector out
	real scalar a, m
	out = J(1, rows(td.levels), 0)
	for (a=1; a<=rows(G.mode1nodes); a++) {
		for (m=1; m<=rows(td.levels); m++) out[m] = out[m] + _ergm_choose(G.degree_total(G.mode1nodes[a]), td.levels[m])
	}
	return(out)
}
real rowvector change_b1star(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real rowvector out
	real scalar delta, node1, d1, m, kk
	out = J(1, rows(td.levels), 0)
	delta = G.has_edge(i,j) ? -1 : 1
	node1 = (G.mode[i]==1 ? i : j)
	d1 = G.degree_total(node1)
	for (m=1; m<=rows(td.levels); m++) {
		kk = td.levels[m]
		out[m] = _ergm_choose(d1+delta,kk) - _ergm_choose(d1,kk)
	}
	return(out)
}

real rowvector stat_b2star(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real rowvector out
	real scalar a, m
	out = J(1, rows(td.levels), 0)
	for (a=1; a<=rows(G.mode2nodes); a++) {
		for (m=1; m<=rows(td.levels); m++) out[m] = out[m] + _ergm_choose(G.degree_total(G.mode2nodes[a]), td.levels[m])
	}
	return(out)
}
real rowvector change_b2star(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real rowvector out
	real scalar delta, node2, d2, m, kk
	out = J(1, rows(td.levels), 0)
	delta = G.has_edge(i,j) ? -1 : 1
	node2 = (G.mode[i]==2 ? i : j)
	d2 = G.degree_total(node2)
	for (m=1; m<=rows(td.levels); m++) {
		kk = td.levels[m]
		out[m] = _ergm_choose(d2+delta,kk) - _ergm_choose(d2,kk)
	}
	return(out)
}

/* ===================================================================
   Bipartite Stage 4 terms (harmonisation unit 162): b1nodematch/
   b2nodematch and the fixed-decay GW-bipartite-degree family
   (bgwdegree1/bgwdegree2), the two term families the roadmap had left
   as "natural follow-ons" after Stages 1-3. Both were flagged there as
   NOT mechanical extensions of the existing pattern - confirmed true:
   R ergm's own real Rd docs (`tools::Rd_db("ergm")`,
   `b1nodematch-ergmTerm-*`/`b2nodematch-ergmTerm-*`, a term introduced
   by Bomiriya et al. 2023) describe a genuinely different statistic
   from plain mode-restricted `nodematch` - a same-attribute TWO-STAR
   count, not a same-attribute TIE count. Every formula below was
   independently DERIVED first, then VALIDATED against real installed R
   ergm 4.12.0 output on a hand-built 7-node bipartite network (4
   mode-1, 3 mode-2 nodes) BEFORE being trusted, per this project's own
   standing "always test against R outcomes" discipline - not taken on
   faith from the Rd prose alone, which is genuinely ambiguous about the
   exact default-parameter formula (its own `alpha=1, beta=1` default
   arguments read as if both discount mechanisms apply simultaneously,
   which is not what `summary()` actually computes).

   b1nodematch(attr) DEFAULT-PARAMETER SCOPE ONLY (diff=FALSE, no
   alpha()/beta()/byb2attr()/levels() - those are real R ergm arguments
   this port does not yet expose; a disclosed, deliberate scope
   decision given this term's genuine complexity, not an oversight):
   for every mode-2 node k, and every value `a' its mode-1 neighbors'
   `attr' takes, contributes C(count_a(k), 2) - equivalently, for every
   unordered PAIR of same-attribute mode-1 nodes, the number of mode-2
   nodes tied to both. Confirmed against real R: base network -> 3;
   removing tie (1,5) -> 2 (delta -1); adding (4,5) or (2,7) -> 3
   unchanged (delta 0) - all three match this derivation exactly, not
   approximately. b2nodematch(attr) is the exact mode-1/mode-2 mirror
   (also independently re-confirmed against R, base network -> 2 with a
   differently-assigned mode-2 attribute).

   Change statistic: toggling (i,j) can only change the ONE mode-2 (or
   mode-1, for b2nodematch) node's own same-attribute-pair count - the
   count contributed by every OTHER mode-2 node is untouched, since only
   node2's own neighbor SET changed. The delta equals +-1 times the
   number of node2's OTHER current neighbors (excluding node1 itself,
   which matters specifically for the tie-removal direction, where
   node1 is currently one of them) sharing node1's own attribute value -
   an O(degree) local computation, not a full-graph rescan, the same
   complexity class every other change statistic in this file already
   has.
   =================================================================== */
real scalar _ergm_bnodematch_partner_count(class ErgmGraph scalar G, real scalar node1, real scalar node2, class ErgmTermData scalar td){
	real rowvector nbrs
	real scalar m, cnt, a1
	a1 = td.attr[node1]
	if (a1 >= .) return(0)
	cnt = 0
	nbrs = G.neighbors_out(node2)
	for (m=1; m<=cols(nbrs); m++) {
		if (nbrs[m] == node1) continue
		if (td.attr[nbrs[m]] == a1) cnt++
	}
	return(cnt)
}
real rowvector stat_b1nodematch(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real rowvector nbrs
	real scalar b, m, c, tot, a1, a2
	tot = 0
	for (b=1; b<=rows(G.mode2nodes); b++) {
		nbrs = G.neighbors_out(G.mode2nodes[b])
		for (m=1; m<=cols(nbrs)-1; m++) {
			a1 = td.attr[nbrs[m]]
			if (a1 >= .) continue
			for (c=m+1; c<=cols(nbrs); c++) {
				a2 = td.attr[nbrs[c]]
				if (a1 == a2) tot++
			}
		}
	}
	return(tot)
}
real rowvector change_b1nodematch(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, node1, node2
	delta = G.has_edge(i,j) ? -1 : 1
	node1 = (G.mode[i]==1 ? i : j)
	node2 = (G.mode[i]==1 ? j : i)
	return(delta * _ergm_bnodematch_partner_count(G, node1, node2, td))
}

real rowvector stat_b2nodematch(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real rowvector nbrs
	real scalar a, m, c, tot, a1, a2
	tot = 0
	for (a=1; a<=rows(G.mode1nodes); a++) {
		nbrs = G.neighbors_out(G.mode1nodes[a])
		for (m=1; m<=cols(nbrs)-1; m++) {
			a1 = td.attr[nbrs[m]]
			if (a1 >= .) continue
			for (c=m+1; c<=cols(nbrs); c++) {
				a2 = td.attr[nbrs[c]]
				if (a1 == a2) tot++
			}
		}
	}
	return(tot)
}
real rowvector change_b2nodematch(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, node1, node2
	delta = G.has_edge(i,j) ? -1 : 1
	node2 = (G.mode[i]==2 ? i : j)
	node1 = (G.mode[i]==2 ? j : i)
	return(delta * _ergm_bnodematch_partner_count(G, node2, node1, td))
}

/*
	bgwdegree1(decay)/bgwdegree2(decay): FIXED-decay only (v1 scope,
	matching plain gwdegree()'s own "curved/free decay is a roadmap
	item" scope note above - R ergm's own gwb1degree()/gwb2degree()
	default to fixed=FALSE/curved, exactly like plain gwdegree() started
	fixed-only before gwdegreefree() was added later as a separate,
	later unit; the same incremental path applies here, left for a
	future unit rather than this one). Direct mode-restriction of the
	already-certified stat_gwdegree()/change_gwdegree() (reusing the
	identical gw_kernel() and the identical two-line structure) exactly
	the way b1degree()/change_b1degree() mode-restrict plain degree() -
	only ONE endpoint (mode-1, or mode-2) is ever affected by a toggle,
	unlike plain gwdegree's own both-endpoints reaction, since a
	bipartite dyad's OTHER endpoint is definitionally the other mode and
	never itself eligible to be counted in a mode-restricted sum.
	Confirmed against real R ergm (gwb1degree(0.7,fixed=TRUE)/
	gwb2degree(0.5,fixed=TRUE) on the same 7-node test network) to exact
	floating-point agreement, not merely close.
*/
real rowvector stat_bgwdegree1(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real scalar a, tot
	tot = 0
	for (a=1; a<=rows(G.mode1nodes); a++) tot = tot + gw_kernel(G.degree_total(G.mode1nodes[a]), td.decay)
	return(tot)
}
real rowvector change_bgwdegree1(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, node1, d1
	delta = G.has_edge(i,j) ? -1 : 1
	node1 = (G.mode[i]==1 ? i : j)
	d1 = G.degree_total(node1)
	return(gw_kernel(d1+delta, td.decay) - gw_kernel(d1, td.decay))
}

real rowvector stat_bgwdegree2(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real scalar a, tot
	tot = 0
	for (a=1; a<=rows(G.mode2nodes); a++) tot = tot + gw_kernel(G.degree_total(G.mode2nodes[a]), td.decay)
	return(tot)
}
real rowvector change_bgwdegree2(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, node2, d2
	delta = G.has_edge(i,j) ? -1 : 1
	node2 = (G.mode[i]==2 ? i : j)
	d2 = G.degree_total(node2)
	return(gw_kernel(d2+delta, td.decay) - gw_kernel(d2, td.decay))
}

/*
	Degrange/idegrange/odegrange: semi-open-interval degree counts -
	generalizes `degree(d)' (exact match) to a RANGE [from,to). `td.levelpairs'
	holds one (from,to) row per requested range (reusing the field
	`nodemix' uses for a different purpose - both just need "one
	statistic per requested pair"). `to' of missing (`.') means no upper
	bound (matching R ergm's own `to' default of `+Inf').
*/
real scalar _ergm_inrange(real scalar d, real scalar from, real scalar to){
	if (d < from) return(0)
	if (to >= .) return(1)
	return(d < to)
}
real rowvector stat_degrange(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real rowvector out
	real scalar i, m
	out = J(1, rows(td.levelpairs), 0)
	for (i=1; i<=G.n; i++) {
		for (m=1; m<=rows(td.levelpairs); m++) out[m] = out[m] + _ergm_inrange(G.degree_total(i), td.levelpairs[m,1], td.levelpairs[m,2])
	}
	return(out)
}
real rowvector change_degrange(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real rowvector out
	real scalar delta, di, dj, m
	out = J(1, rows(td.levelpairs), 0)
	delta = G.has_edge(i,j) ? -1 : 1
	di = G.degree_total(i)
	dj = G.degree_total(j)
	for (m=1; m<=rows(td.levelpairs); m++) {
		out[m] = (_ergm_inrange(di+delta,td.levelpairs[m,1],td.levelpairs[m,2]) - _ergm_inrange(di,td.levelpairs[m,1],td.levelpairs[m,2]))
		out[m] = out[m] + (_ergm_inrange(dj+delta,td.levelpairs[m,1],td.levelpairs[m,2]) - _ergm_inrange(dj,td.levelpairs[m,1],td.levelpairs[m,2]))
	}
	return(out)
}
real rowvector stat_odegrange(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real rowvector out
	real scalar i, m
	out = J(1, rows(td.levelpairs), 0)
	for (i=1; i<=G.n; i++) {
		for (m=1; m<=rows(td.levelpairs); m++) out[m] = out[m] + _ergm_inrange(G.degree_out(i), td.levelpairs[m,1], td.levelpairs[m,2])
	}
	return(out)
}
real rowvector change_odegrange(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real rowvector out
	real scalar delta, di, m
	out = J(1, rows(td.levelpairs), 0)
	delta = G.has_edge(i,j) ? -1 : 1
	di = G.degree_out(i)
	for (m=1; m<=rows(td.levelpairs); m++) out[m] = _ergm_inrange(di+delta,td.levelpairs[m,1],td.levelpairs[m,2]) - _ergm_inrange(di,td.levelpairs[m,1],td.levelpairs[m,2])
	return(out)
}
real rowvector stat_idegrange(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real rowvector out
	real scalar i, m
	out = J(1, rows(td.levelpairs), 0)
	for (i=1; i<=G.n; i++) {
		for (m=1; m<=rows(td.levelpairs); m++) out[m] = out[m] + _ergm_inrange(G.degree_in(i), td.levelpairs[m,1], td.levelpairs[m,2])
	}
	return(out)
}
real rowvector change_idegrange(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real rowvector out
	real scalar delta, dj, m
	out = J(1, rows(td.levelpairs), 0)
	delta = G.has_edge(i,j) ? -1 : 1
	dj = G.degree_in(j)
	for (m=1; m<=rows(td.levelpairs); m++) out[m] = _ergm_inrange(dj+delta,td.levelpairs[m,1],td.levelpairs[m,2]) - _ergm_inrange(dj,td.levelpairs[m,1],td.levelpairs[m,2])
	return(out)
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

/* ===================================================================
   Curved-parameter support (harmonisation unit 133, first slice):
   the theta -> eta map and its Jacobian for the geometrically weighted
   decay family, shared by every GW term (gwesp/gwdsp/gwnsp/gwdegree/
   gwodegree/gwidegree) when the decay itself is estimated rather than
   fixed. v1's own fixed-decay GW terms collapse the whole weighted sum
   into ONE canonical (eta-space) statistic per term, computed directly
   by stat_gwesp()/change_gwesp() etc. below - a curved (free-decay)
   term instead needs the FULL vector of per-count statistics (e.g.
   esp(1), esp(2), ..., esp(n-2) for gwesp), each with its own eta
   value, related to the term's two THETA parameters (an overall
   weight, and the decay itself) via this nonlinear map. This is a
   deliberately standalone, independently certifiable first slice -
   NOT YET wired into ErgmTermData/ErgmModel/MPLE/MCMLE (a curved model
   cannot be requested through nwergm.ado yet); that wiring is later
   work once this piece is certified on its own.

   Clean-room reimplementation from the published Hunter (2007)
   geometrically-weighted construction, cross-checked numerically
   (not copied) against the installed R `ergm' package's own internal
   `ergm:::ergm_GWDECAY' object (ergm 4.13.0, confirmed via direct
   inspection, harmonisation unit 133) - see
   cscripts/test_nwergm_curved.do for the exact transcribed reference
   values. That inspection resolved a real ambiguity left open in
   docs/ERGM_STATNET_STUDY.md's own earlier transcription (which was
   unsure whether ergm_GWDECAY's second free parameter is the decay
   alpha itself or log(alpha)): confirmed directly, by matching
   ergm_GWDECAY$map() against the closed-form GWESP weighted-sum
   formula to machine precision, that it is alpha itself, matching
   this project's own existing fixed-decay `td.decay' convention
   exactly (no extra log/exp reparameterization needed when a term
   transitions from fixed to curved).

   eta_i(theta_w, alpha) = theta_w * exp(alpha) * (1 - (1-exp(-alpha))^i),
   i = 1..n - i.e. theta_w is the usual GW term's own overall
   coefficient, exactly as reported today for a FIXED-decay term, and
   fixing alpha at a caller-chosen value collapses this whole vector
   back into a scalar multiple of v1's own single combined eta
   statistic (confirmed as an identity below, not merely plausible).
   =================================================================== */

/*
	Numerically stable log(1-exp(-a)) for a>0 (the standard two-branch
	form: expm1() avoids the catastrophic cancellation of computing
	1-exp(-a) directly when a is small and exp(-a) is close to 1;
	log1p() avoids a similar loss computing log(1-x) directly when x
	is close to 0, i.e. when a is large and exp(-a) is already small -
	both expm1()/log1p() confirmed as genuine Mata built-ins, not
	polyfilled, harmonisation unit 133). a<=0 is a caller error (alpha
	must be positive - ergm_GWDECAY's own minpar enforces alpha>=0)
	and returns missing rather than silently producing a wrong value.
*/
real scalar ergm_log1mexp(real scalar a){
	if (a <= 0) return(.)
	if (a <= ln(2)) return(ln(-expm1(-a)))
	return(log1p(-exp(-a)))
}

/*
	theta -> eta map for the GW decay family: theta_w (overall weight,
	unconstrained) and alpha (decay, must be >0) -> an n-vector of
	canonical (eta-space) statistics, one per achievable shared-
	partner/degree count 1..n. Certified against R's own
	ergm:::ergm_GWDECAY$map() - see cscripts/test_nwergm_curved.do.
*/
real rowvector ergm_gwdecay_map(real scalar theta_w, real scalar alpha, real scalar n){
	real scalar a, k
	real rowvector eta

	// a = log(1-exp(-alpha)), always < 0 for alpha>0 - deliberately a
	// SINGLE call on alpha itself, then reused (times k) inside the
	// per-k log1mexp call below. Collapsing this into one direct
	// ergm_log1mexp(alpha*k) call per k is WRONG - that computes
	// exp(alpha)*(1-exp(-alpha*k)), not the required
	// exp(alpha)*(1-(1-exp(-alpha))^k) - caught only by tracing R's own
	// two-step `a <- log1mexp(x[2])` / `log1mexp(-a*i)' structure
	// literally rather than assuming a single substitution would do.
	a = ergm_log1mexp(alpha)
	eta = J(1, n, .)
	for (k=1; k<=n; k++) eta[k] = theta_w * exp(alpha + ergm_log1mexp(-a * k))
	return(eta)
}

/*
	Jacobian of ergm_gwdecay_map() above: a 2 x n matrix, row 1 =
	d(eta_i)/d(theta_w), row 2 = d(eta_i)/d(alpha). Certified against
	R's own ergm:::ergm_GWDECAY$gradient() - see
	cscripts/test_nwergm_curved.do. Used later (curved MCMLE) both to
	project an eta-space Newton step back onto the 2-parameter theta
	space and, via the delta method, to transform eta's own sandwich
	covariance into a theta-space one.
*/
real matrix ergm_gwdecay_gradient(real scalar theta_w, real scalar alpha, real scalar n){
	real scalar a, k
	real rowvector w, d_alpha

	a = ergm_log1mexp(alpha)
	w = J(1, n, .)
	for (k=1; k<=n; k++) w[k] = exp(alpha + ergm_log1mexp(-a * k))
	d_alpha = J(1, n, .)
	// exp(a*(k-1)) = (1-exp(-alpha))^(k-1) since exp(a) = 1-exp(-alpha)
	// by construction (a = log of exactly that quantity) - matches the
	// analytic derivative of eta_k = exp(alpha)*(1-(1-exp(-alpha))^k)
	// w.r.t. alpha term-for-term with R's own gradient() source.
	for (k=1; k<=n; k++) d_alpha[k] = theta_w * (w[k] - k * exp(a * (k-1)))
	return(w \ d_alpha)
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
	shared-partner cache for performance). v1 originally used
	common_neighbors() directly here (O(min(deg_i,deg_j)) per lookup,
	deemed sufficient at v1's own target scale); a real R-vs-Stata
	benchmark subsequently showed GWESP-involving models 40-68x slower
	than Statnet's own ergm() where GWESP-free models of similar or
	larger size were only ~3x slower (docs/CERTIFICATION.md harmonisation
	unit 81), pinning the gap specifically on this shared-partner
	machinery - both functions below now call ErgmGraph::shared_partners()
	instead, which is O(1) once a caller has enabled the incremental
	cache (unit 82) and falls back to the identical common_neighbors()
	computation otherwise, so this is a pure performance change with no
	effect on either function's own return value.
*/
real rowvector stat_gwesp(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, tot, p

	if (td.sptype == "OTP") return(stat_gwesp_otp(G, td))
	if (td.sptype == "ITP") return(stat_gwesp_itp(G, td))
	if (td.sptype == "OSP") return(stat_gwesp_osp(G, td))
	if (td.sptype == "ISP") return(stat_gwesp_isp(G, td))
	if (td.sptype == "RTP") return(stat_gwesp_rtp(G, td))
	ties = G.all_ties()
	tot = 0
	for (k=1; k<=rows(ties); k++) {
		p = G.shared_partners(ties[k,1], ties[k,2])
		tot = tot + gw_kernel(p, td.decay)
	}
	return(tot)
}
real rowvector change_gwesp(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, pij, chg, k, m, pik, pjk
	real rowvector nb

	if (td.sptype == "OTP") return(change_gwesp_otp(G, i, j, td))
	if (td.sptype == "ITP") return(change_gwesp_itp(G, i, j, td))
	if (td.sptype == "OSP") return(change_gwesp_osp(G, i, j, td))
	if (td.sptype == "ISP") return(change_gwesp_isp(G, i, j, td))
	if (td.sptype == "RTP") return(change_gwesp_rtp(G, i, j, td))
	delta = G.has_edge(i,j) ? -1 : 1

	pij = G.shared_partners(i,j)
	chg = delta * gw_kernel(pij, td.decay)

	nb = G.neighbors_out(i)
	for (m=1; m<=cols(nb); m++) {
		k = nb[m]
		if (k==j) continue
		if (!G.has_edge(j,k)) continue	// k must be a common neighbor of i and j
		pik = G.shared_partners(i,k)
		chg = chg + (gw_kernel(pik+delta, td.decay) - gw_kernel(pik, td.decay))
		pjk = G.shared_partners(j,k)
		chg = chg + (gw_kernel(pjk+delta, td.decay) - gw_kernel(pjk, td.decay))
	}
	return(chg)
}

/*
	Geometrically weighted dyadwise shared partners (GWDSP; Hunter 2007) -
	term-expansion wave 1, harmonisation unit 88. Undirected only in v1,
	same scope disclosure as GWESP above. Statistic: sum of
	gw_kernel(shared_partners(u,v), decay) over EVERY dyad {u,v} (u != v),
	REGARDLESS of whether u,v are themselves tied - unlike GWESP, which
	sums only over TIED dyads. `stat_gwdsp()' therefore genuinely needs to
	enumerate all O(n^2) dyads from scratch (there is no O(nties) shortcut
	the way `all_ties()' gives GWESP - shared partners are defined for
	untied dyads too) - this matches the term's own real computational
	cost in any implementation, Statnet's own included, and is only ever
	paid once per full statistic() call (MPLE design-matrix construction,
	the observed-network baseline, and each MCMLE iteration's own
	Dbar centering), never inside the O(1)-target MCMC change-statistic
	path below.

	Change statistic for toggling (i,j): because shared_partners(u,v) for
	the dyad {i,j} ITSELF does not depend on whether i-j is tied (shared
	partners are common THIRD nodes), toggling (i,j) contributes NOTHING
	to the GWDSP sum via the {i,j} dyad's own term - only via every OTHER
	dyad that gains or loses i or j as a shared partner. This is exactly
	GWESP's own "for each neighbor of j, adjust dyad (i,k); for each
	neighbor of i, adjust dyad (j,k)" loop, but WITHOUT GWESP's own
	"only if (i,k)/(j,k) is itself a tie" restriction (GWDSP counts every
	dyad, tied or not) and without GWESP's own extra "own dyad" pij term
	(which does not apply here) - making this change function structurally
	simpler than GWESP's despite the statistic itself being more expensive
	to compute from scratch.
*/
/*
	Harmonisation unit 151 (performance): the O(n^2) full-dyad enumeration
	this function used to do directly (see the still-accurate cost
	discussion in the comment block above this function) is genuine
	ALGORITHMIC cost, but it does not need to be paid via n^2 direct
	dyad lookups - `stat_gwdsp(G)' is exactly the telescoping sum of
	`change_gwdsp()' evaluated in the "add" direction over every tie of
	G, replayed from an empty graph of the same size (an empty graph has
	zero shared partners on every dyad, so the sum of first differences
	equals the final value exactly, regardless of insertion order - the
	same identity a change statistic exists to compute). This turns the
	cost from O(n^2) into O(nties * avg per-tie cost), which is a real
	asymptotic win on any genuinely sparse network - confirmed directly
	(dev/ergm_benchmark_r_vs_stata's own benchmark-8 network, n=1000,
	nties=1526: 3.50s -> 0.09s for one call, bit-identical to 1e-9
	relative difference) - and delegates the OTP/ITP/OSP/ISP/RTP
	direction entirely to `change_gwdsp()`'s own existing `td.sptype'
	dispatch, so the five formerly-separate `stat_gwdsp_otp/itp/osp/
	isp/rtp()' full-enumeration functions below are no longer called
	from here (each was independently re-verified equivalent to this
	replacement before being retired - cscripts/test_nwergm_native.do).
*/
real rowvector stat_gwdsp(class ErgmGraph scalar G, class ErgmTermData scalar td){
	class ErgmGraph scalar G2
	real matrix ties
	real scalar k, nties
	real rowvector tot

	ties = G.all_ties()
	nties = rows(ties)
	G2 = ErgmGraph()
	G2.init(G.n, G.directed)
	tot = 0
	for (k=1; k<=nties; k++) {
		tot = tot + change_gwdsp(G2, ties[k,1], ties[k,2], td)
		G2.toggle(ties[k,1], ties[k,2])
	}
	return(tot)
}
real rowvector change_gwdsp(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, chg, k, m, pk
	real rowvector nb

	if (td.sptype == "OTP") return(change_gwdsp_otp(G, i, j, td))
	if (td.sptype == "ITP") return(change_gwdsp_itp(G, i, j, td))
	if (td.sptype == "OSP") return(change_gwdsp_osp(G, i, j, td))
	if (td.sptype == "ISP") return(change_gwdsp_isp(G, i, j, td))
	if (td.sptype == "RTP") return(change_gwdsp_rtp(G, i, j, td))
	delta = G.has_edge(i,j) ? -1 : 1
	chg = 0

	nb = G.neighbors_out(i)
	for (m=1; m<=cols(nb); m++) {
		k = nb[m]
		if (k==j) continue
		pk = G.shared_partners(j,k)
		chg = chg + (gw_kernel(pk+delta, td.decay) - gw_kernel(pk, td.decay))
	}
	nb = G.neighbors_out(j)
	for (m=1; m<=cols(nb); m++) {
		k = nb[m]
		if (k==i) continue
		pk = G.shared_partners(i,k)
		chg = chg + (gw_kernel(pk+delta, td.decay) - gw_kernel(pk, td.decay))
	}
	return(chg)
}

/*
	Directed OTP variants of GWESP/GWDSP (harmonisation unit 91,
	term-expansion wave 5) - dispatched to from `stat_gwesp()'/
	`change_gwesp()'/`stat_gwdsp()'/`change_gwdsp()' above whenever
	`td.sptype == "OTP"' (set by `nwergm.ado' automatically whenever the
	network is directed, matching R ergm's own default `type="OTP"' for
	directed shared-partner terms - fresh-checked against
	`R/InitErgmTerm.dgw_sp.R'). `gwnsp' needs NO separate OTP variant:
	it is already a thin composition of gwdsp/gwesp (`stat_gwnsp() =
	stat_gwdsp(G,td) - stat_gwesp(G,td)'), which will call the OTP
	dispatch above automatically once `td.sptype' is set - the
	composition itself is completely direction-agnostic.

	SP_OTP(a,b) = #{k : a->k and k->b} (see `ErgmGraph::shared_partners_
	otp()' above) is NOT symmetric in (a,b), so toggling arc i->j
	affects two structurally DIFFERENT sets of other ordered pairs,
	unlike the undirected case's single symmetric neighbor loop:
	  (A) for every a with a->i (a is an IN-neighbor of i): i can serve
	      as the "k" connecting a->i->j, so SP_OTP(a,j) changes by
	      delta whenever arc i->j toggles.
	  (B) for every b with j->b (b is an OUT-neighbor of j): j can serve
	      as the "k" connecting i->j->b, so SP_OTP(i,b) changes by
	      delta.
	This is the same "own dyad term (esp only) + two adjustment loops"
	shape as the undirected functions, just with `neighbors_in(i)'/
	`neighbors_out(j)' replacing the undirected `neighbors_out(i)' used
	symmetrically for both loops there, and GWDSP's own dyad-space
	genuinely doubling in size (ALL n*(n-1) ORDERED pairs i != j, not
	just the n*(n-1)/2 unordered ones - SP_OTP(i,j) != SP_OTP(j,i) in
	general, so both directions must be enumerated separately).
*/
real rowvector stat_gwesp_otp(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, tot, p

	ties = G.all_ties()
	tot = 0
	for (k=1; k<=rows(ties); k++) {
		p = G.shared_partners_otp(ties[k,1], ties[k,2])
		tot = tot + gw_kernel(p, td.decay)
	}
	return(tot)
}
real rowvector change_gwesp_otp(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, pij, chg, a, b, m, paj, pib
	real rowvector na, nb

	delta = G.has_edge(i,j) ? -1 : 1

	pij = G.shared_partners_otp(i,j)
	chg = delta * gw_kernel(pij, td.decay)

	na = G.neighbors_in(i)
	for (m=1; m<=cols(na); m++) {
		a = na[m]
		if (a==j) continue
		if (!G.has_edge(a,j)) continue	// esp counts TIED (a,j) arcs only
		paj = G.shared_partners_otp(a,j)
		chg = chg + (gw_kernel(paj+delta, td.decay) - gw_kernel(paj, td.decay))
	}
	nb = G.neighbors_out(j)
	for (m=1; m<=cols(nb); m++) {
		b = nb[m]
		if (b==i) continue
		if (!G.has_edge(i,b)) continue
		pib = G.shared_partners_otp(i,b)
		chg = chg + (gw_kernel(pib+delta, td.decay) - gw_kernel(pib, td.decay))
	}
	return(chg)
}
real rowvector change_gwdsp_otp(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, chg, a, b, m, paj, pib
	real rowvector na, nb

	delta = G.has_edge(i,j) ? -1 : 1
	chg = 0

	na = G.neighbors_in(i)
	for (m=1; m<=cols(na); m++) {
		a = na[m]
		if (a==j) continue
		paj = G.shared_partners_otp(a,j)
		chg = chg + (gw_kernel(paj+delta, td.decay) - gw_kernel(paj, td.decay))
	}
	nb = G.neighbors_out(j)
	for (m=1; m<=cols(nb); m++) {
		b = nb[m]
		if (b==i) continue
		pib = G.shared_partners_otp(i,b)
		chg = chg + (gw_kernel(pib+delta, td.decay) - gw_kernel(pib, td.decay))
	}
	return(chg)
}

/*
	Directed ITP/OSP/ISP variants of GWESP/GWDSP (term-expansion "directed
	shared-partner types" wave, following the OTP wave above), fresh-
	derived from - and cross-checked line-by-line against - the real
	`statnet/ergm` C source (`src/changestats_dgw_sp.h`'s own
	`espITP_change`/`espOSP_change`/`espISP_change`/`dspITP_change`/
	`dspOSP_change`/`dspISP_change` macros, plus `src/changestats_dgw_sp.c`'s
	`all_calcs`/`all_calcs2` dispatch table), not just the one-line R-level
	type comment - getting a directed shared-partner definition backwards
	would silently corrupt every estimate that uses it.

	ITP(i,j) := OTP(j,i) (shared_partners_itp() above) - so ITP's change
	statistics are OTP's own two loops with every dyad MIRRORED: OTP's
	"(A) a in neighbors_in(i): adjust dyad (a,j) using OTP(a,j)" / "(B) b
	in neighbors_out(j): adjust dyad (i,b) using OTP(i,b)" become, for
	ITP, "(A') k in neighbors_in(i): adjust dyad (j,k) using OTP(k,j)" /
	"(B') k in neighbors_out(j): adjust dyad (k,i) using OTP(i,k)" -
	confirmed against `espITP_change'/`dspITP_change' directly (their own
	"hk"/"kt" dyad labels are exactly these mirrored pairs, traced through
	the C macro's own GETDDMUI cache-index arguments).

	OSP(i,j) := #{k: i->k, j->k} and ISP(i,j) := #{k: k->i, k->j} (both
	above) are SYMMETRIC in (i,j), unlike OTP/ITP - so toggling arc i->j
	affects exactly ONE family of other dyads for each (not two): OSP(i,q)
	for q in neighbors_in(j) (mirrored for ISP: ISP(p,j) for p in
	neighbors_out(i)). GWESP only sums over TIED arcs, and OSP(i,q) ==
	OSP(q,i) could be attributed to EITHER the (i,q) arc or the (q,i) arc
	independently (both, one, or neither may exist) - `change_gwesp_osp()'/
	`change_gwesp_isp()' therefore check has_edge() in BOTH directions per
	affected node, confirmed against `espOSP_change'/`espISP_change''s own
	two `IS_OUTEDGE()' guards. `change_gwdsp_osp()'/`change_gwdsp_isp()'
	need no such guard (GWDSP counts every dyad regardless of tie status)
	but must instead DOUBLE each loop iteration's contribution, since a
	single pass only ever visits the affected UNORDERED dyad {i,q} once
	while GWDSP's own statistic - like OTP/ITP's - counts BOTH ordered
	instances (i,q) and (q,i) (confirmed against the real C source's own
	`all_calcs2`/`gw_calc2` macros, which apply this exact `*2`
	specifically to OSP/ISP/RTP and nowhere else) - the direct-enumeration
	`stat_gwdsp()' (harmonisation unit 151) no longer materializes this
	unordered-pairs-doubled loop itself (it now sums `change_gwdsp_osp()'/
	`change_gwdsp_isp()' incrementally instead - see that function's own
	header comment), but the `*2' convention documented here is exactly
	what makes that telescoping sum land on the same total.
*/
real rowvector stat_gwesp_itp(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, tot, p

	ties = G.all_ties()
	tot = 0
	for (k=1; k<=rows(ties); k++) {
		p = G.shared_partners_itp(ties[k,1], ties[k,2])
		tot = tot + gw_kernel(p, td.decay)
	}
	return(tot)
}
real rowvector change_gwesp_itp(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, pij, chg, k, m, pjk, pki
	real rowvector na, nb

	delta = G.has_edge(i,j) ? -1 : 1

	pij = G.shared_partners_itp(i,j)
	chg = delta * gw_kernel(pij, td.decay)

	na = G.neighbors_in(i)
	for (m=1; m<=cols(na); m++) {
		k = na[m]
		if (k==j) continue
		if (!G.has_edge(j,k)) continue
		pjk = G.shared_partners_itp(j,k)
		chg = chg + (gw_kernel(pjk+delta, td.decay) - gw_kernel(pjk, td.decay))
	}
	nb = G.neighbors_out(j)
	for (m=1; m<=cols(nb); m++) {
		k = nb[m]
		if (k==i) continue
		if (!G.has_edge(k,i)) continue
		pki = G.shared_partners_itp(k,i)
		chg = chg + (gw_kernel(pki+delta, td.decay) - gw_kernel(pki, td.decay))
	}
	return(chg)
}
real rowvector stat_gwesp_osp(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, tot, p

	ties = G.all_ties()
	tot = 0
	for (k=1; k<=rows(ties); k++) {
		p = G.shared_partners_osp(ties[k,1], ties[k,2])
		tot = tot + gw_kernel(p, td.decay)
	}
	return(tot)
}
real rowvector change_gwesp_osp(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, pij, chg, q, m, pq
	real rowvector nb

	delta = G.has_edge(i,j) ? -1 : 1

	pij = G.shared_partners_osp(i,j)
	chg = delta * gw_kernel(pij, td.decay)

	nb = G.neighbors_in(j)
	for (m=1; m<=cols(nb); m++) {
		q = nb[m]
		if (q==i) continue
		pq = G.shared_partners_osp(i,q)
		if (G.has_edge(i,q)) chg = chg + (gw_kernel(pq+delta, td.decay) - gw_kernel(pq, td.decay))
		if (G.has_edge(q,i)) chg = chg + (gw_kernel(pq+delta, td.decay) - gw_kernel(pq, td.decay))
	}
	return(chg)
}
real rowvector stat_gwesp_isp(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, tot, p

	ties = G.all_ties()
	tot = 0
	for (k=1; k<=rows(ties); k++) {
		p = G.shared_partners_isp(ties[k,1], ties[k,2])
		tot = tot + gw_kernel(p, td.decay)
	}
	return(tot)
}
real rowvector change_gwesp_isp(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, pij, chg, p, m, pp
	real rowvector na

	delta = G.has_edge(i,j) ? -1 : 1

	pij = G.shared_partners_isp(i,j)
	chg = delta * gw_kernel(pij, td.decay)

	na = G.neighbors_out(i)
	for (m=1; m<=cols(na); m++) {
		p = na[m]
		if (p==j) continue
		pp = G.shared_partners_isp(p,j)
		if (G.has_edge(p,j)) chg = chg + (gw_kernel(pp+delta, td.decay) - gw_kernel(pp, td.decay))
		if (G.has_edge(j,p)) chg = chg + (gw_kernel(pp+delta, td.decay) - gw_kernel(pp, td.decay))
	}
	return(chg)
}

/*
	Directed RTP variant of GWESP - term-expansion "RTP" wave, following
	OTP/ITP/OSP/ISP above. RTP(a,b) is SYMMETRIC (like OSP/ISP) but,
	unlike OSP/ISP, toggling arc i->j leaves every OTHER dyad's RTP
	value COMPLETELY UNCHANGED unless the REVERSE arc j->i already
	exists: RTP is defined purely on the derived MUTUAL-tie graph
	(a<->b), and if j->i is absent, dyad (i,j) is never mutual regardless
	of i->j's own state, so toggling i->j cannot add or remove any edge
	of that mutual-tie graph - confirmed against `espRTP_change''s own
	`htedge=IS_OUTEDGE(head,tail)' gate in the real `statnet/ergm' C
	source, and structurally identical to this file's own
	`change_mutual()' gate (`if (!G.has_edge(j,i)) return(0)') above -
	RTP's own gate is the same fact, just consequential for a whole
	family of OTHER dyads' shared-partner counts here rather than for
	the toggled dyad's own contribution to a DIFFERENT term.

	When j->i DOES exist, toggling i->j flips whether j is a mutual
	partner of i (equivalently i a mutual partner of j) - i.e. adds or
	removes exactly one edge of the mutual-tie graph. That single edge
	change affects RTP(a,b) for two DISTINCT families of other dyads
	(unlike OSP/ISP's single family - RTP is not "one-sided" the way a
	shared OUTGOING or INCOMING target is, because the flipped mutual
	edge is itself symmetric and newly shared from BOTH i's and j's own
	side): (1) every k mutually tied to j gains/loses i as a shared
	RTP-partner for dyad (k,i)/(i,k), and (2) every k mutually tied to i
	gains/loses j as a shared RTP-partner for dyad (k,j)/(j,k) - fresh-
	derived from, and matching, `espRTP_change''s own four
	`L2kt'/`L2tk'/`L2kh'/`L2hk' loops (the first two collapse to family
	(1) here, the last two to family (2); each pair of C loops become
	one loop here with two `has_edge()' guards, the same
	one-loop-two-guard pattern `change_gwesp_osp()'/`change_gwesp_isp()'
	already use above for their own single family).
*/
real rowvector stat_gwesp_rtp(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, tot, p

	ties = G.all_ties()
	tot = 0
	for (k=1; k<=rows(ties); k++) {
		p = G.shared_partners_rtp(ties[k,1], ties[k,2])
		tot = tot + gw_kernel(p, td.decay)
	}
	return(tot)
}
real rowvector change_gwesp_rtp(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, pij, chg, k, m, pk
	real rowvector nb

	delta = G.has_edge(i,j) ? -1 : 1

	pij = G.shared_partners_rtp(i,j)
	chg = delta * gw_kernel(pij, td.decay)

	if (!G.has_edge(j,i)) return(chg)	// toggling i->j only changes the
						// mutual-tie graph (and so only
						// affects OTHER dyads) when j->i
						// already exists

	nb = G.mutual_neighbors(j)
	for (m=1; m<=cols(nb); m++) {
		k = nb[m]
		if (k==i) continue
		pk = G.shared_partners_rtp(k,i)
		if (G.has_edge(k,i)) chg = chg + (gw_kernel(pk+delta, td.decay) - gw_kernel(pk, td.decay))
		if (G.has_edge(i,k)) chg = chg + (gw_kernel(pk+delta, td.decay) - gw_kernel(pk, td.decay))
	}
	nb = G.mutual_neighbors(i)
	for (m=1; m<=cols(nb); m++) {
		k = nb[m]
		if (k==j) continue
		pk = G.shared_partners_rtp(k,j)
		if (G.has_edge(k,j)) chg = chg + (gw_kernel(pk+delta, td.decay) - gw_kernel(pk, td.decay))
		if (G.has_edge(j,k)) chg = chg + (gw_kernel(pk+delta, td.decay) - gw_kernel(pk, td.decay))
	}
	return(chg)
}
real rowvector change_gwdsp_itp(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, chg, k, m, pjk, pki
	real rowvector na, nb

	delta = G.has_edge(i,j) ? -1 : 1
	chg = 0

	na = G.neighbors_in(i)
	for (m=1; m<=cols(na); m++) {
		k = na[m]
		if (k==j) continue
		pjk = G.shared_partners_itp(j,k)
		chg = chg + (gw_kernel(pjk+delta, td.decay) - gw_kernel(pjk, td.decay))
	}
	nb = G.neighbors_out(j)
	for (m=1; m<=cols(nb); m++) {
		k = nb[m]
		if (k==i) continue
		pki = G.shared_partners_itp(k,i)
		chg = chg + (gw_kernel(pki+delta, td.decay) - gw_kernel(pki, td.decay))
	}
	return(chg)
}
real rowvector change_gwdsp_osp(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, chg, q, m, pq
	real rowvector nb

	delta = G.has_edge(i,j) ? -1 : 1
	chg = 0

	nb = G.neighbors_in(j)
	for (m=1; m<=cols(nb); m++) {
		q = nb[m]
		if (q==i) continue
		pq = G.shared_partners_osp(i,q)
		chg = chg + 2*(gw_kernel(pq+delta, td.decay) - gw_kernel(pq, td.decay))
	}
	return(chg)
}
real rowvector change_gwdsp_isp(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, chg, p, m, pp
	real rowvector na

	delta = G.has_edge(i,j) ? -1 : 1
	chg = 0

	na = G.neighbors_out(i)
	for (m=1; m<=cols(na); m++) {
		p = na[m]
		if (p==j) continue
		pp = G.shared_partners_isp(p,j)
		chg = chg + 2*(gw_kernel(pp+delta, td.decay) - gw_kernel(pp, td.decay))
	}
	return(chg)
}

/*
	Directed RTP variant of GWDSP - GWDSP counts EVERY dyad (tied or
	not), so unlike `change_gwesp_rtp()' above there is no "own dyad"
	term and no `has_edge()' guard on the affected dyads either (every
	unordered pair is always in-scope) - but the SAME `has_edge(j,i)'
	gate applies (no mutual-tie-graph edge changes, hence nothing to
	update, unless the reverse arc already exists), and the SAME TWO
	families of affected dyads apply, each contributing via the same `*2'
	convention `change_gwdsp_osp()'/`change_gwdsp_isp()' already establish
	above for enumerating each unordered pair once - confirmed against
	`dspRTP_change''s own `htedge' guard and its `L2kh'/`L2th' loop pair
	(this file's own single `mutual_neighbors(j)' loop below already
	covers both of `dspRTP_change''s per-direction loops the same way
	`change_gwdsp_osp()' collapses OSP's own two C loops into one).
*/
real rowvector change_gwdsp_rtp(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, chg, k, m, pk
	real rowvector nb

	delta = G.has_edge(i,j) ? -1 : 1
	chg = 0

	if (!G.has_edge(j,i)) return(chg)

	nb = G.mutual_neighbors(j)
	for (m=1; m<=cols(nb); m++) {
		k = nb[m]
		if (k==i) continue
		pk = G.shared_partners_rtp(k,i)
		chg = chg + 2*(gw_kernel(pk+delta, td.decay) - gw_kernel(pk, td.decay))
	}
	nb = G.mutual_neighbors(i)
	for (m=1; m<=cols(nb); m++) {
		k = nb[m]
		if (k==j) continue
		pk = G.shared_partners_rtp(k,j)
		chg = chg + 2*(gw_kernel(pk+delta, td.decay) - gw_kernel(pk, td.decay))
	}
	return(chg)
}

/*
	esp(d)/dsp(d) - fixed, non-geometric shared-partner-count terms
	(harmonisation unit 91, term-expansion wave 4): "number of TIED dyads
	with EXACTLY d shared partners" (esp) / "number of dyads, tied or
	not, with EXACTLY d shared partners" (dsp), one coefficient per
	requested d (a numlist, matching R ergm's own vector-valued `d`
	argument - fresh-checked against the current
	`R/InitErgmTerm.dgw_sp.R`: `InitErgmTerm.desp()`/`InitErgmTerm.ddsp()`
	both delegate to a shared `.d_sp_impl()` taking `d` as "a vector of
	distinct integers" and a `type` argument selecting the shared-partner
	definition - `UTP` for undirected, `OTP`/`ITP`/`RTP`/`OSP`/`ISP` for
	various directed common-neighbor definitions, defaulting to `OTP`).
	`nwergm` v1's own GWESP/GWDSP only implement the undirected UTP
	definition (both are documented "undirected only" - no directed
	common-neighbor machinery exists yet, see docs/ERGM_ROADMAP.md's own
	still-open "Directed GWESP variants" item) - `esp()`/`dsp()` here are
	scoped identically (undirected/UTP only), reusing the exact same
	`ErgmGraph::shared_partners()` traversal GWESP/GWDSP already use and
	are already certified against, rather than adding new directed
	infrastructure as a side effect of this otherwise-small addition.

	Both functions are the SAME change-statistic shape as
	`stat_gwesp()`/`change_gwesp()` and `stat_gwdsp()`/`change_gwdsp()`
	directly above, with `gw_kernel(p, decay)` (a single geometric-decay
	scalar) replaced by the exact-match indicator ROWVECTOR
	`(p :== td.levels')` (one 0/1 entry per requested d) - every other
	line of reasoning (which dyads are affected by toggling (i,j), the
	"own dyad" term esp needs that dsp does not, etc.) carries over
	unchanged from the already-certified GW terms, so this is a
	kernel-substitution exercise, not new term-design work.
*/
real rowvector stat_esp(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, p
	real rowvector tot

	if (td.sptype == "OTP") return(stat_esp_otp(G, td))
	if (td.sptype == "ITP") return(stat_esp_itp(G, td))
	if (td.sptype == "OSP") return(stat_esp_osp(G, td))
	if (td.sptype == "ISP") return(stat_esp_isp(G, td))
	if (td.sptype == "RTP") return(stat_esp_rtp(G, td))
	ties = G.all_ties()
	tot = J(1, rows(td.levels), 0)
	for (k=1; k<=rows(ties); k++) {
		p = G.shared_partners(ties[k,1], ties[k,2])
		tot = tot + (p :== td.levels')
	}
	return(tot)
}
real rowvector change_esp(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, pij, k, m, pik, pjk
	real rowvector chg, nb

	if (td.sptype == "OTP") return(change_esp_otp(G, i, j, td))
	if (td.sptype == "ITP") return(change_esp_itp(G, i, j, td))
	if (td.sptype == "OSP") return(change_esp_osp(G, i, j, td))
	if (td.sptype == "ISP") return(change_esp_isp(G, i, j, td))
	if (td.sptype == "RTP") return(change_esp_rtp(G, i, j, td))
	delta = G.has_edge(i,j) ? -1 : 1

	pij = G.shared_partners(i,j)
	chg = delta * (pij :== td.levels')

	nb = G.neighbors_out(i)
	for (m=1; m<=cols(nb); m++) {
		k = nb[m]
		if (k==j) continue
		if (!G.has_edge(j,k)) continue
		pik = G.shared_partners(i,k)
		chg = chg + ((pik+delta :== td.levels') - (pik :== td.levels'))
		pjk = G.shared_partners(j,k)
		chg = chg + ((pjk+delta :== td.levels') - (pjk :== td.levels'))
	}
	return(chg)
}
/*
	Harmonisation unit 151 (performance): same telescoping-sum identity
	as `stat_gwdsp()' just above - see that function's own header
	comment for the full account. `dsp(d)' is exact-match rather than
	geometrically-weighted, but the identity is unchanged: `change_dsp()'
	already computes the correct per-level first difference for every
	`td.sptype', so replaying every tie from an empty graph and summing
	still telescopes to the exact same vector `stat_dsp_otp/itp/osp/isp/
	rtp()' used to compute directly, at O(nties) instead of O(n^2)/
	O(n(n-1)) cost - WITH ONE CORRECTION `gwdsp()' does not need:
	`dsp(d)`'s level==0 bucket counts dyads with EXACTLY ZERO shared
	partners, and an EMPTY graph has every dyad at zero shared partners
	- so the telescoping baseline `stat_dsp(empty)' is NOT the all-zero
	vector `J(1,rows(td.levels),0)' this loop starts from, it is the
	TOTAL dyad count, in the level==0 position specifically (every
	other level, and gwdsp's own smooth `gw_kernel(0,decay)==0' kernel,
	DO start from zero validly - confirmed exact, not merely close to
	zero, from `gw_kernel()`'s own closed form). Caught by a direct
	cross-check against the five old `stat_dsp_otp/itp/osp/isp/rtp()'
	functions below before they were retired (a real bug, not a
	hypothetical one - see docs/CERTIFICATION.md unit 151 for the full
	account), added back explicitly here rather than silently relying
	on level 0 never being requested.
*/
real rowvector stat_dsp(class ErgmGraph scalar G, class ErgmTermData scalar td){
	class ErgmGraph scalar G2
	real matrix ties
	real scalar k, nties, ndyads
	real rowvector tot

	ties = G.all_ties()
	nties = rows(ties)
	G2 = ErgmGraph()
	G2.init(G.n, G.directed)
	tot = J(1, rows(td.levels), 0)
	for (k=1; k<=nties; k++) {
		tot = tot + change_dsp(G2, ties[k,1], ties[k,2], td)
		G2.toggle(ties[k,1], ties[k,2])
	}
	ndyads = G.directed ? G.n*(G.n-1) : G.n*(G.n-1)/2
	tot = tot + ndyads * (td.levels' :== 0)
	return(tot)
}
real rowvector change_dsp(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, k, m, pk
	real rowvector chg, nb

	if (td.sptype == "OTP") return(change_dsp_otp(G, i, j, td))
	if (td.sptype == "ITP") return(change_dsp_itp(G, i, j, td))
	if (td.sptype == "OSP") return(change_dsp_osp(G, i, j, td))
	if (td.sptype == "ISP") return(change_dsp_isp(G, i, j, td))
	if (td.sptype == "RTP") return(change_dsp_rtp(G, i, j, td))
	delta = G.has_edge(i,j) ? -1 : 1
	chg = J(1, rows(td.levels), 0)

	nb = G.neighbors_out(i)
	for (m=1; m<=cols(nb); m++) {
		k = nb[m]
		if (k==j) continue
		pk = G.shared_partners(j,k)
		chg = chg + ((pk+delta :== td.levels') - (pk :== td.levels'))
	}
	nb = G.neighbors_out(j)
	for (m=1; m<=cols(nb); m++) {
		k = nb[m]
		if (k==i) continue
		pk = G.shared_partners(i,k)
		chg = chg + ((pk+delta :== td.levels') - (pk :== td.levels'))
	}
	return(chg)
}

/*
	nsp(d) (nonedgewise shared partners, exact-count per-level vector -
	harmonisation unit 152, built specifically to let `gwnspfree()' reuse
	the same curved-decomposition pattern `gwespfree()'/`gwdspfree()'
	already use, the one piece `gwnsp' itself was missing: `stat_gwnsp()'
	above is a THIN COMPOSITION (`stat_gwdsp() - stat_gwesp()'), with no
	standalone per-count statistic of its own to hand the curved eta-space
	machinery (`ergm_gwdecay_map()' needs a `sum_k eta_k * count_k'
	decomposition, not a single combined scalar).
	`nsp(d) = dsp(d) - esp(d)' is a DEFINITIONAL TAUTOLOGY, not merely an
	identity that happens to hold for the geometrically-weighted
	combination: `dsp(d)' counts every dyad (tied or not) with exactly d
	shared partners; `esp(d)' counts only the TIED subset of that same
	set; `nsp(d)', the untied complement, is what remains - true level by
	level independently, since a dyad is either tied or not, with no
	third case and no double-counting. The scalar `gwnsp = gwdsp - gwesp'
	relationship this file's own `stat_gwnsp()' already relies on
	(confirmed against R ergm's own current source before that unit
	shipped) is the special case of summing this same per-level identity
	against the GW kernel's own weights - this function is the more
	general, weight-free version underneath it, not a new derivation.
	`change_nsp()' follows automatically by linearity of the first
	difference (`Delta(dsp-esp) = Delta(dsp) - Delta(esp)') - both
	`change_dsp()'/`change_esp()' are already independently certified, so
	no new per-toggle reasoning is needed, only composition, exactly
	mirroring `change_gwnsp()`'s own existing pattern one level down.
	Inherits every `td.sptype' (OTP/ITP/OSP/ISP/RTP) dispatch for free,
	since `stat_dsp()'/`stat_esp()'/`change_dsp()'/`change_esp()' already
	handle it internally.
*/
real rowvector stat_nsp(class ErgmGraph scalar G, class ErgmTermData scalar td){
	return(stat_dsp(G, td) - stat_esp(G, td))
}
real rowvector change_nsp(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	return(change_dsp(G, i, j, td) - change_esp(G, i, j, td))
}

/*
	Directed OTP variants of esp(d)/dsp(d) (harmonisation unit 91,
	term-expansion wave 5) - same kernel-substitution relationship to
	`stat_gwesp_otp()'/`change_gwesp_otp()'/`change_gwdsp_otp()' above
	as wave 4's undirected `esp'/`dsp' have
	to `gwesp'/`gwdsp': `gw_kernel(p,decay)' replaced by the exact-match
	indicator rowvector `(p :== td.levels')`. `dsp_otp' intentionally
	does NOT skip `p==0' dyads (a requested d could be exactly 0), same
	disclosed fix as wave 4's undirected `stat_dsp()'.
*/
real rowvector stat_esp_otp(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, p
	real rowvector tot

	ties = G.all_ties()
	tot = J(1, rows(td.levels), 0)
	for (k=1; k<=rows(ties); k++) {
		p = G.shared_partners_otp(ties[k,1], ties[k,2])
		tot = tot + (p :== td.levels')
	}
	return(tot)
}
real rowvector change_esp_otp(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, pij, a, b, m, paj, pib
	real rowvector chg, na, nb

	delta = G.has_edge(i,j) ? -1 : 1

	pij = G.shared_partners_otp(i,j)
	chg = delta * (pij :== td.levels')

	na = G.neighbors_in(i)
	for (m=1; m<=cols(na); m++) {
		a = na[m]
		if (a==j) continue
		if (!G.has_edge(a,j)) continue
		paj = G.shared_partners_otp(a,j)
		chg = chg + ((paj+delta :== td.levels') - (paj :== td.levels'))
	}
	nb = G.neighbors_out(j)
	for (m=1; m<=cols(nb); m++) {
		b = nb[m]
		if (b==i) continue
		if (!G.has_edge(i,b)) continue
		pib = G.shared_partners_otp(i,b)
		chg = chg + ((pib+delta :== td.levels') - (pib :== td.levels'))
	}
	return(chg)
}
real rowvector change_dsp_otp(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, a, b, m, paj, pib
	real rowvector chg, na, nb

	delta = G.has_edge(i,j) ? -1 : 1
	chg = J(1, rows(td.levels), 0)

	na = G.neighbors_in(i)
	for (m=1; m<=cols(na); m++) {
		a = na[m]
		if (a==j) continue
		paj = G.shared_partners_otp(a,j)
		chg = chg + ((paj+delta :== td.levels') - (paj :== td.levels'))
	}
	nb = G.neighbors_out(j)
	for (m=1; m<=cols(nb); m++) {
		b = nb[m]
		if (b==i) continue
		pib = G.shared_partners_otp(i,b)
		chg = chg + ((pib+delta :== td.levels') - (pib :== td.levels'))
	}
	return(chg)
}

/*
	Directed ITP/OSP/ISP variants of esp(d)/dsp(d) - same kernel-
	substitution relationship to the GWESP/GWDSP ITP/OSP/ISP variants
	above (`gw_kernel(p,decay)' replaced by the exact-match indicator
	rowvector `(p :== td.levels')') as the OTP wave's own esp(d)/dsp(d)
	had to gwesp/gwdsp - every dyad family, guard, and (for OSP/ISP's
	dsp forms) doubling convention carries over unchanged from that
	already-verified derivation.
*/
real rowvector stat_esp_itp(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, p
	real rowvector tot

	ties = G.all_ties()
	tot = J(1, rows(td.levels), 0)
	for (k=1; k<=rows(ties); k++) {
		p = G.shared_partners_itp(ties[k,1], ties[k,2])
		tot = tot + (p :== td.levels')
	}
	return(tot)
}
real rowvector change_esp_itp(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, pij, k, m, pjk, pki
	real rowvector chg, na, nb

	delta = G.has_edge(i,j) ? -1 : 1

	pij = G.shared_partners_itp(i,j)
	chg = delta * (pij :== td.levels')

	na = G.neighbors_in(i)
	for (m=1; m<=cols(na); m++) {
		k = na[m]
		if (k==j) continue
		if (!G.has_edge(j,k)) continue
		pjk = G.shared_partners_itp(j,k)
		chg = chg + ((pjk+delta :== td.levels') - (pjk :== td.levels'))
	}
	nb = G.neighbors_out(j)
	for (m=1; m<=cols(nb); m++) {
		k = nb[m]
		if (k==i) continue
		if (!G.has_edge(k,i)) continue
		pki = G.shared_partners_itp(k,i)
		chg = chg + ((pki+delta :== td.levels') - (pki :== td.levels'))
	}
	return(chg)
}
real rowvector stat_esp_osp(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, p
	real rowvector tot

	ties = G.all_ties()
	tot = J(1, rows(td.levels), 0)
	for (k=1; k<=rows(ties); k++) {
		p = G.shared_partners_osp(ties[k,1], ties[k,2])
		tot = tot + (p :== td.levels')
	}
	return(tot)
}
real rowvector change_esp_osp(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, pij, q, m, pq
	real rowvector chg, nb

	delta = G.has_edge(i,j) ? -1 : 1

	pij = G.shared_partners_osp(i,j)
	chg = delta * (pij :== td.levels')

	nb = G.neighbors_in(j)
	for (m=1; m<=cols(nb); m++) {
		q = nb[m]
		if (q==i) continue
		pq = G.shared_partners_osp(i,q)
		if (G.has_edge(i,q)) chg = chg + ((pq+delta :== td.levels') - (pq :== td.levels'))
		if (G.has_edge(q,i)) chg = chg + ((pq+delta :== td.levels') - (pq :== td.levels'))
	}
	return(chg)
}
real rowvector stat_esp_isp(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, p
	real rowvector tot

	ties = G.all_ties()
	tot = J(1, rows(td.levels), 0)
	for (k=1; k<=rows(ties); k++) {
		p = G.shared_partners_isp(ties[k,1], ties[k,2])
		tot = tot + (p :== td.levels')
	}
	return(tot)
}
real rowvector change_esp_isp(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, pij, p, m, pp
	real rowvector chg, na

	delta = G.has_edge(i,j) ? -1 : 1

	pij = G.shared_partners_isp(i,j)
	chg = delta * (pij :== td.levels')

	na = G.neighbors_out(i)
	for (m=1; m<=cols(na); m++) {
		p = na[m]
		if (p==j) continue
		pp = G.shared_partners_isp(p,j)
		if (G.has_edge(p,j)) chg = chg + ((pp+delta :== td.levels') - (pp :== td.levels'))
		if (G.has_edge(j,p)) chg = chg + ((pp+delta :== td.levels') - (pp :== td.levels'))
	}
	return(chg)
}

/*
	Directed RTP variant of esp(d) - same kernel-substitution relationship
	to `stat_gwesp_rtp()'/`change_gwesp_rtp()' above (`gw_kernel(p,decay)'
	replaced by `(p :== td.levels')') as every other esp(d)/dsp(d) variant
	has to its gwesp/gwdsp counterpart; the `has_edge(j,i)' gate and the
	two mutual-neighbor families carry over unchanged.
*/
real rowvector stat_esp_rtp(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, p
	real rowvector tot

	ties = G.all_ties()
	tot = J(1, rows(td.levels), 0)
	for (k=1; k<=rows(ties); k++) {
		p = G.shared_partners_rtp(ties[k,1], ties[k,2])
		tot = tot + (p :== td.levels')
	}
	return(tot)
}
real rowvector change_esp_rtp(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, pij, k, m, pk
	real rowvector chg, nb

	delta = G.has_edge(i,j) ? -1 : 1

	pij = G.shared_partners_rtp(i,j)
	chg = delta * (pij :== td.levels')

	if (!G.has_edge(j,i)) return(chg)

	nb = G.mutual_neighbors(j)
	for (m=1; m<=cols(nb); m++) {
		k = nb[m]
		if (k==i) continue
		pk = G.shared_partners_rtp(k,i)
		if (G.has_edge(k,i)) chg = chg + ((pk+delta :== td.levels') - (pk :== td.levels'))
		if (G.has_edge(i,k)) chg = chg + ((pk+delta :== td.levels') - (pk :== td.levels'))
	}
	nb = G.mutual_neighbors(i)
	for (m=1; m<=cols(nb); m++) {
		k = nb[m]
		if (k==j) continue
		pk = G.shared_partners_rtp(k,j)
		if (G.has_edge(k,j)) chg = chg + ((pk+delta :== td.levels') - (pk :== td.levels'))
		if (G.has_edge(j,k)) chg = chg + ((pk+delta :== td.levels') - (pk :== td.levels'))
	}
	return(chg)
}
real rowvector change_dsp_itp(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, k, m, pjk, pki
	real rowvector chg, na, nb

	delta = G.has_edge(i,j) ? -1 : 1
	chg = J(1, rows(td.levels), 0)

	na = G.neighbors_in(i)
	for (m=1; m<=cols(na); m++) {
		k = na[m]
		if (k==j) continue
		pjk = G.shared_partners_itp(j,k)
		chg = chg + ((pjk+delta :== td.levels') - (pjk :== td.levels'))
	}
	nb = G.neighbors_out(j)
	for (m=1; m<=cols(nb); m++) {
		k = nb[m]
		if (k==i) continue
		pki = G.shared_partners_itp(k,i)
		chg = chg + ((pki+delta :== td.levels') - (pki :== td.levels'))
	}
	return(chg)
}
real rowvector change_dsp_osp(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, q, m, pq
	real rowvector chg, nb

	delta = G.has_edge(i,j) ? -1 : 1
	chg = J(1, rows(td.levels), 0)

	nb = G.neighbors_in(j)
	for (m=1; m<=cols(nb); m++) {
		q = nb[m]
		if (q==i) continue
		pq = G.shared_partners_osp(i,q)
		chg = chg + 2*((pq+delta :== td.levels') - (pq :== td.levels'))
	}
	return(chg)
}
real rowvector change_dsp_isp(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, p, m, pp
	real rowvector chg, na

	delta = G.has_edge(i,j) ? -1 : 1
	chg = J(1, rows(td.levels), 0)

	na = G.neighbors_out(i)
	for (m=1; m<=cols(na); m++) {
		p = na[m]
		if (p==j) continue
		pp = G.shared_partners_isp(p,j)
		chg = chg + 2*((pp+delta :== td.levels') - (pp :== td.levels'))
	}
	return(chg)
}

/*
	Directed RTP variant of dsp(d) - same kernel-substitution relationship
	to `change_gwdsp_rtp()' above as every other dsp(d)
	variant has to its gwdsp counterpart; the `has_edge(j,i)' gate, the
	two mutual-neighbor families, and the `*2' unordered-pair convention
	all carry over unchanged.
*/
real rowvector change_dsp_rtp(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, k, m, pk
	real rowvector chg, nb

	delta = G.has_edge(i,j) ? -1 : 1
	chg = J(1, rows(td.levels), 0)

	if (!G.has_edge(j,i)) return(chg)

	nb = G.mutual_neighbors(j)
	for (m=1; m<=cols(nb); m++) {
		k = nb[m]
		if (k==i) continue
		pk = G.shared_partners_rtp(k,i)
		chg = chg + 2*((pk+delta :== td.levels') - (pk :== td.levels'))
	}
	nb = G.mutual_neighbors(i)
	for (m=1; m<=cols(nb); m++) {
		k = nb[m]
		if (k==j) continue
		pk = G.shared_partners_rtp(k,j)
		chg = chg + 2*((pk+delta :== td.levels') - (pk :== td.levels'))
	}
	return(chg)
}

/*
	transitiveties/cyclicalties (harmonisation unit 91, term-expansion
	wave 6, directed only) - fresh-checked against R ergm's own current
	`R/InitErgmTerm.transitiveties.R` (a file search found these two are
	NOT in the main `InitErgmTerm.R` dispatcher list any more - they get
	their own dedicated file, easy to miss without checking): R's own
	stated definitions are "the number of ties i->j such that there
	exists a two-path from i to j" (transitiveties) and "...from j to i"
	(cyclicalties). Both are threshold/existence indicators built
	directly on the OTP shared-partner machinery wave 5 just added:

	  transitiveties = sum over existing arcs (i,j) of I(SP_OTP(i,j)>=1)
	  cyclicalties   = sum over existing arcs (i,j) of I(SP_OTP(j,i)>=1)
	                   (SP_OTP(j,i) counts k with j->k and k->i - a
	                   two-path from j back to i, which together with
	                   the existing arc i->j closes a directed 3-cycle,
	                   hence the name)

	Change statistic for toggling arc (i,j), delta = has_edge(i,j)?-1:1:
	the SAME two families of affected shared-partner counts as
	`change_gwesp_otp()'/`change_gwdsp_otp()' above (SP_OTP(a,j) for a in
	neighbors_in(i); SP_OTP(i,b) for b in neighbors_out(j)) - but now
	each affected count only contributes to the sum through a THRESHOLD
	CROSSING (0->1 or 1->0), and only when the AFFECTED ARC ITSELF
	exists (both terms sum over existing arcs only), and — critically —
	transitiveties/cyclicalties read that threshold off DIFFERENT
	directed arcs than gwesp/gwdsp did, because each term uses a
	different orientation of SP_OTP as its own per-arc statistic:
	  - transitiveties needs SP_OTP(a,j) attributed to arc a->j itself
	    (`has_edge(a,j)'), and SP_OTP(i,b) attributed to arc i->b itself
	    (`has_edge(i,b)').
	  - cyclicalties needs SP_OTP(a,j) attributed to the REVERSED arc
	    j->a (`has_edge(j,a)', since cyclicalties(p,q) reads SP_OTP(q,p)
	    - here q=a,p=j means the arc in question is (p,q)=(j,a)), and
	    SP_OTP(i,b) attributed to the reversed arc b->i (`has_edge(b,i)').
	Own-arc term for transitiveties uses SP_OTP(i,j) itself (unaffected
	by toggling i-j, same reasoning as every shared-partner term above);
	for cyclicalties it uses SP_OTP(j,i) (also unaffected - i-j does not
	appear inside the SP_OTP(j,i) definition, since that function's own
	internal `k==i'/`k==j' guards exclude i and j as candidate
	intermediaries of their own endpoint pair).
*/
real rowvector stat_transitiveties(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, tot

	ties = G.all_ties()
	tot = 0
	for (k=1; k<=rows(ties); k++) {
		if (G.shared_partners_otp(ties[k,1], ties[k,2]) >= 1) tot++
	}
	return(tot)
}
real rowvector change_transitiveties(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, chg, a, b, m, olda, oldb
	real rowvector na, nb

	delta = G.has_edge(i,j) ? -1 : 1
	chg = delta * (G.shared_partners_otp(i,j) >= 1)

	na = G.neighbors_in(i)
	for (m=1; m<=cols(na); m++) {
		a = na[m]
		if (a==j) continue
		if (!G.has_edge(a,j)) continue
		olda = G.shared_partners_otp(a,j)
		chg = chg + ((olda+delta>=1) - (olda>=1))
	}
	nb = G.neighbors_out(j)
	for (m=1; m<=cols(nb); m++) {
		b = nb[m]
		if (b==i) continue
		if (!G.has_edge(i,b)) continue
		oldb = G.shared_partners_otp(i,b)
		chg = chg + ((oldb+delta>=1) - (oldb>=1))
	}
	return(chg)
}
real rowvector stat_cyclicalties(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real matrix ties
	real scalar k, tot

	ties = G.all_ties()
	tot = 0
	for (k=1; k<=rows(ties); k++) {
		if (G.shared_partners_otp(ties[k,2], ties[k,1]) >= 1) tot++
	}
	return(tot)
}
real rowvector change_cyclicalties(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, chg, a, b, m, olda, oldb
	real rowvector na, nb

	delta = G.has_edge(i,j) ? -1 : 1
	chg = delta * (G.shared_partners_otp(j,i) >= 1)

	na = G.neighbors_in(i)
	for (m=1; m<=cols(na); m++) {
		a = na[m]
		if (a==j) continue
		if (!G.has_edge(j,a)) continue
		olda = G.shared_partners_otp(a,j)
		chg = chg + ((olda+delta>=1) - (olda>=1))
	}
	nb = G.neighbors_out(j)
	for (m=1; m<=cols(nb); m++) {
		b = nb[m]
		if (b==i) continue
		if (!G.has_edge(b,i)) continue
		oldb = G.shared_partners_otp(i,b)
		chg = chg + ((oldb+delta>=1) - (oldb>=1))
	}
	return(chg)
}

/* ===================================================================
   EXTENSION DEMONSTRATION - NOT part of the real v1 term registry.

   istar2: the undirected 2-star count, sum_i C(deg(i),2). Built and
   certified purely to PROVE that docs/ERGM_ARCHITECTURE.md's own "how to
   add a new term" walkthrough actually works end to end for a future
   implementer who is not this code's original author - it deliberately
   does NOT appear in nwergm.ado's option surface (2-star family terms
   are, deliberately, a docs/ERGM_ROADMAP.md item rather than in v1
   scope), and existing only as a certified, working term is the entire
   point: see cscripts/test_nwergm_demoterm.do.

   Change statistic: toggling (i,j) changes only i's and j's OWN 2-star
   contribution (no third node is affected - the same "changes only
   touch the endpoints' own local counts" shape as gwdegree above, not
   the three-way shape gwesp needs). For endpoint degree d before the
   toggle, C(d,2)=d*(d-1)/2 shifts by exactly +d when a tie is ADDED
   (C(d+1,2)-C(d,2)=d) and by exactly -(d-1) when a tie is REMOVED
   (C(d-1,2)-C(d,2)=-(d-1)) - both cases below via the single kernel
   call so the sign/direction logic is identical to every other term's
   own change() (this is not literally reused since istar2 needs no
   decay/attr, but the analogous derivation to gwdegree's own change()
   above is worth reading side by side).
   =================================================================== */
real scalar ergm_2star_kernel(real scalar d){
	return(d*(d-1)/2)
}
real rowvector stat_istar2(class ErgmGraph scalar G, class ErgmTermData scalar td){
	real scalar i, tot
	tot = 0
	for (i=1; i<=G.n; i++) tot = tot + ergm_2star_kernel(G.degree_total(i))
	return(tot)
}
real rowvector change_istar2(class ErgmGraph scalar G, real scalar i, real scalar j, class ErgmTermData scalar td){
	real scalar delta, di, dj, chg
	delta = G.has_edge(i,j) ? -1 : 1
	di = G.degree_total(i)
	dj = G.degree_total(j)
	chg = (ergm_2star_kernel(di+delta) - ergm_2star_kernel(di))
	chg = chg + (ergm_2star_kernel(dj+delta) - ergm_2star_kernel(dj))
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

	// Native (C) MCMC backend config (harmonisation unit 83) - NOT part
	// of "what a model is" in any statistical sense; carried on ErgmModel
	// purely because M already flows through every relevant call site
	// (ErgmNativeSetup(), ErgmMCMCSample(), ErgmMCMCSampleDiag(),
	// ErgmMCMLE()) and Mata class instances exhibit reference semantics
	// across function calls (the same property ErgmGraph's own toggle()
	// already relies on for MCMLE's sequential design) - this avoids
	// needing genuine Mata "global" variables, which set matastrict on
	// does not support declaring inside function bodies the way this
	// unit's own first draft assumed (confirmed by direct trial). See
	// this file's own "Native (C) MCMC backend" section for the full
	// design.
	real scalar native_enabled
	real rowvector native_termcodes	// one entry per OUTPUT COLUMN (not per term instance - a multi-column term instance like nodefactor(3 levels) expands into 3 consecutive slots, one per level)
	real rowvector native_attridx		// per-slot: 1-based index into native_attrmat's own columns (0 = no attribute needed)
	real rowvector native_p1		// per-slot: generic scalar parameter #1 (decay for gw* terms; target level for nodefactor-family; low level for nodemix)
	real rowvector native_p2		// per-slot: generic scalar parameter #2 (high level for nodemix only; unused - left 0 - by every other term)
	real matrix native_attrmat		// one column per distinct attribute array actually needed across the model's own terms (native_attridx indexes into THIS, not into any one term's own td.attr)
	real rowvector native_covidx		// per-slot: 1-based index into native_covmatstack's own n-column BLOCKS (0 = no dyadic covariate matrix needed) - edgecov()/hamming() only; every other term leaves this 0, mirroring native_attridx's own "0 = unused" convention
	real matrix native_covmatstack		// distinct dense n x n dyadic covariate matrices needed across the model's own terms, horizontally concatenated as n-column blocks (block k = columns ((k-1)*n+1)..(k*n)) - a genuinely different shape from native_attrmat's own one-column-per-array convention (a dyadic covariate is one value per DYAD, not per node), so it cannot reuse that mechanism; native_covidx's block index times n tells the wire-protocol callers which columns to slice out and send as their own new dataset variables (see ErgmNativeSampleCore()'s own header comment on this)
	real scalar native_proposal
	real scalar native_lastaccept
	real scalar native_enabled_sample	// harmonisation unit 168 (freedyads() masked TNT native port): native_enabled itself stays FORCED TO 0 for a masked model (ErgmNativeBuildMPLEData()/ErgmNativeCurvedMPLEFit() have no mask awareness at all - MPLE keeps using its own already-correct Mata free-dyad-only path), but MCMC SAMPLING now has a real native masked proposal - this SEPARATE flag gates ONLY the two ErgmMCMCSample()/ErgmMCMCSampleDiag() call sites. For an UNMASKED model this is always set equal to native_enabled (byte-identical old behavior, single shared flag in practice) - the split only ever does anything for a masked model.
	real matrix native_maskmat		// G.freedyadmat, copied here only when native_enabled_sample==1 for a masked model - ErgmNativeSampleCore()'s own wire-protocol payload for the new dense n x n mask field, mirroring native_covmatstack's own "stash on M, read back by the wire-building function" contract

	real scalar fixed_density		// R ergm's own `constraints=~edges` (nwergm's `fixdensity` option): 0 (default, explicitly set by ErgmNativeSetup(), which runs for every model) or 1 - when 1, ErgmMCMCSample()/ErgmMCMCSampleDiag() dispatch to ErgmMCMCSampleSwap()/ErgmMCMCSampleDiagSwap() instead of their own ordinary single-toggle loop; not a dyad-eligibility mask like has_dyadmask above (that restricts WHICH dyads may be proposed; this changes the PROPOSAL SHAPE itself to a tie/non-tie swap that holds the total tie count invariant) - see those functions' own header comments. Native (C) port not attempted (v1 Mata-only, matching this option's own initial scope) - set alongside native_enabled/native_enabled_sample being forced to 0 for a fixed-density model in nwergm.ado.

	// Curved-parameter support (harmonisation unit 134, second slice -
	// generalizes unit 133's own single-term theta->eta map/gradient to
	// a full, possibly-mixed model). `curved' is 0 for every ordinary
	// term instance (theta IS eta, one-to-one) and 1 for a term whose
	// npar[t] eta-space columns are instead generated by a 2-parameter
	// (weight, decay) curved map - v1 scope is exactly
	// ergm_gwdecay_map()/ergm_gwdecay_gradient() for every curved term,
	// so no per-term function pointer is needed (unlike statfn/chgfn
	// above, which genuinely differ term to term). MPLE/MCMLE/SE wiring
	// that actually CONSUMES theta_to_eta()/theta_to_eta_jacobian()
	// below is later, separate work - not yet done.
	real rowvector curved

	void init()
	void addterm()
	void mark_curved()
	real scalar nparam()
	real scalar ntheta()
	real rowvector theta_to_eta()
	real matrix theta_to_eta_jacobian()
	real rowvector project_eta_to_theta()
	string rowvector theta_coefnames()
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
	native_enabled = 0
	native_enabled_sample = 0
	fixed_density = 0		// see this field's own class-header comment - this is the TRUE universal init site (init() always runs, unlike ErgmNativeSetup(), which is skipped entirely for a `nonative' fit, so relying on that call alone would leave this at Mata's own missing-value default - truthy in an if() - for every nonative model)
	curved = J(1, 0, .)
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
	curved = (curved, 0)
}

/*
	Marks the LAST-added term instance as curved (2 free theta
	parameters - weight and decay - generating its npar[nterms] eta
	columns via ergm_gwdecay_map()). Deliberately "the last one added",
	not an arbitrary index - nwergm.ado's own term-dispatch code always
	calls this (if at all) immediately after the matching addterm(),
	mirroring how every other per-instance annotation in this codebase
	is set right at construction time, not patched in later by index.
*/
void ErgmModel::mark_curved(){
	curved[nterms] = 1
}

real scalar ErgmModel::nparam(){
	return(sum(npar))
}

/*
	Theta-space dimension: same as nparam() (eta-space dimension) for a
	model with no curved terms, strictly SMALLER whenever a curved term
	is present (its npar[t] eta columns collapse to exactly 2 theta
	parameters). Curved MPLE/MCMLE optimize in this smaller space;
	theta_to_eta() below maps a point in it back to the full eta vector
	every existing statistic/change/MCMC machinery already understands.
*/
real scalar ErgmModel::ntheta(){
	real scalar t, tot

	tot = 0
	for (t=1; t<=nterms; t++) tot = tot + (curved[t] ? 2 : npar[t])
	return(tot)
}

/*
	Assembles the full eta-space vector (length nparam()) from a
	theta-space vector (length ntheta()): identity for every ordinary
	term's own theta value(s), ergm_gwdecay_map() for a curved term's
	own (weight, decay) pair. Order matches coefnames/npar exactly (term
	by term, in registration order) - the same ordering convention every
	other flat vector in this class already uses.
*/
real rowvector ErgmModel::theta_to_eta(real rowvector theta){
	real rowvector eta
	real scalar t, tpos, epos

	eta = J(1, nparam(), .)
	tpos = 1
	epos = 1
	for (t=1; t<=nterms; t++) {
		if (curved[t]) {
			eta[(epos..epos+npar[t]-1)] = ergm_gwdecay_map(theta[tpos], theta[tpos+1], npar[t])
			tpos = tpos + 2
		}
		else {
			eta[(epos..epos+npar[t]-1)] = theta[(tpos..tpos+npar[t]-1)]
			tpos = tpos + npar[t]
		}
		epos = epos + npar[t]
	}
	return(eta)
}

/*
	Jacobian of theta_to_eta() above: nparam() x ntheta(), J[i,j] =
	d(eta_i)/d(theta_j). Block-diagonal by term (a curved term's own 2
	theta columns only ever affect ITS OWN eta rows, never another
	term's) - an ordinary term's own block is simply the identity
	(d(eta)/d(theta) = 1 when eta IS theta), a curved term's own block is
	ergm_gwdecay_gradient()'s own 2 x npar[t] output, transposed to
	npar[t] x 2 to match this matrix's own (eta-row, theta-col)
	convention. Deliberately named `Jac', not `J' - `J' is Mata's own
	matrix-constant function (J(r,c,val)), used inside this very function
	to allocate the zero matrix below; shadowing it with a same-named
	local would be exactly the kind of subtle self-inflicted bug this
	project's own certification discipline exists to catch before it
	ships, not after.
*/
real matrix ErgmModel::theta_to_eta_jacobian(real rowvector theta){
	real matrix Jac, g
	real scalar t, tpos, epos, k

	Jac = J(nparam(), ntheta(), 0)
	tpos = 1
	epos = 1
	for (t=1; t<=nterms; t++) {
		if (curved[t]) {
			g = ergm_gwdecay_gradient(theta[tpos], theta[tpos+1], npar[t])
			Jac[(epos..epos+npar[t]-1), (tpos..tpos+1)] = g'
			tpos = tpos + 2
		}
		else {
			for (k=1; k<=npar[t]; k++) Jac[epos+k-1, tpos+k-1] = 1
			tpos = tpos + npar[t]
		}
		epos = epos + npar[t]
	}
	return(Jac)
}

/*
	Given a target point in eta-space (`eta_target', length nparam())
	and a weight matrix `W' (nparam() x nparam() - typically an inverse
	covariance, e.g. from a preceding closed-form logit fit's own
	cov.unscaled, or from an MCMLE iteration's own sample covariance)
	and a starting theta (length ntheta()), finds the theta minimizing
	the weighted sum of squares (eta_target - theta_to_eta(theta))' W
	(eta_target - theta_to_eta(theta)) - the shared core numerical step
	BOTH curved MPLE (later work: an initial value from an unconstrained
	logit fit) and curved MCMLE (later work: projecting each iteration's
	own eta-space Newton-step target back onto the smaller theta space)
	will reduce to; built once here so both can call the same certified
	routine rather than each reimplementing it.

	DECOUPLES EXACTLY by term, not merely as a convenient approximation:
	an ORDINARY term's own theta_to_eta() is the identity, so its block
	of the objective can always be driven to EXACTLY ZERO by setting
	that block of theta to that block of eta_target, regardless of what
	the curved block's own theta is chosen to be - i.e. the ordinary
	blocks never trade off against the curved block in the joint
	objective (completing the square in the ordinary block's own theta
	always has a zero-residual solution available, independent of the
	curved block), so minimizing the FULL joint weighted objective is
	identical to minimizing each term's own block independently. Each
	curved term's own 2-parameter block is solved by Gauss-Newton using
	the exact analytic Jacobian from theta_to_eta_jacobian() (no numeric
	differencing, no external optimizer needed for a 2-parameter
	problem with a closed-form derivative already in hand) - projecting
	`alpha' back to a small positive value if a step would drive it
	non-positive (`ergm_gwdecay_map'/`_gradient' are only defined for
	alpha>0, matching R ergm's own `ergm_GWDECAY$minpar` constraint).
*/
real rowvector ErgmModel::project_eta_to_theta(real rowvector eta_target, real matrix W,
	real rowvector theta_start, real scalar maxit, real scalar tol){

	real rowvector theta, target_block, resid, resid_try, delta, theta_try
	real matrix Jb, Wb
	real scalar t, tpos, epos, iter, obj0, obj1, step, halvings, found

	theta = J(1, ntheta(), .)
	tpos = 1
	epos = 1
	for (t=1; t<=nterms; t++) {
		if (curved[t]) {
			theta[(tpos..tpos+1)] = theta_start[(tpos..tpos+1)]
			target_block = eta_target[(epos..epos+npar[t]-1)]
			Wb = W[(epos..epos+npar[t]-1), (epos..epos+npar[t]-1)]
			resid = target_block - ergm_gwdecay_map(theta[tpos], theta[tpos+1], npar[t])
			obj0 = resid * Wb * resid'
			for (iter=1; iter<=maxit; iter++) {
				Jb = ergm_gwdecay_gradient(theta[tpos], theta[tpos+1], npar[t])'
				delta = (invsym(Jb' * Wb * Jb) * Jb' * Wb * resid')'

				// Damped Gauss-Newton (backtracking line search): an
				// undamped step here can overshoot just as badly as
				// ErgmCurvedMPLEFit()'s own analogous fix (unit 137)
				// found - measured directly running this function
				// INSIDE curved MCMLE's own per-iteration loop
				// (harmonisation unit 138), where the eta-space
				// Newton step's own raw target can be far from the
				// achievable curved manifold, especially early on:
				// an undamped projection drove decay to 105 and the
				// whole MCMC chain into a 0%-acceptance degenerate
				// region on a real test network. Halve the step
				// (up to 30 times) until it both keeps decay
				// positive AND does not increase the weighted
				// residual norm - the exact same textbook fix, just
				// checking improvement in the least-squares objective
				// here instead of a log-likelihood, since this
				// function solves a weighted-least-squares problem,
				// not a likelihood maximization.
				step = 1
				found = 0
				for (halvings=1; halvings<=30; halvings++) {
					theta_try = theta[(tpos..tpos+1)] + step :* delta
					if (theta_try[2] > 1e-6) {
						resid_try = target_block - ergm_gwdecay_map(theta_try[1], theta_try[2], npar[t])
						obj1 = resid_try * Wb * resid_try'
						if (obj1 <= obj0) {
							found = 1
							break
						}
					}
					step = step / 2
				}
				if (!found) {
					// no improving, decay-positive step exists even
					// after 30 halvings - graceful boundary stop
					// (clamp decay to its floor, keep weight at its
					// own last valid value), matching
					// ErgmCurvedMPLEFit()'s own identical fix.
					theta[tpos+1] = 1e-6
					break
				}
				theta[(tpos..tpos+1)] = theta_try
				resid = resid_try
				if (obj0 - obj1 < tol) break
				obj0 = obj1
			}
			tpos = tpos + 2
		}
		else {
			theta[(tpos..tpos+npar[t]-1)] = eta_target[(epos..epos+npar[t]-1)]
			tpos = tpos + npar[t]
		}
		epos = epos + npar[t]
	}
	return(theta)
}

/*
	Theta-space coefficient names (length ntheta()): an ordinary term's
	own eta-space names unchanged (theta IS eta there), a curved term's
	own npar[t] internal eta-space names (e.g. "gwespfree_1".."_maxd" -
	never shown to the user) replaced by exactly 2 fixed display names,
	"gwesp_weight"/"gwesp_decay". Hardcoding that specific pair is a
	deliberate v1 simplification, not a general curved-term-naming
	scheme - matching this same file's own existing "not a fully
	independent per-term thing" convention for v1-scope simplifications
	(e.g. type() applying uniformly to every shared-partner term in a
	model rather than per-term) - v1 supports at most one curved term
	per model, and it is always this same weight/decay pair.
*/
string rowvector ErgmModel::theta_coefnames(){
	string rowvector out
	real scalar t, tpos, epos

	out = J(1, ntheta(), "")
	tpos = 1
	epos = 1
	for (t=1; t<=nterms; t++) {
		if (curved[t]) {
			// names[t] is the underlying statistic family the curved
			// term was registered under (harmonisation unit 139: "esp"
			// for gwespfree(), "degree" for gwdegreefree() - each
			// reusing that family's own already-certified statistic/
			// change functions directly, exactly as their own
			// addterm() call sites do) - used here only to pick the
			// right pair of DISPLAY names; v1 still supports at most
			// one curved term per model (nwergm.ado's own mutual-
			// exclusivity checks enforce this), so no per-model
			// disambiguation beyond this lookup is needed.
			if (names[t] == "degree") {
				out[tpos] = "gwdegree_weight"
				out[tpos+1] = "gwdegree_decay"
			}
			else if (names[t] == "dsp") {
				out[tpos] = "gwdsp_weight"
				out[tpos+1] = "gwdsp_decay"
			}
			else if (names[t] == "nsp") {
				out[tpos] = "gwnsp_weight"
				out[tpos+1] = "gwnsp_decay"
			}
			else if (names[t] == "odegree") {
				out[tpos] = "gwodegree_weight"
				out[tpos+1] = "gwodegree_decay"
			}
			else if (names[t] == "idegree") {
				out[tpos] = "gwidegree_weight"
				out[tpos+1] = "gwidegree_decay"
			}
			else {
				out[tpos] = "gwesp_weight"
				out[tpos+1] = "gwesp_decay"
			}
			tpos = tpos + 2
		}
		else {
			out[(tpos..tpos+npar[t]-1)] = coefnames[(epos..epos+npar[t]-1)]
			tpos = tpos + npar[t]
		}
		epos = epos + npar[t]
	}
	return(out)
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

/*
	Curved MPLE fit (harmonisation unit 136, revised - the first
	user-facing consumer of units 133-135's own certified theta<->eta
	numerics). Directly maximizes the SAME pseudolikelihood an ordinary
	(non-curved) MPLE fit's closed-form `logit' call already maximizes,
	logit P(Y_ij=1) = eta' * ChangeStat_ij, eta = theta_to_eta(theta) -
	via Newton-Raphson/Fisher scoring IN THETA-SPACE, using the exact
	analytic Jacobian (unit 134) via the chain rule, rather than a
	two-stage "fit the unconstrained eta MLE, then project it down to
	theta" heuristic (this function's own FIRST implementation, unit
	136's original version - reverted after direct testing against R on
	a well-identified 15-node network found it landing at a materially
	different, WRONG-SIGNED local point: weight -0.24 vs R's own +0.27,
	with a wildly unstable variance on decay, 6e5, despite the
	underlying projection numerics themselves being independently
	certified correct in unit 135 - the two-stage heuristic's own
	target, an already-fit UNCONSTRAINED eta MLE, turns out to not
	reliably sit close enough to the true curved MLE for a single
	Gauss-Newton step from a generic start to recover it, since the
	curved pseudolikelihood surface is genuinely non-convex/multi-modal
	in theta, per the same identifiability the Hunter and Handcock 2006
	curved-exponential-family framework this term class is built on
	already documents). Directly optimizing the TRUE objective in
	theta-space throughout is the textbook-correct fix, not a
	robustness patch on the old approach - every ordinary (non-curved)
	term is fit exactly as before (theta=eta identity collapses this to
	the same Newton-Raphson an ordinary GLM/logit fit already performs
	internally), so this one function now replaces the closed-form
	`logit' call ENTIRELY whenever any curved term is present, fitting
	every coefficient (ordinary and curved) jointly in one loop -
	`project_eta_to_theta()' (unit 135) remains in place, unused by
	MPLE now, since curved MCMLE (separate, not yet built) will still
	need it for its own eta-space Newton-step-then-project design, a
	genuinely different problem (projecting a a Monte Carlo estimating
	equation's own target, not directly maximizing a closed-form
	likelihood).

	Standard Fisher scoring for a binomial GLM with a nonlinear
	(curved) link from theta to the linear predictor's own coefficient
	vector: at each iterate, p = invlogit(X*eta(theta)'), gradient in
	eta-space = X'(y-p), Fisher information in eta-space = X' diag(p(1-p)) X
	(the ordinary logistic-regression information matrix `logit' itself
	computes internally) - chain-ruled into theta-space via this
	iterate's own Jacobian J: gradient_theta = J'*gradient_eta,
	information_theta = J' * information_eta * J (the standard
	Gauss-Newton/Fisher-scoring approximation, ignoring eta(theta)'s own
	second derivative - the same approximation the delta method itself
	always makes, not a new one introduced here). `p(1-p) :* X` avoids
	ever materializing the full ndyads x ndyads diagonal weight matrix
	the textbook formula writes (the same large-matrix-avoidance
	principle already documented at this file's own build_mple_data()
	call site in nwergm.ado, harmonisation unit 81).
*/
void ErgmCurvedMPLEFit(class ErgmModel scalar M, real matrix D,
	real rowvector theta_start, real scalar maxit, real scalar tol,
	string scalar theta_matname, string scalar V_theta_matname,
	string scalar converged_matname){

	real matrix X, Jac, I_eta, I_theta
	real colvector y, p, xb, w
	real rowvector theta, theta_try, eta, g_eta, g_theta, delta
	real scalar iter, converged, ncol, ll0, ll1, step, halvings, alpha_pos, found

	ncol = cols(D) - 1
	X = D[., (1..ncol)]
	y = D[., ncol+1]

	// v1 scope: at most one curved term, always registered LAST, its
	// own 2 theta columns (weight, decay) therefore always the final
	// 2 - `decay' is specifically the very last column. Both the alpha-
	// positivity clamp and the "large jump" backtracking trigger below
	// rely on knowing this position; a future multi-curved-term
	// extension would need a real "which theta columns are decay
	// parameters" accessor instead of this hardcoded last-column
	// assumption (documented as a v1 simplification elsewhere in this
	// file, e.g. ErgmModel::theta_coefnames()).
	alpha_pos = cols(theta_start)

	theta = theta_start
	ll0 = ergm_curved_loglik(M, X, y, theta)
	converged = 0
	for (iter=1; iter<=maxit; iter++) {
		eta = M.theta_to_eta(theta)
		xb = X * eta'
		p = invlogit(xb)
		g_eta = (X' * (y - p))'
		Jac = M.theta_to_eta_jacobian(theta)
		g_theta = g_eta * Jac
		w = p :* (1 :- p)
		I_eta = X' * (w :* X)
		I_theta = Jac' * I_eta * Jac
		delta = (invsym(I_theta) * g_theta')'

		// Damped Newton-Raphson (backtracking line search): a full,
		// undamped step can catastrophically overshoot on this term's
		// own genuinely non-convex pseudolikelihood surface (measured
		// directly during this unit's own development: a full step
		// drove decay to -92 on a real 15-node test network, cascading
		// to missing values everywhere downstream once decay left its
		// required positive domain) - halve the step (up to 30 times)
		// until it both keeps decay positive AND does not decrease the
		// log-pseudolikelihood, the standard, textbook fix for exactly
		// this failure mode (and part of why quasi-Newton methods like
		// R ergm's own BFGS are more robust than plain Newton-Raphson
		// in the first place - they effectively do this automatically).
		step = 1
		found = 0
		for (halvings=1; halvings<=30; halvings++) {
			theta_try = theta + step :* delta
			if (theta_try[alpha_pos] > 1e-6) {
				ll1 = ergm_curved_loglik(M, X, y, theta_try)
				if (ll1 >= ll0) {
					found = 1
					break
				}
			}
			step = step / 2
		}
		if (!found) {
			// No improving, alpha-positive step exists even after 30
			// halvings - the genuine signature of a boundary/degenerate
			// solution (decay -> 0), not a bug: measured directly on a
			// real combined triangle+curved-gwesp model where R's own
			// BFGS independently lands at decay=2.5e-10, essentially
			// the same boundary. Stop gracefully AT the boundary
			// (clamp decay to its floor, leave every other parameter at
			// its own last valid value) rather than accepting whatever
			// the final failed attempt happened to be, which is what
			// was cascading to missing everywhere downstream on this
			// exact case before this fix.
			theta[alpha_pos] = 1e-6
			converged = 1
			break
		}
		theta = theta_try
		ll0 = ll1
		if (max(abs(step :* delta)) < tol) {
			converged = 1
			break
		}
	}
	// final Fisher information (recomputed at the converged theta, not
	// reused from the last iteration's own pre-update value) for the
	// reported covariance - the same "evaluate at the estimate, not the
	// penultimate iterate" convention `logit' itself follows.
	eta = M.theta_to_eta(theta)
	xb = X * eta'
	p = invlogit(xb)
	w = p :* (1 :- p)
	I_eta = X' * (w :* X)
	Jac = M.theta_to_eta_jacobian(theta)
	I_theta = Jac' * I_eta * Jac

	st_matrix(theta_matname, theta)
	st_matrix(V_theta_matname, invsym(I_theta))
	st_matrix(converged_matname, (converged))
}

/*
	Binomial log-pseudolikelihood at a given theta - sum over dyads of
	y*log(p) + (1-y)*log(1-p), p = invlogit(X * theta_to_eta(theta)').
	Used by ErgmCurvedMPLEFit()'s own backtracking line search above to
	decide whether a candidate Newton step actually improves the fit.
*/
real scalar ergm_curved_loglik(class ErgmModel scalar M, real matrix X,
	real colvector y, real rowvector theta){

	real colvector p

	p = invlogit(X * M.theta_to_eta(theta)')
	return(sum(y :* ln(p) :+ (1 :- y) :* ln(1 :- p)))
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
	real scalar i, j, maxdiff, a, b
	real rowvector s0, s1, chg, diff

	maxdiff = 0

	// harmonisation unit 155 (bipartite support): restrict the
	// brute-force toggle sweep to cross-mode dyads only - the same
	// dyad space build_mple_data()/the proposals above are restricted
	// to. Toggling a same-mode pair here would be testing a change
	// statistic on a dyad no real proposal or MPLE row ever visits.
	if (G.bipartite) {
		for (a=1; a<=rows(G.mode1nodes); a++) {
			for (b=1; b<=rows(G.mode2nodes); b++) {
				i = G.mode1nodes[a]
				j = G.mode2nodes[b]
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
	real scalar i, j, ndyads, pos, p, a, b, masked

	p = nparam()
	masked = G.has_dyadmask

	// freedyads() (constraints, first piece - docs/ERGM_ROADMAP.md's
	// "Constraints beyond v1's free binary dyad space" row): a FIXED
	// dyad's own likelihood contribution is a constant given theta under
	// R ergm's own `constraints=~fixallbut(free)' (its tie state can
	// never differ from its observed value, so it drops entirely out of
	// the pseudolikelihood's dependence on theta) - confirmed directly
	// against real, installed R ergm 4.12.0 (`estimate="MPLE"' under
	// `fixallbut()' on a hand-built 6-node/15-dyad network with a 5-dyad
	// free mask reproduced R's OWN reported coefficient, -0.4054651,
	// EXACTLY logit(2/5) - the free-dyads-ONLY closed form - not
	// logit(8/15) (0.1335314, the unconstrained full-network density).
	// This means MPLE must skip fixed dyads' rows entirely, unlike
	// ErgmModel::full_statistic() (used as MCMLE's own OBSERVED target,
	// deliberately unmasked - see that method's own comment) - a fixed
	// dyad still contributes its true observed value to the FULL
	// network's sufficient statistic that a constrained MCMLE fit is
	// solving to match, it just never appears as its own row in the
	// per-dyad pseudolikelihood design matrix.

	// harmonisation unit 155 (bipartite support, docs/ERGM_ROADMAP.md):
	// a bipartite model's own valid dyad space is ONLY cross-mode pairs
	// (mode1nodes x mode2nodes), never the full n(n-1)/2 undirected
	// space - iterating the ordinary loop below would silently include
	// same-mode pairs no toggle/proposal ever visits, corrupting the
	// pseudolikelihood with rows for dyads that can never actually be
	// tied.
	if (G.bipartite) {
		if (masked) ndyads = _ergm_count_free_bipartite(G)
		else ndyads = rows(G.mode1nodes) * rows(G.mode2nodes)
		out = J(ndyads, p+1, 0)
		pos = 1
		for (a=1; a<=rows(G.mode1nodes); a++) {
			for (b=1; b<=rows(G.mode2nodes); b++) {
				i = G.mode1nodes[a]
				j = G.mode2nodes[b]
				if (masked) if (!G.freedyadmat[i,j]) continue
				out[pos, (1..p)] = change_toward_one(G, i, j)
				out[pos, p+1] = G.has_edge(i,j)
				pos++
			}
		}
		return(out)
	}

	if (G.directed) ndyads = G.n * (G.n - 1)
	else ndyads = G.n * (G.n - 1) / 2
	if (masked) ndyads = _ergm_count_free_onemode(G)

	out = J(ndyads, p+1, 0)
	pos = 1
	for (i=1; i<=G.n; i++) {
		for (j=1; j<=G.n; j++) {
			if (i==j) continue
			if (!G.directed && j<i) continue
			if (masked) if (!G.freedyadmat[i,j]) continue
			out[pos, (1..p)] = change_toward_one(G, i, j)
			out[pos, p+1] = G.has_edge(i,j)
			pos++
		}
	}
	return(out)
}

// Free-dyad counters for build_mple_data()'s own preallocation above -
// split out rather than inlined so the exact same canonical dyad-space
// walk (one-mode vs bipartite) is never duplicated/risking drift between
// a counting pass and the real data-filling pass.
real scalar _ergm_count_free_onemode(class ErgmGraph scalar G){
	real scalar i, j, cnt
	cnt = 0
	for (i=1; i<=G.n; i++) {
		for (j=1; j<=G.n; j++) {
			if (i==j) continue
			if (!G.directed && j<i) continue
			if (G.freedyadmat[i,j]) cnt++
		}
	}
	return(cnt)
}
real scalar _ergm_count_free_bipartite(class ErgmGraph scalar G){
	real scalar a, b, i, j, cnt
	cnt = 0
	for (a=1; a<=rows(G.mode1nodes); a++) {
		for (b=1; b<=rows(G.mode2nodes); b++) {
			i = G.mode1nodes[a]
			j = G.mode2nodes[b]
			if (G.freedyadmat[i,j]) cnt++
		}
	}
	return(cnt)
}

end

mata:

/* ===================================================================
   Native (C) MCMC backend - harmonisation unit 83, docs/CERTIFICATION.md.

   See native/ergm_mcmc.c's own header comment for the full evidence
   trail (Statnet source study, Mata microbenchmarks) motivating this
   and the exact wire format. Summary of the design this Mata-side glue
   implements:

   - Scope: originally exactly four terms (edges, mutual, nodematch,
     gwesp) - relaxed (harmonisation unit 91 follow-on, per explicit
     user instruction: "relax the restriction... move all effects to
     C") to also cover the full dyad-independent attribute/factor family
     (nodecov/nodeicov/nodeocov/absdist/nodematch_diff/nodefactor/
     nodeofactor/nodeifactor/sender/receiver/nodemix) and the GW-degree
     family (gwdegree/gwodegree/gwidegree) - see native/ergm_mcmc.c's
     own header and ErgmNativeSetup()'s own header comment below for the
     full current list and what still is NOT covered (edgecov/hamming,
     the shared-partner family beyond gwesp itself, and directed/OTP
     gwesp - both since relaxed too, see native/ergm_mcmc.c's own
     header). ErgmNativeSetup() below is the ONLY place that decides
     eligibility, by inspecting the model's own term names, once per
     `nwergm` call (never inside the MCMC loop). Any term outside the
     current native set anywhere in the model disables native for the
     WHOLE model - a hard architectural constraint, not a gap (see
     ErgmNativeSetup()'s own header) - ErgmMCMCSample()/
     ErgmMCMCSampleDiag() then run their original, unmodified Mata code
     path exactly as before this unit. Harmonisation unit 159 extended
     eligibility to BIPARTITE (two-mode) models too - graph TYPE is no
     longer a blanket disqualifier, only individual term names are (a
     bipartite model using only native-eligible bipartite terms - edges/
     b1cov/b2cov/b1factor/b2factor/b1degree/b2degree/b1star/b2star - now
     runs natively; see native/ergm_mcmc.c's own header for the real,
     measured speedup this unlocked, ~20x, bringing the R-comparison
     ratio from ~39x down to ~1.9x).
   - The Mata/native boundary is crossed exactly once per
     ErgmMCMCSample()/ErgmMCMCSampleDiag() call (i.e. once per MCMLE
     iteration), never once per proposal - the entire burnin+sampling
     loop runs inside the single `plugin call`.
   - Large, dyad-scale data (the edge list) crosses the boundary via
     Stata dataset variables (SF_vdata/st_store), never st_matrix() -
     the same package-wide rule this unit's own predecessor (unit 81)
     established in docs/SPARSE_BACKEND.md. Small, model-scale data
     (theta, term codes/decays, the observed statistic) crosses via a
     single space-separated argument string.
   - A dedicated Stata FRAME (`__ergm_native`) holds the plugin's own
     input/output dataset, entirely isolated from whatever dataset is
     in memory in the user's own current frame - no preserve/restore,
     so this cannot conflict with any preserve nwergm.ado's own calling
     context might already be holding.
   - G is rebuilt from the native run's own final edge list after every
     call, exactly reproducing ErgmMCMCSample()'s existing in-place-
     mutation contract that ErgmMCMLE()'s sequential-MCMLE outer loop
     depends on.
   - RNG: seeded once per call from a value drawn via Mata's own
     runiform() (so it is itself deterministic under `set seed`), then
     iterated independently inside the C plugin (xorshift128+) - see
     native/ergm_mcmc.c's own header for why this gives real Stata-seed
     reproducibility without claiming (or needing) bit-identical sample
     paths against the Mata backend.
   =================================================================== */

/*
	Directory containing the installed nwergm.ado (hence, by this
	project's own dev-repo layout, the sibling lib/plugins/ directory
	holding the compiled plugin) - "" if nwergm.ado cannot be found on
	the adopath (should not happen in practice, but ErgmNativeAvailable()
	below treats that as "native unavailable", falling back to Mata,
	rather than erroring).
*/
string scalar ErgmNativeInstallDir(){
	string scalar full, dir, fn

	full = findfile("nwergm.ado")
	if (full == "") return("")
	pathsplit(full, dir, fn)
	return(dir)
}

/*
	Platform-aware plugin location (harmonisation unit 87,
	docs/CERTIFICATION.md - phase C, cross-platform native builds).
	Three different platforms' own compiled plugin binaries need to
	coexist in the SAME repository/install tree simultaneously (built by
	separate CI runners on separate operating systems - see
	.github/workflows/build-plugins.yml - not chosen one-at-a-time by a
	single developer's own machine the way this project's earlier macOS-
	only build was). Stata's own plugin-naming convention
	(".plugin"/"_unix.plugin") is a human/packaging convention for
	program-name-based auto-discovery via adopath WITHOUT an explicit
	using() path - since every call site here always passes using() with
	a full, explicit path (see ErgmNativeSampleCore()), the actual
	on-disk filename Stata loads is never inferred from the program name,
	so per-platform SUBDIRECTORIES (rather than colliding on a single
	shared filename, which macOS's and Windows's own ".plugin" naming
	would otherwise do) are the simplest, most robust way to ship all
	three platforms' binaries from one commit without any one of them
	overwriting another. `c(os)` is read via `st_global("c(os)")` since
	Mata has no direct OS-detection primitive of its own - confirmed by
	direct trial to return "MacOSX"/"Windows"/"Unix" on the three
	platforms Stata supports.
*/
string scalar ErgmNativePluginSubdir(){
	string scalar os

	os = st_global("c(os)")
	if (os == "Windows") return("windows")
	if (os == "Unix") return("unix")
	return("macos")
}

string scalar ErgmNativePluginFilename(){
	if (st_global("c(os)") == "Unix") return("ergm_mcmc_unix.plugin")
	return("ergm_mcmc.plugin")
}

string scalar ErgmNativePluginPath(){
	string scalar dir

	dir = ErgmNativeInstallDir()
	if (dir == "") return("")
	return(pathjoin(pathjoin(dir, "lib"),
		pathjoin("plugins", pathjoin(ErgmNativePluginSubdir(), ErgmNativePluginFilename()))))
}

/*
	Whether a compiled native plugin exists for THIS platform. Returns 0
	(never errors) on any platform where lib/plugins/ergm_mcmc.plugin was
	not built - the only currently-built platform is macOS (arm64 +
	x86_64 fat binary; see native/Makefile and docs/ERGM_ARCHITECTURE.md's
	native-backend section for the documented, not-yet-executed Windows/
	Linux build recipe) - Windows/Linux users transparently get the
	existing, fully-functional Mata backend instead, matching this
	project's own explicit cross-platform requirement.
*/
real scalar ErgmNativeAvailable(){
	string scalar p

	p = ErgmNativePluginPath()
	if (p == "") return(0)
	return(fileexists(p))
}

/*
	Decides, once per `nwergm` call (never inside the MCMC loop, per
	this unit's own "term dispatch must be cheap" governing instruction),
	whether the model M is eligible for the native backend, and if so
	populates the small file-scope config globals ErgmMCMCSample()/
	ErgmMCMCSampleDiag() check at their own top. ALWAYS resets
	g_ergm_native_enabled first, so a call on an ineligible model
	correctly disables native even if a previous, eligible `nwergm` call
	earlier in the same session left it enabled. Returns 1 if native
	will be used, 0 otherwise (nwergm.ado does not need to inspect this
	return value - it exists mainly so cscripts/test_nwergm_native.do can
	assert eligibility computed as expected on known model shapes).
*/
/*
	Appends `v' as a new column of `A', handling the "A is still empty"
	base case Mata's own `,' (horizontal join) operator cannot handle
	directly (joining a 0x0 matrix to an n x 1 vector is a conformability
	error, not a no-op) - used by ErgmNativeSetup() below to build up
	`M.native_attrmat' one attribute-using term at a time without knowing
	in advance how many distinct attribute arrays the model will need.
*/
real matrix _ergm_mat_appendcol(real matrix A, real colvector v){
	if (cols(A) == 0) return(v)
	return((A, v))
}

/*
	Decides, once per `nwergm` call (never inside the MCMC loop, per
	this unit's own "term dispatch must be cheap" governing instruction),
	whether the model M is eligible for the native backend, and if so
	populates M's own native_* config fields that ErgmNativeSampleCore()
	reads. Returns 1 if native will be used, 0 otherwise (nwergm.ado does
	not need to inspect this return value - it exists mainly so
	cscripts/test_nwergm_native.do can assert eligibility computed as
	expected on known model shapes).

	Native-eligible terms (harmonisation unit 92, "move everything
	reasonably portable to C" - relaxing unit 83's own original narrow
	scope per the user's explicit instruction): edges, mutual,
	nodematch, gwesp (both the undirected/UTP and directed/OTP
	definitions - see wave 4 below), nodecov/nodeicov/nodeocov/absdist,
	nodematch_diff/nodefactor/nodeofactor/nodeifactor/sender/receiver,
	nodemix, gwdegree/gwodegree/gwidegree, the full degree-COUNT family
	- degree/odegree/idegree/concurrent/kstar/ostar/istar/degrange/
	odegrange/idegrange - which needed no new attribute-array plumbing
	at all, only degree bookkeeping already added for gwodegree/
	gwidegree (`outdeg'/`indeg') plus two small, direct C ports of Mata
	helper functions (`_ergm_choose()' -> `ergm_choose()',
	`_ergm_inrange()' -> `in_range()'), the undirected shared-partner
	family beyond gwesp - gwdsp/gwnsp/esp/dsp/triangle - reusing gwesp's
	own `adj[]'/`common_neighbors()' native infrastructure, and (unit 92
	wave 4, this update) the full DIRECTED shared-partner family: the
	OTP mode of gwesp/gwdsp/gwnsp/esp/dsp (dispatched by `tdt.sptype ==
	"OTP"', exactly mirroring this file's own stat_gwesp()/change_gwesp()
	etc. dispatch immediately above) plus ctriple/transitiveties/
	cyclicalties (directed-only terms with no undirected counterpart at
	all). All eight rest on a new `common_neighbors_otp()' primitive in
	native/ergm_mcmc.c - a direct port of this file's own
	`ErgmGraph::shared_partners_otp()' - backed by a NEW pair of
	directed adjacency arrays (`outadj'/`inadj', allocated only when a
	term needing them is present, exactly the same "pay only if used"
	discipline `adj'/`outdeg'/`indeg' already follow) since SP_OTP(a,b)
	!= SP_OTP(b,a) in general and so cannot reuse the undirected `adj[]'
	array gwesp's own UTP mode maintains. `ctriple' needs no dedicated
	native function at all (`change_ctriple()' in this file is exactly
	`delta * shared_partners_otp(j,i)', ported as a one-line
	`common_neighbors_otp(g,j,i)' call in native/ergm_mcmc.c's own
	change_term()) and `gwnsp'\''s OTP mode needs no separate native
	function either, for the same composition reason its UTP mode
	doesn't (`change_gwdsp_otp() - change_gwesp_otp()', computed inline).
	One marshalling wrinkle specific to the degree-COUNT family:
	`degrange()'/`odegrange()'/`idegrange()' allow an open-ended upper
	bound (`to' = Mata's `.' missing value, matching R's own `to=+Inf'
	default) - `.' itself cannot survive a plain `strtok()'/`atof()'
	round-trip through the native args string, so it is replaced with a
	large finite sentinel (1e9, comfortably above any real network's
	degree range) before marshalling; `in_range()' in native/ergm_mcmc.c
	treats `to >= 1e8' as "no upper bound", mirroring Mata's own `to >=
	.' check exactly. Each OUTPUT COLUMN of a multi-column term
	instance (e.g. nodefactor's one column per level) is expanded into
	its own native "slot" here - `native_termcodes'/`native_attridx'/
	`native_p1'/`native_p2' are sized to `M.nparam()' (total output
	columns), NOT `M.nterms' (term instances), unlike the original
	four-term version of this function (which could get away with
	nterms==nparam always, since every one of its four terms was
	single-column - no longer true in general). Distinct attribute
	arrays needed across the model's own terms are collected once into
	`M.native_attrmat' (via `_ergm_mat_appendcol()' above) and referenced
	by column index (`native_attridx', 1-based, 0 = none) rather than
	duplicating a single shared array the way the original version did
	(which only ever supported exactly one nodematch term's own attr).

	ITP/OSP/ISP/RTP (this update): the remaining four directed shared-
	partner definitions, previously bailing the WHOLE model out to Mata
	whenever requested (`td.sptype' anything other than "" or "OTP"),
	are now native too - `ErgmNativeSPCode()' below maps each
	(term, sptype) combination to its own dedicated termcode (40-59 in
	native/ergm_mcmc.c), reusing wave 4's own `outadj'/`inadj' arrays
	with no new graph-level state. Every native change_*_TYPE() function
	is a direct, line-by-line port of its already-certified Mata
	counterpart above (see this file's own shared_partners_itp()/_osp()/
	_isp()/_rtp() headers for the derivations); native-vs-Mata
	equivalence for all four is certified in
	cscripts/test_nwergm_native.do.

	BIPARTITE (two-mode) terms (harmonisation unit 159, termcodes 60-67):
	b1cov/b2cov/b1factor/b2factor (dyad-independent, units 156) and
	b1degree/b2degree/b1star/b2star (dyad-dependent, unit 157) - direct
	ports of this file's own already-certified change_b1cov()/etc.
	functions above. Native/ergm_mcmc.c's own graph_t/total_dyads()/
	propose_uniform() gained real bipartite dyad-space awareness as part
	of this same unit (previously a bipartite model was ALWAYS Mata-only
	regardless of term names, since the native proposal/dyad-space logic
	had none) - see that file's own header for the full account and the
	real, measured speedup (~20x, cutting the R-comparison ratio from
	~39x to ~1.9x, dev/ergm_benchmark_bipartite/). Native-vs-Mata
	equivalence (MCMC sampling AND the mode=1 MPLE design-matrix build)
	certified in cscripts/test_nwergm_bipartite.do.

	STILL NOT native-eligible (any one such term anywhere in the model
	disables native for the WHOLE model, falling back to the unmodified
	Mata sampler - this is a hard architectural constraint, not a
	todo-list gap: every term's change statistic must be evaluated on
	EVERY proposal, so a per-toggle mix of "some terms in C, some in
	Mata" would mean crossing the Mata/C boundary on every single
	proposal, exactly the overhead the native boundary exists to
	eliminate - see this file's own "Native (C) MCMC backend" header):
	edgecov/hamming, which need an n x n dyadic covariate matrix
	marshalled across the boundary - a genuinely different wire-protocol
	shape (a dense matrix, not a per-node attribute array) from
	everything else this function handles, deferred as the one
	remaining scoped follow-on (docs/ERGM_ROADMAP.md's own "Native
	backend" section) rather than folded into this wave to keep it
	controlled, exactly the same discipline the Mata term-expansion
	waves used throughout.
*/
real scalar ErgmNativeSPCode(string scalar sptype, real scalar utp, real scalar otp, real scalar itp, real scalar osp, real scalar isp, real scalar rtp){
	if (sptype == "OTP") return(otp)
	if (sptype == "ITP") return(itp)
	if (sptype == "OSP") return(osp)
	if (sptype == "ISP") return(isp)
	if (sptype == "RTP") return(rtp)
	return(utp)
}
real scalar ErgmNativeSetup(class ErgmModel scalar M, real scalar proposal_code, | class ErgmGraph G){
	real scalar t, k, pos, ncols, aidx, cidx, maxcols, maxattr, maxcovmat, masked
	string scalar nm
	real rowvector termcodes, attridxs, p1v, p2v, covidxs
	real matrix attrmat, covmatstack
	class ErgmTermData scalar tdt

	M.native_enabled = 0
	M.native_enabled_sample = 0
	M.fixed_density = 0		// explicit default for EVERY model (an uninitialized Mata class real scalar reads as missing, which is nonzero/"true" in an `if()` - nwergm.ado overrides this to 1, after this call returns, only for a fixdensity model)

	if (!ErgmNativeAvailable()) return(0)

	// freedyads() masked TNT native port (harmonisation unit 168):
	// masking no longer forces a whole-model Mata bailout here - it
	// only forces M.native_enabled itself to 0 at this function's own
	// tail below (MPLE/curved-MPLE still have no mask awareness at all,
	// a disclosed, narrower follow-on than before, not silently
	// ignored), while `masked' below drives the SEPARATE
	// native_enabled_sample flag that gates MCMC SAMPLING specifically.
	// Every term in the model is still checked for ordinary native
	// eligibility exactly as an unmasked model would be - masking is a
	// proposal/dyad-space concern, not a term-computation one, so it
	// changes nothing about which terms this loop accepts.
	// `rows(G)>0': G is optional (Mata forbids `| class T scalar'
	// outright), an omitted G arrives as a genuine 0 x 0 instance whose
	// own fields must never be read. nested `if', NOT `&': Mata's `&' is
	// NOT short-circuiting (both operands are always evaluated,
	// confirmed directly via a standalone repro - `rows(G) > 0 &
	// G.has_dyadmask' throws "nonclass found where class required" the
	// moment G is omitted, since G.has_dyadmask is evaluated regardless
	// of the left operand's own value). A real bug caught before it
	// ever shipped, not by inspection - kept exactly as it was found,
	// just no longer paired with an early return.
	masked = 0
	if (rows(G) > 0) {
		if (G.has_dyadmask) masked = 1
	}

	// harmonisation unit 155 (bipartite support): bipartite models were
	// ALWAYS Mata-only through unit 157 (native/ergm_mcmc.c's own
	// proposal/dyad-space logic had no bipartite awareness at all, so a
	// bipartite model routed to native would have silently sampled from
	// the FULL one-mode dyad space - visiting same-mode dyads no
	// bipartite proposal is ever supposed to touch). Harmonisation unit
	// 159 gives native/ergm_mcmc.c real bipartite dyad-space awareness
	// (its own `total_dyads()'/`propose_uniform()' now branch on
	// `g->bipartite', a direct C port of this file's own
	// `ergm_total_dyads()'/`ergm_propose_uniform()' bipartite branches)
	// PLUS native termcodes 60-67 for the eight bipartite terms
	// (b1cov/b2cov/b1factor/b2factor/b1degree/b2degree/b1star/b2star) -
	// so bipartite eligibility is now decided the SAME way one-mode
	// eligibility already is, term-by-term in the dispatch loop below,
	// not rejected up front by graph type. `G' is an OPTIONAL trailing
	// argument declared WITHOUT `scalar' (Mata forbids `| class T
	// scalar' outright - confirmed empirically; `| class T' is the only
	// legal form, and an omitted `G' arrives as a genuine 0 x 0 class
	// instance) - `ErgmNativeSampleCore()'/`ErgmNativeBuildMPLEData()'
	// both already receive G directly as their own required argument
	// (unlike this function), so they read `G.bipartite'/`G.mode'
	// straight off it to build the wire's own bipartite fields - no
	// need to stash bipartite state on M here at all.

	// must match native/ergm_mcmc.c's own MAXTERMS/MAXATTR exactly - a
	// model exceeding either falls back to Mata rather than risking the
	// C plugin's own hard-coded array bounds.
	maxcols = 64
	maxattr = 32
	maxcovmat = 8

	ncols = M.nparam()
	if (ncols > maxcols) return(0)

	termcodes = J(1, ncols, 0)
	attridxs = J(1, ncols, 0)
	p1v = J(1, ncols, 0)
	p2v = J(1, ncols, 0)
	covidxs = J(1, ncols, 0)
	attrmat = J(0, 0, .)
	covmatstack = J(0, 0, .)

	pos = 0
	for (t=1; t<=M.nterms; t++) {
		nm = M.names[t]
		tdt = *M.td[t]

		if (nm == "edges") {
			pos++
			termcodes[pos] = 1
		}
		else if (nm == "mutual") {
			pos++
			termcodes[pos] = 2
		}
		else if (nm == "nodematch") {
			if (cols(attrmat) + 1 > maxattr) return(0)
			attrmat = _ergm_mat_appendcol(attrmat, tdt.attr)
			aidx = cols(attrmat)
			pos++
			termcodes[pos] = 3
			attridxs[pos] = aidx
		}
		else if (nm == "gwesp") {
			// Unit 92 wave 4 added the OTP mode (termcode 32); this
			// update adds ITP/OSP/ISP/RTP (40/45/50/55) via
			// ErgmNativeSPCode() - all five directed modes reuse
			// native/ergm_mcmc.c's own outadj/inadj directed
			// adjacency arrays (allocated only when a term needing
			// them - this family, ctriple, transitiveties, or
			// cyclicalties - is present, same "pay only if used"
			// discipline as need_adj/need_outin above).
			pos++
			termcodes[pos] = ErgmNativeSPCode(tdt.sptype, 4, 32, 40, 45, 50, 55)
			p1v[pos] = tdt.decay
		}
		else if (nm == "nodecov") {
			if (cols(attrmat) + 1 > maxattr) return(0)
			attrmat = _ergm_mat_appendcol(attrmat, tdt.attr)
			aidx = cols(attrmat)
			pos++
			termcodes[pos] = 5
			attridxs[pos] = aidx
		}
		else if (nm == "nodeicov") {
			if (cols(attrmat) + 1 > maxattr) return(0)
			attrmat = _ergm_mat_appendcol(attrmat, tdt.attr)
			aidx = cols(attrmat)
			pos++
			termcodes[pos] = 6
			attridxs[pos] = aidx
		}
		else if (nm == "nodeocov") {
			if (cols(attrmat) + 1 > maxattr) return(0)
			attrmat = _ergm_mat_appendcol(attrmat, tdt.attr)
			aidx = cols(attrmat)
			pos++
			termcodes[pos] = 7
			attridxs[pos] = aidx
		}
		else if (nm == "absdist") {
			if (cols(attrmat) + 1 > maxattr) return(0)
			attrmat = _ergm_mat_appendcol(attrmat, tdt.attr)
			aidx = cols(attrmat)
			pos++
			termcodes[pos] = 8
			attridxs[pos] = aidx
		}
		else if (nm == "nodematch_diff") {
			if (cols(attrmat) + 1 > maxattr) return(0)
			attrmat = _ergm_mat_appendcol(attrmat, tdt.attr)
			aidx = cols(attrmat)
			for (k=1; k<=M.npar[t]; k++) {
				pos++
				termcodes[pos] = 9
				attridxs[pos] = aidx
				p1v[pos] = tdt.levels[k]
			}
		}
		else if (nm == "nodefactor") {
			if (cols(attrmat) + 1 > maxattr) return(0)
			attrmat = _ergm_mat_appendcol(attrmat, tdt.attr)
			aidx = cols(attrmat)
			for (k=1; k<=M.npar[t]; k++) {
				pos++
				termcodes[pos] = 10
				attridxs[pos] = aidx
				p1v[pos] = tdt.levels[k]
			}
		}
		else if (nm == "nodeofactor" | nm == "sender") {
			if (cols(attrmat) + 1 > maxattr) return(0)
			attrmat = _ergm_mat_appendcol(attrmat, tdt.attr)
			aidx = cols(attrmat)
			for (k=1; k<=M.npar[t]; k++) {
				pos++
				termcodes[pos] = 11
				attridxs[pos] = aidx
				p1v[pos] = tdt.levels[k]
			}
		}
		else if (nm == "nodeifactor" | nm == "receiver") {
			if (cols(attrmat) + 1 > maxattr) return(0)
			attrmat = _ergm_mat_appendcol(attrmat, tdt.attr)
			aidx = cols(attrmat)
			for (k=1; k<=M.npar[t]; k++) {
				pos++
				termcodes[pos] = 12
				attridxs[pos] = aidx
				p1v[pos] = tdt.levels[k]
			}
		}
		else if (nm == "nodemix") {
			if (cols(attrmat) + 1 > maxattr) return(0)
			attrmat = _ergm_mat_appendcol(attrmat, tdt.attr)
			aidx = cols(attrmat)
			for (k=1; k<=M.npar[t]; k++) {
				pos++
				termcodes[pos] = 13
				attridxs[pos] = aidx
				p1v[pos] = tdt.levelpairs[k,1]
				p2v[pos] = tdt.levelpairs[k,2]
			}
		}
		else if (nm == "gwdegree") {
			pos++
			termcodes[pos] = 14
			p1v[pos] = tdt.decay
		}
		else if (nm == "gwodegree") {
			pos++
			termcodes[pos] = 15
			p1v[pos] = tdt.decay
		}
		else if (nm == "gwidegree") {
			pos++
			termcodes[pos] = 16
			p1v[pos] = tdt.decay
		}
		else if (nm == "degree") {
			for (k=1; k<=M.npar[t]; k++) {
				pos++
				termcodes[pos] = 17
				p1v[pos] = tdt.levels[k]
			}
		}
		else if (nm == "odegree") {
			for (k=1; k<=M.npar[t]; k++) {
				pos++
				termcodes[pos] = 18
				p1v[pos] = tdt.levels[k]
			}
		}
		else if (nm == "idegree") {
			for (k=1; k<=M.npar[t]; k++) {
				pos++
				termcodes[pos] = 19
				p1v[pos] = tdt.levels[k]
			}
		}
		else if (nm == "concurrent") {
			pos++
			termcodes[pos] = 20
		}
		else if (nm == "kstar") {
			for (k=1; k<=M.npar[t]; k++) {
				pos++
				termcodes[pos] = 21
				p1v[pos] = tdt.levels[k]
			}
		}
		else if (nm == "ostar") {
			for (k=1; k<=M.npar[t]; k++) {
				pos++
				termcodes[pos] = 22
				p1v[pos] = tdt.levels[k]
			}
		}
		else if (nm == "istar") {
			for (k=1; k<=M.npar[t]; k++) {
				pos++
				termcodes[pos] = 23
				p1v[pos] = tdt.levels[k]
			}
		}
		else if (nm == "degrange") {
			for (k=1; k<=M.npar[t]; k++) {
				pos++
				termcodes[pos] = 24
				p1v[pos] = tdt.levelpairs[k,1]
				p2v[pos] = (tdt.levelpairs[k,2] >= . ? 1e9 : tdt.levelpairs[k,2])
			}
		}
		else if (nm == "odegrange") {
			for (k=1; k<=M.npar[t]; k++) {
				pos++
				termcodes[pos] = 25
				p1v[pos] = tdt.levelpairs[k,1]
				p2v[pos] = (tdt.levelpairs[k,2] >= . ? 1e9 : tdt.levelpairs[k,2])
			}
		}
		else if (nm == "idegrange") {
			for (k=1; k<=M.npar[t]; k++) {
				pos++
				termcodes[pos] = 26
				p1v[pos] = tdt.levelpairs[k,1]
				p2v[pos] = (tdt.levelpairs[k,2] >= . ? 1e9 : tdt.levelpairs[k,2])
			}
		}
		else if (nm == "gwdsp") {
			// gwdsp has no `sptype' field of its own (unlike gwesp) -
			// its own directed modes reuse the SAME td.sptype field,
			// see this file's own stat_gwdsp() dispatch - so the
			// mapping here mirrors gwesp's above.
			pos++
			termcodes[pos] = ErgmNativeSPCode(tdt.sptype, 27, 33, 41, 46, 51, 56)
			p1v[pos] = tdt.decay
		}
		else if (nm == "gwnsp") {
			pos++
			termcodes[pos] = ErgmNativeSPCode(tdt.sptype, 28, 34, 42, 47, 52, 57)
			p1v[pos] = tdt.decay
		}
		else if (nm == "esp") {
			for (k=1; k<=M.npar[t]; k++) {
				pos++
				termcodes[pos] = ErgmNativeSPCode(tdt.sptype, 29, 35, 43, 48, 53, 58)
				p1v[pos] = tdt.levels[k]
			}
		}
		else if (nm == "dsp") {
			for (k=1; k<=M.npar[t]; k++) {
				pos++
				termcodes[pos] = ErgmNativeSPCode(tdt.sptype, 30, 36, 44, 49, 54, 59)
				p1v[pos] = tdt.levels[k]
			}
		}
		else if (nm == "triangle") {
			pos++
			termcodes[pos] = 31
		}
		else if (nm == "ctriple") {
			pos++
			termcodes[pos] = 37
		}
		else if (nm == "transitiveties") {
			pos++
			termcodes[pos] = 38
		}
		else if (nm == "cyclicalties") {
			pos++
			termcodes[pos] = 39
		}
		// harmonisation unit 159: bipartite terms (units 156/157),
		// termcodes 60-67 - b1cov/b2cov mirror nodecov's own single-
		// column attrmat pattern exactly; b1factor/b2factor mirror
		// nodefactor's own multi-column pattern; b1degree/b2degree
		// mirror degree's own multi-column (no attrmat) pattern;
		// b1star/b2star mirror kstar's own. native/ergm_mcmc.c reads
		// each dyad's own mode via a dedicated `mode[]' array (not one
		// more attrmat column - mode is graph TOPOLOGY the proposal/
		// dyad-space logic also needs, not a per-term covariate), so
		// unlike every attribute-consuming branch above, these do not
		// touch `attrmat'/`attridxs' at all.
		else if (nm == "b1cov") {
			if (cols(attrmat) + 1 > maxattr) return(0)
			attrmat = _ergm_mat_appendcol(attrmat, tdt.attr)
			aidx = cols(attrmat)
			pos++
			termcodes[pos] = 60
			attridxs[pos] = aidx
		}
		else if (nm == "b2cov") {
			if (cols(attrmat) + 1 > maxattr) return(0)
			attrmat = _ergm_mat_appendcol(attrmat, tdt.attr)
			aidx = cols(attrmat)
			pos++
			termcodes[pos] = 61
			attridxs[pos] = aidx
		}
		else if (nm == "b1factor") {
			if (cols(attrmat) + 1 > maxattr) return(0)
			attrmat = _ergm_mat_appendcol(attrmat, tdt.attr)
			aidx = cols(attrmat)
			for (k=1; k<=M.npar[t]; k++) {
				pos++
				termcodes[pos] = 62
				attridxs[pos] = aidx
				p1v[pos] = tdt.levels[k]
			}
		}
		else if (nm == "b2factor") {
			if (cols(attrmat) + 1 > maxattr) return(0)
			attrmat = _ergm_mat_appendcol(attrmat, tdt.attr)
			aidx = cols(attrmat)
			for (k=1; k<=M.npar[t]; k++) {
				pos++
				termcodes[pos] = 63
				attridxs[pos] = aidx
				p1v[pos] = tdt.levels[k]
			}
		}
		else if (nm == "b1degree") {
			for (k=1; k<=M.npar[t]; k++) {
				pos++
				termcodes[pos] = 64
				p1v[pos] = tdt.levels[k]
			}
		}
		else if (nm == "b2degree") {
			for (k=1; k<=M.npar[t]; k++) {
				pos++
				termcodes[pos] = 65
				p1v[pos] = tdt.levels[k]
			}
		}
		else if (nm == "b1star") {
			for (k=1; k<=M.npar[t]; k++) {
				pos++
				termcodes[pos] = 66
				p1v[pos] = tdt.levels[k]
			}
		}
		else if (nm == "b2star") {
			for (k=1; k<=M.npar[t]; k++) {
				pos++
				termcodes[pos] = 67
				p1v[pos] = tdt.levels[k]
			}
		}
		// harmonisation unit 160: edgecov/hamming, the last remaining
		// gap in the native migration - both need a dense n x n dyadic
		// covariate matrix (`tdt.edgecovmat'), a genuinely different
		// shape from every attribute-consuming branch above (one value
		// per DYAD, not per node), so they get their own dedicated
		// "covmat" wire mechanism (native_covidx/native_covmatstack)
		// rather than reusing native_attridx/native_attrmat. Each
		// distinct edgecovmat is appended as its own n-column BLOCK
		// (not a single column, unlike attrmat) - covidxs[pos] records
		// the 1-based BLOCK index, and the wire-protocol callers
		// (ErgmNativeSampleCore()/ErgmNativeBuildMPLEData()/
		// ErgmNativeCurvedMPLEFit()) slice out columns
		// ((covidxs[pos]-1)*n+1)..(covidxs[pos]*n) to send as n new
		// dataset variables, mirroring how the mode[] array already
		// crosses the wire as its own dedicated column block (unit 159).
		else if (nm == "edgecov") {
			if (cols(covmatstack) / cols(tdt.edgecovmat) + 1 > maxcovmat) return(0)
			covmatstack = (cols(covmatstack) == 0 ? tdt.edgecovmat : (covmatstack, tdt.edgecovmat))
			cidx = cols(covmatstack) / cols(tdt.edgecovmat)
			pos++
			termcodes[pos] = 68
			covidxs[pos] = cidx
		}
		else if (nm == "hamming") {
			if (cols(covmatstack) / cols(tdt.edgecovmat) + 1 > maxcovmat) return(0)
			covmatstack = (cols(covmatstack) == 0 ? tdt.edgecovmat : (covmatstack, tdt.edgecovmat))
			cidx = cols(covmatstack) / cols(tdt.edgecovmat)
			pos++
			termcodes[pos] = 69
			covidxs[pos] = cidx
		}
		else return(0)
	}

	M.native_termcodes = termcodes
	M.native_attridx = attridxs
	M.native_p1 = p1v
	M.native_p2 = p2v
	M.native_attrmat = attrmat
	M.native_covidx = covidxs
	M.native_covmatstack = covmatstack
	M.native_proposal = proposal_code

	// harmonisation unit 168: every term passed the SAME eligibility
	// check either way (masking never rejected anything above) - a
	// masked model still forces native_enabled itself to 0 (MPLE/
	// curved-MPLE have no mask awareness - they simply never get called
	// when native_enabled is 0, falling through to their own
	// already-correct Mata free-dyad-only paths), but now also sets the
	// SEPARATE native_enabled_sample flag the two ErgmMCMCSample()/
	// ErgmMCMCSampleDiag() call sites check, plus native_maskmat, the
	// mask ErgmNativeSampleCore() sends across the wire. An unmasked
	// model gets native_enabled_sample==native_enabled always - the
	// split is a genuine no-op for every model that isn't masked.
	if (masked) {
		M.native_enabled = 0
		M.native_enabled_sample = 1
		M.native_maskmat = G.freedyadmat
	}
	else {
		M.native_enabled = 1
		M.native_enabled_sample = 1
	}
	return(1)
}

/*
	Runs the entire burnin+sampling MCMC loop natively via a single
	`plugin call` (see native/ergm_mcmc.c) and returns the same
	(samplesize x nparam) statistic-LEVELS matrix ErgmMCMCSample() itself
	returns - called from that function's (and ErgmMCMCSampleDiag()'s)
	own native branch only, never directly. Mutates G in place to the
	native run's own final network state (see this section's own header
	comment) and leaves the acceptance rate over the sampling phase in
	g_ergm_native_lastaccept for ErgmMCMCSampleDiag() to pick up.
*/
real matrix ErgmNativeSampleCore(class ErgmModel scalar M, class ErgmGraph scalar G,
		real rowvector theta, real scalar burnin, real scalar interval,
		real scalar samplesize, real rowvector obs){

	real matrix ties, out, newties, attrpad
	real scalar n, directed, nties, p, nattr, ncovmat, nobs_needed, i, k, rngseed, nties_out, __junk
	real scalar bipartite, hasmask
	real colvector modevec
	string scalar origframe, argstr, cmd, outvarlist, attrvarlist, modevarlist, covmatvarlist, maskvarlist

	string rowvector outvarnames, attrvarnames, covmatvarnames, maskvarnames

	n = G.n
	directed = G.directed
	bipartite = G.bipartite
	modevec = bipartite ? G.mode : J(0,1,0)
	ties = G.all_ties()
	nties = rows(ties)
	p = cols(theta)
	nattr = cols(M.native_attrmat)
	hasmask = rows(M.native_maskmat) > 0 ? 1 : 0
	ncovmat = n > 0 ? cols(M.native_covmatstack) / n : 0

	nobs_needed = max((ergm_total_dyads(G), samplesize, n, 1))

	origframe = st_framecurrent()
	stata("capture frame drop __ergm_native")
	stata("frame create __ergm_native")
	st_framecurrent("__ergm_native")

	st_addobs(nobs_needed)
	// BUGFIX: st_addvar() returns the new variable's column index -
	// calling it bare (uncaptured), as every line in this block used to,
	// makes Mata auto-display that return value as an unrequested,
	// unexplained integer, exactly like any other uncaptured top-level
	// Mata expression (confirmed directly: a bare st_addvar() call
	// prints its own return value just like a bare "1+1" would). This
	// was invisible in this file's OWN certification runs (every
	// existing cscripts/test_nwergm*.do wraps its own `nwergm'/`estat'
	// calls in `qui', which suppresses it) but fully visible to any
	// interactive user, exactly as reported: a plain
	// "nwergm ..., ...gwesp(0.5)..." call surfaced eight bare integers
	// (2 for v1/v2 here, plus this same bug's own nattr- and p-many
	// repeats just below) before its results table, once per MCMC
	// sample drawn (once per MCMLE iteration, plus once for the final
	// diagnostic sample) - not a cosmetic quirk, a real, unintentional
	// leak of internal bookkeeping into the user-visible log. The
	// identical bug (unvalidated st_addvar() calls) already existed in
	// calculate_betweenness_native() (unw_core.do) too, merely masked
	// there by nwbetween.ado's own qui-wrapped call site - fixed there
	// too, not just papered over here.
	__junk = st_addvar("double", "v1")
	__junk = st_addvar("double", "v2")

	// harmonisation unit 159: the per-node MODE array crosses the wire
	// as its own dedicated frame variable ("m"), positioned right after
	// v1/v2 and BEFORE the attribute columns - unlike attrmat's own
	// per-TERM covariate arrays, `mode' is graph TOPOLOGY the native
	// plugin's own proposal/dyad-space logic needs regardless of which
	// terms are present, so it is not folded into the generic attrmat
	// mechanism. Only created/stored when `bipartite' - a one-mode
	// model's own wire format is completely unchanged from before this
	// unit (byte-identical argstr/dataset shape), so no existing
	// one-mode native certification could regress.
	modevarlist = ""
	if (bipartite) {
		__junk = st_addvar("double", "m")
		modevarlist = " m"
		st_store((1::n), "m", modevec[1::n])
	}

	// Distinct attribute arrays needed across the model's own terms
	// (harmonisation unit 91 follow-on) - each gets its own frame
	// variable, positioned right after v1/v2 (and the mode column, if
	// any) and before the output columns; `native_attridx' (set by
	// ErgmNativeSetup()) is a 1-based index into THESE columns, in the
	// same order native_attrmat's own columns were built.
	attrvarlist = ""
	attrvarnames = J(1, nattr, "")
	for (i=1; i<=nattr; i++) {
		attrvarnames[i] = "a" + strofreal(i)
		__junk = st_addvar("double", attrvarnames[i])
		attrvarlist = attrvarlist + " " + attrvarnames[i]
	}

	// harmonisation unit 160 (edgecov/hamming native port): each distinct
	// dense n x n dyadic covariate matrix crosses the wire as its own
	// BLOCK of n dataset variables (one per matrix COLUMN, n rows each) -
	// positioned right after the attribute columns and before the output
	// columns, mirroring `mode[]''s own "dedicated column block, not
	// folded into attrmat" precedent (unit 159) since a dyadic covariate
	// is a genuinely different shape (one value per dyad) from a per-node
	// attribute array.
	covmatvarlist = ""
	covmatvarnames = J(1, ncovmat * n, "")
	for (k=1; k<=ncovmat; k++) {
		for (i=1; i<=n; i++) {
			covmatvarnames[(k-1)*n + i] = "cm" + strofreal(k) + "_" + strofreal(i)
			__junk = st_addvar("double", covmatvarnames[(k-1)*n + i])
			covmatvarlist = covmatvarlist + " " + covmatvarnames[(k-1)*n + i]
		}
	}

	// harmonisation unit 168 (freedyads() masked TNT native port): the
	// dyad-eligibility mask crosses the wire exactly like a covmat block
	// (its own dense n x n shape, 0/1 instead of a continuous weight) -
	// its own dedicated block of n columns, positioned right after the
	// covmat block and before the output columns, present only when
	// hasmask (this is the only one of the three wire-format callers
	// that ever sends hasmask=1 - ErgmNativeBuildMPLEData()/
	// ErgmNativeCurvedMPLEFit() always send 0, see their own header
	// comments on why masking stays their own Mata-only concern).
	maskvarlist = ""
	maskvarnames = J(1, hasmask * n, "")
	if (hasmask) {
		for (i=1; i<=n; i++) {
			maskvarnames[i] = "fm_" + strofreal(i)
			__junk = st_addvar("double", maskvarnames[i])
			maskvarlist = maskvarlist + " " + maskvarnames[i]
		}
	}

	outvarlist = ""
	outvarnames = J(1, p, "")
	for (i=1; i<=p; i++) {
		outvarnames[i] = "o" + strofreal(i)
		__junk = st_addvar("double", outvarnames[i])
		outvarlist = outvarlist + " " + outvarnames[i]
	}

	if (nties > 0) st_store((1::nties), ("v1","v2"), ties)

	if (nattr > 0) {
		attrpad = M.native_attrmat
		if (rows(attrpad) < n) attrpad = attrpad \ J(n - rows(attrpad), nattr, 0)
		st_store((1::n), attrvarnames, attrpad[1::n, .])
	}

	if (ncovmat > 0) st_store((1::n), covmatvarnames, M.native_covmatstack)
	if (hasmask) st_store((1::n), maskvarnames, M.native_maskmat)

	rngseed = floor(runiform(1,1) * 2147483647)

	// mode=0: run the MCMC burnin+sampling loop (native/ergm_mcmc.c's
	// own original, unchanged behavior) - see this file's own
	// ErgmNativeBuildMPLEData() for mode=1 (harmonisation unit 145).
	// `bipartite' is a new field inserted right after `directed'
	// (harmonisation unit 159) - every field after it shifts position
	// relative to the pre-unit-159 wire format, so native/ergm_mcmc.c's
	// own parser was updated in lockstep, not left to infer the new
	// field's presence from anything else. `ncovmat' (unit 160) is
	// likewise inserted right after `nattr' in ALL THREE wire-format
	// callers (this one, ErgmNativeBuildMPLEData(),
	// ErgmNativeCurvedMPLEFit()) and the C-side parser, in lockstep -
	// unit 92's own field-count-desync bug (a new field added by only
	// one caller silently shifted every later field) is the exact
	// failure mode this ordering discipline exists to avoid.
	// hasmask (unit 168) inserted right after ncovmat, before p - the
	// SAME "all three callers, in lockstep" discipline unit 160's own
	// ncovmat field required, since native/ergm_mcmc.c's single shared
	// header parser reads this exact field for EVERY mode (this
	// function is the only one that ever sends 1; see
	// ErgmNativeBuildMPLEData()/ErgmNativeCurvedMPLEFit() below, which
	// each send a literal 0 at the same position).
	argstr = "0 " + strofreal(n) + " " + strofreal(directed) + " " + strofreal(bipartite) + " " + strofreal(nties) + " " +
		strofreal(samplesize) + " " + strofreal(burnin) + " " + strofreal(interval) + " " +
		strofreal(M.native_proposal) + " " + strofreal(rngseed) + " " + strofreal(nattr) + " " + strofreal(ncovmat) + " " + strofreal(hasmask) + " " + strofreal(p)
	for (i=1; i<=p; i++) {
		argstr = argstr + " " + strofreal(M.native_termcodes[i]) + " " + strofreal(M.native_attridx[i]) +
			" " + strofreal(M.native_p1[i]) + " " + strofreal(M.native_p2[i]) + " " + strofreal(M.native_covidx[i])
	}
	for (i=1; i<=p; i++) argstr = argstr + " " + strofreal(theta[i])
	for (i=1; i<=p; i++) argstr = argstr + " " + strofreal(obs[i])

	// Stata will not let an already-loaded plugin-type program be
	// dropped and redefined within the same session (confirmed by
	// direct trial: a `capture program drop` immediately followed by
	// redefinition still errored "already defined" on the SECOND native
	// call of a session) - since every call here uses the identical
	// path, simply leaving an existing definition in place is correct;
	// `capture` swallows exactly that one harmless case, while a genuine
	// failure (bad path, corrupt plugin) still surfaces moments later
	// when the `plugin call' below cannot find the command.
	stata("capture program ergmnativemcmc, plugin using(" + char(34) + ErgmNativePluginPath() + char(34) + ")")

	cmd = "plugin call ergmnativemcmc v1 v2" + modevarlist + attrvarlist + covmatvarlist + maskvarlist + outvarlist + ", " + char(34) + argstr + char(34)
	stata(cmd)

	nties_out = st_numscalar("__ergm_native_nties_out")
	M.native_lastaccept = st_numscalar("__ergm_native_naccept") / st_numscalar("__ergm_native_ntried")

	out = st_data((1::samplesize), outvarnames)
	if (nties_out > 0) newties = st_data((1::nties_out), ("v1","v2"))
	else newties = J(0, 2, 0)

	st_framecurrent(origframe)
	stata("capture frame drop __ergm_native")

	G.init(n, directed)
	// G.init() unconditionally resets `bipartite'=0 (never touched by
	// init() otherwise, per its own header comment) - since G is being
	// fully rebuilt from the native run's own returned edge list, its
	// bipartite state has to be explicitly restored here or every
	// downstream caller (ErgmMCMLE()'s own next outer iteration,
	// estat gof, ...) would silently see a "one-mode" graph after the
	// very first native-backend bipartite call.
	if (bipartite) G.set_bipartite(modevec)
	for (i=1; i<=rows(newties); i++) G.toggle(newties[i,1], newties[i,2])

	return(out)
}

/*
	Harmonisation unit 145: the native-backend counterpart to
	ErgmModel::build_mple_data() - builds the SAME (ndyads x (p+1))
	design matrix (p change_toward_one() columns, one observed-tie
	response column), one pass over every dyad, but inside the compiled
	C plugin (native/ergm_mcmc.c, mode=1) instead of a Mata-interpreted
	double loop. Motivated directly by profiling on the SJ article's own
	real `ecoli2' benchmark network: with the per-count design-matrix
	width already brought down to its true tightest bound (this same
	unit's own earlier passes), build_mple_data()'s own per-dyad Mata
	loop - 87153 dyads, each a function-pointer call plus vector
	allocation - became the dominant remaining cost (~88% of the total
	curved-MPLE wall time), the same class of "Mata's own per-call
	interpreter overhead, not an algorithmic property" finding that
	originally motivated the native MCMC backend itself (unit 83's own
	header comment, native/ergm_mcmc.c).

	Callers MUST check ErgmNativeSetup()'s own return value first (it
	populates M.native_termcodes/attridx/p1/p2/attrmat as a side effect,
	the same as it already does for the MCMC path) - this function does
	not re-derive eligibility itself, exactly mirroring
	ErgmNativeSampleCore()'s own contract just above. Crucially,
	ErgmNativeSetup()'s own existing per-level expansion loops (`for
	(k=1; k<=M.npar[t]; k++) { pos++; termcodes[pos] = ...ESP...;
	p1v[pos] = tdt.levels[k] }' for "esp"/"dsp", the identical pattern
	for "degree"/"odegree"/"idegree") already handle a CURVED term's own
	multi-level eta-space expansion with ZERO changes needed here or
	there - a curved term is registered under the SAME plain term name
	("esp" for gwespfree(), etc.) with MULTIPLE `levels', exactly like
	the ordinary numlist-parameterized esp(2 3 4) option already native-
	eligible before this unit; ErgmNativeSetup() has never needed to
	know "curved" is a concept at all, and still doesn't.
*/
real matrix ErgmNativeBuildMPLEData(class ErgmModel scalar M, class ErgmGraph scalar G){
	real matrix ties, out, attrpad
	real scalar n, directed, nties, p, nattr, ncovmat, ndyads, nobs_needed, i, k, __junk
	real scalar bipartite
	real colvector modevec
	string scalar origframe, argstr, cmd, outvarlist, attrvarlist, respvar, modevarlist, covmatvarlist
	string rowvector outvarnames, attrvarnames, covmatvarnames

	n = G.n
	directed = G.directed
	bipartite = G.bipartite
	modevec = bipartite ? G.mode : J(0,1,0)
	ties = G.all_ties()
	nties = rows(ties)
	p = cols(M.native_termcodes)
	nattr = cols(M.native_attrmat)
	ncovmat = n > 0 ? cols(M.native_covmatstack) / n : 0
	ndyads = ergm_total_dyads(G)
	nobs_needed = max((ndyads, n, 1))

	origframe = st_framecurrent()
	stata("capture frame drop __ergm_native")
	stata("frame create __ergm_native")
	st_framecurrent("__ergm_native")

	st_addobs(nobs_needed)
	__junk = st_addvar("double", "v1")
	__junk = st_addvar("double", "v2")

	// harmonisation unit 159 - see ErgmNativeSampleCore()'s own identical
	// comment on why `mode' is its own dedicated wire column, not folded
	// into attrmat.
	modevarlist = ""
	if (bipartite) {
		__junk = st_addvar("double", "m")
		modevarlist = " m"
		st_store((1::n), "m", modevec[1::n])
	}

	attrvarlist = ""
	attrvarnames = J(1, nattr, "")
	for (i=1; i<=nattr; i++) {
		attrvarnames[i] = "a" + strofreal(i)
		__junk = st_addvar("double", attrvarnames[i])
		attrvarlist = attrvarlist + " " + attrvarnames[i]
	}

	// harmonisation unit 160 - see ErgmNativeSampleCore()'s own identical
	// comment on the covmat wire mechanism.
	covmatvarlist = ""
	covmatvarnames = J(1, ncovmat * n, "")
	for (k=1; k<=ncovmat; k++) {
		for (i=1; i<=n; i++) {
			covmatvarnames[(k-1)*n + i] = "cm" + strofreal(k) + "_" + strofreal(i)
			__junk = st_addvar("double", covmatvarnames[(k-1)*n + i])
			covmatvarlist = covmatvarlist + " " + covmatvarnames[(k-1)*n + i]
		}
	}

	if (nties > 0) st_store((1::nties), ("v1","v2"), ties)

	if (nattr > 0) {
		attrpad = M.native_attrmat
		if (rows(attrpad) < n) attrpad = attrpad \ J(n - rows(attrpad), nattr, 0)
		st_store((1::n), attrvarnames, attrpad[1::n, .])
	}

	if (ncovmat > 0) st_store((1::n), covmatvarnames, M.native_covmatstack)

	outvarlist = ""
	outvarnames = J(1, p, "")
	for (i=1; i<=p; i++) {
		outvarnames[i] = "o" + strofreal(i)
		__junk = st_addvar("double", outvarnames[i])
		outvarlist = outvarlist + " " + outvarnames[i]
	}
	respvar = "resp"
	__junk = st_addvar("double", respvar)

	// mode=1, then the SAME field order/count ErgmNativeSampleCore()'s
	// own argstr uses (samplesize/burnin/interval/proposal_code/rngseed/
	// theta/obs are all unused on the mode=1 path in native/ergm_mcmc.c -
	// sent as harmless placeholder zeros rather than a second, divergent
	// wire format the C-side parser would need its own branch to read).
	// hasmask (unit 168): always 0 here - MPLE has no mask awareness at
	// all, ErgmNativeSetup() forces M.native_enabled (which gates
	// whether this function is even called) to 0 for a masked model, so
	// this path never runs for one; the literal 0 below only keeps the
	// shared header's OWN field count aligned with ErgmNativeSampleCore()'s.
	argstr = "1 " + strofreal(n) + " " + strofreal(directed) + " " + strofreal(bipartite) + " " + strofreal(nties) + " " +
		"0 0 0 0 0 " + strofreal(nattr) + " " + strofreal(ncovmat) + " 0 " + strofreal(p)
	for (i=1; i<=p; i++) {
		argstr = argstr + " " + strofreal(M.native_termcodes[i]) + " " + strofreal(M.native_attridx[i]) +
			" " + strofreal(M.native_p1[i]) + " " + strofreal(M.native_p2[i]) + " " + strofreal(M.native_covidx[i])
	}
	for (i=1; i<=p; i++) argstr = argstr + " 0"	// theta (unused)
	for (i=1; i<=p; i++) argstr = argstr + " 0"	// obs (unused)

	stata("capture program ergmnativemcmc, plugin using(" + char(34) + ErgmNativePluginPath() + char(34) + ")")

	cmd = "plugin call ergmnativemcmc v1 v2" + modevarlist + attrvarlist + covmatvarlist + outvarlist + " " + respvar + ", " +
		char(34) + argstr + char(34)
	stata(cmd)

	out = st_data((1::ndyads), (outvarnames, respvar))

	st_framecurrent(origframe)
	stata("capture frame drop __ergm_native")

	return(out)
}

/*
	Harmonisation unit 146: curved MPLE, entirely native - builds the
	design matrix AND runs the damped Newton-Raphson fit inside a
	SINGLE plugin call (mode=2, native/ergm_mcmc.c), rather than
	building natively (mode=1, ErgmNativeBuildMPLEData() above) and
	then fitting in Mata (ErgmCurvedMPLEFit()) - motivated by direct
	profiling showing the Newton-Raphson loop itself, not the (already-
	native, already fast) design-matrix build, is the dominant
	remaining cost once the per-count basis width is already small
	(docs/CERTIFICATION.md unit 146). `ncurved' is derived directly from
	M's own structure (the LAST registered term instance's own `npar',
	when `curved[nterms]' is set) rather than passed by the caller -
	the same "registered last" invariant every other curved-MPLE code
	path in this file already relies on.

	Returns 1 on success (theta_matname/V_matname/converged_matname
	posted, exactly matching ErgmCurvedMPLEFit()'s own three-matrix
	output contract so callers can use either interchangeably), 0 if
	native itself reports failure (a singular final information matrix -
	a genuine, if rare, possible outcome on a real, possibly near-
	unidentified curved fit) - callers MUST fall back to
	ErgmCurvedMPLEFit() on the Mata-built design matrix in that case,
	exactly the same "no model ever left broken, only unaccelerated"
	discipline every other native-eligibility check in this file
	follows.
*/
real scalar ErgmNativeCurvedMPLEFit(class ErgmModel scalar M, class ErgmGraph scalar G,
		real scalar curved_decay_start, string scalar theta_matname,
		string scalar V_matname, string scalar converged_matname){

	real matrix ties, attrpad, theta_out, V_out
	real scalar n, directed, nties, p, nattr, ncovmat, nobs_needed, i, j, k, __junk, ncurved, ntheta, rc
	string scalar origframe, argstr, cmd, attrvarlist, covmatvarlist
	string rowvector attrvarnames, covmatvarnames

	n = G.n
	directed = G.directed
	ties = G.all_ties()
	nties = rows(ties)
	p = cols(M.native_termcodes)
	nattr = cols(M.native_attrmat)
	ncovmat = n > 0 ? cols(M.native_covmatstack) / n : 0
	// BUGFIX (caught by the very first smoke test): sized to `n' alone,
	// forgetting that v1/v2 need `nties' rows too - st_store() on the
	// edge list then threw "argument out of range" the moment a network
	// had more ties than nodes (the norm, not the exception). Matches
	// ErgmNativeBuildMPLEData()'s own sizing convention (max over every
	// row count this call actually stores into), just without `ndyads'
	// in the mix, since this function never writes per-dyad output.
	nobs_needed = max((nties, n, 1))
	ncurved = M.curved[M.nterms] ? M.npar[M.nterms] : 0

	origframe = st_framecurrent()
	stata("capture frame drop __ergm_native")
	stata("frame create __ergm_native")
	st_framecurrent("__ergm_native")

	st_addobs(nobs_needed)
	__junk = st_addvar("double", "v1")
	__junk = st_addvar("double", "v2")

	attrvarlist = ""
	attrvarnames = J(1, nattr, "")
	for (i=1; i<=nattr; i++) {
		attrvarnames[i] = "a" + strofreal(i)
		__junk = st_addvar("double", attrvarnames[i])
		attrvarlist = attrvarlist + " " + attrvarnames[i]
	}

	// harmonisation unit 160 - see ErgmNativeSampleCore()'s own identical
	// comment on the covmat wire mechanism. A curved term is never
	// edgecov/hamming itself, but a MIXED model (e.g. edges + gwespfree()
	// + edgecov()) still needs this path to speak the same wire shape as
	// the other two modes, since ErgmNativeSetup() populates
	// native_covidx/native_covmatstack once, model-wide, for all three
	// callers alike.
	covmatvarlist = ""
	covmatvarnames = J(1, ncovmat * n, "")
	for (k=1; k<=ncovmat; k++) {
		for (i=1; i<=n; i++) {
			covmatvarnames[(k-1)*n + i] = "cm" + strofreal(k) + "_" + strofreal(i)
			__junk = st_addvar("double", covmatvarnames[(k-1)*n + i])
			covmatvarlist = covmatvarlist + " " + covmatvarnames[(k-1)*n + i]
		}
	}

	if (nties > 0) st_store((1::nties), ("v1","v2"), ties)

	if (nattr > 0) {
		attrpad = M.native_attrmat
		if (rows(attrpad) < n) attrpad = attrpad \ J(n - rows(attrpad), nattr, 0)
		st_store((1::n), attrvarnames, attrpad[1::n, .])
	}

	if (ncovmat > 0) st_store((1::n), covmatvarnames, M.native_covmatstack)

	// mode=2, then the SAME field order ErgmNativeBuildMPLEData()'s own
	// argstr uses through the term-slot list, plus two new trailing
	// fields this mode alone consumes (ncurved, curved_decay_start) -
	// see native/ergm_mcmc.c's own header comment on the mode field for
	// why these two are always present but only meaningful here.
	// `bipartite' (harmonisation unit 159) is always sent as the literal
	// 0 here, never a real value read off G - curved MPLE has no
	// bipartite-eligible term (Stage 2/3's own bipartite terms are
	// dyad-independent/dyad-dependent counts, never curved), so this
	// mode never legitimately runs on a bipartite model; still parsed
	// on the C side either way, since mode=2 shares mode=0/1's own
	// single uniform wire header format field-for-field.
	// hasmask (unit 168): always 0 here, same reasoning as
	// ErgmNativeBuildMPLEData()'s own identical comment - curved MPLE
	// has no mask awareness either, and never runs when native_enabled
	// is 0 anyway; kept only for the shared header's own field-count
	// alignment across all three callers.
	argstr = "2 " + strofreal(n) + " " + strofreal(directed) + " 0 " + strofreal(nties) + " " +
		"0 0 0 0 0 " + strofreal(nattr) + " " + strofreal(ncovmat) + " 0 " + strofreal(p)
	for (i=1; i<=p; i++) {
		argstr = argstr + " " + strofreal(M.native_termcodes[i]) + " " + strofreal(M.native_attridx[i]) +
			" " + strofreal(M.native_p1[i]) + " " + strofreal(M.native_p2[i]) + " " + strofreal(M.native_covidx[i])
	}
	for (i=1; i<=p; i++) argstr = argstr + " 0"	// theta (unused)
	for (i=1; i<=p; i++) argstr = argstr + " 0"	// obs (unused)
	argstr = argstr + " " + strofreal(ncurved) + " " + strofreal(curved_decay_start)

	stata("capture program ergmnativemcmc, plugin using(" + char(34) + ErgmNativePluginPath() + char(34) + ")")

	cmd = "plugin call ergmnativemcmc v1 v2" + attrvarlist + covmatvarlist + ", " + char(34) + argstr + char(34)
	stata(cmd)

	st_framecurrent(origframe)
	stata("capture frame drop __ergm_native")

	rc = st_numscalar("__ergm_native_curved_rc")
	if (rc != 0) return(0)

	ntheta = st_numscalar("__ergm_native_curved_ntheta_out")
	theta_out = J(1, ntheta, .)
	for (i=1; i<=ntheta; i++) theta_out[i] = st_numscalar("__ergm_native_curved_theta" + strofreal(i))
	// V was written row-major (C convention) as a flat sequence - read
	// back via explicit (row,col) indices rather than a single linear
	// subscript, since Mata's own single-subscript addressing is
	// column-major and would silently transpose an ntheta>1 matrix
	// otherwise (V is symmetric here in theory, but relying on that to
	// paper over a row/column mismatch would be exactly the kind of
	// silent-but-wrong bug this project's own certification discipline
	// exists to catch before it ships).
	V_out = J(ntheta, ntheta, .)
	for (i=1; i<=ntheta; i++) {
		for (j=1; j<=ntheta; j++) {
			V_out[i,j] = st_numscalar("__ergm_native_curved_V" + strofreal((i-1)*ntheta+j))
		}
	}

	st_matrix(theta_matname, theta_out)
	st_matrix(V_matname, V_out)
	st_matrix(converged_matname, st_numscalar("__ergm_native_curved_converged"))
	return(1)
}

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
	if (G.bipartite) return(rows(G.mode1nodes) * rows(G.mode2nodes))
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
	if (G.bipartite) {
		// linear index -> (i,j) over the rectangular mode1 x mode2
		// cross-mode dyad space - the exact same closed-form
		// unranking style the directed branch below already uses,
		// just over a rectangular (n1 x n2) space instead of a
		// square-minus-diagonal (n x (n-1)) one, since every
		// mode1/mode2 pair is a valid, distinct dyad with no
		// diagonal to exclude (a node is never its own dyad partner
		// here, since the two lists are disjoint by construction).
		row = ceil(pick / rows(G.mode2nodes))
		col = mod(pick - 1, rows(G.mode2nodes)) + 1
		i = G.mode1nodes[row]
		j = G.mode2nodes[col]
	}
	else if (G.directed) {
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
	Masked uniform-random-dyad proposal (constraints, first piece -
	docs/ERGM_ROADMAP.md's "Constraints beyond v1's free binary dyad
	space" row - R ergm's own `constraints=~fixallbut(free)`): identical
	to ergm_propose_uniform() above, restricted to dyads G.freedyadmat
	marks eligible. Implemented as plain rejection sampling over the
	already-correct unmasked proposal, not a from-scratch closed-form
	unranking over the free-dyad subset - draws a candidate dyad from
	the FULL space via ergm_propose_uniform() and re-draws whenever it
	lands on a fixed dyad. This is standard-correct (rejection sampling
	from a uniform superset, conditioned on membership, is itself exactly
	uniform over the accepted subset) and stays STILL symmetric/O(1)-ish
	in expectation for any mask that is not pathologically sparse -
	set_dyadmask() already rejects the one truly degenerate case (zero
	free dyads) at setup time, before any MCMC ever runs, so this loop
	is only ever a genuine possibility-of-progress search, never an
	unconditional infinite spin; the `tries' cap below is a defensive
	backstop for an extremely (but not impossibly) sparse mask, not the
	expected path.

	A masked TNT variant (ergm_propose_tnt_masked(), below) now also
	exists (docs/ERGM_ROADMAP.md's "Constraints beyond v1's free binary
	dyad space" row) - nwergm.ado's own proposal() dispatch picks between
	this function and that one purely on `freedyads()' presence, not
	`proposal()' itself, so this remains the ONLY masked proposal when
	`proposal(uniform)' is explicitly requested (or defaulted to on a
	network too small/dense for TNT to matter).
*/
real rowvector ergm_propose_uniform_masked(class ErgmGraph scalar G){
	real rowvector uprop
	real scalar tries

	tries = 0
	do {
		uprop = ergm_propose_uniform(G)
		tries++
		if (tries > 1000000) {
			errprintf("freedyads(): could not find a free dyad to propose after 1,000,000 draws - the mask may be far too sparse relative to the total dyad space.\n")
			exit(error(499))
		}
	} while (!G.freedyadmat[uprop[1], uprop[2]])
	return(uprop)
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

	Picking "a uniformly random existing edge" is done here via
	ErgmGraph's own live edge array (elist/edgepos, maintained
	incrementally by toggle() - see ErgmGraph's own field comments),
	O(1) - originally this materialized the full tie list from scratch
	on every single proposal via all_ties() (O(n+nties)), benchmarked at
	~185x the uniform proposal's own per-step cost (docs/CERTIFICATION.md
	harmonisation unit 79); this is the O(1) live-edge-list fix that
	unit's own follow-on roadmap item called for (unit 80), matching
	Statnet's own C implementation's approach. The Q-branch below
	(ergm_propose_uniform) was ALREADY O(1) throughout - it picks via
	closed-form index unranking over the whole dyad space, never touching
	all_ties() - so this was the only genuinely non-O(1) piece of the
	whole proposal, and fixing it required no change to either branch's
	own Hastings-ratio math below.
*/
real rowvector ergm_propose_tnt(class ErgmGraph scalar G){
	real scalar Dtot, E, P, Q, DP, DO, i, j, logratio, pickedge, erow
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
		erow = ceil(runiform(1,1)*E)
		i = G.elist[erow, 1]
		j = G.elist[erow, 2]
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
	Masked TNT proposal (freedyads() follow-on - docs/ERGM_ROADMAP.md's
	"Constraints beyond v1's free binary dyad space" row): the SAME
	construction as ergm_propose_tnt() above, with every population count
	restricted to the free-dyad subspace. TNT's own derivation (Morris,
	Handcock & Hunter 2008) never assumes anything about WHICH specific
	dyads are eligible, only how many there are and how many are
	currently tied - running it on the free-dyad-only subspace (a
	well-defined, fixed-size state space, since dyad eligibility never
	changes mid-fit, only which free dyads are tied does) is
	mathematically identical to running ordinary TNT on a smaller graph
	whose only dyads are the free ones. So the log-ratio FORMULAS are
	byte-for-byte identical to ergm_propose_tnt()'s own; only the D/E
	they are computed from change:
	  - D (total dyad count)        -> G.nfreedyads (free dyads only)
	  - E (current tie count)       -> G.nfreeties (free AND currently
	                                   tied only - a fixed dyad's own tie
	                                   state, even if tied, can never be
	                                   proposed for removal, so it must
	                                   never count toward E)
	  - "pick a random existing tie" -> draws from G.freeelist (live free
	                                    ties only), never G.elist (which
	                                    also holds fixed ties - drawing
	                                    from there could propose removing
	                                    a fixed dyad, violating the
	                                    constraint outright)
	  - "pick a random dyad"         -> ergm_propose_uniform_masked(G)
	                                    (already-certified rejection
	                                    sampling over the free subspace),
	                                    not duplicated here.
	A fully-free mask (every dyad eligible) makes nfreedyads==Dtot and
	nfreeties==nties exactly, so this collapses to being statistically
	identical to the unmasked ergm_propose_tnt() - the certification test
	for this function confirms exactly that, proving the substitution
	introduces no bias of its own.
*/
real rowvector ergm_propose_tnt_masked(class ErgmGraph scalar G){
	real scalar Dtot, E, P, Q, DP, DO, i, j, logratio, pickedge, erow
	real rowvector uprop

	Dtot = G.nfreedyads
	E = G.nfreeties
	P = 0.5
	Q = 0.5
	DP = P * Dtot
	DO = DP / Q

	pickedge = 0
	if (runiform(1,1) < P & E > 0) pickedge = 1

	if (pickedge) {
		erow = ceil(runiform(1,1)*E)
		i = G.freeelist[erow, 1]
		j = G.freeelist[erow, 2]
	}
	else {
		uprop = ergm_propose_uniform_masked(G)
		i = uprop[1]
		j = uprop[2]
	}

	if (G.has_edge(i,j)) {
		logratio = (E==1) ? -ln(DP+Q) : ln(E :/ (DO+E))
	}
	else {
		logratio = (E==0) ? ln(DP+Q) : ln(1 + DO :/ (E+1))
	}
	return((i, j, logratio))
}

/*
	Fixed-density ("constraints=~edges" in R ergm) tie-swap proposal -
	NOT a filtered/masked single-toggle proposal like
	ergm_propose_uniform_masked()/ergm_propose_tnt_masked() above (those
	restrict WHICH single dyad may be proposed; this proposes TWO dyads
	at once, one tie removed and one non-tie added, so the total tie
	count is invariant by construction on every accepted move). Verified
	directly against R ergm's own real C source (`MH_ConstantEdges`,
	`src/MHproposals.c`, fetched fresh from the real CRAN 4.12.0 source
	tarball): "select edge at random; select non-edge at random" - no
	Hastings-ratio correction is applied there (no `MHp->logratio` set),
	which is correct BY CONSTRUCTION here too: the reverse move (the
	just-added tie picked as the "edge" half, the just-removed dyad
	picked as the "non-edge" half) is proposed with EXACTLY the same
	probability, since the tied/untied POPULATION SIZES themselves never
	change under this constraint (one removed, one added, every step) -
	a genuinely symmetric proposal, logratio=0 unconditionally, same as
	the plain (unmasked) uniform proposal's own symmetric case.

	Returns (tail_remove, head_remove, tail_add, head_add) - the CALLER
	(ErgmMCMCSampleSwap()/ErgmMCMCSampleDiagSwap() below), not this
	function, is responsible for toggling both dyads and evaluating
	their SUMMED change statistic, since that needs G's own intermediate
	(one-toggle-applied) state for a dyad-DEPENDENT term to see the
	correct post-first-toggle graph when evaluating the second dyad's
	own change - a single self-contained proposal function has no
	natural place to do that (see ErgmMCMCSampleSwap()'s own header for
	the exact telescoping argument this relies on).

	The "pick a uniform non-edge" half is done via straightforward
	rejection sampling on top of the already-existing
	ergm_propose_uniform() (propose any dyad, retry if it happens to
	already be tied) rather than a dedicated live non-tie list (unlike
	real ergm's own DyadGenRandNonedge(), which likely maintains one) -
	a disclosed simplification: fine for any network that is not
	extremely dense (few remaining non-ties to hit by chance), matching
	this option's own initial v1 scope (no native port, Mata-only).
*/
real rowvector ergm_propose_swap(class ErgmGraph scalar G){
	real scalar pick, i, j
	real rowvector cand

	if (G.nties == 0 | G.nties == ergm_total_dyads(G)) {
		// No valid swap exists at either boundary (nothing to remove, or
		// nothing to add) - cannot happen for a real fixed-density fit
		// starting from an observed network with at least one tie and at
		// least one non-tie, but guarded explicitly (same errprintf()+
		// exit(error()) idiom freedyads()/blockdiag() already use above)
		// rather than looping forever below.
		errprintf("fixdensity: network has no ties, or is complete - no valid tie/non-tie swap exists.\n")
		exit(error(498))
	}

	pick = ceil(runiform(1,1) * G.nties)

	do {
		cand = ergm_propose_uniform(G)
		i = cand[1]
		j = cand[2]
	} while (G.has_edge(i,j))

	return((G.elist[pick,1], G.elist[pick,2], i, j))
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

/*
	Fixed-density counterpart to ErgmMCMCSample() above - identical
	contract (mutates G in place, returns statistic LEVELS), but every
	step evaluates and accepts/rejects a COMPOUND (tie-removed,
	non-tie-added) move as one atomic unit, via ergm_propose_swap()
	above, rather than ErgmMCMCSample()'s own single-dyad toggle.

	Correctness of summing two change statistics via one intermediate
	toggle (not two independent full_change() calls on the UNCHANGED
	graph, which would be wrong for any dyad-DEPENDENT term): change
	statistics telescope by construction - full_change(G,t1,h1) is
	exactly stat(G after toggling (t1,h1)) - stat(G); tentatively
	applying that toggle and THEN calling full_change(G',t2,h2) on the
	once-toggled graph G' gives exactly stat(G'') - stat(G'), where G''
	has BOTH toggles applied. Summing the two therefore gives exactly
	stat(G'') - stat(G), the true joint change - the identical
	telescoping property `stat_gwdsp()'/`stat_dsp()' already exploit
	elsewhere in this file (replaying observed ties one at a time via
	their own change functions), just used here for a two-step
	tentative-then-maybe-undo proposal instead of a from-scratch replay.
	On rejection, the tentative first toggle is undone (G.toggle() is
	its own inverse - toggling the same dyad twice returns it to its
	original state), leaving G byte-identical to before this proposal
	was evaluated.

	Native (C) port not attempted (v1 Mata-only, matching this
	constraint's own initial scope) - M.fixed_density forces
	native_enabled/native_enabled_sample to 0 in nwergm.ado, so this
	function is always reached via the ordinary (non-native) path.
*/
real matrix ErgmMCMCSampleSwap(class ErgmModel scalar M, class ErgmGraph scalar G,
	real rowvector theta, real scalar burnin, real scalar interval,
	real scalar samplesize){

	real rowvector cur, prop, chg1, chg2, chgtot
	real scalar step, draw, t1, h1, t2, h2, cutoff
	real matrix out

	cur = M.full_statistic(G)
	out = J(samplesize, cols(cur), 0)

	for (step=1; step<=burnin; step++) {
		prop = ergm_propose_swap(G)
		t1 = prop[1]; h1 = prop[2]; t2 = prop[3]; h2 = prop[4]
		chg1 = M.full_change(G, t1, h1)
		G.toggle(t1, h1)
		chg2 = M.full_change(G, t2, h2)
		chgtot = chg1 + chg2
		cutoff = theta * chgtot'
		if (cutoff >= 0 | ln(runiform(1,1)) < cutoff) {
			G.toggle(t2, h2)
			cur = cur + chgtot
		}
		else {
			G.toggle(t1, h1)
		}
	}

	for (draw=1; draw<=samplesize; draw++) {
		for (step=1; step<=interval; step++) {
			prop = ergm_propose_swap(G)
			t1 = prop[1]; h1 = prop[2]; t2 = prop[3]; h2 = prop[4]
			chg1 = M.full_change(G, t1, h1)
			G.toggle(t1, h1)
			chg2 = M.full_change(G, t2, h2)
			chgtot = chg1 + chg2
			cutoff = theta * chgtot'
			if (cutoff >= 0 | ln(runiform(1,1)) < cutoff) {
				G.toggle(t2, h2)
				cur = cur + chgtot
			}
			else {
				G.toggle(t1, h1)
			}
		}
		out[draw, .] = cur
	}
	return(out)
}

real matrix ErgmMCMCSample(class ErgmModel scalar M, class ErgmGraph scalar G,
	real rowvector theta, real scalar burnin, real scalar interval,
	real scalar samplesize, pointer(real rowvector function) scalar proposalfn){

	real rowvector cur, prop, chg
	real scalar step, draw, tail, head, logratio, cutoff
	real matrix out

	cur = M.full_statistic(G)

	// Fixed-density dispatch (M.fixed_density, set in nwergm.ado only for
	// a `fixdensity' model - explicitly 0 for every other model via
	// ErgmNativeSetup(), which always runs before this function is ever
	// called, so this branch is unreachable/always-false for the
	// ordinary case, leaving everything below completely unchanged).
	// Checked BEFORE the native branch below since a fixed-density model
	// always has native_enabled_sample forced to 0 anyway (no native
	// port for this constraint - see ErgmMCMCSampleSwap()'s own header),
	// but checking first here documents that ordering explicitly rather
	// than relying on it silently.
	if (M.fixed_density) {
		return(ErgmMCMCSampleSwap(M, G, theta, burnin, interval, samplesize))
	}

	// Native backend fast path (harmonisation unit 83) - see this file's
	// own "Native (C) MCMC backend" section above. M.native_enabled is
	// set once per `nwergm' call by ErgmNativeSetup(), never inside this
	// loop; when 0 (the ordinary case for any model using a term outside
	// the native backend's own deliberately narrow scope, or on a
	// platform with no compiled plugin) every line below this branch is
	// completely unchanged from before this unit - proposalfn is simply
	// unused in the native branch, since the plugin implements its own
	// proposal/toggle loop natively (crossing the Mata/native boundary
	// once for this whole call, not once per proposal).
	if (M.native_enabled_sample) {
		return(ErgmNativeSampleCore(M, G, theta, burnin, interval, samplesize, cur))
	}

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

/*
	Identical Metropolis-Hastings loop to ErgmMCMCSample() above, plus an
	acceptance-rate tally over the SAMPLING phase (post burn-in) - kept as
	a separate function rather than adding an acceptance-rate return to
	ErgmMCMCSample() itself, so ErgmMCMCSample()'s own already-certified
	signature/behavior (used throughout the MCMLE outer loop, where
	per-iteration acceptance rate is not needed) never changes. Used for
	the one "final" simulation ErgmMCMLE() runs at its converged theta
	(see below) - that draw is also nwergm's own basic MCMC diagnostics
	sample (Part XIX of the governing design brief: trace/mean/SD/
	autocorrelation/ESS/acceptance rate/convergence indicators), so it is
	worth tallying acceptance for exactly that one pass rather than every
	MCMLE iteration's own internal simulation.
*/
struct ErgmMCMCDiag {
	real matrix sample
	real scalar acceptrate
}

/*
	Fixed-density counterpart to ErgmMCMCSampleDiag() below - identical
	relationship ErgmMCMCSampleSwap() has to ErgmMCMCSample() (see its
	own header for the telescoping-change-statistic correctness
	argument), plus the same acceptance-rate tally ErgmMCMCSampleDiag()
	itself adds over ErgmMCMCSample().
*/
struct ErgmMCMCDiag scalar ErgmMCMCSampleDiagSwap(class ErgmModel scalar M, class ErgmGraph scalar G,
	real rowvector theta, real scalar burnin, real scalar interval,
	real scalar samplesize){

	struct ErgmMCMCDiag scalar res
	real rowvector cur, prop, chg1, chg2, chgtot
	real scalar step, draw, t1, h1, t2, h2, cutoff, naccept, ntried

	cur = M.full_statistic(G)
	res.sample = J(samplesize, cols(cur), 0)

	for (step=1; step<=burnin; step++) {
		prop = ergm_propose_swap(G)
		t1 = prop[1]; h1 = prop[2]; t2 = prop[3]; h2 = prop[4]
		chg1 = M.full_change(G, t1, h1)
		G.toggle(t1, h1)
		chg2 = M.full_change(G, t2, h2)
		chgtot = chg1 + chg2
		cutoff = theta * chgtot'
		if (cutoff >= 0 | ln(runiform(1,1)) < cutoff) {
			G.toggle(t2, h2)
			cur = cur + chgtot
		}
		else {
			G.toggle(t1, h1)
		}
	}

	naccept = 0
	ntried = 0
	for (draw=1; draw<=samplesize; draw++) {
		for (step=1; step<=interval; step++) {
			prop = ergm_propose_swap(G)
			t1 = prop[1]; h1 = prop[2]; t2 = prop[3]; h2 = prop[4]
			chg1 = M.full_change(G, t1, h1)
			G.toggle(t1, h1)
			chg2 = M.full_change(G, t2, h2)
			chgtot = chg1 + chg2
			cutoff = theta * chgtot'
			ntried++
			if (cutoff >= 0 | ln(runiform(1,1)) < cutoff) {
				G.toggle(t2, h2)
				cur = cur + chgtot
				naccept++
			}
			else {
				G.toggle(t1, h1)
			}
		}
		res.sample[draw, .] = cur
	}
	res.acceptrate = naccept / ntried
	return(res)
}

struct ErgmMCMCDiag scalar ErgmMCMCSampleDiag(class ErgmModel scalar M, class ErgmGraph scalar G,
	real rowvector theta, real scalar burnin, real scalar interval,
	real scalar samplesize, pointer(real rowvector function) scalar proposalfn){

	struct ErgmMCMCDiag scalar res
	real rowvector cur, prop, chg
	real scalar step, draw, tail, head, logratio, cutoff, naccept, ntried

	cur = M.full_statistic(G)

	// Fixed-density dispatch - see ErgmMCMCSample()'s own identical
	// branch for the full rationale.
	if (M.fixed_density) {
		return(ErgmMCMCSampleDiagSwap(M, G, theta, burnin, interval, samplesize))
	}

	// Native backend fast path - see ErgmMCMCSample()'s own identical
	// branch just above for the full rationale; the acceptance rate
	// ErgmNativeSampleCore() tallies internally is picked up from
	// M.native_lastaccept here since this function's own return type
	// (unlike ErgmMCMCSample()'s bare matrix) has a natural place to put
	// it.
	if (M.native_enabled_sample) {
		res.sample = ErgmNativeSampleCore(M, G, theta, burnin, interval, samplesize, cur)
		res.acceptrate = M.native_lastaccept
		return(res)
	}

	res.sample = J(samplesize, cols(cur), 0)

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

	naccept = 0
	ntried = 0
	for (draw=1; draw<=samplesize; draw++) {
		for (step=1; step<=interval; step++) {
			prop = (*proposalfn)(G)
			tail = prop[1]
			head = prop[2]
			logratio = prop[3]
			chg = M.full_change(G, tail, head)
			cutoff = (theta * chg') + logratio
			ntried++
			if (cutoff >= 0 | ln(runiform(1,1)) < cutoff) {
				G.toggle(tail, head)
				cur = cur + chg
				naccept++
			}
		}
		res.sample[draw, .] = cur
	}
	res.acceptrate = naccept / ntried
	return(res)
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
   procedure.

   Convergence: a genuine joint Hotelling's T² test (via its exact F
   transformation) that the centered sample mean is statistically
   indistinguishable from the zero vector, AND the last step was
   untruncated (gamma==1) - matching Statnet's own default "confidence"
   termination method's actual statistical structure (a joint test
   across all parameters simultaneously, at Statnet's own observed 99%
   confidence level), not merely inspired by its name. An EARLIER
   version of this function used a per-coordinate rule ("every
   |Dbar_k| < 0.5*se_k simultaneously") that was a materially different,
   needlessly conservative test: requiring every marginal coordinate to
   individually clear its own threshold compounds probabilities across
   parameters, so it could take many more MCMLE iterations than a proper
   joint test to declare convergence even once theta had genuinely
   converged - confirmed empirically (harmonisation unit 80) against a
   real head-to-head benchmark with Statnet's own `ergm()` on identical
   data: the per-coordinate rule needed 10-20 iterations where Statnet
   needed 1; the joint Hotelling test now typically needs 1-7.

   Final variance-covariance: `Bread' = the covariance of the
   sufficient statistics from a FRESH simulation at the final theta
   (not reused from a step-shrunk intermediate sample); `e(V) =
   Bread^-1', with a lag-1-autocorrelation inflation factor
   `(1+rho)/(1-rho)' applied per statistic dimension before inverting -
   a basic, disclosed stand-in for Statnet's own spectral/HAC long-run-
   variance correction (docs/ERGM_STATNET_STUDY.md Appendix A §7's own
   explicit finding that skipping this correction entirely would give
   systematically too-small standard errors). A batch-means alternative
   (robust to any autocorrelation shape, not assuming pure AR(1)
   dynamics) was implemented and directly compared against real Statnet
   `ergm()` reference values across 8 seeds on this suite's own
   canonical directed edges+mutual network (harmonisation unit 80): the
   lag-1 correction landed tightly clustered around Statnet's own true
   value (edges 0.39-0.50 vs Statnet's 0.4447; mutual 1.89-2.28 vs
   Statnet's 2.1716), while batch-means (with the standard
   floor(sqrt(samplesize)) batch-count heuristic) was both far noisier
   and often badly biased across the identical seeds (edges 0.34-5.06) -
   rejected on that direct evidence, not merely theoretical preference,
   despite being the more general method in principle. Kept as a
   documented negative result rather than shipped dead code.
   =================================================================== */

struct ErgmMCMLEFit {
	real rowvector coef
	real matrix vcov
	real scalar converged
	real scalar niter
	real matrix coefhist
	real matrix finalsample	// the final simulation's own sufficient-statistic
				// draws (samplesize x nparam) - doubles as nwergm's
				// basic MCMC diagnostics sample (Part XIX)
	real scalar acceptrate	// Metropolis-Hastings acceptance rate over that
				// same final simulation's sampling phase
	real scalar final_interval	// the (possibly grown - unit 85's own
				// adaptive-interval mechanism) `interval' value
				// actually used for the LAST MCMLE iteration and
				// the final diagnostics simulation - equal to the
				// caller-supplied interval whenever no growth was
				// ever triggered (the ordinary case for small/
				// well-mixing models).
	real rowvector coef_theta	// harmonisation unit 138 (curved MCMLE):
				// theta-space coefficients (length M.ntheta()),
				// populated only when M has a curved term -
				// EMPTY (0-length) for an ordinary model, since
				// `coef' above already IS theta there (eta=theta
				// identity) and callers should keep reading that
				// field as before; a curved caller reads THIS
				// field instead, plus transforms `vcov' via the
				// Jacobian at this same point (see nwergm.ado's
				// own call site for the exact delta-method step -
				// identical in form to ErgmCurvedMPLEFit()'s own,
				// just evaluated at the final theta rather than a
				// Newton-Raphson optimum).
	real matrix coefhist_theta	// harmonisation unit 162: the THETA-space
				// analogue of `coefhist' above (which is always
				// eta-space, even for a curved model) - one row
				// per MCMLE iteration, populated only when M has
				// a curved term (0 x M.ntheta() otherwise). Unit
				// 152's own disclosed next step ("log the
				// theta-space trajectory itself across iterations
				// to check whether it is monotonically drifting
				//... versus genuinely oscillating") had never
				// actually been built until this unit - purely
				// additive instrumentation, gated behind the same
				// `is_curved' flag as everything else curved-
				// specific in this function, so it cannot affect
				// any non-curved model's behavior at all.
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

/*
	AR(p)/Yule-Walker long-run-variance inflation factor (harmonisation
	unit 86, docs/CERTIFICATION.md - phase B, "inferential parity")
	replacing `ergm_lag1_autocorr()'-based `(1+rho)/(1-rho)' as the
	production variance correction. Motivation, verified directly rather
	than assumed: Statnet's own current R/mcmc_se.R (fresh GitHub check)
	estimates the long-run Monte Carlo covariance of the sufficient
	statistics via `spectrum0.mvar()' (coda package) - fitting an AR
	model to the (thinned) MCMC series and evaluating its implied
	spectral density at frequency 0, the standard Geyer (1992) "initial
	sequence"/AR approach to MCMC standard errors, generalizing far
	beyond a single lag-1 correction. It also reports an explicit
	`neff = n/infl' - the SAME effective-sample-size concept units 84-85
	already added to this file's own convergence test, independently
	confirming that mechanism's conceptual alignment with Statnet's real
	approach rather than being this project's own invention.

	`ergm_lag1_autocorr()'-based `(1+rho)/(1-rho)' is the exact AR(1)
	special case of this estimator (confirmed by direct construction: on
	a genuine AR(1) series, both formulas agree to 3 significant figures
	- see cscripts/test_nwergm_variance.do) - this function is a strict
	generalization, not a different method. Validated against a REAL
	Statnet reference (the exact 5-node network/theta
	cscripts/test_nwergm_mcmle.do already certifies against, vcov diag
	edges=0.44468 mutual=2.17162): lag-1 lands at 0.3677/1.7475 (17-20%
	low); this AR(p) estimator lands at 0.4066/2.1778 (9% low / 0.3% off)
	- closer on both parameters, essentially exact on the harder-to-pin
	mutual term - the same "implement, test against real evidence, adopt
	only if it wins" discipline already used for the shared-partner cache
	(unit 82) and the batch-means-vs-lag-1 comparison (unit 80), this
	time actually adopting the alternative because it measurably won.

	Fits AR(p) to a mean-centered univariate series via the Yule-Walker
	equations, selecting p by AIC among candidates 0..pmax (matching R's
	own `ar(x, method="yule-walker", aic=TRUE)' default, which
	`spectrum0.ar'/`spectrum0.mvar' build on) - applied per parameter
	dimension rather than as a genuine multivariate VAR (Statnet's own
	`spectrum0.mvar' does fit a multivariate model; this per-dimension
	approximation is a deliberate, disclosed simplification, matching
	this file's own established practice of disclosing where it departs
	from Statnet's own, larger implementation - see
	docs/ERGM_ARCHITECTURE.md). Off-diagonal covariances are left
	untouched (only each dimension's own diagonal variance is inflated),
	exactly mirroring how `ergm_lag1_autocorr()' was already used.
*/
real scalar ergm_ar_yw_infl(real colvector x, real scalar pmax){
	real scalar n, gamma0, k, j, p, best_aic, best_sigma2, sigma2, aic, sumphi, lag
	real colvector acf, phi, r
	real matrix R

	n = rows(x)
	gamma0 = variance(x) * (n-1) / n
	if (gamma0 <= 0) return(1)

	acf = J(pmax, 1, 0)
	for (k=1; k<=pmax; k++) acf[k] = (x[1::(n-k)]' * x[(k+1)::n]) / n / gamma0

	// order 0 (white noise) is always a candidate - infl=1
	best_aic = n * ln(gamma0)
	best_sigma2 = gamma0
	p = 0
	sumphi = 0

	for (j=1; j<=pmax; j++) {
		R = J(j, j, 0)
		r = acf[1::j]
		for (k=1; k<=j; k++) {
			for (lag=1; lag<=j; lag++) {
				R[k,lag] = (k==lag) ? 1 : acf[abs(k-lag)]
			}
		}
		phi = invsym(R) * r
		sigma2 = gamma0 * (1 - r' * phi)
		if (sigma2 <= 0) continue
		aic = n * ln(sigma2) + 2*j
		if (aic < best_aic) {
			best_aic = aic
			best_sigma2 = sigma2
			p = j
			sumphi = sum(phi)
		}
	}

	if (p == 0) return(1)
	// guard against a nonstationary fit at the selected order
	if (sumphi >= 1) sumphi = 0.999
	return( (best_sigma2 / (1-sumphi)^2) / gamma0 )
}

/*
	Applies ergm_ar_yw_infl() to every column of D (centered draws, e.g.
	samp :- mean(samp)) - the direct drop-in replacement for
	`(1 :+ ergm_lag1_autocorr(D)) :/ (1 :- ergm_lag1_autocorr(D))'.
	`pmax' follows R's own `ar()' default order-search bound
	(`min(n-1, floor(10*log10(n)))'), capped at 50 for performance.
*/
real rowvector ergm_spectral0_ar(real matrix D){
	real scalar ncol, k, n, pmax
	real rowvector out

	ncol = cols(D)
	n = rows(D)
	pmax = floor(min((n-1, 10*log10(n))))
	if (pmax > 50) pmax = 50
	if (pmax < 1) pmax = 1
	out = J(1, ncol, 1)
	for (k=1; k<=ncol; k++) out[k] = ergm_ar_yw_infl(D[.,k], pmax)
	return(out)
}

/*
	Harmonisation unit 144: formal MCMC convergence diagnostics - the
	Geweke (1992) z-score and the Heidelberger-Welch (1983) stationarity/
	halfwidth test, the two `coda`-package tests behind R ergm's own
	`mcmc.diagnostics()`. Ported directly from `coda`'s real current
	source (`coda::geweke.diag`/`coda::heidel.diag`/`coda:::pcramer`,
	coda 0.19.4.1, fetched and read directly from a local R install, not
	from memory) rather than re-derived from a textbook description -
	`ergm_spec0_scalar()` below reuses this file's own already-certified
	AR(p) Yule-Walker spectral-density-at-0 estimator (`ergm_ar_yw_infl()`,
	unit 86) for exactly the role `coda::spectrum0.ar()` plays in both
	real functions, rather than a second, independent implementation.

	Heidelberger-Welch's own stationarity test needs `pcramer()`, the
	Cramer-von-Mises CDF, which `coda` itself evaluates via a modified
	Bessel function of the second kind at a NON-integer order (1/4) -
	genuinely nontrivial numerically (no closed form, and the standard
	reflection-formula route via ordinary Bessel I functions loses
	precision to catastrophic cancellation at the statistic's own typical
	range), with no existing infrastructure anywhere in this package.
	Rather than build and separately certify a general Bessel-K routine
	for a single narrow use, the test is instead evaluated the classical
	way (Schruben 1982; this is how Heidelberger-Welch's OWN original
	paper and most pre-`coda` implementations present it): compare the
	Cramer-von-Mises test statistic directly against a FIXED critical
	value at a chosen significance level, rather than compute a
	continuous p-value. `pcramer()` is still the source of truth for
	those critical values - each one below was solved for directly via
	`uniroot()` ON coda's own real `pcramer()` (i.e. "the q such that
	pcramer(q) = 1-pvalue"), not recalled from a table:
		pvalue=0.10 -> 0.3473049202 (pcramer check 0.9000000000)
		pvalue=0.05 -> 0.4613612936 (pcramer check 0.9500000000)
		pvalue=0.025 -> 0.5806146822 (pcramer check 0.9750000000)
		pvalue=0.01 -> 0.7434593138 (pcramer check 0.9900000000)
	This makes the resulting pass/fail decision EXACTLY equivalent to
	coda's own `pcramer(I) < 1-pvalue` test at each of these four
	standard levels (pcramer is a monotonic CDF, so comparing the
	statistic to its own inverse at the target level is identical to
	comparing the CDF value to the level directly) - `nwergm_estat.ado`'s
	own `pvalue()` option is restricted to these four values for exactly
	this reason, not an arbitrary continuous threshold.
*/
real scalar ergm_spec0_scalar(real colvector xcentered){
	real scalar n, pmax, gamma0

	n = rows(xcentered)
	pmax = floor(min((n-1, 10*log10(n))))
	if (pmax > 50) pmax = 50
	if (pmax < 1) pmax = 1
	gamma0 = variance(xcentered) * (n-1) / n
	return(ergm_ar_yw_infl(xcentered, pmax) * gamma0)
}

// Geweke (1992) z-score: compares the mean of the first `frac1' of the
// chain against the mean of the last `frac2' (coda's own defaults,
// 0.1/0.5, are the only ones exposed here - matching R ergm's own
// mcmc.diagnostics() call, which never varies them either), each mean's
// own sampling variance corrected for autocorrelation via
// ergm_spec0_scalar()/niter. z ~ N(0,1) under H0 (both segments share
// the same mean, i.e. the chain has converged); |z| large rejects it.
// Index arithmetic matches coda::geweke.diag's own ceiling/floor
// convention exactly (verified directly against real coda 0.19.4.1 -
// see cscripts/test_nwergm_mcmcdiag.do).
real rowvector ergm_geweke_z(real matrix samp){
	real scalar n, ncol, k, idx1end, idx2start, m1, m2, v1, v2
	real matrix seg1, seg2
	real rowvector out

	n = rows(samp)
	ncol = cols(samp)
	idx1end = ceil(1 + 0.1*(n-1))
	idx2start = floor(n - 0.5*(n-1))
	seg1 = samp[1::idx1end, .]
	seg2 = samp[idx2start::n, .]

	out = J(1, ncol, .)
	for (k=1; k<=ncol; k++) {
		m1 = mean(seg1[.,k])
		m2 = mean(seg2[.,k])
		v1 = ergm_spec0_scalar(seg1[.,k] :- m1) / rows(seg1)
		v2 = ergm_spec0_scalar(seg2[.,k] :- m2) / rows(seg2)
		out[k] = (m1 - m2) / sqrt(v1 + v2)
	}
	return(out)
}

// Heidelberger-Welch (1983) stationarity + halfwidth test, ported from
// coda::heidel.diag - see this section's own header comment for the
// pcramer()/critical-value substitution. `critval' is the caller-
// resolved Cramer-von-Mises critical value for the requested pvalue()
// (nwergm_estat.ado's own job, from the fixed 4-level table above);
// `eps' is coda's own halfwidth relative-tolerance parameter (default
// 0.1, exposed as-is). Returns one row per column of `samp':
//   col 1: stest      (1 = stationarity test passed, 0 = failed)
//   col 2: start      (1-based iteration the passing window began at;
//                       missing if stest failed)
//   col 3: teststat   (the retained window's own Cramer-von-Mises I -
//                       coda's own continuous p-value replaced by this
//                       raw statistic, per the header comment above)
//   col 4: htest      (1 = halfwidth test passed, 0 = failed, missing
//                       if stest itself failed - coda's own convention)
//   col 5: mean       (retained window's own mean)
//   col 6: halfwidth  (retained window's own 95% CI halfwidth)
real matrix ergm_heidel_diag(real matrix samp, real scalar critval, real scalar eps){
	real scalar n, ncol, j, i, nstart, s, nn, ybar, I, converged, S0, S0ci, halfwidth, passed_hw, half_start, step, cur
	real colvector col, Ytrim, B, Bsq, svec
	real matrix out

	n = rows(samp)
	ncol = cols(samp)
	out = J(ncol, 6, .)

	// coda's own start.vec = seq(from=1, to=n/2, by=n/10) - ten
	// candidate trim points, each an increasingly aggressive discard of
	// the chain's own early portion, tried in order until one passes.
	step = n/10
	svec = J(0,1,0)
	cur = 1
	while (cur <= n/2 + 1e-9) {
		svec = svec \ ceil(cur)
		cur = cur + step
	}

	for (j=1; j<=ncol; j++) {
		col = samp[.,j]
		half_start = ceil(n/2)
		S0 = ergm_spec0_scalar(col[half_start::n] :- mean(col[half_start::n]))

		converged = 0
		I = .
		nstart = .
		Ytrim = col
		for (i=1; i<=rows(svec); i++) {
			s = svec[i]
			if (s < 1) s = 1
			if (s > n) continue
			Ytrim = col[s::n]
			nn = rows(Ytrim)
			ybar = mean(Ytrim)
			B = runningsum(Ytrim) :- ybar*(1::nn)
			Bsq = (B:*B) :/ (nn * S0)
			I = sum(Bsq)/nn
			nstart = s
			if (I < . & I < critval) {
				converged = 1
				break
			}
		}

		S0ci = ergm_spec0_scalar(Ytrim :- mean(Ytrim))
		ybar = mean(Ytrim)
		halfwidth = 1.96 * sqrt(S0ci / rows(Ytrim))
		passed_hw = (halfwidth < .) & (abs(halfwidth/ybar) <= eps)

		out[j,1] = converged
		out[j,3] = I
		if (converged) {
			out[j,2] = nstart
			out[j,4] = passed_hw
			out[j,5] = ybar
			out[j,6] = halfwidth
		}
	}
	return(out)
}

struct ErgmMCMLEFit scalar ErgmMCMLE(class ErgmModel scalar M, class ErgmGraph scalar G,
	real rowvector theta0, real scalar maxit, real scalar burnin, real scalar interval0,
	real scalar samplesize, pointer(real rowvector function) scalar proposalfn,
	real scalar verbose, | real rowvector theta_c0){

	struct ErgmMCMLEFit scalar res
	struct ErgmMCMCDiag scalar diag
	real rowvector obs, theta, Dbar, delta, se, theta_c, delta_theta
	real matrix samp, D, V, Vinv, Vc, Vcinv, coefhist, coefhist_theta, Jac, JtVinvJ
	real scalar iter, p, mahal, gamma, converged, k, neff, min_neff, interval_cap, growth, interval
	real scalar T2, Fstat, Fcrit, confidence, is_curved, mahal_theta
	real rowvector rho, infl
	real rowvector eta_full_target, r0, r1, theta_try, theta_c_try
	real scalar obj0_bt, obj1_bt, bt

	// Mata passes a bare-variable argument by reference, so this
	// function's own adaptive-interval growth (below) reassigning its
	// own copy of the requested interval could otherwise mutate a
	// caller's variable if a future caller ever passes one in directly
	// (today's only caller, `nwergm.ado', always passes a literal
	// Stata-macro-substituted number, not a Mata variable, so this was
	// never a live production bug - found while writing this unit's own
	// certification test, `cscripts/test_nwergm_adaptive_interval.do',
	// which DID pass a bare variable and observed it change value after
	// the call). `interval0' is the untouched formal parameter; `interval'
	// is this function's own private, freely-mutable working copy.
	interval = interval0

	obs = M.full_statistic(G)
	theta = theta0
	p = cols(theta)
	coefhist = J(0, p, 0)
	coefhist_theta = J(0, M.ntheta(), 0)
	converged = 0

	// Curved MCMLE (harmonisation unit 138): `theta' throughout this
	// function is always ETA-space (the actual sufficient-statistic
	// weights used to sample/simulate) - genuinely correct and
	// unchanged for a curved model too, since MCMC sampling itself
	// never needs to know a term is curved. `is_curved' gates one
	// small addition inside the loop below: after each iteration's own
	// eta-space Newton step proposes a NEW eta target, snap it back
	// onto the achievable curved manifold via
	// ErgmModel::project_eta_to_theta() (unit 135) before using it for
	// the next MCMC sample - Hunter's own two-stage "Newton step in
	// eta-space, then project to theta" design
	// (docs/ERGM_STATNET_STUDY.md's own study already anticipated
	// this exact shape). `theta_c' is the running theta-space
	// iterate (unused, left empty, for an ordinary model); `theta_c0'
	// is the caller-supplied starting point (the curved MPLE fit's own
	// theta_hat, in nwergm.ado's actual usage) - if omitted for a
	// curved model, a generic fallback start is derived instead so
	// this optional argument never being supplied cannot itself cause
	// a crash, only a possibly-slower first projection.
	is_curved = (M.ntheta() < p)
	if (is_curved) {
		// an omitted optional argument arrives as a 0x0 empty matrix in
		// Mata (there is no separate "was this supplied" sentinel/
		// function to check instead) - `cols(theta_c0)==M.ntheta()'
		// is therefore both the "was it supplied" and "is it the right
		// shape" check in one.
		if (cols(theta_c0)==M.ntheta()) theta_c = theta_c0
		else theta_c = J(1, M.ntheta(), 0)
	}
	// matches Statnet's own default "confidence" termination method's
	// own reported confidence level (observed directly in real ergm()
	// console output: "Converged with 99% confidence").
	confidence = 0.99

	// ADAPTIVE INTERVAL (harmonisation unit 85, docs/CERTIFICATION.md) -
	// closes the open question unit 84 surfaced rather than resolved:
	// that unit's own effective-sample-size fix can correctly report
	// "converged" from a genuinely tiny neff (35.7 out of 3000 raw draws
	// measured on the 500-node sparse GWESP benchmark at the default
	// `mcmcinterval'), which is statistically VALID as a test but leaves
	// the resulting estimate's own PRECISION uncomfortably low - a
	// direct, real Statnet trace on the identical network
	// (`60_verbose_500sparse_r.R') showed Statnet's own interval is not
	// a fixed default either ("New interval = 512" then "New interval =
	// 1024", printed on its own non-converged iterations) - i.e. Statnet
	// itself grows its own MCMC thinning when the achieved effective size
	// is inadequate, rather than accepting a technically-passing but
	// low-precision test. `min_neff' mirrors Statnet's own documented
	// `MCMLE.effectiveSize=64'-per-parameter target (`control.ergm.R'),
	// floored at 200 so a 1-2 parameter model still gets a reasonably
	// precise fit rather than the bare minimum the raw formula would
	// otherwise allow. `interval' itself becomes a per-iteration LOCAL,
	// grown (never shrunk) whenever the achieved `neff' falls short -
	// every existing caller of `ErgmMCMCSample()'/`ErgmMCMCSampleDiag()'
	// below already takes `interval' as an ordinary parameter, so this
	// needs no change anywhere outside this loop, including the native
	// backend (unit 83), which simply receives whatever `interval' this
	// loop passes it each call.
	min_neff = max((200, 64*p))
	interval_cap = 20000

	for (iter=1; iter<=maxit; iter++) {
		samp = ErgmMCMCSample(M, G, theta, burnin, interval, samplesize, proposalfn)
		D = samp :- obs
		Dbar = mean(D)
		V = variance(D)
		Vinv = invsym(V)
		delta = -Dbar * Vinv

		if (is_curved) {
			// Damp the OUTER Newton step using the THETA-SPACE
			// Jacobian's own conditioning, not the raw eta-space V -
			// unit 138's own documented next step
			// (docs/CERTIFICATION.md), tried here for the first time.
			// The eta-space-only `mahal'/`gamma' rule below (the
			// `else' branch) is calibrated for the FULL unconstrained
			// eta space; once a curved term is present, only a much
			// lower-dimensional MANIFOLD of eta points is actually
			// achievable, and a step that looks modest by the raw
			// eta-space rule can require an implausibly large jump
			// once projected onto that manifold - unit 138's own
			// disclosed failure (decay drifting to 105+, 0% MCMC
			// acceptance) even after the projection step itself
			// separately gained its own backtracking safeguard.
			// Local linearization at the CURRENT `theta_c' (the
			// previous iteration's own theta-space point, or the
			// caller-supplied/fallback start on the first iteration):
			// `Jac' (nparam() x ntheta()) is the exact same analytic
			// Jacobian `project_eta_to_theta()' itself uses below,
			// mapping a small theta-space move to its own local
			// eta-space effect. Solving the weighted least-squares
			// "which theta-space step best explains the raw eta-space
			// Newton direction delta" - using the SAME `Vinv' metric
			// already in hand, the natural GLS weight - gives
			// `delta_theta'; its own size in the resulting
			// Gauss-Newton theta-space metric (`Jac'' Vinv Jac', the
			// same normal-equations matrix `project_eta_to_theta()'
			// itself inverts per curved block) is what actually
			// determines how large a jump the curved manifold would
			// be asked to make - capped by the SAME threshold (2) the
			// existing eta-space rule already uses, but applied to the
			// THETA-space step size, so an implausible jump is capped
			// BEFORE it ever reaches the projection, not after.
			// TRUST-REGION BACKTRACKING (harmonisation unit 162): the
			// Mahalanobis-2 cap below uses a LOCAL LINEARIZATION (Jac,
			// taken at the CURRENT theta_c) to bound the theta-space step
			// size - but the true theta->eta map (via the GW kernel) is
			// highly nonlinear in decay, and its own decay-derivative can
			// SATURATE (flatten toward 0) well before a "Mahalanobis-2"
			// linear step would suggest, so a step that looks modest
			// under the linear approximation can massively overshoot in
			// the true nonlinear space and land somewhere the estimating
			// equations can no longer see any local improvement at all -
			// permanently stuck from that point on, not oscillating or
			// slowly drifting. Directly measured on this project's own
			// curvedgwespnet certification network: decay jumped from its
			// MPLE start (4.15) to 66.7 in EXACTLY ONE outer iteration
			// under the unit-152 damping alone, then stayed bit-identical
			// at 66.7 for 19 further iterations - a genuinely different,
			// more specific mechanism than unit 152's own "gradual drift"
			// framing suggested, found by finally building the theta-space
			// trajectory logging that unit itself called for but never
			// implemented (this unit's own `coefhist_theta' addition).
			// Fix: verify the step actually improves the TRUE (not
			// linearized) weighted eta-space objective - measured via a
			// real, un-linearized round trip through
			// `project_eta_to_theta()'/`theta_to_eta()' - before accepting
			// it; halve gamma and retry if not, exactly the same
			// backtracking discipline `project_eta_to_theta()''s own inner
			// loop and `ErgmCurvedMPLEFit()' already both use elsewhere in
			// this same file, just applied one level up, to the outer
			// step itself.
			Jac = M.theta_to_eta_jacobian(theta_c)
			JtVinvJ = Jac' * Vinv * Jac
			delta_theta = (invsym(JtVinvJ) * Jac' * Vinv * delta')'
			mahal_theta = sqrt(delta_theta * JtVinvJ * delta_theta')
			gamma = (mahal_theta > 2 ? 2/mahal_theta : 1)

			eta_full_target = theta + delta	// the UNDAMPED eta-space Newton target - what the step is trying to approach, regardless of how much of it gets taken
			r0 = eta_full_target - M.theta_to_eta(theta_c)
			obj0_bt = r0 * Vinv * r0'
			for (bt=1; bt<=20; bt++) {
				theta_try = theta + gamma*delta
				theta_c_try = M.project_eta_to_theta(theta_try, Vinv, theta_c, 100, 1e-10)
				r1 = eta_full_target - M.theta_to_eta(theta_c_try)
				obj1_bt = r1 * Vinv * r1'
				if (obj1_bt <= obj0_bt) break
				gamma = gamma / 2
			}
		}
		else {
			mahal = sqrt(delta * V * delta')
			gamma = (mahal > 2 ? 2/mahal : 1)
		}

		theta = theta + gamma*delta
		if (is_curved) {
			// snap the (now backtracked-safe) eta-space Newton target
			// back onto the achievable curved manifold - `Vinv' (this
			// iteration's own eta-space information, already computed
			// above for the Newton step itself) is the natural GLS
			// weight, exactly the same role it plays in
			// ErgmCurvedMPLEFit()'s own analogous step. `theta_c'
			// warm-starts from its own PREVIOUS iteration's value, not a
			// generic restart, matching how theta itself is never
			// restarted iteration to iteration either.
			theta_c = M.project_eta_to_theta(theta, Vinv, theta_c, 100, 1e-10)
			theta = M.theta_to_eta(theta_c)
			coefhist_theta = coefhist_theta \ theta_c
		}
		coefhist = coefhist \ theta

		se = sqrt(diagonal(V)/samplesize)'
		// Joint Hotelling's T^2 test that the centered mean Dbar is
		// statistically indistinguishable from the zero vector, given
		// its own sampling covariance - replacing an earlier per-
		// coordinate rule ("every |Dbar_k| < 0.5*se_k simultaneously")
		// that was needlessly conservative: requiring EVERY marginal
		// coordinate to individually clear its own threshold compounds
		// probabilities across parameters (for a 2-parameter model,
		// roughly 0.38^2 =~ 15% chance of jointly clearing even a
		// per-coordinate-generous bar in any given iteration EVEN AFTER
		// theta has already converged, since Dbar is never exactly zero
		// under Monte Carlo noise alone) - a genuinely single largest
		// cause of this estimator needing far more MCMLE iterations than
		// Statnet's own joint "confidence" test on the same data
		// (confirmed empirically: 10-20 iterations here vs. Statnet's
		// own 1, on the same network/model - see docs/CERTIFICATION.md's
		// harmonisation-unit-80 entry).
		//
		// EFFECTIVE-SAMPLE-SIZE CORRECTION (harmonisation unit 84,
		// docs/CERTIFICATION.md): the T^2 -> F transformation above is
		// exact only for i.i.d. draws - `samp' is a THINNED MCMC chain
		// (thinned by `interval', not fully decorrelated), and treating
		// it as i.i.d. of size `samplesize' badly UNDERSTATES the true
		// sampling variance of Dbar whenever draws remain meaningfully
		// autocorrelated. This was root-caused directly, not assumed:
		// running nwergm's own MCMLE in verbose mode on the 500-node
		// sparse GWESP benchmark showed theta stabilizing near its final
		// value from iteration 1 onward (matching Statnet's own converged
		// estimate closely) while Fstat stayed absurdly inflated
		// (20-640, against a FIXED Fcrit=3.79 computed from the raw
		// samplesize=3000) for the full 20-iteration cap - a real
		// Statnet trace on the IDENTICAL network (verbose=TRUE,
		// `dev/ergm_benchmark_r_vs_stata/60_verbose_500sparse_r.R')
		// showed Statnet's own reported convergence-test degrees of
		// freedom are non-integer and far smaller than its own raw
		// recorded sample size (84.9, 129.4, 203.6 across its first three
		// iterations, converging on the fourth) - i.e. Statnet's own
		// "confidence" test already uses an autocorrelation-discounted
		// EFFECTIVE sample size, not the raw draw count, exactly the
		// piece missing here. Fixed by reusing the SAME lag-1
		// autocorrelation machinery the final variance step already
		// applies (`ergm_lag1_autocorr()'/the `(1+rho)/(1-rho)' inflation
		// factor) one step earlier - inside this per-iteration test, not
		// only in the one-off final reporting pass - inflating V's own
		// diagonal per parameter and correspondingly shrinking the
		// effective sample size `neff' used for T2/Fstat/Fcrit. The
		// NEWTON STEP ITSELF (`delta'/`mahal'/`gamma'/the theta update
		// above) deliberately still uses the UNINFLATED `V'/`Vinv' -
		// theta was never the problem (it already tracks Statnet's own
		// converged value from iteration 1), so this fix touches only the
		// STATISTICAL TEST deciding when to stop, not the optimizer.
		//
		// Uses ergm_spectral0_ar() (unit 86) rather than the plain
		// ergm_lag1_autocorr()-based (1+rho)/(1-rho) factor here -  a
		// strict generalization (identical on true AR(1) data, more
		// accurate whenever the chain's autocorrelation structure is
		// richer than a single lag captures) validated directly against
		// a real Statnet reference value, not merely assumed superior.
		infl = ergm_spectral0_ar(D)
		Vc = V
		for (k=1; k<=p; k++) Vc[k,k] = V[k,k] * infl[k]
		Vcinv = invsym(Vc)
		neff = samplesize / mean(infl')
		// guard against a pathologically small effective sample size
		// (near-unit-root autocorrelation) making the F distribution's
		// own degrees of freedom invalid or the test meaningless.
		if (neff < p + 2) neff = p + 2
		T2 = neff * (Dbar * Vcinv * Dbar')
		Fstat = T2 * (neff - p) / (p * (neff - 1))
		Fcrit = invF(p, neff - p, confidence)
		if (verbose) {
			printf("MCMLE iter %g: steplen=%5.3f theta=", iter, gamma)
			for (k=1; k<=p; k++) printf("%9.5f ", theta[k])
			printf(" F=%7.3f (crit %7.3f at %g%% conf, neff=%7.1f/%g) max|Dbar/se|=%6.3f interval=%g\n", Fstat, Fcrit, confidence*100, neff, min_neff, max(abs(Dbar :/ se)), interval)
		}
		if (Fstat <= Fcrit & gamma==1 & neff >= min_neff) {
			converged = 1
			break
		}
		// Not (yet) converged: if the achieved effective sample size is
		// below the target floor, grow `interval' for the NEXT iteration
		// so the next MCMC sample is less autocorrelated - capped both
		// per-step (at most 8x in one jump, avoiding a single noisy
		// autocorrelation estimate causing a wildly oversized next
		// iteration) and in absolute terms (`interval_cap'). Left
		// unchanged (no adaptation) whenever `neff' already clears the
		// floor - the ordinary case for the small/well-mixing benchmarks
		// (1-3), which never pay for this mechanism at all.
		if (neff < min_neff) {
			growth = min((8, ceil(min_neff/neff)))
			interval = min((interval * growth, interval_cap))
		}
	}

	// Final variance-covariance from a fresh simulation at the
	// converged (or last-tried) theta - via ErgmMCMCSampleDiag() rather
	// than ErgmMCMCSample() purely so this one pass also yields an
	// acceptance rate; the accept/reject draw sequence itself is
	// identical (see ErgmMCMCSampleDiag()'s own header comment), so this
	// substitution changes nothing about the numeric result.
	diag = ErgmMCMCSampleDiag(M, G, theta, burnin, interval, samplesize, proposalfn)
	samp = diag.sample
	V = variance(samp)
	// ergm_batchmeans_inflation() (a more general, non-AR(1)-assuming
	// alternative to a plain lag-1 correction) was tried here and
	// REJECTED based on direct empirical comparison (unit 80): run 8
	// times at the exact Statnet-reference theta for this suite's own
	// canonical directed edges+mutual network, a plain lag-1
	// (1+rho)/(1-rho) correction landed tightly clustered around
	// Statnet's own real vcov diagonal (edges 0.39-0.50 vs Statnet's
	// 0.4447; mutual 1.89-2.28 vs Statnet's 2.1716) while batch-means was
	// both far noisier AND often badly biased across the SAME 8 seeds
	// (edges 0.34-5.06) - with only floor(sqrt(3000))=54 batches at
	// nwergm's own default samplesize, batch-means' own statistical
	// efficiency is too low at this scale.
	//
	// SUPERSEDED (harmonisation unit 86): the plain lag-1 correction
	// itself was then replaced by ergm_spectral0_ar() - a strict AR(p)
	// generalization (identical to lag-1 exactly when AIC selects order
	// 1) validated against the SAME known Statnet reference this unit's
	// own comment above cites: lag-1 landed at edges=0.3677/mutual=1.7475
	// (17-20% low); the AR(p) estimator lands at edges=0.4066/
	// mutual=2.1778 (9% low / 0.3% off - essentially exact on the harder
	// term) - a measurable improvement on the one case with an exact
	// external ground truth, not merely a theoretical upgrade. See
	// docs/CERTIFICATION.md unit 86 for the full account, including why
	// this is a per-dimension approximation to Statnet's own genuinely
	// multivariate spectrum0.mvar() rather than a full VAR fit (a
	// disclosed, deliberate simplification, not an oversight).
	infl = ergm_spectral0_ar(samp :- mean(samp))
	for (k=1; k<=p; k++) V[k,k] = V[k,k] * infl[k]

	res.coef = theta
	res.vcov = invsym(V)
	res.converged = converged
	res.niter = iter <= maxit ? iter : maxit
	res.coefhist = coefhist
	res.finalsample = samp
	res.acceptrate = diag.acceptrate
	res.final_interval = interval
	// `theta_c' already reflects the SAME final eta-space `theta'
	// reported above (both were updated together, in lockstep, at the
	// end of every loop iteration - the post-loop diagnostics
	// simulation re-samples at `theta' but never re-runs the
	// projection, so no separate re-derivation is needed here for
	// consistency). Left at its own declared-but-unset (empty) state
	// for an ordinary model, matching this struct's own documented
	// "empty for ordinary, populated for curved" contract.
	if (is_curved) res.coef_theta = theta_c
	res.coefhist_theta = coefhist_theta
	return(res)
}

end
