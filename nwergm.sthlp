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

