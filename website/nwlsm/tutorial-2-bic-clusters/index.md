---
title: "Tutorial 2: How many latent clusters?"
parent: "nwlsm (latent space)"
nav_order: 3
description: "Choose the number of latent clusters of a latent space model with the BIC (estat bic and nwlsmselect) on the Lazega lawyers, read the parts of the BIC, the effect of random sender and receiver effects, and goodness of fit for binary and valued networks."
---

# Tutorial 2: How many latent clusters?

**Goal.** Compare latent space models with 0, 2, 3 and 4 clusters by the BIC, read what the parts of the BIC mean, see how random sender and receiver effects change the picture, and check the fit of the model you chose, for a binary and for a valued network.

**Data.** Lazega's lawyers: 71 lawyers of a corporate law firm and three directed networks among them, advice, co-work and friendship. Here we use friendship (`lazega_fr`, 575 ties).
Source: Lazega, E. (2001), *The Collegial Phenomenon*, Oxford University Press; Lazega, E. and van Duijn, M. (1997), *Social Networks* 19, 375-397;
loaded with `nwwebuse lazega` (see the [data sets page](../../datasets/)). You need the core `nwcommands` and the `nwlsm` package (see [Install](../install/)); the commands were run with `nwlsm` 0.7.0 under Stata 17.
The complete script and log are in [example.do](example.do) and [example.log](example.log). [Tutorial 1](../tutorial-1-first-lsm/) explains the model and the sampler; read it first.

## Why clusters, and why the BIC

A latent space model puts the actors in a plane. With `clusters(#)` the positions are not drawn from one normal distribution around the centre but from a mixture of that many normal distributions: the actors fall into groups that lie together in the space.
How many groups? The data do not say directly. The Bayesian information criterion (BIC) is the usual rough guide: it rewards a model for fitting the data and charges it for each additional parameter. Smaller is better, and only differences between models fitted to the same network matter.

## The BIC of one model

```stata
. nwwebuse lazega, nwclear
. nwlsm lazega_fr, dim(2) seed(12)
. estat bic

BIC of the latent position model (as latentnet's bic.ergmm)
--------------------------------------------
Component                                BIC
--------------------------------------------
Ties given positions (Y)            3016.530
Positions (Z)                        450.588
--------------------------------------------
Overall                             3467.118
--------------------------------------------
Latent clusters: 0; coefficients: 1; effective number of observations (ties): 575
```

`estat bic` follows `bic.ergmm()` of the R package `latentnet`. The overall BIC is a sum of parts. The part for the ties given the positions (Y) is minus twice the log likelihood of the ties plus a charge of the number of coefficients times the log of the effective number of observations;
by default that number is the number of ties, here 575. The part for the positions (Z) is the same kind of number for the positions themselves: how well a normal distribution, or with clusters a mixture of normal distributions, describes where the 71 actors lie. A cluster model can only gain in this part.
Random effects, if present, add a part of their own, as we see below. The BIC is computed at the minimum Kullback-Leibler positions, which are the positions `estat positions` reports.

## Comparing 0, 2, 3 and 4 clusters

```stata
. nwlsmselect lazega_fr, clusters(0 2 3 4) seed(12)

------------------------------------------------------------------------
  Clusters         BIC     BIC (Y)     BIC (Z) Mean loglik   BIC - min
------------------------------------------------------------------------
         2    3453.132    3025.173     427.958   -1553.335       0.000  <- best
         3    3460.268    3025.865     434.403   -1553.315       7.136
         0    3467.118    3016.530     450.588   -1551.040      13.986
         4    3467.777    3026.681     441.096   -1553.541      14.646
------------------------------------------------------------------------
```

`nwlsmselect` fits the model once for every number of clusters in `clusters()`, with the same options and the same seed, and ranks the fits by BIC. Zero clusters means no clusters. The table gives the two parts, the posterior mean log likelihood and the distance to the best BIC; the table is also stored in `r(table)` and the best number of clusters in `r(best)` (here 2).

