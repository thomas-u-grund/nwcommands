---
title: "Tutorial 3: Diagnostics and goodness of fit"
parent: "nwergm (ERGM)"
nav_order: 4
description: "Check a Monte Carlo ERGM fit with estat mcmcdiag, judge it with estat gof, and what to do when a model does not converge."
---

# Tutorial 3: Diagnostics and goodness of fit

**Goal.** Know when a Monte Carlo ERGM fit can be trusted. Two questions need two tools:
*did the simulation behind the estimates behave?* (`estat mcmcdiag`) and *does the fitted model
reproduce the network?* (`estat gof`). The page also shows a model that cannot be fitted and what to do about it.

* Builds on [Tutorial 2](../tutorial-2-terms/). Needs the core `nwcommands` and `nwergm` (see [Install](../install/)).
* Dyad-independent models are fitted by pseudolikelihood, involve no simulation and need no
  `estat mcmcdiag`; `estat gof` works for every fit.

**Data.** The Lazega lawyers' friendship network (directed, 71 lawyers) and the Kapferer tailor shop
network (undirected, 43 workers), both shipped with `nwcommands`. Run with `nwergm` 1.6.0 and core 3.22.0;
the script and log are in [example.do](example.do) and [example.log](example.log). The output of
`estat mcmcdiag` and `estat gof` is long, so only the first tables are shown here.

## A fit with a short interval between the draws

Up to `nwergm` 1.1 the sampler kept a draw every 50 steps after a burn-in of 3,000 steps and recorded 3,000 draws
per iteration. Since 1.2 the interval and burn-in are those of R's `ergm` (`mcmcinterval(1024)`, `mcmcburnin(16384)`),
and since 1.3.0 the sample size is adaptive, as in R: each iteration draws a base sample and keeps sampling until the
effective sample size reaches 64 (`mcmleeffectivesize()`, default 64). `mcmleeffectivesize(0)` switches this off and gives the
fixed-size samples of earlier versions; `mcmcsamplesize()` is then the number of draws, otherwise it is the base size.

The first fit below asks for the old behaviour explicitly (a short interval and a fixed sample of 3,000 draws), because it is
a good example of a chain that mixes badly. The second fit uses the 1.3.0 defaults. Both are 1.6.0 output.

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
             edges |  -3.299282    .161064   -20.48   0.000    -3.614962   -2.983602
            mutual |   .8312222   .1500579     5.54   0.000     .5371141     1.12533
    nodematch_prac |   .7169036   .0846234     8.47   0.000     .5510448    .8827624
nodeicov_seniority |  -.0052748   .0020911    -2.52   0.012    -.0093732   -.0011764
         gwesp_0.5 |   .4898494   .0651695     7.52   0.000     .3621196    .6175792
------------------------------------------------------------------------------------

MCMLE converged after 1 iteration(s).
...
Log-likelihood: -1667.5558 (df = 5)   AIC:    3345.1   BIC:    3377.7
Monte Carlo standard error of the log-likelihood:  .03905
```

The table looks reasonable, and `nwergm` says that the fit converged after one iteration. That sentence
only says that its own stopping rule was met. To look at the simulation itself, use `estat mcmcdiag`:

```stata
. estat mcmcdiag

MCMC diagnostics, final sample             Sample size      =      3,000
                                           Burn-in          =      3,000
                                           Interval         =         50
                                           Acceptance rate  =     0.5716

------------------------------------------------------------------------
         Statistic |      Mean        SD  Autocorr       ESS   Geweke z
-------------------+----------------------------------------------------
             edges |    579.88     37.80     0.990      16.0      1.16
            mutual |     75.96     11.21     0.984      22.7      1.30
    nodematch_prac |    416.38     32.76     0.991      13.0      1.36
nodeicov_seniority |  19186.31   1434.38     0.989      17.5      1.77
         gwesp_0.5 |    568.80     73.55     0.988      20.0      1.36
------------------------------------------------------------------------

