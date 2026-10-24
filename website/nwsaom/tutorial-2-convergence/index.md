---
title: "Tutorial 2: Convergence"
parent: "nwsaom (SAOM)"
nav_order: 3
description: "How to read the convergence diagnostics of nwsaom and what to do when a model has not converged: restart from the estimates, simplify, and test hypotheses with Stata's own Wald tests."
---

# Tutorial 2: Reading convergence, and what to do when it fails

**Goal.** Recognise a model that has not converged, restart it from its own estimates, and
test hypotheses about the coefficients afterwards.

**Data.** The Glasgow friendship data again (`nwwebuse glasgow, nwclear`); see
[Tutorial 1](../tutorial-1-first-saom/). Script and log: [example.do](example.do),
[example.log](example.log).

## Why convergence matters

`nwsaom` estimates by simulation: it adjusts the coefficients until networks simulated from the
model reproduce, on average, the statistics of the observed data. If it stops before they match,
the numbers are simply not the estimates of the model and no table of standard errors can repair that.
The check is therefore part of the output, not an optional extra:

| Overall maximum convergence ratio | What it means |
|---|---|
| every t-ratio below 0.1 in absolute value, overall below 0.25 | good |
| overall below 0.25, some t-ratio at or above 0.1 | acceptable; the offending parameters are listed |
| overall at or above 0.25 | **not converged**: do not interpret |

## A model that does not converge

A rich model (nine effects, several covariates) is estimated here with a deliberately short third
phase, `k3(100)`. The third phase is the one that simulates the final model many times to
compute the convergence statistics and the standard errors (the default is 1,000 simulations);
with only 100 the result is noisy, and this is a convenient way to make the problem appear.
`detail` prints every t-ratio.

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) indegpopularity outactivity egox(alcohol1) altx(alcohol1) simx(alcohol1) samex(smoke1) transtrip cycle3 seed(1) k3(100) detail
...
---------------------------------------------------------------------------------
glasgow1_to_g~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
----------------+----------------------------------------------------------------
      outdegree |  -1.209788   .6076227    -1.99   0.046    -2.400707   -.0188697
    reciprocity |   2.263883    .529079     4.28   0.000     1.226907    3.300859
   samex_smoke1 |   .1610482   .2266739     0.71   0.477    -.2832245    .6053209
  altx_alcohol1 |    .006889   .1107258     0.06   0.950    -.2101297    .2239076
  egox_alcohol1 |   .1359848   .1114579     1.22   0.222    -.0824685    .3544382
indegpopularity |  -.6466204   .4983963    -1.30   0.194    -1.623459    .3302184
    outactivity |  -.1646595   .0717318    -2.30   0.022    -.3052512   -.0240677
      transtrip |  -1.179726   1.512629    -0.78   0.435    -4.144425    1.784972
         cycle3 |   1.029549   1.018194     1.01   0.312    -.9660754    3.025173
      gwesp_.69 |   3.840171   3.118244     1.23   0.218    -2.271475    9.951818
  simx_alcohol1 |   .5145673   .3656165     1.41   0.159     -.202028    1.231163
---------------------------------------------------------------------------------
...
Convergence t-ratios (|t| < 0.1 good; overall maximum ratio < 0.25 good):
  outdegree                  0.199      reciprocity                0.165
  samex_smoke1               0.049      altx_alcohol1              0.300
  egox_alcohol1              0.241      indegpopularity            0.201
  outactivity                0.238      transtrip                  0.213
  cycle3                     0.192      gwesp_.69                  0.215
  simx_alcohol1              0.201
Overall maximum convergence ratio:  0.427
```

The overall ratio is 0.427, far above 0.25, and most individual t-ratios are around 0.2. Look at the
coefficients as well: `transtrip` has flipped sign and, with `cycle3` and `gwesp_.69`, has huge standard errors. These three effects all measure
forms of clustering, so they are likely to be strongly correlated, which can make such a model hard to
estimate. A look at the standard errors can warn you before the convergence line does.

The t-ratios are also stored, as a matrix, in `e(tconv)`:

```stata
. matrix list e(tconv)

e(tconv)[1,11]
          outdegree   reciprocity  samex_smoke1  altx_alcoh~1  egox_alcoh~1  indegpopul~y   outactivity     transtrip
