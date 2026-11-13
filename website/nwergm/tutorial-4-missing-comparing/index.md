---
title: "Tutorial 4: Missing data and comparing models"
parent: "nwergm (ERGM)"
nav_order: 5
description: "Fit an ERGM to a network with missing dyads, compare models with AIC, BIC and likelihood-ratio tests, and compute predicted tie probabilities."
---

# Tutorial 4: Missing data and comparing models

**Goal.** Fit a model when some dyads were not observed, and choose between models with `estat ic`,
`estimates stats` and `lrtest`. At the end, `predict` gives the probability of each tie under the model.

* Builds on [Tutorial 2](../tutorial-2-terms/) and [Tutorial 3](../tutorial-3-diagnostics/).
* Needs the core `nwcommands` and `nwergm` (see [Install](../install/)).

**Data.** The Florentine marriage network (16 families, with `wealth`) and the Lazega friendship
network (71 lawyers). Run with `nwergm` 1.6.0 and core 3.22.0; the script and log are in
[example.do](example.do) and [example.log](example.log). Output is shortened to the coefficient
table and the log-likelihood line; `...` marks what is left out.

## Missing dyads

In survey data a tie can be missing for two quite different reasons: it was not there, or it was not
observed. Treating unobserved ties as non-ties biases the density. `nwergm` follows R's `ergm`: a missing
value in the network (not on the diagonal) is a missing dyad, it is **left out of the likelihood**, and
for a model that depends on other ties the missing dyads are handled by the method of Handcock and Gile
(2010), which draws a second sample in which only the missing dyads vary.

To have something to work with, we blank out three of the Florentine marriages (each as a pair of cells in the
symmetric matrix): `nwtomata` copies the network to a Mata matrix, we set cells to missing and `nwset` builds
a new network `flomiss` from it.

```stata
. nwwebuse florentine, nwclear
. nwtomata flomarriage, mat(A)
. mata: A[1,2] = A[2,1] = .
. mata: A[3,5] = A[5,3] = .
. mata: A[4,9] = A[9,4] = .
. mata: st_matrix("Am", A)
. nwset, mat(Am) undirected name(flomiss)
```

The complete network first, and then the one with the missing dyads:

```stata
. nwergm flomarriage, edges nodecov(wealth)
...
--------------------------------------------------------------------------------
   flomarriage | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
---------------+----------------------------------------------------------------
         edges |  -2.594929   .5360561    -4.84   0.000     -3.64558   -1.544278
nodecov_wealth |   .0105459   .0046743     2.26   0.024     .0013845    .0197073
--------------------------------------------------------------------------------
...
Log-likelihood:   -51.5543 (df = 2)   AIC:     107.1   BIC:     112.7
```

```stata
. nwergm flomiss, edges nodecov(wealth)
Note: network flomiss has 3 missing dyad(s); they are left out of the likelihood, as in ergm.
...
```

```stata
. nwergm flomiss, edges nodecov(wealth)
...
--------------------------------------------------------------------------------
       flomiss | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
---------------+----------------------------------------------------------------
         edges |  -2.692927    .552001    -4.88   0.000    -3.774829   -1.611025
nodecov_wealth |   .0111924   .0047613     2.35   0.019     .0018604    .0205244
--------------------------------------------------------------------------------
...
Log-likelihood:   -49.1649 (df = 2)   AIC:     102.3   BIC:     107.9
```

```stata
. display "missing dyads: " e(nmissing) "   informative dyads: " e(N)
missing dyads: 3   informative dyads: 117
```

`nwergm` prints a note, counts only the 117 informative dyads (of 120) and stores the number of missing
dyads in `e(nmissing)`. With the three dyads removed the tie count is 19 (they contained one marriage),
and the estimates move a little (wealth effect 0.0112 against 0.0105 with the complete data). A model
with a dependence term is fitted with the missing-data MCMLE:

```stata
. nwergm flomiss, edges nodecov(wealth) gwesp(0.5) seed(1)
...
--------------------------------------------------------------------------------
       flomiss | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
---------------+----------------------------------------------------------------
         edges |  -2.678908   .5691385    -4.71   0.000    -3.794399   -1.563417
nodecov_wealth |   .0105619   .0054018     1.96   0.051    -.0000255    .0211493
     gwesp_0.5 |   .0452257   .2927755     0.15   0.877    -.5286037    .6190551
--------------------------------------------------------------------------------

MCMLE converged after 1 iteration(s).
...
Log-likelihood:   -49.1518 (df = 3)   AIC:     104.3   BIC:     112.6
Monte Carlo standard error of the log-likelihood:  .00288
```

Two cautions. First, missing **covariate** values are refused with error 416, as in R; drop or impute
them first. Second, missing dyads cannot yet be combined with `freedyads()`, `blockdiag()` or
`fixdensity`. Fits with a different number of informative dyads (as `flomarriage` and `flomiss` here)
cannot be compared by AIC or by `lrtest`.

## Comparing models

Fit the models to the same network, store them, compare them. We use the Lazega network and three
nested specifications.

```stata
. nwwebuse lazega, nwclear
. encode practice, generate(prac)
```

