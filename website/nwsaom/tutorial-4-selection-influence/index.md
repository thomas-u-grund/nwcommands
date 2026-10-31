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

Network data: 3 waves, 50 actors, directed
-----------------------------------------------------
        wave |     ties     density   avg. degree
-------------+---------------------------------------
           1 |      113      0.0461         2.260
           2 |      116      0.0473         2.320
           3 |      122      0.0498         2.440
-----------------------------------------------------

----------------------------------------------------------------------
      period |    kept   created  dissolved   Jaccard   Hamming
-------------+--------------------------------------------------------
        1->2 |      57        59         56     0.331       115
        2->3 |      66        56         50     0.384       106
----------------------------------------------------------------------

--------------------------------------------------
    behavior |        mean          sd     missing
-------------+------------------------------------
      wave 1 |       2.880       1.118           0
      wave 2 |       3.100       1.199           0
      wave 3 |       3.360       0.985           0
--------------------------------------------------

--------------------------------------------------
      change |          up        down        same
-------------+------------------------------------
        1->2 |          16           6          28
        2->3 |          18           9          23
--------------------------------------------------
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
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) behsim behavior(alcohol1 alcohol2 alcohol3) linear quadratic avalt seed(1)
-------------------------------------------------------------------------------------------------------------------------
SAOM co-evolution (Method of Moments), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2
Behavior: alcohol1 alcohol2 alcohol3
-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------
glasgow1_to~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
--------------+----------------------------------------------------------------
    outdegree |  -2.940128    .167233   -17.58   0.000    -3.267899   -2.612357
  reciprocity |   2.464193   .1974097    12.48   0.000     2.077277    2.851109
    gwesp_.69 |   1.613435   .1633764     9.88   0.000     1.293224    1.933647
       behsim |   1.550423   .6206369     2.50   0.012     .3339968    2.766849
   beh_linear |   .3974465   .1944195     2.04   0.041     .0163913    .7785016
beh_quadratic |  -.5829936   .3035246    -1.92   0.055    -1.177891    .0119037
    beh_avalt |   1.280615   .7760478     1.65   0.099    -.2404103    2.801641
-------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

             |   period1    period2 
-------------+---------------------
network_rate |    6.5156     5.1150 
          se |    1.0511     0.7958 
behavior_r~e |    1.3450     1.7957 
          se |    0.3293     0.4649 
Overall maximum convergence ratio: 0.160 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): not met for rate_beh_period1 (0.127)
Convergence is good only if both criteria are met. Refit starting from these estimates with theta0(); see nwsaom.
```

The network part of the table reads as before: `gwesp_.69` is the clustering effect (the
`gwesp` family of effects is used here instead of `transtrip`). There are now two rates, one for the
network and one for the behavior. The model converged (overall ratio 0.160, below 0.25), with one
t-ratio slightly above 0.1, which is reported separately. A restart as in
[Tutorial 2](../tutorial-2-convergence/) would be a sensible last step before reporting it.

**Reading the selection and influence effects.**

- `behsim` = 1.55 (z = 2.5, p = 0.012): pupils prefer friends with a similar drinking level. This
  is evidence for **selection**.
- `beh_avalt` = 1.28 (z = 1.65, p = 0.099): the sign says that pupils move towards the drinking of
  their friends, but with this effect the evidence for **influence** is weaker than for selection.
- `beh_linear` is positive and `beh_quadratic` negative: the general drift is towards more drinking,
  with a tendency against the extremes.

## A different influence effect

`avalt` is one way to formalise influence; `avsim` ("average similarity") is another; the actor
moves in the direction that makes the behavior more similar to that of the friends, rather than
towards their average. Swapping one for the other is a robustness check that you should always make:

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) behsim behavior(alcohol1 alcohol2 alcohol3) linear quadratic avsim seed(1)
...
       behsim |   1.498898   .5391366     2.78   0.005     .4422095    2.555586
   beh_linear |   .3675215   .1538492     2.39   0.017     .0659827    .6690604
beh_quadratic |  -.0726351   .1049503    -0.69   0.489    -.2783339    .1330636
    beh_avsim |   4.005875   1.941244     2.06   0.039     .2011071    7.810643
...
Overall maximum convergence ratio: 0.159 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

(The network part and the rates are left out.) Selection is again estimated as about 1.5, and now
the influence effect is statistically significant (4.01, z = 2.1, p = 0.039). So the data give some support for
influence, but how strongly depends on the specification of the effect. In a real study you
would report both, say which was your main specification before you looked, and not pick the
more favorable one. Note also that the `quadratic` effect is now close to zero.

## Selection through ego and alter effects

Selection on similarity is not the only possibility. `behegox` asks whether heavier drinkers
send more friendship ties and `behaltx` whether they receive more:

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) behsim behegox behaltx behavior(alcohol1 alcohol2 alcohol3) linear quadratic avalt seed(1)
...
       behsim |    1.55185   .7147432     2.17   0.030      .150979    2.952721
      behegox |   .0718023   .1271858     0.56   0.572    -.1774774    .3210819
      behaltx |  -.0519744   .1046156    -0.50   0.619    -.2570172    .1530685
...
Overall maximum convergence ratio: 0.235 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): not met for rate_period2 (-0.115)
Convergence is good only if both criteria are met. Refit starting from these estimates with theta0(); see nwsaom.
```

Neither is distinguishable from zero, and the similarity effect is unchanged. The overall ratio of
this run is 0.235, close to the limit, so for a real analysis this model would be restarted.

## Goodness of fit with a behavior

After a co-evolution fit `estat gof` adds a fourth statistic, the distribution of the behavior,
and it simulates network and behavior together (here after the `avsim` model, the last one fitted):

```stata
. estat gof, nsim(100) seed(7)

Goodness of fit: Mahalanobis distance test, 100 simulations at the estimates (2 periods pooled)
------------------------------------------------------------
Outdegree     | Mahalanobis dist. =   13.530   p =  0.140 (no evidence against fit)
Indegree      | Mahalanobis dist. =   11.373   p =  0.340 (no evidence against fit)
Geodesic      | Mahalanobis dist. =   29.953   p =  0.000 (evidence AGAINST fit)
Behavior      | Mahalanobis dist. =    0.981   p =  0.910 (no evidence against fit)
------------------------------------------------------------
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
