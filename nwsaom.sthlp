{smcl}
{* *! version 1.0.0  28aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_statmodels:[NW-2.6.6] Statistical Estimation of Networks}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwsaom {hline 2}}Stochastic actor-oriented model (SAOM) estimation between observed network waves{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwsaom}
{cmd:,}
{opt wave1(netname)} {opt wave2(netname)}
{it:or}
{opt waves(namelist)}
{opt outdegree} [{opt reciprocity}]
[{opth nodematch(varname)}]
[{opth nodecov(varname)}]
[{opth nodeicov(varname)}]
[{opth nodeocov(varname)}]
[{opt indegpopularity}]
[{opt outpopularity}]
[{opt outactivity}]
[{opt inactivity}]
[{opt transtrip}]
[{opt cycle3}]
[{opt transties}]
[{opt balance}]
[{opt gwesp(real)}]
[{opth simcov(varname)}]
[{opth egox(varname)}]
[{opth altx(varname)}]
[{opth samex(varname)}]
[{opth simx(varname)}]
[{opth behavior(varlist)}
{opt linear}
{it:or}
{opt linearendow} {opt linearcreation}
{opt quadratic}
{opt avalt}
{opt avsim}
{opt behtheta0(numlist)}]
[{opt rate0(real)}
{opt theta0(numlist)}
{opt k0(int)}
{opt k3(int)}
{opt firstg(real)}
{opt seed(int)}]

