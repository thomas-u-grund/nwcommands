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
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip egox(alcohol1) altx(alcohol1) simx(alcohol1)
>  seed(1)
...
-------------------------------------------------------------------------------
glasgow1_to~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
--------------+----------------------------------------------------------------
    outdegree |  -2.714049   .1174508   -23.11   0.000    -2.944249    -2.48385
  reciprocity |   2.439188   .1944542    12.54   0.000     2.058065    2.820311
altx_alcohol1 |  -.0435285   .0680369    -0.64   0.522    -.1768784    .0898214
egox_alcohol1 |   .0402063   .0760539     0.53   0.597    -.1088566    .1892692
    transtrip |   .6276928   .0765488     8.20   0.000     .4776599    .7777256
simx_alcohol1 |   .6213602   .3148591     1.97   0.048     .0042478    1.238473
-------------------------------------------------------------------------------
...
Overall maximum convergence ratio: 0.155 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): met
```

Wald tests (the z and p columns) say that only `simx_alcohol1` stands out, with p = 0.048. The Wald test needs the
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
y1    -2.7140494     2.4391878    -.04352852     .04020633     .62769275     .62136021
```

The names in `fix()` are written the way the effects were requested, `egox(alcohol1)` and so on.
We take the coefficients of the full model and set the three tested ones to zero:

```stata
. matrix b0 = b

. foreach c in egox_alcohol1 altx_alcohol1 simx_alcohol1 {
  2.     matrix b0[1, colnumb(b0, "`c'")] = 0
  3. }

. local th

. forvalues j = 1/`=colsof(b0)' {
  2.     local th `th' `=b0[1,`j']'
  3. }
```

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip egox(alcohol1) altx(alcohol1) simx(alcohol1)
>  theta0(`th') fix(egox(alcohol1) altx(alcohol1) simx(alcohol1)) seed(1)
...
-------------------------------------------------------------------------------
glasgow1_to~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
--------------+----------------------------------------------------------------
    outdegree |  -2.671588   .1091836   -24.47   0.000    -2.885584   -2.457592
  reciprocity |   2.447578   .1964377    12.46   0.000     2.062567    2.832589
altx_alcohol1 |          0  (omitted)
egox_alcohol1 |          0  (omitted)
    transtrip |   .6211502    .073698     8.43   0.000     .4767049    .7655956
simx_alcohol1 |          0  (omitted)
-------------------------------------------------------------------------------
...
Overall maximum convergence ratio: 0.102 (criterion: below 0.25; met)
Convergence t-ratios (criterion: all below 0.1 in absolute value): not met for
  altx_alcohol1 (0.443) egox_alcohol1 (-0.101) simx_alcohol1 (-1.970)
Convergence is good only if both criteria are met.
To refit starting from these estimates, type nwsaom refit.
```

The fixed effects are shown as `0 (omitted)` and have no standard errors. Their "convergence
t-ratios" are large: they say how far the *observed* statistics are from what the restricted model
produces, and that is exactly what the score test tests. For the same reason the advice to refit can
be ignored here: the t-ratio criterion fails only for the three effects that are held at zero on
purpose. Now:

```stata
. estat score

Score-type test of fixed effects
H0: each effect below equals its fixed value

-----------------------------------------------------------------
      Effect |  Fixed at      chi2   df  Prob > chi2  One-sided z
-------------+---------------------------------------------------
altx_alcoh~1 |    0.0000     0.192    1       0.6612       -0.438
egox_alcoh~1 |    0.0000     0.012    1       0.9114        0.111
simx_alcoh~1 |    0.0000     4.180    1       0.0409        2.045
-------------+---------------------------------------------------
       Joint |               4.905    3       0.1789
-----------------------------------------------------------------

One-step estimates (restricted estimates plus the one-step correction)
-----------------------------------------------------------------
      Effect |    Estimate
-------------+---------------------------------------------------
   outdegree |     -2.6828
 reciprocity |      2.4395
altx_alcoh~1 |     -0.0508
egox_alcoh~1 |      0.0443
   transtrip |      0.6172
simx_alcoh~1 |      0.5908
-----------------------------------------------------------------
```

How to read it. The joint test of all three effects is not significant (p = 0.18): drinking as a
whole does not significantly improve the model. The separate tests single out `simx_alcohol1`
(chi2 = 4.18, p = 0.041; the one-sided value 2.05 is positive, so the improvement would come from
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
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip egox(alcohol1) altx(alcohol1) simx(alcohol1)
>  seed(1)
...
. estat timetest

Test of time heterogeneity (score-type test)
H0: the parameter of each effect is the same in all periods

---------------------------------------------------------
      Effect |          chi2        df        Prob > chi2
-------------+-------------------------------------------
   outdegree |         0.017         1             0.8976
 reciprocity |         0.706         1             0.4008
altx_alcoh~1 |         2.140         1             0.1435
egox_alcoh~1 |         1.551         1             0.2130
   transtrip |         0.331         1             0.5648
simx_alcoh~1 |         1.478         1             0.2240
-------------+-------------------------------------------
       Joint |         8.244         6             0.2208
---------------------------------------------------------

Period-specific deviations (one-step estimates) and separate tests
---------------------------------------------------------
      Effect |  Period   Deviation      chi2  Prob > chi2
-------------+-------------------------------------------
   outdegree |       2     -0.3346     0.017       0.8976
 reciprocity |       2      0.7594     0.706       0.4008
altx_alcoh~1 |       2      0.1366     2.140       0.1435
egox_alcoh~1 |       2      0.0763     1.551       0.2130
   transtrip |       2      0.0606     0.331       0.5648
simx_alcoh~1 |       2     -0.8212     1.478       0.2240
---------------------------------------------------------
```

The joint test (p = 0.22) and every single test are far from significant: the effects can be
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

Relative importance of effects
Expected over the actors at the start of each period
--------------------------------------------------------------------------
      Effect | Estimate  Std. err.    Sigma  Semi-std.     RI p1     RI p2
-------------+------------------------------------------------------------
   outdegree |  -2.7140     0.1175   0.4384    -1.1898    0.4111    0.4749
 reciprocity |   2.4392     0.1945   0.2140     0.5220    0.3539    0.2932
altx_alcoh~1 |  -0.0435     0.0680   1.1027    -0.0480    0.0172    0.0162
egox_alcoh~1 |   0.0402     0.0761   0.4948     0.0199    0.0120    0.0111
   transtrip |   0.6277     0.0765   0.6514     0.4089    0.1572    0.1581
simx_alcoh~1 |   0.6214     0.3149   0.2259     0.1404    0.0486    0.0464
-------------+------------------------------------------------------------
   Certainty |                                            0.2785    0.3501
--------------------------------------------------------------------------
RI: share of the effect in the actors' choices. Semi-std.: estimate x sigma.
Certainty: RSiena's R_H, the expected certainty of the choices.
```

The columns `RI p1` and `RI p2` are the shares of importance in each period (each column adds up to 1).
Roughly 41 to 47% goes to the baseline `outdegree`, 29 to 35% to reciprocity and 16% to
`transtrip`. The significant drinking-similarity effect carries about 5%, and the two other alcohol
effects about 1 to 2%: statistically detectable, but small. `Semi-std.` (estimate times `Sigma`)
makes the coefficients comparable across effects measured in different units. The row `Certainty`
is `R_H`, the certainty of the actors' choices as RSiena's `sienaRI` defines it (higher means that the actors'
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