tconv     .19864068      .1645989     .04859904     .29953977     .24109886     .20086809     .23756474     .21284053
...
```

## Remedy 1: restart from the estimates

The simplest remedy, and the one RSiena recommends, is to estimate again with the previous
estimates as starting values. The option `theta0()` takes one starting value per effect, in the
order of `e(b)`, so we can build the list from the matrix:

```stata
. matrix b = e(b)
. local th
. forvalues j = 1/`=colsof(b)' {
.     local th `th' `=b[1,`j']'
. }
. display "`th'"
-1.209788342910438 2.263883290175206 .161048200899927 .0068889647862173 .1359848318693529 -.646620403954551 -.16465947714
> 10311 -1.179726289641659 1.029548730367141 3.840171283459527 .5145672925763973
```

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) indegpopularity outactivity egox(alcohol1) altx(alcohol1) simx(alcohol1) samex(smoke1) transtrip cycle3 seed(2) theta0(`th') detail
...
---------------------------------------------------------------------------------
glasgow1_to_g~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
----------------+----------------------------------------------------------------
      outdegree |   -1.20907   .5609371    -2.16   0.031    -2.308487   -.1096537
    reciprocity |   2.280546   .2646771     8.62   0.000     1.761789    2.799304
   samex_smoke1 |   .1680516   .1960388     0.86   0.391    -.2161774    .5522807
  altx_alcohol1 |  -.0002235   .0776939    -0.00   0.998    -.1525007    .1520538
  egox_alcohol1 |   .1379253   .1047766     1.32   0.188     -.067433    .3432837
indegpopularity |  -.6432866   .3120702    -2.06   0.039    -1.254933   -.0316402
    outactivity |  -.1674719   .0622312    -2.69   0.007    -.2894428    -.045501
      transtrip |  -1.192036    .806658    -1.48   0.139    -2.773056    .3889849
         cycle3 |   1.015119   .5305186     1.91   0.056    -.0246787    2.054916
      gwesp_.69 |   3.876746   1.589124     2.44   0.015     .7621203    6.991372
  simx_alcohol1 |   .4904613   .3493353     1.40   0.160    -.1942234    1.175146
---------------------------------------------------------------------------------
...
Convergence t-ratios (|t| < 0.1 good; overall maximum ratio < 0.25 good):
  outdegree                  0.063      reciprocity                0.056
  samex_smoke1               0.049      altx_alcohol1              0.025
  egox_alcohol1              0.022      indegpopularity            0.069
  outactivity                0.062      transtrip                  0.058
  cycle3                     0.052      gwesp_.69                  0.060
  simx_alcohol1             -0.005
Overall maximum convergence ratio:  0.091
```

Now every t-ratio is below 0.1 and the overall ratio is 0.091. The estimates themselves hardly
changed (compare `outdegree`, `reciprocity`, `gwesp_.69`), but the standard errors are now based on a
converged model with the full 1,000 phase-3 simulations, and they are much smaller for the clustering
effects. Restarting is cheap, so do it whenever the overall ratio is above 0.25 (and, if
you want to be thorough, also when it is between 0.1 and 0.25). If the second run is not good either, you
can repeat it.

## Remedy 2: simplify the model

If repeated restarts do not help, the model is probably asking too much of the data (here:
three clustering effects at once on 50 actors). Drop the effect with the largest standard error,
or replace several related effects by one. Typical suspects are
`cycle3` or two clustering effects together, or effects of covariates that vary very little. With
only two or three waves and a small group, a model with five or six effects is usually what the data
can carry.

Two further options exist for difficult data. `unconditional` estimates the rates together with the
other parameters instead of conditioning on the observed amount of change (the model then needs
`rate0()` as well as `theta0()` to restart), and `firstg()` sets the starting step size of the
Robbins-Monro algorithm (default 0.2). Both are described in `help nwsaom`; try them only after
the first two remedies.

## Testing hypotheses with Stata's own commands

A converged `nwsaom` fit leaves `e(b)` and `e(V)` behind, and Stata's standard Wald-test commands
work on them. Are the effects of a pupil's own drinking (`egox`) and of the drinking of the
others (`altx`) the same size?

```stata
. test egox_alcohol1 = altx_alcohol1

 ( 1)  - altx_alcohol1 + egox_alcohol1 = 0

           chi2(  1) =    0.98
         Prob > chi2 =    0.3234
```

```stata
. lincom egox_alcohol1 - altx_alcohol1
...
------------------------------------------------------------------------------
glasgow1_t~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
         (1) |   .1381488   .1399055     0.99   0.323     -.136061    .4123586
------------------------------------------------------------------------------
```

There is no evidence that they differ. `test` also takes several coefficients at once for a
joint test, and `estimates store` / `estimates table` compare several fits side by side.
Wald tests need the standard errors to be reliable, which is another reason to only use them
after convergence. A different kind of test, that needs only the *restricted* model, is the
score test in [Tutorial 5](../tutorial-5-testing-comparing/).

## Things to try

- Re-run the first model with `seed(2)`, `seed(3)`, ... and watch the overall ratio. A
  model that is borderline converges in some runs and not in others.
- Run the first model without `k3(100)`: with the default 1,000 simulations the same model with `seed(1)` has an overall ratio of 0.218.
- Remove `cycle3` and compare the standard errors of `transtrip` and `gwesp_.69`.
- After the restart, run `estat gof` and see [Tutorial 3](../tutorial-3-goodness-of-fit/).

## Where next

[Tutorial 3](../tutorial-3-goodness-of-fit/) asks a different question: not whether the estimation
worked but whether the model describes the data well.
