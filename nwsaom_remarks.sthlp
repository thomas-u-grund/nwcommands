{smcl}
{* *! version 1.0.0  05sep2026 author: Thomas Grund}{...}

{title:Title}

{p2colset 9 25 26 2}{...}
{p2col :nwsaom remarks {hline 2}}Remarks, effect library, and estimation details for {cmd:nwsaom}{p_end}
{p2colreset}{...}

{title:Description}

{pstd}
This file describes the effects of {helpb nwsaom}, interactions, multiplex and co-evolution
models, composition change, missing data, structural zeros, undirected relations, and the
estimation algorithm. See {helpb nwsaom} for the syntax, options, and examples.

{marker effects}{...}
{title:Effect library}

{pstd}
{bf:outdegree} and {bf:reciprocity} are the base structural effects (RSiena's density and recip),
the analogues of {help nwergm}'s {opt edges}/{opt mutual}.

{pstd}
{bf:nodematch()}/{bf:nodecov()}/{bf:nodeicov()}/{bf:nodeocov()} use the same covariate statistics
as {help nwergm}. Each depends only on the covariate values of ego and the alter. RSiena names:
{opt nodeocov()} = egoX (the sender's value), {opt nodeicov()} = altX (the receiver's value),
{opt nodematch()} = sameX, {opt nodecov()} = the sum of the two. Each takes a varlist; see
{help nwsaom_remarks##covariates:Covariate effects for several variables} for naming and centring.

{pstd}
{bf:indegpopularity}/{bf:outpopularity}/{bf:outactivity}/{bf:inactivity} are RSiena's inPopSqrt,
outPopSqrt, outAct, and inActSqrt: square-root indegree popularity, square-root outdegree
popularity, squared outdegree activity, and square-root indegree activity. A tie change also
changes other actors' popularity/activity statistics, so the ministep contribution is not the
change in the global statistic.

{pstd}
{bf:transtrip} (transitive triplets) and {bf:cycle3} (directed 3-cycles) are computed from two-path,
out-star, and in-star counts. The ministep contribution of {opt transtrip} is OTP(i,j)+OSP(i,j);
that of {opt cycle3} is OTP(j,i) (note the reversed argument order).

{pstd}
{bf:transties} (RSiena's transTies, {cmd:TransitiveTiesEffect}) is an existence-indicator
alternative to {opt transtrip}: a tie i->j counts if and only if at least one two-path i->k->j
exists, instead of counting every such two-path.

{pstd}
{bf:balance} (RSiena's balance, {cmd:BalanceEffect}) has no user-supplied parameter. RSiena's
"balanceMean" constant (the SIENA manual's {it:b0}) is derived from the data: the mean of
|x_ih - x_jh| over every distinct valid actor triple in the observed waves. It is computed from the
waves in {opt wave1()}/{opt wave2()} or {opt waves()}, pooled across the starting wave of every
period by summing numerators and denominators separately and dividing once (RSiena's
{cmd:calcBalmean()}), not by averaging per-period ratios.

{pstd}
{bf:isolatenet} (RSiena's network-isolate) and {bf:outiso} (RSiena's out-isolate) have no
user-supplied parameter. {opt isolatenet} counts true isolates, actors with indegree and outdegree
both 0 ({cmd:IsolateNetEffect}). Creating a tie also raises the alter's indegree, which can change
the alter's isolate status, so the change also affects other actors' statistics. {opt outiso}
counts actors with outdegree 0 regardless of indegree; RSiena implements outIso through
{cmd:TruncatedOutdegreeEffect} with a specific parameter. {opt outiso} has no spillover: a tie
change never alters another actor's outdegree.

{pstd}
{bf:antiiso}/{bf:antiiniso}/{bf:antiiniso2}/{bf:inplus3}/{bf:isolatepop} are RSiena's
alter-indexed isolate effects ({cmd:AntiIsolateEffect}/{cmd:IsolatePopEffect}): the ministep
contribution depends on the alter's degree, not ego's. {opt inplus3} is RSiena's in3Plus, the same
{cmd:AntiIsolateEffect} as {opt antiiniso}/{opt antiiniso2} with threshold 3 instead of 1 or 2
(Stata option names cannot have a digit followed by letters; the coefficient is labelled
{cmd:in3plus}). {opt antiiniso}/{opt antiiniso2}/{opt inplus3} have no spillover: the ministep
contribution equals the change in the global statistic. {opt antiiso}/{opt isolatepop} also
depend on ego's outdegree, so a tie change can also change ego's membership in the global count.

{pstd}
On small or sparse networks, {opt isolatenet}, {opt outiso}, and the anti-isolate effects can be
weakly identified, and {opt antiiso}/{opt isolatepop} can destabilize the Robbins-Monro estimator.
The Glasgow data have no isolates at any wave, so these effects cannot be estimated there. On toy
networks of up to 10 actors with a few isolate transitions, fits stopped at {bf:thetaBound} or at
the phase-3 covariance check (see {help nwsaom_remarks##endowcreation:Endowment/creation functions}).

{pstd}
{bf:transrectrip}/{bf:outoutass}/{bf:ininass} are RSiena's transRecTrip, outOutAss, and inInAss
({cmd:TransitiveReciprocatedTripletsEffect}, {cmd:OutOutDegreeAssortativityEffect},
{cmd:InInDegreeAssortativityEffect}), in their default parameterization; no square-root variants
are offered. For all three, the change also affects other actors' statistics (for {opt outoutass},
any existing tie into the acting actor uses that actor's outdegree as its alter-degree factor). To
spot-check them, compare each ego's local statistic, not the whole-network statistic before and
after a change.

{pstd}
{bf:outinass}/{bf:inoutass} are RSiena's outInAss and inOutAss
({cmd:OutInDegreeAssortativityEffect}, {cmd:InOutDegreeAssortativityEffect}). {opt outinass} is
not a degree substitution of {opt outoutass}: an out-tie from ego is an in-tie to the alter, so the
alter's indegree changes too, and the creation formula differs. It has the same kind of spillover
as {opt outoutass}/{opt ininass}. {opt inoutass} has no spillover: neither ego's indegree nor the
alter's outdegree changes with the tie.

{pstd}
{bf:gwesp(real)} (geometrically weighted edgewise shared partners, OTP-directed) is RSiena's
gwespFF. Its global statistic equals {help nwergm}'s {opt gwesp()} statistic (RSiena's
{cmd:tieStatistic()}). The ministep contribution, as in RSiena's
{cmd:GenericNetworkEffect::calculateContribution()}, is the decay weight of the dyad's current
shared-partner count; it is not the ERGM change statistic. The argument of {opt gwesp()} is the
decay value itself (the statnet convention, as in {help nwergm}); RSiena's parameter is 100 times
this value, so RSiena's default {cmd:gwespFF(69)} is {opt gwesp(.69)}.

{pstd}
{bf:simcov(varlist)} (RSiena's simX, {cmd:CovariateSimilarityEffect}) has the tie contribution
1 - |x_i - x_j|/range - simMean, where {it:range} is the observed maximum minus minimum of the
covariate and simMean, RSiena's similarityMean, is the mean similarity over all pairs.

{pstd}
All effects run in the native (C) backend.

{marker nwsaom_interaction}{...}
{title:Interaction effects}

{pstd}
{opt interact(effect1#effect2[#effect3])} is RSiena's {cmd:includeInteraction()} (its C++ class
{cmd:NetworkInteractionEffect}). In a ministep, the interaction's contribution for a tie change to
an alter is the product of the components' contributions for creating that tie, negated when the
change withdraws an existing tie. Its statistic is RSiena's
{cmd:NetworkInteractionEffect::egoStatistic()}, summed over actors: when all components but one are
RSiena's C++ ego effects ({opt egox()} and {opt outdegree}), an actor's statistic is the product of
their values and the other component's statistic for that actor (for {opt outiso}: whether the
actor has no out-ties); otherwise it is the sum, over the actor's ties, of the product of the
components' tie statistics ({cmd:tieStatistic()}, e.g. the number of two-paths from ego to alter for
{opt transtrip}, a third of the two-paths from alter to ego for {opt cycle3}). The ministep
contribution and the tie statistic are different functions for effects with spillovers onto other
ties ({opt transties}, the assortativity effects, {opt cycle4}, {opt balance}), as in RSiena.

{pstd}
Every named effect must also be in the model as a main effect (add {opt reciprocity} and
{opt egox(x)} before writing {cmd:interact(egox#reciprocity)}). The combinations allowed are
RSiena's (R/sienaeffects.r). Each effect is an ego, a dyadic or another effect (interactionType in
RSiena's effects table):

{p2colset 9 26 28 2}{...}
{p2col:ego}{opt egox()}, {opt inactivity}, {opt isolatenet}, {opt isolatepop} (and the
anti-isolate effects){p_end}
{p2col:dyadic}{opt outdegree}, {opt reciprocity}, {opt samex()}, {opt altx()}, {opt nodecov()},
{opt simx()}, {opt gwesp()}, {opt outpopularity}, {opt inoutass}{p_end}
{p2col:other}{opt transtrip}, {opt transmedtrip}, {opt transrectrip}, {opt cycle3}, {opt cycle4},
{opt transties}, {opt balance}, {opt indegpopularity}, {opt outactivity}, {opt outiso},
{opt outoutass}, {opt outinass}, {opt ininass}{p_end}
{p2colreset}{...}

{pstd}
A two-way interaction needs at least one ego effect or two dyadic effects ("invalid network
interaction specification: must be at least one ego or both dyadic effects"); a three-way
interaction needs at least two ego effects or only ego and dyadic effects ("invalid network 3-way
interaction specification: must be at least two ego effects or all ego or dyadic effects"). So
{cmd:interact(transtrip#reciprocity)} is refused, {cmd:interact(egox#transtrip)} and
{cmd:interact(egox#inactivity#transtrip)} are allowed. RSiena accepts some interactions its C++
code then cannot compute; {cmd:nwsaom} refuses them: {opt outiso} and {opt isolatenet} have no tie
statistic and work only when every other component is {opt egox()} or {opt outdegree} (RSiena:
"tieStatistic not implemented"), and the anti-isolate effects ({opt antiiso}, {opt antiiniso},
{opt antiiniso2}, {opt inplus3}) are refused altogether (RSiena stops with that error, or with
{opt egox()} gives their whole statistic to the first actor). Checked against RSiena 1.6.6 on 581
combinations of these effects (all pairs and 146 triples): the same decision and message, and, for
the 119 that RSiena computes, the same statistic.

{pstd}
Validated against RSiena (glasgow waves 1-2, conditional, 5 seeds; coefficient differences in
RSiena standard errors): sameX x recip, egoX x recip and sameX x recip x egoX within 0.05;
outIso x egoX, inPopSqrt x egoX and outAct x egoX within 0.04; inActSqrt x recip,
outPopSqrt x recip and egoX x inActSqrt x transTrip within 0.1. For the last three, RSiena was run
with {cmd:setEffect(..., parameter = 1)} for inActSqrt and outPopSqrt.

{pstd}
{it:Note on RSiena's default for inActSqrt and outPopSqrt.} Since RSiena 1.6.1 (unchanged in 1.6.6
on CRAN and 1.6.12 on GitHub), these two effects have the default internal parameter 0, which makes
their statistic use the degrees at the start of the period (outPopSqrt then without the square root),
while their ministep still uses the square root of the current degree. This appears to be a bug and
has been reported as {browse "https://github.com/stocnet/rsiena/issues/151":RSiena issue #151}.
{cmd:nwsaom} deliberately does not copy it: {opt outpopularity} and {opt inactivity} use the square
root of the current degree throughout, the same as RSiena with {cmd:setEffect(..., parameter = 1)}.
To compare with RSiena, set that parameter there.

{pstd}
An interaction can be weakly identified when its two effects are highly correlated in the data
(for example reciprocity and transitivity in friendship networks, where most closed triads are
also reciprocated), even if each main effect is estimated well. The fit then diverges or stops at
the {bf:thetaBound} or phase-3 covariance checks. An interaction of two unrelated effects (e.g.
{cmd:interact(reciprocity#nodecov(x))} for an {it:x} unrelated to network structure) converges
normally.

{marker multiplex}{...}
{title:Multiplex (two networks) - deprecated}

{pstd}
{bf:Deprecated:} {cmd:nwsaom multiplex} still works but prints a note; use {cmd:nwsaom multinet}, which
covers everything described here and much more, and will be the only command for several networks
in a later release.

{pstd}
{cmd:nwsaom multiplex} fits two networks co-evolving over the same two waves, each with its
{opt outdegree}/{opt reciprocity} effects and its opportunity rate, estimated jointly in one
Method-of-Moments fit. It is a separate subcommand:

{p 8 8 2}
{cmd:nwsaom multiplex ,}
{cmd:netawave1(}{it:netname}{cmd:)} {cmd:netawave2(}{it:netname}{cmd:)}
{cmd:netbwave1(}{it:netname}{cmd:)} {cmd:netbwave2(}{it:netname}{cmd:)}
{cmd:[}{opt crprod}{cmd:]} {cmd:[}{opt crprodb}{cmd:]}
{cmd:[}{opt theta01(numlist)}{cmd:]} {cmd:[}{opt theta02(numlist)}{cmd:]}
{cmd:[}{opt k0(#)}{cmd:]} {cmd:[}{opt k3(#)}{cmd:]} {cmd:[}{opt firstg(#)}{cmd:]}
{cmd:[}{opt seed(#)}{cmd:]} {cmd:[}{opt detail}{cmd:]}{p_end}

{pstd}
{opt netawave1()}/{opt netawave2()} name the two waves of the first network, {opt netbwave1()}/
{opt netbwave2()} those of the second (Stata option names cannot have a digit followed by a
letter, hence {cmd:a}/{cmd:b}). Both networks must be directed, not bipartite, and on the same
nodes. {opt theta01()}/{opt theta02()} give comma-separated starting values, one per effect of
each network (one more with {opt crprod}/{opt crprodb}); the default is 0. {opt k0()}/{opt k3()}/
{opt firstg()} work as in {cmd:nwsaom}, and {opt detail} lists the convergence t-ratio of every
parameter.

{pstd}
{opt crprod} adds a cross-network effect to the first network: a tie is more (or less) likely where
the same pair is tied in the second network; its coefficient is {bf:net1_crprod}. {opt crprodb}
adds the mirror effect to the second network ({bf:net2_crprod}); either or both may be given. A
ministep reads the other network's current state, but the statistic of a {opt crprod} effect is
evaluated with the other network at the start of the period (targets and simulated statistics
alike), as RSiena does for effects that link two dependent variables.

{pstd}
Both rates are estimated jointly with the effects (unconditional Method of Moments, RSiena's
default for two dependent variables): each rate's statistic is the number of dyads in which that
network's simulated end state differs from its starting observation, and
{cmd:e(rate1_se)}/{cmd:e(rate2_se)} are their standard errors; {cmd:e(tconv)} holds the convergence
t-ratios (theta1, theta2, rate1, rate2) and {cmd:e(tconv_max)} RSiena's overall maximum convergence
ratio. On a two-network example (friendship: glasgow waves 1-2; a seeded "advice" network generated
from it) with {opt crprod} in both directions, every parameter including both rates agrees with
RSiena 1.6.6 within 0.06 standard errors (mean of five seeds each).

{pstd}
Effects other than {opt outdegree}, {opt reciprocity}, and {opt crprod} are not yet available for
multiplex models. Fits use the native backend in all three phases; the example above takes about
2 seconds.

{marker coev}{...}
{title:Co-evolution (network + behavior)}

{pstd}
{opt behavior(varlist)} adds a second dependent variable, a bounded-integer behavior (e.g. an
ordinal opinion or a count) that changes together with the network between the same waves. It has
its own rate and evaluation function and is estimated jointly with the network side in one
Method-of-Moments fit. This separates selection (network effects that depend on the behavior, such
as {opt behsim}, {opt simcov()}, {opt nodeicov()}, {opt nodeocov()}) from influence (behavior
effects that depend on the network, below) in one model. As in RSiena
({cmd:EpochSimulation.cpp}, {cmd:BehaviorVariable.cpp}), each ministep draws one exponential
waiting time from the total rate summed over both variables, chooses the variable in proportion to
its share of that total, and then chooses an actor within that variable. A behavior ministep has
three alternatives (change by -1, 0, or +1, within the observed range), chosen by the same
multinomial logit as a network ministep.

{pstd}
{bf:linear} (RSiena's linear, {cmd:LinearShapeEffect}) is the behavior analogue of {opt outdegree}
and is required with {opt behavior()}. Ministep contribution: the change (+1 or -1). Statistic: the
sum of the actors' current values.

{pstd}
{bf:quadratic} (RSiena's quad, {cmd:QuadraticShapeEffect}): as in RSiena, the ministep contribution
uses the centred value, {cmd:(2*(value-mean)+diff)*diff}, while the statistic is the sum of the
uncentred values squared.

{pstd}
{bf:avalt} (RSiena's avAlt, {cmd:AverageAlterEffect}) is the standard influence effect: an actor's
behavior is pulled toward the average current value of its network neighbors. Ministep
contribution: {cmd:diff * (average neighbor value - mean)}, 0 for an actor without out-ties.
Statistic: the sum over actors of (value - mean) * (average neighbor value - mean), with mean the
overall behavior mean, as in RSiena. On very small networks (a handful of actors) a model with
{opt avalt} can diverge because there are too few behavior ministeps to identify it; use more
actors or waves.

{pstd}
{bf:avsim} (RSiena's avSim, {cmd:SimilarityEffect} with average, hi, and lo) is an alternative
influence effect: an actor's behavior moves toward a higher average similarity to its neighbors
(sim(a,b) = 1 - |a-b|/range), minus RSiena's similarityMean. This constant is derived from the
observed behavior, like {opt balance}'s balanceMean: it is pooled over every ordered actor pair in
every wave except the last, by summing numerators and denominators. As in RSiena's
{cmd:rangeAndSimilarity()}, it is 0 when the pooled data have zero variance.

{pstd}
{bf:behsim} (RSiena's {cmd:simX} with the co-evolving behavior as its variable, e.g. "drinking
similarity") is the standard selection effect of a co-evolution model, on the network side: the
tie-level contribution of i->j is 1 - |z_i - z_j|/range - simMean, where z are the current
simulated behavior values (they change during a simulated period, unlike a fixed covariate in
{opt simcov()}), range is the observed behavior range and simMean the same similarity mean
{opt avsim} uses. The centring by simMean matches RSiena, so the outdegree coefficient is directly
comparable to RSiena's.

{pstd}
{bf:How co-evolution models are estimated.} With two dependent variables, {cmd:nwsaom} uses
unconditional Method of Moments, as RSiena does: the network rate and the behavior rate of every
period are estimated jointly with all other parameters in phases 1-3. The statistic for a network
rate is the number of dyads in which the simulated end-of-period network differs from the network
at the start of the period; for a behavior rate it is the sum of absolute differences between the
simulated end-of-period behavior and the behavior at the start of the period. Their targets are
the same distances between the observed waves. The rates therefore get standard errors
({cmd:e(rate_se)}/{cmd:e(rate_beh_se)}, or {cmd:e(rates_se)}/{cmd:e(rates_beh_se)} with
{opt waves()}), and the table below the coefficients reports them per period. Statistics that
link the two variables are lagged, as in RSiena: {opt behsim} (network side) is evaluated with the
behavior at the start of the period, {opt avalt}/{opt avsim} (behavior side) with the network at
the start of the period; the ministep contributions always use the current state. {cmd:e(tconv)}
reports RSiena-style convergence t-ratios for every parameter including the rates and
{cmd:e(tconv_max)} RSiena's overall maximum convergence ratio.

{pstd}
{bf:Starting values and a stuck behavior.} As in RSiena, the outdegree effect, the linear shape
effect and the rates start at values computed from the data (RSiena's {cmd:getEffects()}), and
phase 1 ends with RSiena's partial Newton step. On a few random seeds, phase 2 can still overshoot
so far (for example to a large {opt quadratic} effect) that simulated actors hardly change the
behavior any more and the estimates drift without end. {cmd:nwsaom} detects this (in two
consecutive windows of 25 phase-2 steps, the simulated behavior changes by less than three
quarters of the observed amount in every period) and then runs phases 1 and 2 once more with new
simulations; a note says so. On the smoking co-evolution model of the benchmark this happened on 2
of 60 seeds, and every seed then converged.

{pstd}
{bf:Check against RSiena.} RSiena 1.6.6 on its s50 data (friendship {cmd:s501-s503}, drinking
{cmd:s50a}; {cmd:nwwebuse glasgow} holds the same data, nodes in a different order), network:
density, reciprocity, transTrip, simX(drinking); behavior: linear, quad, avAlt. RSiena estimates
(SE) versus {cmd:nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip behsim}
{cmd:behavior(alcohol1 alcohol2 alcohol3) linear quadratic avalt seed(12345)}:

{p2colset 9 36 50 2}{...}
{p2col:{it:effect}}{it:RSiena}{space 8}{it:nwsaom}{p_end}
{p2col:friendship rate p1/p2}6.48/5.17{space 5}6.43/5.12{p_end}
{p2col:outdegree}-2.760 (.145){space 2}-2.752 (.188){p_end}
{p2col:reciprocity}2.354 (.198){space 3}2.364 (.217){p_end}
{p2col:transitive triplets}0.617 (.077){space 3}0.615 (.095){p_end}
{p2col:drinking similarity}1.484 (.626){space 3}1.431 (.842){p_end}
{p2col:drinking rate p1/p2}1.31/1.81{space 5}1.31/1.73{p_end}
{p2col:linear shape}0.392 (.205){space 3}0.386 (.216){p_end}
{p2col:quadratic shape}-0.589 (.311){space 2}-0.567 (.391){p_end}
{p2col:average alter}1.286 (.774){space 3}1.223 (.882){p_end}
{p2colreset}{...}

{marker endowcreation}{...}
{pstd}
{bf:Syntax.} The roles are chosen with two lists, {opt endow(effects)} and {opt creation(effects)}
(RSiena's {cmd:includeEffects(type = "endow")} / {cmd:type = "creation"}); the effects available are
{bf:outdegree}, {bf:reciprocity}, {bf:transties}, {bf:cycle4}, {bf:gwesp}, {bf:balance}, {bf:transtrip}, {bf:cycle3}, {bf:transmedtrip}, {bf:transrectrip} on the network and {bf:linear}, {bf:quadratic},
{bf:avalt}, {bf:avsim} on the behavior. {cmd:endow(transties) creation(transties)} is the same as
the older option pair {cmd:transtiesendow transtiescreation}, which still works; so do
{opt outdegreeendow}/{opt outdegreecreation}, {opt reciprocityendow}/{opt reciprocitycreation} and
{opt linearendow}/{opt linearcreation} (and likewise for the other behavior effects). Splitting an
effect means naming it in both lists and not giving the plain effect; the plain effect and both of
its roles together would be exactly collinear, and a single role on its own is not supported yet.
For {bf:gwesp}, {opt gwesp(#)} supplies the decay parameter and {cmd:endow(gwesp) creation(gwesp)} the roles
({cmd:gwesp(0.69) endow(gwesp) creation(gwesp)}); unlike the effects without a parameter, giving
{opt gwesp(#)} together with both lists is the split, not a plain-plus-split conflict. Checked against
RSiena 1.6.6 on s501-s503 (density, reciprocity, and the split): the targets are identical
(gwesp -67.98 / 80.71, cycle4 -19.75 / 32.5), the gwesp endowment/creation estimates -0.75/-0.69/-0.73
and 3.18/3.13/3.17 against RSiena's -0.75/-0.82/-0.67 and 3.23/3.17/3.10, and for cycle4 over six seeds
endowment 0.11 against 0.09 and creation 0.64 against 0.66 (standard errors 0.55 and 0.3).

{pstd}
{opt transtrip}, {opt cycle3}, {opt transmedtrip} and {opt transrectrip} split the same way; on s501-s503 the
targets are identical to RSiena's (-74/94, -17.3/31, -74/93, -41/61) and the estimates agree. The split of a
sparse effect such as {opt transrectrip} can need a longer first phase: with the default {opt k0(50)} two of ten
seeds stopped (a divergence error, or a parameter kept at its starting value because its estimated derivative
was not positive), while {opt k0(200)} gave RSiena's values. Since 2026-10-22 a non-positive derivative
estimate first lengthens phase 1 (up to 200 replicates, RSiena's rule in phase1.r) before the parameter is fixed;
about 4% of {opt transrectrip} split fits still stop with a divergence error (RSiena stops at its
{cmd:thetaBound} too, less often); if a split fit stops, try another {opt seed()} or a larger {opt k0()}.

{pstd}
{bf:Endowment/creation functions} ({opt linearendow}/{opt linearcreation}):
RSiena lets an effect enter in three roles: evaluation (the default, direction-blind), creation
(contributes only when the value increases), and endowment (contributes only when it decreases).
Using an effect in all three roles is exactly collinear (RSiena manual: "never in all three...
this leads to collinearity"). {cmd:nwsaom} offers the split for the behavior effects
{opt quadratic}/{opt avalt}/{opt avsim} and for the network effect {opt reciprocity} (below). The
behavior {bf:linear} split ({opt linearendow} with {opt linearcreation}, replacing {opt linear}) is
refused: its two statistics (the sums of the decreases and of the increases) add up exactly to the
behavior rate's distance statistic, so with the behavior rate estimated the model is not identified.
RSiena reports "Covariance matrix not positive definite" and no standard errors for this model on
s50 (alcohol, three waves). Splits are weakly identified in general (RSiena manual: "Separating the
contribution of an effect into two functions requires more of the data... this would lead to large
standard errors"), so a fit with one can stop with an error that {bf:thetaBound} (a coefficient
exceeding 50 in magnitude during estimation, RSiena's safeguard in {cmd:R/phase2.r}) was exceeded,
or that the phase-3 covariance matrix is too close to singular to invert. Either message means the
same: use the plain effect instead, or supply better starting values via {opt behtheta0()}.

{pstd}
The split for {opt quadratic}/{opt avalt}/{opt avsim} is given as
{opt quadraticendow}/{opt quadraticcreation}, {opt avaltendow}/{opt avaltcreation}, and
{opt avsimendow}/{opt avsimcreation}, all effect/type combinations that RSiena's
{cmd:getEffects()} offers. Each effect is split independently, e.g.
{opt linear quadraticendow quadraticcreation} is valid. Splitting more than one effect makes weak
identification more likely; RSiena itself gives unreliable standard errors and a non-positive-definite
covariance matrix when both {opt linear} and {opt quadratic} are split on the same data.

{pstd}
The statistics are RSiena's ({cmd:StatisticCalculator::calculateBehaviorStatistics()}). With c_i
the actor's current value minus the overall mean and d_i = initial - current (0 if missing), the
endowment statistic is the sum, over the actors whose value decreased (d_i > 0), of the effect's
endowment statistic, and the creation statistic is minus the endowment statistic computed with -d:
linear -d_i; quadratic c_i^2 - (c_i + d_i)^2; avAlt (c_i sum_j c_j - (c_i + d_i) sum_j (c_j + d_j))
/outdeg_i over the alters j of i; avSim (sum_j |c_j - c_i| - sum_j |c_j + d_j - c_i - d_i|)/n_i over
the alters with a value, all on the period's starting network. As in RSiena, an effect whose
phase-1 derivative stays non-positive after a longer phase 1 is fixed at its starting value with a
note (RSiena fixes the avSim endowment/creation pair on glasgow; so does {cmd:nwsaom}). Validated
against RSiena on the glasgow alcohol co-evolution (unconditional, 5 seeds): linear, quadratic
endowment/creation and avAlt within 0.03 standard errors; linear, quadratic and avAlt
endowment/creation within 0.02 (weakly identified: standard errors vary by seed in both, and one
of five {cmd:nwsaom} seeds stopped at thetaBound); linear, quadratic and avSim endowment/creation
(fixed by both) within 0.07. RSiena also allows a single role (endowment or creation alone, with
or without the evaluation effect); {cmd:nwsaom} requires the pair, which replaces the evaluation
effect.

{pstd}
This split extends to the NETWORK side too - {opt outdegreeendow}/
{opt outdegreecreation} (replacing plain {opt outdegree}) and {opt reciprocityendow}/
{opt reciprocitycreation} (replacing plain {opt reciprocity}) - confirmed real via RSiena's own
{cmd:getEffects()} output ({cmd:density}/{cmd:recip} both offer {cmd:endow}/{cmd:creation} types).
The statistics are RSiena's: an endowment statistic is minus the sum, over the ties lost between the
waves, of the effect's tie statistic in the starting network (1 for outdegree; the reverse tie for
reciprocity), a creation statistic the sum over the ties gained of the tie statistic in the end
network (on s50 waves 1-2: reciprocity endowment -35, creation 27, as in RSiena).
{opt outdegreeendow}/{opt outdegreecreation} is not identified - lost plus gained ties is exactly
the distance that conditional estimation simulates to and that unconditional estimation uses as the
rate's statistic, and RSiena reports a singular covariance matrix for this model under both
estimators - so {cmd:nwsaom} refuses it; use {opt outdegree} with {opt reciprocityendow}/
{opt reciprocitycreation}. On s50 waves 1-2 that model gives (RSiena, unconditional estimation,
mean of five seeds, in parentheses) outdegree -2.04 (-2.04), reciprocity endowment 0.77 (0.82, SE
0.8), reciprocity creation 3.65 (3.60), rate 4.32 (4.34). These fits run in the native plugin since
2026-10-01 (0.2 s on s50; before, in Mata, about a minute). Works with {opt waves()}, {opt present()} (composition change) and {opt missnet()} (real missing
network data); combined with co-evolution it is rejected outright (error 198) rather than
silently producing a partially-gated fit.

{pstd}
{opt behtheta0()} sets starting values for the behavior effects (as {opt theta0()} does for the
network effects). The starting value of the behavior rate (which is then estimated, see above) is
computed from the observed behavior with RSiena's closed-form formula for the general (non-binary)
case, as for the network rate (see {help nwsaom_remarks##estimation:Estimation}). RSiena uses a
separate logistic formula for a binary behavior; {cmd:nwsaom} uses the general formula.

{pstd}
{opt behavior()} works with {opt wave1()}/{opt wave2()} (two waves) or {opt waves()} (three or
more, chaining {it:nwaves}{cmd:-1} periods as in the network-only case, see
{help nwsaom_remarks##estimation:Estimation}). It needs one behavior variable per wave, in the
same order as the waves. Network and behavior coefficients appear in one table; behavior
coefficients are prefixed {cmd:beh_} (e.g. {cmd:beh_linear}, {cmd:beh_avalt}). The two rates are
reported separately (see {bf:Stored results} in {help nwsaom}). {cmd:estat gof} adds a fourth
default auxiliary statistic, {bf:behavior} (RSiena's {cmd:BehaviorDistribution}: the distribution
of behavior values over the observed range, with no overflow category).

{pstd}
Co-evolution uses the native (C) backend, like the network-only case (see {bf:Performance} in
{help nwsaom}). Every effect, the behavior endowment/creation splits included, has native code. If
a model ever contains a term without native code, the whole fit runs in Mata, and
{cmd:e(engine)} and a note after the output say so.

{pstd}
{bf:Genuinely out of scope for co-evolution v1} (tracked, not silently dropped): cross-behavior effects (one behavior
influencing another) and {opt behsim} on a behavior other than the first. The network-side endowment/creation split ({opt endow()}/{opt creation()})
works together with {opt behavior()} (two or more waves, {opt present()}, {opt missnet()}; native plugin, with a slower
Mata fallback that gives the same estimates): on s501/s502 with the alcohol behavior (reciprocity endowment/creation, linear, quadratic, avAlt)
the estimates agree with RSiena 1.6.6 - density -2.04 against -2.03/-2.05/-2.03, reciprocity endowment
0.79-0.84 against 0.75-0.84, creation 3.60-3.65 against 3.63, behavior linear 0.32, quadratic -0.27,
avAlt 0.96-1.04 against 0.32, -0.27 and 0.90-1.00, rates 4.3 and 1.24.

{pstd}
{bf:Degree effects inpop, outpop, inact, outactsqrt.} The plain (non-square-root) popularity/activity effects of RSiena. Checked against
RSiena 1.6.6 on s50 (3 waves): observed statistics 798, 676, 676, 416.092 identical; inPop 0.180 (0.18), outPop -0.26 (-0.25 to -0.26),
outActSqrt 0.11-0.12 (0.12-0.14); inAct alone -0.044 (-0.044 to -0.051). Unlike {opt outpopularity}/{opt inactivity}, these RSiena effects
have the default internal parameter 1 and are not affected by the RSiena 1.6.1 change documented above (stocnet/rsiena#151).
{opt outpop} and {opt inact} have the same total statistic, so the pair is not identified; RSiena accepts it (with arbitrary estimates), {cmd:nwsaom} refuses it with an error.

{pstd}
{bf:Covariate variants diffx, higher, egosqx, altsqx, samexrecip, simrecipx.} Checked against RSiena 1.6.6 on s50 with alcohol (density,
reciprocity and one effect): observed statistics -10, 122.5, 327.587, 303.187, 52 and 13.655 identical; estimates diffX -0.04 (-0.046),
higher 0.19 (0.18), egoSqX 0.12 (0.115), altSqX 0.023 (0.019), sameXRecip -0.148 (-0.155), simRecipX 0.285 (0.265). With missing values (7 of 50 alcohol values set missing; RSiena's rule: a tie
with a missing value is skipped - egoSqX only the ego's, altSqX only the alter's; higher counts such a tie 0.5) the statistics are identical to
RSiena's too (absDiffX 113, egoXaltX 109.489, diffX -9, higher 122.5, egoSqX 216.676, altSqX 207.257, sameXRecip 42, simRecipX 12.977) and the
estimates agree (dev/saom_rsiena_cov2miss.*).

{pstd}
{bf:Endowment/creation of covariate effects.} {cmd:endow(altx:alc) creation(altx:alc)} (also egox, samex, simx, nodecov): the tie statistic of the
effect over the lost ties in the start network and over the gained ties in the end network, as RSiena's {cmd:type = "endow"/"creation"}. Checked on
s50 with alcohol (density, reciprocity, one split): the eight observed statistics (altX -34.72/19.8, egoX -27.72/28.8, sameX -34/33, simX
-5.978/5.799) are identical to RSiena's and the estimates agree (altX -0.38/0.26 (-0.38/0.26), egoX -2.15/2.16 (-2.15/2.15), sameX 0.11/0.17
(0.09/0.20), simX 0.47/0.68 (0.52/0.63)).

{marker tvcov}{...}
{pstd}
{bf:Time-varying covariates.} {cmd:tvcov(}{it:a1 a2 a3}{cmd:)} (several: separated by '|') declares a covariate that changes between
waves, as RSiena's {cmd:varCovar}: the simulation of period {it:p} and its observed statistics use the covariate of wave {it:p}. The
effects are the ordinary covariate effects, called with the covariate's name (the first variable without trailing digits). The values are
centred by the mean of all periods' values (simX: the range and the similarity mean pool all periods). The plugin receives the
period's values through the batch frame (protocol 21). Validation against RSiena 1.6.6 (s50, alcohol waves 1-2 as the changing covariate;
density, reciprocity, transitive triplets, altX, egoX, simX, sameX): the observed statistics are identical to RSiena's targets (238, 160 [80
mutual dyads], 225, 12.38, 20.38, 21.996, 80) and the estimates agree: density -2.69 (-2.70), reciprocity 2.41-2.44 (2.41-2.44),
transTrip 0.63 (0.63), altX -0.03 (-0.03 to -0.04), egoX 0.034-0.037 (0.036-0.042), simX 1.02-1.05 (0.96-1.04), sameX -0.16 (-0.11 to -0.15).

{marker twomode}{...}
{pstd}
{bf:Two-mode networks.} A two-mode (bipartite) network, declared with {cmd:nwset, mat(}{it:A}{cmd:) bipartite}, is estimated like
RSiena's bipartite dependent variable: the actors (by default the rows of the affiliation matrix, {opt actormode()}) change their ties
to the events; events do not act. Internally the network is embedded in a directed one-mode graph on all nodes in which only
actor-to-event dyads are free (all others are structurally zero), so the one-mode sampler, native plugin and statistics are used
unchanged; the rate is the per-actor rate. Available effects: {opt outdegree} (density), {opt indegpopularity} (inPopSqrt), {opt outactivity} (outAct), {opt cycle4}, {opt outiso},
{opt antiiniso}, {opt antiiniso2}, {opt inplus3}, {opt gwdspfb()}, {opt avdeg()}, {opt outtrunc()}/{opt outmore()}/{opt outthreshold()}, the {opt ownx()} ego-degree effects and
{cmd:outinass}, and covariate effects {opt nodeocov()} (egoX, a value per actor), {opt nodeicov()} (altX, per event), {opt egosqx()}, {opt altsqx()} and {opt netx()} (altindist2
totindist2 simegoindist2 sameegoindist2 crossxoutact samexcycle4 sameinxcycle4 homxoutact2 avgroupegox totgroupegox); {opt tvcov()} covariates work in all of them. The covariates
are variables on the {it:node} rows of the dataset after {cmd:nwset} (one row per node, {cmd:_nwmode} tells the mode), centred within their mode. A co-evolving {opt behavior()} of
the actors is possible (the events are generated as absent actors); its network effects are {opt behegox} and
{cmd:netbeh(egosqx altindist2 totindist2 simegoindist2 sameegoindist2 samexcycle4 crossxoutact avgroupegox totgroupegox)}. A dyadic covariate ({opt dyadcov()}, a matrix with one row per actor and one column per event)
and {opt interact()} of the effects above are available too. Several waves ({opt waves()}) are supported. Not available: reciprocity, triads, balance,
gwesp, structural rate effects, {opt missnet()}, endowment/creation, two-mode members in {cmd:nwsaom multinet}; RSiena's sameXOutAct/diffXOutAct cannot be evaluated by siena07 in a
two-mode network and are not offered. Validation against RSiena 1.6.6 on a simulated 40 x 20, 3-wave network
(known parameters; dev/saom_rsiena_twomode_sim.R): the observed statistics are identical to RSiena's targets (density 529,
cycle4 12990, inPopSqrt 2399.29, outAct 4359, egoX 103.142, altX 71.484), and the estimates agree: density -2.37..-2.50 against -2.42..-2.53,
cycle4 0.094 (0.09-0.096), inPopSqrt 0.57 (0.57-0.59), outAct 0.06-0.08 (0.07-0.08), egoX 0.55-0.57 (0.55-0.57), altX 0.217 (0.215),
rates 4.49 and 3.03 (4.52, 3.05).

{marker multibeh}{...}
{pstd}
{bf:Several behaviors.} {cmd:behavior(}{it:vars}{cmd: : }{it:effects}{cmd: | }{it:vars}{cmd: : }{it:effects}{cmd:)}: '|' separates
the behaviors, each given as one variable per wave, optionally followed by ':' and that behavior's own effects
({opt linear quadratic avalt avsim}, their {opt endow}/{opt creation} variants, and {opt behsim} for the first behavior);
without ':' the global effect options apply to every behavior. Every behavior has its own rate per period; at each
step the acting variable is drawn in proportion to its rate and then the actor uniformly (RSiena's mechanism). The
behaviors interact only through the network (avAlt and avSim read it; {opt behsim} selects ties on the first behavior).
Coefficients are named {cmd:beh_}{it:name}{cmd:_}{it:effect}, {it:name} being the first variable without its trailing
digits; {cmd:e(rates_beh)} has one row per behavior. Not yet combinable with {opt symmetric}, {opt ratecov()},
{opt present()}, {opt missnet()}/{opt missbeh()}, {opt structural()}, network {opt endow()}/{opt creation()}, or
{cmd:estat gof}/{cmd:mems}. Validation against RSiena 1.6.6 (s501-s503, alcohol and smoking from s50a/s50s; outdegree,
reciprocity, transitive triplets; linear, quadratic and avAlt for each behavior): outdegree -2.65 against -2.65,
reciprocity 2.42 against 2.43, transitive triplets 0.61 against 0.61; alcohol linear 0.42 (0.43), quadratic -0.54 (-0.54),
avAlt 1.28-1.30 (1.26-1.31); smoking linear -1.91 to -1.94 (-1.92 to -1.94), quadratic 2.02-2.03 (2.03-2.05), avAlt
1.92-1.97 (2.01-2.06); network rates 6.5 and 5.3 (6.5, 5.3), alcohol 1.25 and 1.68 (1.25, 1.66), smoking 2.8 and 2.6 (2.7, 2.6).

{pstd}
{opt transtiesendow}/{opt transtiescreation} split {opt transties} the same way. RSiena's rule, which
is general: the endowment statistic is minus the sum, over the ties lost between the waves, of the
effect's tie statistic evaluated in the {it:start} network (for transTies: 1 if the lost tie had a
two-path), and the creation statistic is the sum over the ties gained of the tie statistic in the
{it:end} network, while the ministep contribution is the usual change statistic restricted to
withdrawals or to new ties. Checked against RSiena 1.6.6 on s501-s503 (density, reciprocity and
the transTies split): targets -62 and 68 are identical, and over three seeds endowment
-0.40/-0.33/-0.45 against RSiena's -0.32/-0.38/-0.41, creation 2.47/2.39/2.47 against
2.40/2.43/2.44, density -2.96 against -2.96.

{marker ratecov}{...}
{title:Covariate-dependent rate}

{pstd}
By default every actor has the same opportunity rate within a period. {opt ratecov(varlist)} lets
node covariates speed some actors up and slow others down (RSiena's RateX effects): actor i's rate
becomes the period rate times exp(sum_k {it:b_k}*{it:x_k}[i]), one coefficient per variable, so a
higher value means more frequent opportunities to act (or fewer, for a negative coefficient). The
covariates are centred by their means unless {opt nocenter} is given.

{pstd}
The coefficients are estimated jointly with the other effects (and, with {opt unconditional}, the
rate) in one Robbins-Monro parameter vector. {opt ratecovcoef(numlist)} sets their starting values,
one per variable or one for all (default 0). If the data do not identify a coefficient (a
non-positive derivative estimate), it is kept fixed at its starting value, as RSiena does;
{bf:e(ratecoefs_fixed)} (with one variable {bf:e(ratecoef_fixed)}) reports whether this happened.
{opt ratecov()} cannot yet be combined with co-evolution, multi-wave models, {opt present()}, or
{opt missnet()}; it can be combined with {opt symmetric}.

{pstd}
With {opt waves()} the coefficient is one value shared by every period (RSiena's {cmd:RateX} has no
period index), each period keeps its own basic rate. Checked against RSiena 1.6.6 on s501-s503
with the alcohol covariate of s50a (directed, density and reciprocity): RateX 0.355 against RSiena's
0.357, density -2.38 and reciprocity 2.85 against -2.375 and 2.849, rates 5.7/4.4 against 5.67/4.47;
and for a symmetrized version (BJOINT, {opt symtype(joint)}): RateX 0.153 against 0.151, density
-1.316 against -1.312, rates 0.307/0.264 against 0.305/0.263.

{marker dyadcov}{...}
{title:Dyadic covariates}

{pstd}
{opt dyadcov(matnames)} and {opt dyadcovrecip(matnames)} add RSiena's {cmd:X} and {cmd:XRecip} effects for
covariates defined on pairs of actors (kinship, distance, an earlier relation). Each name is an
{it:n} x {it:n} Stata matrix; the value is centred by the mean of its non-missing off-diagonal cells (unless
{opt nocenter}), missing cells are 0 after centring and left out of the statistic, and a tie's statistic is its
value ({cmd:XRecip}: its value if the reverse tie exists). Natively the matrix travels to the plugin as {it:n}
attribute columns, so {it:n} is limited by Stata's variable limit (about 2,000 in Stata BE, minus the other
covariates). Checked against RSiena 1.6.6 on s501-s503 with the absolute difference of the alcohol variable of
s50a as the covariate (density and reciprocity in the model): the targets agree (-82.42 for {cmd:X}), and the
estimates are X -0.145 to -0.151 against -0.147, XRecip -0.059 to -0.070 against -0.066, and with 120 missing
cells -0.157 to -0.160 against -0.161.

{marker covariates}{...}
{title:Covariate effects for several variables}

{pstd}
{opt samex()}/{opt nodematch()}, {opt egox()}/{opt nodeocov()}, {opt altx()}/{opt nodeicov()},
{opt nodecov()}, {opt simx()}/{opt simcov()} and {opt ratecov()} take a varlist, one effect and
coefficient per variable, e.g. {cmd:samex(smoke1 sport1) egox(alcohol1) altx(alcohol1) simx(alcohol1)}.
Coefficients are named {it:effect}_{it:variable} ({cmd:samex_smoke1}); e(b), and {opt theta0()},
list the effect types in their fixed order and the variables in the order given. An interaction
names a variable's effect by its coefficient name, {cmd:interact(samex_smoke1#transtrip)}.

{pstd}
Like RSiena's {cmd:coCovar(..., centered = TRUE)}, the default, {cmd:nwsaom} centres the covariates
of {opt egox()}, {opt altx()}, {opt nodecov()} and {opt ratecov()} by their means (missing values
take the mean), so that every coefficient, outdegree and the rate included, is RSiena's.
{opt nocenter} uses the raw values, as {cmd:centered = FALSE}; this changes only the outdegree
coefficient and the rate intercept. {opt samex()} does not depend on the centring; {opt simx()} is
centred by the covariate's similarity mean, as RSiena's simX. The covariate means are returned in
{bf:e(covmeans)}. The default output is compact; with {opt detail}, {cmd:nwsaom} also lists the
covariate means and RSiena's names of the covariate, interaction and behavior effects
("alcohol1 ego", "same smoke1", "alcohol1 similarity", "alcohol1 ego x reciprocity"); all names are
in {bf:e(rsiena_labels)}. With raw (uncentred) covariates, the model with gwespFF, transRecTrip,
inPopSqrt, outAct, sameX on smoke1 and sport1 and egoX/altX/simX(alcohol1) agrees with RSiena's
default run within 0.07 standard errors for every coefficient (conditional and unconditional, five
seeds), and RateX on two raw covariates within 0.03.

{pstd}
Validation against RSiena 1.6.6 (glasgow waves 1-2, five seeds each, conditional and unconditional):
sameX on smoke1 and sport1; egoX, altX and simX on two covariates; a model with gwespFF,
transRecTrip, inPopSqrt, outAct, sameX on two covariates and egoX/altX/simX(alcohol1); a
co-evolution model (waves 1-3, smoking) with sameX on sport1 and alcohol1, simX(smoking),
linear, quadratic and avAlt; RateX on two covariates. Every estimate, rates included, agrees
with RSiena's within 0.07 standard errors (mean 0.02), standard errors within 10% (RateX,
unconditional: nwsaom's 0.7-0.95 of RSiena's, whose mean is inflated by one seed). With
outPopSqrt in place of outAct in the larger model, RSiena does not converge on these data
(maximum convergence ratio about 3 on every seed, also started from {cmd:nwsaom}'s estimates),
while {cmd:nwsaom} converges (below 0.25). The reason is RSiena's default internal parameter 0 for
outPopSqrt, reported as {browse "https://github.com/stocnet/rsiena/issues/151":RSiena issue #151}
(see the note under {help nwsaom_remarks##nwsaom_interaction:Interaction effects}).
Run with {cmd:setEffect(..., outPopSqrt, parameter = 1)}, RSiena converges on every seed and agrees
with {cmd:nwsaom} within 0.06 standard errors (conditional, five seeds). Timings for the larger
model: {cmd:nwsaom} about 1 s, RSiena 5-7 s per fit.

{marker undirected}{...}
{title:Undirected/symmetric relations}

{pstd}
A non-directed relation is one where every tie is symmetric (x_ij always equals x_ji). As in RSiena,
which treats a symmetric one-mode dependent network as non-directed, {cmd:nwsaom} models it as such
when the waves are declared undirected ({cmd:nwset ..., undirected}, {help nwsym}) or are directed
networks that are all tie-symmetric; the option {opt symmetric} requests it explicitly. Waves that
mix undirected networks with directed ones that are not tie-symmetric are refused, as is
{opt symmetric} with such directed waves ({cmd:nwsaom} does not symmetrize data). Tie-symmetric
directed waves stay a directed relation, with a note, when {opt reciprocity} is requested or the
non-directed model does not apply ({opt behavior()}, endowment/creation effects).

{pstd}
{opt symtype()} chooses how a tie changes (RSiena's model types, by name or modelType number):

{p 8 12 2}{bf:forcing} (modelType 2, AFORCE; the default, as RSiena's default for a symmetric
network): an actor, at the per-actor rate, chooses one tie to create or end (or none) exactly as in
the directed model, and imposes the change.{p_end}
{p 8 12 2}{bf:confirmation} (3, AAGREE): as {bf:forcing}, but a new tie is only made if the alter
confirms it, with the logistic probability of the alter's utility of the new tie; ending a tie is
unilateral.{p_end}
{p 8 12 2}{bf:force} (4, BFORCE), {bf:agree} (5, BAGREE), {bf:joint} (6, BJOINT): pairwise; a pair of
actors meets and the tie changes if the initiator wants it (force), if both want a new tie or either
wants to end one (agree), or if their summed utilities favor the change (joint).{p_end}

{pstd}
RSiena's {bf:confirmation} also computes the confirmation step for the no-change option (the actor
choosing itself), which changes nothing but adds to the scores behind the derivative estimate;
{cmd:nwsaom} leaves it out.

{pstd}
Effects that are not meaningful for a non-directed relation are refused: {opt reciprocity} (every
tie is reciprocated), {opt cycle3}, {opt inactivity}, {opt outpopularity}, {opt ininass},
{opt inoutass}, {opt outoutass}, {opt antiiso}, {opt isolatepop}, {opt transrectrip}, and
{opt transtrip} (each is constant, duplicates another effect, or is not offered by RSiena for a
non-directed relation). {opt outdegree}, {opt indegpopularity}, {opt outactivity}, {opt cycle4},
{opt isolatenet}, {opt outiso}, {opt antiiniso}, {opt antiiniso2}, {opt inplus3}, {opt outinass},
{opt gwesp()}, {opt transties}, {opt balance}, and every covariate effect ({opt nodecov()}/
{opt nodeicov()}/{opt nodeocov()}/{opt nodematch()}/{opt simcov()} and their egoX/altX/sameX/simX
aliases) are available.

{pstd}
{opt waves()}, {opt present()}, {opt missnet()}, and {opt ratecov()} (network-only) can each be
combined with {opt symmetric}, and so can {opt behavior()}: an undirected relation co-evolving with a behavior
(native plugin with the threaded batch path required; {cmd:nwsaom, ... symmetric symtype(joint) outdegree
behavior(b1 b2) linear avalt}). The network rates are reported on RSiena's scale, as for network-only fits.
Checked only partly against RSiena: its own estimation of this model (symmetrized s501/s502, alcohol
behavior, BJOINT) is unstable - three of four seeds stop at {cmd:thetaBound} and the finished one fixes
avAlt at 0 - but where RSiena produced numbers they agree with {cmd:nwsaom} (behavior linear 0.32 against
0.29-0.32, behavior rate 1.22 against 1.23-1.26, density -1.32 against -1.27).

{pstd}
{bf:agree} reproduces RSiena's alter probability exactly, which for an alter utility u is
{it:sigma}(-|u|), where {it:sigma} is the logistic function.

{pstd}
{it:The rate of a non-directed model.} For {bf:forcing} and {bf:confirmation} it is the per-actor
rate, as in the directed model and in RSiena. Validation (glasgow waves 1-2 symmetrized and declared
undirected; density, and density with {opt nodematch(smoke1)}; conditional and unconditional; RSiena
and {cmd:nwsaom}, five seeds each): every estimate, the rate included, within 0.06 RSiena standard
errors (mean 0.025); e.g. {bf:forcing}, conditional, rate 1.97, density -1.35. For the pairwise
types:

{pstd}
{cmd:nwsaom} simulates a pairwise ministep as an actor getting an
opportunity at rate rho (the per-actor rate of every other {cmd:nwsaom} model) and picking an alter
among the other n - 1 actors; RSiena gives each actor the basic rate lambda, draws the actor and then
the alter by these rates, and runs at total rate n(n - 1)lambda^2, so each pair at rate lambda^2.
The two are the same process with lambda^2 = rho/(n - 1) (n: actors present). {cmd:e(rate)} is
reported on RSiena's scale, and {cmd:e(rate_actor)} keeps rho:

{p 8 12 2}- unconditional estimation: {cmd:e(rate)} = lambda = sqrt(rho/(n - 1)), RSiena's basic rate
parameter; its standard error by the delta method, se(rho)/(2 sqrt(rho(n - 1))).{p_end}
{p 8 12 2}- conditional estimation: {cmd:e(rate)} = the mean time to reach the observed distance at basic
rate 1, as RSiena reports it, which is {cmd:nwsaom}'s time divided by n - 1, and its SD.{p_end}

{pstd}
The conditional rate is thus on the scale of lambda^2 (the time at basic rate 1 equals lambda^2),
the unconditional one on the scale of lambda, in RSiena as here: on glasgow waves 1-2 symmetrized
0.30 and 0.55 ({bf:joint}; 0.55^2 = 0.30). With {opt ratecov()}, actor i's rate is
lambda exp(b x_i), the alter is drawn by these rates as well, and the same conversion holds with n
all actors. {opt rate0()} is on RSiena's scale too. The convergence t-ratio of the rate does not
depend on the scale.

{pstd}
Validation (glasgow waves 1-2 symmetrized; density alone, density and {opt nodematch(smoke1)}, and
density with {opt ratecov(smoke1)}, centered; each for all three types, conditional and
unconditional; RSiena 1.6.6 and {cmd:nwsaom}, five seeds each): every estimate, the rates and the
covariate-rate coefficient included, agrees with RSiena's within 0.1 RSiena standard errors (mean
0.04), except one conditional covariate-rate coefficient ({bf:force}, 0.13); forward simulations at
fixed parameters give the same expected statistics. RSiena's default starting value for the rate of
these model types is on the per-actor scale (5.6 on these data); from it, unconditional estimation
often fails ("Unlikely to terminate this epoch") or leaves the rate at its start, so the RSiena
references start the rate at 0.5.

{pstd}
Before 2026-10-01 {cmd:e(rate)} of a symmetric model was the per-actor rate rho; {bf:agree} used a
different alter probability, the scores behind the standard errors used only the initiating actor's
side ({bf:joint} standard errors were twice RSiena's), and with {opt ratecov()} the actor and the
alter were drawn uniformly, so the covariate could not affect who acts.

{marker sizelimits}{...}
{title:Size limits}

{pstd}
{bf:How large a network can be fitted.} With the native (C) engine, fit time grows roughly with the cube of the number of actors above about 1,000 actors. For a plain model (outdegree,
reciprocity, transitive triplets; three waves; about ten ties per actor; {opt k0(30)} {opt k3(200)}): 250 actors 1.5 seconds, 500 actors 2.6 s, 1,000 actors 10 s, 2,000 actors 67 s, 4,000 actors
520 s; a full-length run costs several times more. One thousand actors is routine, a few thousand take minutes; beyond roughly 10,000 actors the model itself (every ministep considers all
possible alters) is the limit.

{pstd}
{bf:Stata's own limits matter.} Anything given to {cmd:nwsaom} as a Stata matrix ({opt dyadcov()}, {opt dyadcovrecip()}, {opt missnet()}) is limited by Stata's matrix size: 800 x 800 in Stata/BE,
11,000 x 11,000 in Stata/SE, 65,534 x 65,534 in Stata/MP. A dyadic covariate also travels to the plugin as one variable per actor, so the native engine handles it up to about 1,000 actors (1,023
covariate arrays; Stata/BE has 2,048 variables altogether). Bring larger networks in as edge lists, not matrices.

{pstd}
{bf:Check which engine ran.} If a model exceeds a limit of the native engine, {cmd:nwsaom} falls back to the Mata engine without an error; it gives the same results but is orders of magnitude slower.
After fitting a large network look at {cmd:e(engine)} ({cmd:native} or {cmd:mata}). Until 22 October 2026 a dyadic covariate on 129 or more actors fell back to Mata by mistake.

{marker compchange}{...}
{title:Composition change (joiners and leavers)}

{pstd}
{opt present(varlist)} handles actors who join or leave the network between observed waves - real
RSiena's own "method of joiners and leavers" (Huisman and Snijders 2003, Section 5.3.3 of its own
manual). One 0/1 variable per wave (same convention as {opt behavior()}): 1 marks an actor present
(eligible to act, and eligible to be tied to by another actor) at that wave, 0 marks absent. An
actor is treated as present for a given inter-wave PERIOD only if present at BOTH that period's own
endpoint waves - {cmd:nwsaom} supports WHOLE-PERIOD composition change only (an actor's presence can
change at wave boundaries; for a change at an arbitrary point strictly between two waves use {opt joinat()}/{opt leaveat()}, below) - this covers the common
real-world case (an actor enrolled, transferred, or dropped out between whole survey waves).

{pstd}
The wave data must be prepared by the user, as RSiena's manual also requires: an absent actor's
ties should be coded 0 before the actor joins and kept at their last observed values after the
actor leaves. The same applies to {opt behavior()} values in co-evolution models. If this is done
wrong, the absent actor's row and column show changes the model cannot explain, which can make the
fit stop at the {bf:thetaBound} safeguard (see
{help nwsaom_remarks##endowcreation:Endowment/creation functions}).

{pstd}
Composition change requires unconditional Method-of-Moments estimation in RSiena (manual, Section
7.12.1), and {cmd:nwsaom} uses it even without {opt unconditional} (see
{help nwsaom_remarks##estimation:Estimation}): the rates are estimated with the other parameters,
only the actors present in a period get opportunities to act, and a rate's score counts only them.
{opt present()} uses the native (C) backend, including the draw of the acting actor, the pooled
rate, and the restriction of tie targets, so a fit with composition change runs about as fast as
one without.

{pstd}
{bf:Joiners and leavers at fractional times}: {opt joinat(varname)} and {opt leaveat(varname)} give each actor's joining and
leaving time on RSiena's scale (wave 1 = time 1, wave W = time W; one interval per actor), reproducing
{cmd:sienaCompositionChange()} with option 1. Within a period the active actors act at their rate; a joiner takes on the
ties it had in the start network, a leaver loses all its ties, and (as in RSiena) an inactive actor stays among the possible
alters of an active actor - a tie made to it is removed again at the end of the period when the period has join/leave events.
The rate parameter's compensator is the time-integral of the number of active actors. The simulation reproduces RSiena's:
the five scenarios of {cmd:dev/saom_rsiena_tc_scen.R} (joiners/leavers in each period, actors absent for a whole period) give the same
deviations from the targets as {cmd:siena07}, and s50 with 10 joiners/leavers gives estimates within noise of RSiena (density,
reciprocity, transitive triplets, both rates, and a rate covariate). The same rules apply to {opt present()}: since 2026-10-22 an
absent actor stays among the alters of an active actor, as in RSiena. As in RSiena (option 1), the ties an absent actor has in the
data are used as given - code them 0 for the waves in which the actor is absent - and the distance (the rate target) counts them.
Works with co-evolving {opt behavior()} (one or several behaviors; not with behsim or endowment/creation effects); works with {opt symmetric} (not together with {opt ratecov()}); not yet combined with {opt endow()}/{opt creation()}.

{pstd}
{bf:Genuinely out of scope}: RSiena's composition-change options 2-4 (other treatments of the data of absent actors), several
intervals per actor; the "structural zeros/ones" alternative method real RSiena's own manual also documents (a simpler, less
statistically efficient approach - joiners and leavers was chosen instead). Missing tie/behavior data (a related but distinct
mechanism from composition change) IS supported - see {help nwsaom_remarks##missingdata:Missing data} below.

{marker missingdata}{...}
{title:Missing data}

{pstd}
{opt missnet(matlist)}/{opt missbeh(varlist)} handle dyads and actors whose value at a wave is
unknown, RSiena's missing-data treatment (manual, Section 5.3.2). This differs from composition
change: missing data are uncertainty about the ties or values of an active actor, composition
change means the actor is not part of the network. Both can be used together.

{pstd}
{opt missnet(matlist)} takes one 0/1 n x n matrix name per wave, in the same order as
{opt wave1()}/{opt wave2()} or {opt waves()} (e.g. two waves: {cmd:missnet(m1 m2)}); 1 marks a dyad
missing at that wave, 0 observed. These are Stata matrices, not {cmd:nwset} networks; build them
with {cmd:matrix input} or {cmd:mkmat}. {opt missbeh(varlist)} takes one 0/1 variable per wave (as
{opt present()}), marking actors whose behavior value is missing at that wave; it requires
{opt behavior()}. The two options can be used separately or together.

{pstd}
Missing values are handled in two steps, as in RSiena. (1) {bf:Imputation}: a missing dyad takes
its value from the last wave where it was observed (0 if never observed so far); a missing behavior
value takes the previous observation, else the next observation, else the mode of that wave.
Imputed values are then simulated normally; unlike {opt present()}, missing data do not restrict
who can act. (2) {bf:Masking}: a dyad or actor missing at either wave of a period is excluded from
the observed target statistic and from every simulated statistic for that period, so the moment
conditions are not biased. This works with every effect's statistic unchanged.

{pstd}
For {opt avalt}/{opt avsim} the masking is an approximation: an actor's statistic depends on the
current values of its alters, which vary across simulations. Masking is exact for effects that
depend only on the actor's own value ({opt linear}/{opt quadratic}). In practice masking works
better than not masking, but with heavy missingness and {opt avalt}/{opt avsim} it can be less
precise.

{pstd}
Missing data use the native (C) backend, with the same results as the Mata engine to machine
precision. A dyad missing at either wave of a period is not counted in the distance that
conditional estimation simulates to, nor in the rate's distance statistic of unconditional
estimation, nor in their target (as RSiena).

{pstd}
{bf:Missing covariate data} ({opt nodematch()}, {opt nodecov()}, {opt nodeicov()}, {opt nodeocov()},
{opt simcov()} and their aliases) follows RSiena (checked against its source): a missing value is
imputed with the covariate mean when actors decide ministeps, but the {it:statistic} - the target and
every simulated one - skips a tie whose relevant actor is missing (the alter for {opt altx()}, the
ego for {opt egox()}, either one for {opt samex()}/{opt simx()}). With the default centring a missing
{opt altx()}/{opt egox()}/{opt nodecov()} value is 0, so skipping changes nothing; under
{opt nocenter} and for {opt samex()}/{opt simx()} it does, and {opt simx()}'s range and similarity
mean use the observed values only. Checked against RSiena 1.6.6 on s501/s502 with 8 of 50 covariate
values missing: density, reciprocity, altX, egoX and simX agree to within sampling noise (simX 0.79
against RSiena's 0.78; before this was handled it was 1.02). An {opt interact()} that names a
{opt samex()} or {opt simx()} effect whose variable has missing values is rejected.

RSiena's own "structural zeros/ones" mechanism - a
separate, simpler alternative to ordinary missing data for dyads whose value is fixed by design
rather than merely unobserved - IS implemented; see {help nwsaom_remarks##structural:Structural zeros/ones}
below.

{marker structural}{...}
{title:Structural zeros/ones}

{pstd}
{opt structural(matname)} marks dyads whose tie value is fixed by design rather than chosen by an
actor, RSiena's structural values. Unlike missing data, the value of a structural dyad is known
and cannot change (e.g. a mandated reporting relationship, an impossible tie, or a dyad held fixed
for a counterfactual). RSiena codes structural zeros and ones as 10 and 11 in the network data;
{cmd:nwsaom} uses a separate 0/1 matrix instead, like {opt missnet()}.

{pstd}
{opt structural(matname)} takes one 0/1 n x n Stata matrix (not an {cmd:nwset} network; build it
with {cmd:matrix input} or {cmd:mkmat}) with a zero diagonal; 1 marks a dyad whose value is fixed
for the whole period. A marked dyad must have the same observed value in {opt wave1()} and
{opt wave2()}; a dyad that changed between the waves is refused with an error.

{pstd}
A structural dyad is removed from every actor's set of possible ministep changes. All effect
statistics are used unchanged.

{pstd}
Scope: two waves ({opt wave1()}/{opt wave2()}, not {opt waves()}), network-only (no
{opt behavior()}); cannot yet be combined with {opt symmetric}, {opt ratecov()}, or the network
endowment/creation split ({opt outdegreeendow}/{opt outdegreecreation}/{opt reciprocityendow}/
{opt reciprocitycreation}), each refused with {opt structural()}. A fit on glasgow takes about
0.2 s.

{marker estimation}{...}
{title:Estimation}

{pstd}
{bf:Speed and threads.} With the native backend, the periods' starting data are handed to the
compiled simulator once per fit, and phases 1 and 3 run all their simulations in one call on
worker threads; phase 2 is sequential by construction (each Robbins-Monro step needs the previous
one) and runs only the periods of a step in parallel, and only when the network is large enough
for threads to pay off. {opt cores(#)} sets the number of threads (default: all physical cores).
Each simulation draws from its own random stream derived from the seed and its position, so a
given {opt seed()} gives identical results with {cmd:cores(1)} and with any other number of
threads. Non-directed ({opt symmetric}), {opt ratecov()}, endowment/creation and
{opt structural()} fits use the threaded path too (e.g. 0.3 s for {opt ratecov()} with two
covariates). Timings on one 18-core machine: the s50 three-wave network-only model
{cmd:outdegree reciprocity transtrip} 0.33 s, the two-wave {cmd:outdegree reciprocity} model
0.23 s; the s50 three-wave co-evolution model 0.63 s; a synthetic 500-actor three-wave
co-evolution model 18 s.

{pstd}
Coefficients are estimated by the Method of Moments via Robbins-Monro stochastic approximation,
RSiena's default algorithm and phase structure: Phase 1 estimates the Jacobian
(sensitivity of each expected statistic to each parameter) via {opt k0()} independent simulated
replicates at the starting values and ends with RSiena's partial quasi-Newton step; Phase 2
performs the Robbins-Monro update across RSiena's default of 4 diminishing-gain subphases
({cmd:nsub=4}, {cmd:firstg} default 0.2, {cmd:reduceg=0.5}, RSiena's per-subphase minimum/maximum
iteration schedule); Phase 3 runs {opt k3()} further replicates at the estimates to compute the
standard errors (e(V), RSiena's sandwich formula), the convergence t-ratios {cmd:e(tconv)} (mean
deviation / its standard deviation, one per parameter including the rates) and RSiena's overall
maximum convergence ratio {cmd:e(tconv_max)}. As in RSiena, a fit is considered converged when
every |t| is below 0.1 and the overall ratio below 0.25; otherwise, run the model again from the
estimates ({opt theta0()} and {opt rate0()}, see the examples in {help nwsaom}). Below the coefficient
table, every fit prints the overall ratio and names any parameter whose |t| is 0.1 or more; the
{opt detail} option lists the t-ratios of all parameters, rates included, and {cmd:e(tratio)}
holds the ones of the coefficients in e(b), on the same scale.

{pstd}
{bf:The rate parameters} (one per period: how often, on average, an actor gets the opportunity to
change a tie) are estimated in one of RSiena's two ways, and {cmd:nwsaom} uses RSiena's default for
each kind of model (RSiena's {cmd:initializeFRAN()}: conditional when there is a single dependent
variable, and not with composition change):

{p2colset 9 13 15 2}{...}
{p2col: o}{bf:Conditional estimation} (RSiena's {cmd:cond = TRUE}), the default for a network-only
model: the rates are not Robbins-Monro parameters. Each period is simulated at rate 1 until the
distance between the simulated network and the observed network at the start of the period (dyads
that differ; dyads missing at either wave not counted; symmetric networks in steps of two) reaches
the observed distance between the period's two waves, and the effect statistics are those of the
network at that point. A period's rate is the mean of the simulated times over the {opt k3()}
phase-3 replicates, and {cmd:e(rate_se)}/{cmd:e(rates_se)} report their standard deviation, as
RSiena does ({cmd:ans$rate}, {cmd:ans$vrate}); there is no rate t-ratio. A {opt ratecov()}
coefficient remains a Method-of-Moments parameter, as in RSiena.{p_end}
{p2col: o}{bf:Unconditional estimation} (RSiena's {cmd:cond = FALSE}), option {opt unconditional},
and always for co-evolution and {cmd:nwsaom multiplex} models (two dependent variables) and for
network-only models with composition change ({opt present()} restricting some actor): every rate
is a Method-of-Moments parameter estimated jointly with the effects; its statistic is the distance
above at the end of a unit period, its standard error comes from the sandwich formula. Starting
values: {opt rate0()}, else RSiena's closed-form value computed from the data (a start far from
the data, e.g. twice the closed-form value, can make the phase-1 derivative estimates unusable
and the fit diverge).{p_end}
{p2colreset}{...}

{pstd}
The two estimators are consistent for the same model but differ in finite samples: on RSiena's
s50 data RSiena's conditional and unconditional estimates differ by up to 0.3 standard errors
(outdegree more negative and reciprocity larger under conditional estimation). Checked against
RSiena 1.6.6 (five models on s50, five seeds each): with the default (conditional) estimation every
parameter, the rates included, is within 0.07 RSiena standard errors of RSiena's default output,
and with {opt unconditional} within 0.06 of RSiena's {cmd:cond = FALSE} output; the co-evolution
model agrees with RSiena's (unconditional) default within 0.05. Versions of {cmd:nwsaom} before
1 October 2026 did not centre covariates and held the rates of co-evolution models fixed, so
their estimates differ.

{pstd}
{opt waves(namelist)} chains three or more waves into one pooled fit: the effects are shared
across every period (their statistics summed over periods, RSiena's multi-period
Method-of-Moments convention), while each period has its own rate, reported as
e(rates)/e(rates_se)/e(rate_tratios) (1 x (nwaves-1) matrices) rather than the scalars
e(rate)/e(rate_se)/e(rate_tratio) of the two-wave {opt wave1()}/{opt wave2()} path.


{title:See also}

    {help nwsaom}, {help nwsaom_estat}, {help nwergm}
