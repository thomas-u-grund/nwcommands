---
title: "Tutorial 10: Endowment, creation, interactions and rate effects"
parent: "nwsaom (SAOM)"
nav_order: 11
description: "Separate effects for creating and for ending ties (endow, creation), interactions between effects (interact), and effects on the rate of change (ratecov, outrate) in nwsaom."
---

# Tutorial 10: Endowment, creation, interactions and rate effects

**Goal.** Three ways of refining a model that you already know how to fit: let an effect work differently when a tie
is made and when it is ended; let two effects reinforce or weaken each other; and let the *speed* of change, not only its
direction, depend on something.

**Data.** The Glasgow friendship data again. The commands were run with `nwsaom` 1.6.0 and the core 3.22.0 in Stata 17. The complete script and log are in [example.do](example.do) and [example.log](example.log).

## Part 1: endowment and creation

In the model so far an effect has *one* coefficient for everything an actor does: if reciprocity is worth 2.4 when a tie
is made, then it is worth the same when deciding whether to *keep* a tie. That is a strong assumption. Perhaps
making a friend is easy to explain with similarity, while giving up a friend is not.
RSiena's solution, which `nwsaom` follows, is to give an effect two roles:

- the **creation** role counts only when a tie is *created* (a new tie, or a higher value);
- the **endowment** role counts only when a tie is *given up*. The idea is that we "endow" existing ties with extra value
  that we lose when we drop them.

You split an effect by naming it in both `endow()` and `creation()`; the split then replaces the plain effect. To compare, here is the
plain model:

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transties seed(4)

SAOM (Method of Moments, conditional), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2

------------------------------------------------------------------------------
glasgow1_t~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.871859   .1349753   -21.28   0.000    -3.136405   -2.607312
 reciprocity |   2.439997    .187479    13.01   0.000     2.072545    2.807449
   transties |   1.173467   .1388159     8.45   0.000     .9013933    1.445542
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

------------------------------------
             |   period1    period2 
-------------+----------------------
        rate |    7.5013     5.5891
          se |    1.5015     1.0131
------------------------------------
Overall maximum convergence ratio: 0.041 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

`transties` is a simpler closure effect than `transtrip`: a tie is more attractive if there is a two-path from the sender to the receiver.
Now split it:

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity endow(transties) creation(transties) seed(6)

SAOM (Method of Moments, conditional), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2

-----------------------------------------------------------------------------------
glasgow1_to_gla~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
------------------+----------------------------------------------------------------
        outdegree |  -2.969916   .1941109   -15.30   0.000    -3.350366   -2.589466
      reciprocity |   2.666589   .3040934     8.77   0.000     2.070577    3.262601
   transtiesendow |  -.3560853   .7169222    -0.50   0.619    -1.761227    1.049056
transtiescreation |   2.436963   .5467809     4.46   0.000     1.365293    3.508634
-----------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

------------------------------------
             |   period1    period2 
-------------+----------------------
        rate |    6.3402     4.9594
          se |    1.0790     0.8277
------------------------------------
Overall maximum convergence ratio: 0.053 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

Closure matters for *making* friends (`transtiescreation` 2.44, z = 4.5); there is no evidence that it matters for *keeping*
them (`transtiesendow` -0.36, z = -0.5). Note that the effect now has two coefficients, so it is no longer comparable with the single
`transties` coefficient (1.17). The same can be done for the reciprocity effect, replacing it. The first fit of this model (seed 6) narrowly misses the
t-ratio criterion, so we run it quietly and restart it from its estimates with `nwsaom refit` (see [Tutorial 12](../tutorial-12-estimation-speed/)):

```stata
. quietly nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree endow(reciprocity) creation(reciprocity) seed(6)

. nwsaom refit, seed(8)

------------------------------------------------------------------------------
nwsaom refit, run 1: starting from the last estimates (overall ratio 0.146)
------------------------------------------------------------------------------

SAOM (Method of Moments, conditional), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2

-------------------------------------------------------------------------------------
glasgow1_to_glasg~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
--------------------+----------------------------------------------------------------
          outdegree |   -2.18387   .1243562   -17.56   0.000    -2.427604   -1.940136
   reciprocityendow |   1.180834   .5501995     2.15   0.032     .1024628    2.259205
reciprocitycreation |   4.041258   .4374459     9.24   0.000      3.18388    4.898636
-------------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

------------------------------------
             |   period1    period2 
-------------+----------------------
        rate |    4.5465     3.7735
          se |    0.6196     0.5317
------------------------------------
Overall maximum convergence ratio: 0.077 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met

nwsaom refit: 1 run; largest |t| 0.047, overall ratio 0.077 (converged)
```

The restarted fit meets both convergence criteria (largest |t| 0.047). Reciprocity is 4.04 (z = 9.2) in its creation role, and the endowment role adds 1.18 (z = 2.2, p = 0.03): mutual
ties are made because they are mutual, and they also seem to be valued once they exist. (The rate estimates change with the specification, as they do whenever
the model changes; do not compare them across models.)

### Covariates and behavior

A covariate effect is split per variable, written `effect:variable`. This first fit, too, narrowly misses the t-ratio criterion, so again we restart it:

