---
title: "Tutorial 19: Longitudinal Models: An Overview"
parent: "nwcommands (core)"
nav_order: 19
description: "Stochastic actor-oriented models (nwsaom), relational event models (nwrem) and dynamic network actor models (nwdynam): installing the packages and a first model of each."
---

# Tutorial 19: Longitudinal Models: An Overview

The [first ERGM tutorial](/nwergm/tutorial-1-first-ergm/) modeled a single, static network. Three model packages
for network *change* build on the core, each for a different kind of longitudinal data:

| Package | Model | Data |
|---|---|---|
| `nwsaom` | stochastic actor-oriented model (SAOM) | two or more observed panel waves |
| `nwrem` | relational event model (REM) | a timestamped stream of events |
| `nwdynam` | dynamic network actor model (DyNAM) | a timestamped stream of events |

## Installing the packages

Each is a separate GPL-3 package that needs the core `nwcommands`
(see [Installation & Setup](../01-installation-setup/)):

```stata
nwinstall, models
```

for all four model packages at once (`nwinstall, everything` installs the core as well; a single package: `nwinstall, modelpkg(nwsaom)`). Each package reports its own release
(and stores it in `r(version)`):

```stata
. nwsaom version
nwsaom version 1.6.0, 13nov2026
```

```stata
. nwrem version
nwrem version 1.1.0, 13nov2026
```

```stata
. nwdynam version
nwdynam version 1.3.0, 13nov2026
```


The examples below were run with nwsaom 1.6.0, nwrem 1.1.0, nwdynam 1.3.0 and the core `nwcommands` 3.22.0.

## Stochastic actor-oriented models (SAOM)

> **Full nwsaom tutorials.** This page is an overview. `nwsaom` has its own section with thirteen worked tutorials, each with real output:
> 1. [A first SAOM](../../nwsaom/tutorial-1-first-saom/)
> 2. [Convergence](../../nwsaom/tutorial-2-convergence/)
> 3. [Goodness of fit](../../nwsaom/tutorial-3-goodness-of-fit/)
> 4. [Selection and influence](../../nwsaom/tutorial-4-selection-influence/)
> 5. [Testing and comparing](../../nwsaom/tutorial-5-testing-comparing/)
> 6. [Beyond the basic model](../../nwsaom/tutorial-6-beyond/)
> 7. [Changing actor sets and missing data](../../nwsaom/tutorial-7-composition-missing/)
> 8. [Time-varying and dyadic covariates](../../nwsaom/tutorial-8-covariates/)
> 9. [Undirected and two-mode networks](../../nwsaom/tutorial-9-undirected-twomode/)
> 10. [Endowment, creation, interactions and rate effects](../../nwsaom/tutorial-10-endowment-interaction-rate/)
> 11. [Simulation and what-if analysis](../../nwsaom/tutorial-11-simulation/)
> 12. [Conditional and unconditional estimation, threads and speed](../../nwsaom/tutorial-12-estimation-speed/)
> 13. [Combining several groups with a meta-analysis](../../nwsaom/tutorial-13-meta-analysis/)
> 14. [Several groups at once](../../nwsaom/tutorial-14-several-groups/)
>
> See also [nwsaom and RSiena](../../nwsaom/rsiena/) and the [installation page](../../nwsaom/install/).
{: .note }

An SAOM (`nwsaom`) models change between two or more observed **panel waves** of the same
network as a sequence of unobserved, actor-driven "ministeps": one at a time, an actor is
activated and may create or drop exactly one of its own outgoing ties, choosing among the
alternatives via a model weighted by the same kind of effect coefficients an ERGM uses — but
evaluated *myopically*, from that one actor's own perspective only. That actor-level, myopic
framing is what actually distinguishes an SAOM from an ERGM, not just "two waves instead of one":
an ERGM has no actors or ministeps at all, only a single probability distribution over entire
graphs.

