---
title: "nwsaom"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Stochastic actor-oriented model (SAOM) estimation between observed network waves"
---

# `nwsaom`

Stochastic actor-oriented model (SAOM) estimation between observed network waves

## Syntax

```stata
nwsaom
,
wave1(netname) wave2(netname)
or
waves(namelist)
outdegree [reciprocity]
or outdegreeendow outdegreecreation [reciprocity or reciprocityendow reciprocitycreation]
[covariate_options
structural_options
interaction_options
alias_options
coev_options
compchange_options
ratecov_options
symmetric_options
control_options]
Two networks that change together (nwsaom multiplex):
nwsaom multiplex
,
netawave1(netname) netawave2(netname)
netbwave1(netname) netbwave2(netname)
[multiplex_options]
```

**Observed waves**

| | |
|---|---|
| `wave1(netname)` | First observed wave; requires `wave2()`, exactly two waves. Not combinable with `waves()` |
| `wave2(netname)` | Second (ending) observed wave; requires `wave1()` |
| `waves(namelist)` | Two or more observed waves, in temporal order (e.g. `waves(w1 w2 w3)`) - chains *namelist*`-1` inter-wave periods into one pooled fit. Not combinable with `wave1()`/`wave2()` |

**Baseline network effects**

| | |
|---|---|
| `outdegree` | Outdegree (density) effect, evaluation-function role; **required** in every model UNLESS `outdegreeendow`/`outdegreecreation` are given instead |
| `outdegreeendow` | Outdegree effect, ENDOWMENT (tie-withdrawal) role - splits outdegree's own contribution so it fires only on ties that are REMOVED between waves; must be given together with `outdegreecreation`, and not combined with plain `outdegree` (all three roles together are exactly collinear). **Currently refused**: the endowment and creation statistics (lost and gained ties) add up to the rate's distance statistic, so with the rate estimated the model is not identified (RSiena reports a singular covariance matrix for it too). See [Endowment/creation functions](nwsaom_remarks) in nwsaom_remarks |
| `outdegreecreation` | Outdegree effect, CREATION (new-tie) role - the mirror of `outdegreeendow`, firing only on ties that are ADDED between waves; must be given together with it |
| `reciprocity` | Reciprocated-tie effect, evaluation-function role |
| `reciprocityendow` | Reciprocity effect, ENDOWMENT role - same mechanism/rules as `outdegreeendow`, applied to reciprocity instead, with `outdegree`. Not yet supported combined with co-evolution, multi-wave models, `present()`, or `missnet()`. See [Endowment/creation functions](nwsaom_remarks) in nwsaom_remarks |
| `reciprocitycreation` | Reciprocity effect, CREATION role - the mirror of `reciprocityendow`; must be given together with it |

**Node covariate effects**

| | |
|---|---|
| `nodematch(varlist)` | Homophily on categorical node attributes (exact match), one effect per variable - RSiena alias `samex()` |
| `nodecov(varlist)` | Continuous covariate main effect (sum over sender's and receiver's own values), one effect per variable |
| `nodeicov(varlist)` | Alter (receiver) covariate effect - RSiena's own "altX", one effect per variable - RSiena alias `altx()` |
| `nodeocov(varlist)` | Ego (sender) covariate effect - RSiena's own "egoX", one effect per variable - RSiena alias `egox()` |

**Structural network effects**

