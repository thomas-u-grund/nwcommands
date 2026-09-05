---
title: "nwdynam"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Dynamic Network Actor Model - choice, rate, and choice_coordination sub-models (MLE)"
---

# `nwdynam`

Dynamic Network Actor Model - choice, rate, and choice_coordination sub-models (MLE)

## Syntax

```stata
nwdynam
[netname]
,
[submodel(string)
seed(#)
inertia
recip
indeg
outdeg
trans
cycle
commonsender
commonreceiver
four
nodetrans
same(varname)
diff(varname)
sim(varname)
ego(varname)
alter(varname)
tertius(varname)
egoalterint(varlist)
inertiawindow(#)
recipwindow(#)
indegwindow(#)
outdegwindow(#)
weightedinertia
weightedrecip
weightedindeg
weightedoutdeg
opportunities(varlist)
tie(netname)
intercept]
```

**General**

| | |
|---|---|
| `submodel(string)` | which DyNAM sub-model to fit - **choice** (the default), **rate**, or **choice_coordination**; see **Description** below |
| `seed(#)` | random-number seed before estimation |

**Effects (no decay - the entire prior event history counts equally)**

| | |
|---|---|
| `inertia` | choice sub-model only |
| `recip` | choice sub-model only |
| `indeg` | both sub-models (different meaning in each - see **Description**) |
| `outdeg` | both sub-models (different meaning in each - see **Description**) |
| `trans` | choice sub-model only - two-path closure (transitivity) |
| `cycle` | choice sub-model only - two-path closure (cyclical) |
| `commonsender` | choice sub-model only - two-path closure (common sender) |
| `commonreceiver` | choice sub-model only - two-path closure (common receiver) |
| `four` | choice sub-model only - three-path closure |
| `nodetrans` | both sub-models - embeddedness in transitive structures |
| `same(varname)` | choice sub-model only - homophily on a per-actor covariate |
| `diff(varname)` | choice sub-model only - heterophily (absolute difference) on a per-actor covariate |
| `sim(varname)` | choice sub-model only - homophily by similarity (negative absolute difference) on a per-actor covariate |
| `ego(varname)` | rate sub-model only - the candidate's own covariate value, no comparison |
| `alter(varname)` | choice sub-model only - the candidate receiver's own covariate value, no comparison |
| `tertius(varname)` | both sub-models - mean covariate value of the candidate's own in-neighbors |
| `egoalterint(varlist)` | choice sub-model only - interaction of the sender's and candidate's own covariate values (exactly two variables) |

**Windowed effects (real-time recency cutoff - self-activating, see Description)**

| | |
|---|---|
| `inertiawindow(#)` | choice sub-model only - recency cutoff on `inertia`; self-activates `inertia` |
| `recipwindow(#)` | choice sub-model only - recency cutoff on `recip`; self-activates `recip` |
| `indegwindow(#)` | rate sub-model only - recency cutoff on `indeg`; self-activates `indeg` |
| `outdegwindow(#)` | rate sub-model only - recency cutoff on `outdeg`; self-activates `outdeg` |

**Weighted effects (count instead of presence - self-activating, see Description)**

| | |
|---|---|
| `weightedinertia` | choice sub-model only - self-activates `inertia` |
| `weightedrecip` | choice sub-model only - self-activates `recip` |
| `weightedindeg` | both sub-models - self-activates `indeg` |
| `weightedoutdeg` | both sub-models - self-activates `outdeg` |

**Opportunity restriction (choice sub-model only)**

| | |
|---|---|
| `opportunities(varlist)` | per-event candidate risk-set restriction; see **Description** below |

**Cross-network effects**

| | |
|---|---|
| `tie(netname)` | presence in a SEPARATE, static exogenous network; see **Description** below |

**Intercept (rate sub-model only)**

| | |
|---|---|
| `intercept` | genuinely continuous-time competing-risks hazard; see **Description** below |

## Description

`nwdynam` fits a Dynamic Network Actor Model (Stadtfeld & Block 2017, "Interactions, Actors, and Time: Dynamic Network Actor Models for Relational Events," *Sociological Science* 4, 318-352) to a timestamped sequence of directed dyadic events - the same kind of data [nwrem](nwrem) works on, but factored differently. DyNAM splits the process into two conditionally independent sub-models given the event history so far: a **rate** sub-model (which actor acts next) and a **choice** sub-model (given that actor, which other actor they choose - a conditional logit over the receiver set).

