---
title: "Tutorial 3: Diagnostics and goodness of fit"
parent: "nwergm (ERGM)"
nav_order: 4
description: "Check a Monte Carlo ERGM fit with estat mcmcdiag, judge it with estat gof, and what to do when a model does not converge."
---

# ERGM 3: Diagnostics and goodness of fit

**Goal.** Know when a Monte Carlo ERGM fit can be trusted. Two questions need two tools:
*did the simulation behind the estimates behave?* (`estat mcmcdiag`) and *does the fitted model
reproduce the network?* (`estat gof`). The page also shows a model that cannot be fitted and what to do about it.

* Builds on [ERGM 2](../tutorial-2-terms/). Needs the core `nwcommands` and `nwergm` (see [Install](../install/)).
* Dyad-independent models are fitted by pseudolikelihood, involve no simulation and need no
  `estat mcmcdiag`; `estat gof` works for every fit.

**Data.** The Lazega lawyers' friendship network (directed, 71 lawyers) and the Kapferer tailor shop
network (undirected, 43 workers), both shipped with `nwcommands`. Run with `nwergm` 1.3.0 and core 3.10.0;
the script and log are in [example.do](example.do) and [example.log](example.log). The output of
`estat mcmcdiag` and `estat gof` is long, so only the first tables are shown here.

## A fit with a short interval between the draws

Up to `nwergm` 1.1 the sampler kept a draw every 50 steps after a burn-in of 3,000 steps and recorded 3,000 draws
per iteration. Since 1.2 the interval and burn-in are those of R's `ergm` (`mcmcinterval(1024)`, `mcmcburnin(16384)`),
and since 1.3.0 the sample size is adaptive, as in R: each iteration draws a base sample and keeps sampling until the
effective sample size reaches 64 (`mcmleeffectivesize()`, default 64). `mcmleeffectivesize(0)` switches this off and gives the
fixed-size samples of earlier versions; `mcmcsamplesize()` is then the number of draws, otherwise it is the base size.

The first fit below asks for the old behaviour explicitly (a short interval and a fixed sample of 3,000 draws), because it is
a good example of a chain that mixes badly. The second fit uses the 1.3.0 defaults. Both are 1.3.0 output.

```stata
. nwwebuse lazega, nwclear
. encode practice, generate(prac)
```

```stata
. nwergm lazega_fr, edges mutual nodematch(prac) nodeicov(seniority) gwesp(0.5) seed(1) mcmcinterval(50) mcmcburnin(3000) mcmleeffectivesize(0)
...
------------------------------------------------------------------------------------
         lazega_fr | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------------+----------------------------------------------------------------
             edges |  -3.322119   .1437037   -23.12   0.000    -3.603773   -3.040465
            mutual |    .810562   .1634309     4.96   0.000     .4902434    1.130881
    nodematch_prac |   .6795895    .090628     7.50   0.000     .5019619    .8572172
nodeicov_seniority |  -.0043864   .0020888    -2.10   0.036    -.0084803   -.0002924
         gwesp_0.5 |   .5023746   .0653666     7.69   0.000     .3742584    .6304907
------------------------------------------------------------------------------------

MCMLE converged after 1 iteration(s).
...
Log-likelihood: -1669.6228 (df = 5)   AIC:    3349.2   BIC:    3381.8   (MC std. err. =  .31714)
```

The table looks reasonable, and `nwergm` says that the fit converged after one iteration. That sentence
only says that its own stopping rule was met. To look at the simulation itself, use `estat mcmcdiag`:

```stata
. estat mcmcdiag

MCMC diagnostics for the final simulation (nwergm, method(mcmle))
Sample size:         =    3000
Burn-in:             =    3000
Thinning interval:   =      50
Acceptance rate:     =  0.6694

------------------------------------------------------------
Statistic       |      Mean         SD    Autocorr      ESS
----------------+-------------------------------------------
edges           |  578.0303    45.5309      0.9921     13.7
mutual          |   74.7633    11.5793      0.9850     18.8
nodematch_prac  |  407.8230    34.4362      0.9920     13.7
nodeicov_seniority|19478.4000  1781.8600      0.9913     15.1
gwesp_0.5       |  561.3006    86.7234      0.9913     14.6
------------------------------------------------------------

Geweke diagnostic (first 10% vs. last 50% of the retained sample):
---------------------------------------
Statistic       |         z   p-value
----------------+----------------------
edges           |     4.066    0.0000  *
mutual          |     3.279    0.0010  *
nodematch_prac  |     3.428    0.0006  *
nodeicov_seniority|     5.118    0.0000  *
gwesp_0.5       |     3.957    0.0001  *
---------------------------------------
...
```