| | |
|---|---|
| `indegpopularity` | Indegree popularity, sqrt-transformed ("preferential attachment" toward already-popular alters) |
| `outpopularity` | Outdegree popularity, sqrt-transformed (RSiena's outPopSqrt as documented; see [the note on RSiena's default](nwsaom_remarks)) |
| `outactivity` | Outdegree activity, squared (concentrates out-ties on already-active senders) |
| `inactivity` | Indegree activity, sqrt-transformed (RSiena's inActSqrt as documented; see [the note on RSiena's default](nwsaom_remarks)) |
| `transtrip` | Transitive triplets (weighted count of transitive closures i->j via existing two-paths) |
| `transmedtrip` | Transitive mediated triplets: for each tie i->j, the number of other actors with an incoming tie to both i and j (RSiena's own "transMedTrip") - a distinct measure of shared incoming ties from `transtrip' |
| `cycle3` | Directed 3-cycles (i->j->h->i) |
| `cycle4` | Directed four-cycles effect: a directed three-path i->h<-k->j, closed by the tie
	i->j itself (RSiena's own "four cycles" effect). Base/fixed (non-sqrt) parameterization only |
| `transties` | Existence-indicator triadic closure - simpler, more robust alternative to `transtrip` (RSiena's own "transTies"); no parameter |
| `balance` | Structural balance effect (RSiena's own `balance`); no user-supplied parameter - the "balanceMean" constant is computed automatically from the observed wave data |
| `isolatenet` | Counts actors with BOTH indegree and outdegree exactly 0, true isolates (RSiena's own "network-isolate"); no parameter |
| `outiso` | Counts actors with outdegree exactly 0, regardless of indegree (RSiena's own "out-isolate"); no parameter |
| `antiiso` | Counts actors with indegree>=1 AND outdegree=0, a "pure receiver" (RSiena's own "anti isolates"); no parameter |
| `antiiniso` | Counts actors with indegree>=1, the complement of an in-isolate (RSiena's own "anti in-isolates"); no parameter |
| `antiiniso2` | Counts actors with indegree>=2 (RSiena's own "anti in-near-isolates"); no parameter |
| `inplus3` | Counts actors with indegree>=3 (RSiena's own "in3Plus", same effect family as `antiiniso`/`antiiniso2` with a higher threshold); no parameter |
| `isolatepop` | For each actor, counts its own ties to alters with indegree exactly 1 and outdegree 0 (RSiena's own "isolate - popularity"); no parameter |
| `transrectrip` | Like `transtrip`, but only counting two-paths i->j->h whose final leg j->h is itself reciprocated (RSiena's own "transitive reciprocated triplets"); no parameter |
| `outoutass` | Actors with high outdegree preferentially tie to other high-outdegree actors, default/non-sqrt parameterization only (RSiena's own "out-out degree assortativity"); no parameter |
| `ininass` | The `outoutass` sibling using indegree instead, default/non-sqrt parameterization only (RSiena's own "in-in degree assortativity"); no parameter |
| `outinass` | Actors with high outdegree preferentially tie to actors with high indegree, default/non-sqrt parameterization only (RSiena's own "out-in degree assortativity"); no parameter |
| `inoutass` | Actors with high indegree preferentially tie to actors with high outdegree, default/non-sqrt parameterization only (RSiena's own "in-out degree assortativity"); no parameter |
| `gwesp(real)` | Geometrically weighted edgewise shared partners (OTP-directed), fixed decay - argument is the DIRECT decay value (Statnet's own `gwesp(decay=)` scale), NOT RSiena's own "parameter" (RSiena's own value is 100x this one - RSiena `gwespFF(69)` = `gwesp(.69)` here) |

**Interaction effects**

| | |
|---|---|
| `interact(effect1#effect2[#effect3] [effect4#effect5 ...])` | Two- or three-way interaction (RSiena's `includeInteraction()`) of network effects already in the model as main effects, with its own coefficient; its contribution to a ministep is the product of the components' contributions. Several interactions may be listed. The effects allowed follow RSiena's rule: each effect is an ego effect (`egox()`, `inactivity`, `isolatenet`, `isolatepop`), a dyadic effect (`outdegree`, `reciprocity`, `samex()`, `altx()`, `nodecov()`, `simx()`, `gwesp()`, `outpopularity`, `inoutass`) or another effect (`transtrip`, `transmedtrip`, `transrectrip`, `cycle3`, `cycle4`, `transties`, `balance`, `indegpopularity`, `outactivity`, `outiso`, `outoutass`, `outinass`, `ininass`); two effects need an ego effect or two dyadic effects, three effects two ego effects or only ego and dyadic effects. Interactions RSiena accepts but cannot compute are refused too: `outiso` and `isolatenet` only with `egox()` (and `outdegree`), and the anti-isolate effects not at all. A covariate effect given for several variables is named by its coefficient name, e.g. `interact(samex_smoke1#egox_alcohol1)` (either spelling, `nodematch_smoke1` or `samex_smoke1`); with one variable the effect type alone works (`interact(samex#egox)`). Coefficients are named interact_*A*_*B*, or ix_*A*_*B* when that is longer than 32 characters; RSiena's name is in **e(rsiena_labels)** and listed under the table with `detail`. Behavior interactions are not supported. See [Interaction effects](nwsaom_remarks) in nwsaom_remarks |

**RSiena naming aliases**

| | |
|---|---|
| `simcov(varlist)` | Covariate similarity effect, 1 - \|x_i - x_j\|/range minus its mean over all pairs (RSiena's simX; before 2026-10-01 not centred, which changed only the outdegree coefficient), one effect per variable - RSiena alias `simx()` |
| `egox(varlist)` | RSiena naming alias for `nodeocov()` - identical effect, coefficient label follows this spelling |
| `altx(varlist)` | RSiena naming alias for `nodeicov()` - identical effect, coefficient label follows this spelling |
| `samex(varlist)` | RSiena naming alias for `nodematch()` - identical effect, coefficient label follows this spelling |
| `simx(varlist)` | RSiena naming alias for `simcov()` - identical effect, coefficient label follows this spelling |

**Behavior co-evolution effects**

| | |
|---|---|
| `behavior(varlist)` | Co-evolution: one bounded-integer behavior variable, ONE Stata variable name per wave, same temporal order as `wave1()`/`wave2()` or `waves()` (e.g. two waves: `behavior(b1 b2)`; three: `behavior(b1 b2 b3)`). Requires `linear`. A SECOND dependent variable evolving jointly with the network - see [Co-evolution](nwsaom_remarks) in nwsaom_remarks |
| `linear` | Behavior linear shape effect (RSiena's own baseline behavior effect), evaluation-function role; **required** whenever `behavior()` is specified, as `outdegree` is on the network side |
| `linearendow` | Behavior linear effect, ENDOWMENT (loss/decrease) role - splits the linear effect's downward direction into its own parameter; must be given together with `linearcreation`, and not combined with `linear` (all three roles together are exactly collinear). **Currently refused**: the two statistics (decreases and increases) add up to the behavior rate's distance statistic, so with the behavior rate estimated the model is not identified (RSiena reports a singular covariance matrix for it too); use `linear`. See [Endowment/creation functions](nwsaom_remarks) in nwsaom_remarks |
| `linearcreation` | Behavior linear effect, CREATION (gain/increase) role - the upward-direction counterpart to `linearendow`; must be given together with it |
| `quadratic` | Behavior quadratic shape effect; requires `behavior()`, not combinable with `quadraticendow`/`quadraticcreation` |
| `quadraticendow` `quadraticcreation` | Behavior quadratic effect split into its ENDOWMENT/CREATION roles - same mechanism/rules as `linearendow`/`linearcreation` (must be given together, not combined with plain `quadratic`), applied to the quadratic shape effect instead; independent of whichever baseline role (`linear` or `linearendow`/`linearcreation`) is in use |
| `avalt` | Behavior "average alter" influence effect - own value moves toward network neighbors' own average value; requires `behavior()` |
| `avaltendow` `avaltcreation` | `avalt` split into its ENDOWMENT/CREATION roles - same mechanism/rules as `linearendow`/`linearcreation` |
| `avsim` | Behavior "average similarity" influence effect - own value moves to maximize average similarity to network neighbors' own values, net of a data-derived centering constant; requires `behavior()` |
| `avsimendow` `avsimcreation` | `avsim` split into its ENDOWMENT/CREATION roles - same mechanism/rules as `linearendow`/`linearcreation` |
| `behsim` | Network-side SELECTION effect on the co-evolving behavior (RSiena's `simX` with the dependent behavior, e.g. "drinking similarity"): actors prefer ties to others whose CURRENT behavior value is similar to their own. Tie-level contribution 1 - \|z_i - z_j\|/range - simMean, with range and simMean the behavior's own (the same constants `avsim` uses). Unlike `simcov()`, which reads a fixed covariate, the values change during the simulation as the behavior co-evolves. A network effect: its coefficient appears among the network coefficients, after the other network effects. Requires `behavior()` |
| `behtheta0(numlist)` | Starting values for the behavior-side eval-parameter vector, one per requested behavior effect in the order `linear` (or `linearendow`/`linearcreation`)/`quadratic`/`avalt`/`avsim` appear above; default all zero |

**Composition change and missing data**

| | |
|---|---|
| `present(varlist)` | Composition change ("joiners and leavers"): one 0/1 variable per wave, same "one variable per wave" convention as `behavior()`, marking which actors are present at each wave. Optional - omitting it means every actor is present the whole time. See [Composition change](nwsaom_remarks) in nwsaom_remarks |
| `missnet(matlist)` | Missing tie data: one 0/1 n x n MATRIX name per wave, marking which dyads are missing at that wave. Optional - omitting it means every dyad is fully observed. See [Missing data](nwsaom_remarks) in nwsaom_remarks |
| `missbeh(varlist)` | Missing behavior data: one 0/1 variable per wave, same "one variable per wave" convention as `present()`, marking which actors' behavior value is missing at that wave. Requires `behavior()`. Optional - omitting it means every actor's value is fully observed. See [Missing data](nwsaom_remarks) in nwsaom_remarks |
| `structural(matname)` | Structural zeros/ones: ONE 0/1 n x n MATRIX (zero diagonal) marking dyads whose tie value is fixed by design rather than actor choice (e.g. a legally mandated reporting tie, or a dyad known a priori to never form) - a marked dyad is excluded from every actor's own ministep candidate set, so it can never toggle during simulation. The marked dyad's OBSERVED value must be identical at both waves (a "frozen" dyad that genuinely changed between waves is rejected outright, matching RSiena's own structural-value convention that a fixed dyad's data must actually be constant). v1 scope: exactly two waves (`wave1()`/`wave2()`, not `waves()`), network-only (no `behavior()`); not yet combinable with `symmetric`, `ratecov()`, or the network endowment/creation split. See [Structural zeros/ones](nwsaom_remarks) in nwsaom_remarks |

**Covariate-dependent rate**

| | |
|---|---|
| `ratecov(varlist)` | Let node covariates raise or lower each actor's own opportunity to make a network change, instead of every actor sharing one constant rate for the period - actor i's own rate becomes *rate**exp(sum of *b_k***x_k*[i]) over the variables, one coefficient each (RSiena's RateX effects). The coefficient is estimated jointly with every other effect. Not yet supported combined with co-evolution, multi-wave models, `present()`, or `missnet()`; combinable with `symmetric`. See [Remarks](nwsaom_remarks) |
| `ratecovcoef(numlist)` | Starting values for the `ratecov()` coefficients, one per variable or one for all (default 0) |
| `nocenter` | Use the raw values of the covariates of `egox()`, `altx()`, `nodecov()` and `ratecov()`. By default they are centred by their means (missing values set to the mean), as RSiena's `coCovar(centered = TRUE)`, so that all coefficients, including outdegree and the rate, are RSiena's; the means are returned in **e(covmeans)** and listed under the table with `detail`. Centring changes only the outdegree coefficient (and the rate intercept), not the covariate coefficients. `samex()` does not depend on it; `simx()` is centred by its similarity mean either way |

**Undirected/symmetric relations**

| | |
|---|---|
| `symmetric` | Model a non-directed relation (x_ij always equals x_ji). Not needed for waves declared undirected (`nwset ..., undirected`, [nwsym](nwsym)) or directed waves that are all tie-symmetric: like RSiena, `nwsaom` then models a non-directed relation automatically (tie-symmetric directed waves stay directed only with `reciprocity` or where the non-directed model does not apply: `waves()`, `behavior()`, endowment/creation effects). With directed waves that are not tie-symmetric `symmetric` is an error; it does not symmetrize data. Several effects are not meaningful for a non-directed relation and are rejected - see [Remarks](nwsaom_remarks). v1 scope: exactly two waves (`wave1()`/`wave2()`), network-only; combinable with `present()`, `missnet()`, and `ratecov()` |
| `symtype(string)` | Model type of a non-directed relation, by name or RSiena's modelType number: **forcing** (2; default, RSiena's default for a symmetric network) - an actor chooses a tie to change and imposes it; **confirmation** (3) - as forcing, but a new tie needs the alter's confirmation; **force** (4), **agree** (5), **joint** (6) - pairwise: a random pair meets and the tie changes if the initiator wants it (force), if both want a new tie or either wants to end one (agree), or if their summed preferences favor it (joint). Before 2026-10-01 the default was **joint** and types 2/3 were not available. See [Remarks](nwsaom_remarks) |

**Estimation control**

| | |
|---|---|
| `unconditional` | Estimate a network-only model by UNCONDITIONAL Method of Moments (RSiena's `cond = FALSE`): the rates become Method-of-Moments parameters. The default for a network-only model is CONDITIONAL estimation, RSiena's default for a single dependent network (`cond = TRUE`); co-evolution and `nwsaom multiplex` models are always unconditional, as in RSiena (see [Estimation](nwsaom_remarks) in nwsaom_remarks) |
| `rate0(numlist)` | Starting value(s) of the network rate(s) of an unconditional network-only fit: one value, or one per inter-wave period; default RSiena's closed-form starting value, computed from the data. With `theta0()`, restarts a fit from earlier estimates. For `symmetric` fits on RSiena's scale, as e(rate). Not used under conditional estimation, where the rates are not estimated by Robbins-Monro (see [Estimation](nwsaom_remarks) in nwsaom_remarks) |
| `theta0(numlist)` | Starting values for the eval-parameter vector, one per requested effect IN THE ORDER LISTED IN THE ERROR MESSAGE if omitted or mis-sized (outdegree first, then every other effect in the order its own option appears above); default all zero, except that a network-only model starts `outdegree` at RSiena's data-derived starting value |
| `k0(int)` | Phase-1 replicate count (Jacobian estimation via the score-function derivative estimator); default 50 |
| `k3(int)` | Phase-3 replicate count (convergence diagnostics and the covariance matrix e(V)); default 1,000 |
| `firstg(real)` | Phase-2 starting gain (Robbins-Monro step size); default 0.2, matching RSiena's own default |
| `seed(int)` | Set the random-number seed before simulating (for reproducibility) |
| `cores(#)` | Number of threads the native simulator uses; default 0, all physical cores; `cores(1)` runs single-threaded. Every simulation draws from its own random stream derived from the seed and its position, so results for a given `seed()` are identical whatever the number of threads. Applies to fits with the native backend; see [Estimation](nwsaom_remarks) in nwsaom_remarks |
| `detail` | Also display RSiena's names of the covariate, interaction and behavior effects, the covariates' centring means, an explanation of the conditional rate, and the convergence t-ratio of every parameter. By default only the overall maximum convergence ratio is shown, with any parameter whose t-ratio is 0.1 or more in absolute value; the full information is always stored in **e(rsiena_labels)**, **e(covmeans)** and **e(tconv)** |

**Waves (all required)**

| | |
|---|---|
| `netawave1(netname)` | first network (A) at the first wave |
| `netawave2(netname)` | network A at the second wave |
| `netbwave1(netname)` | second network (B) at the first wave |
| `netbwave2(netname)` | network B at the second wave |

**Effects**

| | |
|---|---|
| `crprod` | effect of a tie in B on the same tie in A (coefficient **net1_crprod**) |
| `crprodb` | effect of a tie in A on the same tie in B (coefficient **net2_crprod**) |

**Estimation**

| | |
|---|---|
| `theta01(numlist)` | starting values for network A's effects, in the order **outdegree**, **reciprocity**, **crprod**; default 0 |
| `theta02(numlist)` | starting values for network B's effects, in the order **outdegree**, **reciprocity**, **crprodb**; default 0 |
| `k0(#)` | Phase 1 simulations; default 30 |
| `k3(#)` | Phase 3 simulations; default 200 |
| `firstg(#)` | initial Robbins-Monro gain; default 0.2 |
| `seed(#)` | random-number seed |
| `detail` | list the convergence t-ratio of every parameter |

## Description

`nwsaom` fits a stochastic actor-oriented model (SAOM, Snijders-style) between two or more observed panel waves of the same network on a fixed set of actors. It fits the same models as the [RSiena](https://www.stats.ox.ac.uk/~snijders/siena/) package (Ripley, Snijders et al.), with the same effects and estimation algorithm, and gives the same estimates; no R or other outside software is needed. `nwsaom` is not affiliated with or endorsed by the RSiena project.

An SAOM models network change as a sequence of unobserved, actor-driven "ministeps": between consecutive observed waves, actors are activated one at a time (at a rate governed by the model's own rate parameter) and each activated actor may create or drop exactly one of its own outgoing ties, choosing among the available alternatives (including "no change") via a multinomial-logit choice model on a linear combination of effect-specific "change statistics", weighted by the effect's estimated coefficient. An actor evaluates a choice only by its own resulting statistics, not by its effect on other actors; this distinguishes an SAOM from an ERGM (see [nwergm](nwergm)), which describes a probability distribution over whole networks. Coefficients are estimated by the Method of Moments via Robbins-Monro stochastic approximation, RSiena's default.

`nwsaom multiplex` fits two directed networks on the same actors that change together between two waves, for example friendship and advice. Each network has its own **outdegree** and **reciprocity** effects and its own rate; `crprod` adds the effect of a tie in the second network on the same tie in the first, and `crprodb` the reverse. In a ministep the other network's current state counts; the `crprod` statistics use the other network at the start of the period, as RSiena does for effects linking two dependent variables. Both rates are estimated with the effects (unconditional Method of Moments, RSiena's default for two dependent variables). Other effects, more than two waves, and `estat gof` are not available for multiplex models. On a friendship network and a simulated advice network, every parameter agrees with RSiena 1.6.6 within 0.06 standard errors (five seeds). See [Multiplex](nwsaom_remarks) in nwsaom_remarks for details.

## Remarks

See [nwsaom_remarks](nwsaom_remarks) for the full effect-derivation library (every effect's own ministep formula and how it was verified against RSiena's real source), interaction/multiplex/co-evolution mechanics, composition-change/missing-data/structural-zero handling, the full performance benchmark, and the estimation-algorithm background (Method-of-Moments phase structure, rate estimation). That material was split into its own file purely to keep this file's own length within Stata's interactive Viewer's rendering limits - it is not optional/secondary content, just relocated.

## Examples

All examples except the last use the Glasgow friendship data (RSiena's s50 data): three waves of friendship among 50 pupils (`glasgow1`-`glasgow3`) and smoking, alcohol and sport at each wave (`smoke1`-`smoke3`, `alcohol1`-`alcohol3`, `sport1`-`sport3`).

```stata
. nwwebuse glasgow, nwclear
```
- **Network change between two waves, and over three waves**

```stata
. nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity seed(1)
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity seed(1)
```
- **Triadic closure and degree effects**

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip cycle3 seed(1)
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) indegpopularity outactivity seed(1)
```
- **Covariate effects** (homophily on smoking; ego, alter and similarity effects of alcohol and
- sport); `detail` also lists RSiena's effect names, the covariate means and every convergence
- t-ratio

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) samex(smoke1) egox(alcohol1 sport1) altx(alcohol1 sport1) simx(alcohol1) seed(1)
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) samex(smoke1) seed(1) detail
```
- **Interaction**: does the effect of reciprocity depend on the sender's alcohol use?

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) egox(alcohol1) interact(egox#reciprocity) seed(1)
```
- **Goodness of fit**

```stata
. estat gof
```
- **Restarting from the estimates** when the overall maximum convergence ratio is above 0.25

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) seed(1)
. matrix b = e(b)
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) theta0(`=b[1,1]' `=b[1,2]' `=b[1,3]') seed(2)
```
- **Unconditional estimation** (RSiena's `cond = FALSE`; restart it with `rate0()` as well
- as `theta0()`)

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) unconditional seed(1)
```
- **Covariate-dependent rate**: do heavier drinkers change their friendships more often?

```stata
. nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity ratecov(alcohol1) seed(1)
```
- **Co-evolution of friendship and drinking**: selection (`behsim`) and influence
- (`avalt`, or `avsim` as the alternative influence effect)

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) behsim behavior(alcohol1 alcohol2 alcohol3) linear quadratic avalt seed(1)
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) behsim behavior(alcohol1 alcohol2 alcohol3) linear quadratic avsim seed(1)
. estat gof
```
- **Separate effects for increasing and decreasing behavior** (endowment and creation)

```stata
. nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity behavior(alcohol1 alcohol2) linear quadraticendow quadraticcreation seed(1)
```
- **Undirected networks**: symmetrized friendship; RSiena's default model type (forcing), and
- the pairwise model in which both actors decide jointly

```stata
. nwsym glasgow1, generate(u1) mode(max)
. nwsym glasgow2, generate(u2) mode(max)
. nwsaom, wave1(u1) wave2(u2) outdegree gwesp(.69) samex(smoke1) seed(1)
. nwsaom, wave1(u1) wave2(u2) outdegree symtype(joint) seed(1)
```
- **Composition change**: three pupils leave after the first wave (`p1`, `p2` mark who
- is present)

```stata
. generate byte p1 = 1
. generate byte p2 = _n > 3
. nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity present(p1 p2) seed(1)
```
- **Missing data**: a missing behavior value (`missbeh()`: one 0/1 variable per wave) and
- missing tie values (`missnet()`: one 0/1 matrix per wave)

```stata
. generate byte mb1 = _n == 5
. generate byte mb2 = 0
. nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity behavior(alcohol1 alcohol2) linear avalt missbeh(mb1 mb2) seed(1)
. matrix miss1 = J(50, 50, 0)
. matrix miss1[1,2] = 1
. matrix miss2 = J(50, 50, 0)
. nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity missnet(miss1 miss2) seed(1)
```
- **Structural zeros**: dyads that cannot change (a 0/1 matrix; here, ties from pupil 1 to
- pupils 11-20, which are absent at both waves)

```stata
. matrix zeros = J(50, 50, 0)
. forvalues j = 11/20 {
.     matrix zeros[1,`j'] = 1
. }
. nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity structural(zeros) seed(1)
```
- **Threads**: the same results on one thread (the default uses all physical cores)

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) cores(1) seed(1)
```
- **Two networks that change together** (`nwsaom multiplex`). The Glasgow data have one
- network, so this example simulates a second one, "advice", that overlaps with friendship:

```stata
. nwtomata glasgow1, mat(F1)
. nwtomata glasgow2, mat(F2)
. set seed 20261001
. mata: A1 = (F1 :* (runiform(50, 50) :< 0.7) + (runiform(50, 50) :< 0.005)) :> 0
. mata: _diag(A1, 0)
. mata: A2 = (A1 :* (runiform(50, 50) :< 0.8) + F2 :* (1 :- A1) :* (runiform(50, 50) :< 0.4)) :> 0
. mata: _diag(A2, 0)
. nwset, mat(A1) directed name(advice1)
. nwset, mat(A2) directed name(advice2)
```
- Each network with outdegree and reciprocity, and the effect of each network on the other:

```stata
. nwsaom multiplex, netawave1(glasgow1) netawave2(glasgow2) netbwave1(advice1) netbwave2(advice2) crprod crprodb seed(1)
```
- Restarting from the estimates (one starting value per effect of each network):

```stata
. matrix b = e(b)
. nwsaom multiplex, netawave1(glasgow1) netawave2(glasgow2) netbwave1(advice1) netbwave2(advice2) crprod crprodb theta01(`=b[1,1]' `=b[1,2]' `=b[1,3]') theta02(`=b[1,4]' `=b[1,5]' `=b[1,6]') seed(2)
```

## Performance

`nwsaom` has a native (C) simulation backend, used automatically whenever the fitted model's effects all have native coverage (no option needed to opt in). See [Remarks](nwsaom_remarks) for a full wall-clock benchmark against real RSiena and the performance-tuning history behind it.

## Supported network types

Binary: yes (only) - a valued/weighted wave is rejected. Directed: yes (required) - SAOM's own ministep formulation is inherently directed (an actor controls only its own outgoing ties); an undirected wave is rejected. Two-mode: no (rejected). Signed: not applicable/not supported.

## Stored results

`nwsaom` stores the following in `e()`:

**Scalars**

- **e(N)** number of actors (= e(nodes))
- **e(nodes)** number of actors
- **e(nwaves)** number of waves supplied
- **e(rate)** network rate parameter (wave1()/wave2() path only): conditional estimation, the mean simulated time to reach the observed distance (RSiena's rate); unconditional, a Method-of-Moments estimate (see [Estimation](nwsaom_remarks) in nwsaom_remarks). `symmetric` fits: on RSiena's scale for pairwise models (see [Undirected/symmetric relations](nwsaom_remarks) in nwsaom_remarks)
- **e(ratecoefs)** `ratecov()` fits: 1 x K covariate-rate coefficients, columns named by the variables; also **e(ratecoefs_se)**, **e(ratecoefs_tratio)**, **e(ratecoefs_fixed)** (with one variable also the scalars **e(ratecoef)**, **e(ratecoef_se)**, **e(ratecoef_tratio)**, **e(ratecoef_fixed)**)
- **e(engine)** **native** if the simulations ran in the C plugin, **mata** if in Mata (then also a note after the table and **e(engine_why)**)
- **e(rsiena_labels)** RSiena's effect names of the coefficients, in **e(b)**'s order, separated by "|" (e.g. "alcohol1 ego", "same smoke1", "alcohol1 ego x reciprocity")
- **e(rate_actor)** non-directed fits only: the rate at which an actor gets an opportunity to change, the scale of every other `nwsaom` rate (differs from e(rate), RSiena's rate, only for the pairwise types force/agree/joint)
- **e(conditional)** 1 for conditional estimation, 0 for unconditional
- **e(centered)** 1 if the covariates were centred (the default), 0 with `nocenter`
- **e(rate_tratio)** network rate parameter's convergence t-ratio on RSiena's scale, missing under conditional estimation (wave1()/wave2() path only - see [Estimation](nwsaom_remarks) in nwsaom_remarks)
- **e(rate_se)** standard error of e(rate) (wave1()/wave2() path only); conditional estimation: RSiena's, the standard deviation of the simulated times
- **e(has_behavior)** 1 if this is a co-evolution fit (`behavior()` specified), 0 otherwise
- **e(p_net)** number of network-side eval-parameter coefficients (co-evolution fits only; the first e(p_net) columns of e(b)/e(V)/e(tratio) are the network's own, the remainder the behavior's own, prefixed `beh_`)
- **e(rate_beh)** estimated behavior rate parameter (co-evolution, wave1()/wave2() path only), estimated jointly with the other parameters (see [Co-evolution](nwsaom_remarks) in nwsaom_remarks)
- **e(rate_beh_se)** standard error of e(rate_beh) (co-evolution, wave1()/wave2() path only)
- **e(rate_beh_tratio)** behavior rate parameter's convergence t-ratio on RSiena's scale (co-evolution, wave1()/wave2() path only)
- **e(tconv_max)** RSiena's overall maximum convergence ratio; below 0.25 indicates good convergence

**Macros**

- **e(cmd)** **nwsaom**
- **e(title)** title of estimation
- **e(waves)** list of wave network names, in temporal order
- **e(symtype)** non-directed fits only: the model type, **forcing**, **confirmation**, **force**, **agree**, or **joint**
- **e(modeltype)** non-directed fits only: RSiena's modelType number of e(symtype) (2, 3, 4, 5, 6)
- **e(wave1)** first wave name (wave1()/wave2() path only)
- **e(wave2)** second wave name (wave1()/wave2() path only)
- **e(behavior)** list of behavior variable names, one per wave, in temporal order (co-evolution fits only)
- **e(estat_cmd)** **nwsaom_estat** (postestimation dispatch)

**Matrices**

- **e(b)** coefficient vector (eval parameters only - excludes rate; network then behavior for a co-evolution fit, see e(p_net) above)
- **e(V)** variance-covariance matrix (eval parameters only)
- **e(tratio)** 1 x nparam convergence t-ratios on RSiena's scale (phase-3 mean deviation / its standard deviation), one per coefficient of e(b) - the matching columns of e(tconv)
- **e(rates)** 1 x (nwaves-1) per-period network rate parameters (waves() path only), as e(rate)
- **e(rate_tratios)** 1 x (nwaves-1) per-period network rate convergence t-ratios (waves() path only)
- **e(rates_se)** 1 x (nwaves-1) per-period standard errors of e(rates) (waves() path only)
- **e(rates_beh)** 1 x (nwaves-1) per-period estimated behavior rate parameters (co-evolution, waves() path only)
- **e(rate_beh_tratios)** 1 x (nwaves-1) per-period behavior rate convergence t-ratios (co-evolution, waves() path only)
- **e(rates_beh_se)** 1 x (nwaves-1) per-period standard errors of e(rates_beh) (co-evolution, waves() path only)
- **e(covmeans)** means of the covariates of `egox()`/`altx()`/`nodecov()`/`ratecov()`, columns named by the variables (subtracted unless `nocenter`)
- **e(tconv)** RSiena-style convergence t-ratios (phase-3 mean deviation / its standard deviation), one per parameter including the rates; all below 0.1 in absolute value indicates good convergence. Printed after the coefficient table, followed by e(tconv_max). (Before 2026-10-01 e(tratio) and the rate t-ratios were mean / (sd/sqrt(k3)), about 31.6 times this scale with the default k3(1000))

`estat gof` stores the following in `r()`, one pair per requested statistic (default **outdegree**/**indegree**/**geodesic**):

**Scalars**

- **r(p_*stat*)** empirical Mahalanobis-distance test p-value for that statistic
- **r(mhd_*stat*)** observed vector's own Mahalanobis distance from the simulated mean

`nwsaom multiplex` stores the following in `e()`:

**Scalars**

- **e(N)** number of actors
- **e(rate1)**, **e(rate2)** rates of networks A and B
- **e(rate1_se)**, **e(rate2_se)** their standard errors
- **e(tconv_max)** overall maximum convergence ratio

**Macros**

- **e(cmd)** **nwsaom_multiplex**
- **e(engine)** **native** or **mata**

**Matrices**

- **e(b)** coefficients: **net1_outdegree**, **net1_reciprocity**, [**net1_crprod**], **net2_outdegree**, **net2_reciprocity**, [**net2_crprod**]
- **e(V)** their covariance matrix
- **e(tconv)** convergence t-ratios of the coefficients and the two rates

## References

Snijders, T.A.B. (2001). The statistical evaluation of social network dynamics. *Sociological Methodology*, 31(1), 361-395. (SAOM/Method of Moments)

Snijders, T.A.B., van de Bunt, G.G., Steglich, C.E.G. (2010). Introduction to stochastic actor-based models for network dynamics. *Social Networks*, 32(1), 44-60.

Ripley, R.M., Snijders, T.A.B., Boda, Z., Voros, A., Preciado, P. (2024). Manual for RSiena. University of Oxford. [stats.ox.ac.uk/~snijders/siena/](https://www.stats.ox.ac.uk/~snijders/siena/)

Lospinoso, J., Snijders, T.A.B. (2019). Goodness of fit for stochastic actor-oriented models. *Methodological Innovations*, 12(3).

`nwsaom` is an independent, native reimplementation and is not affiliated with or endorsed by the RSiena project.

## See also

- [nwergm](nwergm), [nwset](nwset), [nwrandom](nwrandom)
