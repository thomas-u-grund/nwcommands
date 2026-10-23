{smcl}
{* *! version 1.0.0  28aug2026 author: Thomas Grund}{...}

{title:Title}

{p2colset 9 25 26 2}{...}
{p2col :nwsaom postestimation {hline 2}}Postestimation tools for {cmd:nwsaom}{p_end}
{p2colreset}{...}

{title:Description}

{pstd}
The following postestimation command is available after {helpb nwsaom}:

{p2colset 9 29 30 2}{...}
{p2col: {cmd:estat gof}}RSiena-style goodness-of-fit test and violin plot{p_end}
{p2col: {cmd:estat mems}}Micro Effects on Macro Structure (Duxbury) mediation-style sensitivity analysis{p_end}
{p2col: {cmd:estat simulate}}Simulate the fitted model (or the model at chosen coefficients) forward from the observed waves{p_end}
{p2col: {cmd:estat score}}Generalised score-type test of the effects held fixed with {opt fix()}{p_end}
{p2col: {cmd:estat timetest}}Test of time heterogeneity of the effects (RSiena's {cmd:sienaTimeTest}){p_end}
{p2col: {cmd:estat importance}}Relative importance of the effects (RSiena's {cmd:sienaRI}){p_end}
{p2colreset}{...}

{title:Supported network types}

{pstd}
Not applicable - {cmd:estat gof} operates on the fitted model and the wave data left behind by
{help nwsaom}, not on a network directly; see that command's own classification.

{title:estat gof}

{p 8 17 2}
{cmd:estat gof} [{cmd:,} {opt nsim(int)} {opt seed(int)} {opt stats(namelist)} {opt maxdeg(int)} {opt maxdist(int)} {opt twotailed} {opt name(string)} {opt join(off)}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt nsim(int)}}Number of fresh post-fit simulated replicates forming the reference distribution; default 50, minimum 5{p_end}
{synopt:{opt seed(int)}}Set the random-number seed before simulating{p_end}
{synopt:{opt stats(namelist)}}Auxiliary statistics to test, any of {bf:outdegree}, {bf:indegree}, {bf:geodesic}, {bf:triad}, {bf:behavior}; default
the three network distribution statistics, plus {bf:behavior} automatically whenever the fit in memory used {opt behavior()} ({bf:behavior} itself
requires a co-evolution fit; {bf:triad} is never added by default, request it explicitly){p_end}
{synopt:{opt maxdeg(int)}}Highest EXACT out-/in-degree category before the ("maxdeg+") overflow bin; default 15{p_end}
{synopt:{opt maxdist(int)}}Highest EXACT geodesic-distance category before the ("NR", not reached) overflow bin; default 6{p_end}
{synopt:{opt twotailed}}Report a two-tailed p-value instead of the one-tailed default (RSiena's own {cmd:twoTailed=FALSE} default: reject for a SMALL p only, i.e. the observed network is an outlier relative to what the fitted model simulates){p_end}
{synopt:{opt name(string)}}Stub for the violin-plot graph names; default {cmd:gof} (graphs are named {it:name}{cmd:_outdegree},
{it:name}{cmd:_indegree}, {it:name}{cmd:_geodesic}, {it:name}{cmd:_triad}, and {it:name}{cmd:_behavior} for a co-evolution fit's fourth statistic;
with {opt join(off)} each period gets its own graph instead, e.g. {it:name}{cmd:_outdegree_p1}/{it:name}{cmd:_outdegree_p2}){p_end}
{synopt:{opt join(off)}}Run a SEPARATE Mahalanobis test (and violin) per wave-period instead of the default pooled/summed one - real RSiena's own {cmd:join=FALSE} (non-default); omit for the default pooled behavior ({cmd:join=TRUE}){p_end}
{synoptline}

{pstd}
{cmd:estat gof} reports real RSiena's own goodness-of-fit methodology ({cmd:sienaGOF()}/
{cmd:plot.sienaGOF()}, Lospinoso & Snijders 2019) - a fundamentally different, more rigorous
construction than a simple descriptive comparison. For each requested auxiliary statistic (a
user-chosen SUMMARY of the network, not a raw model term - the out-degree distribution, in-degree
distribution, and geodesic-distance distribution, the same trio real RSiena itself uses by
default), {opt nsim()} fresh post-fit replicates are simulated at the fitted coefficients, and a
Mahalanobis-distance hypothesis test compares the observed wave's own auxiliary-statistic vector
against that simulated reference distribution. A small p-value (below 0.05, RSiena's own
convention) is evidence AGAINST the fitted model on that statistic; rough agreement is evidence
for it, not proof.

{pstd}
{bf:The test itself} is a direct, line-by-line port of real RSiena's own {cmd:applyTest()}
closure inside {cmd:sienaGOF()} (verified against the installed package's own R source, not
re-derived from a description): the simulated replicates' own covariance matrix is inverted via a
Moore-Penrose pseudoinverse ({bf:required}, not merely convenient - a distribution's own category
proportions are collinear by construction, e.g. they sum to 1, so the plain covariance matrix is
rank-deficient), each replicate's own Mahalanobis distance from the simulated mean is computed,
and the reported p-value is the empirical proportion of simulated distances at or beyond the
observed vector's own distance - a permutation-style p-value, not a chi-square/normal-theory one.

{pstd}
{bf:Simulation source differs from real RSiena, disclosed.} Real RSiena's own {cmd:iterations}
reuses networks already simulated and stored during the fit itself. {cmd:nwsaom} has no such
storage today, so {cmd:estat gof} runs {opt nsim()} FRESH simulations instead, restarting from
each period's own observed starting wave exactly as {cmd:nwsaom}'s own estimation does - this does
not change the statistical construction (the Mahalanobis test is agnostic to how its reference
draws were generated, only that they are genuine, independent draws at the fitted parameters).

{pstd}
{bf:Pooling across periods.} With three or more waves, each auxiliary statistic's own vector is by
default POOLED (summed) across every period before a single test is run - real RSiena's own
{cmd:join=TRUE} default, matching {cmd:nwsaom}'s own established summation-pooling convention for
the rate/eval parameters themselves. {opt join(off)} switches to real RSiena's own non-default
{cmd:join=FALSE}: a completely SEPARATE test (and violin) per wave-period, replacing the pooled
report entirely for that call rather than adding to it.

{pstd}
{bf:Triad census.} {opt stats(triad)} adds the full 16-category MAN triad census (real RSiena's
own {cmd:TriadCensus()}), reusing {helpb nwtriads}'s own census machinery on a temporary network
built from each simulated/observed wave. Unlike the three distribution statistics above, the triad
census reports RAW counts, not proportions - verified directly against real RSiena's own R source,
matching it exactly (not merely "similar in spirit"). All 16 categories are always reported. After a non-directed fit ({opt symmetric} or undirected
waves) every dyad is mutual or null, so only the categories without asymmetric dyads can be non-zero.

{pstd}
{bf:Limits.} {cmd:estat gof} is not yet available after a two-mode (bipartite) fit (it stops with an error), and not after {cmd:nwsaom multinet} (only {cmd:estat score} and {cmd:estat timetest} are). It works after directed and non-directed one-mode fits with the native-only effects.

{pstd}
{bf:Co-evolution fits} (a {opt behavior()} model) add a fourth default auxiliary statistic,
{bf:behavior} (real RSiena's own {cmd:BehaviorDistribution()}), and simulate network and behavior
JOINTLY for every replicate regardless of which {opt stats()} were actually requested - the fitted
coefficients were estimated jointly, so a network-only simulation would not be faithful to the
fitted model even when only network statistics are being checked. GOF simulates the fitted model -
endowment/creation, {opt structural()}, {opt ratecov()}, {opt present()} and non-directed model
types included - in the native plugin when it covers the model (co-evolution too since 2026-10-01;
before, co-evolution GOF ran in Mata, and network GOF ignored endowment/creation, {opt structural()},
{opt ratecov()} and {opt present()}).

{pstd}
{bf:The plot.} Each statistic's own result is additionally rendered as a violin plot: a
kernel-density shape per category (Stata has no native violin geom - this is the standard
{cmd:kdensity}+{cmd:twoway rarea, horizontal} technique), a thin embedded box (interquartile
range), dashed 2.5th/97.5th-percentile envelope lines, and the observed value overlaid as a
red connected line - reproducing real RSiena's own {cmd:plot.sienaGOF()} panel layout (violin +
{cmd:panel.bwplot(box.ratio=0.1)} + dashed percentile lines + red observed overlay) as closely as
Stata's own graphics primitives allow, with the test's own p-value shown as the plot's x-axis
title, matching RSiena's own {cmd:xlabel = paste("p:", round(x$p,3))} convention exactly.

{title:estat mems}

{p 8 17 2}
{cmd:estat mems, } {opt effect(string)} {opt macro(string)} [{opt nsim(int)} {opt seed(int)} {opt interval(numlist)} {opt nodots}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt effect(string)}}Which fitted coefficient is the "micro process" under test - must be one of this fit's own {help nwsaom##estimation:e(b)} column names{p_end}
{synopt:{opt macro(string)}}Name of a Stata program computing ONE macro-level network summary - takes a single argument (a network name) and must
{cmd:return scalar stat} - your own choice of statistic (density, centralization, segregation, ...), matching real {cmd:netmediate}'s own
user-supplied {cmd:macro_function}{p_end}
{synopt:{opt nsim(int)}}Number of Monte Carlo theta draws; default 500 (matching real {cmd:netmediate}'s own default), minimum 20{p_end}
{synopt:{opt seed(int)}}Set the random-number seed before simulating{p_end}
{synopt:{opt interval(numlist)}}Multipliers applied to {opt effect()}'s own coefficient, in order; default {bf:0 1} (real {cmd:netmediate}'s own default: "as if the effect did not operate at all" vs "at its actual fitted strength"){p_end}
{synopt:{opt nodots}}Suppress the per-interval progress dots{p_end}
{synoptline}

