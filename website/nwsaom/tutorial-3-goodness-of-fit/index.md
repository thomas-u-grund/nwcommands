---
title: "Tutorial 3: Goodness of fit"
parent: "nwsaom (SAOM)"
nav_order: 4
description: "Check how well an nwsaom model describes the Glasgow friendship network with estat gof, read the violin plots, and improve a poorly fitting model."
---

# Tutorial 3: Goodness of fit, and fixing a poor model

**Goal.** A converged model is not necessarily a good model. Here you learn to ask whether the
model can reproduce features of the data that you did *not* put into it, and what to do when it
cannot.

**Data.** The Glasgow friendship data (see [Tutorial 1](../tutorial-1-first-saom/)). Script and
log: [example.do](example.do), [example.log](example.log).

## The idea

A fitted SAOM can be used as a simulator. `estat gof` simulates the model many times at the
estimated coefficients (100 here, with `nsim(100)`) and compares the simulated end networks with the observed one on a
statistic you did not fit directly. The default statistics are the same three that RSiena's
`sienaGOF` uses: the out-degree distribution, the in-degree distribution and the distribution of
geodesic distances ("how many pairs are 1, 2, 3, ... steps apart, or not reachable at all").
A test then asks whether the observed value lies inside the cloud of simulated ones. It is the
Mahalanobis-distance test of Lospinoso and Snijders (2019), and a small p-value (below 0.05) is
evidence **against** the model on that statistic. A large p-value is not proof that the model is right; it only means that this
particular check did not find a problem.

## A thin model

Start with the two effects that every model has, `outdegree` and `reciprocity`:

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity seed(1)
...
------------------------------------------------------------------------------
glasgow1_t~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.379527   .1023186   -23.26   0.000    -2.580068   -2.178986
 reciprocity |    2.86167   .1785912    16.02   0.000     2.511638    3.211703
------------------------------------------------------------------------------
...
Overall maximum convergence ratio: 0.055 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

The model converged. Is it any good?

```stata
. estat gof, nsim(100) seed(7)

Goodness of fit: Mahalanobis distance test
100 simulations at the estimates, 2 periods pooled

------------------------------------------------------
           Statistic |   Mahalanobis  P-value      Fit
---------------------+--------------------------------
           Outdegree |         5.360    0.600       ok
            Indegree |         9.098    0.300       ok
            Geodesic |       198.018    0.000 rejected
------------------------------------------------------
rejected: P < 0.05 (one-tailed); the model does not reproduce this statistic
Violin plots: gof_outdegree gof_indegree gof_geodesic
```

The degree distributions are reproduced, but the geodesic distribution is not (distance 198.0, p
below 0.001). The command also draws a violin plot for every statistic; they are named
`gof_outdegree`, `gof_indegree` and `gof_geodesic` and can be saved with `graph export`:

```stata
. graph export "gof_thin_geodesic.png", name(gof_geodesic) width(900) replace
```

![Geodesic distribution, thin model](gof_thin_geodesic.png)

How to read a violin plot: for every category on the horizontal axis (distance 1, 2, ..., 6, and
"NR" for pairs that cannot reach each other) the grey shape is the distribution of the statistic
over the simulated networks, the thin box inside it the interquartile range, the dashed lines the
2.5th and 97.5th percentiles, and the **red line is the observed value**. A fit
is good when the red line stays inside the dashed envelope. Here it does not: the model cannot
produce a network that looks like the real one in terms of distances.

## Add effects that capture clustering

Friendship networks have more triangles than reciprocity alone can create. Add transitive triplets,
and the two degree effects `indegpopularity` and `outactivity`:

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip indegpopularity outactivity seed(1)
...
Overall maximum convergence ratio: 0.046 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met

. estat gof, nsim(100) seed(7)

Goodness of fit: Mahalanobis distance test
100 simulations at the estimates, 2 periods pooled

------------------------------------------------------
           Statistic |   Mahalanobis  P-value      Fit
---------------------+--------------------------------
           Outdegree |         4.096    0.720       ok
            Indegree |         4.445    0.760       ok
            Geodesic |        15.794    0.040 rejected
