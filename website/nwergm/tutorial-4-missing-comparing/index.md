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
network (71 lawyers). Run with `nwergm` 1.3.1 and core 3.10.0; the script and log are in
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
Log-likelihood:   -51.5543 (df = 2)   AIC:     107.1   BIC:     112.7   (MC std. err. =       0)
```

```stata
. nwergm flomiss, edges nodecov(wealth)
Note: network flomiss has 3 missing dyad(s); they are excluded from the (pseudo)likelihood and handled as in R's ergm (mi
> ssing-data MCMLE).
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
Log-likelihood:   -49.1649 (df = 2)   AIC:     102.3   BIC:     107.9   (MC std. err. =       0)
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
         edges |  -2.695761   .5798708    -4.65   0.000    -3.832287   -1.559235
nodecov_wealth |   .0110237   .0055696     1.98   0.048     .0001075    .0219399
     gwesp_0.5 |   .0274984   .2881655     0.10   0.924    -.5372955    .5922923
--------------------------------------------------------------------------------

MCMLE converged after 1 iteration(s).
...
Log-likelihood:   -49.1563 (df = 3)   AIC:     104.3   BIC:     112.6   (MC std. err. =  .00172)
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
         edges |  -2.740879   .0801423   -34.20   0.000    -2.897955   -2.583803
        mutual |    .991566   .1626233     6.10   0.000     .6728302    1.310302
nodematch_prac |    .907421   .0921732     9.84   0.000     .7267649    1.088077
--------------------------------------------------------------------------------

MCMLE converged after 4 iteration(s).
...
Log-likelihood: -1701.9440 (df = 3)   AIC:    3409.9   BIC:    3429.4   (MC std. err. =  .06952)
```

```stata
. nwergm lazega_fr, edges mutual nodematch(prac) gwesp(0.5) seed(1)
...
--------------------------------------------------------------------------------
     lazega_fr | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
---------------+----------------------------------------------------------------
         edges |  -3.477526   .1008631   -34.48   0.000    -3.675214   -3.279838
        mutual |   .8207466   .1635668     5.02   0.000     .5001615    1.141332
nodematch_prac |   .7016325   .0845186     8.30   0.000     .5359792    .8672859
     gwesp_0.5 |    .496614   .0584773     8.49   0.000     .3820006    .6112274
--------------------------------------------------------------------------------

MCMLE converged after 6 iteration(s).
...
Log-likelihood: -1670.9684 (df = 4)   AIC:    3349.9   BIC:    3376.0   (MC std. err. =  .17019)
```

`estat ic` shows the information criteria of the last fit; `estimates stats` puts the stored models in
one table (compare models only if N is the same):

```stata
. estat ic

Akaike's information criterion and Bayesian information criterion

-----------------------------------------------------------------------------
       Model |        N     ll(null)    ll(model)    df       AIC       BIC
-------------+---------------------------------------------------------------
   lazega_fr |     4970      -3444.9        -1671     4    3349.9      3376
-----------------------------------------------------------------------------
Note: BIC uses N = number of informative dyads; MC std. err. of the log-likelihood =  .17019
```

```stata
. estimates stats m1 m2

Akaike's information criterion and Bayesian information criterion

-----------------------------------------------------------------------------
       Model |          N   ll(null)  ll(model)      df        AIC        BIC
-------------+---------------------------------------------------------------
          m1 |      4,970  -3444.941  -1701.944       3   3409.888   3429.422
          m2 |      4,970  -3444.941  -1670.968       4   3349.937   3375.981
-----------------------------------------------------------------------------
Note: BIC uses N = number of observations. See [R] IC note.
```

Lower AIC and BIC are better. Adding `gwesp(0.5)` lowers AIC from 3409.9 to 3349.9 and BIC from 3429.4
to 3376.0: the closure term earns its place by both criteria. The log-likelihood of a model with
dependence is evaluated by bridge sampling, which is a simulation: the footer of each fit and of `estat ic`
shows its Monte Carlo standard error (here about 0.1), which should be small relative to the differences you
interpret. For nested models the likelihood-ratio test is also available:

```stata
. lrtest m2 m1

Likelihood-ratio test
Assumption: m1 nested within m2

 LR chi2(1) =  61.95
Prob > chi2 = 0.0000
```

The test statistic is 61.95 on one degree of freedom, a strong rejection of the model without closure.
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
           p |      4,970    .1157708    .0926077   .0299585   .8028117
```

```stata
. frame pp: list in 1/5

     +-------------------------+
     | tail   head           p |
     |-------------------------|
  1. |    1      2   .02995849 |
  2. |    1      3   .36097975 |
  3. |    1      4   .10338511 |
  4. |    1      5   .30611146 |
  5. |    1      6   .03618957 |
     +-------------------------+
```

The mean probability, 0.116, is close to the density of the network (0.116). Use `xb` instead of `pr` for
the conditional log-odds.

## Things to try

- Blank out more dyads (10 or 20) and watch how the standard errors grow.
- Add `nodeicov(seniority)` to the Lazega model and compare AIC and BIC with `estimates stats`.
- Compare `gwesp(0.25)`, `gwesp(0.5)` and `gwesp(1)` by AIC.
- Use `predict, matrix(P) pr` and look at the highest probabilities among the dyads that are not tied.

## Where next

[Tutorial 5](../tutorial-5-constraints-twomode-operators/) covers constraints on the sample space,
two-mode networks and the operators. The details on missing data and fit statistics are in `help nwergm_fit`.
