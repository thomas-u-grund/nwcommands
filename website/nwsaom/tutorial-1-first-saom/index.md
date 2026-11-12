---
title: "Tutorial 1: A first SAOM"
parent: "nwsaom (SAOM)"
nav_order: 2
description: "Fit a first stochastic actor-oriented model to the Glasgow friendship data with nwsaom and read the coefficient table, the rates and the convergence check."
---

# Tutorial 1: A first SAOM on the Glasgow friendship data

**Goal.** Fit a first stochastic actor-oriented model (SAOM) with `nwsaom`, understand every
part of the output, and know when you can trust it.

**Data.** Three yearly waves of friendship among 50 pupils in a Scottish school, with the pupils'
smoking, drinking and sport at each wave. These are the data that RSiena ships as `s50`. They are
available from the nwcommands website, so no file is needed. You need the core `nwcommands` and the
`nwsaom` package (see [Install](../install/)); the commands below were run with `nwsaom` 1.6.0
and the core 3.22.0. The complete script and log are in
[example.do](example.do) and [example.log](example.log).

## What a SAOM does, in three sentences

Between two observed waves a network changes through many small, unobserved steps. In each step one
actor gets the chance to change one of its own outgoing ties (create one, drop one, or keep things
as they are) and chooses the change that looks best from its own point of view. The model's
coefficients describe what "looks best" means (for example, "ties that are reciprocated are
attractive"), and `nwsaom` finds the coefficients that reproduce the observed change.

## Load and look at the data

```stata
. nwsaom version
nwsaom version 1.6.0, 13nov2026
  core package nwcommands : installed (development copy, no distribution date)
  native plugin           : .../saom_sim_macos.plugin (plugin build 156)
  compared with           : R RSiena 1.6.14
  license                 : GNU GPL-3
```

```stata
. nwwebuse glasgow, nwclear
```

`nwwebuse` loads the three friendship networks `glasgow1`, `glasgow2` and `glasgow3` and the
actor variables `smoke1`-`smoke3`, `alcohol1`-`alcohol3` and `sport1`-`sport3` into the current
dataset. Always look at the data before modeling. `nwsaom describe` prints what RSiena prints
before an estimation:

```stata
. nwsaom describe, waves(glasgow1 glasgow2 glasgow3)

Network data                        Number of actors  =        50
Directed                            Number of waves   =         3

------------------------------------------------------------------
        Wave |       Ties     Density   Avg. degree
-------------+----------------------------------------------------
           1 |        113      0.0461         2.260
           2 |        116      0.0473         2.320
           3 |        122      0.0498         2.440
------------------------------------------------------------------

------------------------------------------------------------------
      Period |    Kept   Created  Dissolved   Jaccard   Hamming
-------------+----------------------------------------------------
        1->2 |      57        59         56     0.331       115
        2->3 |      66        56         50     0.384       106
------------------------------------------------------------------
```

The density barely moves, but the network is far from static: between the first two waves 57 ties
were kept, 59 were created and 56 were dissolved. The **Jaccard index** (kept ties divided by
all ties present at either wave) is about 0.33 to 0.38. A SAOM needs enough change to learn from, but also
enough stability for the waves to be linked; The package help notes that a period with a Jaccard
index below about 0.3 has few stable ties and carries little information about the change process.
Here both periods are above that.

## The first model

We start with the effects that almost every SAOM contains:

- `outdegree`: the baseline tendency to have ties at all (it plays the role that the intercept
  or `edges` plays in other models);
- `reciprocity`: a tendency to return ties;
- `transtrip`: transitive triplets, "a friend of a friend becomes a friend";
- `samex(smoke1)`: a preference for friends with the same smoking status.

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

`seed(1)` makes the run reproducible (the estimation is a stochastic simulation, so a different seed
gives slightly different numbers). The header says that this is the default estimator: the
**method of moments**, in its **conditional** form, which is RSiena's default for one network.

### The coefficient table

The coefficients are on the log-odds scale of an actor's choice, so a positive number makes the
corresponding change more attractive and a negative number less attractive, **holding the other effects
constant**. The rest of the table (standard errors, z, p-value, interval) is read as in any other Stata
estimation command.

- `outdegree` is -2.76: with nothing else going on, creating a tie is unattractive. This is typical.
  Friendship networks are sparse, and the coefficient mostly tells you the density of the network.
  It is not interpreted substantively.
- `reciprocity` is 2.44 (z = 12.3): pupils strongly prefer to return a friendship. Choosing someone
  who already named you is worth about 2.5 on the log scale, on top of the baseline.
- `transtrip` is 0.61 (z = 7.9): the more friends in common via a path, the more attractive a tie
  is. Friendship clusters.
- `samex_smoke1` is 0.13 (z = 0.9): no evidence that pupils choose friends by smoking status, once
  reciprocity and clustering are in the model.

### The rate parameters

The rate says how many opportunities for change an actor had on average during a period. Between the
first two waves each pupil had about 6.5 opportunities to reconsider a friendship, and 5.2 between the
second and third. The standard errors are 1.2 and 0.9. Rates are nuisance parameters: they are needed, but they are rarely the point of an analysis.

### The convergence check

The last line is the most important one for deciding whether to **believe** the numbers.
The estimation is an iterative simulation and its result is only valid if the simulated networks,
averaged over many runs, reproduce the observed ones. For every parameter `nwsaom` computes a
convergence t-ratio (the discrepancy between simulated and observed statistic, in standard-deviation
units). RSiena's rule, which `nwsaom` follows, is:

- every t-ratio below 0.1 in absolute value and the overall maximum convergence ratio below
  0.25: good;
- overall maximum above 0.25: not converged; do not interpret the estimates, see
  [Tutorial 2](../tutorial-2-convergence/).

Here the overall ratio is 0.103, so the model converged. The option `detail` lists every t-ratio and
the effect names RSiena would use for the same effects:

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip samex(smoke1) seed(1) detail
...
RSiena effect names:
  samex_smoke1                  same smoke1
Convergence t-ratios (criterion: every |t| below 0.1; the overall maximum ratio below 0.25 is a
separate criterion):
  outdegree                 -0.095      reciprocity               -0.095
  samex_smoke1              -0.072      transtrip                 -0.093
Overall maximum convergence ratio:  0.103
```

(The table and rates are repeated and are left out here.)

## What the model stored

As other Stata estimation commands, `nwsaom` leaves its results in `e()`: `e(b)` and `e(V)` hold the
coefficients and their covariance matrix, so `test`, `lincom` and `estimates store` work as usual
(see [Tutorial 2](../tutorial-2-convergence/)), and `e(version)` holds the release of the package that
produced the results, which you should quote when you report an analysis.

## Things to try

- Replace `samex(smoke1)` with `egox(smoke1) altx(smoke1)`: do smokers send or receive more
  friendship nominations?
- Fit the model with only the two waves `waves(glasgow1 glasgow2)`.
- Use a different `seed()` and see how much the coefficients move; this is the simulation noise.
- Add `indegpopularity` and `outactivity` (a tendency for popular pupils to attract more ties, and
  for active pupils to send more).
- Add `detail`, and compare the printed RSiena names with the effects table in
  [nwsaom and RSiena](../rsiena/).

## Where next

[Tutorial 2](../tutorial-2-convergence/) shows what to do when the convergence line says "not
converged". The complete syntax is in Stata's `help nwsaom` and on the
[`nwsaom` reference page](../../reference/nwsaom).