{synoptset 22 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt wave1(netname)}}First observed wave; requires {opt wave2()}, exactly two waves. Not combinable with {opt waves()}{p_end}
{synopt:{opt wave2(netname)}}Second (ending) observed wave; requires {opt wave1()}{p_end}
{synopt:{opt waves(namelist)}}Two or more observed waves, in temporal order (e.g. {cmd:waves(w1 w2 w3)}) - chains {it:namelist}{cmd:-1} inter-wave periods into one pooled fit. Not combinable with {opt wave1()}/{opt wave2()}{p_end}
{synopt:{opt outdegree}}Outdegree (density) effect; {bf:required} in every model{p_end}
{synopt:{opt reciprocity}}Reciprocated-tie effect{p_end}
{synopt:{opth nodematch(varname)}}Homophily on a categorical node attribute (exact match); ONE variable per model - RSiena alias {opt samex()}{p_end}
{synopt:{opth nodecov(varname)}}Continuous covariate main effect (sum over sender's and receiver's own values); ONE variable per model{p_end}
{synopt:{opth nodeicov(varname)}}Alter (receiver) covariate effect - RSiena's own "altX"; ONE variable per model - RSiena alias {opt altx()}{p_end}
{synopt:{opth nodeocov(varname)}}Ego (sender) covariate effect - RSiena's own "egoX"; ONE variable per model - RSiena alias {opt egox()}{p_end}
{synopt:{opt indegpopularity}}Indegree popularity, sqrt-transformed ("preferential attachment" toward already-popular alters){p_end}
{synopt:{opt outpopularity}}Outdegree popularity, sqrt-transformed{p_end}
{synopt:{opt outactivity}}Outdegree activity, squared (concentrates out-ties on already-active senders){p_end}
{synopt:{opt inactivity}}Indegree activity, sqrt-transformed{p_end}
{synopt:{opt transtrip}}Transitive triplets (weighted count of transitive closures i->j via existing two-paths){p_end}
{synopt:{opt cycle3}}Directed 3-cycles (i->j->h->i){p_end}
{synopt:{opt transties}}RSiena's own "transTies" - existence-indicator triadic closure (simpler, more robust alternative to {opt transtrip}); no parameter{p_end}
{synopt:{opt balance}}RSiena's own structural balance; no user-supplied parameter - the "balanceMean" constant is computed automatically from the observed wave data{p_end}
{synopt:{opt gwesp(real)}}Geometrically weighted edgewise shared partners (OTP-directed), fixed decay - argument is the DIRECT decay value (Statnet's own {opt gwesp(decay=)} scale), NOT RSiena's own "parameter" (RSiena's own value is 100x this one - RSiena {cmd:gwespFF(69)} = {opt gwesp(.69)} here){p_end}
{synopt:{opth simcov(varname)}}Covariate similarity effect; ONE variable per model - RSiena alias {opt simx()}{p_end}
{synopt:{opth egox(varname)}}RSiena naming alias for {opt nodeocov()} - identical effect, coefficient label follows this spelling{p_end}
{synopt:{opth altx(varname)}}RSiena naming alias for {opt nodeicov()} - identical effect, coefficient label follows this spelling{p_end}
{synopt:{opth samex(varname)}}RSiena naming alias for {opt nodematch()} - identical effect, coefficient label follows this spelling{p_end}
{synopt:{opth simx(varname)}}RSiena naming alias for {opt simcov()} - identical effect, coefficient label follows this spelling{p_end}
{synopt:{opth behavior(varlist)}}Co-evolution (harmonisation unit 26): one bounded-integer behavior variable, ONE Stata variable name per wave, same temporal order as {opt wave1()}/{opt wave2()} or {opt waves()} (e.g. two waves: {cmd:behavior(b1 b2)}; three: {cmd:behavior(b1 b2 b3)}). Requires {opt linear}. A SECOND dependent variable evolving jointly with the network - see {help nwsaom##coev:Co-evolution} below{p_end}
{synopt:{opt linear}}Behavior linear shape effect (RSiena's own baseline behavior effect), evaluation-function role; {bf:required} whenever {opt behavior()} is specified UNLESS {opt linearendow}/{opt linearcreation} are given instead, matching {opt outdegree}'s own required-baseline role on the network side{p_end}
{synopt:{opt linearendow}}Behavior linear effect, ENDOWMENT (loss/decrease) role - splits the linear effect's downward direction into its own parameter; must be given together with {opt linearcreation}, and not combined with {opt linear} (all three roles together are exactly collinear). See {help nwsaom##endowcreation:Endowment/creation functions} below{p_end}
{synopt:{opt linearcreation}}Behavior linear effect, CREATION (gain/increase) role - the upward-direction counterpart to {opt linearendow}; must be given together with it{p_end}
{synopt:{opt quadratic}}Behavior quadratic shape effect; requires {opt behavior()}, not combinable with {opt linearendow}/{opt linearcreation}{p_end}
{synopt:{opt avalt}}Behavior "average alter" influence effect - own value moves toward network neighbors' own average value; requires {opt behavior()}{p_end}
{synopt:{opt avsim}}Behavior "average similarity" influence effect - own value moves to maximize average similarity to network neighbors' own values, net of a data-derived centering constant; requires {opt behavior()}{p_end}
{synopt:{opt behtheta0(numlist)}}Starting values for the behavior-side eval-parameter vector, one per requested behavior effect in the order {opt linear} (or {opt linearendow}/{opt linearcreation})/{opt quadratic}/{opt avalt}/{opt avsim} appear above; default all zero{p_end}
{synopt:{opt rate0(real)}}Accepted for backward compatibility only - {bf:no longer used}; the rate parameter's own starting value is now computed automatically from the observed data via RSiena's own verified closed-form formula (see {bf:Remarks} below){p_end}
{synopt:{opt theta0(numlist)}}Starting values for the eval-parameter vector, one per requested effect IN THE ORDER LISTED IN THE ERROR MESSAGE if omitted or mis-sized (outdegree first, then every other effect in the order its own option appears above); default all zero{p_end}
{synopt:{opt k0(int)}}Phase-1 replicate count (Jacobian estimation via the score-function derivative estimator); default 50{p_end}
{synopt:{opt k3(int)}}Phase-3 replicate count (convergence diagnostics and the covariance matrix e(V)); default 1,000{p_end}
{synopt:{opt firstg(real)}}Phase-2 starting gain (Robbins-Monro step size); default 0.2, matching RSiena's own default{p_end}
{synopt:{opt seed(int)}}Set the random-number seed before simulating (for reproducibility){p_end}
{synoptline}
{p2colreset}{...}

{title:Postestimation syntax}

{p 8 17 2}
{cmd:estat gof}
{cmd:[}{cmd:,}
{opt nsim(int)}
{opt seed(int)}
{opt stats(namelist)}
{opt maxdeg(int)}
{opt maxdist(int)}
{opt twotailed}
{opt name(string)}{cmd:]}

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt nsim(int)}}Number of fresh post-fit simulated replicates forming the reference distribution; default 50, minimum 5{p_end}
{synopt:{opt seed(int)}}Set the random-number seed before simulating{p_end}
{synopt:{opt stats(namelist)}}Auxiliary statistics to test, any of {bf:outdegree}, {bf:indegree}, {bf:geodesic}, {bf:behavior}; default all three network statistics, plus {bf:behavior} automatically whenever the fit in memory used {opt behavior()} ({bf:behavior} itself requires a co-evolution fit){p_end}
{synopt:{opt maxdeg(int)}}Highest EXACT out-/in-degree category before the ("maxdeg+") overflow bin; default 15{p_end}
{synopt:{opt maxdist(int)}}Highest EXACT geodesic-distance category before the ("NR", not reached) overflow bin; default 6{p_end}
{synopt:{opt twotailed}}Report a two-tailed p-value instead of the one-tailed default (RSiena's own {cmd:twoTailed=FALSE} default: reject for a SMALL p only, i.e. the observed network is an outlier relative to what the fitted model simulates){p_end}
{synopt:{opt name(string)}}Stub for the violin-plot graph names; default {cmd:gof} (graphs are named {cmd:{it:name}_outdegree}, {cmd:{it:name}_indegree}, {cmd:{it:name}_geodesic}){p_end}
{synoptline}
{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwsaom} fits a stochastic actor-oriented model (SAOM, Snijders-style) between two or more
observed panel waves of the same directed network on a fixed actor set - a fully native
Stata/Mata implementation, no R or other external statistical software called at any point. The
{browse "https://www.stats.ox.ac.uk/~snijders/siena/":RSiena} package (Ripley, Snijders et al.)
was studied in detail as the methodological reference throughout development - both its published
manual and, where the manual alone was not enough, its own real R/C++ source (read directly via
{cmd:gh api} against {browse "https://github.com/stocnet/rsiena":github.com/stocnet/rsiena} during
development) - and used, during development only, to certify {cmd:nwsaom}'s own independently
written implementation against real reference output. {cmd:nwsaom} is an independent
reimplementation and is not affiliated with or endorsed by the RSiena project.

{pstd}
An SAOM models network change as a sequence of unobserved, actor-driven "ministeps": between
consecutive observed waves, actors are activated one at a time (at a rate governed by the model's
own rate parameter) and each activated actor may create or drop exactly one of its own outgoing
ties, choosing among the available alternatives (including "no change") via a multinomial-logit
choice model on a linear combination of effect-specific "change statistics", weighted by the
effect's own estimated coefficient. This actor-oriented, MYOPIC formulation - an actor's own
choice is evaluated purely from that actor's own resulting local network statistic, never from
how the choice would affect any OTHER actor's own statistics - is what genuinely distinguishes an
SAOM from an ERGM (see {help nwergm}): an ERGM has no actors or ministeps at all, only a single
global probability distribution over entire graphs. Coefficients are estimated by the Method of
Moments via Robbins-Monro stochastic approximation (RSiena's own default estimation algorithm),
not maximum likelihood.

{pstd}
{bf:A genuine, hard-won methodological lesson from this implementation's own development,
worth stating explicitly here}: several of RSiena's own effects (e.g. {opt gwesp()}) compute their
observed/global statistic in a way that is IDENTICAL to the corresponding ERGM statistic, which
made it tempting to also reuse an ERGM package's own change-statistic (ministep) formula for the
same effect - this is WRONG in general. RSiena's own ministep formula for a given effect is
restricted to the ACTIVATED ACTOR'S OWN statistic only (the myopic-actor rule above), which for
several effects is a genuinely SMALLER quantity than the effect's own full ERGM change statistic
(which legitimately captures the toggle's effect on every actor's own statistic, appropriate for
an ERGM's single-actor-free global model but not for an SAOM ministep). Every effect below was
independently re-derived and verified against RSiena's own real ministep-contribution source
code, not assumed from its global-statistic formula alone; see {help nwsaom##effects:Effect
library} below for the account, term by term, including one case ({opt gwesp()}) where an initial
reuse assumption was shipped, caught, and corrected during this package's own development - kept
in that section's own account rather than silently erased, matching this whole package's
disclosure standard.

{title:Performance}

{pstd}
{cmd:nwsaom} has a native (C) simulation backend, used automatically whenever the fitted model's
effects all have native coverage (no option needed to opt in - see {bf:Estimation} below and, for
co-evolution, the note at the end of {help nwsaom##coev:Co-evolution} below). A direct, reproducible
wall-clock comparison against a real, installed RSiena (version 1.6.6, R 4.6.0) - identical data,
identical model, single run each, scripts and full methodology in {browse "dev/saom_rsiena_benchmark.R"}
and {browse "dev/saom_rsiena_benchmark.do"} - on RSiena's own standard s50 tutorial dataset (50
students, friendship network + alcohol-use behavior, waves 1-2):

{p2colset 9 13 15 2}{...}
{p2col: o}outdegree + reciprocity: RSiena 0.96s, {cmd:nwsaom} 0.94s{p_end}
{p2col: o}+ behavior(alcohol), linear + quadratic: RSiena 1.18s, {cmd:nwsaom} 0.63s{p_end}
{p2colreset}{...}

{pstd}
For the network-only model {cmd:nwsaom} is at parity with real RSiena; for the co-evolution model
it is genuinely faster. This did not happen by accident: an earlier round of this same benchmark
found {cmd:nwsaom} roughly 22x slower (network-only) and 3.2x slower (co-evolution) than real
RSiena, and both gaps were profiled and closed - not by approximating the method more coarsely, but
by finding and eliminating real, avoidable overhead (a rate-refinement loop that had never been
ported to the native backend, and a co-evolution code path that was silently redoing, in slow
interpreted Mata, statistic computations the native backend had already computed in C). See
{browse "docs/SAOM_ROADMAP.md"}'s own harmonisation-unit-30/31/32 entries for the full, measured
account of each fix.

{title:Supported network types}

{pstd}
Binary: yes (only) - a valued/weighted wave is rejected. Directed: yes (required) - SAOM's own
ministep formulation is inherently directed (an actor controls only its own outgoing ties); an
undirected wave is rejected. Two-mode: no (rejected). Signed: not applicable/not supported.

{title:Limitations (v1 scope)}

{pstd}
{cmd:nwsaom} estimates {bf:binary, directed, one-mode} SAOMs on a {bf:fixed actor set} (no
composition change/joiners-leavers) with {bf:no missing tie data}:

{p2colset 9 13 15 2}{...}
{p2col: o}Two-mode (bipartite), temporal-metadata, valued/weighted, or undirected waves are all
rejected with an explicit error - never silently coerced.{p_end}
{p2col: o}Every wave must have the SAME node count - composition change (actors entering/leaving
between waves) is not supported.{p_end}
{p2col: o}Missing tie data between waves is not supported (RSiena's own missing-data machinery,
including its own effect on the "balanceMean" constant under {opt balance}, is not implemented).{p_end}
{p2col: o}Behavior co-evolution ({opt behavior()}, harmonisation unit 26) supports exactly ONE
co-evolving behavior variable. The linear shape effect can be split into endowment/creation roles
({opt linearendow}/{opt linearcreation}, harmonisation unit 28); no other behavior effect has this
split yet, and network-side endowment/creation is not implemented - see
{help nwsaom##coev:Co-evolution} below.{p_end}
{p2colreset}{...}

{pstd}
Each of {opt nodematch()}, {opt nodecov()}, {opt nodeicov()}/{opt egox()}, {opt nodeocov()}/
{opt altx()}, {opt simcov()}/{opt simx()} accepts exactly ONE variable per model (unlike
{help nwergm}'s own {opt varlist}-based options) - a real, current v1 restriction, not a design
choice expected to be permanent.

{marker effects}{...}
{title:Effect library}

{pstd}
{bf:outdegree} and {bf:reciprocity} are the base structural effects, direct RSiena analogues of
{help nwergm}'s own {opt edges}/{opt mutual}.

{pstd}
{bf:nodematch()}/{bf:nodecov()}/{bf:nodeicov()}/{bf:nodeocov()} are direct reuses of
{help nwergm}'s own already-certified covariate-effect statistic/change-statistic pair - each is a
genuine single-actor-local effect (an actor's own choice depends only on its own and the specific
alter's own covariate value), so no myopic-actor restriction was needed here; RSiena's own naming
maps as {opt nodeocov()} = "egoX" (sender's own value), {opt nodeicov()} = "altX" (receiver's own
value), {opt nodematch()} = "sameX", {opt nodecov()} = their combined sum.

{pstd}
{bf:indegpopularity}/{bf:outpopularity}/{bf:outactivity}/{bf:inactivity} are freshly derived
SAOM-native effects (no ERGM analogue reused) - sqrt-transformed in/outdegree popularity, squared
outdegree activity, and sqrt-transformed indegree activity respectively, each independently
verified against RSiena's own real effect source before implementation. A genuine, disclosed
subtlety: unlike a single-actor-local covariate effect above, these effects' own ministep deltas
do NOT equal a toggle's effect on the global statistic (toggling one tie changes OTHER actors' own
popularity/activity statistics too) - expected behavior for a myopic-actor SAOM formulation, not a
bug.

{pstd}
{bf:transtrip} (transitive triplets) and {bf:cycle3} (directed 3-cycles) are freshly derived,
reusing {cmd:nwsaom}'s own already-certified shared-partner primitives (two-path/out-star/in-star
counts) rather than any ERGM term-function pair directly - {opt transtrip}'s own ministep delta is
OTP(i,j)+OSP(i,j); {opt cycle3}'s is OTP(j,i) (a genuinely different, easy-to-get-backwards
argument order from {opt transtrip}'s own).

{pstd}
{bf:transties} (RSiena's own "transTies") is a simpler, existence-indicator alternative to
{opt transtrip}: a tied arc i->j counts toward the statistic if AND ONLY IF a two-path i->k->j
already exists, rather than {opt transtrip}'s own weighted count of every such two-path. Verified
directly against RSiena's real {cmd:TransitiveTiesEffect.cpp} - its OWN dedicated ministep-
contribution class (not a "Generic effect" wrapper, see {opt gwesp()} below), so its own ministep
formula genuinely is the exact myopic-actor-restricted gradient of a well-defined local statistic;
certified via brute-force recomputation, not merely assumed.

{pstd}
{bf:balance} (RSiena's own structural balance) has NO user-supplied parameter: RSiena's own
"balanceMean" constant (the SIENA manual's {it:b0}) is a DATA-DERIVED quantity - the empirical mean
of |x_ih - x_jh| over every distinct valid actor triple in the observed wave data - computed
automatically from the wave(s) supplied to {opt wave1()}/{opt wave2()} or {opt waves()} at
estimation time, pooled across every inter-wave PERIOD'S OWN starting wave by summing
numerators/denominators separately and dividing once (RSiena's own {cmd:calcBalmean()} pooling
convention exactly, not an average of per-period ratios). Like {opt transties}, {opt balance} has
its own dedicated RSiena ministep class, and was independently verified against RSiena's real
{cmd:BalanceEffect.cpp} source before implementation.

{pstd}
{bf:gwesp(real)} (geometrically weighted edgewise shared partners, OTP-directed) reuses
{help nwergm}'s own already-certified GLOBAL/observed statistic directly (RSiena's own
{cmd:tieStatistic()} confirmed to match it exactly) but NOT its own full ERGM change statistic for
the ministep: RSiena's real {cmd:gwespFF} effect is wired through its own "Generic effect"
framework ({cmd:GenericNetworkEffect::calculateContribution()}), whose own ministep contribution
is JUST the geometric-decay kernel's own lookup for the toggled dyad's CURRENT shared-partner
count - no neighbor-adjustment loops at all - a genuinely simpler, deliberate approximation
specific to that framework, NOT the same quantity as {help nwergm}'s own full change statistic
(own-dyad term plus two neighbor-adjustment loops, correct for an ERGM MCMC toggle's effect on the
GLOBAL statistic, but the wrong standard for an SAOM ministep). {bf:This package's own first
version of this effect assumed the two were interchangeable "by mathematical necessity" - they are
not; the mistake was caught and corrected during development (see docs/SAOM_ROADMAP.md's own
"GWESP" entry for the full, disclosed account), and the corrected formula is what ships here.} The
{opt gwesp()} argument is the DIRECT decay value (Statnet's own convention, matching
{help nwergm}'s own {opt gwesp()}) - NOT RSiena's own user-facing "parameter", which is 100x this
value (RSiena's default {cmd:gwespFF(69)} corresponds to {opt gwesp(.69)} here).

{pstd}
{bf:simcov(varname)} (covariate similarity) is freshly derived and independently verified against
RSiena's real {cmd:CovariateSimilarityEffect.cpp}/{cmd:Covariate.cpp} source: Delta =
plus-or-minus(1 - |attr_i - attr_j| / range), where {it:range} is the observed variable's own
max-minus-min. A disclosed simplification: this omits RSiena's own {cmd:similarityMean} centering
constant - a pure re-parameterization against the always-present {opt outdegree} term, not a
correctness gap.

{marker coev}{...}
{title:Co-evolution (network + behavior)}

{pstd}
{opt behavior(varlist)} adds a SECOND dependent variable - a bounded-integer "behavior" (an actor
attribute, e.g. an ordinal opinion or a count) that evolves ALONGSIDE the network between the same
observed waves, with its own rate function and its own evaluation function, estimated JOINTLY with
the network side via a single Method-of-Moments fit. This is what lets a fitted model separate
SELECTION (network effects that depend on the behavior - {opt simcov()}/{opt nodeicov()}/
{opt nodeocov()} above) from INFLUENCE (behavior effects that depend on the network, below) in the
SAME model. Verified directly against RSiena's own real source
({cmd:src/model/EpochSimulation.cpp}, {cmd:src/model/variables/BehaviorVariable.cpp}): at each
ministep opportunity, ONE pooled exponential waiting time is drawn from the grand total rate
(summed across BOTH variables' own total rates), which variable gets to act is chosen proportional
to its own share of that total, then an actor is chosen uniformly within that variable - the same
continuous-time construction the network side alone already uses (see {bf:Estimation} above),
generalized to a race between two competing Poisson processes. A behavior ministep has exactly
THREE alternatives (change by -1, 0, or +1, clamped at the observed min/max range), chosen via the
same multinomial-logit construction as a network ministep, now over 3 alternatives instead of n.

{pstd}
{bf:linear} (RSiena's own {cmd:LinearShapeEffect}) is the behavior-side analogue of {opt outdegree}
- {bf:required} whenever {opt behavior()} is specified. Ministep delta = the raw change (\xb11);
global/observed statistic = the raw sum of every actor's own current value.

{pstd}
{bf:quadratic} (RSiena's own {cmd:QuadraticShapeEffect}) - a genuine, easy-to-miss subtlety caught
by reading the actual RSiena source, not the manual, and kept exactly as RSiena has it rather than
"fixed" toward internal consistency (matching real RSiena's own numbers is this package's own
certification standard throughout): the MINISTEP delta uses the CENTERED value
({cmd:(2*(value-mean)+diff)*diff}), but the GLOBAL/observed statistic sums the RAW, uncentered
value squared - two genuinely different scales for the same effect, both needed.

{pstd}
{bf:avalt} (RSiena's own "avAlt", {cmd:AverageAlterEffect}) is the canonical INFLUENCE effect: an
activated actor's own behavior value is pulled toward the average current value of that actor's own
network neighbors (ministep delta = {cmd:diff * average-neighbor-value}, 0 for an actor with no
out-ties). {bf:A genuine, disclosed small-sample finding from certifying the joint estimator}: at a
small toy scale (a handful of actors, on the order of RSiena's own smallest worked examples),
{opt avalt} specifically can make the joint Robbins-Monro fit genuinely diverge - not a bug, but a
real small-sample identification problem (too few behavior-ministep opportunities for
Robbins-Monro to stay stable against this effect's own self-reinforcing nonlinearity: a stronger
pull produces a more deterministic ministep, which produces an even stronger apparent pull).
Confirmed directly (the phase-1 Jacobian is well-conditioned and the simulator is unbiased AT the
true generating theta - ruling out a formula bug) and resolved simply by using a network with more
actors/behavior activity; see {browse "docs/SAOM_ROADMAP.md"}'s own unit-26 entry for the full
account.

{pstd}
{bf:avsim} (RSiena's own "avSim", verified directly against {cmd:SimilarityEffect.cpp} - the
{cmd:average=TRUE, hi=TRUE, lo=TRUE} construction {cmd:EffectFactory.cpp} itself dispatches
{cmd:"avSim"} to) is a SECOND, alternative influence parameterization to {opt avalt}: instead of
pulling an actor's own value toward its neighbors' own AVERAGE VALUE, {opt avsim} pulls it toward
maximizing its own AVERAGE SIMILARITY to neighbors (sim(a,b) = 1 - |a-b|/range), net of a
DATA-DERIVED "similarityMean" centering constant - RSiena's own {it:b0}-style constant, playing
exactly the same role {opt balance}'s own {it:balanceMean} does on the network side: computed
automatically from the observed behavior data (every PERIOD-BASE wave, i.e. every wave except the
very last, pooled by summation over every ordered actor pair - the identical pooling convention
{opt balance}'s own constant already uses), never user-supplied. A real, disclosed quirk verified
directly from RSiena's own R-side {cmd:rangeAndSimilarity()} source (not invented): this constant
is defined as exactly 0 whenever the pooled data has zero variance, rather than the 1 the general
formula would otherwise give.

{marker endowcreation}{...}
{pstd}
{bf:Endowment/creation functions} ({opt linearendow}/{opt linearcreation}, harmonisation unit 28):
real RSiena models network/behavior change via three possible "roles" for any effect - evaluation
(the default, direction-blind), creation (contributes only when the value INCREASES), and endowment
(contributes only when it DECREASES) - and its own manual states that using an effect in all THREE
roles together is exactly collinear ("never in all three... this leads to collinearity"). {cmd:nwsaom}
lets the behavior-side {bf:linear} effect be split this way: {opt linearendow} and {opt linearcreation}
must be specified TOGETHER, replacing plain {opt linear} (not combinable with it). {bf:This split is
genuinely, and expectedly, weakly identified} - real RSiena's own manual says so explicitly
("Separating the contribution of an effect into two functions requires more of the data... this
would lead to large standard errors") and its own live diagnostics confirm it on real data (a
direct cross-check against real RSiena on RSiena's own s50+alcohol tutorial dataset produced
RSiena's own {cmd:"Standard errors not reliable"}/{cmd:"Covariance matrix not positive definite"}
warnings for this exact model). Because of this, an {cmd:nwsaom} fit using
{opt linearendow}/{opt linearcreation} can legitimately stop with an error reporting that
{bf:thetaBound} (a coefficient's own magnitude exceeding 50 during estimation) was exceeded -
this is {cmd:nwsaom}'s own port of real RSiena's IDENTICAL safeguard for the identical situation
(its own {cmd:R/phase2.r} checks the same condition, at the same point, with the same default
bound), not a bug: if it happens, try plain {opt linear} instead, or supply better starting values
via {opt behtheta0()}. See {browse "docs/SAOM_ROADMAP.md"}'s own harmonisation-unit-28/29 entries
for the full account, including the real-RSiena cross-check that motivated shipping this rather
than withholding it.

{pstd}
{opt behtheta0()} sets starting values for the behavior-side eval-parameter vector (parallel to
{opt theta0()} for the network side); the behavior rate's own starting value is computed
automatically from the observed behavior data via RSiena's own closed-form formula for the general
(non-binary) case, mirroring how the network rate's own starting value is computed (see
{bf:Estimation} below) - a disclosed simplification that skips RSiena's own separate binary-behavior
logistic formula.

{pstd}
{opt behavior()} works with EITHER {opt wave1()}/{opt wave2()} (exactly two waves) OR
{opt waves()} (three or more, chaining {it:nwaves}{cmd:-1} periods exactly as the network-only case
does - see {bf:Estimation} below); it needs exactly one behavior variable name per wave, in the same
temporal order. The coefficient table shows both variables' own effects in ONE table, network
coefficients unprefixed and every behavior coefficient prefixed {cmd:beh_} (e.g. {cmd:beh_linear},
{cmd:beh_avalt}) so the two evaluation functions stay visually distinct while being reported as the
single joint fit they actually are. Two separate rate parameters are reported throughout - see
{bf:Stored results} below - and {cmd:estat gof} gains a fourth default auxiliary statistic,
{bf:behavior} (RSiena's own {cmd:BehaviorDistribution}: the exact bounded-value distribution of
behavior values, no overflow category since every value is already clamped to
{cmd:[min,max]} by construction), automatically added to the default {opt stats()} list.

{pstd}
Co-evolution has the same native (C) speed backend as the network-only case (see {bf:Performance}
above), used automatically - no option needed to opt in - whenever every network AND every behavior
term in the model has native coverage; a fit combining even one not-yet-natively-ported term on
either side transparently falls back to the fully-certified, always-available Mata engine for the
WHOLE fit, never a silent partial native run. {bf:linearendow}/{bf:linearcreation} (below) are one
such case: they always run on the Mata engine, not the native backend, so a fit using them will be
noticeably slower than the {bf:Performance} section's own benchmark numbers, which are for
evaluation-function-only models.

{pstd}
{bf:Genuinely out of scope for co-evolution v1} (tracked, not silently dropped): endowment/creation
for any behavior effect OTHER than {bf:linear} ({opt quadratic}/{opt avalt}/{opt avsim} - not yet
attempted); network-side endowment/creation (not yet attempted); more than one co-evolving behavior
variable.

{title:Estimation}

{pstd}
Coefficients are estimated by the Method of Moments via Robbins-Monro stochastic approximation,
matching RSiena's own default algorithm and phase structure: Phase 1 estimates the Jacobian
(sensitivity of each effect's own expected statistic to each coefficient) via {opt k0()}
independent simulated replicates at the starting coefficients; Phase 2 performs the actual
Robbins-Monro coefficient update across RSiena's own default of 4 diminishing-gain subphases
(unconditionally reused, not re-derived: {cmd:nsub=4}, {cmd:firstg} default 0.2,
{cmd:reduceg=0.5}, per-subphase minimum/maximum simulation-count schedule per RSiena's own
{cmd:siena07.r}); Phase 3 runs {opt k3()} further replicates at the final coefficients to compute
the reported standard errors/covariance matrix (e(V), RSiena's own sandwich-formula construction)
and each parameter's own phase-3 convergence t-ratio (e(tratio) - a SEPARATE diagnostic from the
Std. Err./z/P>|z| columns, which come from e(V); RSiena's own convention treats |t| well under 1 as
good convergence).

{pstd}
{bf:The rate parameter} (the per-period intensity governing how often actors are activated to
ministep) is estimated via real RSiena's own verified CONDITIONAL-estimation construction
(harmonisation unit 27), confirmed directly from RSiena's own real source and cross-checked live
against the installed RSiena package: a closed-form formula gives a starting value, then {opt k3()}
independent replicate simulations - each run not for a fixed time interval but UNTIL the simulated
network's own distance from the observed starting wave reaches the observed target (the same
Hamming distance between waves used elsewhere) - are averaged to give the refined estimate
{cmd:e(rate)}, with {cmd:e(rate_se)} (shown alongside it, in parentheses, matching real RSiena's own
printed convention) the raw standard deviation of those replicate draws (RSiena's own convention,
not divided by {opt k3()}'s own square root). Verified on RSiena's own real reference dataset:
{cmd:e(rate)} matches RSiena's own real fitted rate to within 0.1%, {cmd:e(rate_se)} to within 5%
(see {browse "docs/SAOM_ROADMAP.md"}'s own harmonisation-unit-27 entry for the full account,
including a real bug found and fixed during development - kept in the record, not silently
corrected). {opt rate0()} is still accepted for backward compatibility but not used - the starting
value is always computed from the data. {bf:A real, disclosed scope limit}: this refinement is not
performed for co-evolution fits ({opt behavior()}) - matching real RSiena's own actual default
behavior, not an oversight: RSiena's own conditional-estimation default requires exactly ONE
dependent variable, and a co-evolution model has two (network and behavior), so real RSiena itself
falls back to the SAME closed-form starting-value convention {cmd:nwsaom}'s own co-evolution rates
already use.

{pstd}
{opt waves(namelist)} chains three or more waves into ONE pooled fit: the eval-parameter vector
theta is POOLED/shared across every inter-wave period (RSiena's own multi-period Method-of-Moments
convention, verified directly against a real RSiena fit), while the rate parameter is estimated
SEPARATELY per period and reported as e(rates)/e(rate_tratios) (1 x (nwaves-1) matrices, one column
per period) rather than the scalar e(rate)/e(rate_tratio) the two-wave {opt wave1()}/{opt wave2()}
path reports.

{title:Postestimation}

{pstd}
{cmd:estat gof} reports RSiena's own goodness-of-fit methodology
({cmd:sienaGOF()}/{cmd:plot.sienaGOF()}, Lospinoso & Snijders 2019) - a fundamentally different,
more rigorous construction than a simple descriptive comparison: for each requested auxiliary
statistic (out-degree distribution, in-degree distribution, geodesic-distance distribution - the
same trio RSiena itself uses by default), {opt nsim()} fresh post-fit replicates are simulated at
the fitted coefficients (a genuine, disclosed architectural difference from real RSiena, which
reuses networks already stored during the fit itself - statistically equivalent, since the
Mahalanobis test is agnostic to how its reference draws were generated, only that they are genuine
independent draws at the fitted parameters), and a Mahalanobis-distance hypothesis test (a direct,
verified port of RSiena's own {cmd:applyTest()} construction, including its own Moore-Penrose
pseudoinverse handling of the collinear covariance matrix every distribution-category vector
produces) compares the observed wave's own auxiliary-statistic vector against that simulated
reference distribution. A small p-value (below 0.05, RSiena's own convention) is evidence AGAINST
the fitted model on that statistic. With three or more waves, the auxiliary-statistic vector is
POOLED (summed) across every period before the single test is run - RSiena's own {cmd:join=TRUE}
default, matching this package's own established summation-pooling convention for theta/the
Jacobian. Each statistic's own result is additionally rendered as a violin plot (kernel-density
shape per category, a thin embedded interquartile box, dashed 95% envelope lines, and the observed
value as a red overlay - Stata's standard DIY {cmd:kdensity}+{cmd:twoway rarea, horizontal}
technique, reproducing RSiena's own {cmd:plot.sienaGOF()} panel layout as closely as Stata's
graphics primitives allow) with the test's own p-value as the plot's x-axis title, matching
RSiena's own convention exactly.

{title:Stored results}

{pstd}
{cmd:nwsaom} stores the following in {cmd:e()}:

		Scalars
		  {bf:e(N)}			number of actors (= e(nodes))
		  {bf:e(nodes)}			number of actors
		  {bf:e(nwaves)}		number of waves supplied
		  {bf:e(rate)}			estimated network rate parameter (wave1()/wave2() path only) - REFINED (harmonisation unit 27) for a plain network-only fit; the closed-form STARTING value only for a co-evolution fit (real RSiena's own default behavior for 2+ dependent variables - see {bf:Estimation} above)
		  {bf:e(rate_tratio)}		network rate parameter's own phase-3 convergence t-ratio (wave1()/wave2() path only - see {bf:Estimation} above)
		  {bf:e(rate_se)}		standard error of the REFINED e(rate) (harmonisation unit 27; plain network-only fits only - not set for a co-evolution fit, whose e(rate) is not refined)
		  {bf:e(has_behavior)}		1 if this is a co-evolution fit ({opt behavior()} specified), 0 otherwise
		  {bf:e(p_net)}			number of network-side eval-parameter coefficients (co-evolution fits only; the first e(p_net) columns of e(b)/e(V)/e(tratio) are the network's own, the remainder the behavior's own, prefixed {cmd:beh_})
		  {bf:e(rate_beh)}		estimated behavior rate parameter (co-evolution, wave1()/wave2() path only) - closed-form starting value, not refined (see {bf:Estimation} above)
		  {bf:e(rate_beh_tratio)}	behavior rate parameter's own phase-3 convergence t-ratio (co-evolution, wave1()/wave2() path only)

		Macros
		  {bf:e(cmd)}			{bf:nwsaom}
		  {bf:e(title)}			title of estimation
		  {bf:e(waves)}			list of wave network names, in temporal order
		  {bf:e(wave1)}			first wave name (wave1()/wave2() path only)
		  {bf:e(wave2)}			second wave name (wave1()/wave2() path only)
		  {bf:e(behavior)}		list of behavior variable names, one per wave, in temporal order (co-evolution fits only)
		  {bf:e(estat_cmd)}		{bf:nwsaom_estat} (postestimation dispatch)

		Matrices
		  {bf:e(b)}			coefficient vector (eval parameters only - excludes rate; network then behavior for a co-evolution fit, see e(p_net) above)
		  {bf:e(V)}			variance-covariance matrix (eval parameters only)
		  {bf:e(tratio)}		1 x nparam phase-3 convergence t-ratios, one per eval-parameter coefficient
		  {bf:e(rates)}			1 x (nwaves-1) per-period estimated network rate parameters (waves() path only) - REFINED (harmonisation unit 27) for a plain network-only fit; closed-form STARTING values only for a co-evolution fit
		  {bf:e(rate_tratios)}		1 x (nwaves-1) per-period network rate convergence t-ratios (waves() path only)
		  {bf:e(rates_se)}		1 x (nwaves-1) per-period standard errors of the REFINED e(rates) (harmonisation unit 27; plain network-only fits only)
		  {bf:e(rates_beh)}		1 x (nwaves-1) per-period estimated behavior rate parameters (co-evolution, waves() path only)
		  {bf:e(rate_beh_tratios)}	1 x (nwaves-1) per-period behavior rate convergence t-ratios (co-evolution, waves() path only)

{pstd}
{cmd:estat gof} stores the following in {cmd:r()}, one pair per requested statistic (default
{bf:outdegree}/{bf:indegree}/{bf:geodesic}):

		Scalars
		  {bf:r(p_{it:stat})}		empirical Mahalanobis-distance test p-value for that statistic
		  {bf:r(mhd_{it:stat})}		observed vector's own Mahalanobis distance from the simulated mean

{title:Examples}

		{cmd:. nwset, mat((0,1,1,0,1,0\0,0,1,0,0,1\1,0,0,1,0,0\0,0,0,0,1,1\1,0,0,0,0,1\0,1,0,0,0,0)) directed name(wave1)}
		{cmd:. nwset, mat((0,1,1,1,1,0\1,0,1,0,0,1\1,1,0,1,0,0\0,0,1,0,1,1\1,0,1,0,0,1\0,1,0,1,0,0)) directed name(wave2)}
		{cmd:. nwsaom, wave1(wave1) wave2(wave2) outdegree reciprocity transtrip}
		{cmd:. estat gof}

		{cmd:. nwsaom, waves(wave1 wave2 wave3) outdegree transties balance}

		{cmd:. nwsaom, wave1(wave1) wave2(wave2) outdegree reciprocity behavior(b1 b2) linear avalt}
		{cmd:. estat gof}

		{cmd:. nwsaom, waves(wave1 wave2 wave3) outdegree behavior(b1 b2 b3) linear avalt}

		{cmd:. nwsaom, waves(wave1 wave2 wave3) outdegree behavior(b1 b2 b3) linear avsim}

		{cmd:. nwsaom, wave1(wave1) wave2(wave2) outdegree reciprocity behavior(b1 b2) linearendow linearcreation}

{title:References}

{pstd}
Snijders, T.A.B. (2001). The statistical evaluation of social network dynamics. {it:Sociological
Methodology}, 31(1), 361-395. (SAOM/Method of Moments)

{pstd}
Snijders, T.A.B., van de Bunt, G.G., Steglich, C.E.G. (2010). Introduction to stochastic
actor-based models for network dynamics. {it:Social Networks}, 32(1), 44-60.

{pstd}
Ripley, R.M., Snijders, T.A.B., Boda, Z., Voros, A., Preciado, P. (2024). Manual for RSiena.
University of Oxford. {browse "https://www.stats.ox.ac.uk/~snijders/siena/":stats.ox.ac.uk/~snijders/siena/}

{pstd}
Lospinoso, J., Snijders, T.A.B. (2019). Goodness of fit for stochastic actor-oriented models.
{it:Methodological Innovations}, 12(3).

{pstd}
{cmd:nwsaom} is an independent, native reimplementation and is not affiliated with or endorsed by
the RSiena project. See {browse "docs/SAOM_ROADMAP.md"} for the full scope/status account and
{browse "docs/SAOM_ARCHITECTURE.md"} for the design and per-effect derivation/certification
account, including every case where an initial assumption was caught and corrected during
development.

{title:See also}

	{help nwergm}, {help nwset}, {help nwrandom}
