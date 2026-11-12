---
title: "Tutorial 4: Selection and influence"
parent: "nwsaom (SAOM)"
nav_order: 5
description: "Model friendship and drinking together with nwsaom: network-behavior co-evolution, selection and influence effects, on the Glasgow data."
---

# Tutorial 4: Selection and influence, network-behavior co-evolution

**Goal.** Friends resemble each other. Is that because people **select** friends who are like
them, or because friends **influence** each other so that they become alike? An SAOM can estimate
both processes in one model, with the network and a behavior as two outcomes that change together.

**Data.** The Glasgow data (see [Tutorial 1](../tutorial-1-first-saom/)), with the friendship
networks `glasgow1`-`glasgow3` and the drinking behavior `alcohol1`-`alcohol3`. Script and log:
[example.do](example.do), [example.log](example.log).

## The behavior

The alcohol variables count how often a pupil drinks, in five ordered categories from "non" to
"more" (coded 1 to 5). `nwsaom` needs a behavior with a small number of ordered integer values, one variable per
wave.

```stata
. tabulate alcohol1

            alcohol1 |      Freq.     Percent        Cum.
---------------------+-----------------------------------
                 non |          5       10.00       10.00
once or twice a year |         16       32.00       42.00
        once a month |         12       24.00       66.00
         once a week |         14       28.00       94.00
                more |          3        6.00      100.00
---------------------+-----------------------------------
               Total |         50      100.00
```

`nwsaom describe` accepts the behavior as well and adds the information that a SAOM works with:
the mean in each wave and how many actors increase, decrease or keep their value in each period.

```stata
. nwsaom describe, waves(glasgow1 glasgow2 glasgow3) behavior(alcohol1 alcohol2 alcohol3)

Network data                        Number of actors  =        50
Directed                            Number of waves   =         3

------------------------------------------------------------------
        Wave |       Ties     Density   Avg. degree
-------------+----------------------------------------------------
           1 |        113      0.0461         2.260
           2 |        116      0.0473         2.320
           3 |        122      0.0498         2.440
------------------------------------------------------------------

------------------------------------------------------------------
      Period |    Kept   Created  Dissolved   Jaccard   Hamming
-------------+----------------------------------------------------
        1->2 |      57        59         56     0.331       115
        2->3 |      66        56         50     0.384       106
------------------------------------------------------------------

------------------------------------------------------------------
    Behavior |        Mean   Std. dev.     Missing
-------------+----------------------------------------------------
      Wave 1 |       2.880       1.118           0
      Wave 2 |       3.100       1.199           0
      Wave 3 |       3.360       0.985           0
------------------------------------------------------------------

------------------------------------------------------------------
      Change |          Up        Down        Same
-------------+----------------------------------------------------
        1->2 |          16           6          28
        2->3 |          18           9          23
------------------------------------------------------------------
```

Drinking increases on average from wave to wave, and in each period a good part of the
pupils (22 and 27 of 50) change their value, so there is behavior change to explain.

## A model with selection and influence

The behavior is added with `behavior()`, which takes the variables of all waves, in order. Its
effects are then listed:

- `linear` and `quadratic`: the baseline tendencies of the behavior itself (the linear shape
  effect is required, as `outdegree` is for the network). A negative `quadratic` effect pulls actors
  towards the middle of the scale.
- `avalt`: **influence**. Actors move towards the average drinking level of their friends.
- `behsim`: **selection**. Actors prefer to name as friends others whose *current* drinking is
  similar to their own.

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) behsim behavior(alcohol1 alcohol2 alcohol3)
>  linear quadratic avalt seed(1)

SAOM co-evolution (Method of Moments), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2
Behavior: alcohol1 alcohol2 alcohol3

-------------------------------------------------------------------------------
glasgow1_to~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
--------------+----------------------------------------------------------------
    outdegree |  -2.934307   .1646248   -17.82   0.000    -3.256966   -2.611648
  reciprocity |   2.458445   .1869355    13.15   0.000     2.092058    2.824832
    gwesp_.69 |   1.609623   .1580312    10.19   0.000     1.299888    1.919359
       behsim |   1.541488   .6794717     2.27   0.023     .2097483    2.873228
   beh_linear |   .3961166   .2205673     1.80   0.073    -.0361874    .8284205
beh_quadratic |  -.5839079   .3270813    -1.79   0.074    -1.224975    .0571596
    beh_avalt |    1.28223   .7850593     1.63   0.102    -.2564581    2.820918
-------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

------------------------------------
             |   period1    period2
-------------+----------------------
network_rate |    6.6073     5.1192
          se |    1.5720     0.9132
behavior_r~e |    1.3340     1.7957
          se |    0.4142     0.4536
------------------------------------
Overall maximum convergence ratio: 0.149 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

