---
title: "Tutorial 2: Convergence"
parent: "nwsaom (SAOM)"
nav_order: 3
description: "How to read the convergence diagnostics of nwsaom and what to do when a model has not converged: restart from the estimates, simplify, and test hypotheses with Stata's own Wald tests."
---

# Tutorial 2: Reading convergence, and what to do when it fails

**Goal.** Recognize a model that has not converged, restart it from its own estimates, and
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
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity gwesp(.69) indegpopularity outactivity egox(alcohol1)
> altx(alcohol1) simx(alcohol1) samex(smoke1) transtrip cycle3 seed(1) k3(100) detail
...
---------------------------------------------------------------------------------
glasgow1_to_g~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
----------------+----------------------------------------------------------------
      outdegree |  -1.206797   .4216402    -2.86   0.004    -2.033197   -.3803978
    reciprocity |   2.287804   .2790371     8.20   0.000     1.740901    2.834707
   samex_smoke1 |    .156457   .2465597     0.63   0.526    -.3267912    .6397052
  altx_alcohol1 |  -.0017842   .0908955    -0.02   0.984    -.1799361    .1763677
  egox_alcohol1 |   .1369944   .1706092     0.80   0.422    -.1973935    .4713824
indegpopularity |  -.6523969   .3524032    -1.85   0.064    -1.343094    .0383007
    outactivity |  -.1662348   .0661913    -2.51   0.012    -.2959673   -.0365023
      transtrip |  -1.219792   1.010376    -1.21   0.227    -3.200094    .7605094
         cycle3 |   1.031186   .6487586     1.59   0.112    -.2403572     2.30273
      gwesp_.69 |   3.937775   2.338965     1.68   0.092    -.6465124    8.522062
  simx_alcohol1 |   .5069069   .5748419     0.88   0.378    -.6197626    1.633576
---------------------------------------------------------------------------------
...
Convergence t-ratios (criterion: every |t| below 0.1; the overall maximum ratio below 0.25 is a separate criterion):
  outdegree                 -0.028      reciprocity               -0.117
  samex_smoke1               0.051      altx_alcohol1             -0.148
  egox_alcohol1             -0.087      indegpopularity           -0.059
  outactivity               -0.006      transtrip                 -0.025
  cycle3                    -0.046      gwesp_.69                 -0.028
  simx_alcohol1              0.023
Overall maximum convergence ratio:  0.431
```

The overall ratio is 0.431, far above 0.25. Yet the individual t-ratios are small: only
`altx_alcohol1` (-0.148) and `reciprocity` (-0.117) are above 0.1 in absolute value. The two criteria
are separate: the overall ratio looks at all statistics jointly, so it can be far too large while the
individual t-ratios look almost fine. Look at the
standard errors as well: `transtrip`, `cycle3` and `gwesp_.69` have very large ones (1.01, 0.65 and
2.34), about one and a half times those of the converged fit below. These three effects all measure
forms of clustering, so they are likely to be strongly correlated, which can make such a model hard to
estimate. A look at the standard errors can warn you before the convergence line does.

The t-ratios are also stored, as a matrix, in `e(tconv)`:

```stata
. matrix list e(tconv)

e(tconv)[1,11]
          outdegree   reciprocity  samex_smoke1  altx_alcoh~1  egox_alcoh~1  indegpopul~y   outactivity     transtrip
tconv    -.02768156    -.11684645     .05073641    -.14776505    -.08693343    -.05875035    -.00639966    -.02512445

             cycle3     gwesp_.69  simx_alcoh~1
tconv    -.04559339    -.02820332     .02289189
```

## Remedy 1: restart from the estimates

The simplest remedy, and the one RSiena recommends, is to estimate again with the previous
estimates as starting values. Since nwsaom 1.5.12 one line does it: `nwsaom refit` reruns the last
command (stored in `e(cmdline)`) with the estimates as starting values. Options given to `refit`
replace those of the stored command; here `k3(1000)` restores the default third phase, because the
stored command had `k3(100)`. `maxruns(3)` repeats the refit, at most three times, until both
convergence criteria are met:

```stata
. nwsaom refit, seed(2) k3(1000) maxruns(3)

------------------------------------------------------------------------------
nwsaom refit, run 1 of at most 3: starting from the last estimates (overall ratio 0.431)
------------------------------------------------------------------------------

SAOM (Method of Moments, conditional), waves: glasgow1 glasgow2 glasgow3
...
Overall maximum convergence ratio:  0.295

------------------------------------------------------------------------------
nwsaom refit, run 2 of at most 3: starting from the last estimates (overall ratio 0.295)
------------------------------------------------------------------------------

SAOM (Method of Moments, conditional), waves: glasgow1 glasgow2 glasgow3
Actors: 50                             Periods: 2

