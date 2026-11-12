---
title: "Tutorial 18: Testing Hypotheses about Networks"
parent: "nwcommands (core)"
nav_order: 18
description: "Why ordinary tests fail for network data, and the three tests in nwcommands: conditional uniform graph tests (nwcug), QAP correlation (nwcorrelate) and QAP regression (nwqap)."
---

# Tutorial 18: Testing Hypotheses about Networks

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

You give `nwcug` the command that computes the statistic and the name of the `r()` result to use. `nwcug`
runs the command on the observed network and on every random network, each time with that network's name
after the command name. Any command, or a program of your own, that leaves a number in `r()` will do. If the
network is not the first argument, mark its place with the token `##net##`, for example
`stat(nwcorrelate other ##net##) rname(corr)`:

```stata
. nwwebuse florentine, nwclear

. nwcug flomarriage, stat(nwtriads) rname(transitivity) reps(500) seed(12345)

Conditional uniform graph test                   Number of draws =        500
Network: flomarriage                             Condition       =    density
Statistic: r(transitivity) after nwtriads flomarriage

---------------------------------------------------------------------------
             |  Observed Null mean   Null sd  P >= obs  P <= obs Two-sided
-------------+-------------------------------------------------------------
transitivity |  .1914894  .1487523  .0819702    0.3174    0.6966    0.6347
---------------------------------------------------------------------------
```

The Florentine marriage network has transitivity .19; random networks with its 16 nodes and 20 ties
average .15 (standard deviation .08). The observed value is well within the range of chance (two-sided
p = .64), so with this small network we cannot say that marriage ties close triangles more than random
ties would. `seed()` makes the result reproducible.

A command that needs further options gets them inside `stat()`. `nwcomponents` requires `generate()`, and
it runs once for each random network, so add `replace`:

```stata
. nwcug flomarriage, stat(nwcomponents, generate(cc) replace silent) rname(components) reps(500) seed(12345)

Conditional uniform graph test                   Number of draws =        500
Network: flomarriage                             Condition       =    density
Statistic: r(components) after nwcomponents flomarriage, generate(cc) replace silent

---------------------------------------------------------------------------
             |  Observed Null mean   Null sd  P >= obs  P <= obs Two-sided
-------------+-------------------------------------------------------------
  components |         2     1.986  .8118634    0.7066    0.7625    1.0000
---------------------------------------------------------------------------
```

Two components (a main one and an isolate) is just what a random network of this density would give.
`plot` draws a histogram of the null draws with the observed value marked.

### Holding the degrees fixed

Random networks of the same density are a weak baseline when the degrees are very unequal: a few
well-connected nodes alone produce triangles. `condition(degrees)` keeps every node's degree (in a
directed network its out-degree and in-degree) and randomizes everything else, by exchanging the partners
of two ties at random (the `rewire(keeping_degseq())` of `igraph`):

```stata
. nwcug flomarriage, stat(nwtriads) rname(transitivity) condition(degrees) reps(500) seed(12345)

Conditional uniform graph test                   Number of draws =        500
Network: flomarriage                             Condition       =    degrees
Statistic: r(transitivity) after nwtriads flomarriage

---------------------------------------------------------------------------
             |  Observed Null mean   Null sd  P >= obs  P <= obs Two-sided
-------------+-------------------------------------------------------------
transitivity |  .1914894  .1604681  .0796446    0.4810    0.7984    0.9621
---------------------------------------------------------------------------
```

Holding every family's number of marriages fixed raises the expected transitivity from .15 to .16:
part of the clustering is a consequence of the degrees. The observed .19 is still well within chance.
The other null models of `condition()` are `census` for a directed network (it keeps the dyad census)
and, for two-mode networks, `degrees`, `mode1degree` and `mode2degree` (see the
[two-mode tutorial](../15-two-mode-networks/)). To draw such networks yourself, use `nwrandom` with
`degree()` or `nwpermute` with `swap` ([Tutorial 6](../06-generating-networks/)).

## Is one network related to another? QAP correlation

Is the friendship network of wave 2 related to that of wave 1? `nwcorrelate` gives the correlation between
the tie cells of two networks over the same nodes. The permutation test is the **quadratic assignment
procedure (QAP)**: the rows and columns of one network are permuted together, which keeps its structure but
destroys its link to the other, and the correlation is recomputed `permutations()` times.

```stata
. nwwebuse glasgow, nwclear

. nwcorrelate glasgow1 glasgow2, permutations(500)

Network correlation                              Permutations    =        500
Network 1: glasgow1
Network 2: glasgow2

----------------------------------------------------------
 Correlation     P-value   [95% permutation interval]
----------------------------------------------------------
   .47324572      0.0040      -.03985912   .04260416
----------------------------------------------------------
```

The p-value counts the observed correlation as one more draw of the null, so it is never 0: with 500 permutations the smallest two-sided value is 2/501 = .004, and .004 here means that no permuted network reached .473. Report it as p < .004. The permutation interval holds the middle 95% of the permuted correlations, from -.040 to .043.

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
              glasgow1 |      3.653     .002
           same_smoke1 |       .514     .044
           same_sport1 |       .217     .345
                 _cons |     -4.125
-------------------------------------------------
```

The model is a logit for the presence of a tie in wave 2. A friendship that existed in wave 1 raises the log-odds
of a friendship in wave 2 by 3.65 (an odds ratio of about 39), even with the other terms held fixed. Pupils with
the same smoking category are more likely to be friends (coefficient .51, p = .044), but the same sport category
shows no clear effect (p = .35). The coefficients are those of an ordinary logit; only the p-values come from the permutations.

## Which test when?

| Question | Command |
|---|---|
| Is this statistic of one network unusual for its size and density? | `nwcug` |
| ... and for its degrees? | `nwcug, condition(degrees)` |
| Are two networks on the same nodes associated? | `nwcorrelate, permutations()` |
| Which networks and attributes explain the ties? | `nwqap` |

These tests treat the network as the thing to explain and assume one set of nodes. For models of how a
network *changes*, see [nwsaom](../../nwsaom/); for a model of a single observed network, see
[nwergm](../../nwergm/).