{pstd}
{cmd:estat mems} is a direct port of Scott Duxbury's real {cmd:netmediate} R package
({cmd:MEMS()}/{cmd:netmediate:::MEMS_saom()}, fetched and read directly from the installed
package's own source, not guessed) - "Micro Effects on Macro Structure", a mediation-style
sensitivity analysis asking how much a chosen MICRO-level effect (one of this model's own
coefficients) changes a MACRO-level network summary the user supplies. {cmd:MEMS()} is real
{cmd:netmediate}'s own SAOM-specific function - the package's separate {cmd:AMME()} function
targets cross-sectional (ERGM-style) models instead and is NOT what this command implements.

{pstd}
The real algorithm: draw {opt nsim()} coefficient vectors from an "empirical" multivariate normal
with mean {cmd:e(b)} and covariance {cmd:e(V)} - confirmed from {cmd:MASS::mvrnorm}'s own real
source that {cmd:empirical=TRUE} is an EXACT sample-moment-matching construction (the drawn
sample's OWN mean/covariance equal {cmd:e(b)}/{cmd:e(V)} exactly, not merely asymptotically);
{cmd:estat mems} achieves the identical statistical guarantee via a Cholesky-based whitening
transform rather than {cmd:MASS}'s own SVD-based one - a different but equally valid route to the
same property, not a bit-for-bit RNG-path replication (impossible regardless, since Mata's own RNG
stream is unrelated to R's). For each value in {opt interval()} (default {bf:0 1}), every draw's
own {opt effect()} coefficient is scaled by that value and a fresh network is simulated forward
from the fitted model's OBSERVED starting wave; {opt macro()} is applied to each simulated network.
The paired difference (macro at the last interval value minus macro at the first, pooled across
every draw and consecutive interval pair when {opt interval()} has more than two values, matching
real {cmd:netmediate}'s own whole-matrix pooling) gives the "MEMS" estimate, its Monte Carlo SD, a
95% percentile interval (R's own default {cmd:quantile()} algorithm), and a Monte Carlo p-value
(the real, specific convention: the proportion of draws whose sign is OPPOSITE the overall mean
effect - not doubled). "Prop. Change in M" reports that same difference as a proportion of the
macro value at the LAST interval - real {cmd:netmediate}'s own summary table reports only a point
estimate for this row, no SE/CI/p-value, and this command matches that exactly.

{pstd}
{bf:v1 scope, disclosed}: exactly-two-wave ({opt wave1()}/{opt wave2()}), network-only fits -
co-evolution ({opt behavior()}), multi-wave ({opt waves()}), {opt symmetric}, and multiplex fits
are all rejected with a clear message (each adds real complexity in real {cmd:netmediate}'s own
construction too, e.g. a genuine multi-period forward simulation chained through each period's own
SIMULATED, not observed, end state - not chased here). The VanderWeele E-value sensitivity bound
({cmd:netmediate}'s own {cmd:sensitivity_ev} argument) is not implemented - real
{cmd:netmediate}'s own bootstrap implementation of it has what looks like a genuine copy-paste bug
(reusing its own lower confidence bound for the upper one too), not something worth faithfully
reproducing, and a corrected reimplementation was not this pass's own priority. No
common-random-numbers pairing between a draw's own interval simulations either - only the THETA
draw itself is shared across a row's own interval values, each simulation call draws its own fresh
randomness.

{marker estat_simulate}{...}
{title:estat simulate}

{p 8 17 2}
{cmd:estat simulate} [{cmd:,} {opt nsim(int)} {opt seed(int)} {opt theta(matname)} {opt rates(numlist)} {opt ratesbeh(numlist)} {opt gen:erate(stub)}]

{pstd}
Simulates the fitted model {opt nsim()} times (default 100). Every inter-wave period starts at the observed
start wave of the period and runs for the period's length at the fitted coefficients and rates, the same
simulation that {cmd:estat gof} uses. With {opt theta()} (a row vector in the order of {cmd:e(b)}) and
{opt rates()} (one rate per period; {opt ratesbeh()} for the behavior) the model is simulated at coefficients
of your choice, which is the simulation-only mode (RSiena's {cmd:siena07} with {cmd:simOnly}). {opt generate(stub)}
saves the simulated networks as {cmd:nwcommands} networks named {it:stub}{cmd:_}{it:s}{cmd:_p}{it:period}; after a
co-evolution fit the simulated behavior is saved as variables of the same names.

{pstd}
Returns {cmd:r(sim)} (one row per simulation and period: simulation, period, number of ties, mutual dyads,
transitive triples, mean behavior), {cmd:r(obs)} (the same for the observed end waves) and {cmd:r(nsim)}.
To simulate without a prior fit, give the model options of {cmd:nwsaom} and the coefficients to
{cmd:nwsaom simulate} ({help nwsaom##simulate:see the nwsaom help}).

{marker estat_score}{...}
{title:estat score}

{p 8 17 2}
{cmd:estat score} [{cmd:,} {opt tested(namelist)}]

{pstd}
The generalised score-type test of Schweinberger (2012), RSiena's {cmd:test = TRUE} effects and
{cmd:score.Test()}. Fit the restricted model first, with the effects to be tested held fixed at the restricted
values: {cmd:nwsaom ..., theta0(}{it:values}{cmd:) fix(}{it:effects}{cmd:)}. {cmd:estat score} then asks, from
the phase-3 simulations of the restricted model alone, whether freeing the fixed effects would improve the fit.
It reports the joint chi-squared test (degrees of freedom = number of tested effects), each tested effect
separately (two-sided chi-squared and the one-sided normal variate, signed so that it is positive when the
effect is expected to be positive) and the one-step estimates of all parameters. {opt tested()} restricts the
test to some of the fixed effects. Returns {cmd:r(chi2)}, {cmd:r(df)}, {cmd:r(p)}, {cmd:r(separate)} and
{cmd:r(onestep)}.

{pstd}
After {cmd:nwsaom multinet} the restricted model is fitted with {cmd:theta0()} and {cmd:fix()} of that command (coefficient names such as {cmd:net1_x_crprod}); the rates of all networks and of the behavior are estimated along.

{marker estat_timetest}{...}
{title:estat timetest}

{p 8 17 2}
{cmd:estat timetest} [{cmd:,} {opt eff:ects(namelist)}]

{pstd}
Tests whether the effects of a fit with at least three waves have the same parameter in every period
(RSiena's {cmd:sienaTimeTest}). For every effect the model is extended by period-specific deviations (periods 2
to P), and a score-type test of "no deviation" is computed from the phase-3 simulations of the fit in memory; no
second fit is needed. Reported: a joint test of all deviations, a test per effect (degrees of freedom P - 1), and
per effect and period the one-step estimate of the deviation with its separate test. Returns {cmd:r(chi2)},
{cmd:r(df)}, {cmd:r(p)}, {cmd:r(effect)} and {cmd:r(individual)}.

{pstd}
Also available after {cmd:nwsaom multinet}, for the effects of all networks and of the behavior.

{marker estat_importance}{...}
{title:estat importance}

{p 8 17 2}
{cmd:estat importance}

{pstd}
The relative importance of the effects (RSiena's {cmd:sienaRI}). At the start network of every period the change
contribution of each actor's every possible tie change is computed; the importance of an effect for an actor is the
L1 distance between the actor's choice probabilities with and without the effect, its relative importance the share
among all effects, averaged over the actors. Also reported: sigma (the within-actor standard deviation of the
contributions), the semi-standardised estimate (estimate times sigma) and the certainty R_H of the choices.
Available after fits of a one-mode (directed or non-directed) or two-mode network, with or without one co-evolving behavior, without endowment/creation effects,
{opt present()} or missing-data options (as in RSiena). After a co-evolution fit a second table gives the behavior effects (the options of an actor are changing by -1, 0 or +1) and the results {cmd:r(ri_beh)}, {cmd:r(importance_beh)}, {cmd:r(sigma_beh)}, {cmd:r(sigma_period_beh)} and {cmd:r(certainty_beh)}. For a non-directed network the sizes are those of the forcing model, as in RSiena. Returns {cmd:r(ri)}, {cmd:r(importance)}, {cmd:r(sigma)},
{cmd:r(sigma_period)} and {cmd:r(certainty)}. Needs the native plugin.

{title:Stored results}

{pstd}
{cmd:estat gof} stores the following in {cmd:r()}, one pair per requested statistic (default
{bf:outdegree}/{bf:indegree}/{bf:geodesic}, plus {bf:behavior} for a co-evolution fit; {bf:triad}
only if requested via {opt stats()}). With {opt join(off)}, each period gets its own pair instead,
suffixed {cmd:_p{it:#}} (e.g. {cmd:r(p_outdegree_p1)}, {cmd:r(p_outdegree_p2)}):

		Scalars
		  {bf:r(p_{it:stat})}		empirical Mahalanobis-distance test p-value for that statistic
		  {bf:r(mhd_{it:stat})}		observed vector's own Mahalanobis distance from the simulated mean

{pstd}
{cmd:estat mems} stores the following in {cmd:r()}:

		Scalars
		  {bf:r(mems)}			MEMS point estimate (mean paired difference in the macro statistic)
		  {bf:r(mems_sd)}		Monte Carlo standard deviation of the paired difference
		  {bf:r(mems_lb)}/{bf:r(mems_ub)}	95% percentile interval
		  {bf:r(mems_p)}		Monte Carlo p-value
		  {bf:r(propchange)}		"Prop. Change in M" point estimate

		Macros
		  {bf:r(effect)}		the {opt effect()} requested
		  {bf:r(macro)}			the {opt macro()} program name requested

{title:Examples}

		{cmd:. nwset, mat((0,1,1,0,1,0\0,0,1,0,0,1\1,0,0,1,0,0\0,0,0,0,1,1\1,0,0,0,0,1\0,1,0,0,0,0)) directed name(wave1)}
		{cmd:. nwset, mat((0,1,1,1,1,0\1,0,1,0,0,1\1,1,0,1,0,0\0,0,1,0,1,1\1,0,1,0,0,1\0,1,0,1,0,0)) directed name(wave2)}
		{cmd:. nwsaom, wave1(wave1) wave2(wave2) outdegree reciprocity transtrip}
		{cmd:. estat gof}

		{cmd:. estat gof, nsim(200) stats(outdegree geodesic) maxdeg(10)}

		{cmd:. estat gof, twotailed name(mygof)}

		{cmd:. estat gof, stats(outdegree triad) nsim(200)}

		{cmd:. estat gof, join(off)}

		{cmd:. program myDensity, rclass}
		{cmd:.     args netname}
		{cmd:.     nwsummarize `netname', matonly}
		{cmd:.     return scalar stat = r(density)}
		{cmd:. end}
		{cmd:. estat mems, effect(reciprocity) macro(myDensity) nsim(500) seed(42)}

{title:References}

{pstd}
Lospinoso, J., Snijders, T.A.B. (2019). Goodness of fit for stochastic actor-oriented models.
{it:Methodological Innovations}, 12(3).

{pstd}
Ripley, R.M., Snijders, T.A.B., Boda, Z., Voros, A., Preciado, P. (2024). Manual for RSiena.

{pstd}
Duxbury, S.W. (2023). Micro Effects on Macro Structure. {it:Sociological Methodology}. DOI:
10.1177/00811750231209040.

{pstd}
Duxbury, S.W., Zhao, X. {cmd:netmediate}: Micro-Macro Analysis for Social Networks (R package).

{title:See also}

	{help nwsaom}
