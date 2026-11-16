---
title: "nwdynam and goldfish"
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
  data that goldfish ships (84 actors, 439 phone calls), on the first 631 emails of the manufacturing company data used in the
  tutorials and on small hand-built examples. On the email data the choice model
  with `inertia`, `recip` and `indeg` gives 1.7648, 2.9224 and 0.1096 in both programs (see
  [Tutorial 1](../tutorial-1-first-dynam/)). The compiled plugin was checked against the Mata implementation of the
  package to floating-point round-off.

## What differs

Things that goldfish does and `nwdynam` does not do, as documented in `help nwdynam`:

- `ignoreRep` in the rate sub-model (goldfish accepts it; its likelihood could not be reproduced);
- `tertiusDiff` with time-varying attributes or in two-mode networks;
- `tertius`, `indeg`, `outdeg`, `recip` and `nodeTrans` computed through another network (the closure effects, `tie`
  and the mixed closures are supported);
- effects of two-mode networks that goldfish itself cannot compute: `nwdynam` refuses them with a message.

Everything else that goldfish 1.6.12 offers for DyNAMs is supported, with estimates, standard errors and log likelihoods
that agree with goldfish to 1e-6 on several hundred random event logs (for `choice_coordination` the standard errors are
numerical in both programs and agree to 10%). goldfish has no goodness-of-fit or simulation function, and `nwdynam` adds
none: the postestimation commands are those that goldfish has (see the table). Data preparation is also different: instead of goldfish's objects (`defineNodes`, `defineNetwork`,
`linkEvents`, `defineDependentEvents`) you declare an event list with `nwset ..., eventtime()` (with an optional third
variable for the value of each event) and read attributes
from the dataset of the actors (`nwload ..., xvars`). Changes of an attribute over time, and actors who join or leave, are further event lists (see the table). Absent actors are outside the risk sets; a join or leave at the time of an event counts for that event; an event or covariate change of an absent actor is an error; actors without any event of their own must be added with `nwaddnodes`. Before using `nwdynam` for an important result, run the same model in goldfish.

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
| `tie(network)` (also a network that changes over time; `weighted`, `window`, `ignoreRep`) | `tie(netname)`; through another network `netterms(tie(netname) ...)` with the options `window(#)`, `weighted`, `ignorerep` |
| `trans`, `cycle`, `commonSender`, `commonReceiver`, `four` through another network | `netterms(trans(netname) cycle(netname) ...)` |
| `mixedTrans`, `mixedCycle`, `mixedCommonSender`, `mixedCommonReceiver` | `netterms(mixedtrans(net1 net2) ...)` and the other mixed terms |
| `tertiusDiff(attr)` | `tertiusdiff(var [net])` |
| `ignoreRep = TRUE` on a built-in effect | `ignorerep(effects)` |
| a window on `tertius` | `tertiuswindow(#)` |
| `opportunitiesList` with attribute effects | `opportunities(evvar actvar) oppframe(framename)` |
| `logLik()`, `AIC()`, `BIC()` | `estat ic` |
| `returnIntervalLogL = TRUE` | `estat eventlik` |
| `returnEventProbabilities = TRUE` | `estat eventprob` |
| `examineOutliers()` (Hampel, IQR, Top) | `estat outliers` |
| `examineChangepoints()` (PELT, AMOC, BinSeg) | `estat changepoints` |
| `window = w` on an effect | `inertiawindow(#)`, `recipwindow(#)`, `indegwindow(#)`, `outdegwindow(#)` |
| `weighted = TRUE` on an effect | `weightedinertia`, `weightedrecip`, `weightedindeg`, `weightedoutdeg` |
| `weighted = TRUE, window = w` on an effect | a weighted effect with its own window, for example `weightedinertia inertiawindow(#)` |
| `linkEvents(nodes, changeEvents, attribute = "x")` with `replace` or `increment` columns (time-varying attributes) | the changes of `x` as an event list in which sender and receiver are the same actor and the value is the new value: `nwset id id2 value, eventtime(t) selfloop name(xchg)` (`id2` a copy of `id`), then `change(x xchg)`; `increment` makes the values increments |
| `defineNodes(..., present = TRUE/FALSE)` (composition change) | `present(var)`, a 0/1 variable with one row per actor in the actor dataset (default: everybody present) |
| `linkEvents(nodes, changeEvent = comp, attribute = "present")` with `replace` TRUE/FALSE | `compchange(net)`, an event network made with `nwset id id2 value, eventtime(t) selfloop name(net)`; value 1 = the actor joins, 0 = it leaves |
| `increment` of an event (`linkEvents()`) | a value variable: `nwset sender receiver value, directed eventtime(t)`; without it every event has the value 1 |
| a leading `1 +` in the formula (intercept, rate model) | `intercept` with `submodel(rate)` |
| `opportunitiesList` in `estimationInit` | `opportunities(evvar actvar)` |
| `summary()` of the estimate | the table printed by `nwdynam`; `e(b)`, `e(V)`, `e(ll)`, `e(N)`, `e(nodes)` |

Without any effect option `nwdynam` fits `inertia`, `recip` and `indeg` for the choice model and `indeg` and
`outdeg` for the rate model; naming any effect restricts the model to the effects named. In goldfish the formula
always lists the effects.

## Acknowledgment

`nwdynam` is a port of ideas, definitions and methods that others developed. If you use it, please cite the DyNAM
papers and goldfish, as on the page [How to cite](../citation/). The change point methods of `estat changepoints`
are a port of the R package changepoint (Killick, Haynes, Eckley, Fearnhead and Lee; GPL), which goldfish calls for the same purpose.
