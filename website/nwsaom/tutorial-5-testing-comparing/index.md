---
title: "Tutorial 5: Testing and comparing"
parent: "nwsaom (SAOM)"
nav_order: 6
description: "Score tests for effects held fixed with fix(), tests of time heterogeneity and the relative importance of effects with nwsaom (estat score, estat timetest, estat importance)."
---

# Tutorial 5: Testing and comparing effects

**Goal.** Decide which effects belong in a model, whether an effect is the same in every period,
and how much each effect matters for the actors' choices.

**Data.** The Glasgow data (see [Tutorial 1](../tutorial-1-first-saom/)). Script and log:
[example.do](example.do), [example.log](example.log).

Three tools do these jobs, and all three are RSiena tools, available in `nwsaom` as postestimation
commands: `estat score` (RSiena's score-type test), `estat timetest` (`sienaTimeTest`) and `estat importance`
(`sienaRI`).

## The full model

We ask whether a pupil's drinking (`alcohol1`) matters for friendship choices, in three ways: the
pupil's own drinking (`egox`), the drinking of the pupil who is named (`altx`), and drinking
similarity (`simx`).

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip egox(alcohol1) altx(alcohol1) simx(alcohol1) seed(1)
...
-------------------------------------------------------------------------------
glasgow1_to~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
--------------+----------------------------------------------------------------
    outdegree |  -2.704605   .1132713   -23.88   0.000    -2.926613   -2.482598
  reciprocity |    2.42243   .1930407    12.55   0.000     2.044077    2.800782
altx_alcohol1 |  -.0519366   .0711545    -0.73   0.465    -.1913969    .0875238
egox_alcohol1 |   .0463259   .0742919     0.62   0.533    -.0992835    .1919354
    transtrip |   .6295243   .0734725     8.57   0.000     .4855209    .7735277
simx_alcohol1 |    .628046   .3094458     2.03   0.042     .0215433    1.234549
-------------------------------------------------------------------------------
...
Overall maximum convergence ratio: 0.096 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

Wald tests (the z and p columns) say that only `simx_alcohol1` stands out, with p = 0.042. The Wald test needs the
*full* model to be estimated. A score test works the other way round: it needs only the
*restricted* model, in which the effects to be tested are held at zero, and tells you whether
freeing them would improve the fit. That is useful when the full model is hard to estimate, or when
you want to test many candidate effects one after the other. A joint test of several effects at
once is available too.

## The score test

Fix the three alcohol effects at zero with `fix()`, and give starting values with
`theta0()`, one value per effect in the order of `e(b)`:

```stata
. matrix b = e(b)
. matrix list b

b[1,6]
       outdegree   reciprocity  altx_alcoh~1  egox_alcoh~1     transtrip  simx_alcoh~1
y1    -2.7046054     2.4224296    -.05193656     .04632593     .62952427     .62804597
```

The names in `fix()` are written the way the effects were requested, `egox(alcohol1)` and so on.
We take the coefficients of the full model and set the three tested ones to zero:

```stata
. matrix b0 = b
. foreach c in egox_alcohol1 altx_alcohol1 simx_alcohol1 {
.     matrix b0[1, colnumb(b0, "`c'")] = 0
. }
. local th
. forvalues j = 1/`=colsof(b0)' {
.     local th `th' `=b0[1,`j']'
. }
```

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip egox(alcohol1) altx(alcohol1) simx(alcohol1) theta0(`th') fix(egox(alcohol1) altx(alcohol1) simx(alcohol1)) seed(1)
...
-------------------------------------------------------------------------------
glasgow1_to~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
--------------+----------------------------------------------------------------
    outdegree |  -2.679504   .1231556   -21.76   0.000    -2.920885   -2.438124
  reciprocity |   2.456962   .1990359    12.34   0.000     2.066859    2.847065
altx_alcohol1 |          0  (omitted)
egox_alcohol1 |          0  (omitted)
    transtrip |   .6242752   .0814667     7.66   0.000     .4646033     .783947
simx_alcohol1 |          0  (omitted)
-------------------------------------------------------------------------------
...
Overall maximum convergence ratio: 0.095 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): not met for altx_alcohol1 (0.462) simx_alcohol1 (-1.9
> 87)
Convergence is good only if both criteria are met. Refit starting from these estimates with theta0(); see nwsaom.
```

The fixed effects are shown as `0 (omitted)` and have no standard errors. Their "convergence
t-ratios" are large: they say how far the *observed* statistics are from what the restricted model
produces, and that is exactly what the score test tests. Now:

```stata
. estat score

Score-type test of the restricted model (as RSiena score.Test)
Tests whether the fixed effects below differ from their fixed values.

            effect |  Fixed at     chi2  d.f. Prob>chi2 One-sided z
-------------------+-----------------------------------------------
     altx_alcohol1 |    0.0000    0.207     1    0.6491      -0.455
     egox_alcohol1 |    0.0000    0.002     1    0.9671       0.041
     simx_alcohol1 |    0.0000    4.440     1    0.0351       2.107
-------------------+-----------------------------------------------
        Joint test |              4.990     3    0.1725
-------------------------------------------------------------------

One-step estimates (restricted estimate plus the one-step correction)
            effect |  Estimate
-------------------+----------
         outdegree |   -2.6811
       reciprocity |    2.4278
     altx_alcohol1 |   -0.0427
     egox_alcohol1 |    0.0264
         transtrip |    0.6133
     simx_alcohol1 |    0.5837
