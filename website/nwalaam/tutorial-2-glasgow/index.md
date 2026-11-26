---
title: "Tutorial 2: Smoking in the Glasgow friendship network"
parent: "nwalaam: actor attributes"
nav_order: 2
description: "Fit contagion and covariate effects for smoking in a school friendship network with nwalaam, check the fit, simulate from the model, and see what the contagion term does not say."
---

# Tutorial 2: Smoking in the Glasgow friendship network

**Goal.** Model who smokes in a directed friendship network with contagion, activity and covariate effects, check whether the model reproduces the data, simulate from it, and read the contagion term for what it is.

**Data.** The Teenage Friends and Lifestyle Study excerpt: 50 girls in a school in the West of Scotland, directed friendship nominations (`glasgow1` is the first wave) and smoking, alcohol use and sport (see the
[data sets page](../../datasets/)). The outcome is whether a pupil smokes occasionally or regularly at the first wave: 12 of the 50. You need the core `nwcommands` and the `nwalaam` package (see [Install](../install/));
the commands were run with `nwalaam` 1.2.0. The complete script and log are in [example.do](example.do) and [example.log](example.log).

## The outcome and the network

```stata
. nwwebuse glasgow, nwclear
. generate byte smoker1 = (smoke1 > 1)
. tabulate smoker1

    smoker1 |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |         38       76.00       76.00
          1 |         12       24.00      100.00
------------+-----------------------------------
      Total |         50      100.00
```

## Contagion alone

```stata
. nwalaam smoker1 glasgow1, effects(density contagion) mple
----------------------------------------------------------------------
Autologistic actor attribute model (maximum pseudo-likelihood)
Outcome: smoker1 (12 of 50)                    Network: glasgow1
----------------------------------------------------------------------
-----------------------------------------------------
     smoker1 | Coefficient  Std. err.      z    P>|z|
-------------+---------------------------------------
     density |  -1.769064   .4589819    -3.85   0.000
   contagion |   .4525797   .1989247     2.28   0.023
-----------------------------------------------------
```

In a directed network `contagion` counts, for a pupil, the ties to smokers, incoming and outgoing (a mutual tie counts twice). The pseudo-likelihood estimate is a logit of smoking on that count: each tie to a smoker raises the log odds of smoking by 0.45.
Its standard error is too small, because it treats the outcomes of the others as fixed, so we use it only as a first look.

## The maximum likelihood estimate

```stata
. nwalaam smoker1 glasgow1, effects(density contagion sender receiver) seed(20261118)
----------------------------------------------------------------------
Autologistic actor attribute model (stochastic approximation)
Outcome: smoker1 (12 of 50)                    Network: glasgow1
SA repetitions: 1 (converged: yes)             Proposals per iteration: 1000
----------------------------------------------------------------------
-----------------------------------------------------
     smoker1 | Coefficient  Std. err.      z    P>|z|
-------------+---------------------------------------
     density |  -1.120924   .7140531    -1.57   0.116
   contagion |   .7415663   .2825708     2.62   0.009
      sender |  -.5224544     .39374    -1.33   0.185
    receiver |   .0293046   .2652388     0.11   0.912
-----------------------------------------------------
All convergence t-ratios are within .1 in absolute value.
```

`sender` and `receiver` are the activity effects of directed networks: the number of ties sent, and the number received, by the smokers. Taking them into account, the contagion coefficient is 0.74, with a standard error that is larger than that of the pseudo-likelihood: the
simulation accounts for the dependence among the outcomes.

## Covariates

The command does not centre covariates, so centre alcohol use and sport first (`ego()` adds up the covariate over the actors with the outcome, so the origin of the covariate matters):

```stata
. quietly summarize alcohol1
. generate double alc_c = alcohol1 - r(mean)
. quietly summarize sport1
. generate double sport_c = sport1 - r(mean)
. nwalaam smoker1 glasgow1, effects(density contagion sender receiver ego(alc_c) ego(sport_c)) seed(20261118)
----------------------------------------------------------------------
Autologistic actor attribute model (stochastic approximation)
Outcome: smoker1 (12 of 50)                    Network: glasgow1
SA repetitions: 1 (converged: yes)             Proposals per iteration: 1000
----------------------------------------------------------------------
-----------------------------------------------------
     smoker1 | Coefficient  Std. err.      z    P>|z|
-------------+---------------------------------------
     density |  -1.202652   1.062661    -1.13   0.258
    contagion |   .4173669   .3472694     1.20   0.229
      sender |  -.3880205   .5812799    -0.67   0.504
    receiver |  -.2609823   .3967369    -0.66   0.511
   ego_alc_c |   1.859464   .6992444     2.66   0.008
 ego_sport_c |   .2146388   .9961019     0.22   0.829
-----------------------------------------------------
All convergence t-ratios are within .1 in absolute value.
```

Pupils who drink more are more likely to smoke (`ego(alc_c)`, z = 2.66). Once alcohol use is in the model the contagion coefficient falls to 0.42 and its z-value to 1.20: with 50 pupils and 12 smokers the data cannot separate the tie pattern from the
shared habits of friends. That is the usual reading problem of a cross-sectional model, not a defect of the estimator.

