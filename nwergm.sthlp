{smcl}
{* *! version 2.0.0  22aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_statmodels:[NW-2.6.6] Statistical Estimation of Networks}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwergm {hline 2}}Exponential-family random graph model (ERGM) estimation{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwergm}
[{it:{help netname}}]
{cmd:,}
{opt edges}
[{it:{help nwergm##covariate_effects:covariate_effects}}
{it:{help nwergm##bipartite_effects:bipartite_effects}}
{it:{help nwergm##gw_effects:gw_effects}}
{it:{help nwergm##degree_effects:degree_effects}}
{it:{help nwergm##triad_effects:triad_effects}}
{it:{help nwergm##directed_covariate_effects:directed_covariate_effects}}
{it:{help nwergm##star_range_effects:star_range_effects}}
{it:{help nwergm##sharedpartner_effects:sharedpartner_effects}}
{it:{help nwergm##triad_effects_directed:triad_effects_directed}}
{it:{help nwergm##nodelevel_effects:nodelevel_effects}}
{it:{help nwergm##estimation_control:estimation_control}}]

{synoptset 26}{...}
{p2col:{it:options}}Description{p_end}
{p2line}
{p2col:{it:{help nwergm##covariate_effects:covariate_effects}}}node and dyadic covariate main effects ({opt mutual}, {opt nodematch()}, {opt nodecov()}, {opt edgecov()}, {opt nodefactor()}, {opt nodemix()}, etc.){p_end}
{p2col:{it:{help nwergm##bipartite_effects:bipartite_effects}}}two-mode (bipartite) network terms{p_end}
{p2col:{it:{help nwergm##gw_effects:gw_effects}}}geometrically weighted shared-partner/degree terms, fixed and curved decay{p_end}
{p2col:{it:{help nwergm##degree_effects:degree_effects}}}degree-distribution terms{p_end}
{p2col:{it:{help nwergm##triad_effects:triad_effects}}}undirected triad-closure terms ({opt triangle}, {opt ctriple}){p_end}
{p2col:{it:{help nwergm##directed_covariate_effects:directed_covariate_effects}}}directed-only covariate factor terms{p_end}
{p2col:{it:{help nwergm##star_range_effects:star_range_effects}}}k-star and semi-open degree-range terms{p_end}
{p2col:{it:{help nwergm##sharedpartner_effects:sharedpartner_effects}}}fixed (non-geometric) shared-partner count terms, and the directed shared-partner {opt type()} selector{p_end}
{p2col:{it:{help nwergm##triad_effects_directed:triad_effects_directed}}}directed triad-closure existence-indicator terms{p_end}
{p2col:{it:{help nwergm##nodelevel_effects:nodelevel_effects}}}dyadic-covariate and per-node fixed-effect terms{p_end}
{p2col:{it:{help nwergm##estimation_control:estimation_control}}}estimation method, MCMC tuning, constraints, and output control{p_end}

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt edges}}Include the {cmd:edges} term (density/intercept); required{p_end}

{marker covariate_effects}{...}
{syntab:Node and dyadic covariate effects}
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

{marker bipartite_effects}{...}
{syntab:Two-mode (bipartite) effects}
{synopt:{opth bcov1(varlist)}}Bipartite (two-mode) networks only: the {cmd:b1cov()} term from R's own {cmd:ergm} package (renamed to {cmd:bcov1()} because Stata's {cmd:syntax} command rejects an option name with a digit followed by a letter, e.g. {cmd:b1cov}) - continuous node covariate main effect for the MODE-1 endpoint only (sum, over ties, of the mode-1 endpoint's own covariate value; the mode-2 endpoint's value is never added). Reported coefficient name keeps R's own {cmd:b1cov_}{it:varname} spelling{p_end}
{synopt:{opth bcov2(varlist)}}Bipartite networks only: the {cmd:b2cov()} term - the {opt bcov1()} mirror for the MODE-2 endpoint. Reported coefficient name: {cmd:b2cov_}{it:varname}{p_end}
{synopt:{opth bfactor1(varlist)}}Bipartite networks only: the {cmd:b1factor()} term - one coefficient per NON-BASE distinct level of each listed categorical attribute (lowest-sorted level omitted, same convention as {opt nodefactor()}), each counting the number of ties whose MODE-1 endpoint carries that level (the mode-2 endpoint never gets credit, unlike {opt nodefactor()}'s own both-endpoints convention). Reported coefficient name: {cmd:b1factor_}{it:varname}{cmd:_}{it:level}{p_end}
{synopt:{opth bfactor2(varlist)}}Bipartite networks only: the {cmd:b2factor()} term - the {opt bfactor1()} mirror for the MODE-2 endpoint. Reported coefficient name: {cmd:b2factor_}{it:varname}{cmd:_}{it:level}{p_end}
{synopt:{opt bdegree1(numlist)}}Bipartite networks only: the {cmd:b1degree()} term - one coefficient per listed degree value, counting the number of MODE-1 nodes with that exact (total) degree (the mode-2 endpoint never contributes). Dyad-DEPENDENT (needs {opt method(mcmle)}), unlike {opt bcov1()}/{opt bfactor1()}. Reported coefficient name: {cmd:b1degree_}{it:d}{p_end}
{synopt:{opt bdegree2(numlist)}}Bipartite networks only: the {cmd:b2degree()} term - the {opt bdegree1()} mirror for the MODE-2 endpoint{p_end}
{synopt:{opt bstar1(numlist)}}Bipartite networks only: the {cmd:b1star()} term - one coefficient per listed k, counting the number of distinct k-stars centered on a MODE-1 node (C(degree,k) summed over mode-1 nodes only). Dyad-DEPENDENT (needs {opt method(mcmle)}). Note: {opt bstar1(1)} equals {opt bstar2(1)} equals {opt edges} (R ergm's own documented identity). Reported coefficient name: {cmd:b1star_}{it:k}{p_end}
{synopt:{opt bstar2(numlist)}}Bipartite networks only: the {cmd:b2star()} term - the {opt bstar1()} mirror for the MODE-2 endpoint{p_end}
{synopt:{opth bnodematch1(varlist)}}Bipartite networks only: the {cmd:b1nodematch()} term - pooled homophily (default-parameter scope: no {cmd:diff()}/{cmd:alpha()}/{cmd:beta()}/{cmd:byb2attr()}) on each listed categorical attribute, counting only ties whose MODE-1 endpoint carries the matching level. Dyad-DEPENDENT (needs {opt method(mcmle)}), unlike {opt bcov1()}/{opt bfactor1()}. Reported coefficient name: {cmd:b1nodematch_}{it:varname}{p_end}
{synopt:{opth bnodematch2(varlist)}}Bipartite networks only: the {cmd:b2nodematch()} term - the {opt bnodematch1()} mirror for the MODE-2 endpoint. Reported coefficient name: {cmd:b2nodematch_}{it:varname}{p_end}
{synopt:{opt bgwdegree1(real)}}Bipartite networks only: the {cmd:gwb1degree()} term - geometrically weighted degree, fixed decay, counting only MODE-1 nodes' own degree. Dyad-DEPENDENT (needs {opt method(mcmle)}); no curved (estimated-decay) counterpart yet, unlike plain {opt gwdegree()}/{opt gwdegreefree()}. Reported coefficient name: {cmd:bgwdegree1_}{it:decay}{p_end}
{synopt:{opt bgwdegree2(real)}}Bipartite networks only: the {cmd:gwb2degree()} term - the {opt bgwdegree1()} mirror for the MODE-2 endpoint. Reported coefficient name: {cmd:bgwdegree2_}{it:decay}{p_end}

{marker gw_effects}{...}
{syntab:Geometrically weighted effects}
{synopt:{opt gwesp(real)}}Geometrically weighted edgewise shared partners, fixed decay; undirected (UTP) or directed (shared-partner definition set by {opt type()}, default OTP){p_end}
{synopt:{opt gwespfree(real)}}Geometrically weighted edgewise shared partners with an ESTIMATED (curved) decay parameter; undirected (UTP), or directed (shared-partner definition set by {opt type()}, default OTP - all five of OTP/ITP/OSP/ISP/RTP supported). The argument is only a starting value for decay, not a fixed value. Both {bf:method(mple)} and {bf:method(mcmle)} are supported (default {bf:mcmle}, as for any other dyad-dependent term - see {opt method()} below) - reports {bf:gwesp_weight}/{bf:gwesp_decay} in place of a single {opt gwesp()} coefficient. Cannot be combined with {opt gwesp()}, {opt esp()}, or another curved term{p_end}
{synopt:{opt gwdegreefree(real)}}Geometrically weighted degree with an ESTIMATED (curved) decay parameter, undirected networks only; the argument is only a starting value for decay, not a fixed value. Both {bf:method(mple)} and {bf:method(mcmle)} are supported (default {bf:mcmle}) - reports {bf:gwdegree_weight}/{bf:gwdegree_decay} in place of a single {opt gwdegree()} coefficient. Cannot be combined with {opt gwdegree()}, {opt degree()}, or another curved term{p_end}
{synopt:{opt gwdspfree(real)}}Geometrically weighted dyadwise shared partners with an ESTIMATED (curved) decay parameter, undirected networks only; the argument is only a starting value for decay, not a fixed value. Both {bf:method(mple)} and {bf:method(mcmle)} are supported (default {bf:mcmle}) - reports {bf:gwdsp_weight}/{bf:gwdsp_decay} in place of a single {opt gwdsp()} coefficient. Cannot be combined with {opt gwdsp()}, {opt dsp()}, or another curved term{p_end}
{synopt:{opt gwodegreefree(real)}}Geometrically weighted out-degree with an ESTIMATED (curved) decay parameter, directed networks only; the argument is only a starting value for decay, not a fixed value. Both {bf:method(mple)} and {bf:method(mcmle)} are supported (default {bf:mcmle}) - reports {bf:gwodegree_weight}/{bf:gwodegree_decay} in place of a single {opt gwodegree()} coefficient. Cannot be combined with {opt gwodegree()}, {opt odegree()}, or another curved term{p_end}
{synopt:{opt gwidegreefree(real)}}Geometrically weighted in-degree with an ESTIMATED (curved) decay parameter, directed networks only; the argument is only a starting value for decay, not a fixed value. Both {bf:method(mple)} and {bf:method(mcmle)} are supported (default {bf:mcmle}) - reports {bf:gwidegree_weight}/{bf:gwidegree_decay} in place of a single {opt gwidegree()} coefficient. Cannot be combined with {opt gwidegree()}, {opt idegree()}, or another curved term{p_end}
{synopt:{opt gwnspfree(real)}}Geometrically weighted nonedgewise shared partners with an ESTIMATED (curved) decay parameter, undirected networks only; the argument is only a starting value for decay, not a fixed value. Both {bf:method(mple)} and {bf:method(mcmle)} are supported (default {bf:mcmle}) - reports {bf:gwnsp_weight}/{bf:gwnsp_decay} in place of a single {opt gwnsp()} coefficient. Cannot be combined with {opt gwnsp()} or another curved term{p_end}
{synopt:{opt gwdsp(real)}}Geometrically weighted dyadwise shared partners, fixed decay; undirected (UTP) or directed (see {opt type()}){p_end}
{synopt:{opt gwdegree(real)}}Geometrically weighted degree, fixed decay{p_end}
{synopt:{opt gwodegree(real)}}Geometrically weighted out-degree, fixed decay; directed networks only{p_end}
{synopt:{opt gwidegree(real)}}Geometrically weighted in-degree, fixed decay; directed networks only{p_end}
{synopt:{opt gwnsp(real)}}Geometrically weighted NONedgewise (untied-dyad) shared partners, fixed decay; undirected (UTP) or directed (see {opt type()}). Satisfies gwdsp = gwesp + gwnsp{p_end}

{marker degree_effects}{...}
{syntab:Degree-distribution effects}
{synopt:{opt degree(numlist)}}One coefficient per listed degree value: count of nodes with that exact (total) degree; undirected only{p_end}
{synopt:{opt odegree(numlist)}}One coefficient per listed value: count of nodes with that exact out-degree; directed networks only{p_end}
{synopt:{opt idegree(numlist)}}One coefficient per listed value: count of nodes with that exact in-degree; directed networks only{p_end}
{synopt:{opt concurrent}}Count of nodes with (total) degree 2 or higher; undirected only{p_end}

{marker triad_effects}{...}
{syntab:Triad-closure effects}
{synopt:{opt triangle}}Count of triangles (mutually tied triples); undirected only{p_end}
{synopt:{opt ctriple}}Count of cyclic triples ((i->j),(j->k),(k->i)); directed networks only{p_end}

{marker directed_covariate_effects}{...}
{syntab:Directed covariate effects}
{synopt:{opth nodeofactor(varlist)}}Directed analogue of nodefactor(): one coefficient per NON-BASE distinct level, each counting OUT-degree among nodes at that level; directed networks only{p_end}
{synopt:{opth nodeifactor(varlist)}}Directed analogue of nodefactor(): one coefficient per NON-BASE distinct level, each counting IN-degree among nodes at that level; directed networks only{p_end}

{marker star_range_effects}{...}
{syntab:Star and degree-range effects}
{synopt:{opt kstar(numlist)}}One coefficient per listed k value: count of k-stars ((total) degree choose k, summed over nodes); undirected only{p_end}
{synopt:{opt ostar(numlist)}}One coefficient per listed k value: count of out-k-stars; directed networks only{p_end}
{synopt:{opt istar(numlist)}}One coefficient per listed k value: count of in-k-stars; directed networks only{p_end}
{synopt:{opt degrange(numlist)}}Semi-open-interval degree count: one coefficient per FROM value in this numlist, counting nodes with (total) degree in [from,to); pair with {opt degrangeto()}; undirected only{p_end}
{synopt:{opt degrangeto(numlist)}}TO values pairing with {opt degrange()}, same order/length; omit for an open-ended upper bound{p_end}
{synopt:{opt odegrange(numlist)}}Semi-open-interval OUT-degree count, paired with {opt odegrangeto()}; directed networks only{p_end}
{synopt:{opt odegrangeto(numlist)}}TO values pairing with {opt odegrange()}{p_end}
{synopt:{opt idegrange(numlist)}}Semi-open-interval IN-degree count, paired with {opt idegrangeto()}; directed networks only{p_end}
{synopt:{opt idegrangeto(numlist)}}TO values pairing with {opt idegrange()}{p_end}

{marker sharedpartner_effects}{...}
{syntab:Shared-partner count effects}
{synopt:{opt esp(numlist)}}One coefficient per listed d value: count of TIED dyads with exactly d shared partners (fixed, non-geometric alternative to {opt gwesp()}); undirected (UTP) or directed (see {opt type()}){p_end}
{synopt:{opt dsp(numlist)}}One coefficient per listed d value: count of ALL dyads (tied or not) with exactly d shared partners (fixed, non-geometric alternative to {opt gwdsp()}); undirected (UTP) or directed (see {opt type()}). An EXHAUSTIVE d-range (covering every shared-partner value a toggle can produce) is exactly collinear across its own columns - list a subset, not every achievable value{p_end}
{synopt:{opt type(OTP|ITP|OSP|ISP|RTP)}}Shared-partner definition used by every {opt gwesp()}/{opt gwdsp()}/{opt gwnsp()}/{opt esp()}/{opt dsp()}/{opt gwespfree()} term in the model, on a DIRECTED network only (default {bf:OTP}; silently ignored, matching R ergm's own behaviour, when {bf:netname} is undirected - see the {bf:Remarks} section below for the five definitions){p_end}

{marker triad_effects_directed}{...}
{syntab:Triad-closure effects (directed)}
{synopt:{opt transitiveties}}Count of TIED arcs i->j for which there also exists a two-path i->k->j (an existence/threshold indicator, not a count - contrast with {opt gwesp()}/{opt esp()}); directed networks only{p_end}
{synopt:{opt cyclicalties}}Count of TIED arcs i->j for which there also exists a return two-path j->k->i, closing a directed 3-cycle; directed networks only{p_end}

{marker nodelevel_effects}{...}
{syntab:Dyadic covariate and node-level effects}
{synopt:{opth hamming(netname)}}Hamming distance to a reference network: count of dyads whose tie state disagrees with the same network's{p_end}
{synopt:{opt sender}}One coefficient per node (except a base node) equal to that node's own out-degree; directed networks only{p_end}
{synopt:{opt receiver}}One coefficient per node (except a base node) equal to that node's own in-degree; directed networks only{p_end}

{marker estimation_control}{...}
{syntab:Estimation control}
{synopt:{opt method(mple|mcmle)}}Estimation method; default {it:mcmle} unless the model is dyad-independent, in which case MPLE already is the MLE{p_end}
{synopt:{opth offset(coefname # [coefname # ...])}}Hold one or more named coefficients fixed at a given value rather than estimating them, matching R ergm's own {cmd:offset()} formula wrapper. {bf:coefname} must be a coefficient this model would otherwise report (an option must still be typed to register the term, e.g. {opt triangle}, before {opt offset(triangle #)} can fix its own coefficient - {opt offset()} names an EXISTING coefficient, it does not add a second copy of the term). Works with both {opt method(mple)} and {opt method(mcmle)}. At least one coefficient in the model must remain free. Not currently supported for a curved (free-decay) term's own weight/decay. The fixed coefficient is reported at exactly the given value with standard error exactly 0 (matching R's own real output) and a zero row/column in {bf:e(V)} - see {bf:Remarks} below{p_end}
{synopt:{opt mcmcburnin(int)}}MCMC burn-in steps per simulation; default 3,000{p_end}
{synopt:{opt mcmcinterval(int)}}MCMC steps between recorded draws; default 50{p_end}
{synopt:{opt mcmcsamplesize(int)}}Number of recorded MCMC draws per simulation; default 3,000{p_end}
{synopt:{opt mcmleiterations(int)}}Maximum MCMLE outer iterations; default 20{p_end}
{synopt:{opt proposal(uniform|tnt)}}Metropolis-Hastings proposal; default {it:tnt}. Both have a masked variant when {opt freedyads()} or {opt blockdiag()} is given{p_end}
{synopt:{opth freedyads(netname)}}Restrict the dyad space to fit (see {bf:Remarks}): {bf:netname}'s own ties mark which dyads of the network being fit are free to vary during MCMC; every dyad NOT tied in {bf:netname} is held fixed at its observed value for the rest of the fit (R ergm's own {cmd:fixallbut()} constraint). Compatible with both {opt proposal(uniform)} and {opt proposal(tnt)}, and native (C)-accelerated when otherwise eligible. See {bf:Limitations (v1 scope)} below{p_end}
{synopt:{opth blockdiag(varname)}}Restrict the dyad space to fit (see {bf:Remarks}): only dyads sharing the same value of {bf:varname} are free to vary during MCMC; every cross-value dyad is held fixed at its observed value for the rest of the fit (R ergm's own {cmd:blockdiag()} constraint). Cannot be combined with {opt freedyads()}. Compatible with both {opt proposal(uniform)} and {opt proposal(tnt)}, and native (C)-accelerated when otherwise eligible{p_end}
{synopt:{opt seed(int)}}Set the random-number seed before simulating (for reproducibility){p_end}
{synopt:{opt verbose}}Show MPLE/MCMLE iteration detail{p_end}
{synopt:{opt spcache}}Enable the incremental shared-partner cache for {opt gwesp()}/{opt gwdsp()}/{opt gwnsp()}/{opt esp()}/{opt dsp()}/{opt triangle}/{opt ctriple} on an undirected network; OFF by default because direct benchmarking found it a net LOSS below roughly average degree 30-40 (the common case) and a net win only above that - enable only for denser undirected networks; no effect on a directed network or without any of those terms{p_end}
{synopt:{opt fixdensity}}Hold the total tie count fixed during MCMC (R ergm's own {cmd:constraints=~edges}), via a compound tie/non-tie swap proposal rather than the ordinary single-dyad toggle; native (C)-accelerated when otherwise eligible. Requires {opt method(mcmle)} and at least one term besides {opt edges} (which is dropped, not estimated, under this constraint - see {bf:Remarks}). Cannot currently be combined with {opt freedyads()}/{opt blockdiag()} - v1 supports one dyad-space constraint at a time{p_end}
{synopt:{opt nonative}}Force the pure-Mata backend even on an otherwise native-eligible model - an explicit escape hatch for testing or direct comparison against the native (C) backend; not needed for ordinary use, since {cmd:nwergm} already picks the native backend automatically whenever a model qualifies{p_end}
{synopt:{opt nomcmcsample}}Skip posting {bf:e(mcmcsample)} ({bf:method(mcmle)} only). Populating this matrix from Mata is the single slowest step for a fit with a large {opt mcmcsamplesize()} - a genuine Stata matrix-engine cost at bulk-data scale (confirmed by direct timing: over 30 seconds at 100,000 rows), not something {help nwergm_estat:estat mcmcdiag}'s own consumption of it can be blamed for or sped up (reading the already-posted matrix back is fast regardless of size - the cost is entirely in creating it in the first place). Specify {opt nomcmcsample} when fitting with an unusually large {opt mcmcsamplesize()} and you do not need {cmd:estat mcmcdiag} or to inspect the raw sample directly - the coefficient table, standard errors, and every other stored result are completely unaffected{p_end}

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
{cmd:nwergm} implements a substantial, independently-certified core of Statnet's own {cmd:ergm}
term surface and estimation machinery: a term registry, Metropolis-Hastings simulation with a
genuine tie/no-tie proposal, maximum pseudolikelihood estimation, and Monte Carlo maximum
likelihood estimation, backed by an effect library covering the full node-covariate family,
dyadic covariates, the geometrically weighted family (including directed shared-partner support
and curved/free-decay estimation under both {opt method(mple)} and {opt method(mcmle)}), fixed
shared-partner counts, the complete degree-distribution family, and directed triad-closure terms
- see {help nwergm##limitations:Limitations} below for the complete current list, plus a narrow
term family for two-mode (bipartite) networks. What still sets {cmd:nwergm} apart from full
parity is scope, not term count: a wider bipartite term family and constraints beyond the free
binary dyad space are each a genuine architectural addition rather than another term to add, and
are not yet supported.

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
likelihood. This applies equally to a curved (free-decay) term ({opt gwespfree()} and its five
counterparts) - the curved MPLE fit is the {opt method(mcmle)} starting point, and MCMLE then
refines it using R ergm's own steplength/convergence approach (Hummel, Hunter, and Handcock
2012).

{pstd}
A curved decay parameter can be weakly identified on a small or sparse network, in which case
the fit legitimately converges to a boundary solution - decay near 0 (near-complete collapse to
a single shared-partner-count effect) or, less often, a large decay (near-complete insensitivity
to shared-partner count beyond the first). This is a property of the statistical model, not a
bug: R's own {cmd:ergm} converges to the same kind of boundary solution on the same data, and can
fail to converge at all on a genuinely poorly-identified network (occasionally so does
{cmd:nwergm}, reported honestly as a non-converged fit rather than a plausible-looking wrong
number - see {bf:e(converged)} below). A large standard error on the decay coefficient is the
usual sign this has happened; consider a longer {opt mcmcburnin()}, a larger
{opt mcmcsamplesize()}, a different starting decay, or a fixed-decay ({opt gwesp()} etc.) or
non-curved model instead.

{pstd}
{opt offset()} fixes a named coefficient at a known value instead of estimating it - useful for
imposing a theoretically-motivated effect size, reproducing a published model exactly, or holding
a nuisance term constant. Internally: for {opt method(mple)}, the fixed term's own known
contribution is passed to the underlying logistic regression as a GLM offset (the standard
mechanism for a fixed-coefficient term in any exponential-family regression), and only the
remaining coefficients are estimated; for {opt method(mcmle)}, the Newton step is restricted to
the free coefficients only, while the fixed term's own contribution still fully participates in
MCMC sampling (fixing a coefficient does not remove its term from the model - the network is
still simulated as if that effect were really present at the given strength). Multiple
coefficients may be fixed in one model: {bf:offset(mutual 2 gwesp_weight 0.5)}.

{marker limitations}{...}

{title:Supported network types}

{pstd}
Binary: yes (only) - MPLE/MCMLE estimation here is for a binary tie-formation model; a valued network's own tie values are not used as an outcome (no weighted ERGM family is implemented). Directed: yes, most terms have both directed and undirected forms (see the term list). Weighted: not applicable (see Binary). Signed: not applicable. Two-mode: yes, undirected only - a narrow term family so far ({opt edges}, {opt bcov1()}/{opt bcov2()}/{opt bfactor1()}/{opt bfactor2()}, {opt bdegree1()}/{opt bdegree2()}/{opt bstar1()}/{opt bstar2()}, {opt bnodematch1()}/{opt bnodematch2()}, {opt bgwdegree1()}/{opt bgwdegree2()}); see Limitations below.

{title:Limitations (v1 scope)}

{pstd}
{cmd:nwergm} estimates {bf:binary, static} ERGMs only:

{p2colset 9 13 15 2}{...}
{p2col: o}Two-mode (bipartite) networks are supported for a narrow term family:
{opt edges}; the dyad-independent {opt bcov1()}/{opt bcov2()}/{opt bfactor1()}/{opt bfactor2()}
family (R ergm's own {cmd:b1cov()}/{cmd:b2cov()}/{cmd:b1factor()}/{cmd:b2factor()} terms); the
dyad-dependent {opt bdegree1()}/{opt bdegree2()}/{opt bstar1()}/{opt bstar2()} family (R's own
{cmd:b1degree()}/{cmd:b2degree()}/{cmd:b1star()}/{cmd:b2star()} terms, needs {opt method(mcmle)});
and the also dyad-dependent {opt bnodematch1()}/{opt bnodematch2()} (R's own {cmd:b1nodematch()}/
{cmd:b2nodematch()}, default-parameter scope only) and {opt bgwdegree1()}/{opt bgwdegree2()} (R's
own {cmd:gwb1degree()}/{cmd:gwb2degree()}, fixed decay only) families. All twelve are renamed as
Stata OPTIONS only, because Stata's {cmd:syntax} command rejects an
option name with a digit followed by a letter; the reported coefficient names keep R's own
{cmd:b1cov_}{it:var}/{cmd:b1degree_}{it:d} spelling. Directed two-mode networks and every
one-mode-only term ({opt mutual}, {opt triangle}, {opt gwesp()}, {opt nodecov()}, {opt degree()},
etc.) are rejected with an explicit error on a two-mode network - never silently projected to one
mode or silently applied to a dyad space a term's change statistic was never derived for.{p_end}
{p2col: o}Temporal networks (snapshot/interval/event metadata) are rejected with an explicit
error - never silently collapsed to a single static slice.{p_end}
{p2col: o}Valued/weighted or signed networks are rejected with an explicit error - never
silently dichotomized or stripped of sign. Valued ERGMs are a materially different statistical
framework (Krivitsky 2012) and are tracked as a separate future initiative, not a small
extension.{p_end}
{p2col: o}{opt freedyads()} and {opt blockdiag()} restrict which dyads the MCMC proposal may ever
toggle - every other dyad is held fixed at its observed value for the rest of the fit (matching
R ergm's own {cmd:constraints=~fixallbut()} and {cmd:constraints=~blockdiag()} respectively).
Degree and egocentric constraints are still roadmap items, not yet supported. Both
{opt proposal(uniform)} and {opt proposal(tnt)} have a masked variant (masked
TNT restricts every population count - total dyads, current tie count, the "pick a random
existing tie" draw - to the free-dyad subspace only; a fully-free mask is statistically identical
to the ordinary unmasked proposal, confirmed by certification), so a constrained fit gets the
same TNT mixing advantage an unconstrained fit does, and MCMC sampling for a constrained model is
native (C)-accelerated when otherwise eligible (roughly 3.7x faster than Mata on a benchmark
network) - only {opt method(mple)}/curved fits keep using their own Mata-only free-dyad path
regardless. Verified to reproduce R ergm's own {cmd:fixallbut()} MPLE fit exactly (a fixed dyad's
own likelihood contribution is a theta-independent constant, so it drops entirely out of the
pseudolikelihood - confirmed directly: logit of the FREE-dyads-only density, not the full
network's own density) - see {browse "dev/freedyads_crosscheck.R"}. Only one of
{opt freedyads()}/{opt blockdiag()} may be given at a time.{p_end}
{p2col: o}{opt fixdensity} is a third, mutually exclusive dyad-space constraint: rather than
restricting WHICH dyads may vary (as {opt freedyads()}/{opt blockdiag()} do), it holds the total
tie COUNT itself invariant via a compound tie/non-tie swap proposal (R ergm's own
{cmd:constraints=~edges}), so cannot currently be combined with either. Requires
{opt method(mcmle)} (a fixed-density fit is never a plain MPLE, since MPLE never runs MCMC at all)
and at least one term besides {opt edges}; {opt edges} itself is simply never registered as an
estimated term under this constraint, rather than fit and reported as a theta-independent
constant the way R ergm itself displays it.{p_end}
{p2colreset}{...}

{pstd}
The effect library has grown considerably past its original small first-release set (see the
{cmd:Syntax} block above for the complete, current option list) and now covers, in addition to
{opt edges}/{opt mutual}: the node-covariate family ({opt nodematch()}, {opt nodematchdiff()},
{opt nodecov()}, {opt nodeicov()}/{opt nodeocov()}, {opt absdist()}, {opt nodefactor()},
{opt nodeofactor()}/{opt nodeifactor()}, {opt nodemix()}, {opt sender}, {opt receiver}); dyadic
covariates ({opt edgecov()}, {opt hamming()}); the geometrically weighted family
({opt gwesp()}/{opt gwdsp()}/{opt gwnsp()}/{opt gwdegree()}/{opt gwodegree()}/{opt gwidegree()})
with FIXED decay, plus a curved/free-decay counterpart for each of these five
terms ({opt gwespfree()}/{opt gwdegreefree()}/{opt gwdspfree()}/{opt gwnspfree()}/{opt gwodegreefree()}/
{opt gwidegreefree()}, both {opt method(mple)} and {opt method(mcmle)} supported); fixed shared-partner
counts ({opt esp()}/{opt dsp()}); the degree-distribution family ({opt degree()}/{opt odegree()}/
{opt idegree()}/{opt concurrent}/{opt kstar()}/{opt ostar()}/{opt istar()}/{opt degrange()}/
{opt odegrange()}/{opt idegrange()}); directed triad-closure terms ({opt triangle}/
{opt ctriple}/{opt transitiveties}/{opt cyclicalties}); and, for two-mode (bipartite) networks
only, the mode-restricted covariate family ({opt bcov1()}/{opt bcov2()}/{opt bfactor1()}/
{opt bfactor2()} - R ergm's own {cmd:b1cov()}/{cmd:b2cov()}/{cmd:b1factor()}/{cmd:b2factor()}
terms) and the mode-restricted degree/star family ({opt bdegree1()}/{opt bdegree2()}/
{opt bstar1()}/{opt bstar2()} - R's own {cmd:b1degree()}/{cmd:b2degree()}/{cmd:b1star()}/
{cmd:b2star()} terms) and the mode-restricted homophily/geometrically-weighted-degree family
({opt bnodematch1()}/{opt bnodematch2()}/{opt bgwdegree1()}/{opt bgwdegree2()} - R's own
{cmd:b1nodematch()}/{cmd:b2nodematch()}/{cmd:gwb1degree()}/{cmd:gwb2degree()} terms).
{opt gwesp()}/{opt gwdsp()}/{opt gwnsp()}/
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
All five directed shared-partner definitions R ergm itself offers are implemented. Two-mode/
bipartite support currently covers a narrow term family only (see {help nwergm##limitations:Supported network types} above); {cmd:balance}/signed-network terms are blocked (signed networks are not a
supported data type at all). {opt freedyads()}, {opt blockdiag()}, and {opt fixdensity} cover the
dyad-space and tie-count constraints implemented so far; degree constraints and egocentric
constraints are not yet implemented (fixed-coefficient/{opt offset()} support IS implemented -
see the {cmd:Syntax} block above). Basic MCMC diagnostics ({help nwergm_estat:estat mcmcdiag})
and basic goodness of fit ({help nwergm_estat:estat gof}) are both available; see
{help nwergm_estat}.

{marker native}{...}
{title:Performance: the native (C) MCMC backend}

{pstd}
{cmd:nwergm} ships a fully independent Mata implementation of its entire estimator (term
registry, MCMC sampler, MPLE, MCMLE) - this is always the reference implementation and is what
runs for every model on every platform. For a growing subset of models, {cmd:nwergm} ALSO
compiles the MCMC inner loop (for {opt method(mcmle)}) or the MPLE design-matrix build (for
{opt method(mple)}) into a native Stata plugin (C) and uses that instead, entirely
transparently: there is nothing to turn on, no option to set, and no difference in how results
are interpreted. Whether a given run used the native backend or the Mata one is purely a
performance detail, exposed only for curiosity via {bf:e(native)} after EITHER method - the two
are certified to produce statistically indistinguishable results for {opt method(mcmle)}
(independent random-number streams, so not bit-identical sample paths, but the same target
distribution; see the package's own {cmd:cscripts/test_nwergm_native.do}) and a bit-identical
design matrix for {opt method(mple)} (deterministic given a fixed graph, so native and Mata
agree exactly, not merely statistically). {opt nonative} forces the Mata backend deliberately
even on an otherwise native-eligible model, for testing or direct comparison; ordinary use never
needs it, since eligibility is otherwise detected and used automatically.

{pstd}
The native backend requires a compiled plugin for the current platform (macOS is built and
shipped; Windows/Linux build automatically via the package's own CI once available there). Given
a compiled plugin, every term and every constraint mechanism {cmd:nwergm} implements is
native-eligible - the one-mode term library ({opt edges}, {opt mutual}, every node-covariate term,
the full degree-distribution family, and the entire shared-partner family under every
{opt type()}); the dyadic-covariate terms {opt edgecov()}/{opt hamming()}; the two-mode
(bipartite) term library ({opt bcov1()}/{opt bcov2()}/{opt bfactor1()}/{opt bfactor2()}/
{opt bdegree1()}/{opt bdegree2()}/{opt bstar1()}/{opt bstar2()}/{opt bnodematch1()}/
{opt bnodematch2()}/{opt bgwdegree1()}/{opt bgwdegree2()}); every curved (free-decay) term's own
raw statistic ({opt gwespfree()}/{opt gwdegreefree()}/{opt gwdspfree()}/{opt gwnspfree()}/
{opt gwodegreefree()}/{opt gwidegreefree()}); and {opt offset()}/{opt freedyads()}/
{opt blockdiag()}/{opt fixdensity}, none of which change a model's own native eligibility (a
masked or fixed-density model runs native exactly when an ordinary model with the same terms
would - see {bf:Remarks} above for {opt fixdensity}'s own compound tie/non-tie swap proposal,
which the native backend implements too). A model still falls back to the Mata sampler as a
whole when it exceeds the native backend's own fixed capacity limits on term/attribute/covariate
count - the WHOLE model, never "some terms in C, some in Mata", since every term's own change
statistic must be evaluated on every proposal, and there is no way to cross the Mata/C boundary
selectively without doing so on every single MCMC step (which would defeat the entire purpose).

{pstd}
For a curved term ({opt gwespfree()}/{opt gwdegreefree()}/{opt gwdspfree()}/
{opt gwodegreefree()}/{opt gwidegreefree()}) under {opt method(mple)}, the native backend
additionally fits the Newton-Raphson optimization itself in C (not just the design-matrix
build), when eligible - still exposed only via {bf:e(native)}, since a curved fit and its own
design-matrix build always share the same native-or-Mata routing. On a genuine boundary solution
(the estimated decay collapsing toward 0, a real, if uncommon, outcome discussed under
{opt method()} above), the native fit uses the same generalized-inverse handling of a singular
final Fisher information matrix that Mata's own {cmd:invsym()}-based fit uses, rather than
falling back to Mata. Under {opt method(mcmle)}, a curved term's MCMC sampling is
native-accelerated the same way any other {opt method(mcmle)} fit's is; the outer estimating
step itself (translating each simulated sample into the next coefficient update) always runs in
Mata, curved or not.

{pstd}
Concretely, on direct head-to-head benchmarks against R's own {cmd:ergm} 4.12.0 (default
settings on both sides, median of 5 repeated runs): a 30-node directed {opt edges}+{opt mutual}
model runs at roughly 1.15x R's own time; a 100-node directed
{opt edges}+{opt mutual}+{opt nodematch()} model at roughly 0.62x - FASTER than R; a 100-node
undirected {opt edges}+{opt gwesp()} model at roughly 1.0x (essential parity); a 500-node sparse
undirected {opt edges}+{opt nodematch()}+{opt gwesp()} model at roughly 0.9x - FASTER than R;
and a 1000-node directed {opt edges}+{opt mutual}+{opt nodematch()} control at roughly 0.6x -
FASTER than R. On a real
published network (the {it:E. coli} transcriptional-regulation network of Salgado et al. 2001
and Shen-Orr et al. 2002, 418 nodes, 519 edges, distributed with R's own {cmd:ergm} package as
{cmd:data(ecoli)}), median of five runs each side: a fixed-decay
{opt edges}+{opt gwesp(.25)} model ({opt method(mcmle)}) runs at roughly 1.2x R's own time, and
its curved, freely-estimated counterpart {opt edges}+{opt gwespfree(.25)}
({opt method(mple)}) at roughly 2.1x.

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
	  {bf:e(native)}		1 if the native (C) backend was used for this run (the MCMC sampler
					for method(mcmle); the MPLE design-matrix build for method(mple)),
					0 if the Mata implementation ran instead - purely informational,
					see {help nwergm##native:Performance} below

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
Fit, Simulate and Diagnose Exponential-Family Models for Networks. {it:Journal of Statistical Software}, 24(3), 1-29.

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
by the Statnet project.

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
{opt nodefactor()} with $ categories, or {opt degree(2 3 4)}) consumes that many consecutive
entries from {opt theta()}, in the same left-to-right order its own levels/values are listed.
There is no per-term coefficient sub-option, by design, so this exactly reuses the same
term-construction code {cmd:nwergm}'s own estimation path uses rather than a parallel
implementation.

{pstd}
{bf:The resulting simulated network's own dataset does not carry the caller's covariate variable(s) forward.} Each simulated draw is built via a fresh {cmd:nwset} call that replaces
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

	{help nwqap}, {help nwrandom}, {help nwcug}, {help nwintro##limits:feasible network sizes}

