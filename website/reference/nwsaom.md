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
| `outdegreeendow` | Outdegree effect, ENDOWMENT (tie-withdrawal) role - splits outdegree's own contribution so it fires only on ties that are REMOVED between waves; must be given together with `outdegreecreation`, and not combined with plain `outdegree` (all three roles together are exactly collinear). Satisfies the same required-baseline role plain `outdegree` does. Not yet supported combined with co-evolution, multi-wave models, `present()`, or `missnet()`. See [Endowment/creation functions](nwsaom_remarks) in nwsaom_remarks |
| `outdegreecreation` | Outdegree effect, CREATION (new-tie) role - the mirror of `outdegreeendow`, firing only on ties that are ADDED between waves; must be given together with it |
| `reciprocity` | Reciprocated-tie effect, evaluation-function role |
| `reciprocityendow` | Reciprocity effect, ENDOWMENT role - same mechanism/rules as `outdegreeendow`, applied to reciprocity instead; independent of whichever baseline role (`outdegree` or `outdegreeendow`/`outdegreecreation`) is in use. Note: on data where a mutual tie is essentially never lost in BOTH directions at once, this effect's own observed target can be exactly zero, leaving it unidentified (a genuine data property, not a bug) - see [Endowment/creation functions](nwsaom_remarks) in nwsaom_remarks |
| `reciprocitycreation` | Reciprocity effect, CREATION role - the mirror of `reciprocityendow`; must be given together with it |

**Node covariate effects**

| | |
|---|---|
| `nodematch(varname)` | Homophily on a categorical node attribute (exact match); ONE variable per model - RSiena alias `samex()` |
| `nodecov(varname)` | Continuous covariate main effect (sum over sender's and receiver's own values); ONE variable per model |
| `nodeicov(varname)` | Alter (receiver) covariate effect - RSiena's own "altX"; ONE variable per model - RSiena alias `altx()` |
| `nodeocov(varname)` | Ego (sender) covariate effect - RSiena's own "egoX"; ONE variable per model - RSiena alias `egox()` |

**Structural network effects**

