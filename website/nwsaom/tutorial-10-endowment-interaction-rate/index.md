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

**Data.** The Glasgow friendship data again. The commands were run with `nwsaom` 1.1.1 and the core 3.10.0 in Stata 18,
and checked in Stata 17. The complete script and log are in [example.do](example.do) and [example.log](example.log).

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
----------------------------------------------------------------------------------------------------
SAOM (Method of Moments, conditional), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2
----------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------
glasgow1_t~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.867764   .1349245   -21.25   0.000    -3.132211   -2.603317
 reciprocity |   2.435639   .1836997    13.26   0.000     2.075595    2.795684
   transties |   1.173796   .1325602     8.85   0.000     .9139823    1.433609
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

             |   period1    period2 
-------------+---------------------
        rate |    7.4252     5.5577 
          se |    1.4258     0.9936 
Overall maximum convergence ratio: 0.082 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

`transties` is a simpler closure effect than `transtrip`: a tie is more attractive if there is a two-path from the sender to the receiver.
Now split it:

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity endow(transties) creation(transties) seed(6)
----------------------------------------------------------------------------------------------------
SAOM (Method of Moments, conditional), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2
----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
glasgow1_to_gla~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
------------------+----------------------------------------------------------------
        outdegree |  -2.937801   .2219279   -13.24   0.000    -3.372771    -2.50283
      reciprocity |   2.662705   .3052802     8.72   0.000     2.064367    3.261043
   transtiesendow |  -.3730114    .681025    -0.55   0.584    -1.707796     .961773
transtiescreation |   2.396332   .5770431     4.15   0.000     1.265348    3.527316
-----------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

             |   period1    period2 
-------------+---------------------
        rate |    6.3342     5.0200 
          se |    1.1150     0.8223 
Overall maximum convergence ratio: 0.126 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

Closure matters for *making* friends (`transtiescreation` 2.40, z = 4.2); there is no evidence that it matters for *keeping*
them (`transtiesendow` -0.37, z = -0.5). Note that the effect now has two coefficients, so it is no longer comparable with the single
`transties` coefficient (1.17). The same can be done for the reciprocity effect, replacing it:

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree endow(reciprocity) creation(reciprocity) seed(6)
----------------------------------------------------------------------------------------------------
SAOM (Method of Moments, conditional), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2
----------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
glasgow1_to_glasg~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
--------------------+----------------------------------------------------------------
          outdegree |  -2.184284   .1293756   -16.88   0.000    -2.437856   -1.930713
   reciprocityendow |   1.159558   .5655688     2.05   0.040     .0510638    2.268053
reciprocitycreation |   4.080603   .4319001     9.45   0.000     3.234095    4.927112
-------------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

             |   period1    period2 
-------------+---------------------
        rate |    4.5166     3.7584 
          se |    0.6481     0.5292 
Overall maximum convergence ratio: 0.125 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

Reciprocity is 4.08 (z = 9.5) in its creation role, and the endowment role adds 1.16 (z = 2.1): mutual ties are made because they are
mutual, and they are also valued once they exist. (The rate estimates change with the specification, as they do whenever
the model changes; do not compare them across models.)

### Covariates and behavior

A covariate effect is split per variable, written `effect:variable`:

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transties endow(altx:alcohol1) creation(altx:alcohol1) seed(4)
----------------------------------------------------------------------------------------------------
SAOM (Method of Moments, conditional), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2
----------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
 glasgow1_to_glasgow3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
----------------------+----------------------------------------------------------------
            outdegree |  -2.868272   .1250885   -22.93   0.000    -3.113441   -2.623103
          reciprocity |   2.448188    .193526    12.65   0.000     2.068884    2.827492
   altxendow_alcohol1 |  -.3811653   .1916677    -1.99   0.047    -.7568271   -.0055035
altxcreation_alcohol1 |   .2663148   .1141502     2.33   0.020     .0425845    .4900451
            transties |   1.176264   .1279014     9.20   0.000     .9255822    1.426947
---------------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

             |   period1    period2 
-------------+---------------------
        rate |    7.5216     5.8361 
          se |    1.4005     1.1486 
Overall maximum convergence ratio: 0.090 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

The two parts of the alcohol-alter effect have opposite signs (`altxcreation_alcohol1` 0.27, `altxendow_alcohol1` -0.38). A single `altx` effect
would have averaged these and found next to nothing. Both are, however, only about two standard errors from zero, in a single data set,
so this is a hint for further analysis, not a finding.

The behavior side has the same options (`linearendow`/`linearcreation`, `quadraticendow`/`quadraticcreation`, `avalt`, `avsim`):