Here are three yearly waves of friendship among 50 pupils in a Scottish school (the Glasgow
data, RSiena's `s50` data), with outdegree, reciprocity, transitive closure, and homophily on
smoking:

```stata
. nwwebuse glasgow, nwclear
```

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip samex(smoke1) seed(1)

SAOM (Method of Moments, conditional), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2

------------------------------------------------------------------------------
glasgow1_t~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.759213   .1516059   -18.20   0.000    -3.056355   -2.462071
 reciprocity |   2.441024    .198022    12.33   0.000     2.052908     2.82914
samex_smoke1 |   .1325353   .1474368     0.90   0.369    -.1564356    .4215062
   transtrip |   .6147119   .0773888     7.94   0.000     .4630327    .7663911
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

------------------------------------
             |   period1    period2 
-------------+----------------------
        rate |    6.5200     5.2401
          se |    1.1516     0.9196
------------------------------------
Overall maximum convergence ratio: 0.103 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```


`outdegree` plays the same baseline-density role `edges` plays in an ERGM. `reciprocity` and
`transtrip` (transitive triplets: a friend of a friend becomes a friend) are both strongly
positive; once they are in the model, pupils show no significant tendency to befriend others with
the same smoking status (`samex_smoke1`). The rate table says how often, on average, a pupil had
the opportunity to change a friendship in each period. The last line checks convergence: an
overall maximum convergence ratio below 0.25 (with every t-ratio below 0.1 it is reported as
good) means the estimates can be used; otherwise, run the model again starting from them with
`theta0()`.

### Checking the model

With three waves, `estat timetest` asks whether an effect had the same size in both periods:

```stata
. estat timetest

Test of time heterogeneity (score-type test)
H0: the parameter of each effect is the same in all periods

---------------------------------------------------------
      Effect |          chi2        df        Prob > chi2
-------------+-------------------------------------------
   outdegree |         0.069         1             0.7928
 reciprocity |         0.975         1             0.3234
samex_smoke1 |         0.147         1             0.7017
   transtrip |         0.460         1             0.4975
-------------+-------------------------------------------
       Joint |         5.428         4             0.2461
---------------------------------------------------------
```


(output shortened to the joint test and the test of each effect). No effect differs significantly
between the periods. `estat importance` says how much each effect contributes to the actors'
choices, as RSiena's `sienaRI` does:

```stata
. estat importance

Relative importance of effects
Expected over the actors at the start of each period
--------------------------------------------------------------------------
      Effect | Estimate  Std. err.    Sigma  Semi-std.     RI p1     RI p2
-------------+------------------------------------------------------------
   outdegree |  -2.7592     0.1516   0.4384    -1.2096    0.4268    0.4980
 reciprocity |   2.4410     0.1980   0.2140     0.5224    0.3744    0.3069
samex_smoke1 |   0.1325     0.1474   0.5043     0.0668    0.0375    0.0357
   transtrip |   0.6147     0.0774   0.6514     0.4004    0.1613    0.1594
-------------+------------------------------------------------------------
   Certainty |                                            0.2667    0.3478
--------------------------------------------------------------------------
RI: share of the effect in the actors' choices. Semi-std.: estimate x sigma.
Certainty: RSiena's R_H, the expected certainty of the choices.
```


Reciprocity and the outdegree term dominate the actors' choices; smoking similarity hardly
matters. Further postestimation includes `estat gof` (goodness of fit), `estat score` (a test of
effects held fixed with `fix()`) and `estat simulate`. This is only an overview; the [nwsaom section](../../nwsaom/) has thirteen worked tutorials, an
installation page and a guide for RSiena users. Beyond this model, `nwsaom` also fits
co-evolving behavior (`behavior()`), several dependent networks (`nwsaom multinet`), maximum
likelihood instead of the method of moments (`ml`), and Bayesian estimation (`nwsaom bayes`); see
[Tutorial 6](../../nwsaom/tutorial-6-beyond/) and the [`nwsaom` reference page](../../reference/nwsaom).

## Relational event models (REM)

An REM (`nwrem`) is built for the opposite kind of data: a raw, continuous-time stream of
individual events (an email sent, a call placed, a message posted) rather than snapshots at a
handful of waves. There's no aggregation step at all — every single event is its own observation,
compared against every other actor-pair that *could* have generated an event at that same moment
but didn't.

```stata
. input sender receiver t

        sender   receiver          t
  1. 1 2 1
  2. 1 3 2
  3. 2 1 3
  4. 1 2 4
  5. 3 2 5
  6. 2 3 6
  7. 1 3 7
  8. 3 1 8
  9. 2 1 9
 10. 1 3 10
 11. end
```

```stata
. nwset sender receiver, directed eventtime(t) name(chat)
```


```stata
. nwrem chat, nodsnd nidrec
------------------------------------------------------------
Relational event model (ordinal partial likelihood, MLE)
Network: chat                          Actors: 3
Events: 10                             Log likelihood:  -15.9033
------------------------------------------------------------
------------------------------------------------------------------------------
        chat | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
      nodsnd |   1.268585   1.354195     0.94   0.349    -1.385589    3.922758
      nidrec |  -5.567767    3.51114    -1.59   0.113    -12.44948    1.313941
------------------------------------------------------------------------------
```


`nodsnd` asks whether a sender's own total out-activity so far predicts sending the next event;
`nidrec` asks the same for a receiver's in-activity. Ten events among three actors is nowhere
near enough data to estimate anything precisely — the point here is the workflow, not the
substantive result.

## Dynamic network actor models (DyNAM)

`nwdynam` works on the same kind of event stream, but splits an event into two decisions: *who*
acts next (the **rate** sub-model) and *whom* that actor chooses (the **choice** sub-model).
The event log above is directed, so we can fit the rate sub-model to it directly; here,
does an actor's in- or out-degree so far predict how soon it acts?

```stata
. nwdynam chat, submodel(rate)
------------------------------------------------------------
Dynamic Network Actor Model - rate sub-model, no intercept (MLE)
Network: chat                          Actors: 3
Events: 10                             Log likelihood:  -10.9009
------------------------------------------------------------
------------------------------------------------------------------------------
        chat | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
       indeg |   .1728906   1.091221     0.16   0.874    -1.965863    2.311645
      outdeg |  -.1728888    .658234    -0.26   0.793    -1.463004    1.117226
------------------------------------------------------------------------------
```


The choice sub-model (the default, `nwdynam chat`, with effects such as `inertia` and `recip`)
is fitted the same way; on ten events among three actors it gives degenerate estimates (huge standard errors), so it is
not shown here — use a real event log. See the [`nwdynam`](../../reference/nwdynam) and
[`nwrem`](../../reference/nwrem) reference pages for the effects each package offers.

## Which one fits your data?

If you observed the network at a handful of discrete points in time (a survey repeated every
year, say), reach for `nwsaom`. If you have a genuine timestamped log of individual interactions,
`nwrem` and `nwdynam` use that timing directly rather than throwing it away by collapsing into
waves.