By default, both sub-models fit here use the ordinal partial likelihood (Cox-style, using only the ORDER events happened in, never real elapsed time) - the same convention [nwrem](nwrem) already uses throughout this package. The NO-intercept rate case (the `submodel(rate)` default) turns out to be exactly this same ordinal partial likelihood, just over a different risk set than the choice sub-model (verified against the reference R implementation on both a toy example and real data). `intercept` (rate sub-model only) requests the genuinely DIFFERENT, continuous-time competing- risks hazard variant instead - see its own paragraph below.

`nwdynam` requires *netname* to already be declared as an event-type, directed temporal network via [nwset](nwset)'s `eventtime(varname)` option:

```stata
. nwset sender receiver, eventtime(t) name(mynet)
. nwdynam mynet
. nwdynam mynet, submodel(rate)
```
`intercept` ("expansion batch 17") requests goldfish's own genuinely continuous-time competing-risks hazard variant of the rate sub-model - each actor is modeled as an independent Poisson clock with hazard *exp(beta'X_i(t))*, and the fitted model becomes sensitive to the ACTUAL SCALE of elapsed real time between events (matching *netname*'s own `eventtime()` values), not just their order - `goldfish`'s own `teaching1.Rmd` vignette: "an intercept of -14 means a waiting time of 334 hours." Matches `goldfish`'s own convention exactly (a literal `1` as the first formula term requests an intercept - `dep ~ 1 + indeg(net)`), confirmed directly against `goldfish`'s own `parseIntercept()` source. Every observed event after the FIRST contributes *beta'X_s_k* minus *(t_k - t_k-1)* times the summed hazard of every actor; the first observed event contributes only its own *beta'X_s_1* term (checked directly against real `goldfish` - there is no assumed risk period before the first observed event). `submodel(rate)` only, matching `goldfish`'s own architecture (only the rate sub-model has ever had an intercept concept - the choice sub-model's own conditional logit has none, by construction). `weightedindeg`, `weightedoutdeg`, and two-mode (bipartite) networks ("expansion batch 18") are verified together with `intercept` - the same statistic swaps the NO-intercept engine already uses turned out to compose correctly with the hazard-integral aggregation exactly as written, confirmed by exact agreement with real `goldfish`. `indegwindow()` and `outdegwindow()` combined with `intercept` remain REJECTED - a real, disclosed architectural gap, not merely unverified: `goldfish`'s own `window()` mechanism inserts synthetic "dissolve" events into the timeline at exactly *event_time + window* for every windowed tie, forcing its piecewise-constant hazard machinery to recompute right at each expiry; this command only recomputes statistics at real dependent events, so a windowed contact would silently over-count for the rest of the current inter-event interval once `intercept`'s own hazard-INTEGRAL aggregation is in play (the NO-intercept engine's ordinal partial likelihood never integrates over real time at all, which is why `indegwindow()` and `outdegwindow()` already work correctly without `intercept`).

```stata
. nwdynam mynet, submodel(rate) intercept indeg
. nwdynam mynet, submodel(rate) intercept outdeg ego(dept)
. nwdynam mynet, submodel(rate) intercept weightedoutdeg
```
**submodel(choice_coordination)** is goldfish's own THIRD sub-model (Stadtfeld, Hollway & Block 2017, "Dynamic Network Actor Models: Investigating Coordination Ties through Time," *Sociological Methodology* 47(1), 1-40) - a genuinely different likelihood from `submodel(choice)`, for UNDIRECTED ("coordination") tie-formation events where neither actor plays a privileged sender/receiver role (e.g. treaty formation, co-authorship). Requires an UNDIRECTED, one-mode network - the opposite of `submodel(choice)` and `submodel(rate)`'s own directed-only requirement:

```stata
. nwset sender receiver, undirected eventtime(t) name(mynet)
. nwdynam mynet, submodel(choice_coordination)
```
Mechanically, for each event, `nwdynam` computes an ordinary choice-submodel probability in BOTH directions for every candidate pair *a*,*b* - *p*(*a* would choose *b*) and *p*(*b* would choose *a*) - multiplies them, and normalizes over every possible unordered pair to get the probability that *a* and *b* form a tie together (a "multinomial-multinomial" joint model, not a simple conditional logit). The per-effect STATISTICS themselves are identical to `submodel(choice)`'s own `inertia`, `indeg`, `same()`, `diff()`, `sim()`, `alter()`, `nodetrans`, `trans`, `tertius()`, `four`, `egoalterint()`, and `tie()` (confirmed directly against `goldfish`'s own source: every one of its own `choice_coordination`-specific effect functions is a thin wrapper calling the identical `choice`-side function) - only the AGGREGATION differs. Effect selection uses the SAME flag names as `submodel(choice)` - giving nothing fits `inertia` and `indeg` together by default. `recip`, `outdeg`, `cycle`, `commonsender`, `commonreceiver`, and `ego()` are all rejected under `submodel(choice_coordination)` - `recip` and `outdeg` because an undirected tie has no direction to reciprocate and in-degree/out-degree coincide; `cycle`, `commonsender`, and `commonreceiver` because `goldfish` itself does not register a `choice_coordination` version of them at all; `ego()` because it is `submodel(rate)`-only, matching `submodel(choice)`'s own scope exactly. `tertiusDiff()` remains real-goldfish-eligible but not yet wired - a real, disclosed gap rather than a blanket restriction. `opportunities()`, every window option, `weightedinertia`, `weightedrecip`, `weightedindeg`, `weightedoutdeg`, and two-mode networks are likewise not yet supported for `submodel(choice_coordination)`.