## Does the model reproduce the data?

```stata
. estat gof, nsim(1000) seed(7)

Goodness of fit: 1,000 simulated outcome vectors from the fitted model (burn-in 10,000, interval 1,000)
------------------------------------------------------------
     Statistic |   Observed  Sim. mean    Sim. SD    t-ratio
---------------+--------------------------------------------
       density |     12.000     12.113      2.612      0.043
     contagion |     14.000     14.335      6.067      0.055
        sender |     26.000     26.331      6.380      0.052
      receiver |     30.000     30.423      7.887      0.054
     ego_alc_c |     13.440     13.666      2.802      0.080
   ego_sport_c |      0.120      0.111      1.081     -0.008
---------------+--------------------------------------------
not in the model: |
   reciprocity |     20.000     19.911      5.077     -0.018
      outstar2 |     18.000     20.382      6.496      0.367 *
       instar2 |     46.000     45.922     15.777     -0.005
     mixedstar |     52.000     56.643     18.112      0.256
   mixedsource |     48.000     45.129     12.160     -0.236
     mixedsink |     75.000     61.750     17.497     -0.757 *
contagionrecip |      5.000      5.333      2.501      0.133
   transitive1 |     21.000     22.928      6.253      0.308 *
   transitive3 |      8.000     10.284      7.156      0.319 *
  transitived1 |     22.000     22.001      5.106      0.000
  transitiveu1 |     27.000     26.372      7.554     -0.083
       cyclic1 |     15.000     15.631      4.642      0.136
       cyclic3 |      2.000      2.199      1.736      0.115
  alterinstar2 |     13.000     10.196      5.430     -0.516 *
 alteroutstar2 |     22.000     13.505      6.240     -1.361 *
------------------------------------------------------------
Mahalanobis distance of the observed statistics from the simulated ones:     5.208
t-ratio = (simulated mean - observed) / simulated SD; * marks |t| > 0.3
(t-ratios of the statistics in the model should be near 0 after a converged
fit; for the other statistics, values within about 0.3 indicate a good fit).
```

`estat gof` simulates outcome vectors from the fitted model and compares the statistics of the data with those of the simulations. The statistics in the model must come out near 0 (they do: the
fit has converged); the telling rows are the ones below, statistics that were not fitted. A t-ratio within about 0.3 is a good fit; a few of the other statistics are marked with a star, and the largest, `alteroutstar2` (-1.36), is one that the model reproduces
less well: the simulated outcomes have fewer of them than the data. With 12 smokers, one such statistic is no reason to give the model up, but it says where to look next, and `estat mcmcdiag` shows the convergence of the fit.

## Simulating from the model

```stata
. nwalaam simulate, nsim(100) generate(sim) seed(2)
Simulated 100 outcome vectors on 50 actors, stored in variables sim1 to sim100 (seed 2, burn-in 10000 and interval 1000 proposals).
. egen simsmoke = rowtotal(sim1-sim100)
. summarize simsmoke

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
    simsmoke |         50        23.3    27.18362          0         93
```

`nwalaam simulate` draws outcome vectors from a fitted model (or from coefficients you give with `theta()`) and stores them as variables. A pupil smokes on average in 23.3 of the 100 draws, close to the 24 percent of the data, and in the draws the pupils differ a lot:
some never smoke, some smoke in 93 of the 100.

## What contagion does not say

The contagion coefficient describes how smokers are placed on the network at one point in time. It does not say that a pupil starts to smoke because friends smoke: pupils choose friends who are like them (selection), friends share a school, a class and an age (confounding), and
the model takes the network as given. The statistic is also a count of ties to smokers on the scale of the log odds, not a share of friends, and the coefficients are of a different kind from those of a regression on the share of friends who smoke:

```stata
. nwaltergen frsmoke = proportion(alter.smoker1==1), net(glasgow1)
. logit smoker1 frsmoke
...
     frsmoke |   2.588576   1.050983     2.46   0.014     .5286875    4.648465
       _cons |   -1.83919   .5196682    -3.54   0.000    -2.857721   -.8206591
```

The logit has 46 observations, because four pupils name nobody and the share of friends is undefined for them, while the ALAAM uses all 50 pupils. A regression of smoking one wave later on the share of friends who smoke now, with own smoking now as a control (a linear regression, as in the book), estimates the association of exposure with a later change; that
is a different quantity again from the cross-sectional contagion term, and none of the three numbers can be put in the place of another. To ask whether friends influence each other, use a longitudinal model: see [nwsaom](../../nwsaom/) and its
[tutorial on selection and influence](../../nwsaom/tutorial-4-selection-influence/).

## Things to try

- Fit the same model on the second wave (`smoker2` and `glasgow2`) and compare the contagion coefficients.
- Add `method(ee) runs(30)` to the last fit to compare with the update of ALAAMEE.
- Run `estat mcmcdiag` after a fit and read the convergence table.

## Next

Back to the [overview of nwalaam](../), or to [how to cite](../citation/).