------------------------------------------------------
rejected: P < 0.05 (one-tailed); the model does not reproduce this statistic
Violin plots: gof_outdegree gof_indegree gof_geodesic
```

The distance fell from 198.0 to 15.8, which is a large improvement, but the p-value (0.04) is still below
0.05. A good habit is to improve the model one step at a time and to look at the same
statistic again.

## A better model

The next step is to combine the plain transitive-triplets count with the
geometrically weighted edgewise shared partner effect `gwesp(.69)`, which lets the benefit of an extra
common friend fade, and add `outpopularity`:

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) transtrip indegpopularity outactivity outpopularity seed(1)
...
---------------------------------------------------------------------------------
glasgow1_to_g~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
----------------+----------------------------------------------------------------
      outdegree |  -1.223729   .4558109    -2.68   0.007    -2.117102   -.3303564
    reciprocity |    2.89898   .3521915     8.23   0.000     2.208697    3.589263
indegpopularity |  -.3658625   .4108215    -0.89   0.373    -1.171058    .4393328
    outactivity |  -.1679043   .0508948    -3.30   0.001    -.2676562   -.0681524
      transtrip |  -.4891488    .427785    -1.14   0.253    -1.327592    .3492945
      gwesp_.69 |   3.364111    1.07733     3.12   0.002     1.252583    5.475638
  outpopularity |   -.373887   .3504424    -1.07   0.286    -1.060741    .3129674
---------------------------------------------------------------------------------
...
Overall maximum convergence ratio: 0.185 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met

. estat gof, nsim(100) seed(7)

Goodness of fit: Mahalanobis distance test
100 simulations at the estimates, 2 periods pooled

------------------------------------------------------
           Statistic |   Mahalanobis  P-value      Fit
---------------------+--------------------------------
           Outdegree |         3.101    0.810       ok
            Indegree |         3.448    0.810       ok
            Geodesic |         9.634    0.140       ok
------------------------------------------------------
rejected: P < 0.05 (one-tailed); the model does not reproduce this statistic
Violin plots: gof_outdegree gof_indegree gof_geodesic
```

All three statistics are now within what the model can produce.

![Geodesic distribution, better model](gof_final_geodesic.png)

The red line follows the center of the simulated distributions, including the large "NR" category
(pairs without a path between them). Three remarks on this model:

- The clustering is carried by `gwesp_.69` (3.36, z = 3.1); with it in the model `transtrip` is
  not significant. The two effects overlap, so do not interpret them separately; what matters for
  goodness of fit is that together they reproduce the distances.
- `outactivity` is negative: pupils who already name many friends are less eager to name even more.
  
- Several of the effects in the model are individually not significant. Goodness of fit is not about
  significance: an effect can be needed to fit the data without being "significant" on its own, and
  you should not remove an effect only because its p-value is above 0.05.

## More statistics, and one test per period

The triad census (the counts of the 16 triad types, RSiena's `TriadCensus`) is not part of the
default. It can be requested explicitly:

```stata
. estat gof, nsim(100) seed(7) stats(triad)

Goodness of fit: Mahalanobis distance test
100 simulations at the estimates, 2 periods pooled

------------------------------------------------------
           Statistic |   Mahalanobis  P-value      Fit
---------------------+--------------------------------
               Triad |        83.004    0.000 rejected
------------------------------------------------------
rejected: P < 0.05 (one-tailed); the model does not reproduce this statistic
Violin plots: gof_triad
```

Even this model does not reproduce the triad census, which is a stricter test than the other three. How much
weight to give this is a judgment: you have to decide what features the model must reproduce for your
substantive question. With three or more waves the periods are by default pooled into a single test; `join(off)`
tests each period separately:

```stata
. estat gof, nsim(100) seed(7) stats(outdegree) join(off)

Goodness of fit: Mahalanobis distance test
100 simulations at the estimates, one test per period

------------------------------------------------------
           Statistic |   Mahalanobis  P-value      Fit
---------------------+--------------------------------
Outdegree (period 1) |         2.942    0.800       ok
Outdegree (period 2) |         7.585    0.350       ok
------------------------------------------------------
rejected: P < 0.05 (one-tailed); the model does not reproduce this statistic
Violin plots: gof_outdegree_p1 gof_outdegree_p2
```

## Things to try

- `estat gof, twotailed` reports a two-tailed p-value, which rejects for deviations in either direction (the default is one-tailed, as in RSiena).
- Use a larger `nsim()` (200 or more) for a final check; with 100 simulations a p-value can only change in steps of 0.01.
- Fit your own model with and without `gwesp(.69)` and compare the geodesic test.
- After a co-evolution fit `estat gof` adds a fourth test, for the behavior distribution
  ([Tutorial 4](../tutorial-4-selection-influence/)).
- The goodness-of-fit commands and options are described in `help nwsaom_estat`.

## Where next

[Tutorial 4](../tutorial-4-selection-influence/) adds a behavior that changes together with the
network. [Tutorial 5](../tutorial-5-testing-comparing/) shows how to decide *which* effects to
include with score tests, instead of trial and error.