```stata
. nwdynam mynet, submodel(choice_coordination) inertia
. nwload mynet, xvars
. gen dept = ...
. nwdynam mynet, submodel(choice_coordination) inertia same(dept)
. nwdynam mynet, submodel(choice_coordination) nodetrans trans
. nwdynam mynet, submodel(choice_coordination) tertius(dept) four
. gen dept2 = ...
. nwdynam mynet, submodel(choice_coordination) egoalterint(dept dept2)
```
**Two-mode (bipartite) networks** are supported for a real, but DELIBERATELY NARROW, set of effects: `inertia` (choice), `indeg` (choice), and `outdeg` (rate) - each verified to match `goldfish` exactly on a real toy affiliation network (see **Remarks** below). Declare the network via [nwset](nwset)'s `twomode` option combined with `eventtime()`:

```stata
. nwset sender receiver, twomode eventtime(t) name(mynet)
. nwdynam mynet
```
`nwdynam` requires every event's sender to be mode 1 and receiver to be mode 2 (never the reverse), matching `goldfish`'s own strictly one-directional two-mode DyNAM architecture - checked directly against the real event data, not assumed. `recip`, `outdeg` under `submodel(choice)`, `commonreceiver`, and `indeg` under `submodel(rate)` are rejected outright for two-mode networks - `goldfish` itself hard-rejects each of these at estimation time (a candidate/sender role that structurally cannot exist when mode 2 never sends and mode 1 never receives), not merely a scope choice on this command's own part. Every attribute effect (`same()`, `diff()`, `sim()`, `alter()`, `ego()`, `egoalterint()`, `tertius()`) is ALSO rejected for two-mode - a real limitation found DURING verification, not assumed safe: direct comparison against `goldfish`'s own internal statistics showed even the simplest attribute effects computing something different from the obvious combined-covariate approach, traced to a `goldfish`-internal representation detail (its own "exclude the self-tie" convention applied by raw row/column index rather than actual actor identity) that could not be confidently reverse-engineered in the time available - disclosed as a real gap rather than shipped with an unverified formula. `trans`, `cycle`, `commonsender`, `four`, `nodetrans`, and every windowed or weighted effect are likewise not yet verified for two-mode and are rejected outright.