Read the parts. The part for the ties barely moves: 3016.5 without clusters, between 3025.2 and 3026.7 with them. The mean log likelihood is about the same too. The clusters do not help to explain the ties.
What changes is the part for the positions: with two clusters it falls from 450.6 to 428.0. The gain is 22.6 and the clusters cost nothing in the ties part beyond 8.6, so two clusters win by 14.0 points. Three and four clusters add parameters to the mixture without
a matching gain, and four clusters are no better than none. A difference of about 10 points is usually called strong, a difference below 2 or 3 hardly worth mentioning. The BIC is a rough guide, and `latentnet` itself warns that it is not certain to be right for comparing clustered with unclustered models.

## Random sender and receiver effects

The friendship network is directed. Some lawyers name many friends, some name few, and some are named more often than others. A latent space model with distances alone cannot say this; `sender` and `receiver` give every actor a random effect for the tendency to send and to receive ties.

```stata
. nwlsmselect lazega_fr, clusters(0 2 3 4) sender receiver seed(12) refit
. estat bic

------------------------------------------------------------------------
  Clusters         BIC     BIC (Y)     BIC (Z) Mean loglik   BIC - min
------------------------------------------------------------------------
         2    3364.487    2820.765     421.804   -1487.138       0.000  <- best
         3    3364.575    2823.273     419.268   -1487.955       0.088
         4    3367.102    2821.847     422.803   -1487.436       2.615
         0    3379.585    2815.788     441.720   -1486.275      15.098
------------------------------------------------------------------------

BIC of the latent position model (as latentnet's bic.ergmm)
--------------------------------------------
Component                                BIC
--------------------------------------------
Ties given positions (Y)            2820.765
Positions (Z)                        421.804
Random effect: sender                104.889
Random effect: receiver               17.029
--------------------------------------------
Overall                             3364.487
--------------------------------------------
Latent clusters: 2; coefficients: 1; effective number of observations (ties): 575
```

`refit` fits the best model again so that it is the active model afterwards, and `estat bic` then shows its parts. Now there are two more parts, one for the sender effects (104.9) and one for the receiver effects (17.0).
The sender effects matter more than the receiver effects, which is also visible in the variances: the posterior mean of the sender variance is 0.41, of the receiver variance 0.22. The part for the ties falls from about 3025 to 2821.

The overall BIC of the best model is 3364.5, against 3453.1 without the effects: random effects pay off for these data. The choice of the number of clusters is less clear than before. Two clusters beat three by only 0.09 points, and four clusters are 2.6 points behind.
The no-cluster model is still 15.1 behind. So the BIC supports some clustering, but not a particular number of clusters; take the smallest, two, and do not read the difference to three as a finding.

## How clear are the clusters?

A model with two clusters does not by itself mean that there are two clearly separate groups. The posterior membership probabilities say how sure the model is about each actor.

```stata
. estat clusters, generate(grp) nolist
. tabulate grp_class

  grp_class |      Freq.     Percent        Cum.
------------+-----------------------------------
          2 |         71      100.00      100.00
------------+-----------------------------------
      Total |         71      100.00

. summarize grp_p1 grp_p2

    Variable |        Obs        Mean    Std. dev.       Min        Max
-------------+---------------------------------------------------------
      grp_p1 |         71    .3669366    .0465165     .28925        .46
      grp_p2 |         71    .6330634    .0465165        .54     .71075
```

This is the sobering part. All 71 actors are classified into cluster 2, and the probability of that cluster lies between 0.54 and 0.71 for everyone. The two clusters are not separated: the mixture describes the positions slightly better than one normal distribution does, but it
does not hand us two groups of lawyers. The BIC difference is real but the clusters are weak. Do not use `grp_class` as a grouping variable here. A model with a different number of dimensions or other covariates (`absdiff()`) is the next thing to try.

## The default number of starting points

The positions and effects in the BIC come from an optimisation, the minimum Kullback-Leibler fit, which can end in a poor local optimum. With `sender`, `receiver` or `sociality`, `nwlsm` starts it from four points by default and keeps the best result (`e(mklstarts)` is 4); without random effects it uses one, as `latentnet` does.
You can set it with `mklstarts(#)`. In this example the choice hardly matters: with `mklstarts(1)` the overall BIC is 3364.471 instead of 3364.487. The default protects against fits that end in a bad optimum, where the parts of the BIC for the random effects jump upward, and costs a little time.

## The effective number of observations

```stata
. estat bic, effobs(actors)
...
Ties given positions (Y)            2818.674
Positions (Z)                        421.804
...
Overall                             3362.395
```

