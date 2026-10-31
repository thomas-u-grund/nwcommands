---
title: "Tutorial 13: Testing hypotheses about networks"
parent: "nwcommands (core)"
nav_order: 13
description: "Why ordinary tests fail for network data, and the three tests in nwcommands: conditional uniform graph tests (nwcug), QAP correlation (nwcorrelate) and QAP regression (nwqap)."
---

# Tutorial 13: Testing hypotheses about networks

Ordinary significance tests assume that observations are independent. The ties of a network are not: the
same node takes part in many of them. Standard errors from a regression on pairs of nodes are therefore too
small, and "significant" results too frequent. The tests in this tutorial avoid the assumption by comparing
the observed result with **a reference distribution made by computer**: a large number of random networks
(CUG test), or the same network with its nodes randomly relabelled (QAP). The p-value is the share of
random results at least as extreme as what you observed.

The script is [`example.do`](example.do), the complete output [`example.log`](example.log).

## Is a statistic unusual for this size and density? `nwcug`

Many statistics depend mechanically on density: a network with many ties has more triangles and fewer
components almost automatically. A **conditional uniform graph (CUG) test** (Anderson, Butts and Carley
1999) asks whether a statistic is unusual *given only the number of nodes and the density*. `nwcug` draws
random networks with the same size and density, computes your statistic on each, and compares.

You give `nwcug` the command that computes the statistic, with the token `##net##` where the network name
goes, and the name of the `r()` result to use:

```stata
. nwwebuse florentine, nwclear

. nwcug flomarriage, stat(nwtriads ##net##) rname(transitivity) reps(500) seed(12345)
----------------------------------------
  Network: flomarriage
  Statistic: nwtriads ##net##/r(transitivity)
  Observed: .191
  Null mean (sd): .149 (.082)
  Reps: 500
  p (upper tail): .316
  p (lower tail): .696
  p (two-sided): .632
----------------------------------------
```

The Florentine marriage network has transitivity .19; random networks with its 16 nodes and 20 ties
average .15 (standard deviation .08). The observed value is well within the range of chance (two-sided
p = .63), so with this small network we cannot say that marriage ties close triangles more than random
ties would. `seed()` makes the result reproducible.

A command that needs further options gets them inside `stat()`. `nwcomponents` requires `generate()`, and
it runs once for each random network, so add `replace`:

```stata
. nwcug flomarriage, stat(nwcomponents ##net##, generate(cc) replace silent) rname(components) reps(500) seed(12345)
----------------------------------------
  Network: flomarriage
  Statistic: nwcomponents ##net##, generate(cc) replace silent/r(components)
  Observed: 2
  Null mean (sd): 1.986 (.812)
  Reps: 500
  p (upper tail): .706
  p (lower tail): .762
  p (two-sided): 1
----------------------------------------
```

Two components (a main one and an isolate) is just what a random network of this density would give.
`condition()` changes the null model: for directed networks `census` keeps the dyad census, and for
two-mode networks `degrees` keeps the degree sequences (see the [two-mode tutorial](../11-two-mode-networks/)).
`plot` draws a histogram of the null draws with the observed value marked.

## Is one network related to another? QAP correlation

Is the friendship network of wave 2 related to that of wave 1? `nwcorrelate` gives the correlation between
the tie cells of two networks over the same nodes. The permutation test is the **quadratic assignment
procedure (QAP)**: the rows and columns of one network are permuted together, which keeps its structure but
destroys its link to the other, and the correlation is recomputed `permutations()` times.

```stata
. nwwebuse glasgow, nwclear

. nwcorrelate glasgow1 glasgow2, permutations(500)
----------------------------------------
  Network1 name: glasgow1
  Network2 name: glasgow2
----------------------------------------
    Correlation: .473
    P-value: 0
```

A p-value of 0 means that no permuted network reached .473 in 500 tries; report it as p < 1/500 = .002.

## What explains the ties? QAP regression

`nwqap` regresses a network (the first name) on other networks and on node attributes, with p-values from
the same QAP permutations. A numeric attribute is turned into a "same value" network (`same_smoke1`: 1 if the two pupils have the
same smoking category):

```stata
. nwqap glasgow2 glasgow1 smoke1 sport1


Multiple Regression Quadratic Assignment Procedure

  Estimation            =  QAP
  Regression            =  logit
  Permutations          =  500
  Number of vertices    =  50
  Number of arcs        =  116

-------------------------------------------------
              glasgow2 |      Coef.    P-value
-----------------------+-------------------------
              glasgow1 |      3.653        0
           same_smoke1 |       .514     .042
           same_sport1 |       .217     .344
                 _cons |     -4.125
-------------------------------------------------
```

The model is a logit for the presence of a tie in wave 2. A friendship that existed in wave 1 raises the log-odds
of a friendship in wave 2 by 3.65 (an odds ratio of about 39), even with the other terms held fixed. Pupils with
the same smoking category are more likely to be friends (coefficient .51, p = .042), but the same sport category
shows no clear effect (p = .34). The coefficients are those of an ordinary logit; only the p-values come from the permutations.

## Which test when?

| Question | Command |
|---|---|
| Is this statistic of one network unusual for its size and density? | `nwcug` |
| Are two networks on the same nodes associated? | `nwcorrelate, permutations()` |
| Which networks and attributes explain the ties? | `nwqap` |

These tests treat the network as the thing to explain and assume one set of nodes. For models of how a
network *changes*, see [nwsaom](../../nwsaom/); for a model of a single observed network, see
[nwergm](../../nwergm/).
