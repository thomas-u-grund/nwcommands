---
title: "nwrem"
parent: "Command reference"
nav_exclude: true
search_exclude: false
description: "Relational event model (ordinal partial likelihood, MLE)"
---

# `nwrem`

Relational event model (ordinal partial likelihood, MLE)

## Syntax

```stata
nwrem
[netname]
,
[nodsnd
nidrec
nidsnd
nodrec
ntdegsnd
ntdegrec
frpsndsnd
frrecsnd
covsnd(varname)
covrec(varname)
covint(varname)
covevent(netname)
rsndsnd
rrecsnd
seed(#)]
```

**Degree effects**

| | |
|---|---|
| `nodsnd` | sender's normalized out-degree affects the sending rate (share of all prior events in which this actor was the sender) |
| `nidrec` | receiver's normalized in-degree affects the receiving rate (share of all prior events in which this actor was the receiver) |
| `nidsnd` | sender's normalized in-degree affects the sending rate |
| `nodrec` | receiver's normalized out-degree affects the receiving rate |
| `ntdegsnd` | sender's normalized total degree (in+out, averaged) affects the sending rate |
| `ntdegrec` | receiver's normalized total degree (in+out, averaged) affects the receiving rate |

**Inertia effects**

| | |
|---|---|
| `frpsndsnd` | "inertia": the fraction of the sender's own past sends that went specifically to this receiver affects the sending rate to that receiver |
| `frrecsnd` | "reciprocity of receipt": the fraction of the sender's own past receipts that came specifically from this receiver affects the sending rate to that receiver |

**Covariate effects**

