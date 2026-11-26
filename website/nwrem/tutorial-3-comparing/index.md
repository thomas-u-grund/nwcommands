---
title: "Tutorial 3: Comparing specifications"
parent: "nwrem: relational events"
nav_order: 3
description: "Compare relational event models fitted with nwrem by log likelihood, AIC, BIC and likelihood-ratio tests, check that the estimates are stable, and see what the command refuses."
---

# Tutorial 3: Comparing specifications

**Goal.** Choose between several relational event models for the same events, check that the estimates do not depend on the
starting point of the optimizer, and know what `nwrem` does not do.

**Data.** The e-mails of [Tutorial 1](../tutorial-1-first-rem/): the first five days of the manufacturing company e-mail data, 631 e-mails among 144 employees
(Michalski, R. (2020), Harvard Dataverse, [doi:10.7910/DVN/6Z3CGX](https://doi.org/10.7910/DVN/6Z3CGX), CC0 1.0; Nurek, M. and Michalski, R. (2020),
*Applied Sciences* 10(5), 1699; see the [data sets page](../../datasets/)). You need the core `nwcommands` and `nwrem` (see [Install](../install/)); the commands were run with `nwrem` 1.1.2 and the
core 3.25.1. Script and log: [example.do](example.do), [example.log](example.log).

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
. quietly nwrem mail, nodsnd nidrec
. estimates store m1
...
. quietly nwrem mail, nodsnd nidrec rsndsnd rrecsnd
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
          m1 |        631          .  -5992.517       2   11989.03   11997.93
          m2 |        631          .  -5733.442       2   11470.88   11479.78
          m3 |        631          .  -5531.783       4   11071.57   11089.36
          m4 |        631          .  -5389.231       2   10782.46   10791.36
          m5 |        631          .  -5221.696       4   10451.39   10469.18
-----------------------------------------------------------------------------
Note: BIC uses N = number of observations. See [R] BIC note.
```

Lower AIC and BIC are better. The ranking is the same by both: m5 (activity and recency) is best, followed by m4 (recency), m3 (activity and frequency), then
m2, with m1 (activity alone) last. Three conclusions follow:

1. The history of the pair matters more than the general activity of the actors (m1 against m2: 518 AIC units).
2. Recency beats frequency: m4 and m2 have two parameters each, and m4 is better by 688 AIC units. Even m3, with four parameters,
   is 289 units behind m4 (11071.6 against 10782.5).
3. Activity still adds something once recency is in the model (m5 against m4: a gain of about 331 AIC units), and in m3 the activity
   effects were clearly different from zero as well (Tutorial 1).

Nested models can also be tested, as in a likelihood-ratio test (`lrtest` needs the larger model first):

```stata
. lrtest m3 m1
 LR chi2(2) = 921.47
Prob > chi2 =  0.0000
. lrtest m3 m2
 LR chi2(2) = 403.32
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
. nwrem mail, nodsnd nidrec frpsndsnd frrecsnd seed(1)
...
      nodsnd |   14.36445   1.616696     8.89   0.000     11.19579    17.53312
      nidrec |   22.01799   1.182937    18.61   0.000     19.69948    24.33651
   frpsndsnd |   2.296243   .1856085    12.37   0.000     1.932457    2.660029
    frrecsnd |   3.821278   .1618695    23.61   0.000      3.50402    4.138537

. nwrem mail, nodsnd nidrec frpsndsnd frrecsnd seed(2)
...
      nodsnd |   14.36445   1.616694     8.89   0.000     11.19579    17.53312
      nidrec |   22.02006   1.182888    18.62   0.000     19.70164    24.33848
   frpsndsnd |   2.296228   .1856043    12.37   0.000     1.932451    2.660006
    frrecsnd |   3.821261   .1618674    23.61   0.000     3.504007    4.138515
```

The two fits agree to three digits or more (the largest difference is 0.002, in `nidrec`), so this model is well determined by these data. (The estimates in Tutorial 1 differ from these
in the third or fourth digit, for example 14.362 and 14.364 for `nodsnd`, which is the tolerance of the optimizer.) If your own model changes visibly with the seed while the log likelihood stays
about the same, you are on the ridge: do not interpret the individual degree coefficients, and prefer a simpler model or more events.

## What `nwrem` refuses

```stata
. capture noisily nwrem mail
nwrem requires at least one effect: nodsnd nidrec nidsnd nodrec ntdegsnd
ntdegrec frpsndsnd frrecsnd covsnd() covrec() covint() covevent() rsndsnd
rrecsnd (see nwrem for what each computes).
invalid syntax
. capture noisily nwrem mail, frpsndsnd covsnd(nosuchvar)
variable nosuchvar not found
(error in option covsnd())
. capture noisily nwrem ordinary, nodsnd
nwrem requires a network declared via nwset's eventtime() option (an event-type
temporal network) - see nwset.
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

- Fit `nwrem mail, nodsnd nidrec nidsnd nodrec` and look at the standard errors: with four degree effects at once the ridge appears.
- Add `covsnd(level)` to m5 (see Tutorial 2 for how to load the attribute) and compare by AIC.
- Fit the models on the first 300 events only, and see which conclusions survive.

Back to the [overview of nwrem](../).
