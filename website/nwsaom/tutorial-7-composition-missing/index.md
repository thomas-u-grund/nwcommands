---
title: "Tutorial 7: Changing actor sets and missing data"
parent: "nwsaom (SAOM)"
nav_order: 8
description: "Pupils who join or leave between waves and values that were not observed: composition change with present(), joinat() and leaveat(), and missing data with missnet() and missbeh() in nwsaom."
---

# Tutorial 7: Changing actor sets and missing data

**Goal.** Real panel data are rarely tidy. Some people join the group after the first survey, some
leave before the last one, and some do not answer at one wave. This tutorial shows how to tell `nwsaom`
about this, so that it neither invents changes nor throws the data away.

**Data.** The Glasgow friendship data of [Tutorial 1](../tutorial-1-first-saom/). The Glasgow data are
complete, so we **construct** the problems ourselves: we pretend that some pupils joined or left and that
some answers are missing, and we say exactly how. The constructed examples show how the commands work;
they are not findings about the school. The commands were run with `nwsaom` 1.1.1 and the core 3.10.0 in
Stata 18, and checked in Stata 17. The complete script and log are in [example.do](example.do) and
[example.log](example.log).

## Two different problems

It helps to keep two situations apart.

- **Composition change.** An actor is *not part of the group* at some time: a pupil who has not yet
  arrived, or who has left. Such an actor cannot send or receive ties while away, and the model must not
  count their absence as friendships that were dropped.
- **Missing data.** An actor *is* part of the group, but we do not know their ties or their behavior at
  that wave, for example because they were ill on the day of the survey. The model then fills in a
  plausible value for the simulation and leaves the unknown part out when it compares the simulated and
  observed networks.

## Composition change with present()

Suppose pupils 1 to 4 joined the school after the first wave and pupils 5 to 7 left after the second.
`nwsaom` wants one 0/1 variable per wave that says who is present, and wave data that are *prepared* in
a particular way: an actor who has not yet arrived has no ties in the earlier waves, and an actor who has
left keeps the ties they had at the last wave they were present. The following Mata code prepares such
networks from the three Glasgow waves (it is in the script; `nwtomata` copies a network to a Mata matrix and
`nwset` turns a Stata matrix back into a network):

```stata
. nwtomata glasgow1, mat(G1)
. nwtomata glasgow2, mat(G2)
. nwtomata glasgow3, mat(G3)
. mata:
: G1[1::4, .] = J(4, 50, 0)
: G1[., 1::4] = J(50, 4, 0)
: G3[5::7, .] = G2[5::7, .]
: G3[., 5::7] = G2[., 5::7]
: st_matrix("C1", G1)
: st_matrix("C2", G2)
: st_matrix("C3", G3)
: end
. nwset, mat(C1) directed name(comp1)
. nwset, mat(C2) directed name(comp2)
. nwset, mat(C3) directed name(comp3)
```

Now the presence variables, one per wave:

```stata
. generate byte pres1 = _n > 4
. generate byte pres2 = 1
. generate byte pres3 = !inrange(_n, 5, 7)
```

A quick check that they mark the right numbers of pupils:

```stata
. tabulate pres1

      pres1 |      Freq.     Percent        Cum.
------------+-----------------------------------
          0 |          4        8.00        8.00
          1 |         46       92.00      100.00
------------+-----------------------------------
      Total |         50      100.00
```

and the model, with `present()` listing the three variables in the order of the waves:

