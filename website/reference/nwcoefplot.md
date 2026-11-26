---
title: "nwcoefplot"
parent: "Core command reference"
grand_parent: "Packages and reference"
nav_exclude: true
search_exclude: false
description: "Coefficient plot of network model results"
---

# `nwcoefplot`

Coefficient plot of network model results

## Syntax

```stata
nwcoefplot [namelist] [, options]
namelist holds names of results saved with estimates store; a period (.) stands for the active estimation results, which is also what is plotted without a list. Up to eight models are drawn side by side.
```

| | |
|---|---|
| `l:evel(#)` | confidence level; default is `c(level)`, normally 95 |
| `keep(patterns)` | plot only the coefficients that match; the patterns also set their order |
| `drop(patterns)` | leave out the coefficients that match |
| `nocons:tant` | leave out `_cons` |
| `ef:orm` | exponentiate: odds ratios or rate ratios; the reference line is 1 on a log scale |
| `byeq` | one panel for each equation (the default when there is more than one equation) |
| `mixeq` | all equations on one axis, labelled *eq*`:`*name* |
| `common` | with several models: only the coefficients that all models have |
| `skip:missing` | leave out models without `e(b)` and `e(V)` instead of stopping |
| `msy:mbol(symbols)` | marker symbol for each model, in the order of the models (for example `msymbol(O D T)`); symbols are used again from the start when there are fewer than models; default is a circle for all |
| `ti:tle(string)` | title of the graph |
| `name(name[, replace])` | name of the graph in memory; default `coefplot`; an existing graph is replaced |
| `sav:ing(filename[, replace])` | save the graph to a `.gph` file; an existing file is replaced |
| `exp:ort(filename[, options])` | write the graph with `graph export`; an existing file is replaced |
| *twoway_options* | other options of `twoway`, applied to each panel; they come last, so `xscale()` and `xlabel()` replace the default axis; the size options `xsize()`, `ysize()`, `aspectratio()` and `scale()` replace the default size (with `byeq` or `mixeq` across several panels they apply to the combined graph) |

## Description

`nwcoefplot` draws point estimates with confidence intervals of the coefficients in `e(b)` and `e(V)` of the last estimation or of stored results. It works after `nwsaom`, `nwergm`, `nwdynam`, `nwrem`, `nwalaam`, `nwlsm` and after any other command that leaves `e(b)` and `e(V)`. The coefficients are labelled with their names. The intervals are *b* +/- *z* se, with a *t* quantile when the command stores `e(df_r)`. For `nwlsm` the coefficients are posterior means with posterior standard deviations, so the intervals are normal approximations; the credible intervals of the fit are in the output of `nwlsm`. Coefficients that were omitted or have no variance are not drawn.

Equations are never mixed on one axis unless `mixeq` is given: a model with several equations (for example the network and outcome equations of `nwlsm` with `influence()`) gets one panel for each, with its own scale. The axis of a panel always contains all intervals and the reference line (0, or 1 with `eform`), with a margin; with `eform` the axis is logarithmic and labelled at 1, 2, 5 times powers of ten.

`eform` gives odds ratios after `nwergm`, `nwalaam` and `nwlsm` with the Bernoulli or binomial family, and rate ratios after `nwdynam` and `nwrem` (and after `nwlsm` with the Poisson family). It is refused for `nwsaom` and `nwsbm`, whose parameters are not log odds or log rates; in the outcome equation of `nwlsm` the coefficients stay on their own scale. For other commands the axis reads "Exponentiated coefficient".

`keep()` and `drop()` take coefficient names or patterns with `*` and `?`. A pattern is compared with the name (`edges`, `gwesp*`) and with *eq*`:`*name* (`network:*`). The order of the `keep()` patterns is the order of the coefficients from top to bottom.

With a list of models the coefficients of different models are drawn in one row in different colours, with a legend; `nwcompare, graph` calls this for the fit table. For a black-and-white print give each model its own marker with `msymbol()`, for example `msymbol(O D T)` for three models (circle, diamond, triangle; hollow forms are `Oh Dh Th Sh`); at most one symbol per model is allowed, and a symbol that is not a Stata marker symbol name stops the command with r(198).

## Examples

- `. nwergm flomarriage, edges gwesp(.5)`
- `. nwcoefplot, eform title("ERGM of the marriage network")`

- `. nwergm flomarriage, edges triangle`
- `. estimates store m0`
- `. nwergm flomarriage, edges gwesp(.5)`
- `. estimates store m1`
- `. nwcoefplot m0 m1, keep(edges) export(coefs.png, width(1200))`

- `. nwcoefplot m0 m1, msymbol(O D) export(coefs_gray.png, width(1200))`

- `. nwlsm advice, dim(2) influence(belief2 belief1 tenure) neighbors(10)`
- `. nwcoefplot, noconstant`

## Stored results

`nwcoefplot` stores in `r()`:

- **`r(level)`** --- confidence level
- **`r(n_coef)`** --- number of plotted estimates (coefficients times models)
- **`r(n_panels)`** --- number of panels
- **`r(n_models)`** --- number of models
- **`r(models)`** --- names of the models

## Also see

[nwcompare](nwcompare), `nwergm`, `nwsaom`, `nwdynam`, `nwrem`, `nwalaam`, `nwlsm`, `estimates`

---

*nwcommands version 3.37.2, 26 November 2026* ([check your installed version](nwversion))