```stata
. quietly nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transties endow(altx:alcohol1) creation(altx:alcohol1) seed(4)

. nwsaom refit, seed(6)

------------------------------------------------------------------------------
nwsaom refit, run 1: starting from the last estimates (overall ratio 0.136)
------------------------------------------------------------------------------

SAOM (Method of Moments, conditional), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2

---------------------------------------------------------------------------------------
 glasgow1_to_glasgow3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
----------------------+----------------------------------------------------------------
            outdegree |  -2.877431   .1311782   -21.94   0.000    -3.134536   -2.620327
          reciprocity |   2.458253   .1990711    12.35   0.000     2.068081    2.848426
   altxendow_alcohol1 |  -.3869229   .1763595    -2.19   0.028    -.7325812   -.0412646
altxcreation_alcohol1 |   .2688568   .1206798     2.23   0.026     .0323288    .5053848
            transties |   1.176411   .1346011     8.74   0.000     .9125978    1.440224
---------------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

------------------------------------
             |   period1    period2 
-------------+----------------------
        rate |    7.6239     5.9103
          se |    1.4489     1.0756
------------------------------------
Overall maximum convergence ratio: 0.070 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met

nwsaom refit: 1 run; largest |t| 0.016, overall ratio 0.070 (converged)
```

The two parts of the alcohol-alter effect have opposite signs (`altxcreation_alcohol1` 0.27, `altxendow_alcohol1` -0.39). A single `altx` effect
would have averaged these and found next to nothing. Both are, however, only about two standard errors from zero, in a single data set,
so this is a hint for further analysis, not a finding.

The behavior side has the same options (`linearendow`/`linearcreation`, `quadraticendow`/`quadraticcreation`, `avalt`, `avsim`):

```stata
. nwsaom, waves(glasgow1 glasgow2) outdegree reciprocity behavior(alcohol1 alcohol2) linear quadrati
> cendow quadraticcreation seed(4)

SAOM co-evolution (Method of Moments), waves: glasgow1 glasgow2
Actors: 50                             Periods: 1
Behavior: alcohol1 alcohol2

----------------------------------------------------------------------------------------
  glasgow1_to_glasgow2 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-----------------------+----------------------------------------------------------------
             outdegree |  -2.228531   .1378878   -16.16   0.000    -2.498786   -1.958276
           reciprocity |   2.434498   .2623425     9.28   0.000     1.920316     2.94868
            beh_linear |   .4141268   .3970118     1.04   0.297    -.3640021    1.192256
   beh_quadratic_endow |   .0988066   .4379107     0.23   0.821    -.7594827    .9570959
beh_quadratic_creation |  -.2232361   .5486043    -0.41   0.684    -1.298481    .8520086
----------------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

-------------------------
             |   period1 
-------------+-----------
network_rate |    5.5062
          se |    0.8440
behavior_r~e |    1.2515
          se |    0.3523
-------------------------
Overall maximum convergence ratio: 0.122 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

In this two-wave example the shape effects are not significant, but the syntax is the point.

Two cautions. An effect and both of its roles cannot be in the model at the same time, because the three would be exactly collinear. And a
fully separate model for creating and for ending ties needs good data: you need enough created *and* enough dissolved ties.

## Part 2: interactions

An **interaction** lets the strength of one effect depend on another. `interact()` names two (or three) effects that are already
in the model; its contribution to a choice is the product of the two effects' contributions, and it has its own coefficient. First: does the pull of
reciprocity depend on how much the sender drinks?

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transties egox(alcohol1) interact(egox#reciprocity) seed(4) detail

SAOM (Method of Moments, conditional), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2

-----------------------------------------------------------------------------------------------
         glasgow1_to_glasgow3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
------------------------------+----------------------------------------------------------------
                    outdegree |  -2.886535   .1370334   -21.06   0.000    -3.155115   -2.617954
                  reciprocity |   2.459194   .1969747    12.48   0.000     2.073131    2.845258
                egox_alcohol1 |   .0965064   .0967151     1.00   0.318    -.0930517    .2860644
                    transties |   1.176884   .1383444     8.51   0.000     .9057343    1.448034
interact_nodeocov_reciprocity |  -.1492179   .2164106    -0.69   0.491    -.5733749    .2749391
-----------------------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

------------------------------------
             |   period1    period2 
-------------+----------------------
        rate |    7.4886     5.6157
          se |    1.4634     1.0277
------------------------------------
(conditional: rate = mean time to reach the observed distance, se = its SD)
RSiena effect names:
  egox_alcohol1                 alcohol1 ego
  interact_nodeocov_reciprocity alcohol1 ego x reciprocity
Covariates centred by their means, as RSiena's coCovar(centered = TRUE):
  alcohol1                          2.880
Convergence t-ratios (criterion: every |t| below 0.1; the overall maximum ratio below 0.25 is a
separate criterion):
  outdegree                  0.044      reciprocity                0.058
  egox_alcohol1             -0.011      transties                  0.040
  interact_nodeocov_recip~  -0.056
Overall maximum convergence ratio:  0.104
```