The convergence test of MCMLE was satisfied after 1 iteration. This is necessary but not sufficient for convergence;
option plot draws the trace plots.
If the ESS is low, raise mcmleeffectivesize(); after mcmleeffectivesize(0), raise mcmcsamplesize() or mcmcinterval().
```

(Options `heidel` and `report` add the Heidelberger-Welch tests and the output of R's `mcmc.diagnostics()`.)
How to read it:

- **Acceptance rate** is the share of proposed changes that the sampler accepted; very low values mean
  that the sampler hardly moves.
- **Autocorr** is the correlation between draws that are `Interval` steps apart. Values near 1
  mean that consecutive draws are nearly copies of each other. The interval shown is that of the final sample; when
  the adaptive sampler had to space the draws further apart than requested, a note below the table says so.
- **ESS**, the effective sample size, is the number of independent draws that the 3,000 draws of this fit are worth.
  Here it is 13 to 23 for every statistic: the estimates rest on very little information, although the
  sample looks large.
- **Geweke z** compares the mean of the start and of the end of the chain; an absolute value above about 2
  suggests that the chain is not stable. Here the values are 1.2 to 1.8: not alarming on their own, but with so few
  effective draws the test has little power.

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
             edges |  -3.318445   .1335225   -24.85   0.000    -3.580144   -3.056746
            mutual |   .8058073   .1547052     5.21   0.000     .5025907    1.109024
    nodematch_prac |   .7113241   .0808705     8.80   0.000     .5528208    .8698274
nodeicov_seniority |  -.0044112   .0017983    -2.45   0.014    -.0079358   -.0008866
         gwesp_0.5 |   .4896686   .0639934     7.65   0.000     .3642438    .6150933
------------------------------------------------------------------------------------

MCMLE converged after 6 iteration(s).
...
Log-likelihood: -1667.5431 (df = 5)   AIC:    3345.1   BIC:    3377.6
Monte Carlo standard error of the log-likelihood:  .16479
```

```stata
. estat mcmcdiag

MCMC diagnostics, final sample             Sample size      =        593
                                           Burn-in          =     16,384
                                           Interval         =      4,096
                                           Acceptance rate  =     0.5765

------------------------------------------------------------------------
         Statistic |      Mean        SD  Autocorr       ESS   Geweke z
-------------------+----------------------------------------------------
             edges |    579.02     39.63     0.496     201.1      0.17
            mutual |     73.96     10.62     0.367     185.4      0.23
    nodematch_prac |    414.53     30.84     0.491     203.8      0.13
nodeicov_seniority |  19563.64   1467.93     0.439     232.1      0.14
         gwesp_0.5 |    562.29     75.43     0.484     207.4      0.33
------------------------------------------------------------------------
The adaptive sampler raised the interval from 1,024 to 4,096.

The convergence test of MCMLE was satisfied after 6 iterations. This is necessary but not sufficient for convergence;
option plot draws the trace plots.
If the ESS is low, raise mcmleeffectivesize(); after mcmleeffectivesize(0), raise mcmcsamplesize() or mcmcinterval().
```

The coefficients barely moved (for example `gwesp_0.5` 0.490 and 0.490, `mutual` 0.831 and 0.806), but
the autocorrelation fell from about 0.99 to 0.37-0.50 and the ESS rose from 13-23 to 185-232. This fit needed 593 draws
(the table of the fit prints "MCMC sample size"), a fifth of the 3,000 of the first fit, and is worth far more. Its draws are
4,096 steps apart, not the 1,024 that were requested: the adaptive sampler doubles the spacing whenever the sample has doubled in
size, and the note below the table of `estat mcmcdiag` says so. The Geweke statistics are all small (below 0.4).
For a final analysis it is still worth looking at the
trace (`estat mcmcdiag, plot`) and raising the target (`mcmleeffectivesize(200)`). Note that
even then the autocorrelation is far from zero: independence is not needed, only enough effective draws.

The default fit with `seed(1)` is the same fit as in [Tutorial 2](../tutorial-2-terms/) and prints the same numbers there. The
first fit above differs from it because its settings differ. A different `seed()` or a different setting
gives slightly different numbers; treat differences of this size as simulation noise.

## Goodness of fit

`estat gof` simulates networks from the fitted model and compares the observed network with them, first on
the model's own statistics, then on features the model was not built to reproduce: geodesic distances,
degrees and edgewise shared partners. A small Monte Carlo p-value flags a feature the model misses.
`nsim()` sets the number of simulated networks (50 here to keep the page short; use more in a real analysis).