(The report continues with the Heidelberger-Welch tests and the output of R's `mcmc.diagnostics()`.)
How to read it:

- **Acceptance rate** is the share of proposed changes that the sampler accepted; very low values mean
  that the sampler hardly moves.
- **Autocorr** is the correlation between draws that are `Thinning interval` steps apart. Values near 1
  mean that consecutive draws are nearly copies of each other.
- **ESS**, the effective sample size, is the number of independent draws that the 3,000 draws are worth.
  Here it is 14 to 19 for every statistic: the estimates rest on very little information, although the
  sample looks large.
- **Geweke** compares the start and the end of the chain. A star marks a statistic whose chain is
  not stable; here all five are flagged.

## Fixing it: the defaults of 1.3.0

The usual cure is to let the sampler run longer between the draws that are kept (`mcmcinterval()`) and
before the first draw (`mcmcburnin()`), and to base the estimates on enough effective draws. The defaults of 1.3.0 do both:
R's interval and burn-in, and a sample that is extended until its effective sample size is large enough.
`mcmcsamplesize()` sets the base number of draws and `mcmleiterations()` the maximum number of MCMLE iterations.

```stata
. nwergm lazega_fr, edges mutual nodematch(prac) nodeicov(seniority) gwesp(0.5) seed(1)
...
------------------------------------------------------------------------------------
         lazega_fr | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------------+----------------------------------------------------------------
             edges |   -3.32184    .131386   -25.28   0.000    -3.579352   -3.064328
            mutual |   .7969492   .1553399     5.13   0.000     .4924887     1.10141
    nodematch_prac |   .7214706    .080024     9.02   0.000     .5646264    .8783149
nodeicov_seniority |  -.0046162   .0018014    -2.56   0.010    -.0081468   -.0010856
         gwesp_0.5 |   .4935235    .061269     8.06   0.000     .3734384    .6136085
------------------------------------------------------------------------------------

MCMLE converged after 2 iteration(s).
...
Log-likelihood: -1667.4731 (df = 5)   AIC:    3344.9   BIC:    3377.5   (MC std. err. =  .15171)
```

```stata
. estat mcmcdiag

MCMC diagnostics for the final simulation (nwergm, method(mcmle))
Sample size:         =     486
Burn-in:             =   16384
Thinning interval:   =    1024
Acceptance rate:     =  0.6692

------------------------------------------------------------
Statistic       |      Mean         SD    Autocorr      ESS
----------------+-------------------------------------------
edges           |  571.1543    39.0767      0.6726     95.6
mutual          |   73.6770    10.4820      0.5538    120.0
nodematch_prac  |  406.3889    30.0663      0.6635     98.8
nodeicov_seniority|19282.2500  1453.6430      0.6317     73.9
gwesp_0.5       |  546.8287    74.5329      0.6491    103.9
------------------------------------------------------------

Geweke diagnostic (first 10% vs. last 50% of the retained sample):
---------------------------------------
Statistic       |         z   p-value
----------------+----------------------
edges           |    -1.610    0.1073
mutual          |    -1.972    0.0486  *
nodematch_prac  |    -1.128    0.2594
nodeicov_seniority|    -1.297    0.1947
gwesp_0.5       |    -1.501    0.1335
---------------------------------------
...
```

The coefficients barely moved (for example `gwesp_0.5` 0.502 and 0.494, `mutual` 0.811 and 0.797), but
the autocorrelation fell from 0.99 to 0.55-0.67 and the ESS rose from 14-19 to 74-120. This fit needed 486 draws
(the table of the fit prints "MCMC sample size"), a sixth of the 3,000 of the first fit, and is worth far more. One Geweke statistic is still flagged
(`mutual`, z = -1.97, p = 0.049), only just: with five statistics, one borderline flag is not alarming, but it is a reason to look at the
trace (`estat mcmcdiag, plot`) and to raise the target (`mcmleeffectivesize(200)`) for a final analysis. Note that
even then the autocorrelation is far from zero: independence is not needed, only enough effective draws.

The default fit with `seed(1)` is the same fit as in [ERGM 2](../tutorial-2-terms/) and prints the same numbers there. The
first fit above differs from it because its settings differ. A different `seed()` or a different setting
gives slightly different numbers; treat differences of this size as simulation noise.

## Goodness of fit

`estat gof` simulates networks from the fitted model and compares the observed network with them, first on
the model's own statistics, then on features the model was not built to reproduce: geodesic distances,
degrees and edgewise shared partners. A small Monte Carlo p-value flags a feature the model misses.
`nsim()` sets the number of simulated networks (50 here to keep the page short; use more in a real analysis).

```stata
. estat gof, nsim(50) seed(2)

Goodness-of-fit for model statistics

                       obs       min      mean       max  MC p-value
edges                  575       503    586.20       685        0.80
mutual                  74        58     74.20        96        1.00
nodematch_prac         412       366    421.06       493        0.84
nodeicov_senio~y     19379     15657  19581.72     22829        0.80
gwesp_0.5        555.61913 431.86804    580.31   786.826        0.76

Goodness-of-fit for minimum geodesic distance

                       obs       min      mean       max  MC p-value
1                      575       503    586.20       685        0.80
2                     2316      2086   2553.72      2968        0.16
3                     1782      1201   1684.34      1968        0.56
4                      154        18    115.78       335        0.48
5                        3         0      1.98        10        0.44
Inf                    140         0     27.98       140        0.04
...
```

(The out-degree, in-degree and shared-partner tables follow in the log.) The model statistics are all
reproduced (p between 0.76 and 1.00), and so are the geodesic distances 1 to 5; the pairs at
infinite distance (not connected) are less well reproduced (observed 140, simulated 28 on average, p = 0.04). Over the whole output only a
handful of rows are flagged: out-degree 0 (two lawyers send no nominations; the model simulates 0.24 on
average, p = 0.00), out-degree 9 and 22 (both p = 0.04). With about 60 rows, a few
small p-values are expected by chance; look for patterns, not single rows. A systematic gap, for
example too few high-degree nodes, would suggest adding a degree term (see [ERGM 2](../tutorial-2-terms/)).

## A model that cannot be fitted

Triangle counts are a classic trap. `triangle` is the plain number of triangles; a model with it can
fall into a degenerate region where the simulated networks are almost empty or almost complete.

```stata
. capture noisily nwergm kapferer_t2, edges triangle seed(1) mcmcsamplesize(1000)
Warning: MCMLE iter 2 - statistic(s) at column(s) 1 2 not varying this iteration - this may indicate an extreme point or 
> dead-end configuration.
Unconstrained MCMC sampling did not mix at all. Optimization cannot continue.
```

The sampler did not move at all, and the command stopped with return code 498. The message is the
signal: do not make the settings longer, change the specification. The geometrically weighted
`gwesp()` was designed to avoid this behavior:

```stata
. nwergm kapferer_t2, edges gwesp(0.5) seed(1)
...
------------------------------------------------------------------------------
 kapferer_t2 | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------+----------------------------------------------------------------
       edges |  -4.270901   .4311131    -9.91   0.000    -5.115867   -3.425935
   gwesp_0.5 |   1.505898   .2434484     6.19   0.000     1.028747    1.983048
------------------------------------------------------------------------------

MCMLE converged after 4 iteration(s).
...
Log-likelihood:  -428.6868 (df = 2)   AIC:     861.4   BIC:     871.0   (MC std. err. =  .22782)
```

```stata
. estat gof, nsim(50) seed(2)

Goodness-of-fit for model statistics

                       obs       min      mean       max  MC p-value
edges                  190       146    186.54       227        0.88
gwesp_0.5        275.77262 195.37931    269.97 342.59428        0.84

Goodness-of-fit for minimum geodesic distance

                       obs       min      mean       max  MC p-value
1                      190       146    186.54       227        0.88
2                      535       397    526.12       614        0.84
3                      163        62    139.84       233        0.60
4                       15         0      7.38        48        0.28
5                        0         0      0.22         6        1.00
Inf                      0         0     42.90       200        0.88

Goodness-of-fit for degree

                       obs       min      mean       max  MC p-value
...
```

The fit converges and the closure effect is strongly positive (1.51). The goodness of fit shows one point
worth a note: the observed network has no pair at infinite distance, while the model simulates about 43
unconnected pairs on average (range 0 to 200, p = 0.88). The model gets density and clustering right but
is loose about connectedness; adding a degree term such as `gwdegree()` would be the next step.

## A checklist for a Monte Carlo fit

1. Read the warnings printed during estimation; "not varying" or "did not mix" means the model is
   degenerate or the sampler is stuck.
2. `estat mcmcdiag`: look at ESS (the default aims for at least 64 per statistic; for a final analysis, hundreds rather than tens), Geweke and the acceptance rate.
3. If the diagnostics are poor, raise `mcmleeffectivesize()` (the target for the adaptive sample), `mcmcinterval()`, `mcmcburnin()` and `mcmcsamplesize()`;
   `estat mcmcdiag, plot` draws trace plots for a visual check.
4. If the sampler is stuck or the fit will not converge, change the terms (for example `triangle` to
   `gwesp()`), not the settings.
5. `estat gof` with a larger `nsim()`, and rerun with another `seed()` to see how much the results move.

## Things to try

- Fit the Lazega model with `mcmcinterval(2000)` and compare the ESS with the table above.
- Run `estat mcmcdiag, plot`.
- Add `gwidegree(0.5)` to the Kapferer model and see whether the unconnected pairs disappear.
- Use `estat gof, nsim(200)` and compare the p-values with those above.

## Where next

[ERGM 4](../tutorial-4-missing-comparing/) turns to missing dyads and to comparing models.
The syntax of both tools is in `help nwergm_estat`.