| | |
|---|---|
| `covsnd(varname)` | a per-actor covariate affects the sending rate (an "ego" effect - *varname* is read from the CURRENT dataset, one row per actor, in *netname*'s own actor order - see [nwload](nwload)'s `xvars` option below) |
| `covrec(varname)` | a per-actor covariate affects the receiving rate (an "alter" effect) |
| `covint(varname)` | a per-actor covariate affects both the sending and the receiving rate together (the same variable, one shared coefficient) |
| `covevent(netname)` | a pairwise (dyad-level) covariate affects the rate of the event from sender to receiver directly - *netname* must already be a loaded network with the SAME actors as the event network, one value per ordered (sender,receiver) pair (read from its own tie values, exactly like [nwergm](nwergm)'s `edgecov()`) |

**Recency effects**

| | |
|---|---|
| `rsndsnd` | "recency of sending": how RECENTLY (not how often) the sender previously sent to this receiver affects the sending rate to that receiver again (1/rank among the sender's own past receivers, most recent = rank 1; 0 if never sent to before) |
| `rrecsnd` | "recency of receipt": how RECENTLY (not how often) the sender previously received from this receiver affects the sending rate back to that receiver (1/rank among the sender's own past senders, most recent = rank 1; 0 if never received from before) - a recency-based reciprocity effect |

| | |
|---|---|
| `seed(#)` | set the random-number seed before estimation (affects only which of several internal optimizer restarts is tried first when the default starting point fails to converge - never affects the reported MLE once a fit succeeds) |

## Description

`nwrem` fits a relational event model (Butts 2008, "A Relational Event Framework for Social Action," *Sociological Methodology* 38(1), 155-200) to a timestamped sequence of dyadic events, via the ordinal partial likelihood: at each event, the model asks "given that some event happened next, which of the *n*(*n*-1) possible ordered actor pairs was it," and estimates which actor-level effects make the realized event more likely relative to every other pair that could have happened instead - the same conditional-likelihood logic Cox proportional-hazards models use.

Unlike [nwergm](nwergm) (static structure) and [nwsaom](nwsaom) (discrete panel-wave evolution), `nwrem` works directly on a raw, continuous-time event stream - no snapshot or aggregation step. It requires *netname* to already be declared as an **event**-type temporal network via [nwset](nwset)'s `eventtime(varname)` option:

```stata
. nwset sender receiver, eventtime(t) name(mynet)
. nwrem mynet, nodsnd nidrec
```
**Speed**: on direct head-to-head wall-clock benchmarks against R's own `relevent::rem.dyad()` 1.2-1 (identical data, identical effect set, `ordinal=TRUE`, `fit.method="MLE"` on the R side; `nwrem`'s own pure-Mata engine on this side - **no native C backend yet**): a 2-effect model (**nodsnd**+**nidrec**, 30 actors, 2000 events) runs consistently around 0.8s vs. R's 1.54s - roughly 2x faster, with little run-to-run variation. The full 8-effect degree+inertia model on the identical data is faster than R on **every** repeated trial measured, but with real variation run to run - 9.2s to 48.6s across thirteen repeated fits (two independent benchmark sessions), median around 39s, against R's own single measured 107.75s: roughly **2.5-3x faster** typically, up to **12x** when the optimizer's first attempt happens to converge directly. The variation itself is a disclosed, understood property, not noise to average away: this particular 8-effect model sits on the degree-effect family's own collinearity ridge (see the note on precision below), so `nwrem`'s own retry-based optimizer sometimes needs only one attempt and sometimes several before converging - R's own single `optim(BFGS)` call has no equivalent retry strategy for the same ridge, which is why `nwrem` still wins on every trial despite its own variation. See `dev/rem_benchmark.R`/`.do` and `dev/rem_benchmark_multi.R`/`.do` in the package's own source for the exact scripts.

`nwrem` fits any combination of the 14 effects above (at least one required). There is deliberately no intercept option - a term constant across every candidate pair at a given event cancels out exactly in the ordinal likelihood's own normalization (the same reason Cox proportional-hazards models have no identifiable baseline intercept), so one is never estimable here regardless of what is requested. Effects not yet implemented (triadic/shared-partner effects, fixed effects, the full non-ordinal/waiting-time likelihood, Bayesian estimation) are tracked, not silently missing - see the package's own development roadmap for what is planned next.

**rsndsnd**/**rrecsnd** are different from **frpsndsnd**/**frrecsnd**: the latter measure HOW OFTEN a sender has contacted a given partner relative to their total activity (a fraction); **rsndsnd**/**rrecsnd** measure HOW RECENTLY, via reciprocal RANK among that sender's own past contacts, ignoring how many times contact happened before or since. A sender who contacted a partner once, very recently, scores as high on **rsndsnd** for that partner as one who contacted them constantly and most recently - only the ordering matters, not the count.

**Covariate effects** require the current Stata dataset, at the time `nwrem` is called, to have exactly one row per actor in *netname*'s own actor order - NOT the event-level dataset *netname* itself was declared from. Use [nwload](nwload)'s `xvars` option first to load that per-node dataset:

```stata
. nwload mynet, xvars
. gen seniority = ...
. nwrem mynet, nodsnd covsnd(seniority)
```
This mirrors [nwsaom](nwsaom)'s own `nodecov()` convention exactly, not a new mechanism specific to `nwrem`.

**covevent()** is different: it is a per-*pair* (not per-actor) covariate, so it is read from ANOTHER already-loaded network's own tie values rather than from a Stata variable - the same convention [nwergm](nwergm)'s `edgecov()` already uses for dyadic covariates. Declare the pairwise covariate as its own network first, then reference it by name - **nwset**'s `edgelist` option is required here (`nwset` otherwise reads three bare variables as a wide affiliation matrix, not an edgelist):

```stata
. nwset i j value, name(seatdist) edgelist
. nwrem mynet, nodsnd covevent(seatdist)
```
`covevent(seatdist)` must have the same actors as `mynet`; its tie value for the ordered pair (sender,receiver) enters the sending rate directly for that pair (no ego/alter broadcasting, unlike `covsnd()`/`covrec()`/`covint()`). Because the effect reads (sender,receiver) values directly, **nwset does not auto-symmetrize** an edgelist declaration: an ordered pair with no explicit row gets value 0, even if its reverse pair *was* given a value. For a covariate that is genuinely symmetric (e.g. physical distance), supply BOTH ordered pairs (i,j) and (j,i) explicitly; for one that is genuinely directional (e.g. "i reports to j"), that asymmetry is exactly what **covevent()** is for.

**A note on precision**: `nodsnd`/`nidrec`/`nidsnd`/`nodrec`/`ntdegsnd`/ `ntdegrec` are each a running average - the fraction of *all prior events* in which an actor sent/received - and that fraction's cross-actor spread narrows as the event sequence grows (it converges toward 1/*n* for every actor). This means, unlike an ordinary regression covariate, point estimates from these effects can remain noisy even with several thousand events, a genuine property of the effects themselves (verified against a real reference relational-event-model implementation on identical data, not a limitation of this command). Combining several of these degree-type effects in the same model (e.g. `nodsnd` with `nidsnd` and `ntdegsnd` together) can also produce a nearly flat ridge in the likelihood surface along some combination of their coefficients - different starting values can then converge to visibly different individual coefficients while fitting the data almost equally well; check whether the overall model fit (log likelihood) is what actually matters for your question before over-interpreting any single coefficient in that situation. The fitted model reliably improves on the no-effect baseline even when a single point estimate is imprecise; interpret standard errors accordingly and prefer larger event counts where possible.

## Examples

- Fit a relational event model on a small event log:

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
. nwrem chat, nodsnd nidrec
```
(a handful of events on very few actors, as above, has too little information to pin down either coefficient precisely - the wide confidence intervals in this toy example are expected, not a sign of a problem; see this help file's own note on precision above)

- Add an inertia effect (does a sender tend to keep sending to the same recent partner) alongside a degree effect:

```stata
. nwrem chat, nidrec frpsndsnd
```
- Add an actor-attribute covariate effect - does a per-actor variable affect the sending rate:

```stata
. nwload chat, xvars
. gen seniority = _n
. nwrem chat, nodsnd covsnd(seniority)
```
- Add a pairwise covariate effect - does a variable specific to the (sender,receiver) pair
- itself, not to either actor alone, affect the sending rate (seat distance is symmetric, so both
- ordered pairs are given explicitly - see the note on symmetry above):

```stata
. clear
. input i j value
. 1 2 5
. 2 1 5
. 1 3 2
. 3 1 2
. 2 3 8
. 3 2 8
. end
. nwset i j value, name(seatdist) edgelist
. nwrem chat, nodsnd covevent(seatdist)
```
- Add a recency effect - does a sender tend to return to whoever they contacted most recently,
- regardless of how often (contrast with `frpsndsnd` above, which is about frequency):

```stata
. nwrem chat, nodsnd rsndsnd
```

## Stored results

**Scalars**

- **e(N)** number of events
- **e(nodes)** number of actors
- **e(ll)** log likelihood at the MLE

**Macros**

- **e(cmd)** **nwrem**
- **e(title)** "Relational event model (ordinal partial likelihood, MLE)"
- **e(depvar)** name of the event network fit

**Matrices**

- **e(b)** coefficient vector
- **e(V)** variance-covariance matrix (observed information)