------------------------------
```

How to read it. The joint test of all three effects is not significant (p = 0.17): drinking as a
whole does not significantly improve the model. The separate tests single out `simx_alcohol1`
(c = 4.44, p = 0.035; the one-sided value 2.11 is positive, so the improvement would come from
a *positive* effect). Own and others' drinking add nothing. This is the same message as the Wald tests of the full model,
reached without ever estimating it. The one-step estimates at the bottom approximate what you would get by
freeing the effects, and `r(chi2)`, `r(df)`, `r(p)`, `r(separate)` and `r(onestep)` store the results.
`estat score, tested(namelist)` restricts the test to some of the fixed effects.

A practical strategy that follows from this is to fit a model you are happy with, then to fix several
candidate effects at zero and test them all in one run, and to free only those that look promising.

## Time heterogeneity

An SAOM assumes that the coefficients are the same in every period. With three or more waves, this can be tested:
`estat timetest` extends the model by period-specific deviations (RSiena's `sienaTimeTest`) and asks whether any of them is needed. It uses the fit in memory
(here again the full model, so we first fit it again) and needs no second estimation:

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip egox(alcohol1) altx(alcohol1) simx(alcohol1) seed(1)
. estat timetest

Test of time heterogeneity (score-type test; as RSiena sienaTimeTest)
Is the parameter of an effect the same in all periods?

            effect |      chi2  d.f.  Prob>chi2
-------------------+---------------------------
         outdegree |     0.017     1     0.8955
       reciprocity |     0.755     1     0.3848
     altx_alcohol1 |     2.449     1     0.1176
     egox_alcohol1 |     1.631     1     0.2016
         transtrip |     0.330     1     0.5657
     simx_alcohol1 |     1.292     1     0.2557
-------------------+---------------------------
        Joint test |     8.022     6     0.2365
-----------------------------------------------

Period-specific deviations (one-step estimates) and separate tests
            effect |  Period   Deviation      chi2  Prob>chi2
-------------------+-----------------------------------------
         outdegree |       2     -0.3116     0.017     0.8955
       reciprocity |       2      0.7407     0.755     0.3848
     altx_alcohol1 |       2      0.1365     2.449     0.1176
     egox_alcohol1 |       2      0.0821     1.631     0.2016
         transtrip |       2      0.0519     0.330     0.5657
     simx_alcohol1 |       2     -0.8234     1.292     0.2557
-------------------------------------------------------------
```

The joint test (p = 0.24) and every single test are far from significant: the effects can be
assumed to be constant over the two periods. If one effect did differ, the "deviation" table would show by how much
in which period. (The default treats the rate parameters as estimated; the option `fixrates` holds them fixed
as `sienaTimeTest` does. The two agree closely except for effects such as the out-degree effect of a
network whose changes are close to random. See `help nwsaom_estat`.)

## Relative importance

A significant effect can still be a small effect. `estat importance` asks, for every actor and every
possible tie change, how much the choice probabilities would change without the effect, and
averages over the actors (`sienaRI`):

```stata
. estat importance

Relative importance of effects (as RSiena sienaRI)
Expected over the actors at the start of each period
            effect | Estimate  Std. err.    Sigma  Semi-std.     RI p1     RI p2
-------------------+------------------------------------------------------------
         outdegree |  -2.7046     0.1133   0.4384    -1.1857    0.4083    0.4719
       reciprocity |   2.4224     0.1930   0.2140     0.5184    0.3510    0.2906
     altx_alcohol1 |  -0.0519     0.0712   1.1027    -0.0573    0.0204    0.0193
     egox_alcohol1 |   0.0463     0.0743   0.4948     0.0229    0.0137    0.0128
         transtrip |   0.6295     0.0735   0.6514     0.4101    0.1577    0.1584
     simx_alcohol1 |   0.6280     0.3094   0.2259     0.1419    0.0489    0.0469
-------------------+------------------------------------------------------------
     Certainty R_H |                                            0.2765    0.3479
--------------------------------------------------------------------------------
RI: share of the effect in the actors' choices. Semi-std. = estimate x sigma.
```

The columns `RI p1` and `RI p2` are the shares of importance in each period (each column adds up to 1).
Roughly 40 to 47% goes to the baseline `outdegree`, 29 to 35% to reciprocity and 16% to
`transtrip`. The significant drinking-similarity effect carries about 5%, and the two other alcohol
effects about 1 to 2%: statistically detectable, but small. `semi-std.` (estimate times `sigma`)
makes the coefficients comparable across effects measured in different units. `R_H` is the
certainty of the actors' choices as RSiena's `sienaRI` defines it (higher means that the actors'
choices are more predictable from the model): 0.28 and 0.35 in the two periods.

## Things to try

- Test `indegpopularity`, `outactivity` and `cycle3` jointly with `fix()` and `estat score`.
- Fix a larger set of effects and use the option `tested()` of `estat score` to test only some of them.
- Run `estat timetest, fixrates` and compare it with the default.
- Run `estat importance` after a co-evolution fit ([Tutorial 4](../tutorial-4-selection-influence/));
  it adds a second table for the behavior effects.
- Wald tests with `test` and `lincom` are in [Tutorial 2](../tutorial-2-convergence/).

## Where next

[Tutorial 6](../tutorial-6-beyond/) leaves the basic model behind: other estimators and more than
one network.
