---
title: "Tutorial 6: Beyond the basic model"
parent: "nwsaom (SAOM)"
nav_order: 7
description: "Maximum likelihood and Bayesian estimation with nwsaom, and two networks that change together (nwsaom multinet), with short runnable examples."
---

# Tutorial 6: Beyond the basic model

**Goal.** A short tour of three things `nwsaom` can do besides the method-of-moments fit of one
network: **maximum likelihood**, **Bayesian estimation** and **several networks** that change
together. Each section is a small, complete example; the full documentation is in `help nwsaom`,
`help nwsaom_bayes` and the manual.

**Data.** The Glasgow data (see [Tutorial 1](../tutorial-1-first-saom/)) and, for the last section,
a second network that we simulate. Script and log: [example.do](example.do),
[example.log](example.log).

## Three estimators, one model

The model of [Tutorial 1](../tutorial-1-first-saom/), without the covariate, estimated by the
method of moments (the default):

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip seed(1)
...
------------------------------------------------------------------------------
glasgow1_t~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.675306   .1130571   -23.66   0.000    -2.896894   -2.453718
 reciprocity |   2.453519   .1841138    13.33   0.000     2.092662    2.814375
   transtrip |   .6151182    .075624     8.13   0.000     .4668978    .7633385
------------------------------------------------------------------------------
...
Overall maximum convergence ratio: 0.123 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

## Maximum likelihood

The option `ml` estimates the same model by maximum likelihood (a Robbins-Monro algorithm applied
to the likelihood of the data augmented by the unobserved ministeps, as in RSiena's
`maxlike = TRUE`). The command prints the method-of-moments fit first and then the maximum likelihood table:

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip seed(1) ml
...
Maximum likelihood (iterations: phase 1 50, phase 2 4 x 100, phase 3 1000) ...

Maximum likelihood estimates (Robbins-Monro on the score of the augmented data)
------------------------------------------------------------------------------
glasgow1_t~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.644514   .1034917   -25.55   0.000    -2.847354   -2.441674
 reciprocity |   2.220063   .1667722    13.31   0.000     1.893195     2.54693
   transtrip |   .6942384   .0633412    10.96   0.000     .5700919    .8183848
------------------------------------------------------------------------------
Rate parameters (one per inter-wave period):

------------------------------------
             |   period1    period2
-------------+----------------------
        rate |    6.3079     5.2549
          se |    0.8436     0.9311
       tconv |   -0.0008    -0.0352
------------------------------------
Overall maximum t-ratio of the scores: 0.104 (acceptable)
```

(The method-of-moments table and its convergence line, printed first, are omitted.) The two estimators
are two ways to estimate the same model, so the two sets of coefficients are
similar: `reciprocity` is 2.45 by the method of moments and 2.22 by maximum likelihood, `transtrip` 0.62 and 0.69,
and the standard errors of the likelihood estimates are somewhat smaller. The last line is the
analogue of the convergence check for this estimator (t-ratios of the scores); the command
prints its own verdict, here "acceptable". Details of the options (`mloptions()`) are in
`help nwsaom` under "Maximum likelihood".

## Bayesian estimation

`nwsaom bayes` follows a fit and samples the posterior distribution of the model that was
just fitted, using the fit as starting point and for the proposal distribution. The method is that
of multiSiena (Snijders, Koskinen, Ripley). The defaults (50 pre-warming, 50 warming and 250
main iterations of 20 batches each) are meant for a real analysis and take longer. For a demonstration we use a very short run.
**This is only to show the output**; for a real analysis use the defaults or more.

```stata
. nwsaom bayes, nprewarm(20) nwarm(20) nmain(100) nrunmh(5) seed(7)
Sampling: 20 pre-warming + 20 warming + 100 main iterations of 5 batches ...

Bayesian SAOM (data augmentation)                Number of actors  =       50
Waves: glasgow1 glasgow2 glasgow3                Saved draws       =      100
Pre-warm 20, warm 20, main 100 x 5               Mean chain length =    547.9
Acceptance rates: effects 0.448, rates 0.238
Chain steps accepted: diagonal 0.720, permute 0.737
                      insert-permute 0.383, delete-permute 0.341
-----------------------------------------------------------------------------
      Effect |       Mean  Std. dev.    [95% cred. interval]     Median   ESS
-------------+---------------------------------------------------------------
   outdegree |    -2.7197     0.1106     -2.9433     -2.4910    -2.7264    25
 reciprocity |     2.3220     0.1642      1.9523      2.6334     2.3299    20
   transtrip |     0.7196     0.0594      0.6238      0.8337     0.7109    26
rate_period1 |     6.2188     0.7302      5.1230      7.9070     6.0991    13
rate_period2 |     4.8437     0.4542      4.0459      5.8121     4.8109    19
-----------------------------------------------------------------------------
Draws (one per main iteration) are in frame nwsaom_bayes_draws:
  b1..b3 (effects), rate1..rate2, nchain, loglik.
Priors: effects flat unless priorsigeta() (with priormeaneta()) is given; rates normal with
ratepriormean() and ratepriorsd() (ratepriorsd(0): flat), or gamma with gibbsrates/priorrate().
```

Posterior means and standard deviations take the place of estimates and standard errors, with a 95%
interval of the posterior. The column ESS is the effective sample size of the chain: here it is only
13 to 26 draws, which is what a 100-iteration run can give, and why this run is an illustration and not
a result. For a real analysis you want a much larger ESS. Even so, the posterior means
are close to the maximum likelihood estimates above, as they should be with flat priors. The draws are stored in a Stata frame, so
you can summarise or plot them with ordinary Stata commands, for example
`frame nwsaom_bayes_draws: summarize b2`. The Bayesian estimator at present fits one directed one-mode network, with or
without one behavior; the exact conditions are in `help nwsaom_bayes`.

## Two networks that change together

Friendship and advice, or trust and collaboration, are different relations among the same people and
they influence each other. `nwsaom multinet` fits two networks at once; each has its own
effects and rate, and **cross-network effects** let a tie in one network change the chance of
the same tie in the other. The Glasgow data have only one network, so for this demonstration we
**simulate** an "advice" network that overlaps with friendship (the example is for the
syntax, not for substance; the second network is artificial):

```stata
. nwtomata glasgow1, mat(F1)

