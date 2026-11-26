---
title: "nwcompare"
parent: "Core command reference"
grand_parent: "Packages and reference"
nav_exclude: true
search_exclude: false
description: "Compare the fit statistics of stored network models"
---

# `nwcompare`

Compare the fit statistics of stored network models

## Syntax

```stata
nwcompare [namelist] [, sort(criterion) graph name(name) saving(filename) export(filename[, options]) coefopts(options)]
namelist holds names of results saved with estimates store; a period (.) stands for the active estimation results. Without a list, all stored results are shown.
```

| | |
|---|---|
| `sort(criterion)` | order the rows by `aic`, `bic`, `icl` (smallest first) or `ll` (largest first); default: the order of the list |
| `graph` | also draw the coefficients of the models side by side with [nwcoefplot](nwcoefplot); `plot` is a synonym |
| `name(name)` | name of the graph in memory; default `compare` |
| `sav:ing(filename)` | save the graph to a `.gph` file |
| `exp:ort(filename[, options])` | write the graph with `graph export` |
| `coefopts(options)` | options passed to [nwcoefplot](nwcoefplot), for example `keep()` or `eform` |

## Description

`nwcompare` lists, one row per model, the number of observations *N*, the log likelihood, the number of parameters *k*, and the criteria AIC, BIC and ICL, as stored by `nwergm`, `nwsaom`, `nwlsm`, `nwsbm`, `nwalaam` and by Stata's own estimation commands. A statistic that a model does not provide is shown as a period.

What is shown for each command:

- `nwergm`: `e(ll)`, `e(aic)`, `e(bic)` as stored; *k* is `e(df_m)`, the number of coefficients.
- `nwergm`, dyad dependence: the log likelihood is estimated by bridge sampling or is a pseudolikelihood; a note under the table says which.
- `nwlsm`: the posterior mean of the log likelihood, `e(ll_mean)`; no AIC or BIC, because the fit is Bayesian; *k* is the number of coefficients in `e(b)` (the latent positions are not counted).
- `nwsbm`: the expected complete-data log likelihood `e(PL)` and the integrated classification likelihood `e(ICL)`; *N* is the number of actors; AIC and BIC are not shown.
- `nwsbm`, *k*: `e(npar)` (block parameters, covariate coefficients, a Gaussian variance) plus the free membership proportions, *Q* - 1 for *Q* blocks (*Q1* - 1 plus *Q2* - 1 for two modes), as in the ICL penalty.
- `nwdynam`, `nwrem`: `e(ll)`; *k* is `e(df_m)` when the command stores it (`nwrem`), otherwise the number of coefficients in `e(b)`; AIC and BIC as stored, or computed from the log likelihood.
- `nwsaom`, `nwalaam`: these estimators (method of moments, Monte Carlo) do not store a likelihood, so only *N* and *k*, the number of coefficients in `e(b)`, appear.
- Other estimation commands: `e(ll)`, `e(aic)`, `e(bic)`; *k* is `e(rank)`, else `e(df_m)`, else the number of coefficients; AIC and BIC are computed from the log likelihood when not stored.

## Remarks

Criteria from different model families are not always comparable. An ERGM is a likelihood for the *N* dyads, a latent space model with a posterior mean log likelihood is not a maximised likelihood, and the block model's PL and ICL refer to the actors and include the memberships. Compare AIC and BIC between models of the same family fitted to the same network (for example several `nwergm` specifications, or several numbers of blocks), and treat a comparison across families as a rough guide at most. `nwcompare` prints a note when the rows differ in *N* or in the network.

`nwsbm` stores no coefficient vector, so `estimates store` cannot keep its results: list them with the period, as the active results. Restoring another model afterwards replaces them, so fit the block model last, or call `nwcompare` again after fitting it.

With `graph`, `nwcompare` adds a graph of the coefficients (point estimates with confidence intervals, one colour for each model) of the models that have a coefficient vector, restricted to the coefficients that all of them share by name; the sample models in the example below share `edges`. Models of different kinds that share no coefficient give a note instead of a graph.

## Examples

- `. nwergm flomarriage, edges`
- `. estimates store m0`
- `. nwergm flomarriage, edges gwesp(.5)`
- `. estimates store m1`
- `. nwcompare m0 m1, sort(bic)`

- `. nwcompare m0 m1, graph coefopts(eform)`
- `. nwcompare m0 m1, graph export(compare.png, width(1200))`

- `. nwsbm flomarriage, maxblocks(4) seed(1)`
- `. nwcompare m0 m1 .`

## Stored results

`nwcompare` stores in `r()`:

- **`r(table)`** --- matrix with one row per model and the columns `N`, `ll`, `k`, `aic`, `bic`, `icl`
- **`r(names)`** --- names of the models
- **`r(commands)`** --- estimation commands of the models

## Also see

[nwcoefplot](nwcoefplot), `nwergm`, `nwsaom`, `nwlsm`, `nwsbm`, `nwalaam`, `estimates`

---

*nwcommands version 3.38.0, 26 November 2026* ([check your installed version](nwversion))
