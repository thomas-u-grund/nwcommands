/***
{smcl}
{* *! version 2.0.0  22aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis:[NW-2.6] Analysis}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwergm {hline 2} Exponential-family random graph model (ERGM) estimation{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwergm}
[{it:{help netname}}]
{cmd:,}
{opt edges} [{opt mutual}]
[{opth nodematch(varlist)}]
[{opth nodematchdiff(varlist)}]
[{opth nodecov(varlist)}]
[{opth nodeicov(varlist)}]
[{opth nodeocov(varlist)}]
[{opth edgecov(netname)}]
[{opth absdist(varlist)}]
[{opth nodefactor(varlist)}]
[{opth nodemix(varlist)}]
[{opt gwesp(real)}]
[{opt gwdsp(real)}]
[{opt gwnsp(real)}]
[{opt gwdegree(real)}]
[{opt gwodegree(real)}]
[{opt gwidegree(real)}]
[{opt degree(numlist)}]
[{opt odegree(numlist)}]
[{opt idegree(numlist)}]
[{opt concurrent}]
[{opt triangle}]
[{opt ctriple}]
[{opt method(mple|mcmle)}
{opt mcmcburnin(int)}
{opt mcmcinterval(int)}
{opt mcmcsamplesize(int)}
{opt mcmleiterations(int)}
{opt proposal(uniform|tnt)}
{opt seed(int)}
{opt verbose}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt edges}}Include the {cmd:edges} term (density/intercept); required{p_end}
{synopt:{opt mutual}}Reciprocated-tie count; directed networks only{p_end}
{synopt:{opth nodematch(varlist)}}Pooled homophily on each listed categorical node attribute (exact match, one coefficient per variable){p_end}
{synopt:{opth nodematchdiff(varlist)}}Differential homophily: one coefficient PER DISTINCT LEVEL of each listed attribute, rather than pooled across levels{p_end}
{synopt:{opth nodecov(varlist)}}Continuous node covariate main effect (sum over tie endpoints){p_end}
{synopt:{opth nodeicov(varlist)}}Directed receiver-covariate effect; directed networks only{p_end}
{synopt:{opth nodeocov(varlist)}}Directed sender-covariate effect; directed networks only{p_end}
{synopt:{opth edgecov(netname)}}Dyadic covariate effect, taken from an already-loaded network's own tie values{p_end}
{synopt:{opth absdist(varlist)}}Absolute-difference effect on a continuous node covariate: sum over ties of |x_i - x_j|{p_end}
{synopt:{opth nodefactor(varlist)}}One coefficient per NON-BASE distinct level of each listed categorical attribute (the lowest-sorted level is omitted, matching R ergm's own default, to avoid exact collinearity with edges), each counting total degree among nodes at that level{p_end}
{synopt:{opth nodemix(varlist)}}Full categorical mixing matrix: one coefficient per distinct unordered pair of levels of each listed attribute{p_end}
{synopt:{opt gwesp(real)}}Geometrically weighted edgewise shared partners, fixed decay; undirected only{p_end}
{synopt:{opt gwdsp(real)}}Geometrically weighted dyadwise shared partners, fixed decay; undirected only{p_end}
{synopt:{opt gwdegree(real)}}Geometrically weighted degree, fixed decay{p_end}
{synopt:{opt gwodegree(real)}}Geometrically weighted out-degree, fixed decay; directed networks only{p_end}
{synopt:{opt gwidegree(real)}}Geometrically weighted in-degree, fixed decay; directed networks only{p_end}
{synopt:{opt gwnsp(real)}}Geometrically weighted NONedgewise (untied-dyad) shared partners, fixed decay; undirected only. Satisfies gwdsp = gwesp + gwnsp{p_end}
{synopt:{opt degree(numlist)}}One coefficient per listed degree value: count of nodes with that exact (total) degree; undirected only{p_end}
{synopt:{opt odegree(numlist)}}One coefficient per listed value: count of nodes with that exact out-degree; directed networks only{p_end}
{synopt:{opt idegree(numlist)}}One coefficient per listed value: count of nodes with that exact in-degree; directed networks only{p_end}
{synopt:{opt concurrent}}Count of nodes with (total) degree 2 or higher; undirected only{p_end}
{synopt:{opt triangle}}Count of triangles (mutually tied triples); undirected only{p_end}
{synopt:{opt ctriple}}Count of cyclic triples ((i->j),(j->k),(k->i)); directed networks only{p_end}
{synopt:{opt method(mple|mcmle)}}Estimation method; default {it:mcmle} unless the model is dyad-independent, in which case MPLE already is the MLE{p_end}
{synopt:{opt mcmcburnin(int)}}MCMC burn-in steps per simulation; default 3,000{p_end}
{synopt:{opt mcmcinterval(int)}}MCMC steps between recorded draws; default 50{p_end}
{synopt:{opt mcmcsamplesize(int)}}Number of recorded MCMC draws per simulation; default 3,000{p_end}
{synopt:{opt mcmleiterations(int)}}Maximum MCMLE outer iterations; default 20{p_end}
{synopt:{opt proposal(uniform|tnt)}}Metropolis-Hastings proposal; default {it:tnt}{p_end}
{synopt:{opt seed(int)}}Set the random-number seed before simulating (for reproducibility){p_end}
{synopt:{opt verbose}}Show MPLE/MCMLE iteration detail{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwergm} fits an exponential-family random graph model (ERGM) to the network(s) in
{help netname} (default: the currently set network) using a fully native Stata/Mata
implementation - no R or other external statistical software is called at any point, at
estimation time or otherwise. Statnet's mature {cmd:ergm} R package was studied in detail as a
behavioural and architectural reference during development (see {browse "https://cran.r-project.org/package=ergm":statnet.org})
and used, during development only, to certify {cmd:nwergm}'s own independently-written
implementation against real reference output; see {help nwergm##provenance:Provenance} below.

{pstd}
This is a deliberately small first release: a working extensible core (term registry,
Metropolis-Hastings simulation with a genuine tie/no-tie proposal, maximum pseudolikelihood
estimation, and Monte Carlo maximum likelihood estimation) with a small, carefully certified
effect library, rather than an attempt at parity with Statnet's own much larger term/control
surface. See {help nwergm##limitations:Limitations} below for exactly what is and is not
supported, and the package's own {browse "docs/ERGM_ROADMAP.md"} for the prioritised extension
plan.

{pstd}
{opt method()} selects the estimation method. If every requested term is dyad-independent
(currently: {opt edges}, {opt nodematch()}, {opt nodecov()}, {opt nodeicov()},
{opt nodeocov()}, {opt edgecov()}) and neither {opt mutual} nor any geometrically weighted term
is present, maximum pseudolikelihood {it:is} the maximum likelihood estimate - {cmd:nwergm}
detects this automatically and reports {opt method(mple)} results directly (labeled as such,
not as full ERGM MLE) without ever running MCMC. Otherwise the default is
{opt method(mcmle)}: pseudolikelihood is used only as the starting value for Monte Carlo maximum
likelihood.

{marker limitations}{...}
{title:Limitations (v1 scope)}

{pstd}
{cmd:nwergm} estimates {bf:binary, static, one-mode} ERGMs only:

{p2colset 9 13 15 2}{...}
{p2col: o}Two-mode (bipartite) networks are rejected with an explicit error - never silently
projected to one mode.{p_end}
{p2col: o}Temporal networks (snapshot/interval/event metadata) are rejected with an explicit
error - never silently collapsed to a single static slice.{p_end}
{p2col: o}Valued/weighted or signed networks are rejected with an explicit error - never
silently dichotomized or stripped of sign. Valued ERGMs are a materially different statistical
framework (Krivitsky 2012) and are tracked as a separate future initiative, not a small
extension.{p_end}
{p2colreset}{...}

{pstd}
The effect library covers {opt edges}, {opt mutual}, {opt nodematch()}, {opt nodecov()},
{opt nodeicov()}/{opt nodeocov()}, {opt edgecov()}, and the geometrically weighted
{opt gwesp()}/{opt gwdegree()}/{opt gwodegree()}/{opt gwidegree()} family with FIXED decay only
(curved/free-decay estimation is a roadmap item). Constraints beyond the free binary dyad space
and offsets are not yet implemented - see the roadmap. Basic MCMC diagnostics
({help nwergm_estat:estat mcmcdiag}) and basic goodness of fit ({help nwergm_estat:estat gof})
are both available; see {help nwergm_estat}.

{title:Postestimation}

{pstd}
{help nwergm_estat:estat mcmcdiag} reports basic diagnostics for the final MCMC simulation
(mean/SD/autocorrelation/effective sample size per statistic, plus the overall acceptance rate)
after {opt method(mcmle)}. Not available after a pure MPLE fit, which involves no MCMC
simulation.

{pstd}
{help nwergm_estat:estat gof} reports a basic simulation-based goodness-of-fit comparison
(mean degree, average geodesic distance, complete-triad count) between the fitted model's own
simulated networks and the network {cmd:nwergm} was fitted on - available after either
estimation method. See {help nwergm_estat} for full details.

{title:Stored results}

	Scalars
	  {bf:e(N)}			number of dyads
	  {bf:e(nodes)}			number of nodes
	  {bf:e(ties)}			number of observed ties
	  {bf:e(converged)}		1 if MCMLE's own convergence test was satisfied (method(mcmle) only)
	  {bf:e(mcmle_iterations)}	number of MCMLE outer iterations run (method(mcmle) only)
	  {bf:e(mcmc_acceptrate)}	Metropolis-Hastings acceptance rate, final simulation (method(mcmle) only)
	  {bf:e(mcmc_burnin)}		MCMC burn-in steps used (method(mcmle) only)
	  {bf:e(mcmc_interval)}		MCMC thinning interval requested (method(mcmle) only)
	  {bf:e(mcmc_interval_final)}	MCMC thinning interval actually used for the last iteration - may
					exceed e(mcmc_interval) if the adaptive-interval mechanism grew it
					to reach an adequate effective sample size (method(mcmle) only)
	  {bf:e(mcmc_samplesize)}	MCMC recorded-draw count used (method(mcmle) only)

	Macros
	  {bf:e(cmd)}			{bf:nwergm}
	  {bf:e(title)}			title of estimation
	  {bf:e(depvar)}		name of the estimated network
	  {bf:e(method)}		{bf:mple} or {bf:mcmle}
	  {bf:e(directed)}		{bf:true}/{bf:false}
	  {bf:e(proposal)}		Metropolis-Hastings proposal used (method(mcmle) only)
	  {bf:e(estat_cmd)}		{bf:nwergm_estat} (postestimation dispatch)

	Matrices
	  {bf:e(b)}			coefficient vector
	  {bf:e(V)}			variance-covariance matrix
	  {bf:e(mcmcsample)}		final simulation's sufficient-statistic draws, samplesize x nparam (method(mcmle) only)

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwergm flomarriage, edges}
	{cmd:. nwergm flomarriage, edges nodecov(wealth)}
	{cmd:. nwergm flomarriage, edges gwesp(.5)}

{marker provenance}{...}
{title:References}

{pstd}
Hunter, D.R., Handcock, M.S., Butts, C.T., Goodreau, S.M., Morris, M. (2008). ergm: A Package to
Fit, Simulate and Diagnose Exponential-Family Models for Networks. {it:Journal of Statistical
Software}, 24(3), 1-29.

{pstd}
Hunter, D.R., Handcock, M.S. (2006). Inference in curved exponential family models for networks.
{it:Journal of Computational and Graphical Statistics}, 15(3), 565-583. (MPLE)

{pstd}
Hunter, D.R. (2007). Curved exponential family models for social networks. {it:Social Networks},
29(2), 216-230. (GWESP/GWDEGREE)

{pstd}
Morris, M., Handcock, M.S., Hunter, D.R. (2008). Specification of Exponential-Family Random
Graph Models: Terms and Computational Aspects. {it:Journal of Statistical Software}, 24(4),
1-24. (TNT proposal)

{pstd}
Hummel, R.M., Hunter, D.R., Handcock, M.S. (2012). Improving Simulation-Based Algorithms for
Fitting ERGMs. {it:Journal of Computational and Graphical Statistics}, 21(4), 920-939. (MCMLE
step length)

{pstd}
Geyer, C.J., Thompson, E.A. (1992). Constrained Monte Carlo Maximum Likelihood for Dependent
Data. {it:Journal of the Royal Statistical Society, Series B}, 54(3), 657-699. (MCMLE)

{pstd}
{cmd:nwergm} is an independent, native reimplementation and is not affiliated with or endorsed
by the Statnet project. See {browse "docs/ERGM_PROVENANCE.md"} for the full licensing and
provenance account, and {browse "docs/ERGM_STATNET_STUDY.md"} for the architecture study this
implementation is based on.

{title:Simulation}

{p 8 17 2}
{cmdab: nwergm} {cmd:simulate}
{it:nodes}
{cmd:,}
{opt edges} [{opt mutual}]
[{opt gwesp(real)}]
[{opt gwdegree(real)}]
[{opt gwodegree(real)}]
[{opt gwidegree(real)}]
{opt theta(numlist)}
[{opt directed}
{opt nsim(int)}
{opt mcmcburnin(int)}
{opt mcmcinterval(int)}
{opt proposal(uniform|tnt)}
{opt seed(int)}
{opt generate(string)}]

{pstd}
{cmd:nwergm simulate} draws one or more networks from a fully-specified ERGM (fixed
coefficients, not estimated) via the same native Metropolis-Hastings sampler {cmd:nwergm}
itself uses for estimation - matching the {browse "https://cran.r-project.org/package=ergm":Statnet
ergm} package's own {cmd:simulate.ergm}. {it:nodes} is the number of nodes to simulate on (no
existing network is required or read); the term options are the SAME ones {cmd:nwergm} itself
takes, but v1's simulate interface deliberately only supports the terms that need no external
covariate data ({opt edges}, {opt mutual}, and the geometrically weighted family) - nodematch()/
nodecov()/nodeicov()/nodeocov()/edgecov() are not yet supported for simulation (see
{browse "docs/ERGM_ROADMAP.md"}). {opt theta()} supplies one coefficient per requested term, IN
THE SAME ORDER the term options are listed on the command line (edges first, then mutual if
present, then any gw* terms in the order written) - there is no per-term coefficient
sub-option, by design, so this exactly reuses the same term-construction code {cmd:nwergm}'s own
estimation path uses rather than a parallel implementation.

{pstd}
{opt nsim(int)} (default 1) draws that many independent networks (a fresh burn-in for each,
matching {cmd:nwergm}'s own control conventions rather than continuing one long chain), named
{opt generate()}{cmd:_1}, {opt generate()}{cmd:_2}, ... when {opt nsim()}{cmd: > 1} (default stub
{cmd:ergmsim}), or plain {opt generate()} (default {cmd:ergmsim}) when {opt nsim(1)}.

{title:See also}

	{help nwqap}, {help nwrandom}, {help nwcug}

***/

