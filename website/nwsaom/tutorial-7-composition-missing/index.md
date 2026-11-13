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
they are not findings about the school. The commands were run with `nwsaom` 1.6.0 and the core 3.22.0 in
Stata 17. The complete script and log are in [example.do](example.do) and
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

SAOM (Method of Moments, unconditional), waves: comp1 comp2 comp3
Actors: 50                             Periods: 2

------------------------------------------------------------------------------
comp1_to_c~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.533458   .1135779   -22.31   0.000    -2.756067    -2.31085
 reciprocity |   2.401016   .2013638    11.92   0.000      2.00635    2.795682
   transtrip |   .5687039   .0866895     6.56   0.000     .3987956    .7386123
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

------------------------------------
             |   period1    period2 
-------------+----------------------
        rate |    8.3697     4.2092
          se |    1.7167     0.5975
------------------------------------
Overall maximum convergence ratio: 0.144 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): not met for
  transtrip (0.125) rate_period1 (0.114)
Convergence is good only if both criteria are met.
To refit starting from these estimates, type nwsaom refit.
```

Three things to notice. First, the header says **unconditional**. With changing actor sets the
estimation must be unconditional (the rates are estimated together with the other parameters, as
described in [Tutorial 12](../tutorial-12-estimation-speed/)); `nwsaom` switches to it by itself. Second, the rates
(8.37 and 4.21) differ from those of the complete data (6.45 and 5.25), because they now describe the actors who are present in
a period; a pupil who is away is not given opportunities to change. Third, the coefficients are close to
those of the complete data, as they should be, because we only hid a few pupils. The t-ratios of `transtrip` and
of the first rate are slightly above 0.1 in this run; `nwsaom refit` ([Tutorial 2](../tutorial-2-convergence/)) would
bring them down before the results are reported.

### What happens if the model is not told?

For comparison, the same networks without `present()`:

```stata
. nwsaom, waves(comp1 comp2 comp3) outdegree reciprocity transtrip seed(4)

SAOM (Method of Moments, conditional), waves: comp1 comp2 comp3
Actors: 50                             Periods: 2

------------------------------------------------------------------------------
comp1_to_c~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.614313   .1188111   -22.00   0.000    -2.847179   -2.381448
 reciprocity |   2.440239   .1994858    12.23   0.000     2.049254    2.831224
   transtrip |   .6092232   .0908508     6.71   0.000      .431159    .7872875
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

------------------------------------
             |   period1    period2 
-------------+----------------------
        rate |    7.5681     4.2258
          se |    1.4209     0.6866
------------------------------------
Overall maximum convergence ratio: 0.134 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

Here the estimates are also similar, because only seven of 50 pupils are involved. The difference is in
what the model believes: the joiners appear to have *created* all their ties between waves one and two
and the leavers to have *kept* theirs, and these are treated as ordinary choices of ordinary actors. With
a larger share of joiners and leavers, or with a stronger structure in the network, such a model
is wrong in a way that no output will tell you. Whenever the group changes, declare it.

| model | outdegree | reciprocity | transtrip | rate 1 | rate 2 |
|---|---|---|---|---|---|
| complete data | -2.68 | 2.44 | 0.62 | 6.45 | 5.25 |
| joiners and leavers, `present()` | -2.53 | 2.40 | 0.57 | 8.37 | 4.21 |
| joiners and leavers, not declared | -2.61 | 2.44 | 0.61 | 7.57 | 4.23 |

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

SAOM (Method of Moments, unconditional), waves: timed1 timed2 timed3
Actors: 50                             Periods: 2

------------------------------------------------------------------------------
timed1_to_~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.611397   .1228231   -21.26   0.000    -2.852126   -2.370668
 reciprocity |   2.474275   .2042072    12.12   0.000     2.074037    2.874514
   transtrip |   .5668171   .0805009     7.04   0.000     .4090382     .724596
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

------------------------------------
             |   period1    period2 
-------------+----------------------
        rate |    8.1344     6.5500
          se |    1.5383     1.4172
------------------------------------
Overall maximum convergence ratio: 0.128 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): not met for
  reciprocity (0.109) transtrip (0.123)