---------------------------------------------------------------------------------
glasgow1_to_g~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
----------------+----------------------------------------------------------------
      outdegree |  -1.201625   .5178923    -2.32   0.020    -2.216675   -.1865751
    reciprocity |   2.244478   .2636989     8.51   0.000     1.727637    2.761318
   samex_smoke1 |   .1632869   .1966773     0.83   0.406    -.2221936    .5487674
  altx_alcohol1 |   -.000592   .0836662    -0.01   0.994    -.1645747    .1633906
  egox_alcohol1 |   .1309877   .1009262     1.30   0.194    -.0668241    .3287995
indegpopularity |  -.6507214   .2986804    -2.18   0.029    -1.236124   -.0653186
    outactivity |  -.1626539   .0546861    -2.97   0.003    -.2698367    -.055471
      transtrip |  -1.178038   .6513056    -1.81   0.070    -2.454574    .0984971
         cycle3 |   1.043553   .4070135     2.56   0.010     .2458211    1.841285
      gwesp_.69 |   3.805257   1.373177     2.77   0.006     1.113881    6.496634
  simx_alcohol1 |   .5047753   .3170162     1.59   0.111     -.116565    1.126116
---------------------------------------------------------------------------------
...
Convergence t-ratios (criterion: every |t| below 0.1; the overall maximum ratio below 0.25 is a separate criterion):
  outdegree                 -0.007      reciprocity               -0.051
  samex_smoke1              -0.001      altx_alcohol1             -0.042
  egox_alcohol1             -0.006      indegpopularity           -0.011
  outactivity                0.007      transtrip                 -0.011
  cycle3                     0.012      gwesp_.69                 -0.028
  simx_alcohol1             -0.012
Overall maximum convergence ratio:  0.216

nwsaom refit: 2 runs; largest |t| 0.051, overall ratio 0.216 (converged)
```

The first run brings the overall ratio down from 0.431 to 0.295, still above 0.25, so `refit` runs
again. After the second run every t-ratio is below 0.1 (the largest is 0.051) and the overall ratio is
0.216: the fit has converged. The estimates themselves hardly changed (compare `outdegree`,
`reciprocity`, `gwesp_.69`), but the standard errors are now based on a converged model with the full
1,000 phase-3 simulations, and they are much smaller for the clustering effects. Restarting is cheap,
so do it whenever the overall ratio is above 0.25 (and, if you want to be thorough, also when some
t-ratio is above 0.1).

The same can be done by hand: rerun the `nwsaom` command with `theta0()`, which takes one starting
value per effect, in the order of `e(b)`. An unconditional fit also needs the rates, with `rate0()`
(see [Tutorial 12](../tutorial-12-estimation-speed/)).

## Remedy 2: simplify the model

If repeated restarts do not help, the model is probably asking too much of the data (here:
three clustering effects at once on 50 actors). Drop the effect with the largest standard error,
or replace several related effects by one. Typical suspects are
`cycle3` or two clustering effects together, or effects of covariates that vary very little. With
only two or three waves and a small group, a model with five or six effects is usually what the data
can carry.

Two further options exist for difficult data. `unconditional` estimates the rates together with the
other parameters instead of conditioning on the observed amount of change (to restart it,
`nwsaom refit` passes `rate0()` as well as `theta0()`), and `firstg()` sets the starting step size of the
Robbins-Monro algorithm (default 0.2). Both are described in `help nwsaom`; try them only after
the first two remedies.

## Testing hypotheses with Stata's own commands

A converged `nwsaom` fit leaves `e(b)` and `e(V)` behind, and Stata's standard Wald-test commands
work on them. Are the effects of a pupil's own drinking (`egox`) and of the drinking of the
others (`altx`) the same size?

```stata
. test egox_alcohol1 = altx_alcohol1

 ( 1)  - altx_alcohol1 + egox_alcohol1 = 0

           chi2(  1) =    0.80
         Prob > chi2 =    0.3702
```

```stata
. lincom egox_alcohol1 - altx_alcohol1

 ( 1)  - altx_alcohol1 + egox_alcohol1 = 0

------------------------------------------------------------------------------
glasgow1_t~3 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
         (1) |   .1315797   .1468356     0.90   0.370    -.1562127    .4193721
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
- Run the first model without `k3(100)`, with the default 1,000 simulations, and compare the overall
  ratio with the 0.431 above.
- Remove `cycle3` and compare the standard errors of `transtrip` and `gwesp_.69`.
- After the restart, run `estat gof` and see [Tutorial 3](../tutorial-3-goodness-of-fit/).

## Where next

[Tutorial 3](../tutorial-3-goodness-of-fit/) asks a different question: not whether the estimation
worked but whether the model describes the data well.
