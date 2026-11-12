---
title: "Tutorial 11: Simulation and what-if analysis"
parent: "nwsaom (SAOM)"
nav_order: 12
description: "Use a fitted stochastic actor-oriented model to simulate networks (estat simulate, nwsaom simulate) and to ask what a network would look like if an effect did not operate (estat mems)."
---

# Tutorial 11: Simulation and what-if analysis

**Goal.** A SAOM is a *model of a process*, so it can be run forward. This tutorial shows how to simulate networks from a fitted
model, how to simulate at coefficients that you choose, and how to ask a what-if question: how different would the network be
if one of the effects were switched off?

**Data.** The Glasgow friendship data, first wave to second wave. The commands were run with `nwsaom` 1.6.0 and the core 3.22.0 in
Stata 17. The complete script and log are in [example.do](example.do) and [example.log](example.log).

## Simulating the fitted model: estat simulate

Fit a model for one period:

```stata
. nwsaom, waves(glasgow1 glasgow2) outdegree reciprocity transtrip seed(4)

SAOM (Method of Moments, conditional), waves: glasgow1 glasgow2
Actors: 50                             Periods: 1

------------------------------------------------------------------------------
glasgow1_t~2 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.528005    .135743   -18.62   0.000    -2.794057   -2.261954
 reciprocity |   2.126118   .2558338     8.31   0.000     1.624693    2.627543
   transtrip |   .5977949   .1096539     5.45   0.000     .3828772    .8127125
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

-------------------------
             |   period1 
-------------+-----------
        rate |    6.1337
          se |    1.0059
-------------------------
Overall maximum convergence ratio: 0.117 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

`estat simulate` starts at the observed first wave and lets the process run for the length of the period, with the fitted
coefficients and the fitted rate, 100 times:

```stata
. estat simulate, nsim(100) seed(5)
Simulation from the fitted model: 100 replication(s) of 1 period(s)

------------------------------------
   Statistic |       Sim       Obs
-------------+----------------------
Period 1     |
        Ties |     115.9       116
      Mutual |      35.5        35
  Transitive |      92.7        88
------------------------------------
Sim is the mean over the replications; Obs is the observed end wave.
```

The line compares the *average* simulated end network with the observed one: 115.9 ties against 116 observed, 35.5 mutual dyads against 35, and 92.7 transitive
triples against 88. A model that reproduces such summaries is a reasonable description of the process, the idea behind
[Tutorial 3](../tutorial-3-goodness-of-fit/). The results are in `r(sim)` (one row per simulated network) and `r(obs)`; the spread of the simulated
networks is as informative as their average:

```stata
. matrix S = r(sim)
```

The number of ties varies from one simulated network to the next with a standard deviation of 18, the number of mutual dyads with 8, and the number
of transitive triples with 54: clustering is the most variable feature of the simulated networks. With `generate(sim)` the simulated end networks
are kept as networks called `sim_1_p1`, `sim_2_p1`, ... (simulation number, then the period). Here is how the first simulated network differs from the
second observed wave:

```stata
. nwsaom describe, waves(glasgow2 sim_1_p1)

Network data                        Number of actors  =        50
Directed                            Number of waves   =         2

------------------------------------------------------------------
        Wave |       Ties     Density   Avg. degree
-------------+----------------------------------------------------
           1 |        116      0.0473         2.320
           2 |         96      0.0392         1.920
------------------------------------------------------------------

------------------------------------------------------------------
      Period |    Kept   Created  Dissolved   Jaccard   Hamming
-------------+----------------------------------------------------
        1->2 |      31        65         85     0.171       150
------------------------------------------------------------------
Note: Jaccard < 0.3 in period 1->2; few ties stay, the data say little about change.
```

Only 31 ties are present in both the observed second wave (116 ties) and this simulated network (96 ties), so the Jaccard index is 0.17. That shows how much room for chance the process leaves: one
simulated network is one possibility, not a prediction, and this one happens to be a below-average draw (96 ties against an average of 116).

## Simulating at chosen coefficients: nwsaom simulate

You do not need a fit to simulate. `nwsaom simulate` takes the same model description as `nwsaom`, together with the coefficients (`theta()`) and
the rates (`rates()`; one per period), and runs the process without estimating anything. The coefficients are listed in the order of the coefficient table of a fit of the same model:

```stata
. nwsaom simulate, waves(glasgow1 glasgow2) outdegree reciprocity transtrip theta(-2.7 2.4 0.6) rate
> s(6) nsim(100) seed(5)
Simulation from the fitted model: 100 replication(s) of 1 period(s)

