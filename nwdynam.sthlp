{smcl}
{* *! version 1.16.0  02sep2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_statmodels:[NW-2.6.7] Statistical Estimation of Networks}

{title:Title}

{p2colset 9 15 22 2}{...}
{p2col :nwdynam  {hline 2}}Dynamic Network Actor Model - choice, rate, and choice_coordination sub-models (MLE){p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwdynam}
[{it:{help netname}}]
{cmd:,}
[{opt submodel(string)}
{opt seed(#)}
{opt inertia}
{opt recip}
{opt indeg}
{opt outdeg}
{opt trans}
{opt cycle}
{opt commonsender}
{opt commonreceiver}
{opt four}
{opt nodetrans}
{opth same(varname)}
{opth diff(varname)}
{opth sim(varname)}
{opth ego(varname)}
{opth alter(varname)}
{opth tertius(varname)}
{opt egoalterint(varlist)}
{opt inertiawindow(#)}
{opt recipwindow(#)}
{opt indegwindow(#)}
{opt outdegwindow(#)}
{opt weightedinertia}
{opt weightedrecip}
{opt weightedindeg}
{opt weightedoutdeg}
{opt opportunities(varlist)}
{opt tie(netname)}
{opt intercept}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:General}
{synopt:{opt submodel(string)}}which DyNAM sub-model to fit - {bf:choice} (the default), {bf:rate}, or {bf:choice_coordination}; see {bf:Description} below{p_end}
{synopt:{opt seed(#)}}random-number seed before estimation{p_end}

{syntab:Effects (no decay - the entire prior event history counts equally)}
{synopt:{opt inertia}}choice sub-model only{p_end}
{synopt:{opt recip}}choice sub-model only{p_end}
{synopt:{opt indeg}}both sub-models (different meaning in each - see {bf:Description}){p_end}
{synopt:{opt outdeg}}both sub-models (different meaning in each - see {bf:Description}){p_end}
{synopt:{opt trans}}choice sub-model only - two-path closure (transitivity){p_end}
{synopt:{opt cycle}}choice sub-model only - two-path closure (cyclical){p_end}
{synopt:{opt commonsender}}choice sub-model only - two-path closure (common sender){p_end}
{synopt:{opt commonreceiver}}choice sub-model only - two-path closure (common receiver){p_end}
{synopt:{opt four}}choice sub-model only - three-path closure{p_end}
{synopt:{opt nodetrans}}both sub-models - embeddedness in transitive structures{p_end}
{synopt:{opth same(varname)}}choice sub-model only - homophily on a per-actor covariate{p_end}
{synopt:{opth diff(varname)}}choice sub-model only - heterophily (absolute difference) on a per-actor covariate{p_end}
{synopt:{opth sim(varname)}}choice sub-model only - homophily by similarity (negative absolute difference) on a per-actor covariate{p_end}
{synopt:{opth ego(varname)}}rate sub-model only - the candidate's own covariate value, no comparison{p_end}
{synopt:{opth alter(varname)}}choice sub-model only - the candidate receiver's own covariate value, no comparison{p_end}
{synopt:{opth tertius(varname)}}both sub-models - mean covariate value of the candidate's own in-neighbors{p_end}
{synopt:{opt egoalterint(varlist)}}choice sub-model only - interaction of the sender's and candidate's own covariate values (exactly two variables){p_end}

{syntab:Windowed effects (real-time recency cutoff - self-activating, see Description)}
{synopt:{opt inertiawindow(#)}}choice sub-model only - recency cutoff on {opt inertia}; self-activates {opt inertia}{p_end}
{synopt:{opt recipwindow(#)}}choice sub-model only - recency cutoff on {opt recip}; self-activates {opt recip}{p_end}
{synopt:{opt indegwindow(#)}}rate sub-model only - recency cutoff on {opt indeg}; self-activates {opt indeg}{p_end}
{synopt:{opt outdegwindow(#)}}rate sub-model only - recency cutoff on {opt outdeg}; self-activates {opt outdeg}{p_end}

{syntab:Weighted effects (count instead of presence - self-activating, see Description)}
{synopt:{opt weightedinertia}}choice sub-model only - self-activates {opt inertia}{p_end}
{synopt:{opt weightedrecip}}choice sub-model only - self-activates {opt recip}{p_end}
{synopt:{opt weightedindeg}}both sub-models - self-activates {opt indeg}{p_end}
{synopt:{opt weightedoutdeg}}both sub-models - self-activates {opt outdeg}{p_end}

{syntab:Opportunity restriction (choice sub-model only)}
{synopt:{opt opportunities(varlist)}}per-event candidate risk-set restriction; see {bf:Description} below{p_end}

{syntab:Cross-network effects}
{synopt:{opt tie(netname)}}presence in a SEPARATE, static exogenous network; see {bf:Description} below{p_end}

{syntab:Intercept (rate sub-model only)}
{synopt:{opt intercept}}genuinely continuous-time competing-risks hazard; see {bf:Description} below{p_end}
{synoptline}
{p2colreset}{...}
{pstd}Giving no effect option at all fits every structural effect for the chosen sub-model. Giving
one or more restricts the fit to exactly those. See {bf:Effect selection} below.{p_end}


{title:Description}

{pstd}
{cmd:nwdynam} fits a Dynamic Network Actor Model (Stadtfeld & Block 2017, "Interactions, Actors,
and Time: Dynamic Network Actor Models for Relational Events," {it:Sociological Science} 4,
318-352) to a timestamped sequence of directed dyadic events - the same kind of data
{help nwrem} works on, but factored differently. DyNAM splits the process into two conditionally
independent sub-models given the event history so far: a {bf:rate} sub-model (which actor acts
next) and a {bf:choice} sub-model (given that actor, which other actor they choose - a
conditional logit over the receiver set).

{pstd}
By default, both sub-models fit here use the ordinal partial likelihood (Cox-style, using only the
ORDER events happened in, never real elapsed time) - the same convention {help nwrem} already uses
throughout this package. The NO-intercept rate case (the {opt submodel(rate)} default) turns out to
be exactly this same ordinal partial likelihood, just over a different risk set than the choice
sub-model (verified against the reference R implementation on both a toy example and real data).
{opt intercept} (rate sub-model only) requests the genuinely DIFFERENT, continuous-time competing-
risks hazard variant instead - see its own paragraph below.

{pstd}
{cmd:nwdynam} requires {it:netname} to already be declared as an event-type, directed temporal
network via {help nwset}'s {opt eventtime(varname)} option:

	{cmd:. nwset sender receiver, eventtime(t) name(mynet)}
	{cmd:. nwdynam mynet}
	{cmd:. nwdynam mynet, submodel(rate)}

{pstd}
{opt intercept} ("expansion batch 17") requests goldfish's own genuinely continuous-time
competing-risks hazard variant of the rate sub-model - each actor is modeled as an independent
Poisson clock with hazard {it:exp(beta'X_i(t))}, and the fitted model becomes sensitive to the
ACTUAL SCALE of elapsed real time between events (matching {it:netname}'s own {opt eventtime()}
values), not just their order - {cmd:goldfish}'s own {cmd:teaching1.Rmd} vignette: "an intercept of
-14 means a waiting time of 334 hours." Matches {cmd:goldfish}'s own convention exactly (a literal
{cmd:1} as the first formula term requests an intercept - {cmd:dep ~ 1 + indeg(net)}), confirmed
directly against {cmd:goldfish}'s own {cmd:parseIntercept()} source. Every observed event after the
FIRST contributes {it:beta'X_{s_k}} minus {it:(t_k - t_{k-1})} times the summed hazard of every
actor; the first observed event contributes only its own {it:beta'X_{s_1}} term (checked directly
against real {cmd:goldfish} - there is no assumed risk period before the first observed event).
{opt submodel(rate)} only, matching {cmd:goldfish}'s own architecture (only the rate sub-model has
ever had an intercept concept - the choice sub-model's own conditional logit has none, by
construction). {opt weightedindeg}, {opt weightedoutdeg}, and two-mode (bipartite) networks
("expansion batch 18") are verified together with {opt intercept} - the same statistic swaps the
NO-intercept engine already uses turned out to compose correctly with the hazard-integral
aggregation exactly as written, confirmed by exact agreement with real {cmd:goldfish}.
{opt indegwindow()} and {opt outdegwindow()} combined with {opt intercept} remain REJECTED - a real,
disclosed architectural gap, not merely unverified: {cmd:goldfish}'s own {opt window()} mechanism
inserts synthetic "dissolve" events into the timeline at exactly {it:event_time + window} for every
windowed tie, forcing its piecewise-constant hazard machinery to recompute right at each expiry;
this command only recomputes statistics at real dependent events, so a windowed contact would
silently over-count for the rest of the current inter-event interval once {opt intercept}'s own
hazard-INTEGRAL aggregation is in play (the NO-intercept engine's ordinal partial likelihood never
integrates over real time at all, which is why {opt indegwindow()} and {opt outdegwindow()} already work
correctly without {opt intercept}).

	{cmd:. nwdynam mynet, submodel(rate) intercept indeg}
	{cmd:. nwdynam mynet, submodel(rate) intercept outdeg ego(dept)}
	{cmd:. nwdynam mynet, submodel(rate) intercept weightedoutdeg}

{pstd}
{bf:submodel(choice_coordination)} is goldfish's own THIRD sub-model (Stadtfeld, Hollway & Block
2017, "Dynamic Network Actor Models: Investigating Coordination Ties through Time,"
{it:Sociological Methodology} 47(1), 1-40) - a genuinely different likelihood from
{opt submodel(choice)}, for UNDIRECTED ("coordination") tie-formation events where neither actor
plays a privileged sender/receiver role (e.g. treaty formation, co-authorship). Requires an
UNDIRECTED, one-mode network - the opposite of {opt submodel(choice)} and {opt submodel(rate)}'s own
directed-only requirement:

	{cmd:. nwset sender receiver, undirected eventtime(t) name(mynet)}
	{cmd:. nwdynam mynet, submodel(choice_coordination)}

{pstd}
Mechanically, for each event, {cmd:nwdynam} computes an ordinary choice-submodel probability in
BOTH directions for every candidate pair {it:a},{it:b} - {it:p}({it:a} would choose {it:b}) and
{it:p}({it:b} would choose {it:a}) - multiplies them, and normalizes over every possible unordered
pair to get the probability that {it:a} and {it:b} form a tie together (a "multinomial-multinomial"
joint model, not a simple conditional logit). The per-effect STATISTICS themselves are identical to
{opt submodel(choice)}'s own {opt inertia}, {opt indeg}, {opt same()}, {opt diff()}, {opt sim()},
{opt alter()}, {opt nodetrans}, {opt trans}, {opt tertius()}, {opt four}, {opt egoalterint()}, and
{opt tie()} (confirmed directly against {cmd:goldfish}'s own source: every one of its own
{cmd:choice_coordination}-specific effect functions is a thin wrapper calling the identical
{opt choice}-side function) - only the AGGREGATION differs. Effect selection uses the SAME flag
names as {opt submodel(choice)} - giving nothing fits {opt inertia} and {opt indeg} together by
default. {opt recip}, {opt outdeg}, {opt cycle}, {opt commonsender}, {opt commonreceiver}, and
{opt ego()} are all rejected under {opt submodel(choice_coordination)} - {opt recip} and
{opt outdeg} because an undirected tie has no direction to reciprocate and in-degree/out-degree
coincide; {opt cycle}, {opt commonsender}, and {opt commonreceiver} because {cmd:goldfish} itself does
not register a {cmd:choice_coordination} version of them at all; {opt ego()} because it is
{opt submodel(rate)}-only, matching {opt submodel(choice)}'s own scope exactly. {opt tertiusDiff()}
remains real-goldfish-eligible but not yet wired - a real, disclosed gap rather than a blanket
restriction.
{opt opportunities()}, every window option, {opt weightedinertia}, {opt weightedrecip},
{opt weightedindeg}, {opt weightedoutdeg}, and two-mode networks are likewise not yet supported for
{opt submodel(choice_coordination)}.

	{cmd:. nwdynam mynet, submodel(choice_coordination) inertia}
	{cmd:. nwload mynet, xvars}
	{cmd:. gen dept = ...}
	{cmd:. nwdynam mynet, submodel(choice_coordination) inertia same(dept)}
	{cmd:. nwdynam mynet, submodel(choice_coordination) nodetrans trans}
	{cmd:. nwdynam mynet, submodel(choice_coordination) tertius(dept) four}
	{cmd:. gen dept2 = ...}
	{cmd:. nwdynam mynet, submodel(choice_coordination) egoalterint(dept dept2)}

{pstd}
{bf:Two-mode (bipartite) networks} are supported for a real, but DELIBERATELY NARROW, set of
effects: {opt inertia} (choice), {opt indeg} (choice), and {opt outdeg} (rate) - each verified to
match {cmd:goldfish} exactly on a real toy affiliation network (see {bf:Remarks} below). Declare
the network via {help nwset}'s {opt twomode} option combined with {opt eventtime()}:

	{cmd:. nwset sender receiver, twomode eventtime(t) name(mynet)}
	{cmd:. nwdynam mynet}

{pstd}
{cmd:nwdynam} requires every event's sender to be mode 1 and receiver to be mode 2 (never the
reverse), matching {cmd:goldfish}'s own strictly one-directional two-mode DyNAM architecture -
checked directly against the real event data, not assumed. {opt recip}, {opt outdeg} under
{opt submodel(choice)}, {opt commonreceiver}, and {opt indeg} under {opt submodel(rate)} are
rejected outright for two-mode networks - {cmd:goldfish} itself hard-rejects each of these at
estimation time (a candidate/sender role that structurally cannot exist when mode 2 never sends and
mode 1 never receives), not merely a scope choice on this command's own part. Every attribute effect
({opt same()}, {opt diff()}, {opt sim()}, {opt alter()}, {opt ego()}, {opt egoalterint()},
{opt tertius()}) is ALSO rejected for two-mode - a real limitation found DURING verification, not
assumed safe: direct comparison against {cmd:goldfish}'s own internal statistics showed even the
simplest attribute effects computing something different from the obvious combined-covariate
approach, traced to a {cmd:goldfish}-internal representation detail (its own "exclude the self-tie"
convention applied by raw row/column index rather than actual actor identity) that could not be
confidently reverse-engineered in the time available - disclosed as a real gap rather than shipped
with an unverified formula. {opt trans}, {opt cycle}, {opt commonsender}, {opt four},
{opt nodetrans}, and every windowed or weighted effect are likewise not yet verified for two-mode
and are rejected outright.

{pstd}
{opt opportunities(evvar actvar)} restricts the candidate risk set PER EVENT to a caller-supplied
list of available actors - {cmd:goldfish}'s own {cmd:opportunitiesList} {cmd:estimationInit}
argument (its own documentation: "ONLY for choice models"), rejected outright under
{opt submodel(rate)}. Takes exactly two numeric variables from the CURRENT Stata dataset, at the
time {cmd:nwdynam} is called, in a genuinely different SHAPE from the covariate options above: ONE
ROW PER (event, available-actor) PAIR, not one row per actor. {it:evvar} is the event's own
sequence number (1 through the number of events in {it:netname}, matching its own chronological
event order); {it:actvar} is an actor ID (1 through the number of actors, matching {it:netname}'s
own actor order) that was available as a candidate receiver for that event. An actor not listed for
a given event is excluded from the risk set for that event only; an event with no rows at all in
{it:evvar} and {it:actvar} has no candidates beyond the sender's own unconditional self-exclusion (still
applied regardless of whether the sender itself is listed as available - checked directly against
{cmd:goldfish}'s own behavior). Because {opt opportunities()} needs the event/available-actor shape
and {opt same()}, {opt diff()}, {opt sim()}, {opt alter()}, {opt ego()}, {opt tertius()}, and
{opt egoalterint()} each need the one-row-per-actor shape, the current dataset cannot satisfy both
at once - {opt opportunities()} cannot be combined with any of those seven options in the same
{cmd:nwdynam} call, a real, disclosed v1 limitation.

	{cmd:. nwdynam mynet, inertia opportunities(evvar actvar)}

{pstd}
{opt tie(netname)} ("cross-network effects, v1 scope") reads whether a tie exists in a SEPARATE,
already-declared network - goldfish's own {cmd:tie(network, ...)} effect, {it:s(i,j,t,x) = I(x_ij>0)},
identical in shape to {opt inertia} but reading a fixed, exogenous matrix instead of the
dependent network's own event history. {it:netname} must be an ORDINARY (non-{opt eventtime()})
network with exactly the same number of actors as the network being fit, in the same row/index
order (row/index correspondence, not label matching, the same convention {opt same()} and
{opt diff()} already use). Valid under {opt submodel(choice)} and {opt submodel(choice_coordination)}
(extended to the latter "batch 16" - the coordination engine's own full-matrix requirement makes
{opt tie()} the simplest possible addition there, since the exogenous matrix is used directly with
no further computation), matching {cmd:goldfish}'s own effect table exactly; rejected under
{opt submodel(rate)}. This v1 only supports a STATIC exogenous network - {it:netname} cannot itself
be an {opt eventtime()}-declared (dynamically evolving) network; {cmd:goldfish}'s own fuller
generality, where the SECOND network can itself change over time, remains a real, disclosed
follow-on. {opt weighted}, {opt window()}, and {opt ignoreRep} are likewise not yet supported for
{opt tie()}.

	{cmd:. nwset, mat(staticmat) name(covnet) directed}
	{cmd:. nwdynam mynet, tie(covnet)}
	{cmd:. nwdynam mynet, inertia tie(covnet)}
	{cmd:. nwdynam treaties, submodel(choice_coordination) tie(covnet)}

{pstd}
{bf:Effect selection}: each sub-model has a fixed roster of effects, documented below. By default
{cmd:nwdynam} fits the structural effects of the chosen sub-model together - {opt inertia},
{opt recip}, {opt indeg} for {bf:choice}; {opt indeg}, {opt outdeg} for {bf:rate}. Passing one or
more effect options restricts the fit to exactly that subset instead, matching {help nwrem}'s own
per-effect-flag convention. An effect option that does not apply to the chosen {opt submodel()}
is rejected with a clear error rather than silently ignored.

{pstd}
{bf:submodel(choice)} structural effects - given the realized sender, a conditional logit over
every other actor as the candidate receiver:

{p2colset 9 20 22 2}{...}
{p2col:{bf:inertia}}whether the sender has ever sent to this candidate before (binary){p_end}
{p2col:{bf:recip}}whether this candidate has ever sent to the sender before (binary){p_end}
{p2col:{bf:indeg}}the candidate's own in-degree - count of distinct actors who have ever sent to
them before{p_end}
{p2col:{bf:outdeg}}the candidate's own out-degree - count of distinct actors they have ever sent
to{p_end}
{p2colreset}{...}

{pstd}
{bf:submodel(choice)} two- and three-path closure effects - each counts paths through the
DEPENDENT network itself linking the sender, the candidate, and a third actor ({cmd:goldfish}'s
own default when no other network is named; using an exogenous network instead, or the two-network
"mixed" variants {cmd:goldfish} also offers, is not yet supported by this command):

{p2colset 9 20 22 2}{...}
{p2col:{bf:trans}}two-paths sender -> third actor -> candidate{p_end}
{p2col:{bf:cycle}}two-paths candidate -> third actor -> sender{p_end}
{p2col:{bf:commonsender}}two-paths from a common third actor to both sender and candidate{p_end}
{p2col:{bf:commonreceiver}}two-paths from both sender and candidate to a common third actor{p_end}
{p2col:{bf:four}}three-paths sender -> k <- l -> candidate, for two DISTINCT third actors k, l{p_end}
{p2col:{bf:nodetrans}}the candidate's own embeddedness in transitive structures (a property of the
candidate alone, not a sender/candidate comparison - available under both sub-models, like
{opt indeg} and {opt outdeg}){p_end}
{p2colreset}{...}

{pstd}
{opt inertia}, {opt recip}, {opt same()}, {opt diff()}, {opt sim()}, {opt trans}, {opt cycle},
{opt commonsender}, and {opt commonreceiver} are genuinely choice-only - this is a structural fact
about the two sub-models, not an arbitrary restriction: each is a DYADIC statistic comparing the
realized sender against a specific candidate receiver (e.g. {opt recip} asks whether THIS
candidate has a recent tie back to THIS sender; {opt trans}, {opt cycle}, {opt commonsender}, and
{opt commonreceiver} each ask about a two-path linking sender and candidate specifically), but
{opt submodel(rate)} has no candidate-receiver role at all - it is a single-actor hazard over
which actor acts next, so a dyadic comparison has no second actor to compare against. {opt indeg},
{opt outdeg}, and {opt nodetrans} are the exception because they are NOT dyadic - each is a
property of a single actor (their own in-degree, out-degree, or embeddedness), equally
well-defined whether that actor is playing the rate sub-model's own candidate-sender role or the
choice sub-model's own candidate-receiver role, so the SAME option name is reused deliberately for
all three (matching {cmd:goldfish}'s own convention, where the effect's own "type" - ego or alter -
is inferred from context rather than given a separate name per sub-model). {opt four} is
choice-only for a different reason - it needs two DISTINCT third actors (k and l) to close a
genuine three-path, a shape that only makes sense relative to a specific sender/candidate pair, not
a single actor's own standing.

{pstd}
{bf:submodel(choice)} attribute effects - each reads a per-actor covariate from its own
{opt same()}, {opt diff()}, {opt sim()}, or {opt alter()} option (independent variables, not
forced to share one, exactly like {help nwrem}'s own {opt covsnd()}, {opt covrec()},
{opt covint()}):

{p2colset 9 20 22 2}{...}
{p2col:{bf:same}}whether sender and candidate have the SAME covariate value{p_end}
{p2col:{bf:diff}}absolute difference between sender's and candidate's own values{p_end}
{p2col:{bf:sim}}negative absolute difference - mathematically exactly {cmd:-diff} on the same
variable, so combining {opt diff()} and {opt sim()} on the SAME variable is not identified{p_end}
{p2col:{bf:alter}}the candidate's own value alone, no comparison to the sender{p_end}
{p2col:{bf:egoalterint}}the sender's own covariate 1 value TIMES the candidate's own covariate 2
value - an interaction, not a comparison; needs exactly two variables{p_end}
{p2colreset}{...}

{pstd}
{bf:submodel(rate)} effects - a conditional logit over every actor (all {it:n}, not {it:n}-1)
as the candidate next sender:

{p2colset 9 20 22 2}{...}
{p2col:{bf:indeg}}the candidate's own in-degree - "ego" type, their own standing{p_end}
{p2col:{bf:outdeg}}the candidate's own out-degree - "ego" type{p_end}
{p2col:{bf:nodetrans}}the candidate's own embeddedness in transitive structures - "ego" type{p_end}
{p2col:{bf:ego}}the candidate's own covariate value alone, no comparison{p_end}
{p2colreset}{...}

{pstd}
{opt tertius(varname)} is available under BOTH sub-models (like {opt indeg}, {opt outdeg}, and
{opt nodetrans} - a property of a single actor, not a sender/candidate comparison): the MEAN
covariate value of the candidate's own in-neighbors on the DEPENDENT network itself (everyone who
has ever contacted them) - {cmd:goldfish}'s own "alter type" (choice) / "ego type" (rate)
{cmd:tertius()} effect, default aggregation (mean) only. An actor with no in-neighbors yet is
imputed as 0 - checked directly against {cmd:goldfish}'s own actual behavior (its own
documentation describes a different imputation rule, "the average of the aggregate values of
nodes with in-neighbors," but that is NOT what {cmd:goldfish} 1.6.12 itself does at estimation
time; 0 is what was verified).

{pstd}
{opt ego()} is {opt alter()}'s own rate-sub-model counterpart under {cmd:goldfish}'s own different
name for it - both are "this candidate's own static covariate value, no comparison to anyone,"
just named for whichever sub-model's own candidate role it modifies (the potential next sender for
{opt ego()}; the potential receiver for {opt alter()}). There is no separate rate-side {opt alter()}
to add - {opt ego()} already is it.

{pstd}
{bf:Windowed effects}: by default {opt inertia}, {opt recip} (choice sub-model) and {opt indeg},
{opt outdeg} (rate sub-model) look back over the entire prior event history with no time limit.
{opt inertiawindow(#)}, {opt recipwindow(#)}, {opt indegwindow(#)}, {opt outdegwindow(#)} each
restrict their own effect independently to a real-time recency cutoff instead - a tie counts as
present only if its most recent occurrence happened within {it:#} time units of the current event
(a hard cutoff, not a decaying weight; a tie can expire once too much time has passed, even though
it was present a moment earlier). {it:#} is in the same time units as the network's own
{opt eventtime()} values. Each window option on its own both selects its own effect and sets its
window - no separate {opt inertia}, {opt recip}, {opt indeg}, or {opt outdeg} flag is needed (the
same convention {help nwergm}'s own {opt gwesp(real)} uses). {opt inertiawindow()} and
{opt recipwindow()} apply under {opt submodel(choice)} only; {opt indegwindow()} and
{opt outdegwindow()} apply under {opt submodel(rate)} only ({opt indeg} means something different
in each sub-model - see {bf:Effect selection} above - so its own window option is likewise
sub-model-specific). All windows are fully independent of each other - a model can use different
values for each.

	{cmd:. nwdynam mynet, inertiawindow(604800)}
	{cmd:. nwdynam mynet, inertiawindow(604800) recipwindow(86400)}
	{cmd:. nwdynam mynet, submodel(rate) indegwindow(604800) outdegwindow(86400)}

{pstd}
{bf:Weighted effects}: by default {opt inertia}, {opt recip}, {opt indeg}, and {opt outdeg} each
count tie PRESENCE (has this ever happened, yes or no). {opt weightedinertia}, {opt weightedrecip},
{opt weightedindeg}, {opt weightedoutdeg} switch that same effect to count the cumulative NUMBER of
prior events instead (repeated events between the same dyad, or by the same actor, all count) -
matching {cmd:goldfish}'s own {opt weighted(TRUE)} argument. Self-activating, the same convention
as the window options above - {opt weightedinertia} alone both selects {opt inertia} and switches
it to counting. {opt weightedindeg} and {opt weightedoutdeg} apply under BOTH sub-models (unlike
{opt indegwindow()} and {opt outdegwindow()}, which remain {opt submodel(rate)}-only - a real, disclosed
gap in choice-side windowing, not in choice-side weighting). A weighted effect and that SAME
effect's own window cannot be combined (not yet verified together against {cmd:goldfish}) - use one
or the other, never both, for the same effect.

	{cmd:. nwdynam mynet, weightedinertia}
	{cmd:. nwdynam mynet, weightedinertia weightedrecip}
	{cmd:. nwdynam mynet, submodel(rate) weightedindeg weightedoutdeg}

{pstd}
{opt same()}, {opt diff()}, {opt sim()}, {opt ego()}, {opt alter()}, and {opt egoalterint()} have
no window option at all, matching {cmd:goldfish}'s own effect signatures exactly (checked directly
against {cmd:goldfish}'s own documentation, not omitted by oversight) - windowing is a real-time
recency FILTER ON TIES (has this dyad had a recent event?), but these six effects read a STATIC
per-actor covariate value that never changes over the course of the fit and has no "most recent
occurrence" to filter on in the first place. {opt inertia}, {opt recip}, {opt indeg}, and
{opt outdeg} are windowable because each is genuinely tie-based (their own value depends on the
event history), which these six are not. {opt tertius()} DOES read the event history (it is a
mean over the candidate's own in-neighbors), so it is windowable in {cmd:goldfish}'s own table -
not yet wired here, a real, disclosed scope limit matching choice's own already-unwindowed
{opt indeg}.

{pstd}
Covariate options ({opt same()}, {opt diff()}, {opt sim()}, {opt ego()}, {opt alter()},
{opt tertius()}, {opt egoalterint()}) require the current Stata dataset, at the time {cmd:nwdynam}
is called, to have exactly one row per actor in {it:netname}'s own actor order - not the
event-level dataset {it:netname} itself was declared from. Use {help nwload}'s {opt xvars} option
first:

	{cmd:. nwload mynet, xvars}
	{cmd:. gen floor = ...}
	{cmd:. nwdynam mynet, same(floor)}

{pstd}
Every effect is evaluated fresh at each event from the event history strictly prior to that
event (no lookahead); the covariate effects are static (the covariate itself does not change
over the fit).

{pstd}
{bf:Verified} against the real reference R implementation ({cmd:goldfish}, CRAN,
{cmd:stocnet/goldfish}) fit on its own bundled {cmd:Social_Evolution} dataset (84 actors, 439
real phone-call events) - both implementations converge to the same log-likelihood surface for
every sub-model, structural subset, attribute effect, and windowed configuration tested,
recovering matching coefficients to within 1e-2. See {cmd:dev/dynam_unit1_crosscheck.R} for the
R side and {cmd:dev/dynam_unit1_choice_crosscheck.do} through {cmd:dev/dynam_unit11_weighted_crosscheck.do}
for the direct head-to-head comparisons in this package's own source. The two-mode support
described above is separately verified on a real hand-built toy affiliation network (6 "people," 4
"orgs," 60 events) - see {cmd:dev/dynam_unit12_twomode_crosscheck.R} and {cmd:.do}. {opt opportunities()}
is separately verified on a real hand-built toy directed network (8 actors, 30 events, one random
per-event exclusion) - see {cmd:dev/dynam_unit13_opportunities_crosscheck.R}, the matching direct
Mata-call {cmd:.do}, and {cmd:dev/dynam_unit13b_opportunities_ado_crosscheck.do} for the same
numbers reproduced through this {cmd:.ado} command itself. {opt submodel(choice_coordination)} is
separately verified on real hand-built toy undirected networks (a 4-actor/4-event {opt inertia}-only
example and a 6-actor/12-event example with {opt inertia}, {opt indeg}, {opt same()}, {opt diff()},
{opt sim()}, and {opt alter()} each checked) against real {cmd:goldfish} - see
{cmd:dev/dynam_unit14_coordination_crosscheck.R}, the matching direct Mata-call {cmd:.do}, and
{cmd:dev/dynam_unit14b_coordination_ado_crosscheck.do} for the same numbers reproduced through this
{cmd:.ado} command itself. {opt nodetrans} and {opt trans} under {opt submodel(choice_coordination)}
are separately verified on the same 6-actor/12-event toy network, alone and combined with
{opt inertia} - see {cmd:dev/dynam_unit15_coordination_closure_crosscheck.R}, the matching direct
Mata-call {cmd:.do}, and {cmd:dev/dynam_unit15b_coordination_closure_ado_crosscheck.do}.
{opt tertius()} and {opt four} under {opt submodel(choice_coordination)} are likewise verified on
the same toy network, alone and combined with {opt inertia} - see
{cmd:dev/dynam_unit16_coordination_tertius_four_crosscheck.R}, the matching direct Mata-call
{cmd:.do}, and {cmd:dev/dynam_unit16b_coordination_tertius_four_ado_crosscheck.do}.
{opt egoalterint()} under {opt submodel(choice_coordination)} is likewise verified on the same toy
network, alone and combined with {opt inertia} - see
{cmd:dev/dynam_unit17_coordination_egoalterint_crosscheck.R}, the matching direct Mata-call
{cmd:.do}, and {cmd:dev/dynam_unit17b_coordination_egoalterint_ado_crosscheck.do}. {opt tie()} is
separately verified on a real hand-built toy directed network with a genuinely separate, static
exogenous network, alone and combined with {opt inertia} - see
{cmd:dev/dynam_unit18_tie_crosscheck.R}, the matching direct Mata-call {cmd:.do}, and
{cmd:dev/dynam_unit18b_tie_ado_crosscheck.do}. {opt tie()} under {opt submodel(choice_coordination)}
is likewise verified, alone and combined with {opt inertia} - see
{cmd:dev/dynam_unit19_coordination_tie_crosscheck.R}, the matching direct Mata-call {cmd:.do}, and
{cmd:dev/dynam_unit19b_coordination_tie_ado_crosscheck.do}. {opt intercept} is separately verified
on a real hand-built toy directed network with REAL (unevenly-spaced) timestamps, matching
{cmd:goldfish} exactly on two independent effect combinations - see
{cmd:dev/dynam_unit20_rateintercept_crosscheck.R}, the matching direct Mata-call {cmd:.do}, and
{cmd:dev/dynam_unit20b_rateintercept_ado_crosscheck.do}. {opt intercept} combined with two-mode
networks and with {opt weightedindeg} and {opt weightedoutdeg} is likewise verified, each independently
on its own real toy network with real timestamps - see
{cmd:dev/dynam_unit21_rateintercept_twomode_crosscheck.R} and {cmd:dynam_unit21c_..._weighted_...R}, the
matching direct Mata-call {cmd:dev/dynam_unit21_rateintercept_extras_crosscheck.do}, and
{cmd:dev/dynam_unit21b_rateintercept_extras_ado_crosscheck.do}.

{pstd}
Selecting exactly the three original structural effects, with neither window active, reuses a
native-eligible (C) engine - any other active set dispatches to a Mata-only engine instead
(no native backend for a genuine subset or a windowed fit yet, a disclosed follow-on). Both
engines were confirmed to agree with each other on the full structural-effect set.

{pstd}
The native (C) backend, when available for the running platform, accelerates the
log-likelihood/gradient evaluation Mata's own optimizer calls repeatedly - the optimization
itself always runs in Mata. Falls back to the pure-Mata engine transparently on any platform
without a compiled plugin.


{title:Stored results}

	Scalars
	  {bf:e(N)}		number of events
	  {bf:e(nodes)}		number of actors
	  {bf:e(ll)}		log likelihood at the MLE

	Macros
	  {bf:e(cmd)}		{bf:nwdynam}
	  {bf:e(title)}		sub-model-specific title string
	  {bf:e(depvar)}	name of the event network fit
	  {bf:e(submodel)}	{bf:choice} or {bf:rate}
	  {bf:e(effects)}	space-separated list of the effects actually fit, in their fixed order

	Matrices
	  {bf:e(b)}		coefficient vector (columns named per {bf:e(effects)})
	  {bf:e(V)}		variance-covariance matrix (observed information)


{title:Examples}

{pstd}Fit a DyNAM choice sub-model on a small event log:{p_end}

	{cmd:. clear}
	{cmd:. input sender receiver t}
	{cmd:. 1 2 1}
	{cmd:. 1 3 2}
	{cmd:. 2 1 3}
	{cmd:. 1 2 4}
	{cmd:. 3 2 5}
	{cmd:. 2 3 6}
	{cmd:. 1 3 7}
	{cmd:. 3 1 8}
	{cmd:. 2 1 9}
	{cmd:. 1 3 10}
	{cmd:. end}
	{cmd:. nwset sender receiver, eventtime(t) name(chat)}
	{cmd:. nwdynam chat}

{pstd}
(a handful of events on very few actors, as above, has too little information to pin down the
coefficients precisely - wide confidence intervals in this toy example are expected){p_end}

{pstd}Fit the rate sub-model on the same event log:{p_end}

	{cmd:. nwdynam chat, submodel(rate)}

{pstd}Fit only a subset of the choice sub-model's own effects:{p_end}

	{cmd:. nwdynam chat, inertia}

{pstd}Add a homophily effect alongside the structural effects:{p_end}

	{cmd:. nwload chat, xvars}
	{cmd:. gen dept = _n <= 5}
	{cmd:. nwdynam chat, inertia recip indeg same(dept)}

{pstd}Does a per-actor covariate on its own predict how often an actor initiates the next event:{p_end}

	{cmd:. nwdynam chat, submodel(rate) ego(dept)}

{pstd}Does a candidate receiver's own out-degree predict whether they get chosen (the choice
sub-model's own {opt outdeg}, distinct from the rate sub-model's own {opt outdeg} above):{p_end}

	{cmd:. nwdynam chat, inertia outdeg}

{pstd}Restrict inertia to a real-time recency window ({opt inertiawindow()} alone selects {opt inertia}):{p_end}

	{cmd:. nwdynam chat, inertiawindow(3)}

{pstd}Give inertia and reciprocity genuinely different recency windows in the same model:{p_end}

	{cmd:. nwdynam chat, inertiawindow(3) recipwindow(5)}

{pstd}Restrict the rate sub-model's in-degree effect to a real-time recency window
({opt indegwindow()} alone selects {opt indeg}):{p_end}

	{cmd:. nwdynam chat, submodel(rate) indegwindow(3)}

{pstd}Give in-degree and out-degree genuinely different recency windows in the rate sub-model:{p_end}

	{cmd:. nwdynam chat, submodel(rate) indegwindow(3) outdegwindow(5)}

{pstd}Does closing a two-path (transitivity) predict the next tie, alongside inertia:{p_end}

	{cmd:. nwdynam chat, inertia trans}

{pstd}Is a candidate more likely to be chosen the more embedded they are in transitive structures
(available under either sub-model):{p_end}

	{cmd:. nwdynam chat, nodetrans}
	{cmd:. nwdynam chat, submodel(rate) nodetrans}

{pstd}Does a candidate's own well-connected friends (high average department) predict being
chosen:{p_end}

	{cmd:. nwdynam chat, tertius(dept)}

{pstd}Does the sender's own department moderate how much the candidate's own department matters:{p_end}

	{cmd:. nwdynam chat, alter(dept) egoalterint(dept dept)}

{pstd}Restrict the candidate risk set to only those actors actually available at each event (a
dataset with one row per event/available-actor pair, event sequence numbers 1-10, actor IDs 1-3
matching {cmd:chat}'s own three actors):{p_end}

	{cmd:. clear}
	{cmd:. input evvar actvar}
	{cmd:. 1 1}
	{cmd:. 1 2}
	{cmd:. 2 2}
	{cmd:. 2 3}
	{cmd:. (one row per event/available-actor pair, continuing through event 10)}
	{cmd:. end}
	{cmd:. nwdynam chat, inertia opportunities(evvar actvar)}

{pstd}Fit the choice_coordination sub-model on an UNDIRECTED event log (a coordination/mutual-tie
network - {opt submodel(choice_coordination)} requires {opt nwset ..., undirected}):{p_end}

	{cmd:. nwset sender receiver, undirected eventtime(t) name(treaties)}
	{cmd:. nwdynam treaties, submodel(choice_coordination)}
	{cmd:. nwload treaties, xvars}
	{cmd:. gen dept = ...}
	{cmd:. nwdynam treaties, submodel(choice_coordination) inertia same(dept)}

{pstd}Does whether two actors already have a formal agreement in a SEPARATE, static network
predict a tie in {cmd:chat}, alongside {opt inertia} ({it:covnet} declared from a Stata matrix,
same actor count and order as {cmd:chat}):{p_end}

	{cmd:. nwset, mat((0,1,1\1,0,0\1,0,0)) name(covnet) directed labs(A,B,C)}
	{cmd:. nwdynam chat, inertia tie(covnet)}

{pstd}Fit the genuinely continuous-time WITH-INTERCEPT rate sub-model, sensitive to the real
elapsed time between events, not just their order (combining {opt intercept} with
{opt weightedoutdeg} or a two-mode network is also verified and supported;
{opt indegwindow()} and {opt outdegwindow()} are not, see {bf:Description} above):{p_end}

	{cmd:. nwdynam chat, submodel(rate) intercept indeg}
	{cmd:. nwdynam chat, submodel(rate) intercept weightedoutdeg}


{title:Also see}

{p 4 14 2}Help: {help nwset}, {help nwattime}, {help nwrem}, {help nwergm}, {help nwsaom}{p_end}
