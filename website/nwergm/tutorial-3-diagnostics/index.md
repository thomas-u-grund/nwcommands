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
network (undirected, 43 workers), both shipped with `nwcommands`. Run with `nwergm` 1.2.2 and core 3.6.0;
the script and log are in [example.do](example.do) and [example.log](example.log). The output of
`estat mcmcdiag` and `estat gof` is long, so only the first tables are shown here.

## A fit with a short interval between the draws

Up to `nwergm` 1.1 the sampler kept a draw every 50 steps after a burn-in of 3,000 steps. Since 1.2 the defaults are
those of R's `ergm` (`mcmcinterval(1024)`, `mcmcburnin(16384)`). The first fit below gives the old values
explicitly, because it is a good example of a chain that mixes badly; the fits of the other tutorials use the new defaults.

```stata
. nwwebuse lazega, nwclear
. encode practice, generate(prac)
```

```stata
. nwergm lazega_fr, edges mutual nodematch(prac) nodeicov(seniority) gwesp(0.5) seed(1) mcmcinterval(50) mcmcburnin(3000)
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

## Fixing it: a longer interval and burn-in

The usual cure is to let the sampler run longer between the draws that are kept (`mcmcinterval()`) and
before the first draw (`mcmcburnin()`). `mcmcsamplesize()` sets the number of draws and
`mcmleiterations()` the maximum number of MCMLE iterations.

```stata
. nwergm lazega_fr, edges mutual nodematch(prac) nodeicov(seniority) gwesp(0.5) seed(1) mcmcinterval(1000) mcmcburnin(20
> 000)
...
------------------------------------------------------------------------------------
         lazega_fr | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------------+----------------------------------------------------------------
             edges |     -3.322   .1322327   -25.12   0.000    -3.581171   -3.062828
            mutual |   .8054353   .1623456     4.96   0.000     .4872438    1.123627
    nodematch_prac |   .7085933   .0833194     8.50   0.000     .5452903    .8718963
nodeicov_seniority |  -.0044098    .001753    -2.52   0.012    -.0078456    -.000974
         gwesp_0.5 |   .4920627   .0629934     7.81   0.000     .3685979    .6155275
------------------------------------------------------------------------------------

MCMLE converged after 1 iteration(s).
...
Log-likelihood: -1667.7124 (df = 5)   AIC:    3345.4   BIC:    3378.0   (MC std. err. =  .13051)
```

```stata
. estat mcmcdiag

MCMC diagnostics for the final simulation (nwergm, method(mcmle))
Sample size:         =    3000
Burn-in:             =   20000
Thinning interval:   =    1000
Acceptance rate:     =  0.6673

------------------------------------------------------------
Statistic       |      Mean         SD    Autocorr      ESS
----------------+-------------------------------------------
edges           |  572.1920    40.0988      0.8120    294.4
mutual          |   73.6250    10.4400      0.7226    372.5
nodematch_prac  |  408.7103    29.6283      0.8069    291.1
nodeicov_seniority|19333.6900  1498.0030      0.7868    327.1
gwesp_0.5       |  552.2042    74.8614      0.8046    297.2
------------------------------------------------------------

Geweke diagnostic (first 10% vs. last 50% of the retained sample):
---------------------------------------
Statistic       |         z   p-value
----------------+----------------------
---------------------------------------
...
```

The coefficients barely moved (for example `gwesp_0.5` 0.502 and 0.492, `mutual` 0.811 and 0.805), but
the autocorrelation fell from 0.99 to 0.72-0.81, the ESS rose to 291-373 and no Geweke statistic is
flagged. That is the pattern to aim for. Note that even then the autocorrelation is far from zero:
independence is not needed, only enough effective draws.

Even with the same `seed()`, the same model run in two different scripts gave
slightly different numbers in my runs (compare the `edges` row of the first fit with
the same fit in [ERGM 2](../tutorial-2-terms/)). Treat differences of this size as simulation noise.

## Goodness of fit

`estat gof` simulates networks from the fitted model and compares the observed network with them, first on
the model's own statistics, then on features the model was not built to reproduce: geodesic distances,
degrees and edgewise shared partners. A small Monte Carlo p-value flags a feature the model misses.
`nsim()` sets the number of simulated networks (50 here to keep the page short; use more in a real analysis).

```stata
. estat gof, nsim(50) seed(2)

