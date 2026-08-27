/***
{smcl}
{* *! version 2.0.0  22aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_statmodels:[NW-2.6.6] Statistical Estimation of Networks}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwergm {hline 2}}Exponential-family random graph model (ERGM) estimation{p_end}
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
[{opth hamming(netname)}]
[{opth absdist(varlist)}]
[{opth nodefactor(varlist)}]
[{opth nodeofactor(varlist)}]
[{opth nodeifactor(varlist)}]
[{opth nodemix(varlist)}]
[{opt sender}]
[{opt receiver}]
[{opt gwesp(real)}]
[{opt gwespfree(real)}]
[{opt gwdegreefree(real)}]
[{opt gwdspfree(real)}]
[{opt gwdsp(real)}]
[{opt gwnsp(real)}]
[{opt gwdegree(real)}]
[{opt gwodegree(real)}]
[{opt gwidegree(real)}]
[{opt esp(numlist)}]
[{opt dsp(numlist)}]
[{opt type(OTP|ITP|OSP|ISP|RTP)}]
[{opt degree(numlist)}]
[{opt odegree(numlist)}]
[{opt idegree(numlist)}]
[{opt kstar(numlist)}]
[{opt ostar(numlist)}]
[{opt istar(numlist)}]
[{opt degrange(numlist)}
{opt degrangeto(numlist)}]
[{opt odegrange(numlist)}
{opt odegrangeto(numlist)}]
[{opt idegrange(numlist)}
{opt idegrangeto(numlist)}]
[{opt concurrent}]
[{opt triangle}]
[{opt ctriple}]
[{opt transitiveties}]
[{opt cyclicalties}]
[{opt method(mple|mcmle)}
{opt mcmcburnin(int)}
{opt mcmcinterval(int)}
{opt mcmcsamplesize(int)}
{opt mcmleiterations(int)}
{opt proposal(uniform|tnt)}
{opt seed(int)}
{opt verbose}
{opt spcache}]


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
{synopt:{opt gwesp(real)}}Geometrically weighted edgewise shared partners, fixed decay; undirected (UTP) or directed (shared-partner definition set by {opt type()}, default OTP){p_end}
{synopt:{opt gwespfree(real)}}Geometrically weighted edgewise shared partners with an ESTIMATED (curved) decay parameter, undirected networks only; the argument is only a starting value for decay, not a fixed value. {bf:method(mple)} only for now (curved MCMLE is not yet implemented) - reports {bf:gwesp_weight}/{bf:gwesp_decay} in place of a single {opt gwesp()} coefficient. Cannot be combined with {opt gwesp()}, {opt esp()}, or another curved term{p_end}
{synopt:{opt gwdegreefree(real)}}Geometrically weighted degree with an ESTIMATED (curved) decay parameter, undirected networks only; the argument is only a starting value for decay, not a fixed value. {bf:method(mple)} only for now (curved MCMLE is not yet implemented) - reports {bf:gwdegree_weight}/{bf:gwdegree_decay} in place of a single {opt gwdegree()} coefficient. Cannot be combined with {opt gwdegree()}, {opt degree()}, or another curved term{p_end}
{synopt:{opt gwdspfree(real)}}Geometrically weighted dyadwise shared partners with an ESTIMATED (curved) decay parameter, undirected networks only; the argument is only a starting value for decay, not a fixed value. {bf:method(mple)} only for now (curved MCMLE is not yet implemented) - reports {bf:gwdsp_weight}/{bf:gwdsp_decay} in place of a single {opt gwdsp()} coefficient. Cannot be combined with {opt gwdsp()}, {opt dsp()}, or another curved term{p_end}
{synopt:{opt gwdsp(real)}}Geometrically weighted dyadwise shared partners, fixed decay; undirected (UTP) or directed (see {opt type()}){p_end}
{synopt:{opt gwdegree(real)}}Geometrically weighted degree, fixed decay{p_end}
{synopt:{opt gwodegree(real)}}Geometrically weighted out-degree, fixed decay; directed networks only{p_end}
{synopt:{opt gwidegree(real)}}Geometrically weighted in-degree, fixed decay; directed networks only{p_end}
{synopt:{opt gwnsp(real)}}Geometrically weighted NONedgewise (untied-dyad) shared partners, fixed decay; undirected (UTP) or directed (see {opt type()}). Satisfies gwdsp = gwesp + gwnsp{p_end}
{synopt:{opt degree(numlist)}}One coefficient per listed degree value: count of nodes with that exact (total) degree; undirected only{p_end}
{synopt:{opt odegree(numlist)}}One coefficient per listed value: count of nodes with that exact out-degree; directed networks only{p_end}
{synopt:{opt idegree(numlist)}}One coefficient per listed value: count of nodes with that exact in-degree; directed networks only{p_end}
{synopt:{opt concurrent}}Count of nodes with (total) degree 2 or higher; undirected only{p_end}
{synopt:{opt triangle}}Count of triangles (mutually tied triples); undirected only{p_end}
{synopt:{opt ctriple}}Count of cyclic triples ((i->j),(j->k),(k->i)); directed networks only{p_end}
{synopt:{opth nodeofactor(varlist)}}Directed analogue of nodefactor(): one coefficient per NON-BASE distinct level, each counting OUT-degree among nodes at that level; directed networks only{p_end}
{synopt:{opth nodeifactor(varlist)}}Directed analogue of nodefactor(): one coefficient per NON-BASE distinct level, each counting IN-degree among nodes at that level; directed networks only{p_end}
{synopt:{opt kstar(numlist)}}One coefficient per listed k value: count of k-stars ((total) degree choose k, summed over nodes); undirected only{p_end}
{synopt:{opt ostar(numlist)}}One coefficient per listed k value: count of out-k-stars; directed networks only{p_end}
{synopt:{opt istar(numlist)}}One coefficient per listed k value: count of in-k-stars; directed networks only{p_end}
{synopt:{opt degrange(numlist)}}Semi-open-interval degree count: one coefficient per FROM value in this numlist, counting nodes with (total) degree in [from,to); pair with {opt degrangeto()}; undirected only{p_end}
{synopt:{opt degrangeto(numlist)}}TO values pairing with {opt degrange()}, same order/length; omit for an open-ended upper bound{p_end}
{synopt:{opt odegrange(numlist)}}Semi-open-interval OUT-degree count, paired with {opt odegrangeto()}; directed networks only{p_end}
{synopt:{opt odegrangeto(numlist)}}TO values pairing with {opt odegrange()}{p_end}
{synopt:{opt idegrange(numlist)}}Semi-open-interval IN-degree count, paired with {opt idegrangeto()}; directed networks only{p_end}
{synopt:{opt idegrangeto(numlist)}}TO values pairing with {opt idegrange()}{p_end}
{synopt:{opt esp(numlist)}}One coefficient per listed d value: count of TIED dyads with exactly d shared partners (fixed, non-geometric alternative to {opt gwesp()}); undirected (UTP) or directed (see {opt type()}){p_end}
{synopt:{opt dsp(numlist)}}One coefficient per listed d value: count of ALL dyads (tied or not) with exactly d shared partners (fixed, non-geometric alternative to {opt gwdsp()}); undirected (UTP) or directed (see {opt type()}). An EXHAUSTIVE d-range (covering every shared-partner value a toggle can produce) is exactly collinear across its own columns - list a subset, not every achievable value{p_end}
{synopt:{opt type(OTP|ITP|OSP|ISP|RTP)}}Shared-partner definition used by every {opt gwesp()}/{opt gwdsp()}/{opt gwnsp()}/{opt esp()}/{opt dsp()} term in the model, on a DIRECTED network only (default {bf:OTP}; silently ignored, matching R ergm's own behaviour, when {bf:netname} is undirected - see the {bf:Remarks} section below for the five definitions){p_end}
{synopt:{opt transitiveties}}Count of TIED arcs i->j for which there also exists a two-path i->k->j (an existence/threshold indicator, not a count - contrast with {opt gwesp()}/{opt esp()}); directed networks only{p_end}
{synopt:{opt cyclicalties}}Count of TIED arcs i->j for which there also exists a return two-path j->k->i, closing a directed 3-cycle; directed networks only{p_end}
{synopt:{opth hamming(netname)}}Hamming distance to a reference network: count of dyads whose tie state disagrees with the same network's{p_end}
{synopt:{opt sender}}One coefficient per node (except a base node) equal to that node's own out-degree; directed networks only{p_end}
{synopt:{opt receiver}}One coefficient per node (except a base node) equal to that node's own in-degree; directed networks only{p_end}
{synopt:{opt method(mple|mcmle)}}Estimation method; default {it:mcmle} unless the model is dyad-independent, in which case MPLE already is the MLE{p_end}
{synopt:{opt mcmcburnin(int)}}MCMC burn-in steps per simulation; default 3,000{p_end}
{synopt:{opt mcmcinterval(int)}}MCMC steps between recorded draws; default 50{p_end}
{synopt:{opt mcmcsamplesize(int)}}Number of recorded MCMC draws per simulation; default 3,000{p_end}
{synopt:{opt mcmleiterations(int)}}Maximum MCMLE outer iterations; default 20{p_end}
{synopt:{opt proposal(uniform|tnt)}}Metropolis-Hastings proposal; default {it:tnt}{p_end}
{synopt:{opt seed(int)}}Set the random-number seed before simulating (for reproducibility){p_end}
{synopt:{opt verbose}}Show MPLE/MCMLE iteration detail{p_end}
{synopt:{opt spcache}}Enable the incremental shared-partner cache for {opt gwesp()}/{opt gwdsp()}/{opt gwnsp()}/{opt esp()}/{opt dsp()}/{opt triangle}/{opt ctriple} on an undirected network; OFF by default because direct benchmarking found it a net LOSS below roughly average degree 30-40 (the common case) and a net win only above that - enable only for denser undirected networks; no effect on a directed network or without any of those terms{p_end}

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
{cmd:nwergm} started as a deliberately small first release (a working extensible core - term
registry, Metropolis-Hastings simulation with a genuine tie/no-tie proposal, maximum
pseudolikelihood estimation, and Monte Carlo maximum likelihood estimation - with a small,
carefully certified effect library) and has since grown considerably closer to parity with
Statnet's own term surface: the current effect library covers the full node-covariate family,
dyadic covariates, the geometrically weighted family (including directed shared-partner
support), fixed shared-partner counts, the complete degree-distribution family, and directed
triad-closure terms - see {help nwergm##limitations:Limitations} below for the complete current
list. What still sets {cmd:nwergm} apart from full parity is scope, not term count: two-mode
(bipartite) ERGMs, curved/free-decay estimation, and constraints beyond the free binary dyad
space remain roadmap items, each a genuine architectural addition rather than another term to
add. See the package's own {browse "docs/ERGM_ROADMAP.md"} for the prioritised extension plan.

{pstd}
{opt method()} selects the estimation method. If every requested term is dyad-independent
(the node-covariate family - {opt edges}, {opt nodematch()}, {opt nodematchdiff()},
{opt nodecov()}, {opt nodeicov()}/{opt nodeocov()}, {opt absdist()}, {opt nodefactor()},
{opt nodeofactor()}/{opt nodeifactor()}, {opt nodemix()}, {opt sender}, {opt receiver} - plus
the dyadic-covariate terms {opt edgecov()}/{opt hamming()}) and no dyad-DEPENDENT term
({opt mutual}, any geometrically weighted term, any degree-distribution term, {opt triangle},
{opt ctriple}, {opt transitiveties}, {opt cyclicalties}, {opt esp()}, or {opt dsp()}) is
present, maximum pseudolikelihood {it:is} the maximum likelihood estimate - {cmd:nwergm}
detects this automatically and reports {opt method(mple)} results directly (labeled as such,
not as full ERGM MLE) without ever running MCMC. Otherwise the default is
{opt method(mcmle)}: pseudolikelihood is used only as the starting value for Monte Carlo maximum
likelihood.

{marker limitations}{...}

{title:Supported network types}

{pstd}
Binary: yes (only) - MPLE/MCMLE estimation here is for a binary tie-formation model; a valued network's own tie values are not used as an outcome (no weighted ERGM family is implemented). Directed: yes, most terms have both directed and undirected forms (see the term list). Weighted: not applicable (see Binary). Signed: not applicable. Two-mode: not checked - term availability for a genuinely bipartite network has not been independently verified.

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
The effect library has grown considerably past its original small first-release set (see the
{cmd:Syntax} block above for the complete, current option list) and now covers, in addition to
{opt edges}/{opt mutual}: the node-covariate family ({opt nodematch()}, {opt nodematchdiff()},
{opt nodecov()}, {opt nodeicov()}/{opt nodeocov()}, {opt absdist()}, {opt nodefactor()},
{opt nodeofactor()}/{opt nodeifactor()}, {opt nodemix()}, {opt sender}, {opt receiver}); dyadic
covariates ({opt edgecov()}, {opt hamming()}); the geometrically weighted family
({opt gwesp()}/{opt gwdsp()}/{opt gwnsp()}/{opt gwdegree()}/{opt gwodegree()}/{opt gwidegree()})
with FIXED decay only (curved/free-decay estimation is a roadmap item); fixed shared-partner
counts ({opt esp()}/{opt dsp()}); the degree-distribution family ({opt degree()}/{opt odegree()}/
{opt idegree()}/{opt concurrent}/{opt kstar()}/{opt ostar()}/{opt istar()}/{opt degrange()}/
{opt odegrange()}/{opt idegrange()}); and directed triad-closure terms ({opt triangle}/
{opt ctriple}/{opt transitiveties}/{opt cyclicalties}). {opt gwesp()}/{opt gwdsp()}/{opt gwnsp()}/
{opt esp()}/{opt dsp()} also support directed networks via any of FIVE directed shared-partner
definitions, selected with {opt type()} (default {bf:OTP}, R ergm's own default) and applied
uniformly to every one of these five terms present in the same model:

{p2colset 9 22 24 2}
{p2col:{bf:OTP}}outgoing two-path, i->k->j (the default){p_end}
{p2col:{bf:ITP}}incoming two-path, i<-k<-j{p_end}
{p2col:{bf:OSP}}outgoing shared partner, i->k<-j (i and j share an out-neighbor k){p_end}
{p2col:{bf:ISP}}incoming shared partner, i<-k->j (i and j share an in-neighbor k){p_end}
{p2col:{bf:RTP}}reciprocated two-path, i<->k<->j (k is a shared partner only through a mutual tie on each leg){p_end}
{p2colreset}

{pstd}
All five directed shared-partner definitions R ergm itself offers are implemented. Two-mode/bipartite terms are deliberately
deprioritized as a
later initiative (see the roadmap); {cmd:balance}/signed-network terms are blocked (signed networks
are not a supported data type at all); curved parameters need a genuine MCMLE architecture
change, not a term-only addition. Constraints beyond the free binary dyad space and offsets are
not yet implemented - see the roadmap. Basic MCMC diagnostics ({help nwergm_estat:estat mcmcdiag})
and basic goodness of fit ({help nwergm_estat:estat gof}) are both available; see
{help nwergm_estat}.

{marker native}{...}
{title:Performance: the native (C) MCMC backend}

{pstd}
{cmd:nwergm} ships a fully independent Mata implementation of its entire estimator (term
registry, MCMC sampler, MPLE, MCMLE) - this is always the reference implementation and is what
runs for every model on every platform. For a growing subset of models, {cmd:nwergm} ALSO
compiles the MCMC inner loop into a native Stata plugin (C) and uses that instead, entirely
transparently: there is nothing to turn on, no option to set, and no difference in how results
are interpreted. Whether a given run used the native backend or the Mata one is purely a
performance detail, exposed only for curiosity via {bf:e(native)} after {opt method(mcmle)} -
the two are certified to produce statistically indistinguishable results (independent random-
number streams, so not bit-identical sample paths, but the same target distribution; see the
package's own {cmd:cscripts/test_nwergm_native.do}).

{pstd}
The native backend requires a compiled plugin for the current platform (macOS is built and
shipped; Windows/Linux build automatically via the package's own CI once available there) AND
every term in the model to be one the native backend currently implements - a single term
outside that set falls the WHOLE model back to the Mata sampler, since every term's own change
statistic must be evaluated on every proposal (there is no way to run "some terms in C, some in
Mata" without crossing the Mata/C boundary on every single MCMC step, which would defeat the
entire purpose). As of this release the native-eligible set is: {opt edges}, {opt mutual},
every node-covariate term ({opt nodematch()}, {opt nodematchdiff()}, {opt nodecov()},
{opt nodeicov()}/{opt nodeocov()}, {opt absdist()}, {opt nodefactor()},
{opt nodeofactor()}/{opt nodeifactor()}, {opt nodemix()}, {opt sender}, {opt receiver}); the
entire degree-distribution family ({opt degree()}/{opt odegree()}/{opt idegree()}/{opt concurrent}/
{opt kstar()}/{opt ostar()}/{opt istar()}/{opt degrange()}/{opt odegrange()}/{opt idegrange()}/
{opt gwdegree()}/{opt gwodegree()}/{opt gwidegree()}); and the entire shared-partner family, both
undirected and directed, EVERY {opt type()} included ({opt gwesp()}/{opt gwdsp()}/{opt gwnsp()}/
{opt esp()}/{opt dsp()}/{opt triangle}/{opt ctriple}/{opt transitiveties}/{opt cyclicalties}). In
practice this means essentially every {cmd:nwergm} model now runs on the native backend. The one
remaining exception (automatically and correctly using the Mata backend instead, with no error and
no action needed): {opt edgecov()}/{opt hamming()}, which need an entire dyadic covariate matrix
marshalled across the plugin boundary rather than the per-node values or scalar parameters every
other term needs - see {browse "docs/ERGM_ROADMAP.md"}'s own "Native backend" section for the
current status.

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
	  {bf:e(native)}		1 if the native (C) MCMC backend was used for this run's simulations,
					0 if the Mata sampler ran instead (method(mcmle) only) - purely
					informational, see {help nwergm##native:Performance} below

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
[{it:{help nwergm##simulate_terms:term options}}]
[{opt type(OTP|ITP|OSP|ISP|RTP)}]
{opt theta(numlist)}
[{opt directed}
{opt nsim(int)}
{opt mcmcburnin(int)}
{opt mcmcinterval(int)}
{opt proposal(uniform|tnt)}
{opt seed(int)}
{opt generate(string)}
{opt spcache}]

{pstd}
{cmd:nwergm simulate} draws one or more networks from a fully-specified ERGM (fixed
coefficients, not estimated) via the same native Metropolis-Hastings sampler {cmd:nwergm}
itself uses for estimation - matching the {browse "https://cran.r-project.org/package=ergm":Statnet
ergm} package's own {cmd:simulate.ergm}. {it:nodes} is the number of nodes to simulate on (no
existing network is required or read).

{marker simulate_terms}{...}
{pstd}
As of this release, {cmd:nwergm simulate} supports the full {cmd:nwergm} term library - every
term option listed in the {cmd:nwergm} {bf:Syntax} section above - not just the geometrically
weighted family. Each family sources its data the same way it does during estimation:

{p2colset 9 32 34 2}{...}
{p2col:{it:no external data}}{opt mutual}, {opt concurrent}, {opt triangle}, {opt ctriple},
{opt transitiveties}, {opt cyclicalties}, {opt degree(numlist)}, {opt odegree(numlist)},
{opt idegree(numlist)}, {opt kstar(numlist)}, {opt ostar(numlist)}, {opt istar(numlist)},
{opt degrange(numlist)}/{opt degrangeto(numlist)} (and the {opt o}-/{opt i}- directed
analogues), {opt esp(numlist)}, {opt dsp(numlist)}, and the full geometrically weighted family
({opt gwesp}/{opt gwdsp}/{opt gwnsp}/{opt gwdegree}/{opt gwodegree}/{opt gwidegree}, all
{it:real}, decay value only){p_end}
{p2col:{it:node covariate}}{opt nodematch(varname)}, {opt nodematchdiff(varname)},
{opt nodecov(varname)}, {opt nodeicov(varname)}, {opt nodeocov(varname)}, {opt absdist(varname)},
{opt nodefactor(varname)}, {opt nodeofactor(varname)}, {opt nodeifactor(varname)},
{opt nodemix(varname)}, {opt sender}, {opt receiver} - read via {cmd:st_data()} from
{it:the currently active Stata dataset}, exactly as estimation reads them from whatever dataset
is loaded alongside the network being fit. The active dataset must already have {it:nodes}
observations with the named variable populated before calling {cmd:simulate} (e.g.
{cmd:set obs 20} + {cmd:gen mygroup = ...}); {opt sender}/{opt receiver} need no real
covariate at all, since their own "attribute" is just each node's own index.{p_end}
{p2col:{it:dyadic covariate}}{opt edgecov(netname)}, {opt hamming(netname)} - read from
{it:netname}, an already-{help nwset:set}/loaded reference network of the same size as
{it:nodes}, exactly as estimation reads a dyadic covariate from a second network object.{p_end}

{pstd}
{opt type()} selects which of the five directed shared-partner definitions (default {bf:OTP}) any
{opt gwesp}/{opt gwdsp}/{opt gwnsp}/{opt esp()}/{opt dsp()} term simulates under, with {opt directed}
- exactly the same option, with the same meaning, as {cmd:nwergm}'s own estimation path; see that
command's own {bf:Remarks} section for the five definitions.

{pstd}
{opt theta()} supplies one coefficient per resulting model term, in the SAME fixed sequence
{cmd:nwergm}'s own estimation path itself always processes terms in (edges, mutual, then every
node-covariate family, then the structural/numlist family, then {opt sender}/{opt receiver},
then the dyadic-covariate family, then the geometrically weighted family - regardless of the
order the options happen to be typed on the command line, since Stata's own option parsing does
not preserve that order to begin with). A term that expands into several coefficients (e.g.
{opt nodefactor()} with $k$ categories, or {opt degree(2 3 4)}) consumes that many consecutive
entries from {opt theta()}, in the same left-to-right order its own levels/values are listed.
There is no per-term coefficient sub-option, by design, so this exactly reuses the same
term-construction code {cmd:nwergm}'s own estimation path uses rather than a parallel
implementation.

{pstd}
{bf:The resulting simulated network's own dataset does not carry the caller's covariate
variable(s) forward.} Each simulated draw is built via a fresh {cmd:nwset} call that replaces
the active dataset with just that network's own bare node/edge structure - any covariate
variable read during term construction is captured once, in Mata, before that replacement
happens, and is not itself part of the simulated result. Regenerate it afterward (by node
index, since simulated node identity is always {cmd:1}..{it:nodes} in the caller's original row
order) if a postestimation step - e.g. checking the resulting network's own mixing pattern -
needs it alongside the simulated network.

{pstd}
{opt nsim(int)} (default 1) draws that many independent networks (a fresh burn-in for each,
matching {cmd:nwergm}'s own control conventions rather than continuing one long chain), named
{opt generate()}{cmd:_1}, {opt generate()}{cmd:_2}, ... when {opt nsim()}{cmd: > 1} (default stub
{cmd:ergmsim}), or plain {opt generate()} (default {cmd:ergmsim}) when {opt nsim(1)}.

{title:See also}

	{help nwqap}, {help nwrandom}, {help nwcug}, {help nw_intro##limits:feasible network sizes}

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
		GWESPFREE(string) GWDEGREEFREE(string) GWDSPFREE(string) ///
		DEGREE(string) ODEGREE(string) IDEGREE(string) CONCURRENT TRIANGLE CTRIPLE ///
		NODEIFACTOR(string) NODEOFACTOR(string) ///
		KSTAR(string) ISTAR(string) OSTAR(string) ///
		DEGRANGE(string) DEGRANGETO(string) ODEGRANGE(string) ODEGRANGETO(string) ///
		IDEGRANGE(string) IDEGRANGETO(string) ESP(string) DSP(string) ///
		TRANSITIVETIES CYCLICALTIES HAMMING(string) SENDER RECEIVER ///
		TYPE(string) ///
		METHOD(string) MCMCBURNIN(integer 3000) MCMCINTERVAL(integer 50) ///
		MCMCSAMPLESIZE(integer 3000) MCMLEITERATIONS(integer 20) ///
		PROPOSAL(string) SEED(integer -1) VERBOSE SPCACHE ]
	set more off

	if "`edges'" == "" {
		di "{err}option {bf:edges} is required - every v1 nwergm model includes an edges term."
		error 198
	}
	if "`proposal'" == "" local proposal "tnt"
	_opts_oneof "uniform tnt" "proposal" "`proposal'" 6556
	if "`method'" != "" {
		_opts_oneof "mple mcmle" "method" "`method'" 6556
	}
	local __ergm_type_explicit = ("`type'" != "")
	local type = upper("`type'")
	if "`type'" == "" local type "OTP"
	_opts_oneof "OTP ITP OSP ISP RTP" "type" "`type'" 6556

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
		di "{err}nwergm never silently dichotomizes tie values or drops signs. Valued ERGMs are a separate, larger future initiative."
		error 198
	}
	if "`mutual'" != "" & "`directed'" != "true" {
		di "{err}option {bf:mutual} requires a directed network; {bf:`netname'} is undirected."
		error 198
	}
	// gwespfree() (harmonisation unit 136 MPLE, unit 138 MCMLE): curved
	// (free-decay) gwesp - the first user-facing curved term. Dyad-
	// dependent like any other gwesp-family term, so method() auto-
	// selection (below, unchanged) already picks mcmle by default and
	// mple only when explicitly requested - no special-casing needed
	// here now that both methods are actually implemented. Undirected
	// v1 scope only, matching gwesp() itself.
	if "`gwespfree'" != "" {
		if "`gwesp'" != "" {
			di "{err}options {bf:gwesp()} and {bf:gwespfree()} cannot both be specified - a gwesp term is either fixed-decay or curved (free-decay), not both."
			error 198
		}
		if "`esp'" != "" {
			di "{err}options {bf:esp()} and {bf:gwespfree()} cannot both be specified - gwespfree() already spans every achievable shared-partner count, so combining it with an explicit esp() subset would be redundant/collinear."
			error 198
		}
		if "`directed'" == "true" {
			di "{err}option {bf:gwespfree()} (v1 scope) is undirected only; {bf:`netname'} is directed. Use {bf:gwesp()} with {bf:type()} for a directed fixed-decay model - curved directed models are not yet supported."
			error 198
		}
		if `nodes' < 3 {
			di "{err}option {bf:gwespfree()} needs at least 3 nodes (gwesp itself needs a real shared-partner count to be achievable)."
			error 198
		}
		// method(mple) only, for now (harmonisation unit 138): the
		// underlying curved-MCMLE plumbing (ErgmMCMLE()'s own
		// per-iteration eta->theta snap-back, delta-method SEs,
		// missing-value degeneracy guard - unw_ergm.do) is built and
		// does not regress the non-curved path, but direct testing on
		// two independent real networks (one where R's own reference
		// implementation independently failed identically -
		// "Unconstrained MCMC sampling did not mix at all" - and a
		// second, unrelated network) both drove the chain to a 0%
		// Metropolis-Hastings acceptance rate even after adding
		// backtracking robustness to the projection step itself. This
		// is a genuinely deeper problem than a local fix - the OUTER
		// eta-space Newton step's own step-length damping (calibrated
		// for the full, unconstrained eta space) does not yet account
		// for how differently a step behaves once snapped onto the
		// much lower-dimensional curved manifold - not yet solved, so
		// not yet exposed to users. See docs/ERGM_ROADMAP.md.
		if "`method'" != "" & "`method'" != "mple" {
			di "{err}option {bf:gwespfree()} is currently estimable via {bf:method(mple)} only - curved MCMLE is built but not yet reliable enough to expose (see docs/ERGM_ROADMAP.md)."
			error 198
		}
		local method "mple"
	}
	// gwdegreefree() (harmonisation unit 139): curved (free-decay)
	// gwdegree, mirroring gwespfree()'s own exact pattern - reuses the
	// already-certified stat_degree()/change_degree() machinery
	// (degree(d)=0 always contributes exactly zero to the geometric
	// sum by construction, gw_kernel(0,alpha)=exp(alpha)*(1-1)=0
	// regardless of alpha, so d=1..(nodes-1) already covers every
	// value that can matter). method(mple) only, same reasoning as
	// gwespfree(). Undirected v1 scope only, matching gwdegree() itself.
	if "`gwdegreefree'" != "" {
		if "`gwdegree'" != "" {
			di "{err}options {bf:gwdegree()} and {bf:gwdegreefree()} cannot both be specified - a gwdegree term is either fixed-decay or curved (free-decay), not both."
			error 198
		}
		if "`gwespfree'" != "" {
			di "{err}options {bf:gwespfree()} and {bf:gwdegreefree()} cannot both be specified - v1 scope supports at most one curved term per model."
			error 198
		}
		if "`degree'" != "" {
			di "{err}options {bf:degree()} and {bf:gwdegreefree()} cannot both be specified - gwdegreefree() already spans every achievable degree value, so combining it with an explicit degree() subset would be redundant/collinear."
			error 198
		}
		if "`directed'" == "true" {
			di "{err}option {bf:gwdegreefree()} (v1 scope) is undirected only; {bf:`netname'} is directed. Use {bf:gwodegree()}/{bf:gwidegree()} for a directed fixed-decay model - curved directed models are not yet supported."
			error 198
		}
		if `nodes' < 2 {
			di "{err}option {bf:gwdegreefree()} needs at least 2 nodes."
			error 198
		}
		if "`method'" != "" & "`method'" != "mple" {
			di "{err}option {bf:gwdegreefree()} is currently estimable via {bf:method(mple)} only - curved MCMLE is built but not yet reliable enough to expose (see docs/ERGM_ROADMAP.md)."
			error 198
		}
		local method "mple"
	}
	// gwdspfree() (harmonisation unit 140): curved (free-decay)
	// gwdsp, mirroring gwespfree()'s/gwdegreefree()'s own exact
	// pattern - reuses the already-certified stat_dsp()/change_dsp()
	// machinery directly. Unlike gwesp's own d=1..(nodes-2) range,
	// gwdsp examines shared partners over EVERY dyad (tied or not),
	// but the achievable shared-partner COUNT for any one dyad is
	// still bounded by nodes-2 (every other node is a candidate
	// shared partner) - same maxd formula as gwespfree(), different
	// underlying dyad universe. method(mple) only, same reasoning as
	// the other two curved options. Undirected v1 scope only, matching
	// gwdsp() itself.
	if "`gwdspfree'" != "" {
		if "`gwdsp'" != "" {
			di "{err}options {bf:gwdsp()} and {bf:gwdspfree()} cannot both be specified - a gwdsp term is either fixed-decay or curved (free-decay), not both."
			error 198
		}
		if "`gwespfree'" != "" | "`gwdegreefree'" != "" {
			di "{err}option {bf:gwdspfree()} cannot be combined with {bf:gwespfree()} or {bf:gwdegreefree()} - v1 scope supports at most one curved term per model."
			error 198
		}
		if "`dsp'" != "" {
			di "{err}options {bf:dsp()} and {bf:gwdspfree()} cannot both be specified - gwdspfree() already spans every achievable shared-partner count, so combining it with an explicit dsp() subset would be redundant/collinear."
			error 198
		}
		if "`directed'" == "true" {
			di "{err}option {bf:gwdspfree()} (v1 scope) is undirected only; {bf:`netname'} is directed. Use {bf:gwdsp()} with {bf:type()} for a directed fixed-decay model - curved directed models are not yet supported."
			error 198
		}
		if `nodes' < 3 {
			di "{err}option {bf:gwdspfree()} needs at least 3 nodes (gwdsp itself needs a real shared-partner count to be achievable)."
			error 198
		}
		if "`method'" != "" & "`method'" != "mple" {
			di "{err}option {bf:gwdspfree()} is currently estimable via {bf:method(mple)} only - curved MCMLE is built but not yet reliable enough to expose (see docs/ERGM_ROADMAP.md)."
			error 198
		}
		local method "mple"
	}
	if ("`nodeicov'" != "" | "`nodeocov'" != "") & "`directed'" != "true" {
		di "{err}options {bf:nodeicov()}/{bf:nodeocov()} require a directed network; {bf:`netname'} is undirected."
		error 198
	}
	// gwesp()/gwdsp()/gwnsp()/esp()/dsp() now support directed networks
	// too (harmonisation unit 91) via one of five directed shared-
	// partner definitions - OTP ("outgoing two-path", i->k->j, R ergm's
	// own default), ITP ("incoming two-path", i<-k<-j), OSP ("outgoing
	// shared partner", i->k<-j), ISP ("incoming shared partner",
	// i<-k->j), or RTP ("reciprocated two-path", i<->k<->j - a shared
	// partner only through a mutual tie on each leg) - selected by the
	// shared `type()' option and applied uniformly to every one of these
	// five terms present in the same model (a per-term `type=' the way R
	// ergm's own arglist allows is not offered - nwergm's own
	// option-string convention for these terms is already just a bare
	// decay/numlist, not a nested sub-syntax, and one shared-partner
	// definition per model covers the realistic use case without that
	// added parsing complexity). `nwergm.ado' sets `td.sptype' to the
	// resolved `type' automatically for these terms whenever
	// `directed'=="true", leaving the undirected/UTP path (`td.sptype'
	// left blank) completely untouched for undirected networks -
	// matching R ergm's own documented override ("if and only if the
	// network is undirected, the UTP routine is used ... irrespective of
	// the user's selection"). All five directed types R ergm itself
	// offers are now implemented - none remain outstanding.
	if `__ergm_type_explicit' & "`directed'" != "true" {
		di "{err}note: option {bf:type()} only affects directed networks; {bf:`netname'} is undirected, so the undirected shared-partner definition is used regardless."
	}
	if `__ergm_type_explicit' & "`gwesp'`gwdsp'`gwnsp'`esp'`dsp'" == "" {
		di "{err}note: option {bf:type()} has no effect - no {bf:gwesp()}/{bf:gwdsp()}/{bf:gwnsp()}/{bf:esp()}/{bf:dsp()} term was requested."
	}
	if ("`gwodegree'" != "" | "`gwidegree'" != "") & "`directed'" != "true" {
		di "{err}options {bf:gwodegree()}/{bf:gwidegree()} require a directed network; {bf:`netname'} is undirected. Use {bf:gwdegree()} for an undirected network."
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
	if ("`nodeifactor'" != "" | "`nodeofactor'" != "") & "`directed'" != "true" {
		di "{err}options {bf:nodeifactor()}/{bf:nodeofactor()} require a directed network; {bf:`netname'} is undirected. Use {bf:nodefactor()} for an undirected network."
		error 198
	}
	if "`kstar'" != "" & "`directed'" == "true" {
		di "{err}option {bf:kstar()} is undirected only; {bf:`netname'} is directed. Use {bf:ostar()}/{bf:istar()} for a directed network."
		error 198
	}
	if ("`ostar'" != "" | "`istar'" != "") & "`directed'" != "true" {
		di "{err}options {bf:ostar()}/{bf:istar()} require a directed network; {bf:`netname'} is undirected. Use {bf:kstar()} for an undirected network."
		error 198
	}
	if "`degrange'" != "" & "`directed'" == "true" {
		di "{err}option {bf:degrange()} is undirected only; {bf:`netname'} is directed. Use {bf:odegrange()}/{bf:idegrange()} for a directed network."
		error 198
	}
	if ("`odegrange'" != "" | "`idegrange'" != "") & "`directed'" != "true" {
		di "{err}options {bf:odegrange()}/{bf:idegrange()} require a directed network; {bf:`netname'} is undirected. Use {bf:degrange()} for an undirected network."
		error 198
	}
	// esp()/dsp() now support directed networks too (wave 5) via the
	// same automatic OTP default as gwesp()/gwdsp()/gwnsp() above.
	if ("`transitiveties'" != "" | "`cyclicalties'" != "") & "`directed'" != "true" {
		di "{err}options {bf:transitiveties}/{bf:cyclicalties} require a directed network; {bf:`netname'} is undirected."
		error 198
	}
	if ("`sender'" != "" | "`receiver'" != "") & "`directed'" != "true" {
		di "{err}options {bf:sender}/{bf:receiver} require a directed network; {bf:`netname'} is undirected."
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

	// --- spcache (Part XXV performance work, docs/CERTIFICATION.md unit
	// 82/132): the incremental shared-partner cache exists and is fully
	// certified, but is NOT auto-enabled by default - unit 82's own
	// direct A/B benchmarking found it a NET LOSS below roughly degree
	// 30-40 (the realistic case for most fitted sparse models, where
	// TNT's high acceptance rate makes the cache's own per-toggle
	// maintenance cost dominate its O(1) lookup savings). This is the
	// disclosed, deliberate opt-in the roadmap called for: the user, who
	// knows their own network's density, decides. Only the undirected
	// shared-partner definition (`shared_partners()') is cached - the
	// directed OTP/ITP/OSP/ISP/RTP paths use their own dedicated,
	// uncached primitives (see their own header comments), so the option
	// has no effect on a directed network. Applies to BOTH MPLE and
	// MCMLE fits (build_mple_data() toggles the same __nwergm_last_G
	// singleton the MCMC sampler uses, so MPLE's own design-matrix
	// construction benefits identically), even though only the MCMLE
	// branch below surfaces e(spcache) - matching e(native)'s own
	// existing MPLE-vs-MCMLE asymmetry (assert missing(e(native)) for
	// MPLE fits, cscripts/test_nwergm_ado.do).
	local __ergm_spcache_relevant = ("`gwesp'"!="" | "`gwdsp'"!="" | "`gwnsp'"!="" | "`esp'"!="" | "`dsp'"!="" | "`triangle'"!="" | "`ctriple'"!="")
	local __ergm_spcache_used = 0
	if "`spcache'" != "" {
		if "`directed'" == "true" {
			di "{err}note: option {bf:spcache} has no effect on a directed network; the incremental shared-partner cache only implements the undirected shared-partner definition."
		}
		else if !`__ergm_spcache_relevant' {
			di "{err}note: option {bf:spcache} has no effect without gwesp()/gwdsp()/gwnsp()/esp()/dsp()/triangle/ctriple; none of those terms was requested."
		}
		else {
			mata: __nwergm_last_G.enable_sp_cache()
			local __ergm_spcache_used = 1
		}
	}

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
		mata: `__td_nf`__ergm_termidx''.levels = _ergm_drop_base_level(`__td_nf`__ergm_termidx''.levels)
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

	// --- term-expansion wave 3 (harmonisation unit 91): nodeifactor()/
	// nodeofactor() (directed analogues of nodefactor(), same base-level
	// omission), kstar()/istar()/ostar() (general k-star family, k as a
	// numlist), degrange()/odegrange()/idegrange() (semi-open-interval
	// degree counts, from()/to() as paired numlists).
	local __ergm_termidx = 0
	foreach __ergm_v of local nodeofactor {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_nof`__ergm_termidx'
		mata: `__td_nof`__ergm_termidx'' = ErgmTermData()
		mata: `__td_nof`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: `__td_nof`__ergm_termidx''.levels = uniqrows(`__td_nof`__ergm_termidx''.attr)
		mata: `__td_nof`__ergm_termidx''.levels = _ergm_drop_base_level(`__td_nof`__ergm_termidx''.levels)
		mata: st_local("__ergm_nlev", strofreal(rows(`__td_nof`__ergm_termidx''.levels)))
		tempname __ergm_levvec3
		mata: st_matrix("`__ergm_levvec3'", `__td_nof`__ergm_termidx''.levels')
		local __ergm_cnames ""
		forvalues __k = 1/`__ergm_nlev' {
			local __ergm_cnames "`__ergm_cnames' nodeofactor_`__ergm_v'_`=`__ergm_levvec3'[1,`__k']''"
		}
		mata: __nwergm_last_M.addterm("nodeofactor", `__ergm_nlev', &stat_nodeofactor(), &change_nodeofactor(), `__td_nof`__ergm_termidx'', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_nof`__ergm_termidx''"
	}
	local __ergm_termidx = 0
	foreach __ergm_v of local nodeifactor {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_nif`__ergm_termidx'
		mata: `__td_nif`__ergm_termidx'' = ErgmTermData()
		mata: `__td_nif`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: `__td_nif`__ergm_termidx''.levels = uniqrows(`__td_nif`__ergm_termidx''.attr)
		mata: `__td_nif`__ergm_termidx''.levels = _ergm_drop_base_level(`__td_nif`__ergm_termidx''.levels)
		mata: st_local("__ergm_nlev", strofreal(rows(`__td_nif`__ergm_termidx''.levels)))
		tempname __ergm_levvec4
		mata: st_matrix("`__ergm_levvec4'", `__td_nif`__ergm_termidx''.levels')
		local __ergm_cnames ""
		forvalues __k = 1/`__ergm_nlev' {
			local __ergm_cnames "`__ergm_cnames' nodeifactor_`__ergm_v'_`=`__ergm_levvec4'[1,`__k']''"
		}
		mata: __nwergm_last_M.addterm("nodeifactor", `__ergm_nlev', &stat_nodeifactor(), &change_nodeifactor(), `__td_nif`__ergm_termidx'', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_nif`__ergm_termidx''"
	}

	if "`kstar'" != "" {
		tempname __td_kstar
		mata: `__td_kstar' = ErgmTermData()
		mata: `__td_kstar'.levels = strtoreal(tokens("`kstar'"))'
		mata: st_local("__ergm_nk", strofreal(rows(`__td_kstar'.levels)))
		local __ergm_cnames ""
		foreach __ergm_kv of numlist `kstar' {
			local __ergm_cnames "`__ergm_cnames' kstar_`__ergm_kv'"
		}
		mata: __nwergm_last_M.addterm("kstar", `__ergm_nk', &stat_kstar(), &change_kstar(), `__td_kstar', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_kstar'"
	}
	if "`ostar'" != "" {
		tempname __td_ostar
		mata: `__td_ostar' = ErgmTermData()
		mata: `__td_ostar'.levels = strtoreal(tokens("`ostar'"))'
		mata: st_local("__ergm_nk", strofreal(rows(`__td_ostar'.levels)))
		local __ergm_cnames ""
		foreach __ergm_kv of numlist `ostar' {
			local __ergm_cnames "`__ergm_cnames' ostar_`__ergm_kv'"
		}
		mata: __nwergm_last_M.addterm("ostar", `__ergm_nk', &stat_ostar(), &change_ostar(), `__td_ostar', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_ostar'"
	}
	if "`istar'" != "" {
		tempname __td_istar
		mata: `__td_istar' = ErgmTermData()
		mata: `__td_istar'.levels = strtoreal(tokens("`istar'"))'
		mata: st_local("__ergm_nk", strofreal(rows(`__td_istar'.levels)))
		local __ergm_cnames ""
		foreach __ergm_kv of numlist `istar' {
			local __ergm_cnames "`__ergm_cnames' istar_`__ergm_kv'"
		}
		mata: __nwergm_last_M.addterm("istar", `__ergm_nk', &stat_istar(), &change_istar(), `__td_istar', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_istar'"
	}

	if "`degrange'" != "" {
		local __ergm_ndr : word count `degrange'
		if "`degrangeto'" == "" {
			local __ergm_dto ""
			forvalues __k = 1/`__ergm_ndr' {
				local __ergm_dto "`__ergm_dto' ."
			}
		}
		else {
			local __ergm_dto "`degrangeto'"
			local __ergm_ndto : word count `degrangeto'
			if `__ergm_ndto' != `__ergm_ndr' {
				di "{err}degrange() and degrangeto() must supply the same number of values."
				error 198
			}
		}
		tempname __td_dr
		mata: `__td_dr' = ErgmTermData()
		mata: `__td_dr'.levelpairs = strtoreal(tokens("`degrange'"))' , strtoreal(tokens("`__ergm_dto'"))'
		local __ergm_cnames ""
		forvalues __k = 1/`__ergm_ndr' {
			local __ergm_cnames "`__ergm_cnames' degrange_`__k'"
		}
		mata: __nwergm_last_M.addterm("degrange", `__ergm_ndr', &stat_degrange(), &change_degrange(), `__td_dr', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_dr'"
	}
	if "`odegrange'" != "" {
		local __ergm_ndr : word count `odegrange'
		if "`odegrangeto'" == "" {
			local __ergm_dto ""
			forvalues __k = 1/`__ergm_ndr' {
				local __ergm_dto "`__ergm_dto' ."
			}
		}
		else {
			local __ergm_dto "`odegrangeto'"
			local __ergm_ndto : word count `odegrangeto'
			if `__ergm_ndto' != `__ergm_ndr' {
				di "{err}odegrange() and odegrangeto() must supply the same number of values."
				error 198
			}
		}
		tempname __td_odr
		mata: `__td_odr' = ErgmTermData()
		mata: `__td_odr'.levelpairs = strtoreal(tokens("`odegrange'"))' , strtoreal(tokens("`__ergm_dto'"))'
		local __ergm_cnames ""
		forvalues __k = 1/`__ergm_ndr' {
			local __ergm_cnames "`__ergm_cnames' odegrange_`__k'"
		}
		mata: __nwergm_last_M.addterm("odegrange", `__ergm_ndr', &stat_odegrange(), &change_odegrange(), `__td_odr', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_odr'"
	}
	if "`idegrange'" != "" {
		local __ergm_ndr : word count `idegrange'
		if "`idegrangeto'" == "" {
			local __ergm_dto ""
			forvalues __k = 1/`__ergm_ndr' {
				local __ergm_dto "`__ergm_dto' ."
			}
		}
		else {
			local __ergm_dto "`idegrangeto'"
			local __ergm_ndto : word count `idegrangeto'
			if `__ergm_ndto' != `__ergm_ndr' {
				di "{err}idegrange() and idegrangeto() must supply the same number of values."
				error 198
			}
		}
		tempname __td_idr
		mata: `__td_idr' = ErgmTermData()
		mata: `__td_idr'.levelpairs = strtoreal(tokens("`idegrange'"))' , strtoreal(tokens("`__ergm_dto'"))'
		local __ergm_cnames ""
		forvalues __k = 1/`__ergm_ndr' {
			local __ergm_cnames "`__ergm_cnames' idegrange_`__k'"
		}
		mata: __nwergm_last_M.addterm("idegrange", `__ergm_ndr', &stat_idegrange(), &change_idegrange(), `__td_idr', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_idr'"
	}

	// --- term-expansion wave 4 (harmonisation unit 91 continuation):
	// esp(d)/dsp(d), fixed non-geometric shared-partner-count terms.
	// Wave 5 extended these (and gwesp/gwdsp/gwnsp below) to directed
	// networks via R ergm's own default directed shared-partner
	// definition (OTP) - `td.sptype' is set to "OTP" automatically
	// whenever the network is directed, left blank (UTP) otherwise.
	if "`esp'" != "" {
		local __ergm_nd : word count `esp'
		tempname __td_esp
		mata: `__td_esp' = ErgmTermData()
		mata: `__td_esp'.levels = strtoreal(tokens("`esp'"))'
		if "`directed'" == "true" {
			mata: `__td_esp'.sptype = "`type'"
		}
		local __ergm_cnames ""
		foreach __ergm_dv of numlist `esp' {
			local __ergm_cnames "`__ergm_cnames' esp`__ergm_dv'"
		}
		mata: __nwergm_last_M.addterm("esp", `__ergm_nd', &stat_esp(), &change_esp(), `__td_esp', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_esp'"
	}
	if "`dsp'" != "" {
		local __ergm_nd : word count `dsp'
		tempname __td_dsp
		mata: `__td_dsp' = ErgmTermData()
		mata: `__td_dsp'.levels = strtoreal(tokens("`dsp'"))'
		if "`directed'" == "true" {
			mata: `__td_dsp'.sptype = "`type'"
		}
		local __ergm_cnames ""
		foreach __ergm_dv of numlist `dsp' {
			local __ergm_cnames "`__ergm_cnames' dsp`__ergm_dv'"
		}
		mata: __nwergm_last_M.addterm("dsp", `__ergm_nd', &stat_dsp(), &change_dsp(), `__td_dsp', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_dsp'"
	}

	// --- term-expansion wave 6 (harmonisation unit 91 continuation):
	// transitiveties/cyclicalties, directed-only, built on wave 5's OTP
	// shared-partner machinery.
	if "`transitiveties'" != "" {
		tempname __td_tt
		mata: `__td_tt' = ErgmTermData()
		mata: __nwergm_last_M.addterm("transitiveties", 1, &stat_transitiveties(), &change_transitiveties(), `__td_tt', ("transitiveties"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_tt'"
	}
	if "`cyclicalties'" != "" {
		tempname __td_ct
		mata: `__td_ct' = ErgmTermData()
		mata: __nwergm_last_M.addterm("cyclicalties", 1, &stat_cyclicalties(), &change_cyclicalties(), `__td_ct', ("cyclicalties"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_ct'"
	}

	// --- term-expansion wave 7 (harmonisation unit 91 continuation):
	// sender()/receiver() (per-node out-/in-degree fixed effects, base=1
	// omitted, matching R ergm's own default) - a thin convenience
	// wrapper: the node's own identity (1..nodes) IS the "attribute",
	// reusing the already-certified stat_nodeofactor()/stat_nodeifactor()
	// with zero new Mata code.
	if "`sender'" != "" {
		tempname __td_send
		mata: `__td_send' = ErgmTermData()
		mata: `__td_send'.attr = (1::`nodes')
		mata: `__td_send'.levels = (2::`nodes')
		local __ergm_cnames ""
		forvalues __k = 2/`nodes' {
			local __ergm_cnames "`__ergm_cnames' sender`__k'"
		}
		mata: __nwergm_last_M.addterm("sender", `nodes'-1, &stat_nodeofactor(), &change_nodeofactor(), `__td_send', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_send'"
	}
	if "`receiver'" != "" {
		tempname __td_recv
		mata: `__td_recv' = ErgmTermData()
		mata: `__td_recv'.attr = (1::`nodes')
		mata: `__td_recv'.levels = (2::`nodes')
		local __ergm_cnames ""
		forvalues __k = 2/`nodes' {
			local __ergm_cnames "`__ergm_cnames' receiver`__k'"
		}
		mata: __nwergm_last_M.addterm("receiver", `nodes'-1, &stat_nodeifactor(), &change_nodeifactor(), `__td_recv', tokens("`__ergm_cnames'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_recv'"
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

	// --- hamming(netname): Hamming distance to a reference network,
	// same nw_syntax()-based network-name resolution as edgecov() above,
	// but a BINARY reference (get_matrix_mod(0,...), not (1,...) -
	// hamming distance cares only about tie/no-tie agreement, not
	// covariate weight).
	local __ergm_termidx = 0
	foreach __ergm_v of local hamming {
		local ++__ergm_termidx
		tempname __td_hm`__ergm_termidx'
		mata: `__td_hm`__ergm_termidx'' = ErgmTermData()
		nw_syntax `__ergm_v', max(1) other(hm`__ergm_termidx')
		if `hm`__ergm_termidx'nodes' != `nodes' {
			di "{err}hamming() network {bf:`__ergm_v'} has a different number of nodes than {bf:`netname'}."
			error 198
		}
		mata: `__td_hm`__ergm_termidx''.edgecovmat = *(`hm`__ergm_termidx'netobj'->get_matrix_mod(0,("`directed'"=="true")))
		mata: __nwergm_last_M.addterm("hamming", 1, &stat_hamming(), &change_hamming(), `__td_hm`__ergm_termidx'', ("hamming_`__ergm_v'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_hm`__ergm_termidx''"
	}

	if "`gwesp'" != "" {
		confirm number `gwesp'
		tempname __td_gwesp
		mata: `__td_gwesp' = ErgmTermData()
		mata: `__td_gwesp'.decay = `gwesp'
		if "`directed'" == "true" {
			mata: `__td_gwesp'.sptype = "`type'"
		}
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
		if "`directed'" == "true" {
			mata: `__td_gwdsp'.sptype = "`type'"
		}
		mata: __nwergm_last_M.addterm("gwdsp", 1, &stat_gwdsp(), &change_gwdsp(), `__td_gwdsp', ("gwdsp_`gwdsp'"))
		local __ergm_matatemps "`__ergm_matatemps' `__td_gwdsp'"
	}
	if "`gwnsp'" != "" {
		confirm number `gwnsp'
		tempname __td_gwnsp
		mata: `__td_gwnsp' = ErgmTermData()
		mata: `__td_gwnsp'.decay = `gwnsp'
		if "`directed'" == "true" {
			mata: `__td_gwnsp'.sptype = "`type'"
		}
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
	// gwespfree() (harmonisation unit 136): registered as a curved
	// `esp' term spanning EVERY achievable shared-partner count
	// 1..(nodes-2) - reusing the already-certified stat_esp()/
	// change_esp() machinery directly, not new statistic/change code
	// (curved-ness is an estimation-side property, not a per-term one -
	// see unw_ergm.do's own ErgmModel::curved comment). Deliberately
	// registered LAST (after every other term) so its own 2 theta
	// columns are always the final 2 in theta-space regardless of what
	// else is in the model - the MPLE code below relies on this to
	// build a starting theta without needing a general "find this
	// term's own theta position" accessor.
	if "`gwespfree'" != "" {
		confirm number `gwespfree'
		local __ergm_curved_maxd = `nodes' - 2
		tempname __td_gwespfree
		mata: `__td_gwespfree' = ErgmTermData()
		mata: `__td_gwespfree'.levels = (1..`__ergm_curved_maxd')'
		// addterm()'s own cnames must have length npar (here
		// __ergm_curved_maxd, the ETA-space dimension - one name per
		// achievable shared-partner count) - NOT the 2-dimensional
		// THETA-space this term is ultimately reported in. These names
		// are internal/intermediate only (never shown to the user - the
		// MPLE code below replaces the whole coefficient vector with
		// the 2 theta-space names "gwesp_weight"/"gwesp_decay" before
		// ereturn post), given a distinct "gwespfree_" prefix so they
		// cannot collide with an ordinary esp() term's own "espN" names
		// in any diagnostic that displays them before that replacement.
		local __ergm_curved_cnames ""
		forvalues __k = 1/`__ergm_curved_maxd' {
			local __ergm_curved_cnames "`__ergm_curved_cnames' gwespfree_`__k'"
		}
		mata: __nwergm_last_M.addterm("esp", `__ergm_curved_maxd', &stat_esp(), &change_esp(), `__td_gwespfree', tokens("`__ergm_curved_cnames'"))
		mata: __nwergm_last_M.mark_curved()
		local __ergm_matatemps "`__ergm_matatemps' `__td_gwespfree'"
	}
	// gwdegreefree() (harmonisation unit 139): mirrors gwespfree()'s
	// own exact pattern, registered under "degree" (reusing
	// stat_degree()/change_degree() directly) spanning every
	// achievable degree value 1..(nodes-1) - d=0 is safe to omit
	// entirely, since gw_kernel(0,alpha)=exp(alpha)*(1-1)=0 for any
	// alpha, so it can never contribute to the geometric sum. Also
	// registered LAST (after gwespfree(), which the mutual-exclusivity
	// check above guarantees cannot coexist with this one anyway), for
	// the same "always the final 2 theta columns" reason gwespfree()
	// documents at its own registration site.
	if "`gwdegreefree'" != "" {
		confirm number `gwdegreefree'
		local __ergm_curved_maxd = `nodes' - 1
		tempname __td_gwdegreefree
		mata: `__td_gwdegreefree' = ErgmTermData()
		mata: `__td_gwdegreefree'.levels = (1..`__ergm_curved_maxd')'
		local __ergm_curved_cnames ""
		forvalues __k = 1/`__ergm_curved_maxd' {
			local __ergm_curved_cnames "`__ergm_curved_cnames' gwdegreefree_`__k'"
		}
		mata: __nwergm_last_M.addterm("degree", `__ergm_curved_maxd', &stat_degree(), &change_degree(), `__td_gwdegreefree', tokens("`__ergm_curved_cnames'"))
		mata: __nwergm_last_M.mark_curved()
		local __ergm_matatemps "`__ergm_matatemps' `__td_gwdegreefree'"
	}
	// gwdspfree() (harmonisation unit 140): mirrors the other two
	// curved options' own exact pattern, registered under "dsp"
	// (reusing stat_dsp()/change_dsp() directly).
	if "`gwdspfree'" != "" {
		confirm number `gwdspfree'
		local __ergm_curved_maxd = `nodes' - 2
		tempname __td_gwdspfree
		mata: `__td_gwdspfree' = ErgmTermData()
		mata: `__td_gwdspfree'.levels = (1..`__ergm_curved_maxd')'
		local __ergm_curved_cnames ""
		forvalues __k = 1/`__ergm_curved_maxd' {
			local __ergm_curved_cnames "`__ergm_curved_cnames' gwdspfree_`__k'"
		}
		mata: __nwergm_last_M.addterm("dsp", `__ergm_curved_maxd', &stat_dsp(), &change_dsp(), `__td_gwdspfree', tokens("`__ergm_curved_cnames'"))
		mata: __nwergm_last_M.mark_curved()
		local __ergm_matatemps "`__ergm_matatemps' `__td_gwdspfree'"
	}

	// Unified curved-model flag/starting-value (harmonisation unit
	// 139): v1 scope allows at most one curved term per model (the
	// mutual-exclusivity checks above enforce this), so exactly one of
	// `gwespfree'/`gwdegreefree' can be non-empty at this point -
	// `__ergm_curved' and `__ergm_curved_start' let every downstream
	// curved-path branch (MPLE fit, e(curved), MCMLE gating) check ONE
	// flag instead of repeating "gwespfree() OR gwdegreefree()"
	// everywhere.
	local __ergm_curved = ("`gwespfree'" != "" | "`gwdegreefree'" != "" | "`gwdspfree'" != "")
	if "`gwespfree'" != "" local __ergm_curved_start "`gwespfree'"
	else if "`gwdegreefree'" != "" local __ergm_curved_start "`gwdegreefree'"
	else local __ergm_curved_start "`gwdspfree'"

	// dyad-independent iff only edges/nodematch/nodecov/nodeicov/nodeocov/
	// edgecov/absdist/nodematchdiff/nodefactor/nodemix are present (mutual
	// and every geometrically-weighted term, including gwdsp/gwnsp, are
	// dyad-dependent - gwdsp/gwnsp no less than gwesp, since shared-
	// partner counts are just as nonlocal for untied dyads as for tied
	// ones; degree()/odegree()/idegree()/concurrent/triangle/ctriple are
	// ALSO dyad-dependent - unit 90 - since each depends on more than
	// just its own two endpoints' attributes, via other nodes' degrees
	// or shared third parties).
	// nodeofactor()/nodeifactor() are dyad-independent (like nodefactor -
	// their change stat depends only on the toggled dyad's own endpoint
	// attribute, not on other dyads' state), so they are deliberately
	// excluded from this check. kstar/ostar/istar/degrange/odegrange/
	// idegrange are all degree-based and so are dyad-dependent (wave 3).
	local __ergm_dind = (`"`mutual'"'=="" & `"`gwesp'"'=="" & `"`gwdsp'"'=="" & `"`gwnsp'"'=="" & `"`gwdegree'"'=="" & `"`gwodegree'"'=="" & `"`gwidegree'"'=="" & `"`degree'"'=="" & `"`odegree'"'=="" & `"`idegree'"'=="" & `"`concurrent'"'=="" & `"`triangle'"'=="" & `"`ctriple'"'=="" & `"`kstar'"'=="" & `"`ostar'"'=="" & `"`istar'"'=="" & `"`degrange'"'=="" & `"`odegrange'"'=="" & `"`idegrange'"'=="" & `"`esp'"'=="" & `"`dsp'"'=="" & "`transitiveties'"=="" & "`cyclicalties'"=="" & "`gwespfree'"=="" & "`gwdegreefree'"=="" & "`gwdspfree'"=="")
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

	tempname __b_mple __V_mple
	// Curved gwesp (harmonisation unit 136): fit directly in THETA-space
	// via ErgmCurvedMPLEFit() (unw_ergm.do) - Newton-Raphson/Fisher
	// scoring on the SAME pseudolikelihood the ordinary closed-form
	// `logit' call below maximizes, chain-ruled through the certified
	// theta_to_eta()/theta_to_eta_jacobian() (units 133-134). This
	// replaces `logit' entirely for a curved model (fits every
	// coefficient, ordinary and curved, jointly in one loop) rather
	// than running `logit' and then transforming its result - a first
	// version of this feature did exactly that (fit the unconstrained
	// eta MLE via `logit', then project down to theta), and direct
	// testing against R on a well-identified 15-node network found it
	// landing at a materially different, wrong-signed local point -
	// see ErgmCurvedMPLEFit()'s own header comment for the full
	// account of why directly optimizing the true objective is the
	// correct fix, not a patch on the old approach. Whichever curved
	// term is present (harmonisation unit 139 generalized this from
	// gwespfree() alone to gwespfree()/gwdegreefree()), its own
	// weight/decay theta columns are always the LAST 2 (registered
	// last, by construction - see its own addterm() call above), so a
	// starting theta of (0-vector, weight0=0, decay0=`__ergm_curved_start')
	// is built directly rather than needing a general "find this term's
	// own theta position" accessor.
	if `__ergm_curved' {
		tempname __ergm_curvedconv
		mata: __ergm_theta_start = (J(1, __nwergm_last_M.ntheta()-2, 0), 0, `__ergm_curved_start')
		mata: ErgmCurvedMPLEFit(__nwergm_last_M, `__nw_D', __ergm_theta_start, 100, 1e-10, "`__b_mple'", "`__V_mple'", "`__ergm_curvedconv'")
		mata: mata drop __ergm_theta_start
		mata: st_local("__ergm_curved_converged", strofreal(st_matrix("`__ergm_curvedconv'")[1,1]))
		mata: st_local("__ergm_coefnames", invtokens(__nwergm_last_M.theta_coefnames()))
		if `__ergm_curved_converged' == 0 {
			di "{err}note: the curved MPLE fit did not converge within 100 Newton-Raphson iterations - treat these results with caution."
		}
	}
	else {
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

		// BUGFIX: a fully edgeless (zero-tie) network - an MPLE fit
		// where the outcome never varies - used to crash completely
		// silently (only "r(2000);", no explanatory text at all) from
		// this bare, uncaptured `logit' call, unlike this command's
		// otherwise consistently friendly "{err}...{txt}" validation
		// messages for every other rejected input. `restore' still
		// needs to run regardless of failure, or a caught error here
		// would leave the caller's own dataset in the modified,
		// mid-preserve state (the same class of bug already fixed once
		// in nwrename.ado this same pass).
		capture qui logit __ergm_y `__ergm_xlist', noconstant
		if _rc != 0 {
			local __ergm_mple_rc = _rc
			restore
			di "{err}The MPLE fit did not converge (outcome does not vary - e.g. a fully edgeless network with no ties at all). Cannot estimate this model."
			error `__ergm_mple_rc'
		}
		matrix `__b_mple' = e(b)
		matrix `__V_mple' = e(V)
		restore
	}

	if "`method'" == "mple" {
		// logit's own e(b)/e(V) (non-curved path only - the curved
		// path's own ErgmCurvedMPLEFit() posts plain, unstriped
		// matrices directly) carry an equation-name stripe (the
		// depvar's own name, e.g. "__ergm_y:__ergm_x1") - blanked
		// explicitly before assigning fresh colnames/rownames, or a
		// stale/mismatched stripe between b and V makes `ereturn post`
		// fail with a "name conflict" (r(507)) - the exact same bug
		// class already found and fixed once in nwqap.ado (see its own
		// header comment). Harmless no-op on the curved path's own
		// already-unstriped matrices.
		capture matrix coleq `__b_mple' = _
		capture matrix coleq `__V_mple' = _
		capture matrix roweq `__V_mple' = _
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
		ereturn scalar curved = `__ergm_curved'

		nwergm_display "`netname'" "`nodes'" "`directed'" "MPLE" "" ""
		if `__ergm_curved' {
			di "{txt}Note: {bf:decay} is an ESTIMATED (curved) parameter here, fit via Newton-Raphson directly on the pseudolikelihood in theta-space - not expected to be bit-identical to R ergm's own BFGS-based curved MPLE (a different exact optimization path to the same objective), but should agree closely on a well-identified model."
		}
	}
	else {
		tempname __theta0
		// Curved gwesp (harmonisation unit 138): `__b_mple' is now
		// THETA-space for a curved model (unit 136's own MPLE change -
		// it reports gwesp_weight/gwesp_decay directly, not raw
		// eta-space esp() coefficients), but ErgmMCMLE() needs an
		// ETA-space starting vector (the actual MCMC sampling weight,
		// regardless of curved-ness). `__ergm_theta_c0_mcmle' - the
		// curved MPLE's own theta_hat, kept as a live Mata variable
		// rather than round-tripped through a Stata matrix - doubles
		// as ErgmMCMLE()'s own optional starting point for its
		// internal per-iteration eta->theta projection, so the MCMLE
		// loop warm-starts from the SAME point MPLE already found
		// rather than a generic (0,...,0,alpha0) restart.
		if `__ergm_curved' {
			mata: __ergm_theta_c0_mcmle = st_matrix("`__b_mple'")
			mata: `__theta0' = __nwergm_last_M.theta_to_eta(__ergm_theta_c0_mcmle)
		}
		else {
			mata: `__theta0' = st_matrix("`__b_mple'")
		}
		local __ergm_matatemps "`__ergm_matatemps' `__theta0'"

		if "`proposal'" == "tnt" {
			local __ergm_propfn "&ergm_propose_tnt()"
			local __ergm_propcode 2
		}
		else {
			local __ergm_propfn "&ergm_propose_uniform()"
			local __ergm_propcode 1
		}

		// Native (C) MCMC backend eligibility (harmonisation unit 83;
		// scope relaxed considerably, unit 91 follow-on - see
		// unw_ergm.do's own ErgmNativeSetup() header comment for the
		// full current term list) - decided ONCE here, before any MCMC
		// runs, never inside ErgmMCMLE()'s own loop. Sets
		// __nwergm_last_M.native_enabled; ErgmMCMCSample()/
		// ErgmMCMCSampleDiag() (called internally by ErgmMCMLE() below)
		// check that field themselves and fall back to the unmodified
		// Mata sampler whenever it is 0 - a model using any term outside
		// the native backend's own current scope, or a platform with no
		// compiled lib/plugins/ergm_mcmc.plugin, is completely
		// unaffected by this call. See unw_ergm.do's own "Native (C)
		// MCMC backend" section and docs/ERGM_ARCHITECTURE.md for the
		// full design.
		// BUGFIX: ErgmNativeSetup() returns real scalar (1/0, whether the
		// native backend ended up eligible) - calling it bare left Mata
		// auto-displaying that return value as a stray, unexplained "1"
		// (or "0") before anything else this command prints. The
		// eligibility flag itself is read straight off
		// __nwergm_last_M.native_enabled on the next line regardless, so
		// the return value was never actually needed here at all.
		mata: __ergm_native_setup_rc = ErgmNativeSetup(__nwergm_last_M, `__ergm_propcode')
		mata: st_local("__ergm_native_used", strofreal(__nwergm_last_M.native_enabled))
		mata: mata drop __ergm_native_setup_rc

		tempname __fit
		if `__ergm_curved' {
			mata: `__fit' = ErgmMCMLE(__nwergm_last_M, __nwergm_last_G, `__theta0', `mcmleiterations', `mcmcburnin', `mcmcinterval', `mcmcsamplesize', `__ergm_propfn', ("`verbose'"!=""), __ergm_theta_c0_mcmle)
			mata: mata drop __ergm_theta_c0_mcmle
		}
		else {
			mata: `__fit' = ErgmMCMLE(__nwergm_last_M, __nwergm_last_G, `__theta0', `mcmleiterations', `mcmcburnin', `mcmcinterval', `mcmcsamplesize', `__ergm_propfn', ("`verbose'"!=""))
		}
		local __ergm_matatemps "`__ergm_matatemps' `__fit'"

		tempname __b_mcmle __V_mcmle
		if `__ergm_curved' {
			// Curved gwesp (harmonisation unit 138): `__fit'.coef is
			// still eta-space (ErgmMCMLE() itself never reports
			// theta directly - see its own header comment); the
			// reported fit is `__fit'.coef_theta, with `__fit'.vcov
			// (eta-space) transformed via the exact same delta-method
			// formula ErgmCurvedMPLEFit() already uses internally,
			// evaluated at the converged theta rather than a
			// Newton-Raphson optimum.
			//
			// Curved MCMLE degeneracy guard: measured directly during
			// this unit's own development that a curved model CAN
			// drive the underlying MCMC chain into a genuinely
			// degenerate region (100% Metropolis-Hastings acceptance,
			// a classic stuck-chain signature) on a real test network -
			// confirmed as a genuine difficulty of the statistical
			// problem itself, not a bug specific to this
			// implementation, since R ergm's OWN reference
			// implementation independently failed outright
			// ("Unconstrained MCMC sampling did not mix at all") on
			// the identical network. Unlike R, nothing here previously
			// detected this and it silently reported a "converged"
			// fit with missing coef_theta entries cascading into a
			// nonsensical result - checked and refused explicitly now,
			// matching this project's own "never silently report a
			// wrong answer" convention, rather than chasing full
			// robustness against MCMC degeneracy (a substantially
			// larger undertaking, and one R's own mature
			// implementation does not fully solve either).
			mata: st_local("__ergm_curved_degenerate", strofreal(missing(`__fit'.coef_theta) > 0))
			if `__ergm_curved_degenerate' {
				di "{err}The curved MCMLE fit did not produce a valid result - the underlying MCMC chain likely became degenerate for this model/network combination (this is a genuine difficulty of curved-decay estimation in general, not specific to this package; R's own ergm can fail identically with 'Unconstrained MCMC sampling did not mix at all' on a hard case). Try a different starting decay value, a longer {bf:mcmcburnin()}, or a simpler model."
				error 430
			}
			mata: st_matrix("`__b_mcmle'", `__fit'.coef_theta)
			mata: __ergm_Jac_mcmle = __nwergm_last_M.theta_to_eta_jacobian(`__fit'.coef_theta)
			mata: st_matrix("`__V_mcmle'", invsym(__ergm_Jac_mcmle' * invsym(`__fit'.vcov) * __ergm_Jac_mcmle))
			mata: mata drop __ergm_Jac_mcmle
			mata: st_local("__ergm_coefnames", invtokens(__nwergm_last_M.theta_coefnames()))
		}
		else {
			mata: st_matrix("`__b_mcmle'", `__fit'.coef)
			mata: st_matrix("`__V_mcmle'", `__fit'.vcov)
		}
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
		// 1 if this model's own term list was eligible for the native
		// (C) MCMC backend and the compiled plugin was actually used for
		// this run's own simulations; 0 if the Mata sampler ran instead
		// (either because a term outside the native backend's current
		// scope was present, or no compiled plugin exists for this
		// platform) - see docs/ERGM_ARCHITECTURE.md's own "Native (C)
		// MCMC backend" section for exactly which terms are covered
		// today. Purely informational: both backends are certified
		// statistically indistinguishable (cscripts/test_nwergm_native.do)
		// and nothing about interpreting results differs based on this
		// flag - it exists so a user curious about performance can see,
		// without guessing, whether their own specific model got the
		// native speedup.
		ereturn scalar native = `__ergm_native_used'
		// 1 if the Mata incremental shared-partner cache (spcache option,
		// off by default - see this call's own build-up comment above)
		// was actually enabled for this fit, 0 otherwise. Purely
		// informational, like e(native); has no effect when e(native)==1
		// (the native backend never uses this Mata-level cache at all).
		ereturn scalar spcache = `__ergm_spcache_used'
		ereturn scalar curved = `__ergm_curved'
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
		if `__ergm_curved' {
			di "{txt}Note: {bf:decay} is an ESTIMATED (curved) parameter here. Each MCMLE iteration's own eta-space Newton-step target is projected back onto the 2-parameter (weight, decay) curved manifold before the next simulation - a disclosed simplification of R ergm's own curved-model machinery, not expected to be bit-identical to it."
		}
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
		NODEMATCH(string) NODEMATCHDIFF(string) NODECOV(string) NODEICOV(string) NODEOCOV(string) ///
		EDGECOV(string) ABSDIST(string) NODEFACTOR(string) NODEMIX(string) ///
		GWESP(real 0) GWDSP(real 0) GWNSP(real 0) GWDEGREE(real 0) GWODEGREE(real 0) GWIDEGREE(real 0) ///
		DEGREE(string) ODEGREE(string) IDEGREE(string) CONCURRENT TRIANGLE CTRIPLE ///
		NODEIFACTOR(string) NODEOFACTOR(string) ///
		KSTAR(string) ISTAR(string) OSTAR(string) ///
		DEGRANGE(string) DEGRANGETO(string) ODEGRANGE(string) ODEGRANGETO(string) ///
		IDEGRANGE(string) IDEGRANGETO(string) ESP(string) DSP(string) ///
		TRANSITIVETIES CYCLICALTIES HAMMING(string) SENDER RECEIVER ///
		TYPE(string) ///
		THETA(numlist) directed NSIM(integer 1) MCMCBURNIN(integer 3000) ///
		MCMCINTERVAL(integer 50) PROPOSAL(string) SEED(integer -1) GENERATE(string) SPCACHE ]

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
	// gwesp()/gwdsp()/gwnsp()/esp()/dsp() support directed simulation too
	// (matching the estimation path above) via one of four directed
	// shared-partner definitions selected by `type()' (default OTP) -
	// no directedness restriction on these terms themselves.
	local __ergm_type_explicit = ("`type'" != "")
	local type = upper("`type'")
	if "`type'" == "" local type "OTP"
	_opts_oneof "OTP ITP OSP ISP RTP" "type" "`type'" 6556
	if `__ergm_type_explicit' & "`directed'" == "" {
		di "{err}note: option {bf:type()} only affects directed simulation; without {bf:directed}, the undirected shared-partner definition is used regardless."
	}
	if `__ergm_type_explicit' & (`gwesp'==0 & `gwdsp'==0 & `gwnsp'==0 & "`esp'`dsp'"=="") {
		di "{err}note: option {bf:type()} has no effect - no {bf:gwesp()}/{bf:gwdsp()}/{bf:gwnsp()}/{bf:esp()}/{bf:dsp()} term was requested."
	}
	if ("`nodeicov'" != "" | "`nodeocov'" != "") & "`directed'" == "" {
		di "{err}options {bf:nodeicov()}/{bf:nodeocov()} require {bf:directed}."
		error 198
	}
	if "`degree'" != "" & "`directed'" != "" {
		di "{err}option {bf:degree()} is undirected only. Use {bf:odegree()}/{bf:idegree()} for a directed simulation."
		error 198
	}
	if ("`odegree'" != "" | "`idegree'" != "") & "`directed'" == "" {
		di "{err}options {bf:odegree()}/{bf:idegree()} require {bf:directed}. Use {bf:degree()} for an undirected simulation."
		error 198
	}
	if "`concurrent'" != "" & "`directed'" != "" {
		di "{err}option {bf:concurrent} (v1 scope) is undirected only."
		error 198
	}
	if "`triangle'" != "" & "`directed'" != "" {
		di "{err}option {bf:triangle} is undirected only. Use {bf:ctriple} for a directed simulation."
		error 198
	}
	if "`ctriple'" != "" & "`directed'" == "" {
		di "{err}option {bf:ctriple} requires {bf:directed}. Use {bf:triangle} for an undirected simulation."
		error 198
	}
	if ("`nodeifactor'" != "" | "`nodeofactor'" != "") & "`directed'" == "" {
		di "{err}options {bf:nodeifactor()}/{bf:nodeofactor()} require {bf:directed}. Use {bf:nodefactor()} for an undirected simulation."
		error 198
	}
	if "`kstar'" != "" & "`directed'" != "" {
		di "{err}option {bf:kstar()} is undirected only. Use {bf:ostar()}/{bf:istar()} for a directed simulation."
		error 198
	}
	if ("`ostar'" != "" | "`istar'" != "") & "`directed'" == "" {
		di "{err}options {bf:ostar()}/{bf:istar()} require {bf:directed}. Use {bf:kstar()} for an undirected simulation."
		error 198
	}
	if "`degrange'" != "" & "`directed'" != "" {
		di "{err}option {bf:degrange()} is undirected only. Use {bf:odegrange()}/{bf:idegrange()} for a directed simulation."
		error 198
	}
	if ("`odegrange'" != "" | "`idegrange'" != "") & "`directed'" == "" {
		di "{err}options {bf:odegrange()}/{bf:idegrange()} require {bf:directed}. Use {bf:degrange()} for an undirected simulation."
		error 198
	}
	if ("`transitiveties'" != "" | "`cyclicalties'" != "") & "`directed'" == "" {
		di "{err}options {bf:transitiveties}/{bf:cyclicalties} require {bf:directed}."
		error 198
	}
	if ("`sender'" != "" | "`receiver'" != "") & "`directed'" == "" {
		di "{err}options {bf:sender}/{bf:receiver} require {bf:directed}."
		error 198
	}
	if "`proposal'" == "" local proposal "tnt"
	_opts_oneof "uniform tnt" "proposal" "`proposal'" 6556
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

	// --- node-covariate terms (ported from the estimation path above):
	// read directly via st_data(1::nodes, "varname") from the ACTIVE
	// Stata dataset, exactly as estimation itself does - a network
	// object is not involved at all in this read, so nothing about
	// simulation-vs-estimation changes it. The caller needs `nodes'
	// observations with the named variable(s) already loaded (e.g.
	// `set obs 20' + `gen mygroup = ...' before calling simulate) -
	// documented in nwergm.sthlp's own Simulation section.
	local __ergm_termidx = 0
	foreach __ergm_v of local nodematch {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_nm`__ergm_termidx'
		mata: `__td_nm`__ergm_termidx'' = ErgmTermData()
		mata: `__td_nm`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: __nwergm_last_M.addterm("nodematch", 1, &stat_nodematch(), &change_nodematch(), `__td_nm`__ergm_termidx'', ("nodematch_`__ergm_v'"))
		local ntermtok "`ntermtok' nodematch_`__ergm_v'"
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
		local ntermtok "`ntermtok' nodecov_`__ergm_v'"
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
		local ntermtok "`ntermtok' nodeicov_`__ergm_v'"
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
		local ntermtok "`ntermtok' nodeocov_`__ergm_v'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_no`__ergm_termidx''"
	}
	local __ergm_termidx = 0
	foreach __ergm_v of local absdist {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_ad`__ergm_termidx'
		mata: `__td_ad`__ergm_termidx'' = ErgmTermData()
		mata: `__td_ad`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: __nwergm_last_M.addterm("absdist", 1, &stat_absdist(), &change_absdist(), `__td_ad`__ergm_termidx'', ("absdist_`__ergm_v'"))
		local ntermtok "`ntermtok' absdist_`__ergm_v'"
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
		local ntermtok "`ntermtok' `__ergm_cnames'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_nmd`__ergm_termidx''"
	}
	local __ergm_termidx = 0
	foreach __ergm_v of local nodefactor {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_nf`__ergm_termidx'
		mata: `__td_nf`__ergm_termidx'' = ErgmTermData()
		mata: `__td_nf`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: `__td_nf`__ergm_termidx''.levels = uniqrows(`__td_nf`__ergm_termidx''.attr)
		mata: `__td_nf`__ergm_termidx''.levels = _ergm_drop_base_level(`__td_nf`__ergm_termidx''.levels)
		mata: st_local("__ergm_nlev", strofreal(rows(`__td_nf`__ergm_termidx''.levels)))
		tempname __ergm_levvec2
		mata: st_matrix("`__ergm_levvec2'", `__td_nf`__ergm_termidx''.levels')
		local __ergm_cnames ""
		forvalues __k = 1/`__ergm_nlev' {
			local __ergm_cnames "`__ergm_cnames' nodefactor_`__ergm_v'_`=`__ergm_levvec2'[1,`__k']''"
		}
		mata: __nwergm_last_M.addterm("nodefactor", `__ergm_nlev', &stat_nodefactor(), &change_nodefactor(), `__td_nf`__ergm_termidx'', tokens("`__ergm_cnames'"))
		local ntermtok "`ntermtok' `__ergm_cnames'"
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
		local ntermtok "`ntermtok' `__ergm_cnames'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_mx`__ergm_termidx''"
		capture mata: mata drop __ergm_lv __ergm_np __ergm_lp __ergm_a __ergm_b
	}

	// --- structural terms with no covariate data at all: numlist-
	// parameterized (degree()/odegree()/idegree()/kstar()/ostar()/
	// istar()/degrange()/odegrange()/idegrange()/esp()/dsp()) or plain
	// flags (concurrent/triangle/ctriple/transitiveties/cyclicalties) -
	// ported verbatim from the estimation path, which needs nothing
	// beyond the term's own parameters either.
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
		local ntermtok "`ntermtok' `__ergm_cnames'"
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
		local ntermtok "`ntermtok' `__ergm_cnames'"
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
		local ntermtok "`ntermtok' `__ergm_cnames'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_ideg'"
	}
	if "`concurrent'" != "" {
		tempname __td_conc
		mata: `__td_conc' = ErgmTermData()
		mata: __nwergm_last_M.addterm("concurrent", 1, &stat_concurrent(), &change_concurrent(), `__td_conc', ("concurrent"))
		local ntermtok "`ntermtok' concurrent"
		local __ergm_matatemps "`__ergm_matatemps' `__td_conc'"
	}
	if "`triangle'" != "" {
		tempname __td_tri
		mata: `__td_tri' = ErgmTermData()
		mata: __nwergm_last_M.addterm("triangle", 1, &stat_triangle(), &change_triangle(), `__td_tri', ("triangle"))
		local ntermtok "`ntermtok' triangle"
		local __ergm_matatemps "`__ergm_matatemps' `__td_tri'"
	}
	if "`ctriple'" != "" {
		tempname __td_ctri
		mata: `__td_ctri' = ErgmTermData()
		mata: __nwergm_last_M.addterm("ctriple", 1, &stat_ctriple(), &change_ctriple(), `__td_ctri', ("ctriple"))
		local ntermtok "`ntermtok' ctriple"
		local __ergm_matatemps "`__ergm_matatemps' `__td_ctri'"
	}

	local __ergm_termidx = 0
	foreach __ergm_v of local nodeofactor {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_nof`__ergm_termidx'
		mata: `__td_nof`__ergm_termidx'' = ErgmTermData()
		mata: `__td_nof`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: `__td_nof`__ergm_termidx''.levels = uniqrows(`__td_nof`__ergm_termidx''.attr)
		mata: `__td_nof`__ergm_termidx''.levels = _ergm_drop_base_level(`__td_nof`__ergm_termidx''.levels)
		mata: st_local("__ergm_nlev", strofreal(rows(`__td_nof`__ergm_termidx''.levels)))
		tempname __ergm_levvec3
		mata: st_matrix("`__ergm_levvec3'", `__td_nof`__ergm_termidx''.levels')
		local __ergm_cnames ""
		forvalues __k = 1/`__ergm_nlev' {
			local __ergm_cnames "`__ergm_cnames' nodeofactor_`__ergm_v'_`=`__ergm_levvec3'[1,`__k']''"
		}
		mata: __nwergm_last_M.addterm("nodeofactor", `__ergm_nlev', &stat_nodeofactor(), &change_nodeofactor(), `__td_nof`__ergm_termidx'', tokens("`__ergm_cnames'"))
		local ntermtok "`ntermtok' `__ergm_cnames'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_nof`__ergm_termidx''"
	}
	local __ergm_termidx = 0
	foreach __ergm_v of local nodeifactor {
		confirm variable `__ergm_v'
		local ++__ergm_termidx
		tempname __td_nif`__ergm_termidx'
		mata: `__td_nif`__ergm_termidx'' = ErgmTermData()
		mata: `__td_nif`__ergm_termidx''.attr = st_data(1::`nodes', "`__ergm_v'")
		mata: `__td_nif`__ergm_termidx''.levels = uniqrows(`__td_nif`__ergm_termidx''.attr)
		mata: `__td_nif`__ergm_termidx''.levels = _ergm_drop_base_level(`__td_nif`__ergm_termidx''.levels)
		mata: st_local("__ergm_nlev", strofreal(rows(`__td_nif`__ergm_termidx''.levels)))
		tempname __ergm_levvec4
		mata: st_matrix("`__ergm_levvec4'", `__td_nif`__ergm_termidx''.levels')
		local __ergm_cnames ""
		forvalues __k = 1/`__ergm_nlev' {
			local __ergm_cnames "`__ergm_cnames' nodeifactor_`__ergm_v'_`=`__ergm_levvec4'[1,`__k']''"
		}
		mata: __nwergm_last_M.addterm("nodeifactor", `__ergm_nlev', &stat_nodeifactor(), &change_nodeifactor(), `__td_nif`__ergm_termidx'', tokens("`__ergm_cnames'"))
		local ntermtok "`ntermtok' `__ergm_cnames'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_nif`__ergm_termidx''"
	}

	if "`kstar'" != "" {
		tempname __td_kstar
		mata: `__td_kstar' = ErgmTermData()
		mata: `__td_kstar'.levels = strtoreal(tokens("`kstar'"))'
		mata: st_local("__ergm_nk", strofreal(rows(`__td_kstar'.levels)))
		local __ergm_cnames ""
		foreach __ergm_kv of numlist `kstar' {
			local __ergm_cnames "`__ergm_cnames' kstar_`__ergm_kv'"
		}
		mata: __nwergm_last_M.addterm("kstar", `__ergm_nk', &stat_kstar(), &change_kstar(), `__td_kstar', tokens("`__ergm_cnames'"))
		local ntermtok "`ntermtok' `__ergm_cnames'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_kstar'"
	}
	if "`ostar'" != "" {
		tempname __td_ostar
		mata: `__td_ostar' = ErgmTermData()
		mata: `__td_ostar'.levels = strtoreal(tokens("`ostar'"))'
		mata: st_local("__ergm_nk", strofreal(rows(`__td_ostar'.levels)))
		local __ergm_cnames ""
		foreach __ergm_kv of numlist `ostar' {
			local __ergm_cnames "`__ergm_cnames' ostar_`__ergm_kv'"
		}
		mata: __nwergm_last_M.addterm("ostar", `__ergm_nk', &stat_ostar(), &change_ostar(), `__td_ostar', tokens("`__ergm_cnames'"))
		local ntermtok "`ntermtok' `__ergm_cnames'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_ostar'"
	}
	if "`istar'" != "" {
		tempname __td_istar
		mata: `__td_istar' = ErgmTermData()
		mata: `__td_istar'.levels = strtoreal(tokens("`istar'"))'
		mata: st_local("__ergm_nk", strofreal(rows(`__td_istar'.levels)))
		local __ergm_cnames ""
		foreach __ergm_kv of numlist `istar' {
			local __ergm_cnames "`__ergm_cnames' istar_`__ergm_kv'"
		}
		mata: __nwergm_last_M.addterm("istar", `__ergm_nk', &stat_istar(), &change_istar(), `__td_istar', tokens("`__ergm_cnames'"))
		local ntermtok "`ntermtok' `__ergm_cnames'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_istar'"
	}

	if "`degrange'" != "" {
		local __ergm_ndr : word count `degrange'
		if "`degrangeto'" == "" {
			local __ergm_dto ""
			forvalues __k = 1/`__ergm_ndr' {
				local __ergm_dto "`__ergm_dto' ."
			}
		}
		else {
			local __ergm_dto "`degrangeto'"
			local __ergm_ndto : word count `degrangeto'
			if `__ergm_ndto' != `__ergm_ndr' {
				di "{err}degrange() and degrangeto() must supply the same number of values."
				error 198
			}
		}
		tempname __td_dr
		mata: `__td_dr' = ErgmTermData()
		mata: `__td_dr'.levelpairs = strtoreal(tokens("`degrange'"))' , strtoreal(tokens("`__ergm_dto'"))'
		local __ergm_cnames ""
		forvalues __k = 1/`__ergm_ndr' {
			local __ergm_cnames "`__ergm_cnames' degrange_`__k'"
		}
		mata: __nwergm_last_M.addterm("degrange", `__ergm_ndr', &stat_degrange(), &change_degrange(), `__td_dr', tokens("`__ergm_cnames'"))
		local ntermtok "`ntermtok' `__ergm_cnames'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_dr'"
	}
	if "`odegrange'" != "" {
		local __ergm_ndr : word count `odegrange'
		if "`odegrangeto'" == "" {
			local __ergm_dto ""
			forvalues __k = 1/`__ergm_ndr' {
				local __ergm_dto "`__ergm_dto' ."
			}
		}
		else {
			local __ergm_dto "`odegrangeto'"
			local __ergm_ndto : word count `odegrangeto'
			if `__ergm_ndto' != `__ergm_ndr' {
				di "{err}odegrange() and odegrangeto() must supply the same number of values."
				error 198
			}
		}
		tempname __td_odr
		mata: `__td_odr' = ErgmTermData()
		mata: `__td_odr'.levelpairs = strtoreal(tokens("`odegrange'"))' , strtoreal(tokens("`__ergm_dto'"))'
		local __ergm_cnames ""
		forvalues __k = 1/`__ergm_ndr' {
			local __ergm_cnames "`__ergm_cnames' odegrange_`__k'"
		}
		mata: __nwergm_last_M.addterm("odegrange", `__ergm_ndr', &stat_odegrange(), &change_odegrange(), `__td_odr', tokens("`__ergm_cnames'"))
		local ntermtok "`ntermtok' `__ergm_cnames'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_odr'"
	}
	if "`idegrange'" != "" {
		local __ergm_ndr : word count `idegrange'
		if "`idegrangeto'" == "" {
			local __ergm_dto ""
			forvalues __k = 1/`__ergm_ndr' {
				local __ergm_dto "`__ergm_dto' ."
			}
		}
		else {
			local __ergm_dto "`idegrangeto'"
			local __ergm_ndto : word count `idegrangeto'
			if `__ergm_ndto' != `__ergm_ndr' {
				di "{err}idegrange() and idegrangeto() must supply the same number of values."
				error 198
			}
		}
		tempname __td_idr
		mata: `__td_idr' = ErgmTermData()
		mata: `__td_idr'.levelpairs = strtoreal(tokens("`idegrange'"))' , strtoreal(tokens("`__ergm_dto'"))'
		local __ergm_cnames ""
		forvalues __k = 1/`__ergm_ndr' {
			local __ergm_cnames "`__ergm_cnames' idegrange_`__k'"
		}
		mata: __nwergm_last_M.addterm("idegrange", `__ergm_ndr', &stat_idegrange(), &change_idegrange(), `__td_idr', tokens("`__ergm_cnames'"))
		local ntermtok "`ntermtok' `__ergm_cnames'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_idr'"
	}

	if "`esp'" != "" {
		local __ergm_nd : word count `esp'
		tempname __td_esp
		mata: `__td_esp' = ErgmTermData()
		mata: `__td_esp'.levels = strtoreal(tokens("`esp'"))'
		if "`directed'" != "" {
			mata: `__td_esp'.sptype = "`type'"
		}
		local __ergm_cnames ""
		foreach __ergm_dv of numlist `esp' {
			local __ergm_cnames "`__ergm_cnames' esp`__ergm_dv'"
		}
		mata: __nwergm_last_M.addterm("esp", `__ergm_nd', &stat_esp(), &change_esp(), `__td_esp', tokens("`__ergm_cnames'"))
		local ntermtok "`ntermtok' `__ergm_cnames'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_esp'"
	}
	if "`dsp'" != "" {
		local __ergm_nd : word count `dsp'
		tempname __td_dsp2
		mata: `__td_dsp2' = ErgmTermData()
		mata: `__td_dsp2'.levels = strtoreal(tokens("`dsp'"))'
		if "`directed'" != "" {
			mata: `__td_dsp2'.sptype = "`type'"
		}
		local __ergm_cnames ""
		foreach __ergm_dv of numlist `dsp' {
			local __ergm_cnames "`__ergm_cnames' dsp`__ergm_dv'"
		}
		mata: __nwergm_last_M.addterm("dsp", `__ergm_nd', &stat_dsp(), &change_dsp(), `__td_dsp2', tokens("`__ergm_cnames'"))
		local ntermtok "`ntermtok' `__ergm_cnames'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_dsp2'"
	}

	if "`transitiveties'" != "" {
		tempname __td_tt
		mata: `__td_tt' = ErgmTermData()
		mata: __nwergm_last_M.addterm("transitiveties", 1, &stat_transitiveties(), &change_transitiveties(), `__td_tt', ("transitiveties"))
		local ntermtok "`ntermtok' transitiveties"
		local __ergm_matatemps "`__ergm_matatemps' `__td_tt'"
	}
	if "`cyclicalties'" != "" {
		tempname __td_ct
		mata: `__td_ct' = ErgmTermData()
		mata: __nwergm_last_M.addterm("cyclicalties", 1, &stat_cyclicalties(), &change_cyclicalties(), `__td_ct', ("cyclicalties"))
		local ntermtok "`ntermtok' cyclicalties"
		local __ergm_matatemps "`__ergm_matatemps' `__td_ct'"
	}

	// sender()/receiver(): per-node out-/in-degree fixed effects, base=1
	// omitted - the node's own identity (1..nodes) IS the "attribute",
	// reusing stat_nodeofactor()/stat_nodeifactor() with no new Mata code,
	// exactly as the estimation path does.
	if "`sender'" != "" {
		tempname __td_send
		mata: `__td_send' = ErgmTermData()
		mata: `__td_send'.attr = (1::`nodes')
		mata: `__td_send'.levels = (2::`nodes')
		local __ergm_cnames ""
		forvalues __k = 2/`nodes' {
			local __ergm_cnames "`__ergm_cnames' sender`__k'"
		}
		mata: __nwergm_last_M.addterm("sender", `nodes'-1, &stat_nodeofactor(), &change_nodeofactor(), `__td_send', tokens("`__ergm_cnames'"))
		local ntermtok "`ntermtok' `__ergm_cnames'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_send'"
	}
	if "`receiver'" != "" {
		tempname __td_recv
		mata: `__td_recv' = ErgmTermData()
		mata: `__td_recv'.attr = (1::`nodes')
		mata: `__td_recv'.levels = (2::`nodes')
		local __ergm_cnames ""
		forvalues __k = 2/`nodes' {
			local __ergm_cnames "`__ergm_cnames' receiver`__k'"
		}
		mata: __nwergm_last_M.addterm("receiver", `nodes'-1, &stat_nodeifactor(), &change_nodeifactor(), `__td_recv', tokens("`__ergm_cnames'"))
		local ntermtok "`ntermtok' `__ergm_cnames'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_recv'"
	}

	// --- dyadic-covariate terms: edgecov()/hamming() reference ANOTHER
	// already-loaded network (not a plain variable) - resolved via
	// nw_syntax exactly as the estimation path does, just checked
	// against the `nodes' argument instead of an observed netname's own
	// size (simulate has no observed network to compare against).
	local __ergm_termidx = 0
	foreach __ergm_v of local edgecov {
		local ++__ergm_termidx
		tempname __td_ec`__ergm_termidx'
		mata: `__td_ec`__ergm_termidx'' = ErgmTermData()
		nw_syntax `__ergm_v', max(1) other(ec`__ergm_termidx')
		if `ec`__ergm_termidx'nodes' != `nodes' {
			di "{err}edgecov() network {bf:`__ergm_v'} has a different number of nodes than requested ({bf:`nodes'})."
			error 198
		}
		mata: `__td_ec`__ergm_termidx''.edgecovmat = *(`ec`__ergm_termidx'netobj'->get_matrix_mod(1,("`directed'"!="")))
		mata: __nwergm_last_M.addterm("edgecov", 1, &stat_edgecov(), &change_edgecov(), `__td_ec`__ergm_termidx'', ("edgecov_`__ergm_v'"))
		local ntermtok "`ntermtok' edgecov_`__ergm_v'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_ec`__ergm_termidx''"
	}
	local __ergm_termidx = 0
	foreach __ergm_v of local hamming {
		local ++__ergm_termidx
		tempname __td_hm`__ergm_termidx'
		mata: `__td_hm`__ergm_termidx'' = ErgmTermData()
		nw_syntax `__ergm_v', max(1) other(hm`__ergm_termidx')
		if `hm`__ergm_termidx'nodes' != `nodes' {
			di "{err}hamming() network {bf:`__ergm_v'} has a different number of nodes than requested ({bf:`nodes'})."
			error 198
		}
		mata: `__td_hm`__ergm_termidx''.edgecovmat = *(`hm`__ergm_termidx'netobj'->get_matrix_mod(0,("`directed'"!="")))
		mata: __nwergm_last_M.addterm("hamming", 1, &stat_hamming(), &change_hamming(), `__td_hm`__ergm_termidx'', ("hamming_`__ergm_v'"))
		local ntermtok "`ntermtok' hamming_`__ergm_v'"
		local __ergm_matatemps "`__ergm_matatemps' `__td_hm`__ergm_termidx''"
	}

	if `gwesp' != 0 {
		tempname td_gwesp
		mata: `td_gwesp' = ErgmTermData()
		mata: `td_gwesp'.decay = `gwesp'
		if "`directed'" != "" {
			mata: `td_gwesp'.sptype = "`type'"
		}
		mata: __nwergm_last_M.addterm("gwesp", 1, &stat_gwesp(), &change_gwesp(), `td_gwesp', ("gwesp"))
		local ntermtok "`ntermtok' gwesp"
		local __ergm_matatemps "`__ergm_matatemps' `td_gwesp'"
	}
	if `gwdsp' != 0 {
		tempname td_gwdsp
		mata: `td_gwdsp' = ErgmTermData()
		mata: `td_gwdsp'.decay = `gwdsp'
		if "`directed'" != "" {
			mata: `td_gwdsp'.sptype = "`type'"
		}
		mata: __nwergm_last_M.addterm("gwdsp", 1, &stat_gwdsp(), &change_gwdsp(), `td_gwdsp', ("gwdsp"))
		local ntermtok "`ntermtok' gwdsp"
		local __ergm_matatemps "`__ergm_matatemps' `td_gwdsp'"
	}
	if `gwnsp' != 0 {
		tempname td_gwnsp
		mata: `td_gwnsp' = ErgmTermData()
		mata: `td_gwnsp'.decay = `gwnsp'
		if "`directed'" != "" {
			mata: `td_gwnsp'.sptype = "`type'"
		}
		mata: __nwergm_last_M.addterm("gwnsp", 1, &stat_gwnsp(), &change_gwnsp(), `td_gwnsp', ("gwnsp"))
		local ntermtok "`ntermtok' gwnsp"
		local __ergm_matatemps "`__ergm_matatemps' `td_gwnsp'"
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

	// spcache: same option/cache as the main nwergm program (see its own
	// build-up comment), computed ONCE here rather than per-draw below.
	// Note the cost-benefit here is even less favorable than in
	// estimation: each simulated draw gets a FRESH ErgmGraph (see the
	// loop below), so the cache's O(sum deg^2) build cost is paid nsim
	// times over, against only `mcmcburnin' toggles of benefit per draw
	// (not an entire MCMLE run's worth) - offered for consistency with
	// the estimation command, not because it is expected to help here.
	local __ergm_spcache_relevant = (`gwesp'!=0 | `gwdsp'!=0 | `gwnsp'!=0 | "`esp'"!="" | "`dsp'"!="" | "`triangle'"!="" | "`ctriple'"!="")
	if "`spcache'" != "" {
		if "`directed'" != "" {
			di "{err}note: option {bf:spcache} has no effect on a directed simulation; the incremental shared-partner cache only implements the undirected shared-partner definition."
		}
		else if !`__ergm_spcache_relevant' {
			di "{err}note: option {bf:spcache} has no effect without gwesp()/gwdsp()/gwnsp()/esp()/dsp()/triangle/ctriple; none of those terms was requested."
		}
	}
	local __ergm_spcache_used = ("`spcache'"!="" & "`directed'"=="" & `__ergm_spcache_relevant')

	// BUGFIX: used to render the simulated draw's dense adjacency matrix
	// as a literal Stata matrix-expression string (ErgmMatToLiteral())
	// and hand that to nwset's own mat() option, which hits Stata's own
	// "too many tokens" command-line limit somewhere around 16 nodes
	// (confirmed directly - see nwergm_estat.ado's identical fix for the
	// full account) - `nwergm ..., simulate' was completely broken for
	// any network that size or larger, not merely slow. Fixed the same
	// way: pass the matrix as a bare Mata variable name instead of a
	// literal expression string, which nwset's own mat() option already
	// accepts directly (the same pattern nwrandom.ado's own generators
	// already use) and has no size limit to hit.
	tempname __ergm_simmat
	forvalues __s = 1/`nsim' {
		capture mata: mata drop __nwergm_last_G
		mata: __nwergm_last_G = ErgmGraph()
		mata: __nwergm_last_G.init(`nodes', ("`directed'"!=""))
		// enable_sp_cache() only when the user explicitly opted in via
		// spcache (see this program's own build-up comment above for why
		// it is off by default and why simulate's own cost-benefit is
		// even less favorable than estimation's).
		if `__ergm_spcache_used' {
			mata: __nwergm_last_G.enable_sp_cache()
		}
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
		mata: `__ergm_simmat' = __nwergm_last_G.to_dense()

		local __ergm_simname = cond(`nsim'==1, "`generate'", "`generate'_`__s'")
		capture nwdrop `__ergm_simname'
		qui drop _all
		qui set obs `nodes'
		nwset, mat(`__ergm_simmat') `=cond("`directed'"!="","directed","undirected")' name(`__ergm_simname')
	}

	mata: mata drop __nwergm_last_M __nwergm_last_G __gof_discard `__ergm_simmat' `__ergm_matatemps'
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