The charge of the BIC for the coefficients uses the log of an effective number of observations. The default is the number of ties (575). `effobs(dyads)` and `effobs(actors)` use the number of dyads or of actors (71) instead. Only the part for the ties changes:
2820.8 becomes 2818.7. With one coefficient the choice moves the BIC by about two points, less than most differences above. It matters more when you compare models with many coefficients.

## Goodness of fit, binary and valued

The BIC says which model is best of those you tried, not that it is good. `estat gof` simulates networks from the fitted model and compares them with the observed one (Tutorial 1 shows the degree table). For the directed friendship network, here is the distribution of geodesic distances:

```stata
. estat gof, gof(distance) nsim(100) seed(1)

Goodness of fit: minimum geodesic distance (100 networks simulated from the posterior)
------------------------------------------------------------------
    Distance |  Observed       Min      Mean       Max  MC p-value
-------------+----------------------------------------------------
           1 |       575       496    577.35       647        0.90
           2 |      2316      1856   2272.55      2630        0.88
           3 |      1782      1556   1758.89      2060        0.76
           4 |       154       121    261.43       598        0.12
           5 |         3         0     15.54       121        0.42
           6 |         0         0      0.56        10        1.00
           7 |         0         0      0.02         2        1.00
         Inf |       140         0     83.66       412        0.50
------------------------------------------------------------------
```

The observed counts are close to the simulated means and every Monte Carlo p-value is above 0.1: the model reproduces the distances in this network well. The simulated networks vary a lot in the long distances (up to 598 pairs at distance 4), because some simulated networks have isolated actors.

For a valued network the dyads carry values, not only ties. Here is a count of how many of the three relations hold for a pair of lawyers, 0 to 3, built with `nwgen` and fitted with the binomial family and three trials:

```stata
. nwgen lazega_all = lazega_fr + lazega_adv + lazega_cow
. nwlsm lazega_all, family(binomial) trials(3) dim(2) sender receiver seed(12)
. estat gof, gof(distance values) nsim(100) seed(1)

Goodness of fit: tie values (100 networks simulated from the posterior)
------------------------------------------------------------------
       Value |  Observed       Min      Mean       Max  MC p-value
-------------+----------------------------------------------------
           0 |      3396      3093   3173.62      3253        0.00
           1 |       824      1105   1178.00      1242        0.00
           2 |       503       396    472.04       524        0.16
           3 |       247       116    146.34       179        0.00
------------------------------------------------------------------
```

The table of values counts the dyads with each value. The model puts too few pairs at 0 and at 3 and too many at 1: the observed pairs have either none of the relations or all three more often than three independent trials with a pair-specific probability would give. The relations of a pair go together more than this model allows.
The model, and with it the binomial family, is a poor description of this combined network.

For valued networks the structure statistics (degrees, shared partners, distances) are computed on a binary network, the dyads with a value above 0 by default. `cutoff(#)` moves that threshold; the observed and the simulated networks are cut in the same way:

```stata
. estat gof, gof(distance) nsim(100) seed(1) cutoff(1)
...
Degree, shared partners and distances are those of the network of the dyads
with a value above 1.
```

With `cutoff(1)` the network has the pairs with at least two of the three relations, 750 pairs against 618 on average in the simulated networks (the full table is in [example.log](example.log)). A cutoff lets you ask whether the model reproduces the structure of the strong ties alone.

## What to remember

- `estat bic` splits the BIC into a part for the ties given the positions, a part for the positions and a part for each random effect. Compare models of the same network only, and read the parts, not only the sum.
- `nwlsmselect` fits the model for several numbers of clusters and ranks them. With `refit` the best model is the active one afterwards.
- A small BIC difference (here 0.09 between two and three clusters) is no finding. A BIC that prefers clusters does not mean that the clusters are clear: check the membership probabilities with `estat clusters`.
- Random sender and receiver effects change the BIC a lot for a directed network. Check them before spending effort on clusters.
- The BIC chooses among models; `estat gof` tells you whether the best of them is any good. For valued networks use `cutoff()` to look at the strong ties.
- For a stochastic block model of a network, where the number of blocks is chosen by a likelihood criterion, see the [nwsbm tutorial](../../nwsbm/tutorial-1-first-sbm/).
