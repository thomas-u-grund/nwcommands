---
title: "ERGM 3: Diagnostics and goodness of fit"
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
network (undirected, 43 workers), both shipped with `nwcommands`. Run with `nwergm` 1.0.1 and core 3.0.0;
the script and log are in [example.do](example.do) and [example.log](example.log). The output of
`estat mcmcdiag` and `estat gof` is long, so only the first tables are shown here.

## A fit with the default simulation settings

```stata
. nwwebuse lazega, nwclear
. encode practice, generate(prac)
```

```stata
. nwergm lazega_fr, edges mutual nodematch(prac) nodeicov(seniority) gwesp(0.5) seed(1)
...
------------------------------------------------------------------------------------
         lazega_fr | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------------+----------------------------------------------------------------
             edges |  -3.374867   .1442935   -23.39   0.000    -3.657677   -3.092057
            mutual |   .8033219     .17915     4.48   0.000     .4521944    1.154449
    nodematch_prac |   .7218557   .0911736     7.92   0.000     .5431588    .9005526
nodeicov_seniority |  -.0047432   .0018304    -2.59   0.010    -.0083307   -.0011558
         gwesp_0.5 |   .5112641   .0714758     7.15   0.000      .371174    .6513541
------------------------------------------------------------------------------------

MCMLE converged after 1 iteration(s).
...
Log-likelihood: -1667.7296 (df = 5)   AIC:    3345.5   BIC:    3378.0   (MC std. err. =  .04434)
```

The table looks reasonable, and `nwergm` says that the fit converged after one iteration. That sentence
only says that its own stopping rule was met. To look at the simulation itself, use `estat mcmcdiag`:

```stata
. estat mcmcdiag

MCMC diagnostics for the final simulation (nwergm, method(mcmle))
Sample size:         =    3000
Burn-in:             =    3000
Thinning interval:   =      50
Acceptance rate:     =  0.6557

------------------------------------------------------------
Statistic       |      Mean         SD    Autocorr      ESS
----------------+-------------------------------------------
edges           |  545.3090    47.1413      0.9922     14.6
mutual          |   68.9320    12.3692      0.9868     21.0
nodematch_prac  |  394.6353    37.1673      0.9928     13.5
nodeicov_seniority|18243.2600  1654.4490      0.9899     18.5
gwesp_0.5       |  508.5762    89.9782      0.9925     13.5
------------------------------------------------------------

Geweke diagnostic (first 10% vs. last 50% of the retained sample):
---------------------------------------
Statistic       |         z   p-value
----------------+----------------------
edges           |     2.258    0.0239  *
mutual          |     2.901    0.0037  *
nodematch_prac  |     1.641    0.1007
nodeicov_seniority|     2.204    0.0275  *
gwesp_0.5       |     2.236    0.0253  *
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
  Here it is 13 to 21 for every statistic: the estimates rest on very little information, although the
  sample looks large.
- **Geweke** compares the start and the end of the chain. A star marks a statistic whose chain is
  not stable; here four of five are flagged.

## Fixing it: a longer interval and burn-in

The usual cure is to let the sampler run longer between the draws that are kept (`mcmcinterval()`) and
before the first draw (`mcmcburnin()`). `mcmcsamplesize()` sets the number of draws and
`mcmleiterations()` the maximum number of MCMLE iterations.

```stata
. nwergm lazega_fr, edges mutual nodematch(prac) nodeicov(seniority) gwesp(0.5) seed(1) mcmcinterval(1000) mcmcburnin(200
> 00)
...
------------------------------------------------------------------------------------
         lazega_fr | Coefficient  Std. err.      z    P>|z|     [95% conf. interval]
-------------------+----------------------------------------------------------------
             edges |   -3.31567   .1327801   -24.97   0.000    -3.575914   -3.055426
            mutual |   .8062929   .1602816     5.03   0.000     .4921466    1.120439
    nodematch_prac |   .7002809   .0800612     8.75   0.000     .5433639    .8571979
nodeicov_seniority |  -.0045754   .0018168    -2.52   0.012    -.0081363   -.0010145
         gwesp_0.5 |   .4925098   .0634213     7.77   0.000     .3682063    .6168133
------------------------------------------------------------------------------------

MCMLE converged after 1 iteration(s).
...
Log-likelihood: -1667.9836 (df = 5)   AIC:    3346.0   BIC:    3378.5   (MC std. err. =   .2491)
```

```stata
. estat mcmcdiag

MCMC diagnostics for the final simulation (nwergm, method(mcmle))
Sample size:         =    3000
Burn-in:             =   20000
Thinning interval:   =    1000
Acceptance rate:     =  0.6688