```stata
. nwsaom, waves(comp1 comp2 comp3) outdegree reciprocity transtrip present(pres1 pres2 pres3) seed(4)
----------------------------------------------------------------------------------------------------
SAOM (Method of Moments, unconditional), waves: comp1 comp2 comp3
Actors: 50                             Periods: 2
----------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------
comp1_to_c~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.514709   .1123886   -22.38   0.000    -2.734987   -2.294432
 reciprocity |   2.383011   .1944882    12.25   0.000     2.001821    2.764201
   transtrip |   .5621572   .0847645     6.63   0.000     .3960219    .7282926
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

             |   period1    period2 
-------------+---------------------
        rate |    8.2471     4.5747 
          se |    1.7841     0.7200 
Overall maximum convergence ratio: 0.169 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

Three things to notice. First, the header says **unconditional**. With changing actor sets the
estimation must be unconditional (the rates are estimated together with the other parameters, as
described in [Tutorial 12](../tutorial-12-estimation-speed/)); `nwsaom` switches to it by itself. Second, the rates
(8.25 and 4.57) differ from those of the complete data (6.50 and 5.26), because they now describe the actors who are present in
a period; a pupil who is away is not given opportunities to change. Third, the coefficients are close to
those of the complete data, as they should be, because we only hid a few pupils.

### What happens if the model is not told?

For comparison, the same networks without `present()`:

```stata
. nwsaom, waves(comp1 comp2 comp3) outdegree reciprocity transtrip seed(4)
----------------------------------------------------------------------------------------------------
SAOM (Method of Moments, conditional), waves: comp1 comp2 comp3
Actors: 50                             Periods: 2
----------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------
comp1_to_c~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |   -2.62262   .1121841   -23.38   0.000    -2.842496   -2.402743
 reciprocity |   2.456261    .196206    12.52   0.000     2.071704    2.840818
   transtrip |   .6072784   .0879736     6.90   0.000     .4348533    .7797034
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

             |   period1    period2 
-------------+---------------------
        rate |    7.5197     4.2130 
          se |    1.4456     0.6905 
Overall maximum convergence ratio: 0.066 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

Here the estimates are also similar, because only seven of 50 pupils are involved. The difference is in
what the model believes: the joiners appear to have *created* all their ties between waves one and two
and the leavers to have *kept* theirs, and these are treated as ordinary choices of ordinary actors. With
a larger share of joiners and leavers, or with a stronger structure in the network, such a model
is wrong in a way that no output will tell you. Whenever the group changes, declare it.

| model | outdegree | reciprocity | transtrip | rate 1 | rate 2 |
|---|---|---|---|---|---|
| complete data | -2.70 | 2.47 | 0.63 | 6.50 | 5.26 |
| joiners and leavers, `present()` | -2.51 | 2.38 | 0.56 | 8.25 | 4.57 |
| joiners and leavers, not declared | -2.62 | 2.46 | 0.61 | 7.52 | 4.21 |

## Joiners and leavers at any time: joinat() and leaveat()

`present()` assumes that actors come and go *at* the waves. In reality a pupil may arrive in March and
leave in October. RSiena's way to describe this, which `nwsaom` follows, puts time on a scale on which wave 1
is time 1 and wave 3 is time 3, and gives each actor the time they join and the time they leave.
Pupils 1 to 4 now join at time 1.5, halfway between the first and second wave, and pupils 5 to 7 leave at time
2.5. Actors keep an empty row and column in the waves in which they are not there:

```stata
. generate double jn = 1
. replace jn = 1.5 if _n <= 4
. generate double lv = 3
. replace lv = 2.5 if inrange(_n, 5, 7)
```

`jn` is the joining time (1 for everybody who is there from the start) and `lv` the leaving time (3 for
everybody who stays to the end):

