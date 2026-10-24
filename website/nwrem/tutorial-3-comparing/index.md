---
title: "Tutorial 3: Comparing specifications"
parent: "nwrem tutorials"
nav_order: 3
description: "Compare relational event models fitted with nwrem by log likelihood, AIC, BIC and likelihood-ratio tests, check that the estimates are stable, and see what the command refuses."
grand_parent: "nwrem (REM)"
---

# Tutorial 3: Comparing specifications

**Goal.** Choose between several relational event models for the same events, check that the estimates do not depend on the
starting point of the optimizer, and know what `nwrem` does not do.

**Data.** The 439 phone calls among 84 students of [Tutorial 1](../tutorial-1-first-rem/) (the data files: [events](../data/calls_events.csv), [actors](../data/calls_actors.csv)). You need
the core `nwcommands` and `nwrem` (see [Install](../install/)); the commands were run with `nwrem` 1.0.1 and the core 3.0.0.
Script and log: [example.do](example.do), [example.log](example.log).

## Five specifications

The effects of `nwrem` fall into three groups: activity (degree) effects, effects of the history of the pair (frequency or recency), and
covariates. We fit five models that combine the first two groups, and store each:

| Model | Effects | Idea |
|---|---|---|
| m1 | `nodsnd nidrec` | activity of sender and receiver |
| m2 | `frpsndsnd frrecsnd` | frequency of contact within the pair |
| m3 | `nodsnd nidrec frpsndsnd frrecsnd` | activity and frequency |
| m4 | `rsndsnd rrecsnd` | recency of contact within the pair |
| m5 | `nodsnd nidrec rsndsnd rrecsnd` | activity and recency |

```stata
. quietly nwrem calls, nodsnd nidrec
. estimates store m1
...
. quietly nwrem calls, nodsnd nidrec rsndsnd rrecsnd
. estimates store m5
```

## Compare them

`estimates stats` reports the log likelihood, the number of parameters, and the information criteria:

```stata
. estimates stats m1 m2 m3 m4 m5
Akaike's information criterion and Bayesian information criterion
-----------------------------------------------------------------------------
       Model |          N   ll(null)  ll(model)      df        AIC        BIC
-------------+---------------------------------------------------------------
          m1 |        439          .  -3117.419       2   6238.837   6247.006
          m2 |        439          .  -2274.048       2   4552.096   4560.265
          m3 |        439          .   -2115.76       4   4239.519   4255.857
          m4 |        439          .  -2122.016       2   4248.032   4256.201
          m5 |        439          .  -1968.845       4   3945.689   3962.027
-----------------------------------------------------------------------------
Note: BIC uses N = number of observations. See [R] IC note.
```

Lower AIC and BIC are better. The ranking is the same by both: m5 (activity and recency) is best, followed by m3 and m4 (which are
close, m3 a little ahead), then m2, with m1 (activity alone) far behind. Three conclusions follow:

1. The history of the pair matters much more than the general activity of the actors (m1 against m2: 1,700 AIC units).
2. Recency beats frequency: m4 and m2 have two parameters each, and m4 is better by 304 AIC units. Even m3, with four parameters,
   is only slightly ahead of m4 (4239.5 against 4248.0).
3. Activity still adds something once recency is in the model (m5 against m4: a gain of about 300 AIC units), although in m3 the
   receiver's activity was not distinguishable from zero (Tutorial 1).

Nested models can also be tested, as in a likelihood-ratio test (`lrtest` needs the larger model first):

```stata
. lrtest m3 m1
 LR chi2(2) = 2003.32
Prob > chi2 =  0.0000
. lrtest m3 m2
 LR chi2(2) = 316.58
Prob > chi2 =  0.0000
```

Adding the pair's frequency to the activity model (m3 against m1), or the activity to the frequency model (m3 against m2),
improves the fit significantly. The frequency and the recency models are not nested in each other, so use the information criteria for these.
The number of events is `N`, but the events are not independent draws in the usual sense; read the p-values as a guide and not as exact.

## Are the estimates stable?

The help file warns that degree effects are running shares that become more alike over the log, and that several of them in one
model can form a nearly flat ridge in the likelihood. Check this for the most crowded model by changing the `seed()`, which
decides which restart of the optimizer is tried first:

```stata
. nwrem calls, nodsnd nidrec frpsndsnd frrecsnd seed(1)
...
      nodsnd |   5.392444    .437614    12.32   0.000     4.534736    6.250151
      nidrec |   .9485508   .5809881     1.63   0.103     -.190165    2.087267
   frpsndsnd |   5.782833   .1612639    35.86   0.000     5.466762    6.098905
    frrecsnd |   1.640031   .1538416    10.66   0.000     1.338507    1.941555

. nwrem calls, nodsnd nidrec frpsndsnd frrecsnd seed(2)
...
      nodsnd |   5.392423   .4376143    12.32   0.000     4.534715    6.250131
      nidrec |   .9485645   .5809885     1.63   0.103    -.1901521    2.087281
   frpsndsnd |    5.78284   .1612634    35.86   0.000      5.46677    6.098911
    frrecsnd |   1.640016   .1538413    10.66   0.000     1.338493     1.94154
```

The two fits agree to four digits, so this model is well determined by these data. (The estimates in the earlier tutorials differ from these in the
fifth digit, which is the tolerance of the optimizer.) If your own model changes visibly with the seed while the log likelihood stays
about the same, you are on the ridge: do not interpret the individual degree coefficients, and prefer a simpler model or more events.

## What `nwrem` refuses

```stata
. capture noisily nwrem calls
nwrem requires at least one effect: nodsnd nidrec nidsnd nodrec ntdegsnd ntdegrec frpsndsnd frrecsnd covsnd() covrec() covint() covevent() rsndsnd rrecsnd (see nwrem ...
. capture noisily nwrem calls, frpsndsnd covsnd(nosuchvar)
variable nosuchvar not found
(error in option covsnd())
. capture noisily nwrem ordinary, nodsnd
nwrem requires a network declared via nwset's eventtime() option (an event-type temporal network) - see nwset.
```

There is no intercept option: a term that is the same for every possible pair at a given event cancels out of the partial
likelihood, so it could never be estimated, whatever is requested.

## What the package does not do

- **No triadic effects.** The effects are degree, inertia, reciprocity-of-receipt, recency and covariate effects. Shared-partner and
  other triad-type statistics, fixed effects, the full likelihood that uses the waiting times, and Bayesian estimation are not implemented.
- **Only the order of events.** The ordinal partial likelihood ignores the length of the gaps between events.
- **No goodness-of-fit command.** Use the comparison of specifications as above.
- **Pure Mata engine.** There is no compiled plugin.

If you need effects that `nwrem` does not have, the DyNAM of [nwdynam](../../nwdynam/) offers closure effects such as
`trans` and `cycle` and works on the same kind of data, and the R package relevent has more effects (see [nwrem and relevent](../r-relevent/)).

## Things to try

- Fit `nwrem calls, nodsnd nidrec nidsnd nodrec` and look at the standard errors: with four degree effects at once the ridge appears.
- Add `covsnd(floor)` to m5 (see Tutorial 2 for how to load the attribute) and compare by AIC.
- Fit the models on the first 150 events only, and see which conclusions survive.

Back to the [overview of nwrem](../).