```stata
. estat gof, nsim(50) seed(2)

Goodness of fit: model statistics (50 simulated networks)
------------------------------------------------------------------------
         Statistic |  Observed       Min      Mean       Max  MC p-value
-------------------+----------------------------------------------------
             edges |       575       520    583.70       646        0.80
            mutual |        74        58     77.32       101        0.80
    nodematch_prac |       412       369    416.98       477        0.88
nodeicov_seniority |     19379     17207  19613.96     22532        0.88
         gwesp_0.5 |    555.62    446.94    572.61    687.94        0.76
------------------------------------------------------------------------

Goodness of fit: minimum geodesic distance (50 simulated networks)
------------------------------------------------------------------
    Distance |  Observed       Min      Mean       Max  MC p-value
-------------+----------------------------------------------------
           1 |       575       520    583.70       646        0.80
           2 |      2316      2248   2556.40      2865        0.12
           3 |      1782      1409   1697.08      1969        0.56
           4 |       154        11    106.16       240        0.40
           5 |         3         0      1.48        14        0.40
         Inf |       140         0     25.18       139        0.00
------------------------------------------------------------------
...
```

(The out-degree, in-degree and shared-partner tables follow in the log.) The model statistics are all
reproduced (p between 0.76 and 0.88), and so are the geodesic distances 1 to 5; the pairs at
infinite distance (not connected) are not (observed 140, simulated 25 on average, p = 0.00). Over the whole output only a
handful of rows are flagged: out-degree 0 (two lawyers send no nominations; the model simulates 0.16 on
average, p = 0.00), out-degree 3 and 20 (both p = 0.04). With about 60 rows, a few
small p-values are expected by chance; look for patterns, not single rows. A systematic gap, for
example too few high-degree nodes, would suggest adding a degree term (see [Tutorial 2](../tutorial-2-terms/)).

## A model that cannot be fitted

Triangle counts are a classic trap. `triangle` is the plain number of triangles; a model with it can
fall into a degenerate region where the simulated networks are almost empty or almost complete.

```stata
. capture noisily nwergm kapferer_t2, edges triangle seed(1) mcmcsamplesize(1000)
Warning: MCMLE iter 2 - statistic(s) at column(s) 1 2
not varying this iteration - this may indicate an extreme point or dead-end configuration.
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
       edges |  -4.246618   .4222083   -10.06   0.000    -5.074131   -3.419105
   gwesp_0.5 |   1.498293   .2426614     6.17   0.000     1.022685    1.973901
------------------------------------------------------------------------------

MCMLE converged after 6 iteration(s).
...
Log-likelihood:  -429.0194 (df = 2)   AIC:     862.0   BIC:     871.7
Monte Carlo standard error of the log-likelihood:  .11996
```

```stata
. estat gof, nsim(50) seed(2)

Goodness of fit: model statistics (50 simulated networks)
------------------------------------------------------------------
   Statistic |  Observed       Min      Mean       Max  MC p-value
-------------+----------------------------------------------------
       edges |       190       143    190.48       229        0.84
   gwesp_0.5 |    275.77    202.20    276.47    348.81        0.80
------------------------------------------------------------------

Goodness of fit: minimum geodesic distance (50 simulated networks)
------------------------------------------------------------------
    Distance |  Observed       Min      Mean       Max  MC p-value
-------------+----------------------------------------------------
           1 |       190       143    190.48       229        0.84
           2 |       535       377    535.10       613        0.88
           3 |       163        69    130.50       209        0.44
           4 |        15         0      4.02        23        0.12
           5 |         0         0      0.06         2        1.00
         Inf |         0         0     42.84       200        0.84
------------------------------------------------------------------
...
```

The fit converges and the closure effect is strongly positive (1.50). The goodness of fit shows one point
worth a note: the observed network has no pair at infinite distance, while the model simulates about 43
unconnected pairs on average (range 0 to 200, p = 0.84). The model gets density and clustering right but
is loose about connectedness; adding a degree term such as `gwdegree()` would be the next step.

## A checklist for a Monte Carlo fit

1. Read the warnings printed during estimation; "not varying" or "did not mix" means the model is
   degenerate or the sampler is stuck.
2. `estat mcmcdiag`: look at ESS (the default aims for at least 64 per statistic; for a final analysis, hundreds rather than tens), Geweke and the acceptance rate.
3. If the diagnostics are poor, raise `mcmleeffectivesize()` (the target for the adaptive sample; the note at the end of the report
   suggests it), `mcmcinterval()` and `mcmcburnin()`. For a fit with a fixed-size sample (`mcmleeffectivesize(0)`) raise `mcmcsamplesize()` or `mcmcinterval()` instead;
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

[Tutorial 4](../tutorial-4-missing-comparing/) turns to missing dyads and to comparing models.
The syntax of both tools is in `help nwergm_estat`.