```stata
. nwsaom, waves(timed1 timed2 timed3) outdegree reciprocity transtrip joinat(jn) leaveat(lv) seed(4)
----------------------------------------------------------------------------------------------------
SAOM (Method of Moments, unconditional), waves: timed1 timed2 timed3
Actors: 50                             Periods: 2
----------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------
timed1_to_~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.613242   .1205242   -21.68   0.000    -2.849465   -2.377019
 reciprocity |   2.467177   .2110509    11.69   0.000     2.053525    2.880829
   transtrip |    .570416   .0827945     6.89   0.000     .4081418    .7326903
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

             |   period1    period2 
-------------+---------------------
        rate |    8.1907     6.4872 
          se |    2.0645     1.0973 
Overall maximum convergence ratio: 0.140 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

The pupils who join halfway through period one are active during the second half of it only, and the
pupils who leave halfway through period two are active during its first half only; the model counts
the time each pupil is present. The rates (8.19 and 6.49) are therefore not comparable with those of the
`present()` model, in which a pupil is either present for a whole period or not at all. Use `joinat()` and `leaveat()`
when you know the dates; use `present()` when you only know the waves.

## Missing data

### Missing ties: missnet()

Now the pupils are all present, but pupils 8 and 9 did not return the questionnaire in wave 2, so we
do not know whom they named. `missnet()` takes one 0/1 matrix per wave; a 1 marks a dyad whose value is
unknown. Here the whole outgoing rows of pupils 8 and 9 are missing in wave 2:

```stata
. mata:
: M2 = J(50, 50, 0)
: M2[8::9, .] = J(2, 50, 1)
: _diag(M2, 0)
: st_matrix("miss1", J(50, 50, 0))
: st_matrix("miss2", M2)
: st_matrix("miss3", J(50, 50, 0))
: end
```

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip missnet(miss1 miss2 miss3) seed(4)
----------------------------------------------------------------------------------------------------
SAOM (Method of Moments, conditional), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2
----------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------
glasgow1_t~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.747335   .1397676   -19.66   0.000    -3.021274   -2.473395
 reciprocity |   2.544075   .2319734    10.97   0.000     2.089416    2.998735
   transtrip |   .6478841   .0805108     8.05   0.000     .4900857    .8056824
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

             |   period1    period2 
-------------+---------------------
        rate |    6.1345     5.2180 
          se |    1.0683     0.8978 
Overall maximum convergence ratio: 0.072 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

The model uses the last observed value to fill in the unknown dyads for the simulation and leaves the dyads out of the
statistics that are compared with the data. The estimates (-2.75, 2.54 and 0.65) are again close to the full-data
values, with somewhat larger standard errors, which is exactly what a loss of information should do. Note that a
missing dyad is a Stata *matrix*, not a network.

### Missing behavior: missbeh()

Missing behavior works the same way with one 0/1 variable per wave. Here pupils 8 and 9 have no alcohol value in wave 2
(`mb2` is 1 for them):

```stata
. generate byte mb1 = 0
. generate byte mb2 = inlist(_n, 8, 9)
. generate byte mb3 = 0
```

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) behsim behavior(alcohol1 alcohol2 alcohol3) linear quadratic avalt missbeh(mb1 mb2 mb3) seed(4)
----------------------------------------------------------------------------------------------------
SAOM co-evolution (Method of Moments), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2
Behavior: alcohol1 alcohol2 alcohol3
----------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------
glasgow1_to~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
--------------+----------------------------------------------------------------
    outdegree |  -2.922766   .1522532   -19.20   0.000    -3.221176   -2.624355
  reciprocity |   2.468063   .1988948    12.41   0.000     2.078236    2.857889
    gwesp_.69 |   1.604373   .1615976     9.93   0.000     1.287647    1.921098
       behsim |   1.426698    .615931     2.32   0.021     .2194952      2.6339
   beh_linear |   .4229424   .2706495     1.56   0.118    -.1075208    .9534057
beh_quadratic |  -.6064355   .4572518    -1.33   0.185    -1.502633    .2897615
    beh_avalt |   1.346736   1.122016     1.20   0.230    -.8523742    3.545846
-------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

             |   period1    period2 
-------------+---------------------
network_rate |    6.5868     5.1593 
          se |    1.2039     0.9752 
behavior_r~e |    1.1568     1.8091 
          se |    0.3251     0.4882 
Overall maximum convergence ratio: 0.110 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

This is the co-evolution model of [Tutorial 4](../tutorial-4-selection-influence/), read in the same way (selection through
`behsim` is 1.43, z = 2.3; influence through `avalt` is 1.35 with a large standard error); `missbeh()` needs `behavior()`.
For `avalt` and `avsim` the treatment of missing values is an approximation, which is the more noticeable the more values are
missing; the package help describes the limits.

## Things to try

- Let more pupils join or leave, and see how the rates change.
- Combine `present()` with `missnet()`: both may be used together.
- Make the data wrong on purpose (leave the ties of a leaver in the first wave but code the pupil as
  absent) and look at the result.
- Add `present()` to the co-evolution model of Tutorial 4.

## Where next

[Tutorial 8](../tutorial-8-covariates/) adds covariates that change over time and covariates defined for pairs of actors.
The complete rules for composition change and missing data are in `help nwsaom` and `help nwsaom_remarks`.
