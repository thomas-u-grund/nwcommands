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
   outdegree |  -2.687867   .1214406   -22.13   0.000    -2.925886   -2.449847
 reciprocity |   2.457453   .2035477    12.07   0.000     2.058507      2.8564
   transtrip |   .6202674   .0789534     7.86   0.000     .4655217    .7750132
------------------------------------------------------------------------------
...
Overall maximum convergence ratio: 0.142 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): not met for outdegree (-0.139) reciprocity (-0.130)
Convergence is good only if both criteria are met. Refit starting from these estimates with theta0(); see nwsaom.
```

## Maximum likelihood

The option `ml` estimates the same model by maximum likelihood (a Robbins-Monro algorithm applied
to the likelihood of the data augmented by the unobserved ministeps, as in RSiena's
`maxlike = TRUE`). The command prints the method-of-moments fit first and then the maximum likelihood table:

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip seed(1) ml
...
Maximum likelihood: phase 1 50 iterations, phase 2 4 subphases from 100 iterations, phase 3 1000 iterations ...

Maximum likelihood estimates (Robbins-Monro on the score of the augmented data)
------------------------------------------------------------------------------
glasgow1_t~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.646338   .1095288   -24.16   0.000     -2.86101   -2.431665
 reciprocity |   2.265619   .1803705    12.56   0.000     1.912099    2.619139
   transtrip |   .6837719   .0654852    10.44   0.000     .5554233    .8121205
------------------------------------------------------------------------------
Rate parameters (one per inter-wave period):

       period1  period2
 rate   6.4886   5.4048
   se   0.8839   0.7473
tconv  -0.0540  -0.0422
Overall maximum t-ratio of the scores: 0.234 (acceptable)
```

(The method-of-moments table and its convergence line, printed first, are omitted.) The two estimators
are two ways to estimate the same model, so the two sets of coefficients are
similar: `reciprocity` is 2.46 by the method of moments and 2.22 by maximum likelihood, `transtrip` 0.62 and 0.69,
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
Pre-warm 20, warm 20, main 100 x 5               Mean chain length =    570.3
Acceptance: effects 0.462, rates 0.270; chain steps: diagonal 0.728, permute 0.619, insert-permute 0.370, delete-permute
-----------------------------------------------------------------------------
      Effect |Post. mean  Post. sd[95% interval]             Median      ESS
-------------+---------------------------------------------------------------
   outdegree |   -2.6935    0.1232   -2.9096   -2.4620   -2.6920        9
 reciprocity |    2.2710    0.1989    1.9126    2.6400    2.2763        8
   transtrip |    0.7051    0.0669    0.5824    0.8292    0.6930       27
rate_period1 |    6.0542    0.6211    5.1038    7.1997    6.0441       13
rate_period2 |    5.3817    0.7525    4.0248    6.9119    5.2871        6
-----------------------------------------------------------------------------
Draws (one per main iteration) are in frame nwsaom_bayes_draws (b1..b3 effects, rate1..rate2, nchain, loglik); flat priors unless
priormean()/priorsd()/priorrate() are given.
```

Posterior means and standard deviations take the place of estimates and standard errors, with a 95%
interval of the posterior. The column ESS is the effective sample size of the chain: here it is only
26 to 41 draws, which is what a 100-iteration run can give, and why this run is an illustration and not
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
-------------------------------------------------------------------------------------------------------------------------
Several co-evolving networks (Method of Moments), 2 waves, 50 actors
-------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------
                 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-----------------+----------------------------------------------------------------
  net1_outdegree |  -2.297847   .1393271   -16.49   0.000    -2.570923   -2.024771
net1_reciprocity |   2.299379      .2197    10.47   0.000     1.868775    2.729983
   net1_x_crprod |   .6369573   .3438109     1.85   0.064    -.0368996    1.310814
  net2_outdegree |  -2.039054   .3099247    -6.58   0.000    -2.646495   -1.431613
net2_reciprocity |   2.017523   .4941018     4.08   0.000     1.049101    2.985944
   net2_x_crprod |     .87247   .9096327     0.96   0.337    -.9103773    2.655317
----------------------------------------------------------------------------------
Rates (estimated):

           period1
rate_net1    6.744
rate_net2    1.590
  se_net1    1.001
  se_net2    0.224
Overall maximum convergence ratio: 0.260 (criterion: below 0.25; not met)
```

The coefficients carry the prefix `net1_` or `net2_`. The overall ratio is 0.260, just above
the limit of 0.25, so this run has not converged. As in
[Tutorial 2](../tutorial-2-convergence/), restart from the estimates:

```stata
. matrix b = e(b)
. local th
. forvalues j = 1/`=colsof(b)' {
.     local th `th' `=b[1,`j']'
. }
. nwsaom multinet, net1(glasgow1 glasgow2) net2(advice1 advice2) cross1(crprod) cross2(crprod) theta0(`th') seed(2)
...
  net1_outdegree |  -2.311336   .1234978   -18.72   0.000    -2.553388   -2.069285
net1_reciprocity |   2.314326   .2774067     8.34   0.000     1.770619    2.858033
   net1_x_crprod |   .6479287   .3880397     1.67   0.095    -.1126152    1.408473
  net2_outdegree |  -2.021367    .208823    -9.68   0.000    -2.430652   -1.612081
net2_reciprocity |   2.032402   .4654263     4.37   0.000     1.120184    2.944621
   net2_x_crprod |   .8226323   .6930513     1.19   0.235    -.5357232    2.180988
...
Overall maximum convergence ratio: 0.179 (criterion: below 0.25; met)
```

The ratio is now 0.179, below 0.25. Each network is reciprocal (2.3 and 2.0). The two cross-network
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