------------------------------------------------------------
Statistic       |      Mean         SD    Autocorr      ESS
----------------+-------------------------------------------
edges           |  571.0987    42.1567      0.8337    272.8
mutual          |   73.0120    10.8698      0.7540    260.8
nodematch_prac  |  407.2043    32.2887      0.8356    214.0
nodeicov_seniority|19286.0800  1533.9190      0.7990    335.8
gwesp_0.5       |  548.0583    78.1940      0.8277    257.2
------------------------------------------------------------

Geweke diagnostic (first 10% vs. last 50% of the retained sample):
---------------------------------------
Statistic       |         z   p-value
----------------+----------------------
edges           |     0.342    0.7326
mutual          |     0.914    0.3610
nodematch_prac  |     0.579    0.5628
nodeicov_seniority|    -0.237    0.8130
gwesp_0.5       |     0.475    0.6351
---------------------------------------
...
```

The coefficients barely moved (for example `gwesp_0.5` 0.511 and 0.493, `mutual` 0.803 and 0.806), but
the autocorrelation fell from 0.99 to 0.75-0.84, the ESS rose to 214-336 and no Geweke statistic is
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
edges                  575       487    563.22       646        0.84
mutual                  74        51     69.82        99        0.72
nodematch_prac         412       344    402.88       458        0.88
nodeicov_senio~y     19379     15800  18993.70     21852        0.84
gwesp_0.5        555.61913 376.95167    534.54 690.21781        0.84

Goodness-of-fit for minimum geodesic distance

                       obs       min      mean       max  MC p-value
1                      575       487    563.22       646        0.84
2                     2316      2039   2451.46      2820        0.64
3                     1782      1432   1758.32      2018        0.76
4                      154        28    157.94       389        0.80
5                        3         0      6.70        49        0.84
6                        0         0      0.22         4        1.00
Inf                    140         0     32.14       209        0.08
...
```

(The out-degree, in-degree and shared-partner tables follow in the log.) The model statistics are all
reproduced (p between 0.72 and 0.88), and so are the geodesic distances 1 to 6; the pairs at
infinite distance (not connected) are less well reproduced (observed 140, simulated 32 on average, p = 0.08, see the log). Over the whole output only a
handful of rows are flagged: out-degree 0 (two lawyers send no nominations; the model simulates 0.28 on
average, p = 0.00), out-degree 22 and edgewise shared partners 6 (p = 0.04). With about 70 rows, a few
small p-values are expected by chance; look for patterns, not single rows. A systematic gap, for
example too few high-degree nodes, would suggest adding a degree term (see [ERGM 2](../tutorial-2-terms/)).

## A model that cannot be fitted

Triangle counts are a classic trap. `triangle` is the plain number of triangles; a model with it can
fall into a degenerate region where the simulated networks are almost empty or almost complete.

```stata
. capture noisily nwergm kapferer_t2, edges triangle seed(1) mcmcsamplesize(1000)
Warning: MCMLE iter 3 - statistic(s) at column(s) 1 2 not varying this iteration - this may indicate an extreme point or 
> dead-end configuration.
Unconstrained MCMC sampling did not mix at all. Optimization cannot continue.
             ErgmMCMLE():   498  Stata returned error
                 <istmt>:     -  function returned error
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
       edges |  -4.687943   .3238733   -14.47   0.000    -5.322723   -4.053163
   gwesp_0.5 |   1.731426   .2009058     8.62   0.000     1.337658    2.125195
------------------------------------------------------------------------------

MCMLE converged after 2 iteration(s).
...
Log-likelihood:  -430.2126 (df = 2)   AIC:     864.4   BIC:     874.0   (MC std. err. =  .13589)
```

```stata
. estat gof, nsim(50) seed(2)

Goodness-of-fit for model statistics

                       obs       min      mean       max  MC p-value
edges                  190       125    169.88       218        0.36
gwesp_0.5        275.77262 165.84383    245.55 330.45462        0.40

Goodness-of-fit for minimum geodesic distance

                       obs       min      mean       max  MC p-value
1                      190       125    169.88       218        0.36
2                      535       325    467.50       578        0.28
3                      163        60    144.84       241        0.68
4                       15         0      9.60        52        0.44
5                        0         0      0.16         4        1.00
Inf                      0         0    111.02       308        0.20

Goodness-of-fit for degree

                       obs       min      mean       max  MC p-value
...
```

The fit converges and the closure effect is strongly positive (1.73). The goodness of fit shows one point
worth a note: the observed network has no pair at infinite distance, while the model simulates about 111
unconnected pairs on average (range 0 to 308, p = 0.20). The model gets density and clustering right but
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