------------------------------------
   Statistic |       Sim       Obs
-------------+----------------------
Period 1     |
        Ties |     105.4       116
      Mutual |      33.9        35
  Transitive |      72.6        88
------------------------------------
Sim is the mean over the replications; Obs is the observed end wave.
```

With coefficients close to the estimates, the simulated networks resemble the observed second wave (105 ties on average against 116, 34 mutual dyads against 35, 73 transitive triples against 88). Now the same world without any
tendency to reciprocate (the second coefficient is zero):

```stata
. nwsaom simulate, waves(glasgow1 glasgow2) outdegree reciprocity transtrip theta(-2.7 0 0.6) rates(
> 6) nsim(100) seed(5)
Simulation from the fitted model: 100 replication(s) of 1 period(s)

------------------------------------
   Statistic |       Sim       Obs
-------------+----------------------
Period 1     |
        Ties |      39.8       116
      Mutual |       0.6        35
  Transitive |       1.2        88
------------------------------------
Sim is the mean over the replications; Obs is the observed end wave.
```

Without reciprocity, the simulated networks have only 40 ties (against 105), almost no mutual dyads (0.6) and hardly any
transitive triples (1.2). This is a useful way to learn what an effect does in a model. It is also how to check a model against a known truth: simulate data
with known coefficients, fit the model to the simulated data, and see whether the coefficients come back.

## What if an effect did not operate? estat mems

The question "what would the network look like without reciprocity?" can be asked more carefully. `estat mems` (after Duxbury's "micro effects on macro
structure") draws coefficient vectors from the sampling distribution of the estimates, switches one of the coefficients off (or scales it), simulates from each, and compares a
**summary of the whole network that you define**, for example the number of mutual dyads. You supply the summary as a small program that receives the name of a network
and returns a number in `r(stat)`:

```stata
. capture program drop mutualties
. program define mutualties, rclass
.     args netname
.     nwtomata `netname', mat(MM)
.     mata: st_numscalar("__mut", sum(MM :* MM') / 2)
.     return scalar stat = scalar(__mut)
. end
```

```stata
. quietly nwsaom, waves(glasgow1 glasgow2) outdegree reciprocity transtrip seed(4)

. estat mems, effect(reciprocity) macro(mutualties) nsim(100) seed(1)
interval 0: ..
interval 1: ..

MEMS: micro effects on macro structure (Duxbury), macro statistic mutualties
Micro process: reciprocity  Interval: 0 1  nsim: 100
-----------------------------------------------------------------------
             |  Estimate  Std. dev.    [95% conf. interval]  MC p-value
-------------+---------------------------------------------------------
        MEMS |   37.1000    11.8973     17.0000     62.6250      0.0000
Prop. change |    0.9716
-----------------------------------------------------------------------
MEMS: mean difference in mutualties between interval=1 and interval=0.
Prop. change: that difference as a share of the value at interval=1.
MC p-value: share of draws with the opposite sign. Each draw is simulated
independently (no common random numbers); no E-value sensitivity bound.
```

With reciprocity at its fitted strength there are on average 37 more mutual dyads than without it (95% interval from 17 to 63). The proportional change, 0.97, says
that about 97% of the mutual dyads at the fitted strength would be missing without the reciprocity effect. `estat mems` is available after two-wave fits of a network (no behavior).

## Things to try

- Simulate with `transtrip` set to 0 and compare the number of transitive triples.
- Use `rates(3)` and `rates(12)` and see how the amount of change responds.
- Write a summary program for something else, for instance the density or the number of isolates, and give it to `estat mems`.
- Simulate a three-wave model: give `rates()` one value per period.

## Where next

[Tutorial 12](../tutorial-12-estimation-speed/) explains conditional and unconditional estimation and how to speed up and control the estimation.