Goodness-of-fit for model statistics

                       obs       min      mean       max  MC p-value
edges                  575       504    571.86       668        1.00
mutual                  74        52     71.76        97        0.80
nodematch_prac         412       354    407.68       504        0.76
nodeicov_senio~y     19379     16381  19258.90     22808        0.88
gwesp_0.5        555.61913 404.60634    546.79 727.40261        0.84

Goodness-of-fit for minimum geodesic distance

                       obs       min      mean       max  MC p-value
1                      575       504    571.86       668        1.00
2                     2316      2080   2490.06      2948        0.36
3                     1782      1316   1742.34      2054        0.76
4                      154        33    140.94       388        0.76
5                        3         0      3.78        37        0.96
6                        0         0      0.08         3        1.00
Inf                    140         0     20.94       139        0.00
...
```

(The out-degree, in-degree and shared-partner tables follow in the log.) The model statistics are all
reproduced (p between 0.76 and 1.00), and so are the geodesic distances 1 to 6; the pairs at
infinite distance (not connected) are less well reproduced (observed 140, simulated 21 on average, p = 0.00). Over the whole output only a
handful of rows are flagged: out-degree 0 (two lawyers send no nominations; the model simulates 0.10 on
average, p = 0.00), out-degree 22 and edgewise shared partners 6 (both p = 0.00). With about 70 rows, a few
small p-values are expected by chance; look for patterns, not single rows. A systematic gap, for
example too few high-degree nodes, would suggest adding a degree term (see [ERGM 2](../tutorial-2-terms/)).

## A model that cannot be fitted

Triangle counts are a classic trap. `triangle` is the plain number of triangles; a model with it can
fall into a degenerate region where the simulated networks are almost empty or almost complete.

```stata
. capture noisily nwergm kapferer_t2, edges triangle seed(1) mcmcsamplesize(1000)
Warning: MCMLE iter 2 - statistic(s) at column(s) 1 2 not varying this iteration - this may indicate an extreme point or
>  dead-end configuration.
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
       edges |  -4.294914   .4016951   -10.69   0.000    -5.082222   -3.507606
   gwesp_0.5 |   1.520809   .2313551     6.57   0.000     1.067362    1.974257
------------------------------------------------------------------------------

MCMLE converged after 3 iteration(s).
...
Log-likelihood:  -429.2887 (df = 2)   AIC:     862.6   BIC:     872.2   (MC std. err. =  .09657)
```

```stata
. estat gof, nsim(50) seed(2)

Goodness-of-fit for model statistics

                       obs       min      mean       max  MC p-value
edges                  190       132    186.58       227        1.00
gwesp_0.5        275.77262 166.16593    270.61 340.41329        0.88

Goodness-of-fit for minimum geodesic distance

                       obs       min      mean       max  MC p-value
1                      190       132    186.58       227        1.00
2                      535       377    521.64       609        1.00
3                      163        63    137.78       224        0.52
4                       15         0      8.04        59        0.32
5                        0         0      0.26         3        1.00
Inf                      0         0     48.70       162        0.80

Goodness-of-fit for degree

                       obs       min      mean       max  MC p-value
...
```

The fit converges and the closure effect is strongly positive (1.52). The goodness of fit shows one point
worth a note: the observed network has no pair at infinite distance, while the model simulates about 49
unconnected pairs on average (range 0 to 162, p = 0.80). The model gets density and clustering right but
is loose about connectedness; adding a degree term such as `gwdegree()` would be the next step.

## A checklist for a Monte Carlo fit

1. Read the warnings printed during estimation; "not varying" or "did not mix" means the model is
   degenerate or the sampler is stuck.
2. `estat mcmcdiag`: look at ESS (hundreds, not tens), Geweke and the acceptance rate.
3. If the diagnostics are poor, raise `mcmcinterval()`, `mcmcburnin()` and `mcmcsamplesize()`;
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
