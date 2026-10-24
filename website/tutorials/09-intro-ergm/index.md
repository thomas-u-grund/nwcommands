---
title: "Intro to ERGM in Stata"
parent: "nwergm (ERGM)"
nav_order: 1.5
description: "Exponential-family random graph models with the nwergm package: a first model, missing data, information criteria and goodness of fit."
---

# Intro to ERGM in Stata

Every tutorial so far has treated a network's structure as a fixed thing to *describe* — count
ties, compute centrality, extract a path. An **exponential-family random graph model (ERGM)**
turns that around: instead of describing one observed network, it asks what statistical process
could plausibly have *generated* it, and estimates that process from the data.

## Installing nwergm

`nwergm` is its own package (GPL-3), separate from the core `nwcommands`. Install the core first
(see [Installation & Setup](../01-installation-setup/)), then the model package:

```stata
net install nwergm, from(https://raw.githubusercontent.com/thomas-u-grund/nwergm/main/)
```

or, with the core's installer, `nwinstall, modelpkg(nwergm)`. Check what you have with
`nwergm version`, which prints the package release and stores it in `r(version)`:

```stata
. nwergm version
nwergm version 1.0.1, 24oct2026
```


The same page of output also names the core package and the native plugin the package uses. The
examples below were run with nwergm 1.0.1 and the core `nwcommands` 3.0.0.

## The idea

An ERGM models the probability of the entire observed network as a function of a handful of
network statistics — how many ties there are, whether ties tend to cluster into triangles,
whether nodes with the same attribute tend to tie to each other, and so on. Each statistic gets
its own coefficient, estimated so that the statistics of the *observed* network are about as
likely as possible under the fitted model. A coefficient's sign and size then say whether that
particular structural or covariate effect makes a tie more or less likely, holding the others
fixed — the same logic as a logistic regression coefficient, because a dyad-independent ERGM
*is* one.

## A minimal example

Every `nwergm` model needs an `edges` term — it plays the role of the intercept, and by itself
gives a model where every potential tie is equally likely:

```stata
. nwwebuse florentine, nwclear
```

```stata
. nwergm flomarriage, edges

Exponential-family random graph model

Network:               =  flomarriage
Nodes:                 =  16
Ties:                  =  20
Directed:              =  No
Estimation:            =  MPLE

------------------------------------------------------------------------------
 flomarriage | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
       edges |  -1.609438    .244949    -6.57   0.000    -2.089529   -1.129347
------------------------------------------------------------------------------

Maximum pseudolikelihood estimate (not full ERGM maximum likelihood unless the model is dyad-independent).

             Null Deviance:     166.4  on 120 degrees of freedom
         Residual Deviance:     108.1  on 119 degrees of freedom

Log-likelihood:   -54.0673 (df = 1)   AIC:     110.1   BIC:     112.9   (MC std. err. =       0)
```


That coefficient isn't arbitrary — for an edges-only model it's exactly the log-odds of the
network's own density: `flomarriage` has 20 ties out of 120 possible dyads (density ≈ 0.167), and
`logit(0.167) ≈ -1.609`, matching the output above. Because every term here is dyad-independent,
the pseudolikelihood estimate *is* the maximum likelihood estimate, and the footer reports the
log-likelihood, AIC and BIC.

Adding a covariate asks a real question: are wealthier families more likely to have married
into each other?

```stata
. nwergm flomarriage, edges nodecov(wealth)

Exponential-family random graph model

Network:               =  flomarriage
Nodes:                 =  16
Ties:                  =  20
Directed:              =  No
Estimation:            =  MPLE

--------------------------------------------------------------------------------
   flomarriage | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
---------------+----------------------------------------------------------------
         edges |  -2.594929   .5360561    -4.84   0.000     -3.64558   -1.544278
nodecov_wealth |   .0105459   .0046743     2.26   0.024     .0013845    .0197073
--------------------------------------------------------------------------------

Maximum pseudolikelihood estimate (not full ERGM maximum likelihood unless the model is dyad-independent).

             Null Deviance:     166.4  on 120 degrees of freedom
         Residual Deviance:     103.1  on 118 degrees of freedom

Log-likelihood:   -51.5543 (df = 2)   AIC:     107.1   BIC:     112.7   (MC std. err. =       0)
```


`nodecov_wealth` is positive and significant (p = 0.024): combined family wealth is associated
with a higher chance of a marriage tie, controlling for the baseline density captured by `edges`.
`estat ic` repeats the information criteria in a table that is convenient for comparing models:

```stata
. estat ic

Akaike's information criterion and Bayesian information criterion

-----------------------------------------------------------------------------
       Model |        N     ll(null)    ll(model)    df       AIC       BIC
-------------+---------------------------------------------------------------
 flomarriage |      120      -83.178      -51.554     2    107.11    112.68
-----------------------------------------------------------------------------
Note: BIC uses N = number of informative dyads; MC std. err. of the log-likelihood =       0
```


## Triadic closure and MCMC estimation

Terms that depend on other ties, such as `gwesp()` (geometrically weighted edgewise shared
partners, a smooth measure of triadic closure), make the model dyad-dependent. `nwergm` then
switches to Monte Carlo maximum likelihood on its own; `seed()` makes the run reproducible:

```stata
. nwergm flomarriage, edges gwesp(.5) seed(1)

Exponential-family random graph model

Network:               =  flomarriage
Nodes:                 =  16
Ties:                  =  20
Directed:              =  No
Estimation:            =  MCMLE
MCMC sample size:      =  3000

------------------------------------------------------------------------------
 flomarriage | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
       edges |  -1.726681   .3662283    -4.71   0.000    -2.444476   -1.008887
    gwesp_.5 |   .1042924    .263231     0.40   0.692    -.4116309    .6202157
------------------------------------------------------------------------------

MCMLE converged after 1 iteration(s).
Evaluating log-likelihood at the estimate (bridge sampling with 16 bridges) ...

             Null Deviance:     166.4  on 120 degrees of freedom
         Residual Deviance:     108.0  on 118 degrees of freedom

Log-likelihood:   -54.0058 (df = 2)   AIC:     112.0   BIC:     117.6   (MC std. err. =  .00591)
```


Here the closure term is small and not significant once the density is accounted for, in line
with the wealth effect being the more important explanation for these marriages.

## Goodness of fit

`estat gof` simulates networks from the fitted model and compares the observed network with them
on the model's own statistics and on geodesic distances, degrees and edgewise shared partners
(output shortened to the first table):

```stata
. estat gof

Goodness-of-fit for model statistics

                       obs       min      mean       max  MC p-value
edges                   20        12     20.17        30        1.00
gwesp_.5         8.3934693-1.510e-14      8.17 25.725357        0.92
```

A Monte Carlo p-value close to zero for a statistic means the model does not reproduce that
feature of the network; here none of the tables flags a problem.
After an MCMC fit, `estat mcmcdiag` reports diagnostics of the simulation itself.

## Where to go from here

`nwergm` follows R's `ergm` closely: besides the terms above it has homophily and mixing terms
(`nodematch()`, `nodefactor()`, `nodemix()`), degree and star terms, directed and two-mode
variants, curved terms with an estimated decay (`gwespfree()`), constraints, `predict`, and the
handling of missing dyads (they are dropped from the likelihood, as in R). See the
[`nwergm` reference page](../../reference/nwergm) for the package, its help file and the full
term list.
