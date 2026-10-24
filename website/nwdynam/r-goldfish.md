---
title: "DyNAM: nwdynam and goldfish"
parent: "nwdynam (DyNAM)"
nav_order: 5
permalink: /nwdynam/r-goldfish/
description: "What nwdynam shares with the R package goldfish, what it lacks, how it was compared, and a translation table from goldfish to nwdynam."
---

# nwdynam and goldfish

`nwdynam` follows the R package goldfish and exists because of it. The dynamic network actor model is due to
Christoph Stadtfeld and Per Block (2017); goldfish (Stadtfeld, Hollway, Block and many contributors) is the
reference implementation, and `nwdynam` takes its effect definitions, its likelihoods and its way of estimating from
that work. `nwdynam` is not affiliated with or endorsed by the goldfish project, and errors in `nwdynam` are the
author's. If you can use R, goldfish remains the reference and the more complete program; `nwdynam` is for
people who work in Stata, or prefer it.

The software was developed with Claude Code (Anthropic), an AI coding assistant, working under the author's direction;
its correctness rests on numerical comparison with the R package.

`nwdynam` is distributed under the GNU General Public License, version 3, as goldfish is (GPL version 3 or later).

## What is the same

- **The model.** A rate sub-model (which actor acts next) and a choice sub-model (whom the actor chooses), plus the
  coordination sub-model for undirected events (`submodel(choice_coordination)`).
- **The effects.** The effects of the choice and rate models that are listed in the table below, with the same definitions.
- **The estimation.** Maximum likelihood with the ordinal partial likelihood (only the order of events); with `intercept`,
  the continuous-time hazard of the rate model.
- **The comparison.** Coefficients and log likelihoods were compared with goldfish 1.6.12 on the Social Evolution
  data that goldfish ships (84 actors, 439 phone calls) and on small hand-built examples. On those data the choice model
  with `inertia`, `recip` and `indeg` gives 5.3656, 1.3894 and -0.1735 in both programs (see
  [Tutorial 1](../tutorial-1-first-dynam/)). The compiled plugin was checked against the Mata implementation of the
  package to floating-point round-off.

## What differs

Things that goldfish does and `nwdynam` does not (yet) do, as documented in `help nwdynam`:

- the effect `tertiusDiff`, the mixed variants of the closure effects that use two networks, and closure effects through
  an exogenous network;
- a second network in `tie()` that itself changes over time (`nwdynam` accepts a static network only);
- the `ignoreRep` argument and, for `tie()`, the arguments `weighted` and `window`;
- windowed rate effects (`indegwindow()`, `outdegwindow()`) in combination with `intercept`;
- windows on `tertius()`, and weighted or windowed versions in `choice_coordination`;
- attribute effects (`same`, `diff`, `sim`, `ego`, `alter`, `egoalterint`, `tertius`) and closure effects in two-mode networks;
- `opportunities()` in the same call as an attribute effect (the two need different data layouts);
- time-varying covariates: attributes are fixed over the log.

The help file documents no goodness-of-fit, simulation or Bayesian command. The estimates and the log likelihood are
the output. Data preparation is also different: instead of goldfish's objects (`defineNodes`, `defineNetwork`,
`linkEvents`, `defineDependentEvents`) you declare an event list with `nwset ..., eventtime()` and read attributes
from the dataset of the actors (`nwload ..., xvars`). Before using `nwdynam` for an important result, run the same model in goldfish.

## Translation table

| goldfish | nwdynam |
|---|---|
| `defineNodes()`, `defineNetwork()`, `linkEvents()`, `defineDependentEvents()` | `nwset sender receiver, directed eventtime(t) name(net)`; isolates with `nwaddnodes`; attributes with `nwload net, xvars` |
| `estimate(f, model = "DyNAM", subModel = "choice")` | `nwdynam net` (the default sub-model) |
| `... subModel = "rate"` | `nwdynam net, submodel(rate)` |
| `... subModel = "choice_coordination"` | `nwdynam net, submodel(choice_coordination)` on an undirected network |
| `inertia`, `recip` | `inertia`, `recip` |
| `indeg`, `outdeg` | `indeg`, `outdeg` (both sub-models) |
| `trans`, `cycle`, `commonSender`, `commonReceiver`, `four` | `trans`, `cycle`, `commonsender`, `commonreceiver`, `four` |
| `nodeTrans` | `nodetrans` |
| `same(attr)`, `diff(attr)`, `sim(attr)` | `same(var)`, `diff(var)`, `sim(var)` |
| `ego(attr)` (rate), `alter(attr)` (choice) | `ego(var)`, `alter(var)` |
| `egoAlterInt(attr)` | `egoalterint(var1 var2)` |
| `tertius(attr)` | `tertius(var)` |
| `tie(network)` | `tie(netname)` |
| `window = w` on an effect | `inertiawindow(#)`, `recipwindow(#)`, `indegwindow(#)`, `outdegwindow(#)` |
| `weighted = TRUE` on an effect | `weightedinertia`, `weightedrecip`, `weightedindeg`, `weightedoutdeg` |
| a leading `1 +` in the formula (intercept, rate model) | `intercept` with `submodel(rate)` |
| `opportunitiesList` in `estimationInit` | `opportunities(evvar actvar)` |
| `summary()` of the estimate | the table printed by `nwdynam`; `e(b)`, `e(V)`, `e(ll)`, `e(N)`, `e(nodes)` |

Without any effect option `nwdynam` fits `inertia`, `recip` and `indeg` for the choice model and `indeg` and
`outdeg` for the rate model; naming any effect restricts the model to the effects named. In goldfish the formula
always lists the effects.

## Acknowledgment

`nwdynam` is a port of ideas, definitions and methods that others developed. If you use it, please cite the DyNAM
papers and goldfish, as on the page [How to cite](../citation/).