| | |
|---|---|
| `indegpopularity` | Indegree popularity, sqrt-transformed ("preferential attachment" toward already-popular alters) |
| `outpopularity` | Outdegree popularity, sqrt-transformed |
| `outactivity` | Outdegree activity, squared (concentrates out-ties on already-active senders) |
| `inactivity` | Indegree activity, sqrt-transformed |
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
| `interact(effect1#effect2[#effect3] [effect4#effect5 ...])` | Two- or three-way interaction (RSiena's own `includeInteraction()`) between effects ALREADY included in the model as their own main effects - the interaction's own contribution to an actor's ministep utility is the PRODUCT of the components' own contributions, with its own freely-estimated coefficient. Multiple interactions may be listed, space-separated. Restricted to "dyadic" (tie-level) effects that have a well-defined per-tie contribution to multiply: **outdegree reciprocity nodematch nodecov nodeicov nodeocov transtrip cycle3 simcov transrectrip outoutass ininass outinass inoutass cycle4 transmedtrip gwesp transties balance** (and their RSiena aliases `egox()`/`altx()`/`samex()`/`simx()`) - the node-level effects (**indegpopularity outactivity outpopularity inactivity isolatenet outiso antiiso antiiniso antiiniso2 inplus3**) have no such per-tie value and are rejected, whether named first, second, or third. Three-way interactions are Mata-only (no native speed-up yet); behavior interactions are not yet supported. See [Interaction effects](nwsaom_remarks) in nwsaom_remarks |

**RSiena naming aliases**

| | |
|---|---|
| `simcov(varname)` | Covariate similarity effect; ONE variable per model - RSiena alias `simx()` |
| `egox(varname)` | RSiena naming alias for `nodeocov()` - identical effect, coefficient label follows this spelling |
| `altx(varname)` | RSiena naming alias for `nodeicov()` - identical effect, coefficient label follows this spelling |
| `samex(varname)` | RSiena naming alias for `nodematch()` - identical effect, coefficient label follows this spelling |
| `simx(varname)` | RSiena naming alias for `simcov()` - identical effect, coefficient label follows this spelling |

**Behavior co-evolution effects**

| | |
|---|---|
| `behavior(varlist)` | Co-evolution: one bounded-integer behavior variable, ONE Stata variable name per wave, same temporal order as `wave1()`/`wave2()` or `waves()` (e.g. two waves: `behavior(b1 b2)`; three: `behavior(b1 b2 b3)`). Requires `linear`. A SECOND dependent variable evolving jointly with the network - see [Co-evolution](nwsaom_remarks) in nwsaom_remarks |
| `linear` | Behavior linear shape effect (RSiena's own baseline behavior effect), evaluation-function role; **required** whenever `behavior()` is specified UNLESS `linearendow`/`linearcreation` are given instead, matching `outdegree`'s own required-baseline role on the network side |
| `linearendow` | Behavior linear effect, ENDOWMENT (loss/decrease) role - splits the linear effect's downward direction into its own parameter; must be given together with `linearcreation`, and not combined with `linear` (all three roles together are exactly collinear). See [Endowment/creation functions](nwsaom_remarks) in nwsaom_remarks |
| `linearcreation` | Behavior linear effect, CREATION (gain/increase) role - the upward-direction counterpart to `linearendow`; must be given together with it |
| `quadratic` | Behavior quadratic shape effect; requires `behavior()`, not combinable with `quadraticendow`/`quadraticcreation` |
| `quadraticendow` `quadraticcreation` | Behavior quadratic effect split into its ENDOWMENT/CREATION roles - same mechanism/rules as `linearendow`/`linearcreation` (must be given together, not combined with plain `quadratic`), applied to the quadratic shape effect instead; independent of whichever baseline role (`linear` or `linearendow`/`linearcreation`) is in use |
| `avalt` | Behavior "average alter" influence effect - own value moves toward network neighbors' own average value; requires `behavior()` |
| `avaltendow` `avaltcreation` | `avalt` split into its ENDOWMENT/CREATION roles - same mechanism/rules as `linearendow`/`linearcreation` |
| `avsim` | Behavior "average similarity" influence effect - own value moves to maximize average similarity to network neighbors' own values, net of a data-derived centering constant; requires `behavior()` |
| `avsimendow` `avsimcreation` | `avsim` split into its ENDOWMENT/CREATION roles - same mechanism/rules as `linearendow`/`linearcreation` |
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
| `ratecov(varname)` | Let a node covariate raise or lower each actor's own opportunity to make a network change, instead of every actor sharing one constant rate for the period - actor i's own rate becomes *rate**exp(**ratecovcoef****varname*[i]). The coefficient is estimated jointly with every other effect. Not yet supported combined with co-evolution, multi-wave models, `present()`, `missnet()`, or `symmetric`. See [Remarks](nwsaom_remarks) |
| `ratecovcoef(real)` | Starting value for `ratecov()`'s own jointly-estimated coefficient (default 0) |

**Undirected/symmetric relations**

| | |
|---|---|
| `symmetric` | Fit a relation where every tie is symmetric (x_ij always equals x_ji), using a mutual-consent ministep: a candidate tie change is only made when BOTH actors' own preferences favor it. Requires the input data to already be tie-symmetric at both waves (this option changes how ties are simulated, it does not symmetrize your data). Several effects are not meaningful once every tie is forced symmetric and are rejected outright - see [Remarks](nwsaom_remarks) for the full list. v1 scope: exactly two waves (`wave1()`/`wave2()`, not `waves()`), network-only (no `behavior()`); combinable with `present()`, `missnet()`, and `ratecov()` (see [Remarks](nwsaom_remarks)) |
| `symtype(string)` | Which mutual-consent rule `symmetric` uses: **joint** (default) accepts a change when the sum of both actors' own preferences is favorable; **force** lets the initiating actor alone decide, ignoring the other actor's own preference; **agree** requires both actors to independently agree when creating a tie, or either one to want it gone when removing one. Requires `symmetric` |

**Estimation control**

| | |
|---|---|
| `rate0(real)` | Accepted for backward compatibility only - **no longer used**; the rate parameter's own starting value is now computed automatically from the observed data via RSiena's own verified closed-form formula (see [Remarks](nwsaom_remarks)) |
| `theta0(numlist)` | Starting values for the eval-parameter vector, one per requested effect IN THE ORDER LISTED IN THE ERROR MESSAGE if omitted or mis-sized (outdegree first, then every other effect in the order its own option appears above); default all zero |
| `k0(int)` | Phase-1 replicate count (Jacobian estimation via the score-function derivative estimator); default 50 |
| `k3(int)` | Phase-3 replicate count (convergence diagnostics and the covariance matrix e(V)); default 1,000 |
| `firstg(real)` | Phase-2 starting gain (Robbins-Monro step size); default 0.2, matching RSiena's own default |
| `seed(int)` | Set the random-number seed before simulating (for reproducibility) |

## Description

`nwsaom` fits a stochastic actor-oriented model (SAOM, Snijders-style) between two or more observed panel waves of the same directed network on a fixed actor set - a fully native Stata/Mata implementation, no R or other external statistical software called at any point. The [RSiena](https://www.stats.ox.ac.uk/~snijders/siena/) package (Ripley, Snijders et al.) was studied in detail as the methodological reference throughout development - both its published manual and, where the manual alone was not enough, its own real R/C++ source (read directly via `gh api` against [github.com/stocnet/rsiena](https://github.com/stocnet/rsiena) during development) - and used, during development only, to certify `nwsaom`'s own independently written implementation against real reference output. `nwsaom` is an independent reimplementation and is not affiliated with or endorsed by the RSiena project.

An SAOM models network change as a sequence of unobserved, actor-driven "ministeps": between consecutive observed waves, actors are activated one at a time (at a rate governed by the model's own rate parameter) and each activated actor may create or drop exactly one of its own outgoing ties, choosing among the available alternatives (including "no change") via a multinomial-logit choice model on a linear combination of effect-specific "change statistics", weighted by the effect's own estimated coefficient. This actor-oriented, MYOPIC formulation - an actor's own choice is evaluated purely from that actor's own resulting local network statistic, never from how the choice would affect any OTHER actor's own statistics - is what genuinely distinguishes an SAOM from an ERGM (see [nwergm](nwergm)): an ERGM has no actors or ministeps at all, only a single global probability distribution over entire graphs. Coefficients are estimated by the Method of Moments via Robbins-Monro stochastic approximation (RSiena's own default estimation algorithm), not maximum likelihood.

## Remarks

See [nwsaom_remarks](nwsaom_remarks) for the full effect-derivation library (every effect's own ministep formula and how it was verified against RSiena's real source), interaction/multiplex/co-evolution mechanics, composition-change/missing-data/structural-zero handling, the full performance benchmark, and the estimation-algorithm background (Method-of-Moments phase structure, rate refinement). That material was split into its own file purely to keep this file's own length within Stata's interactive Viewer's rendering limits - it is not optional/secondary content, just relocated.

## Examples

```stata
. nwset, mat((0,1,1,0,1,0\0,0,1,0,0,1\1,0,0,1,0,0\0,0,0,0,1,1\1,0,0,0,0,1\0,1,0,0,0,0)) directed name(wave1)
. nwset, mat((0,1,1,1,1,0\1,0,1,0,0,1\1,1,0,1,0,0\0,0,1,0,1,1\1,0,1,0,0,1\0,1,0,1,0,0)) directed name(wave2)
. nwsaom, wave1(wave1) wave2(wave2) outdegree reciprocity transtrip
. estat gof
```
```stata
. nwsaom, waves(wave1 wave2 wave3) outdegree transties balance
```
```stata
. nwsaom, wave1(wave1) wave2(wave2) outdegree isolatenet outiso
```
```stata
. nwsaom, wave1(wave1) wave2(wave2) outdegree reciprocity behavior(b1 b2) linear avalt
. estat gof
```
```stata
. nwsaom, waves(wave1 wave2 wave3) outdegree behavior(b1 b2 b3) linear avalt
```
```stata
. nwsaom, waves(wave1 wave2 wave3) outdegree behavior(b1 b2 b3) linear avsim
```
```stata
. nwsaom, wave1(wave1) wave2(wave2) outdegree reciprocity behavior(b1 b2) linearendow linearcreation
```
```stata
. nwsaom, wave1(wave1) wave2(wave2) outdegree reciprocity present(p1 p2)
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
- **e(rate)** estimated network rate parameter (wave1()/wave2() path only) - REFINED for a plain network-only fit with no `present()`/`missnet()`/`missbeh()`; the closed-form STARTING value only for a co-evolution fit (real RSiena's own default behavior for 2+ dependent variables), a `present()` fit (composition change forces unconditional estimation - see [Estimation](nwsaom_remarks) in nwsaom_remarks), or a missing-data fit (`missnet()`/`missbeh()` - see [Missing data](nwsaom_remarks) in nwsaom_remarks)
- **e(rate_tratio)** network rate parameter's own phase-3 convergence t-ratio (wave1()/wave2() path only - see [Estimation](nwsaom_remarks) in nwsaom_remarks)
- **e(rate_se)** standard error of the REFINED e(rate) (plain network-only fits with no `present()`/`missnet()`/`missbeh()` only - 0 for a co-evolution, `present()`, or missing-data fit, whose e(rate) is not refined)
- **e(has_behavior)** 1 if this is a co-evolution fit (`behavior()` specified), 0 otherwise
- **e(p_net)** number of network-side eval-parameter coefficients (co-evolution fits only; the first e(p_net) columns of e(b)/e(V)/e(tratio) are the network's own, the remainder the behavior's own, prefixed `beh_`)
- **e(rate_beh)** estimated behavior rate parameter (co-evolution, wave1()/wave2() path only) - closed-form starting value, not refined (see [Estimation](nwsaom_remarks) in nwsaom_remarks)
- **e(rate_beh_tratio)** behavior rate parameter's own phase-3 convergence t-ratio (co-evolution, wave1()/wave2() path only)

**Macros**

- **e(cmd)** **nwsaom**
- **e(title)** title of estimation
- **e(waves)** list of wave network names, in temporal order
- **e(wave1)** first wave name (wave1()/wave2() path only)
- **e(wave2)** second wave name (wave1()/wave2() path only)
- **e(behavior)** list of behavior variable names, one per wave, in temporal order (co-evolution fits only)
- **e(estat_cmd)** **nwsaom_estat** (postestimation dispatch)

**Matrices**

- **e(b)** coefficient vector (eval parameters only - excludes rate; network then behavior for a co-evolution fit, see e(p_net) above)
- **e(V)** variance-covariance matrix (eval parameters only)
- **e(tratio)** 1 x nparam phase-3 convergence t-ratios, one per eval-parameter coefficient
- **e(rates)** 1 x (nwaves-1) per-period estimated network rate parameters (waves() path only) - REFINED for a plain network-only fit with no `present()`/`missnet()`/`missbeh()`; closed-form STARTING values only for a co-evolution, `present()`, or missing-data fit
- **e(rate_tratios)** 1 x (nwaves-1) per-period network rate convergence t-ratios (waves() path only)
- **e(rates_se)** 1 x (nwaves-1) per-period standard errors of the REFINED e(rates) (plain network-only fits with no `present()`/`missnet()`/`missbeh()` only - 0 otherwise)
- **e(rates_beh)** 1 x (nwaves-1) per-period estimated behavior rate parameters (co-evolution, waves() path only)
- **e(rate_beh_tratios)** 1 x (nwaves-1) per-period behavior rate convergence t-ratios (co-evolution, waves() path only)

`estat gof` stores the following in `r()`, one pair per requested statistic (default **outdegree**/**indegree**/**geodesic**):

**Scalars**

- **r(p_*stat*)** empirical Mahalanobis-distance test p-value for that statistic
- **r(mhd_*stat*)** observed vector's own Mahalanobis distance from the simulated mean

## References

Snijders, T.A.B. (2001). The statistical evaluation of social network dynamics. *Sociological Methodology*, 31(1), 361-395. (SAOM/Method of Moments)

Snijders, T.A.B., van de Bunt, G.G., Steglich, C.E.G. (2010). Introduction to stochastic actor-based models for network dynamics. *Social Networks*, 32(1), 44-60.

Ripley, R.M., Snijders, T.A.B., Boda, Z., Voros, A., Preciado, P. (2024). Manual for RSiena. University of Oxford. [stats.ox.ac.uk/~snijders/siena/](https://www.stats.ox.ac.uk/~snijders/siena/)

Lospinoso, J., Snijders, T.A.B. (2019). Goodness of fit for stochastic actor-oriented models. *Methodological Innovations*, 12(3).

`nwsaom` is an independent, native reimplementation and is not affiliated with or endorsed by the RSiena project.

## See also

- [nwergm](nwergm), [nwset](nwset), [nwrandom](nwrandom)