. nwtomata glasgow2, mat(F2)

. set seed 20261001

. mata: A1 = (F1 :* (runiform(50, 50) :< 0.7) + (runiform(50, 50) :< 0.005)) :> 0

. mata: _diag(A1, 0)

. mata: A2 = (A1 :* (runiform(50, 50) :< 0.8) + F2 :* (1 :- A1) :* (runiform(50, 50) :< 0.4)) :> 0

. mata: _diag(A2, 0)

. nwset, mat(A1) directed name(advice1)

. nwset, mat(A2) directed name(advice2)
```

Each network gets the default effects (`outdegree`, `reciprocity`), and `cross1(crprod)` and
`cross2(crprod)` add the effect of a tie in the other network on the same tie ("crprod", the
cross-network product, as in RSiena):

```stata
. nwsaom multinet, net1(glasgow1 glasgow2) net2(advice1 advice2) cross1(crprod) cross2(crprod) seed(1)

Several co-evolving networks (Method of Moments), 2 waves, 50 actors

----------------------------------------------------------------------------------
                 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-----------------+----------------------------------------------------------------
  net1_outdegree |  -2.307828   .1315487   -17.54   0.000    -2.565659   -2.049997
net1_reciprocity |    2.31696   .2444205     9.48   0.000     1.837904    2.796015
   net1_x_crprod |    .636828   .3649647     1.74   0.081    -.0784896    1.352146
  net2_outdegree |  -2.050233   .2451438    -8.36   0.000    -2.530707    -1.56976
net2_reciprocity |   2.033514    .466895     4.36   0.000     1.118416    2.948611
   net2_x_crprod |   .8708796   .7418836     1.17   0.240    -.5831854    2.324945
----------------------------------------------------------------------------------
Rates (estimated):

------------------------
             |  period1
-------------+----------
   rate_net1 |    6.794
   rate_net2 |    1.588
     se_net1 |    1.515
     se_net2 |    0.268
------------------------
Overall maximum convergence ratio: 0.135 (criterion: below 0.25; met)
```

The coefficients carry the prefix `net1_` or `net2_`. The overall ratio is 0.135, below 0.25, so
this run has converged. Had it not, you would restart from the estimates, as in
[Tutorial 2](../tutorial-2-convergence/). Since nwsaom 1.5.13 `nwsaom refit` works after `multinet`
too; it reruns the stored command with the estimates in `theta0()`:

```stata
. nwsaom refit, seed(2)

------------------------------------------------------------------------------
nwsaom refit, run 1: starting from the last estimates (overall ratio 0.135)
------------------------------------------------------------------------------

Several co-evolving networks (Method of Moments), 2 waves, 50 actors

----------------------------------------------------------------------------------
                 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-----------------+----------------------------------------------------------------
  net1_outdegree |  -2.324234   .1432232   -16.23   0.000    -2.604946   -2.043522
net1_reciprocity |   2.345437   .2401338     9.77   0.000     1.874783     2.81609
   net1_x_crprod |   .6290936   .4552866     1.38   0.167    -.2632518    1.521439
  net2_outdegree |  -2.030494   .2247149    -9.04   0.000    -2.470927   -1.590061
net2_reciprocity |   2.057765   .4778972     4.31   0.000     1.121103    2.994426
   net2_x_crprod |   .7900366   .7665403     1.03   0.303    -.7123548    2.292428
----------------------------------------------------------------------------------
...
Overall maximum convergence ratio: 0.182 (criterion: below 0.25; met)

nwsaom refit: 1 run; largest |t| 0.069, overall ratio 0.182 (converged)
```

The refit has converged as well (overall ratio 0.182), and the estimates hardly change. Each
network is reciprocal (2.3 and 2.1). The two cross-network
effects are positive, but neither is clearly different from zero in
this small, artificial example. After `multinet`, `estat score` and `estat timetest` are available;
`estat gof` is not yet.

## Further reading

- **Two-mode networks** (for example pupils and clubs): `nwsaom` detects a bipartite network
  declared with `nwset, bipartite` and lets the actors choose among the events. See "Two-mode networks"
  in `help nwsaom_remarks`.
- **Undirected networks** (`symtype()`) and two-mode networks are in [Tutorial 9](../tutorial-9-undirected-twomode/),
  **composition change** (`present()`) and **missing data** (`missnet()`, `missbeh()`) in [Tutorial 7](../tutorial-7-composition-missing/),
  **a covariate-dependent rate** (`ratecov()`), endowment and creation effects and interactions in
  [Tutorial 10](../tutorial-10-endowment-interaction-rate/), simulation in [Tutorial 11](../tutorial-11-simulation/) and
  **combining several groups** (`nwsaom meta`, RSiena's `siena08`) in [Tutorial 13](../tutorial-13-meta-analysis/) and **estimating several groups jointly** (`groups()`) in [Tutorial 14](../tutorial-14-several-groups/).
  A behavior in a multinet model and **structural zeros** (`structural()`) are in `help nwsaom` and `help nwsaom_remarks`.
- [nwsaom and RSiena](../rsiena/) lists what is different from RSiena; the
  [effect overview](../effects/) lists the effect families.