The network part of the table reads as before: `gwesp_.69` is the clustering effect (the
`gwesp` family of effects is used here instead of `transtrip`). There are now two rates, one for the
network and one for the behavior. The model converged: the overall ratio is 0.149, below 0.25, and
every t-ratio is below 0.1.

**Reading the selection and influence effects.**

- `behsim` = 1.54 (z = 2.27, p = 0.023): pupils prefer friends with a similar drinking level. This
  is evidence for **selection**.
- `beh_avalt` = 1.28 (z = 1.63, p = 0.102): the sign says that pupils move towards the drinking of
  their friends, but with this effect the evidence for **influence** is weaker than for selection.
- `beh_linear` is positive and `beh_quadratic` negative: the general drift is towards more drinking,
  with a tendency against the extremes.

## A different influence effect

`avalt` is one way to formalise influence; `avsim` ("average similarity") is another; the actor
moves in the direction that makes the behavior more similar to that of the friends, rather than
towards their average. Swapping one for the other is a robustness check that you should always make:

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) behsim behavior(alcohol1 alcohol2 alcohol3)
>  linear quadratic avsim seed(1)
...
       behsim |   1.501996   .6059983     2.48   0.013     .3142607     2.68973
   beh_linear |   .3608452   .1676806     2.15   0.031     .0321973     .689493
beh_quadratic |  -.0727403   .0991779    -0.73   0.463    -.2671254    .1216447
    beh_avsim |   3.995552     1.9381     2.06   0.039     .1969465    7.794158
...
Overall maximum convergence ratio: 0.152 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

(The network part and the rates are left out.) Selection is again estimated as about 1.5, and now
the influence effect is statistically significant (4.00, z = 2.06, p = 0.039). So the data give some support for
influence, but how strongly depends on the specification of the effect. In a real study you
would report both, say which was your main specification before you looked, and not pick the
more favorable one. Note also that the `quadratic` effect is now close to zero.

## Selection through ego and alter effects

Selection on similarity is not the only possibility. `behegox` asks whether heavier drinkers
send more friendship ties and `behaltx` whether they receive more:

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) behsim behegox behaltx behavior(alcohol1 al
> cohol2 alcohol3) linear quadratic avalt seed(1)
...
       behsim |    1.52533   .6705486     2.27   0.023     .2110787    2.839581
      behegox |    .063739   .1120308     0.57   0.569    -.1558373    .2833153
      behaltx |  -.0401824   .1024794    -0.39   0.695    -.2410384    .1606736
...
Overall maximum convergence ratio: 0.173 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): not met for
  rate_period2 (-0.105)
Convergence is good only if both criteria are met.
To refit starting from these estimates, type nwsaom refit.
```

Neither is distinguishable from zero, and the similarity effect is unchanged (1.53). The overall
ratio of this run is 0.173, but one t-ratio (`rate_period2`, -0.105) is slightly above 0.1, so for a
real analysis this model would be restarted with `nwsaom refit`, as the output suggests (see
[Tutorial 2](../tutorial-2-convergence/)).

## Goodness of fit with a behavior

After a co-evolution fit `estat gof` adds a fourth statistic, the distribution of the behavior,
and it simulates network and behavior together (here after the `avsim` model, the last one fitted):

```stata
. estat gof, nsim(100) seed(7)

Goodness of fit: Mahalanobis distance test
100 simulations at the estimates, 2 periods pooled

------------------------------------------------------
           Statistic |   Mahalanobis  P-value      Fit
---------------------+--------------------------------
           Outdegree |        13.376    0.160       ok
            Indegree |        10.875    0.340       ok
            Geodesic |        24.287    0.010 rejected
            Behavior |         1.019    0.870       ok
------------------------------------------------------
rejected: P < 0.05 (one-tailed); the model does not reproduce this statistic
Violin plots: gof_outdegree gof_indegree gof_geodesic gof_behavior
```

The behavior distribution is reproduced very well. The geodesic distances are not, as in the
thin model of [Tutorial 3](../tutorial-3-goodness-of-fit/); the same remedies (more clustering and degree effects)
apply.

## Things to try

- Use `smoke1 smoke2 smoke3` as the behavior (smoking has fewer categories) and ask the same
  selection/influence question for smoking.
- Add `egox(alcohol1) altx(alcohol1)` as constant covariates and compare with `behegox` /
  `behaltx`: the covariate versions use the fixed first-wave value, the behavior versions the current
  value, which changes during the simulation.
- Fit the network-only model without the behavior and see how the network effects change.
- Look up the other behavior effects (`avsim` split into endowment and creation, `beheff()`
  for effects of network position on the behavior, several behaviors at once) in
  `help nwsaom` under "Behavior co-evolution effects".

## Where next

[Tutorial 5](../tutorial-5-testing-comparing/) shows how to test whether an effect should be in the
model without fitting it, and how to see how much each effect matters.
