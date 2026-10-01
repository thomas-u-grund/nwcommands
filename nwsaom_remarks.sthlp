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
{title:Multiplex (two networks)}

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
On the network side, {opt outdegreeendow}/{opt outdegreecreation} (replacing {opt outdegree}) and
{opt reciprocityendow}/{opt reciprocitycreation} (replacing {opt reciprocity}) correspond to the
endow/creation types of RSiena's density and recip. The statistics are RSiena's: an endowment
statistic is minus the sum, over the ties lost between the waves, of the effect's tie statistic in
the starting network (1 for outdegree; the reverse tie for reciprocity), a creation statistic the
sum over the ties gained of the tie statistic in the end network (on s50 waves 1-2: reciprocity
endowment -35, creation 27, as in RSiena). {opt outdegreeendow}/{opt outdegreecreation} is not
identified: lost plus gained ties is exactly the distance that conditional estimation simulates to
and that unconditional estimation uses as the rate's statistic, and RSiena reports a singular
covariance matrix for this model under both estimators. {cmd:nwsaom} therefore refuses it; use
{opt outdegree} with {opt reciprocityendow}/{opt reciprocitycreation}. On s50 waves 1-2 that model
gives (RSiena, unconditional estimation, mean of five seeds, in parentheses) outdegree -2.04
(-2.04), reciprocity endowment 0.77 (0.82, SE 0.8), reciprocity creation 3.65 (3.60), rate 4.32
(4.34); a fit takes about 0.2 s. The network split cannot yet be combined with co-evolution,
multi-wave models, {opt present()} (composition change), or {opt missnet()} (missing network
data); each is refused (error 198).

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
{bf:Not supported}: more than one co-evolving behavior variable, and the network
endowment/creation split together with {opt behavior()}.

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
non-directed model does not apply ({opt waves()}, {opt behavior()}, endowment/creation effects).

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
{opt present()}, {opt missnet()}, and {opt ratecov()} can each be combined with {opt symmetric}.
Otherwise the scope is two waves ({opt wave1()}/{opt wave2()}, not {opt waves()}) and network-only
models (no {opt behavior()}).

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

{marker compchange}{...}
{title:Composition change (joiners and leavers)}

{pstd}
{opt present(varlist)} handles actors who join or leave the network between observed waves,
RSiena's method of joiners and leavers (Huisman and Snijders 2003; RSiena manual, Section 5.3.3).
It takes one 0/1 variable per wave (as {opt behavior()}): 1 marks an actor present (able to act
and to receive ties) at that wave, 0 absent. An actor is present in a period only if present at
both of its waves. {cmd:nwsaom} supports composition change at wave boundaries only, not RSiena's
more general joining and leaving at any time within a period. This covers the common case of
actors who enrol, transfer, or drop out between survey waves.

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
{bf:Not supported}: joining and leaving within a period (only whole-period presence), and RSiena's
alternative method of structural zeros/ones for composition change, which is simpler but less
efficient. Missing tie and behavior data, a distinct mechanism, is supported; see
{help nwsaom_remarks##missingdata:Missing data}.

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
{bf:Not supported}: missing covariate data ({opt nodecov()}/{opt nodeicov()}/{opt nodeocov()}/
{opt simcov()} etc. must be fully observed). Structural zeros/ones, for dyads whose value is fixed
by design rather than unobserved, are supported; see
{help nwsaom_remarks##structural:Structural zeros/ones}.

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
