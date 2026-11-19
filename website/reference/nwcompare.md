---
title: "nwcompare"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Compare the fit statistics of stored network models"
---

# `nwcompare`

Compare the fit statistics of stored network models

## Syntax

```stata
nwcompare [namelist] [, sort(criterion)]
namelist holds names of results saved with estimates store; a period (.) stands for the active estimation results. Without a list, all stored results are shown.
```

| | |
|---|---|
| `sort(criterion)` | order the rows by `aic`, `bic`, `icl` (smallest first) or `ll` (largest first); default: the order of the list |

## Description

`nwcompare` lists, one row per model, the number of observations *N*, the log likelihood, the number of parameters *k*, and the criteria AIC, BIC and ICL, as stored by `nwergm`, `nwsaom`, `nwlsm`, `nwsbm`, `nwalaam` and by Stata's own estimation commands. A statistic that a model does not provide is shown as a period.

What is shown for each command:

- `nwergm`: `e(ll)`, `e(aic)`, `e(bic)` as stored (for a model with dyad dependence the log likelihood is estimated by bridge sampling or is a pseudolikelihood; a note says which); *k* is `e(df_m)`.
- `nwlsm`: the posterior mean of the log likelihood, `e(ll_mean)`; there is no AIC or BIC, because the fit is Bayesian.
- `nwsbm`: the expected complete-data log likelihood `e(PL)`, the number of parameters `e(npar)` and the integrated classification likelihood `e(ICL)`; *N* is the number of actors.
- `nwsaom`, `nwalaam`: these estimators (method of moments, Monte Carlo) do not store a likelihood, so only *N* and *k* appear.
- Other estimation commands: `e(ll)`, `e(aic)`, `e(bic)`; AIC and BIC are computed from the log likelihood when the command did not store them.

## Remarks

Criteria from different model families are not always comparable. An ERGM is a likelihood for the *N* dyads, a latent space model with a posterior mean log likelihood is not a maximised likelihood, and the block model's PL and ICL refer to the actors and include the memberships. Compare AIC and BIC between models of the same family fitted to the same network (for example several `nwergm` specifications, or several numbers of blocks), and treat a comparison across families as a rough guide at most. `nwcompare` prints a note when the rows differ in *N* or in the network.

`nwsbm` stores no coefficient vector, so `estimates store` cannot keep its results: list them with the period, as the active results. Restoring another model afterwards replaces them, so fit the block model last, or call `nwcompare` again after fitting it.

## Examples

- `. nwergm flomarriage, edges`
- `. estimates store m0`
- `. nwergm flomarriage, edges gwesp(.5)`
- `. estimates store m1`
- `. nwcompare m0 m1, sort(bic)`

- `. nwsbm flomarriage, maxblocks(4) seed(1)`
- `. nwcompare m0 m1 .`

## Stored results

`nwcompare` stores in `r()`:

- **`r(table)`** --- matrix with one row per model and the columns `N`, `ll`, `k`, `aic`, `bic`, `icl`
- **`r(names)`** --- names of the models
- **`r(commands)`** --- estimation commands of the models

## Also see

`nwergm`, `nwsaom`, `nwlsm`, `nwsbm`, `nwalaam`, `estimates`

---

*nwcommands version 3.27.0, 18 November 2026* ([check your installed version](nwversion))