Convergence is good only if both criteria are met.
To refit starting from these estimates, type nwsaom refit.
```

The pupils who join halfway through period one are active during the second half of it only, and the
pupils who leave halfway through period two are active during its first half only; the model counts
the time each pupil is present. The rates (8.13 and 6.55) are therefore not comparable with those of the
`present()` model, in which a pupil is either present for a whole period or not at all. (Two t-ratios are again
slightly above 0.1; refit before reporting.) Use `joinat()` and `leaveat()`
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

SAOM (Method of Moments, conditional), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2

------------------------------------------------------------------------------
glasgow1_t~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.746586   .1378324   -19.93   0.000    -3.016732   -2.476439
 reciprocity |   2.533789   .2284156    11.09   0.000     2.086102    2.981475
   transtrip |   .6528808   .0801681     8.14   0.000     .4957542    .8100074
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

------------------------------------
             |   period1    period2 
-------------+----------------------
        rate |    6.0834     5.2370
          se |    1.0307     0.9249
------------------------------------
Overall maximum convergence ratio: 0.150 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

The model uses the last observed value to fill in the unknown dyads for the simulation and leaves the dyads out of the
statistics that are compared with the data. The estimates (-2.75, 2.53 and 0.65) are again close to the full-data
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

SAOM co-evolution (Method of Moments), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2
Behavior: alcohol1 alcohol2 alcohol3

-------------------------------------------------------------------------------
glasgow1_to~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
--------------+----------------------------------------------------------------
    outdegree |  -2.921145   .1677994   -17.41   0.000    -3.250026   -2.592264
  reciprocity |   2.466327   .1909513    12.92   0.000     2.092069    2.840585
    gwesp_.69 |   1.603193   .1692151     9.47   0.000     1.271537    1.934848
       behsim |   1.426001   .6629097     2.15   0.031     .1267221     2.72528
   beh_linear |    .428535   .2586134     1.66   0.098     -.078338     .935408
beh_quadratic |  -.6037095   .4196919    -1.44   0.150     -1.42629    .2188715
    beh_avalt |   1.327782   .9986662     1.33   0.184    -.6295674    3.285132
-------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

------------------------------------
             |   period1    period2 
-------------+----------------------
network_rate |    6.5743     5.1583
          se |    1.2127     1.0772
behavior_r~e |    1.1632     1.8139
          se |    0.3271     0.4554
------------------------------------
Overall maximum convergence ratio: 0.123 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

This is the co-evolution model of [Tutorial 4](../tutorial-4-selection-influence/), read in the same way (selection through
`behsim` is 1.43, z = 2.2; influence through `avalt` is 1.33 with a large standard error); `missbeh()` needs `behavior()`.
For `avalt` and `avsim` the treatment of missing values is an approximation, which is the more noticeable the more values are
missing; the package help describes the limits.

## Dyads that cannot change: structural zeros and ones

Sometimes some pairs of actors can never be tied (for example pupils in different classrooms), or are always
tied. RSiena calls these *structural zeros* and *structural ones*. They go into the wave data as special
values: **10** marks a dyad that is fixed at "no tie" and **11** a dyad that is fixed at "tie". `nwsaom`
recognizes the codes by itself, no option is needed, and they may differ from wave to wave. As an
illustration we pretend that pupils 1 to 25 and pupils 26 to 50 sit in different classrooms, so that no tie can
form between the two groups. This changes the Glasgow data, so the numbers are not findings about the school.

```stata
. nwtomata glasgow1, mat(S1)
. nwtomata glasgow2, mat(S2)
. nwtomata glasgow3, mat(S3)
. mata:
: S1[1::25, 26::50] = J(25, 25, 10)
: S1[26::50, 1::25] = J(25, 25, 10)
: (the same two lines for S2 and S3)
: st_matrix("SZ1", S1)
: st_matrix("SZ2", S2)
: st_matrix("SZ3", S3)
: end
. nwset, mat(SZ1) directed name(sz1)
. nwset, mat(SZ2) directed name(sz2)
. nwset, mat(SZ3) directed name(sz3)
```

```stata
. nwsaom, waves(sz1 sz2 sz3) outdegree reciprocity transtrip seed(1)

SAOM (Method of Moments, conditional), waves: sz1 sz2 sz3
Actors: 50                             Periods: 2

------------------------------------------------------------------------------
  sz1_to_sz3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
   outdegree |  -2.987998   .2289911   -13.05   0.000    -3.436813   -2.539184
 reciprocity |   2.942142   .3298347     8.92   0.000     2.295677    3.588606
   transtrip |   .6678744   .1171709     5.70   0.000     .4382236    .8975251
------------------------------------------------------------------------------
Rate parameters (estimated, one per inter-wave period):

------------------------------------
             |   period1    period2 
-------------+----------------------
        rate |    4.7006     3.0595
          se |    0.8448     0.6093
------------------------------------
Overall maximum convergence ratio: 0.072 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

There are 1,250 fixed dyads in each wave (25 x 25 in each direction). Fixed dyads cannot change, so ties can
only form or be dropped between pupils in the same group, and the estimates describe tie formation inside the
two groups. Use 10 for dyads that must stay empty and 11 for dyads that must stay tied.
RSiena uses the same codes, and the older option `structural()` that takes a matrix still works but is
deprecated.

## Things to try

- Let more pupils join or leave, and see how the rates change.
- Combine `present()` with `missnet()`: both may be used together.
- Make the data wrong on purpose (leave the ties of a leaver in the first wave but code the pupil as
  absent) and look at the result.
- Add `present()` to the co-evolution model of Tutorial 4.

## Where next

[Tutorial 8](../tutorial-8-covariates/) adds covariates that change over time and covariates defined for pairs of actors.
The complete rules for composition change and missing data are in `help nwsaom` and `help nwsaom_remarks`.