capture program drop nwergm
program nwergm, eclass
	version 14
	if `"`1'"' == "simulate" {
		gettoken __ergm_sub 0 : 0
		nwergm_simulate `0'
		exit
	}
	syntax [anything(name=netname)] [, edges mutual ///
		NODEMATCH(string) NODEMATCHDIFF(string) NODECOV(string) NODEICOV(string) NODEOCOV(string) ///
		EDGECOV(string) ABSDIST(string) NODEFACTOR(string) NODEMIX(string) ///
		GWESP(string) GWDSP(string) GWNSP(string) GWDEGREE(string) GWODEGREE(string) GWIDEGREE(string) ///
		DEGREE(string) ODEGREE(string) IDEGREE(string) CONCURRENT TRIANGLE CTRIPLE ///
		METHOD(string) MCMCBURNIN(integer 3000) MCMCINTERVAL(integer 50) ///
		MCMCSAMPLESIZE(integer 3000) MCMLEITERATIONS(integer 20) ///
		PROPOSAL(string) SEED(integer -1) VERBOSE ]
	set more off

	if "`edges'" == "" {
		di "{err}option {bf:edges} is required - every v1 nwergm model includes an edges term."
		error 198
	}
	if "`proposal'" == "" local proposal "tnt"
	_opts_oneof "uniform tnt" "proposal" "`proposal'" 198
	if "`method'" != "" {
		_opts_oneof "mple mcmle" "method" "`method'" 198
	}

	nw_syntax `netname', max(1)

	// --- network-type validation (Part IV/XXII/XXIII/XXIV): reject,
	// never silently reinterpret.
	if "`is2mode'" == "true" {
		di "{err}nwergm does not yet support two-mode (bipartite) networks; {bf:`netname'} is two-mode."
		di "{err}Native bipartite ERGM terms are a roadmap item - nwergm never silently projects a two-mode network to one mode."
		error 198
	}
	if "`istemporal'" == "true" {
		di "{err}nwergm estimates static ERGMs only; {bf:`netname'} carries temporal metadata."
		di "{err}nwergm never silently collapses a temporal network to a single slice - build an explicit static network first (e.g. via nwattime) and estimate on that."
		error 198
	}
	if "`valued'" == "true" {
		di "{err}nwergm estimates binary ERGMs only; {bf:`netname'} is valued/weighted."
		di "{err}nwergm never silently dichotomizes tie values or drops signs. Valued ERGMs are a separate, larger future initiative (see docs/ERGM_ROADMAP.md)."
		error 198
	}
	if "`mutual'" != "" & "`directed'" != "true" {
		di "{err}option {bf:mutual} requires a directed network; {bf:`netname'} is undirected."
		error 198
	}
	if ("`nodeicov'" != "" | "`nodeocov'" != "") & "`directed'" != "true" {
		di "{err}options {bf:nodeicov()}/{bf:nodeocov()} require a directed network; {bf:`netname'} is undirected."
		error 198
	}
	if "`gwesp'" != "" & "`directed'" == "true" {
		di "{err}option {bf:gwesp()} (v1 scope) is undirected only; {bf:`netname'} is directed. See docs/ERGM_ROADMAP.md for the directed OTP/ITP/OSP/ISP variants."
		error 198
	}
	if "`gwdsp'" != "" & "`directed'" == "true" {
		di "{err}option {bf:gwdsp()} (v1 scope) is undirected only; {bf:`netname'} is directed."
		error 198
	}
	if ("`gwodegree'" != "" | "`gwidegree'" != "") & "`directed'" != "true" {
		di "{err}options {bf:gwodegree()}/{bf:gwidegree()} require a directed network; {bf:`netname'} is undirected. Use {bf:gwdegree()} for an undirected network."
		error 198
	}
	if "`gwnsp'" != "" & "`directed'" == "true" {
		di "{err}option {bf:gwnsp()} (v1 scope) is undirected only; {bf:`netname'} is directed."
		error 198
	}
	if "`degree'" != "" & "`directed'" == "true" {
		di "{err}option {bf:degree()} is undirected only; {bf:`netname'} is directed. Use {bf:odegree()}/{bf:idegree()} for a directed network."
		error 198
	}
	if ("`odegree'" != "" | "`idegree'" != "") & "`directed'" != "true" {
		di "{err}options {bf:odegree()}/{bf:idegree()} require a directed network; {bf:`netname'} is undirected. Use {bf:degree()} for an undirected network."
		error 198
	}
	if "`concurrent'" != "" & "`directed'" == "true" {
		di "{err}option {bf:concurrent} (v1 scope) is undirected only; {bf:`netname'} is directed."
		error 198
	}
	if "`triangle'" != "" & "`directed'" == "true" {
		di "{err}option {bf:triangle} is undirected only; {bf:`netname'} is directed. Use {bf:ctriple} for a directed network."
		error 198
	}
	if "`ctriple'" != "" & "`directed'" != "true" {
		di "{err}option {bf:ctriple} requires a directed network; {bf:`netname'} is undirected. Use {bf:triangle} for an undirected network."
		error 198
	}

	if `seed' != -1 {
		set seed `seed'
	}

	// --- build the ErgmGraph from the current NWdef network (one-time
	// read via the already-established sparse accessors; ErgmGraph
	// itself never touches NWdef again after this point - it is, by
	// design, fully decoupled from NWdef; see unw_ergm.do's own header
	// comment). The bridge itself (ergm_bridge_from_netobj(), defined
	// once at file scope below) lives here, in the .ado integration
	// layer, not in either decoupled Mata subsystem.
	// every Mata-side tempname created below is appended to this list
	// (in expanded, literal-name form) so it can be dropped in one shot
	// at the end of the program - a one-line interactive `mata: X = ...'
	// call creates a permanent, top-level Mata variable that is NEVER
	// garbage-collected on its own (unlike a proper Mata function's own
	// locals), so without this bookkeeping every nwergm call leaks one
	// object per term instance into the ambient Mata workspace. Left
	// unfixed, this eventually collides with Mata objects Stata's own
	// machinery creates internally (e.g. `estimates table'/`esttab'),
	// surfacing as a baffling "Mata object __NNNNNN already exists".
	local __ergm_matatemps ""

	// __nwergm_last_G/__nwergm_last_M are DELIBERATE fixed-name Mata
	// singletons, not tempnames - `estat gof' (nwergm_estat.ado) needs to
	// find this call's own fitted graph/model again later, in a SEPARATE
	// program invocation with no access to this program's own locals.
	// Each new nwergm call replaces (never accumulates) the previous
	// call's singleton, guarded exactly like ergm_bridge_from_netobj()'s
	// own redefinition guard below - this is a single, well-managed
	// object, not the unmanaged per-call accumulation unit 73 fixed.
	capture mata: mata drop __nwergm_last_G
	mata: __nwergm_last_G = ErgmGraph()
	mata: __nwergm_last_G.init(`nodes', ("`directed'"=="true"))
	mata: ergm_bridge_from_netobj(`netobj', __nwergm_last_G, ("`directed'"=="true"))
	// captured HERE, before any MCMC ever runs: __nwergm_last_G's own
	// .nties mutates throughout MCMLE's own simulation (it IS the live
	// MCMC state, not a frozen copy of the observed network - see its
	// own class header comment), so reading e(ties) from it AFTER
	// ErgmMCMLE() returns would report the last SIMULATED tie count, not
	// the true observed one. A genuine bug of exactly this shape existed
	// in this file from unit 72 through unit 75 (`e(ties)` was read from
	// `__nwergm_last_G.nties` after fitting, in the method(mcmle) branch
	// below), caught only once `estat gof` (Part XX) needed a genuinely
	// correct observed density and its own reported "Observed" column
	// didn't match the true network by hand-inspection.
	mata: st_local("__ergm_obsties", strofreal(__nwergm_last_G.nties))

	// --- build the model: one addterm() call per requested term.
	capture mata: mata drop __nwergm_last_M
	mata: __nwergm_last_M = ErgmModel()
	mata: __nwergm_last_M.init()

	tempname __td_edges
	mata: `__td_edges' = ErgmTermData()
	mata: __nwergm_last_M.addterm("edges", 1, &stat_edges(), &change_edges(), `__td_edges', ("edges"))
	local __ergm_matatemps "`__ergm_matatemps' `__td_edges'"

	if "`mutual'" != "" {
		tempname __td_mutual
		mata: `__td_mutual' = ErgmTermData()
		mata: __nwergm_last_M.addterm("mutual", 1, &stat_mutual(), &change_mutual(), `__td_mutual', ("mutual"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_mutual'"
	}

	local __ergm_termidx = 0
	foreach __ergm_v of local nodematch {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_nm`__ergm_termidx'
		mata: `__td_nm`__ergm_termidx'' = ErgmTermData()
		mata: `__td_nm`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: __nwergm_last_M.addterm("nodematch", 1, &stat_nodematch(), &change_nodematch(), `__td_nm`__ergm_termidx'', ("nodematch_`__ergm_v'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_nm`__ergm_termidx''"
	}

	local __ergm_termidx = 0
	foreach __ergm_v of local nodecov {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_nc`__ergm_termidx'
		mata: `__td_nc`__ergm_termidx'' = ErgmTermData()
		mata: `__td_nc`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: __nwergm_last_M.addterm("nodecov", 1, &stat_nodecov(), &change_nodecov(), `__td_nc`__ergm_termidx'', ("nodecov_`__ergm_v'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_nc`__ergm_termidx''"
	}

	local __ergm_termidx = 0
	foreach __ergm_v of local nodeicov {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_ni`__ergm_termidx'
		mata: `__td_ni`__ergm_termidx'' = ErgmTermData()
		mata: `__td_ni`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: __nwergm_last_M.addterm("nodeicov", 1, &stat_nodeicov(), &change_nodeicov(), `__td_ni`__ergm_termidx'', ("nodeicov_`__ergm_v'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_ni`__ergm_termidx''"
	}

	local __ergm_termidx = 0
	foreach __ergm_v of local nodeocov {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_no`__ergm_termidx'
		mata: `__td_no`__ergm_termidx'' = ErgmTermData()
		mata: `__td_no`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: __nwergm_last_M.addterm("nodeocov", 1, &stat_nodeocov(), &change_nodeocov(), `__td_no`__ergm_termidx'', ("nodeocov_`__ergm_v'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_no`__ergm_termidx''"
	}

	// --- term-expansion wave 1 (harmonisation unit 88): absdist,
	// nodematch(diff=TRUE) (a separate nodematchdiff() option, per this
	// file's own header comment on why a suboption on nodematch() itself
	// was not used), nodefactor, nodemix - see unw_ergm.do's own header
	// comment on these four terms for the full statistical definitions.
	local __ergm_termidx = 0
	foreach __ergm_v of local absdist {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_ad`__ergm_termidx'
		mata: `__td_ad`__ergm_termidx'' = ErgmTermData()
		mata: `__td_ad`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: __nwergm_last_M.addterm("absdist", 1, &stat_absdist(), &change_absdist(), `__td_ad`__ergm_termidx'', ("absdist_`__ergm_v'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_ad`__ergm_termidx''"
	}

	local __ergm_termidx = 0
	foreach __ergm_v of local nodematchdiff {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_nmd`__ergm_termidx'
		mata: `__td_nmd`__ergm_termidx'' = ErgmTermData()
		mata: `__td_nmd`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: `__td_nmd`__ergm_termidx''.levels = uniqrows(`__td_nmd`__ergm_termidx''.attr)
		mata: st_local("__ergm_nlev", strofreal(rows(`__td_nmd`__ergm_termidx''.levels)))
		tempname __ergm_levvec
		mata: st_matrix("`__ergm_levvec'", `__td_nmd`__ergm_termidx''.levels')
		local __ergm_cnames ""
		forvalues __k = 1/`__ergm_nlev' {
			local __ergm_cnames "`__ergm_cnames' nodematch_`__ergm_v'_`=`__ergm_levvec'[1,`__k']''"
		}
		mata: __nwergm_last_M.addterm("nodematch_diff", `__ergm_nlev', &stat_nodematch_diff(), &change_nodematch_diff(), `__td_nmd`__ergm_termidx'', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_nmd`__ergm_termidx''"
	}

	local __ergm_termidx = 0
	foreach __ergm_v of local nodefactor {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_nf`__ergm_termidx'
		mata: `__td_nf`__ergm_termidx'' = ErgmTermData()
		mata: `__td_nf`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		// Omit the first (lowest-sorted) level by default, matching R
		// ergm's own nodefactor(attr, base=1) convention (harmonisation
		// unit 90, docs/CERTIFICATION.md) - fresh verification of R's
		// current InitErgmTerm.R confirmed nodefactor sums, per level,
		// "number of times a node with that attribute appears in an
		// edge"; for an undirected network this equals 2*edges once ALL
		// levels are summed, making the FULL-level parameterization
		// exactly collinear with the already-present `edges' term (one
		// level's own coefficient is unidentified) - precisely the
		// redundancy R's own `base' convention exists to avoid. An
		// earlier version of this term (unit 88) shipped without this
		// omission; `stat_nodefactor()'/`change_nodefactor()' themselves
		// needed NO change to fix this - both are already fully generic
		// over whatever `td.levels' holds, so this is a pure `nwergm.ado'
		// construction-time fix.
		mata: `__td_nf`__ergm_termidx''.levels = uniqrows(`__td_nf`__ergm_termidx''.attr)
		mata: if (rows(`__td_nf`__ergm_termidx''.levels) > 1) `__td_nf`__ergm_termidx''.levels = `__td_nf`__ergm_termidx''.levels[2::rows(`__td_nf`__ergm_termidx''.levels)]
		mata: st_local("__ergm_nlev", strofreal(rows(`__td_nf`__ergm_termidx''.levels)))
		tempname __ergm_levvec2
		mata: st_matrix("`__ergm_levvec2'", `__td_nf`__ergm_termidx''.levels')
		local __ergm_cnames ""
		forvalues __k = 1/`__ergm_nlev' {
			local __ergm_cnames "`__ergm_cnames' nodefactor_`__ergm_v'_`=`__ergm_levvec2'[1,`__k']''"
		}
		mata: __nwergm_last_M.addterm("nodefactor", `__ergm_nlev', &stat_nodefactor(), &change_nodefactor(), `__td_nf`__ergm_termidx'', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_nf`__ergm_termidx''"
	}

	local __ergm_termidx = 0
	foreach __ergm_v of local nodemix {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_mx`__ergm_termidx'
		mata: `__td_mx`__ergm_termidx'' = ErgmTermData()
		mata: `__td_mx`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: __ergm_lv = uniqrows(`__td_mx`__ergm_termidx''.attr)
		mata: __ergm_np = rows(__ergm_lv)
		mata: __ergm_lp = J(0,2,0)
		mata: for (__ergm_a=1; __ergm_a<=__ergm_np; __ergm_a++) for (__ergm_b=__ergm_a; __ergm_b<=__ergm_np; __ergm_b++) __ergm_lp = __ergm_lp \ (__ergm_lv[__ergm_a], __ergm_lv[__ergm_b])
		mata: `__td_mx`__ergm_termidx''.levelpairs = __ergm_lp
		mata: st_local("__ergm_nlp", strofreal(rows(__ergm_lp)))
		tempname __ergm_lpmat
		mata: st_matrix("`__ergm_lpmat'", __ergm_lp)
		local __ergm_cnames ""
		forvalues __k = 1/`__ergm_nlp' {
			local __ergm_cnames "`__ergm_cnames' nodemix_`__ergm_v'_`=`__ergm_lpmat'[`__k',1]'_`=`__ergm_lpmat'[`__k',2]''"
		}
		mata: __nwergm_last_M.addterm("nodemix", `__ergm_nlp', &stat_nodemix(), &change_nodemix(), `__td_mx`__ergm_termidx'', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_mx`__ergm_termidx''"
		capture mata: mata drop __ergm_lv __ergm_np __ergm_lp __ergm_a __ergm_b
	}

	// --- term-expansion wave 2 (harmonisation unit 90): degree(numlist)/
	// odegree(numlist)/idegree(numlist), concurrent, triangle, ctriple -
	// see unw_ergm.do's own header comment on these terms for the full
	// statistical definitions and R-ergm cross-checks. All dyad-
	// DEPENDENT (each depends on more than just its own two endpoints'
	// attributes), so none of these are added to the MPLE-eligibility
	// check below - matching mutual/every geometrically-weighted term.
	if "`degree'" != "" {
		tempname __td_deg
		mata: `__td_deg' = ErgmTermData()
		mata: `__td_deg'.levels = strtoreal(tokens("`degree'"))'
		mata: st_local("__ergm_ndeg", strofreal(rows(`__td_deg'.levels)))
		local __ergm_cnames ""
		foreach __ergm_dv of numlist `degree' {
			local __ergm_cnames "`__ergm_cnames' degree_`__ergm_dv'"
		}
		mata: __nwergm_last_M.addterm("degree", `__ergm_ndeg', &stat_degree(), &change_degree(), `__td_deg', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_deg'"
	}
	if "`odegree'" != "" {
		tempname __td_odeg
		mata: `__td_odeg' = ErgmTermData()
		mata: `__td_odeg'.levels = strtoreal(tokens("`odegree'"))'
		mata: st_local("__ergm_ndeg", strofreal(rows(`__td_odeg'.levels)))
		local __ergm_cnames ""
		foreach __ergm_dv of numlist `odegree' {
			local __ergm_cnames "`__ergm_cnames' odegree_`__ergm_dv'"
		}
		mata: __nwergm_last_M.addterm("odegree", `__ergm_ndeg', &stat_odegree(), &change_odegree(), `__td_odeg', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_odeg'"
	}
	if "`idegree'" != "" {
		tempname __td_ideg
		mata: `__td_ideg' = ErgmTermData()
		mata: `__td_ideg'.levels = strtoreal(tokens("`idegree'"))'
		mata: st_local("__ergm_ndeg", strofreal(rows(`__td_ideg'.levels)))
		local __ergm_cnames ""
		foreach __ergm_dv of numlist `idegree' {
			local __ergm_cnames "`__ergm_cnames' idegree_`__ergm_dv'"
		}
		mata: __nwergm_last_M.addterm("idegree", `__ergm_ndeg', &stat_idegree(), &change_idegree(), `__td_ideg', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_ideg'"
	}
	if "`concurrent'" != "" {
		tempname __td_conc
		mata: `__td_conc' = ErgmTermData()
		mata: __nwergm_last_M.addterm("concurrent", 1, &stat_concurrent(), &change_concurrent(), `__td_conc', ("concurrent"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_conc'"
	}
	if "`triangle'" != "" {
		tempname __td_tri
		mata: `__td_tri' = ErgmTermData()
		mata: __nwergm_last_M.addterm("triangle", 1, &stat_triangle(), &change_triangle(), `__td_tri', ("triangle"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_tri'"
	}
	if "`ctriple'" != "" {
		tempname __td_ctri
		mata: `__td_ctri' = ErgmTermData()
		mata: __nwergm_last_M.addterm("ctriple", 1, &stat_ctriple(), &change_ctriple(), `__td_ctri', ("ctriple"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_ctri'"
	}

	local __ergm_termidx = 0
	foreach __ergm_v of local edgecov {
		local ++__ergm_termidx
		tempname __td_ec`__ergm_termidx'
		mata: `__td_ec`__ergm_termidx'' = ErgmTermData()
		nw_syntax `__ergm_v', max(1) other(ec`__ergm_termidx')
		if `ec`__ergm_termidx'nodes' != `nodes' {
			di "{err}edgecov() network {bf:`__ergm_v'} has a different number of nodes than {bf:`netname'}."
			error 198
		}
		mata: `__td_ec`__ergm_termidx''.edgecovmat = *(`ec`__ergm_termidx'netobj'->get_matrix_mod(1,("`directed'"=="true")))
		mata: __nwergm_last_M.addterm("edgecov", 1, &stat_edgecov(), &change_edgecov(), `__td_ec`__ergm_termidx'', ("edgecov_`__ergm_v'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_ec`__ergm_termidx''"
	}

	if "`gwesp'" != "" {
		confirm number `gwesp'
		tempname __td_gwesp
		mata: `__td_gwesp' = ErgmTermData()
		mata: `__td_gwesp'.decay = `gwesp'
		mata: __nwergm_last_M.addterm("gwesp", 1, &stat_gwesp(), &change_gwesp(), `__td_gwesp', ("gwesp_`gwesp'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_gwesp'"
		// ErgmGraph::enable_sp_cache() (Part XXV performance work,
		// docs/CERTIFICATION.md unit 82) is DELIBERATELY NOT called here.
		// It was built, exhaustively certified for correctness, wired in,
		// and then measured directly against this suite's own realistic
		// GWESP benchmarks (100-node and 500-node sparse networks) - and
		// found to make BOTH slower (100-node: 23.1s -> 39.3s; a clean,
		// controlled A/B test isolating the cache as the only variable),
		// not faster. Root cause, fully characterized: TNT's own
		// acceptance rate on a FITTED sparse model is very high (83-93%
		// measured directly, not assumed) - so toggle()'s own cache-
		// maintenance cost (paid on nearly every proposal, not
		// occasionally) dominates the cheaper O(1) lookup's own savings
		// at the LOW degree (~4-6) these realistic benchmark networks
		// have. A degree sweep at a matched high acceptance rate found
		// the cache only becomes a net win around degree ~30-40+ (1.6x
		// faster there; 1.6-2x SLOWER at degree 4-20) - well above what
		// either benchmark network has. Kept unwired rather than removed
		// entirely: the machinery itself is correct and useful for
		// genuinely dense networks, just not a good default for the
		// sparse case this package's own realistic test networks
		// represent. See docs/CERTIFICATION.md unit 82 and
		// docs/ERGM_ROADMAP.md's own Performance section for the full,
		// disclosed account - the same "implement, measure, and report
		// honestly even when the obvious optimization does not pan out"
		// discipline this project used for the batch-means variance
		// estimator (unit 80).
	}
	if "`gwdsp'" != "" {
		confirm number `gwdsp'
		tempname __td_gwdsp
		mata: `__td_gwdsp' = ErgmTermData()
		mata: `__td_gwdsp'.decay = `gwdsp'
		mata: __nwergm_last_M.addterm("gwdsp", 1, &stat_gwdsp(), &change_gwdsp(), `__td_gwdsp', ("gwdsp_`gwdsp'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_gwdsp'"
	}
	if "`gwnsp'" != "" {
		confirm number `gwnsp'
		tempname __td_gwnsp
		mata: `__td_gwnsp' = ErgmTermData()
		mata: `__td_gwnsp'.decay = `gwnsp'
		mata: __nwergm_last_M.addterm("gwnsp", 1, &stat_gwnsp(), &change_gwnsp(), `__td_gwnsp', ("gwnsp_`gwnsp'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_gwnsp'"
	}
	if "`gwdegree'" != "" {
		confirm number `gwdegree'
		tempname __td_gwdeg
		mata: `__td_gwdeg' = ErgmTermData()
		mata: `__td_gwdeg'.decay = `gwdegree'
		mata: __nwergm_last_M.addterm("gwdegree", 1, &stat_gwdegree(), &change_gwdegree(), `__td_gwdeg', ("gwdegree_`gwdegree'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_gwdeg'"
	}
	if "`gwodegree'" != "" {
		confirm number `gwodegree'
		tempname __td_gwod
		mata: `__td_gwod' = ErgmTermData()
		mata: `__td_gwod'.decay = `gwodegree'
		mata: __nwergm_last_M.addterm("gwodegree", 1, &stat_gwodegree(), &change_gwodegree(), `__td_gwod', ("gwodegree_`gwodegree'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_gwod'"
	}
	if "`gwidegree'" != "" {
		confirm number `gwidegree'
		tempname __td_gwid
		mata: `__td_gwid' = ErgmTermData()
		mata: `__td_gwid'.decay = `gwidegree'
		mata: __nwergm_last_M.addterm("gwidegree", 1, &stat_gwidegree(), &change_gwidegree(), `__td_gwid', ("gwidegree_`gwidegree'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_gwid'"
	}

	// dyad-independent iff only edges/nodematch/nodecov/nodeicov/nodeocov/
	// edgecov/absdist/nodematchdiff/nodefactor/nodemix are present (mutual
	// and every geometrically-weighted term, including gwdsp/gwnsp, are
	// dyad-dependent - gwdsp/gwnsp no less than gwesp, since shared-
	// partner counts are just as nonlocal for untied dyads as for tied
	// ones; degree()/odegree()/idegree()/concurrent/triangle/ctriple are
	// ALSO dyad-dependent - unit 90 - since each depends on more than
	// just its own two endpoints' attributes, via other nodes' degrees
	// or shared third parties).
	local __ergm_dind = (`"`mutual'"'=="" & `"`gwesp'"'=="" & `"`gwdsp'"'=="" & `"`gwnsp'"'=="" & `"`gwdegree'"'=="" & `"`gwodegree'"'=="" & `"`gwidegree'"'=="" & `"`degree'"'=="" & `"`odegree'"'=="" & `"`idegree'"'=="" & `"`concurrent'"'=="" & `"`triangle'"'=="" & `"`ctriple'"'=="")
	if "`method'" == "" {
		local method = cond(`__ergm_dind', "mple", "mcmle")
	}
	if "`method'" == "mple" & !`__ergm_dind' {
		di "{txt}Note: {bf:method(mple)} requested for a dyad-dependent model - reporting pseudolikelihood, NOT full ERGM maximum likelihood."
	}

	// Built directly as a Mata matrix and handed straight to st_store()
	// below - NEVER routed through an intermediate Stata MATRIX
	// (st_matrix()), which is fine at the tiny scale of this suite's own
	// certification networks but catastrophically slow (effectively
	// hangs - confirmed directly: a trivial 999000x4 st_matrix() call
	// alone did not complete in over 2 minutes, where the equivalent
	// st_store() directly from Mata took 0.008 seconds) once ndyads
	// scales into the hundreds of thousands - i.e. any directed model
	// with a few hundred nodes or more. Stata matrices are architected
	// for small structures (coefficient vectors, VCV matrices), not
	// bulk per-observation data - the dataset/variable system st_store()
	// targets is what Stata itself uses for that, and performs
	// accordingly. Found and fixed while building the R-vs-Stata
	// benchmark suite's own large-network control case
	// (docs/CERTIFICATION.md harmonisation unit 81).
	tempname __nw_D
	mata: `__nw_D' = __nwergm_last_M.build_mple_data(__nwergm_last_G)
	local __ergm_matatemps "`__ergm_matatemps' `__nw_D'"
	mata: st_local("__ergm_nrows", strofreal(rows(`__nw_D')))
	mata: st_local("__ergm_p", strofreal(cols(`__nw_D')-1))

	tempname __ergm_coefnames
	mata: st_local("__ergm_coefnames", invtokens(__nwergm_last_M.coefnames))

	local __ergm_xlist ""
	forvalues __k = 1/`__ergm_p' {
		local __ergm_xlist "`__ergm_xlist' __ergm_x`__k'"
	}

	preserve
	qui drop _all
	qui set obs `__ergm_nrows'
	foreach __v of local __ergm_xlist {
		qui gen double `__v' = .
	}
	qui gen double __ergm_y = .
	mata: st_store(., tokens("`__ergm_xlist' __ergm_y"), `__nw_D')

	qui logit __ergm_y `__ergm_xlist', noconstant
	tempname __b_mple __V_mple
	matrix `__b_mple' = e(b)
	matrix `__V_mple' = e(V)
	restore

	if "`method'" == "mple" {
		// logit's own e(b)/e(V) carry an equation-name stripe (the
		// depvar's own name, e.g. "__ergm_y:__ergm_x1") - blanked
		// explicitly before assigning fresh colnames/rownames, or a
		// stale/mismatched stripe between b and V makes `ereturn post`
		// fail with a "name conflict" (r(507)) - the exact same bug
		// class already found and fixed once in nwqap.ado (see its own
		// header comment).
		matrix coleq `__b_mple' = _
		matrix coleq `__V_mple' = _
		matrix roweq `__V_mple' = _
		matrix colnames `__b_mple' = `__ergm_coefnames'
		matrix rownames `__V_mple' = `__ergm_coefnames'
		matrix colnames `__V_mple' = `__ergm_coefnames'

		ereturn post `__b_mple' `__V_mple', depname(`netname') obs(`__ergm_nrows')
		ereturn local cmd "nwergm"
		ereturn local title "Exponential-family random graph model (MPLE)"
		ereturn local depvar "`netname'"
		ereturn local method "mple"
		ereturn local directed "`directed'"
		ereturn local estat_cmd "nwergm_estat"
		ereturn scalar N = `__ergm_nrows'
		ereturn scalar nodes = `nodes'
		ereturn scalar ties = `__ergm_obsties'

		nwergm_display "`netname'" "`nodes'" "`directed'" "MPLE" "" ""
	}
	else {
		tempname __theta0
		mata: `__theta0' = st_matrix("`__b_mple'")
		local __ergm_matatemps "`__ergm_matatemps' `__theta0'"

		if "`proposal'" == "tnt" {
			local __ergm_propfn "&ergm_propose_tnt()"
			local __ergm_propcode 2
		}
		else {
			local __ergm_propfn "&ergm_propose_uniform()"
			local __ergm_propcode 1
		}

		// Native (C) MCMC backend eligibility (harmonisation unit 83) -
		// decided ONCE here, before any MCMC runs, never inside
		// ErgmMCMLE()'s own loop. Sets __nwergm_last_M.native_enabled;
		// ErgmMCMCSample()/ErgmMCMCSampleDiag() (called internally by
		// ErgmMCMLE() below) check that field themselves and fall back
		// to the unmodified Mata sampler whenever it is 0 - a model
		// using any term outside the native backend's own deliberately
		// narrow scope (edges/mutual/nodematch/gwesp), or a platform
		// with no compiled lib/plugins/ergm_mcmc.plugin, is completely
		// unaffected by this call. See unw_ergm.do's own "Native (C)
		// MCMC backend" section and docs/ERGM_ARCHITECTURE.md for the
		// full design.
		mata: ErgmNativeSetup(__nwergm_last_M, `__ergm_propcode')

		tempname __fit
		mata: `__fit' = ErgmMCMLE(__nwergm_last_M, __nwergm_last_G, `__theta0', `mcmleiterations', `mcmcburnin', `mcmcinterval', `mcmcsamplesize', `__ergm_propfn', ("`verbose'"!=""))
		local __ergm_matatemps "`__ergm_matatemps' `__fit'"

		tempname __b_mcmle __V_mcmle
		mata: st_matrix("`__b_mcmle'", `__fit'.coef)
		mata: st_matrix("`__V_mcmle'", `__fit'.vcov)
		// captured into plain locals, NOT e(name)-style scalars: `ereturn
		// post' below clears whatever the e() results namespace
		// currently holds, so referencing `e(converged)' AFTER that
		// call (as this code originally, incorrectly, did) reads back
		// missing - the exact same "r(x) is only published once the
		// program exits" confusion already found and fixed once in this
		// package's own nw2project.ado, here for e() instead of r().
		mata: st_local("__ergm_converged", strofreal(`__fit'.converged))
		mata: st_local("__ergm_niter", strofreal(`__fit'.niter))
		mata: st_local("__ergm_acceptrate", strofreal(`__fit'.acceptrate))
		mata: st_local("__ergm_interval_final", strofreal(`__fit'.final_interval))

		matrix coleq `__b_mcmle' = _
		matrix coleq `__V_mcmle' = _
		matrix roweq `__V_mcmle' = _
		matrix colnames `__b_mcmle' = `__ergm_coefnames'
		matrix rownames `__V_mcmle' = `__ergm_coefnames'
		matrix colnames `__V_mcmle' = `__ergm_coefnames'

		ereturn post `__b_mcmle' `__V_mcmle', depname(`netname') obs(`__ergm_nrows')
		ereturn local cmd "nwergm"
		ereturn local title "Exponential-family random graph model (MCMLE)"
		ereturn local depvar "`netname'"
		ereturn local method "mcmle"
		ereturn local directed "`directed'"
		ereturn local proposal "`proposal'"
		ereturn local estat_cmd "nwergm_estat"
		ereturn scalar N = `__ergm_nrows'
		ereturn scalar nodes = `nodes'
		ereturn scalar converged = `__ergm_converged'
		ereturn scalar mcmle_iterations = `__ergm_niter'
		ereturn scalar mcmc_acceptrate = `__ergm_acceptrate'
		ereturn scalar mcmc_burnin = `mcmcburnin'
		ereturn scalar mcmc_interval = `mcmcinterval'
		// The interval actually used for the LAST MCMLE iteration and the
		// final diagnostics simulation (harmonisation unit 85) - may
		// exceed `e(mcmc_interval)' (the caller-supplied starting value)
		// when the adaptive-interval mechanism grew it because the
		// achieved effective MCMC sample size fell short of the target
		// floor; equal to `e(mcmc_interval)' whenever no growth was ever
		// triggered (the ordinary case for small/well-mixing models).
		ereturn scalar mcmc_interval_final = `__ergm_interval_final'
		ereturn scalar mcmc_samplesize = `mcmcsamplesize'
		ereturn scalar ties = `__ergm_obsties'
		// the final simulation's own sufficient-statistic draws
		// (samplesize x nparam), doubling as nwergm's basic MCMC
		// diagnostics sample (Part XIX) - consumed by `estat mcmcdiag'
		// (nwergm_estat.ado). Columns are unnamed (no natural row/column
		// stripe applies to a raw draw-by-draw sample); `estat mcmcdiag'
		// pulls coefficient names from e(b) instead.
		mata: st_matrix("e(mcmcsample)", `__fit'.finalsample)

		if `__ergm_converged' == 0 {
			di "{err}Warning: MCMLE did NOT satisfy its own convergence test after `__ergm_niter' iterations."
			di "{err}Results are reported but should not be treated as a converged fit - consider increasing mcmleiterations()/mcmcsamplesize()."
		}

		nwergm_display "`netname'" "`nodes'" "`directed'" "MCMLE" "`__ergm_converged'" "`__ergm_niter'" "`mcmcsamplesize'"
	}

	mata: mata drop `__ergm_matatemps'
end

capture program drop nwergm_display
program nwergm_display
	args netname nodes directed method converged niter mcmcsamplesize

	di
	di "{txt}Exponential-family random graph model"
	di
	di "{txt}Network:{col 24}={res}  `netname'"
	di "{txt}Nodes:{col 24}={res}  `nodes'"
	di "{txt}Ties:{col 24}={res}  `=e(ties)'"
	di "{txt}Directed:{col 24}={res}  " cond("`directed'"=="true","Yes","No")
	di "{txt}Estimation:{col 24}={res}  `method'"
	if "`method'" == "MCMLE" {
		di "{txt}MCMC sample size:{col 24}={res}  `mcmcsamplesize'"
	}
	di
	ereturn display
	di
	if "`method'" == "MCMLE" {
		if "`converged'" == "1" {
			di "{txt}MCMLE converged after `niter' iteration(s)."
		}
		else {
			di "{err}MCMLE did not converge after `niter' iteration(s)."
		}
	}
	else {
		di "{txt}Maximum pseudolikelihood estimate (not full ERGM maximum likelihood unless the model is dyad-independent)."
	}
end

/*
	nwergm simulate (Part X's own example syntax): draws one or more
	networks from a fully-specified ERGM (fixed theta, not estimated),
	via the same native MCMC engine nwergm's own estimation path uses.
	v1 scope deliberately covers only the terms needing no external
	covariate data (edges/mutual/the gw family) - see this program's own
	SMCL doc header above ("Simulation" section) for the full rationale
	and docs/ERGM_ROADMAP.md for extending this to covariate terms.
*/
capture program drop nwergm_simulate
program nwergm_simulate
	version 14
	syntax anything(name=nodes) , edges [mutual ///
		GWESP(real 0) GWDEGREE(real 0) GWODEGREE(real 0) GWIDEGREE(real 0) ///
		THETA(numlist) directed NSIM(integer 1) MCMCBURNIN(integer 3000) ///
		MCMCINTERVAL(integer 50) PROPOSAL(string) SEED(integer -1) GENERATE(string) ]

	confirm integer number `nodes'
	if `nodes' < 2 {
		di "{err}nwergm simulate needs at least 2 nodes."
		error 198
	}
	if "`theta'" == "" {
		di "{err}option {bf:theta()} is required - one coefficient per requested term, in the same order the term options are listed (edges first)."
		error 198
	}
	if "`mutual'" != "" & "`directed'" == "" {
		di "{err}option {bf:mutual} requires {bf:directed}."
		error 198
	}
	if (`gwodegree' != 0 | `gwidegree' != 0) & "`directed'" == "" {
		di "{err}options {bf:gwodegree()}/{bf:gwidegree()} require {bf:directed}. Use {bf:gwdegree()} for an undirected simulation."
		error 198
	}
	if `gwesp' != 0 & "`directed'" != "" {
		di "{err}option {bf:gwesp()} (v1 scope) is undirected only."
		error 198
	}
	if "`proposal'" == "" local proposal "tnt"
	_opts_oneof "uniform tnt" "proposal" "`proposal'" 198
	if "`generate'" == "" local generate "ergmsim"
	if `seed' != -1 {
		set seed `seed'
	}

	local __ergm_matatemps ""

	capture mata: mata drop __nwergm_last_M
	mata: __nwergm_last_M = ErgmModel()
	mata: __nwergm_last_M.init()

	tempname td_edges
	mata: `td_edges' = ErgmTermData()
	mata: __nwergm_last_M.addterm("edges", 1, &stat_edges(), &change_edges(), `td_edges', ("edges"))
	local ntermtok "edges"
	local __ergm_matatemps "`__ergm_matatemps' `td_edges'"

	if "`mutual'" != "" {
		tempname td_mutual
		mata: `td_mutual' = ErgmTermData()
		mata: __nwergm_last_M.addterm("mutual", 1, &stat_mutual(), &change_mutual(), `td_mutual', ("mutual"))
		local ntermtok "`ntermtok' mutual"
		local __ergm_matatemps "`__ergm_matatemps' `td_mutual'"
	}
	if `gwesp' != 0 {
		tempname td_gwesp
		mata: `td_gwesp' = ErgmTermData()
		mata: `td_gwesp'.decay = `gwesp'
		mata: __nwergm_last_M.addterm("gwesp", 1, &stat_gwesp(), &change_gwesp(), `td_gwesp', ("gwesp"))
		local ntermtok "`ntermtok' gwesp"
		local __ergm_matatemps "`__ergm_matatemps' `td_gwesp'"
	}
	if `gwdegree' != 0 {
		tempname td_gwdeg
		mata: `td_gwdeg' = ErgmTermData()
		mata: `td_gwdeg'.decay = `gwdegree'
		mata: __nwergm_last_M.addterm("gwdegree", 1, &stat_gwdegree(), &change_gwdegree(), `td_gwdeg', ("gwdegree"))
		local ntermtok "`ntermtok' gwdegree"
		local __ergm_matatemps "`__ergm_matatemps' `td_gwdeg'"
	}
	if `gwodegree' != 0 {
		tempname td_gwod
		mata: `td_gwod' = ErgmTermData()
		mata: `td_gwod'.decay = `gwodegree'
		mata: __nwergm_last_M.addterm("gwodegree", 1, &stat_gwodegree(), &change_gwodegree(), `td_gwod', ("gwodegree"))
		local ntermtok "`ntermtok' gwodegree"
		local __ergm_matatemps "`__ergm_matatemps' `td_gwod'"
	}
	if `gwidegree' != 0 {
		tempname td_gwid
		mata: `td_gwid' = ErgmTermData()
		mata: `td_gwid'.decay = `gwidegree'
		mata: __nwergm_last_M.addterm("gwidegree", 1, &stat_gwidegree(), &change_gwidegree(), `td_gwid', ("gwidegree"))
		local ntermtok "`ntermtok' gwidegree"
		local __ergm_matatemps "`__ergm_matatemps' `td_gwid'"
	}

	local nterm : word count `ntermtok'
	local nth : word count `theta'
	if `nth' != `nterm' {
		di "{err}theta() supplies `nth' coefficient(s) but `nterm' term(s) were requested (`ntermtok') - exactly one coefficient per term, in listed order."
		error 198
	}
	tempname thetamat
	matrix `thetamat' = J(1, `nterm', 0)
	forvalues __k = 1/`nterm' {
		matrix `thetamat'[1,`__k'] = `: word `__k' of `theta''
	}

	forvalues __s = 1/`nsim' {
		capture mata: mata drop __nwergm_last_G
		mata: __nwergm_last_G = ErgmGraph()
		mata: __nwergm_last_G.init(`nodes', ("`directed'"!=""))
		// enable_sp_cache() deliberately NOT called here either - see the
		// main nwergm program's own gwesp block for the full, measured
		// account of why (net loss at the low degree realistic sparse
		// networks have; only a net win above roughly degree 30-40).
		// ErgmNativeSetup() is likewise deliberately NOT called on this
		// path (harmonisation unit 83): this loop calls ErgmMCMCSample()
		// once PER SIMULATED NETWORK with samplesize=1, so `nsim' native
		// plugin calls would each pay the native boundary's own fixed
		// per-call overhead (frame create/drop, program define, dataset
		// construction) for a single-row draw - exactly the "crossing
		// the boundary too often" architecture this unit's own governing
		// instructions warn against. __nwergm_last_M.native_enabled
		// therefore simply stays at its ErgmModel::init() default of 0
		// here, so every draw runs on the unmodified Mata sampler.
		mata: __gof_discard = ErgmMCMCSample(__nwergm_last_M, __nwergm_last_G, st_matrix("`thetamat'"), `mcmcburnin', `mcmcinterval', 1, `=cond("`proposal'"=="tnt","&ergm_propose_tnt()","&ergm_propose_uniform()")')
		mata: st_local("__ergm_simexpr", ErgmMatToLiteral(__nwergm_last_G.to_dense()))

		local __ergm_simname = cond(`nsim'==1, "`generate'", "`generate'_`__s'")
		capture nwdrop `__ergm_simname'
		qui drop _all
		qui set obs `nodes'
		nwset, mat(`__ergm_simexpr') `=cond("`directed'"!="","directed","undirected")' name(`__ergm_simname')
	}

	mata: mata drop __nwergm_last_M __nwergm_last_G __gof_discard `__ergm_matatemps'
end

/*
	Bridge from an NWdef network to a fresh ErgmGraph: one-time read via
	NWdef's own neighbors() sparse accessor, undirected ties added once
	each (nb[k] <= i skipped, since ErgmGraph.toggle() already mirrors
	an undirected tie in both directions internally). Defined once at
	file scope (guarded, matching nwqap.ado's own established pattern
	for file-scope Mata helpers) rather than inside the program body -
	redefining a Mata function on every single nwergm call would error
	on the second call within the same session ("already exists").
*/
capture mata: mata drop ergm_bridge_from_netobj()
mata:
void ergm_bridge_from_netobj(pointer(class nw_def scalar) scalar netobj,
	class ErgmGraph scalar G, real scalar directed){
	real scalar i, k
	real matrix nb

	for (i=1; i<=G.n; i++) {
		nb = netobj->neighbors(i)
		for (k=1; k<=rows(nb); k++) {
			if (!directed & nb[k] <= i) continue
			G.toggle(i, nb[k])
		}
	}
}
end