```stata
. nwergm lazega_fr, edges mutual nodematch(prac) seed(1)
...
--------------------------------------------------------------------------------
     lazega_fr | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
---------------+----------------------------------------------------------------
         edges |   -2.73884   .0813401   -33.67   0.000    -2.898264   -2.579417
        mutual |   .9924631    .152278     6.52   0.000     .6940037    1.290922
nodematch_prac |   .9027794   .0922064     9.79   0.000     .7220581    1.083501
--------------------------------------------------------------------------------

MCMLE converged after 3 iteration(s).
...
Log-likelihood: -1702.2907 (df = 3)   AIC:    3410.6   BIC:    3430.1
Monte Carlo standard error of the log-likelihood:  .06401
```

```stata
. nwergm lazega_fr, edges mutual nodematch(prac) gwesp(0.5) seed(1)
...
--------------------------------------------------------------------------------
     lazega_fr | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
---------------+----------------------------------------------------------------
         edges |  -3.479122   .1130881   -30.76   0.000     -3.70077   -3.257473
        mutual |   .8125966   .1626768     5.00   0.000      .493756    1.131437
nodematch_prac |   .6985484   .0792428     8.82   0.000     .5432353    .8538615
     gwesp_0.5 |   .4967716   .0653576     7.60   0.000      .368673    .6248702
--------------------------------------------------------------------------------

MCMLE converged after 6 iteration(s).
...
Log-likelihood: -1670.6819 (df = 4)   AIC:    3349.4   BIC:    3375.4
Monte Carlo standard error of the log-likelihood:  .15369
```

`estat ic` shows the information criteria of the last fit; `estimates stats` puts the stored models in
one table (compare models only if N is the same):

```stata
. estat ic

Akaike's information criterion and Bayesian information criterion

-----------------------------------------------------------------------------
       Model |        N     ll(null)    ll(model)    df       AIC       BIC
-------------+---------------------------------------------------------------
   lazega_fr |     4970      -3444.9      -1670.7     4    3349.4    3375.4
-----------------------------------------------------------------------------
Note: BIC uses N = number of informative dyads.
Monte Carlo standard error of the log-likelihood:  .15369
```

```stata
. estimates stats m1 m2

Akaike's information criterion and Bayesian information criterion

-----------------------------------------------------------------------------
       Model |          N   ll(null)  ll(model)      df        AIC        BIC
-------------+---------------------------------------------------------------
          m1 |      4,970  -3444.941  -1702.291       3   3410.581   3430.115
          m2 |      4,970  -3444.941  -1670.682       4   3349.364   3375.409
-----------------------------------------------------------------------------
Note: BIC uses N = number of observations. See [R] BIC note.
```

Lower AIC and BIC are better. Adding `gwesp(0.5)` lowers AIC from 3410.6 to 3349.4 and BIC from 3430.1
to 3375.4: the closure term earns its place by both criteria. The log-likelihood of a model with
dependence is evaluated by bridge sampling, which is a simulation: the footer of each fit and of `estat ic`
shows its Monte Carlo standard error (here between 0.06 and 0.15), which should be small relative to the differences you
interpret. For nested models the likelihood-ratio test is also available:

```stata
. lrtest m2 m1

Likelihood-ratio test
Assumption: m1 nested within m2

 LR chi2(1) =  63.22
Prob > chi2 = 0.0000
```

The test statistic is 63.22 on one degree of freedom, a strong rejection of the model without closure.
`lrtest` needs the models to be nested and fitted to the same N. The likelihood is not evaluated for a
model with a curved (free-decay) term fitted by MCMLE, and `nologlik` skips the bridge sampling (then
AIC and BIC are missing) when you only need coefficients.

## Predicted tie probabilities

`predict` gives, for every dyad, the probability of a tie **given the rest of the observed network** (R's
`predict.ergm`). With `frame()` the result is a table with one row per dyad; with `matrix()` it is a
matrix, with missing dyads set to missing. The prediction is for the most recent fit (here the model
with `gwesp`).

```stata
. predict, frame(pp) pr
(frame pp contains one row per informative dyad: tail, head, p = conditional tie probability)
```

```stata
. frame pp: summarize p

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
           p |      4,970    .1152925    .0920556   .0299122   .8009428
```

```stata
. frame pp: list in 1/5

     +-------------------------+
     | tail   head           p |
     |-------------------------|
  1. |    1      2   .02991216 |
  2. |    1      3   .35812657 |
  3. |    1      4   .10249971 |
  4. |    1      5   .30525013 |
  5. |    1      6   .03613612 |
     +-------------------------+
```

The mean probability, 0.115, is close to the density of the network (0.116). Use `xb` instead of `pr` for
the conditional log-odds.

## Things to try

- Blank out more dyads (10 or 20) and watch how the standard errors grow.
- Add `nodeicov(seniority)` to the Lazega model and compare AIC and BIC with `estimates stats`.
- Compare `gwesp(0.25)`, `gwesp(0.5)` and `gwesp(1)` by AIC.
- Use `predict, matrix(P) pr` and look at the highest probabilities among the dyads that are not tied.

## Where next

[Tutorial 5](../tutorial-5-constraints-twomode-operators/) covers constraints on the sample space,
two-mode networks and the operators. The details on missing data and fit statistics are in `help nwergm_fit`.