The interaction is -0.15 (z = -0.7): no sign that heavy drinkers reciprocate differently. The coefficient is named after the two components
(`interact_nodeocov_reciprocity`); `detail` shows the name RSiena uses ("alcohol1 ego x reciprocity") and the covariate's centering mean.

A second example with two covariate effects: `samex(smoke1)` (a preference for friends with the same smoking status) and
`egox(alcohol1)` (heavier drinkers name more friends).

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transties samex(smoke1) egox(alcohol1) interact(samex#egox) seed(4)

SAOM (Method of Moments, conditional), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2

---------------------------------------------------------------------------------------------
       glasgow1_to_glasgow3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
----------------------------+----------------------------------------------------------------
                  outdegree |  -3.228923   .2161502   -14.94   0.000     -3.65257   -2.805276
                reciprocity |   2.474205   .2044445    12.10   0.000     2.073501    2.874909
               samex_smoke1 |   .3557494   .1891709     1.88   0.060    -.0150187    .7265174
              egox_alcohol1 |   .3858571   .1383916     2.79   0.005     .1146145    .6570997
                  transties |   1.161768   .1332806     8.72   0.000     .9005431    1.422993
interact_nodematch_nodeocov |  -.4453379    .166993    -2.67   0.008    -.7726382   -.1180376
---------------------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

------------------------------------
             |   period1    period2 
-------------+----------------------
        rate |    7.5730     5.6752
          se |    1.4274     1.0405
------------------------------------
Overall maximum convergence ratio: 0.102 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

The interaction is negative (-0.45, z = -2.7): the bonus for same-smoking friends is smaller for pupils who drink a lot (and, equally, the
drinking effect is smaller when the friend smokes like oneself). When an interaction is in the model, the main effects are
the effects at the zero (average, for centered variables) value of the other, so read all three coefficients together. `interact()` has rules about which effects can be
combined (an effect of the actor, of the dyad, or of the network; `help nwsaom` lists them) and says so when a combination is not allowed.

## Part 3: effects on the rate

Until now all pupils had the same rate: the same number of opportunities to change their friendships in a period.
`ratecov()` lets covariates speed pupils up or slow them down. The rate of pupil *i* is multiplied by
exp(*b* x covariate), so a positive *b* means more frequent opportunities for pupils with a higher value.
Do pupils who drink more change their friendships more often?

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transties ratecov(alcohol1) seed(4)

SAOM (Method of Moments, conditional), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2

------------------------------------------------------------------------------
glasgow1_t~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.876421   .1312406   -21.92   0.000    -3.133648   -2.619194
 reciprocity |   2.425393   .1888139    12.85   0.000     2.055324    2.795461
   transties |   1.187353     .13654     8.70   0.000     .9197395    1.454966
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

------------------------------------
             |   period1    period2 
-------------+----------------------
        rate |    7.2761     5.6371
          se |    1.3636     1.0490
------------------------------------
Covariate-rate coefficient (alcohol1):    0.4260 (se 0.1198)
Overall maximum convergence ratio: 0.065 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

The coefficient is 0.43 (se 0.12), shown under the rate table, and it is stored in `e(ratecoefs)`. Per unit of alcohol (on the 1 to 5 scale,
relative to the average of 2.88) the rate is multiplied by exp(0.43) = 1.54: about half as many again. Heavier drinkers are the more
restless pupils, a result that no effect on the *choice* could have shown.

The rate can also depend on the actor's position in the network. `outrate` makes the rate depend on the number of friends the pupil currently has
(there are also `inrate`, `reciprate` and logarithmic and inverse versions; see `help nwsaom`):

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transties outrate seed(4)

SAOM (Method of Moments, conditional), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2

------------------------------------------------------------------------------
glasgow1_t~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.695975   .1974299   -13.66   0.000     -3.08293   -2.309019
 reciprocity |    2.35989   .2069168    11.41   0.000      1.95434    2.765439
   transties |   1.133056   .1541168     7.35   0.000     .8309929     1.43512
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

------------------------------------
             |   period1    period2 
-------------+----------------------
        rate |    3.7292     2.8171
          se |    0.7903     0.5459
------------------------------------
Covariate-rate coefficient (outrate):    0.2677 (se 0.1347)
Overall maximum convergence ratio: 0.115 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

Here the coefficient is 0.27 with a standard error of 0.13, about two standard errors from zero: a weak hint that pupils with
more friends change them more often, not a firm result.
Note that the baseline rate (3.7 and 2.8) now refers to a pupil with no friends and is not comparable with the earlier models.

## Things to try

- Split `gwesp(.69)` into its roles: `gwesp(.69) endow(gwesp) creation(gwesp)`.
- Interact `altx(alcohol1)` with `egox(alcohol1)`.
- Use `ratecov(alcohol1 smoke1)` for two covariates, and `nocenter` to see what centering does.
- Compare the models of this tutorial with `estat gof` (Tutorial 3) and `estat score` (Tutorial 5).

## Where next

[Tutorial 11](../tutorial-11-simulation/) uses a fitted model to simulate networks, and answers "what would the network look like if an
effect were not there?"