`opportunities(evvar actvar)` restricts the candidate risk set PER EVENT to a caller-supplied list of available actors - `goldfish`'s own `opportunitiesList` `estimationInit` argument (its own documentation: "ONLY for choice models"), rejected outright under `submodel(rate)`. Takes exactly two numeric variables from the CURRENT Stata dataset, at the time `nwdynam` is called, in a genuinely different SHAPE from the covariate options above: ONE ROW PER (event, available-actor) PAIR, not one row per actor. *evvar* is the event's own sequence number (1 through the number of events in *netname*, matching its own chronological event order); *actvar* is an actor ID (1 through the number of actors, matching *netname*'s own actor order) that was available as a candidate receiver for that event. An actor not listed for a given event is excluded from the risk set for that event only; an event with no rows at all in *evvar* and *actvar* has no candidates beyond the sender's own unconditional self-exclusion (still applied regardless of whether the sender itself is listed as available - checked directly against `goldfish`'s own behavior). Because `opportunities()` needs the event/available-actor shape and `same()`, `diff()`, `sim()`, `alter()`, `ego()`, `tertius()`, and `egoalterint()` each need the one-row-per-actor shape, the current dataset cannot satisfy both at once - `opportunities()` cannot be combined with any of those seven options in the same `nwdynam` call, a real, disclosed v1 limitation.

```stata
. nwdynam mynet, inertia opportunities(evvar actvar)
```
`tie(netname)` ("cross-network effects, v1 scope") reads whether a tie exists in a SEPARATE, already-declared network - goldfish's own `tie(network, ...)` effect, *s(i,j,t,x) = I(x_ij>0)*, identical in shape to `inertia` but reading a fixed, exogenous matrix instead of the dependent network's own event history. *netname* must be an ORDINARY (non-`eventtime()`) network with exactly the same number of actors as the network being fit, in the same row/index order (row/index correspondence, not label matching, the same convention `same()` and `diff()` already use). Valid under `submodel(choice)` and `submodel(choice_coordination)` (extended to the latter "batch 16" - the coordination engine's own full-matrix requirement makes `tie()` the simplest possible addition there, since the exogenous matrix is used directly with no further computation), matching `goldfish`'s own effect table exactly; rejected under `submodel(rate)`. This v1 only supports a STATIC exogenous network - *netname* cannot itself be an `eventtime()`-declared (dynamically evolving) network; `goldfish`'s own fuller generality, where the SECOND network can itself change over time, remains a real, disclosed follow-on. `weighted`, `window()`, and `ignoreRep` are likewise not yet supported for `tie()`.

```stata
. nwset, mat(staticmat) name(covnet) directed
. nwdynam mynet, tie(covnet)
. nwdynam mynet, inertia tie(covnet)
. nwdynam treaties, submodel(choice_coordination) tie(covnet)
```
**Effect selection**: each sub-model has a fixed roster of effects, documented below. By default `nwdynam` fits the structural effects of the chosen sub-model together - `inertia`, `recip`, `indeg` for **choice**; `indeg`, `outdeg` for **rate**. Passing one or more effect options restricts the fit to exactly that subset instead, matching [nwrem](nwrem)'s own per-effect-flag convention. An effect option that does not apply to the chosen `submodel()` is rejected with a clear error rather than silently ignored.

**submodel(choice)** structural effects - given the realized sender, a conditional logit over every other actor as the candidate receiver:

- ****inertia**** --- whether the sender has ever sent to this candidate before (binary)
- ****recip**** --- whether this candidate has ever sent to the sender before (binary)
- ****indeg**** --- the candidate's own in-degree - count of distinct actors who have ever sent to them before
- ****outdeg**** --- the candidate's own out-degree - count of distinct actors they have ever sent to

**submodel(choice)** two- and three-path closure effects - each counts paths through the DEPENDENT network itself linking the sender, the candidate, and a third actor (`goldfish`'s own default when no other network is named; using an exogenous network instead, or the two-network "mixed" variants `goldfish` also offers, is not yet supported by this command):

- ****trans**** --- two-paths sender -> third actor -> candidate
- ****cycle**** --- two-paths candidate -> third actor -> sender
- ****commonsender**** --- two-paths from a common third actor to both sender and candidate
- ****commonreceiver**** --- two-paths from both sender and candidate to a common third actor
- ****four**** --- three-paths sender -> k <- l -> candidate, for two DISTINCT third actors k, l
- ****nodetrans**** --- the candidate's own embeddedness in transitive structures (a property of the candidate alone, not a sender/candidate comparison - available under both sub-models, like `indeg` and `outdeg`)

`inertia`, `recip`, `same()`, `diff()`, `sim()`, `trans`, `cycle`, `commonsender`, and `commonreceiver` are genuinely choice-only - this is a structural fact about the two sub-models, not an arbitrary restriction: each is a DYADIC statistic comparing the realized sender against a specific candidate receiver (e.g. `recip` asks whether THIS candidate has a recent tie back to THIS sender; `trans`, `cycle`, `commonsender`, and `commonreceiver` each ask about a two-path linking sender and candidate specifically), but `submodel(rate)` has no candidate-receiver role at all - it is a single-actor hazard over which actor acts next, so a dyadic comparison has no second actor to compare against. `indeg`, `outdeg`, and `nodetrans` are the exception because they are NOT dyadic - each is a property of a single actor (their own in-degree, out-degree, or embeddedness), equally well-defined whether that actor is playing the rate sub-model's own candidate-sender role or the choice sub-model's own candidate-receiver role, so the SAME option name is reused deliberately for all three (matching `goldfish`'s own convention, where the effect's own "type" - ego or alter - is inferred from context rather than given a separate name per sub-model). `four` is choice-only for a different reason - it needs two DISTINCT third actors (k and l) to close a genuine three-path, a shape that only makes sense relative to a specific sender/candidate pair, not a single actor's own standing.

**submodel(choice)** attribute effects - each reads a per-actor covariate from its own `same()`, `diff()`, `sim()`, or `alter()` option (independent variables, not forced to share one, exactly like [nwrem](nwrem)'s own `covsnd()`, `covrec()`, `covint()`):

- ****same**** --- whether sender and candidate have the SAME covariate value
- ****diff**** --- absolute difference between sender's and candidate's own values
- ****sim**** --- negative absolute difference - mathematically exactly `-diff` on the same variable, so combining `diff()` and `sim()` on the SAME variable is not identified
- ****alter**** --- the candidate's own value alone, no comparison to the sender
- ****egoalterint**** --- the sender's own covariate 1 value TIMES the candidate's own covariate 2 value - an interaction, not a comparison; needs exactly two variables

**submodel(rate)** effects - a conditional logit over every actor (all *n*, not *n*-1) as the candidate next sender:

- ****indeg**** --- the candidate's own in-degree - "ego" type, their own standing
- ****outdeg**** --- the candidate's own out-degree - "ego" type
- ****nodetrans**** --- the candidate's own embeddedness in transitive structures - "ego" type
- ****ego**** --- the candidate's own covariate value alone, no comparison

`tertius(varname)` is available under BOTH sub-models (like `indeg`, `outdeg`, and `nodetrans` - a property of a single actor, not a sender/candidate comparison): the MEAN covariate value of the candidate's own in-neighbors on the DEPENDENT network itself (everyone who has ever contacted them) - `goldfish`'s own "alter type" (choice) / "ego type" (rate) `tertius()` effect, default aggregation (mean) only. An actor with no in-neighbors yet is imputed as 0 - checked directly against `goldfish`'s own actual behavior (its own documentation describes a different imputation rule, "the average of the aggregate values of nodes with in-neighbors," but that is NOT what `goldfish` 1.6.12 itself does at estimation time; 0 is what was verified).

`ego()` is `alter()`'s own rate-sub-model counterpart under `goldfish`'s own different name for it - both are "this candidate's own static covariate value, no comparison to anyone," just named for whichever sub-model's own candidate role it modifies (the potential next sender for `ego()`; the potential receiver for `alter()`). There is no separate rate-side `alter()` to add - `ego()` already is it.

**Windowed effects**: by default `inertia`, `recip` (choice sub-model) and `indeg`, `outdeg` (rate sub-model) look back over the entire prior event history with no time limit. `inertiawindow(#)`, `recipwindow(#)`, `indegwindow(#)`, `outdegwindow(#)` each restrict their own effect independently to a real-time recency cutoff instead - a tie counts as present only if its most recent occurrence happened within *#* time units of the current event (a hard cutoff, not a decaying weight; a tie can expire once too much time has passed, even though it was present a moment earlier). *#* is in the same time units as the network's own `eventtime()` values. Each window option on its own both selects its own effect and sets its window - no separate `inertia`, `recip`, `indeg`, or `outdeg` flag is needed (the same convention [nwergm](nwergm)'s own `gwesp(real)` uses). `inertiawindow()` and `recipwindow()` apply under `submodel(choice)` only; `indegwindow()` and `outdegwindow()` apply under `submodel(rate)` only (`indeg` means something different in each sub-model - see **Effect selection** above - so its own window option is likewise sub-model-specific). All windows are fully independent of each other - a model can use different values for each.

```stata
. nwdynam mynet, inertiawindow(604800)
. nwdynam mynet, inertiawindow(604800) recipwindow(86400)
. nwdynam mynet, submodel(rate) indegwindow(604800) outdegwindow(86400)
```
**Weighted effects**: by default `inertia`, `recip`, `indeg`, and `outdeg` each count tie PRESENCE (has this ever happened, yes or no). `weightedinertia`, `weightedrecip`, `weightedindeg`, `weightedoutdeg` switch that same effect to count the cumulative NUMBER of prior events instead (repeated events between the same dyad, or by the same actor, all count) - matching `goldfish`'s own `weighted(TRUE)` argument. Self-activating, the same convention as the window options above - `weightedinertia` alone both selects `inertia` and switches it to counting. `weightedindeg` and `weightedoutdeg` apply under BOTH sub-models (unlike `indegwindow()` and `outdegwindow()`, which remain `submodel(rate)`-only - a real, disclosed gap in choice-side windowing, not in choice-side weighting). A weighted effect and that SAME effect's own window cannot be combined (not yet verified together against `goldfish`) - use one or the other, never both, for the same effect.

```stata
. nwdynam mynet, weightedinertia
. nwdynam mynet, weightedinertia weightedrecip
. nwdynam mynet, submodel(rate) weightedindeg weightedoutdeg
```
`same()`, `diff()`, `sim()`, `ego()`, `alter()`, and `egoalterint()` have no window option at all, matching `goldfish`'s own effect signatures exactly (checked directly against `goldfish`'s own documentation, not omitted by oversight) - windowing is a real-time recency FILTER ON TIES (has this dyad had a recent event?), but these six effects read a STATIC per-actor covariate value that never changes over the course of the fit and has no "most recent occurrence" to filter on in the first place. `inertia`, `recip`, `indeg`, and `outdeg` are windowable because each is genuinely tie-based (their own value depends on the event history), which these six are not. `tertius()` DOES read the event history (it is a mean over the candidate's own in-neighbors), so it is windowable in `goldfish`'s own table - not yet wired here, a real, disclosed scope limit matching choice's own already-unwindowed `indeg`.

Covariate options (`same()`, `diff()`, `sim()`, `ego()`, `alter()`, `tertius()`, `egoalterint()`) require the current Stata dataset, at the time `nwdynam` is called, to have exactly one row per actor in *netname*'s own actor order - not the event-level dataset *netname* itself was declared from. Use [nwload](nwload)'s `xvars` option first:

```stata
. nwload mynet, xvars
. gen floor = ...
. nwdynam mynet, same(floor)
```
Every effect is evaluated fresh at each event from the event history strictly prior to that event (no lookahead); the covariate effects are static (the covariate itself does not change over the fit).

**Verified** against the real reference R implementation (`goldfish`, CRAN, `stocnet/goldfish`) fit on its own bundled `Social_Evolution` dataset (84 actors, 439 real phone-call events) - both implementations converge to the same log-likelihood surface for every sub-model, structural subset, attribute effect, and windowed configuration tested, recovering matching coefficients to within 1e-2. See `dev/dynam_unit1_crosscheck.R` for the R side and `dev/dynam_unit1_choice_crosscheck.do` through `dev/dynam_unit11_weighted_crosscheck.do` for the direct head-to-head comparisons in this package's own source. The two-mode support described above is separately verified on a real hand-built toy affiliation network (6 "people," 4 "orgs," 60 events) - see `dev/dynam_unit12_twomode_crosscheck.R` and `.do`. `opportunities()` is separately verified on a real hand-built toy directed network (8 actors, 30 events, one random per-event exclusion) - see `dev/dynam_unit13_opportunities_crosscheck.R`, the matching direct Mata-call `.do`, and `dev/dynam_unit13b_opportunities_ado_crosscheck.do` for the same numbers reproduced through this `.ado` command itself. `submodel(choice_coordination)` is separately verified on real hand-built toy undirected networks (a 4-actor/4-event `inertia`-only example and a 6-actor/12-event example with `inertia`, `indeg`, `same()`, `diff()`, `sim()`, and `alter()` each checked) against real `goldfish` - see `dev/dynam_unit14_coordination_crosscheck.R`, the matching direct Mata-call `.do`, and `dev/dynam_unit14b_coordination_ado_crosscheck.do` for the same numbers reproduced through this `.ado` command itself. `nodetrans` and `trans` under `submodel(choice_coordination)` are separately verified on the same 6-actor/12-event toy network, alone and combined with `inertia` - see `dev/dynam_unit15_coordination_closure_crosscheck.R`, the matching direct Mata-call `.do`, and `dev/dynam_unit15b_coordination_closure_ado_crosscheck.do`. `tertius()` and `four` under `submodel(choice_coordination)` are likewise verified on the same toy network, alone and combined with `inertia` - see `dev/dynam_unit16_coordination_tertius_four_crosscheck.R`, the matching direct Mata-call `.do`, and `dev/dynam_unit16b_coordination_tertius_four_ado_crosscheck.do`. `egoalterint()` under `submodel(choice_coordination)` is likewise verified on the same toy network, alone and combined with `inertia` - see `dev/dynam_unit17_coordination_egoalterint_crosscheck.R`, the matching direct Mata-call `.do`, and `dev/dynam_unit17b_coordination_egoalterint_ado_crosscheck.do`. `tie()` is separately verified on a real hand-built toy directed network with a genuinely separate, static exogenous network, alone and combined with `inertia` - see `dev/dynam_unit18_tie_crosscheck.R`, the matching direct Mata-call `.do`, and `dev/dynam_unit18b_tie_ado_crosscheck.do`. `tie()` under `submodel(choice_coordination)` is likewise verified, alone and combined with `inertia` - see `dev/dynam_unit19_coordination_tie_crosscheck.R`, the matching direct Mata-call `.do`, and `dev/dynam_unit19b_coordination_tie_ado_crosscheck.do`. `intercept` is separately verified on a real hand-built toy directed network with REAL (unevenly-spaced) timestamps, matching `goldfish` exactly on two independent effect combinations - see `dev/dynam_unit20_rateintercept_crosscheck.R`, the matching direct Mata-call `.do`, and `dev/dynam_unit20b_rateintercept_ado_crosscheck.do`. `intercept` combined with two-mode networks and with `weightedindeg` and `weightedoutdeg` is likewise verified, each independently on its own real toy network with real timestamps - see `dev/dynam_unit21_rateintercept_twomode_crosscheck.R` and `dynam_unit21c_..._weighted_...R`, the matching direct Mata-call `dev/dynam_unit21_rateintercept_extras_crosscheck.do`, and `dev/dynam_unit21b_rateintercept_extras_ado_crosscheck.do`.

Selecting exactly the three original structural effects, with neither window active, reuses a native-eligible (C) engine - any other active set dispatches to a Mata-only engine instead (no native backend for a genuine subset or a windowed fit yet, a disclosed follow-on). Both engines were confirmed to agree with each other on the full structural-effect set.

The native (C) backend, when available for the running platform, accelerates the log-likelihood/gradient evaluation Mata's own optimizer calls repeatedly - the optimization itself always runs in Mata. Falls back to the pure-Mata engine transparently on any platform without a compiled plugin.

## Examples

- Fit a DyNAM choice sub-model on a small event log:

```stata
. clear
. input sender receiver t
. 1 2 1
. 1 3 2
. 2 1 3
. 1 2 4
. 3 2 5
. 2 3 6
. 1 3 7
. 3 1 8
. 2 1 9
. 1 3 10
. end
. nwset sender receiver, eventtime(t) name(chat)
. nwdynam chat
```
(a handful of events on very few actors, as above, has too little information to pin down the coefficients precisely - wide confidence intervals in this toy example are expected)

- Fit the rate sub-model on the same event log:

```stata
. nwdynam chat, submodel(rate)
```
- Fit only a subset of the choice sub-model's own effects:

```stata
. nwdynam chat, inertia
```
- Add a homophily effect alongside the structural effects:

```stata
. nwload chat, xvars
. gen dept = _n <= 5
. nwdynam chat, inertia recip indeg same(dept)
```
- Does a per-actor covariate on its own predict how often an actor initiates the next event:

```stata
. nwdynam chat, submodel(rate) ego(dept)
```
- Does a candidate receiver's own out-degree predict whether they get chosen (the choice
- sub-model's own `outdeg`, distinct from the rate sub-model's own `outdeg` above):

```stata
. nwdynam chat, inertia outdeg
```
- Restrict inertia to a real-time recency window (`inertiawindow()` alone selects `inertia`):

```stata
. nwdynam chat, inertiawindow(3)
```
- Give inertia and reciprocity genuinely different recency windows in the same model:

```stata
. nwdynam chat, inertiawindow(3) recipwindow(5)
```
- Restrict the rate sub-model's in-degree effect to a real-time recency window
- (`indegwindow()` alone selects `indeg`):

```stata
. nwdynam chat, submodel(rate) indegwindow(3)
```
- Give in-degree and out-degree genuinely different recency windows in the rate sub-model:

```stata
. nwdynam chat, submodel(rate) indegwindow(3) outdegwindow(5)
```
- Does closing a two-path (transitivity) predict the next tie, alongside inertia:

```stata
. nwdynam chat, inertia trans
```
- Is a candidate more likely to be chosen the more embedded they are in transitive structures
- (available under either sub-model):

```stata
. nwdynam chat, nodetrans
. nwdynam chat, submodel(rate) nodetrans
```
- Does a candidate's own well-connected friends (high average department) predict being
- chosen:

```stata
. nwdynam chat, tertius(dept)
```
- Does the sender's own department moderate how much the candidate's own department matters:

```stata
. nwdynam chat, alter(dept) egoalterint(dept dept)
```
- Restrict the candidate risk set to only those actors actually available at each event (a
- dataset with one row per event/available-actor pair, event sequence numbers 1-10, actor IDs 1-3
- matching `chat`'s own three actors):

```stata
. clear
. input evvar actvar
. 1 1
. 1 2
. 2 2
. 2 3
. (one row per event/available-actor pair, continuing through event 10)
. end
. nwdynam chat, inertia opportunities(evvar actvar)
```
- Fit the choice_coordination sub-model on an UNDIRECTED event log (a coordination/mutual-tie
- network - `submodel(choice_coordination)` requires `nwset ..., undirected`):

```stata
. nwset sender receiver, undirected eventtime(t) name(treaties)
. nwdynam treaties, submodel(choice_coordination)
. nwload treaties, xvars
. gen dept = ...
. nwdynam treaties, submodel(choice_coordination) inertia same(dept)
```
- Does whether two actors already have a formal agreement in a SEPARATE, static network
- predict a tie in `chat`, alongside `inertia` (*covnet* declared from a Stata matrix,
- same actor count and order as `chat`):

```stata
. nwset, mat((0,1,1\1,0,0\1,0,0)) name(covnet) directed labs(A,B,C)
. nwdynam chat, inertia tie(covnet)
```
- Fit the genuinely continuous-time WITH-INTERCEPT rate sub-model, sensitive to the real
- elapsed time between events, not just their order (combining `intercept` with
- `weightedoutdeg` or a two-mode network is also verified and supported;
- `indegwindow()` and `outdegwindow()` are not, see **Description** above):

```stata
. nwdynam chat, submodel(rate) intercept indeg
. nwdynam chat, submodel(rate) intercept weightedoutdeg
```

## Stored results

**Scalars**

- **e(N)** number of events
- **e(nodes)** number of actors
- **e(ll)** log likelihood at the MLE

**Macros**

- **e(cmd)** **nwdynam**
- **e(title)** sub-model-specific title string
- **e(depvar)** name of the event network fit
- **e(submodel)** **choice** or **rate**
- **e(effects)** space-separated list of the effects actually fit, in their fixed order

**Matrices**

- **e(b)** coefficient vector (columns named per **e(effects)**)
- **e(V)** variance-covariance matrix (observed information)