```stata
. nwsaom, wave1(glasgow1) wave2(glasgow2) outdegree reciprocity behavior(alcohol1 alcohol2) linear quadraticendow quadraticcreation seed(4)
----------------------------------------------------------------------------------------------------
SAOM co-evolution (Method of Moments), waves: glasgow1 -> glasgow2
Actors: 50                             Network rate:  5.530 (0.850)
Behavior: alcohol1 alcohol2            Behavior rate:  1.242 (0.311)
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
  glasgow1_to_glasgow2 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-----------------------+----------------------------------------------------------------
             outdegree |  -2.225501   .1288093   -17.28   0.000    -2.477962   -1.973039
           reciprocity |   2.420582   .2492538     9.71   0.000     1.932053     2.90911
            beh_linear |    .424995   .3422905     1.24   0.214    -.2458821    1.095872
   beh_quadratic_endow |   .1106879   .4323379     0.26   0.798    -.7366789    .9580547
beh_quadratic_creation |   -.217134   .4636833    -0.47   0.640    -1.125937    .6916686
----------------------------------------------------------------------------------------
Overall maximum convergence ratio: 0.133 (criterion: below 0.25; met)
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
----------------------------------------------------------------------------------------------------
SAOM (Method of Moments, conditional), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2
----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
         glasgow1_to_glasgow3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
------------------------------+----------------------------------------------------------------
                    outdegree |  -2.890084   .1388058   -20.82   0.000    -3.162138    -2.61803
                  reciprocity |   2.468652    .182564    13.52   0.000     2.110833     2.82647
                egox_alcohol1 |   .0909282   .1032645     0.88   0.379    -.1114666    .2933229
                    transties |   1.171759   .1430727     8.19   0.000     .8913419    1.452177
interact_nodeocov_reciprocity |  -.1488986   .2342888    -0.64   0.525    -.6080962    .3102991
-----------------------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

             |   period1    period2 
-------------+---------------------
        rate |    7.5984     5.6681 
          se |    1.4431     1.0199 
(conditional: rate = mean time to reach the observed distance, se = its SD)
RSiena effect names:
  egox_alcohol1                 alcohol1 ego
  interact_nodeocov_reciprocity alcohol1 ego x reciprocity
Covariates centred by their means, as RSiena's coCovar(centered = TRUE):
  alcohol1                          2.880
Convergence t-ratios (criterion: every |t| below 0.1; the overall maximum ratio below 0.25 is a separate criterion):
  outdegree                 -0.060      reciprocity               -0.032
  egox_alcohol1             -0.091      transties                 -0.045
  interact_nodeocov_recip~  -0.104
Overall maximum convergence ratio:  0.134
```

The interaction is -0.15 (z = -0.6): no sign that heavy drinkers reciprocate differently. The coefficient is named after the two components
(`interact_nodeocov_reciprocity`); `detail` shows the name RSiena uses ("alcohol1 ego x reciprocity") and the covariate's centering mean.

A second example with two covariate effects: `samex(smoke1)` (a preference for friends with the same smoking status) and
`egox(alcohol1)` (heavier drinkers name more friends).

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transties samex(smoke1) egox(alcohol1) interact(samex#egox) seed(4)
----------------------------------------------------------------------------------------------------
SAOM (Method of Moments, conditional), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2
----------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
       glasgow1_to_glasgow3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
----------------------------+----------------------------------------------------------------
                  outdegree |  -3.220108   .2206385   -14.59   0.000    -3.652551   -2.787664
                reciprocity |   2.469673   .1932599    12.78   0.000      2.09089    2.848455
               samex_smoke1 |   .3569517   .1852166     1.93   0.054    -.0060662    .7199696
              egox_alcohol1 |   .3827144   .1439699     2.66   0.008     .1005385    .6648903
                  transties |   1.148795    .123673     9.29   0.000     .9064005     1.39119
interact_nodematch_nodeocov |  -.4448597   .1660293    -2.68   0.007    -.7702712   -.1194483
---------------------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

             |   period1    period2 
-------------+---------------------
        rate |    7.5054     5.6764 
          se |    1.4264     1.0365 
Overall maximum convergence ratio: 0.081 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

The interaction is negative (-0.44, z = -2.7): the bonus for same-smoking friends is smaller for pupils who drink a lot (and, equally, the
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
----------------------------------------------------------------------------------------------------
SAOM (Method of Moments, conditional), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2
----------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------
glasgow1_t~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.871685   .1312082   -21.89   0.000    -3.128849   -2.614522
 reciprocity |   2.428765   .1855593    13.09   0.000     2.065076    2.792455
   transties |   1.180279   .1278749     9.23   0.000     .9296485    1.430909
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

             |   period1    period2 
-------------+---------------------
        rate |    7.1977     5.7059 
          se |    1.4212     1.0823 
Covariate-rate coefficient (alcohol1):    0.4191 (se 0.1443)
Overall maximum convergence ratio: 0.150 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

The coefficient is 0.42 (se 0.14), shown under the rate table, and it is stored in `e(ratecoefs)`. Per unit of alcohol (on the 1 to 5 scale,
relative to the average of 2.88) the rate is multiplied by exp(0.42) = 1.52: about half as many again. Heavier drinkers are the more
restless pupils, a result that no effect on the *choice* could have shown.

The rate can also depend on the actor's position in the network. `outrate` makes the rate depend on the number of friends the pupil currently has
(there are also `inrate`, `reciprate` and logarithmic and inverse versions; see `help nwsaom`):

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transties outrate seed(4)
----------------------------------------------------------------------------------------------------
SAOM (Method of Moments, conditional), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2
----------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------
glasgow1_t~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.700628   .1371836   -19.69   0.000    -2.969503   -2.431753
 reciprocity |   2.357928   .2132406    11.06   0.000     1.939984    2.775872
   transties |   1.128274   .1423971     7.92   0.000     .8491806    1.407367
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

             |   period1    period2 
-------------+---------------------
        rate |    3.9495     2.9879 
          se |    0.8066     0.5726 
Covariate-rate coefficient (outrate):    0.2462 (se 0.2564)
Overall maximum convergence ratio: 0.103 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

Here the coefficient is 0.25 with a standard error of 0.26: no sign that pupils with more friends change them more often.
Note that the baseline rate (3.9 and 3.0) now refers to a pupil with no friends and is not comparable with the earlier models.

## Things to try

- Split `gwesp(.69)` into its roles: `gwesp(.69) endow(gwesp) creation(gwesp)`.
- Interact `altx(alcohol1)` with `egox(alcohol1)`.
- Use `ratecov(alcohol1 smoke1)` for two covariates, and `nocenter` to see what centering does.
- Compare the models of this tutorial with `estat gof` (Tutorial 3) and `estat score` (Tutorial 5).

## Where next

[Tutorial 11](../tutorial-11-simulation/) uses a fitted model to simulate networks, and answers "what would the network look like if an
effect were not there?"
