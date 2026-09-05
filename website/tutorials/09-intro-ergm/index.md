---
title: "Intro to ERGM in Stata"
parent: Tutorials
nav_order: 9
description: "What an exponential-family random graph model is, and a minimal nwergm example."
---

# Intro to ERGM in Stata

Every tutorial so far has treated a network's structure as a fixed thing to *describe* — count
ties, compute centrality, extract a path. An **exponential-family random graph model (ERGM)**
turns that around: instead of describing one observed network, it asks what statistical process
could plausibly have *generated* it, and estimates that process from the data.

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
```

That coefficient isn't arbitrary — for an edges-only model it's exactly the log-odds of the
network's own density: `flomarriage` has 20 ties out of 120 possible dyads (density ≈ 0.167), and
`logit(0.167) ≈ -1.609`, matching the output above.

Adding a covariate term asks a real question: are wealthier families more likely to have married
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
```

`nodecov_wealth` is positive and significant (p = 0.024): combined family wealth is associated
with a higher chance of a marriage tie, controlling for the baseline density captured by `edges`.

## Where to go from here

`nwergm` supports a large family of additional terms beyond `nodecov()` — homophily
(`nodematch()`), triadic closure (`gwesp()`), degree-distribution effects, directed and two-mode
variants, and both MPLE and full MCMC maximum-likelihood (`method(mcmle)`) estimation — see the
[command reference](../../reference/nwergm) for the complete term list. A forthcoming Stata Press
book covers ERGM (and the longitudinal models in the next tutorial) in full depth: model
selection, goodness-of-fit diagnostics, convergence checking for MCMC estimation, and worked
applications beyond this orientation.
