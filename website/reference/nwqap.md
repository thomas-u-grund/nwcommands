---
title: "nwqap"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "Multivariate QAP regression"
---

# `nwqap`

Multivariate QAP regression

## Syntax

```stata
nwqap 
depnet
[indepvars]
[,
perm:utations(#)
mode(mode)
type(regcmd)
typeoptions(regoptions)
detail
save(filename)
predict(newnetname)
plot
name(string)
qapspp
force]
```

| | |
|---|---|
| `perm:utations(#)` | number of QAP permutations; default = 500 |
| `mode`(*[mode](nwexpand)*) | modes for expanding variables to networks |
| `type`(*[regcmd](nwqap)*) | regression command to be used for dyad dataset; default = *logit* |
| `typeoptions(regoptions)` | options to be passed on to the regression command |
| `detail` | display details of regression results and the permutation progress lines |
| `save`(*`filename`*) | save coefficients from permutations in file |
| `predict(newnetname)` | store the fitted dyad-level values (from **type()**'s own default prediction, e.g. Pr(y=1) for **logit**/**probit**, the fitted mean for **regress**) as a new valued network |
| `plot` | Draw one histogram panel per coefficient (including the constant), each with a dashed reference line at the observed coefficient against its own `permutations()` null draws - the same comparison R's **sna::plot.qaptest()** draws, generalized to every coefficient in the regression |
| `name(string)` | Name for the combined graph created by `plot`; default = **qap** |
| `qapspp` | Use double semi-partialling (Dekker, Krackhardt & Snijders 2007) instead of the plain permutation p-value for every independent variable's own coefficient - see [qapspp](nwqap) below |
| `force` | Run the command although its matrices would not fit in memory (it stops with r(484) above 10,000 nodes otherwise) |

## Description

MR-QAP is a multiple regression procedure used to assess the impact of independent variables upon a dependent variable. In standard regression techniques, the typical "unit of analysis" is an individual observation. In MR-QAP analysis, the unit of analysis is a dyad, a pair of individuals who may or may not have some sort of relation connecting them to one another.

`nwqap` reshapes a network to a dataset of edges/arcs. For example, a directed network with 10 nodes is transformed in a dataset with 90 dyads (selfloops are not permitted).

The dependent variable is *y_ij*, indicating the network relationship between nodes *i* and *j*.  Independent variables can be other [networks](netname) or normal `variables`. Normal variables are expanded to networks of the same size as the dependent network using [nwexpand](nwexpand). The default **mode** is **"same"** (see [here](nwexpand) for other modes. When more than one `varname` is specified as independent variable, different modes can be selected for each variable, e.g. **mode(same dist invdist)** chooses mode **"dist"** for the second `varname` that appears as independent variable.

`nwqap` performs the regression specified in **type()**, by default `logit` regression is choosen. But notice that any other type of regression can be used (e.g. `probit`, `xtmixed`). Furthermore, options are passed on to the selected regression command with **typeoptions()**. This gives a lot of flexibility to perform dyad-level regression. For example instead of logistic regression one can use probit regression with option *asis*:

- **nwqap glasgow2 glasgow1, type(probit) typeoptions(asis)**

The raw output of this dyad-level regression is displayed with option **detail**.

`predict(newnetname)` stores **type()**'s own fitted dyad-level values - whatever statistic that regression command's own default `predict` reports (predicted probability for **logit**/**probit**/**cloglog**, the fitted linear mean for **regress**, etc.) - as a new valued network, e.g. for comparing predicted tie probabilities against the observed network as a goodness-of-fit check. Captured from the one real (non-permuted), observed-data regression this command already runs internally to obtain **type()**'s own coefficients - not from any of the `permutations(int)` null-model draws. The diagonal (excluded from estimation, like every self-tie in this command's dyadic reshaping) is set to 0 in the resulting network. A name collision with an existing network is handled the same non-destructive way every other network-creating command in this package handles it (auto-renamed with a warning, unless *newnetname* is free).

Once a dataset is assembled and a regression is carried out, the resulting coefficients indicate the direction of the effect of independent variables upon the dependent variable. However, calculating the standard error of these coefficients has been shown to lead to biased results when autocorrelation exists - which occurs, for instance, when interpersonal relations determine individual behavior (Krackhardt 1988).

Since this method is employed to test hypotheses that suggest interpersonal relations matter, a different significance test is needed. The second step of QAP regression, therefore, is to repeatedly permute rows and columns of the matrix representing the dependent variable and after each permutation to re-compute regression coefficients. Indicators of statistical significance report the proportion of results from randomly altered matrices with regression coefficients as high as those from the unaltered dependent variable matrix (Krackhardt 1987).

In this second step, `nwqap` randomly permutes rows and columns (together) of the dependent matrix (dependent network) and recomputes the regression, storing all coefficients. By default this step is repeated 500 times. The number of permutations can be changed with the option **permutations**. The coefficients of all these permutations are saved with `save(filename)`. Based one the distribution of coefficients, `nwqap` calculates adjusted p-values and saves them in *e(pvalues)*.

`plot` draws this same permutation distribution visually: one histogram panel per coefficient (the constant included), each with a dashed vertical line at that coefficient's real, unpermuted value against a histogram of its own `permutations()` null draws - the standard visual check for a QAP test (is the real coefficient out in the tail of what pure permutation produces, or comfortably inside it?), the same comparison R's **sna** package's **plot.qaptest()** draws for a single coefficient, generalized here to every coefficient in the regression at once. Grayscale by design, matching every other plot this package produces.

*References*

Grund, T. and Densley, J. (2012). "Ethnic Heterogeneity in the Activity and Structure of a Black Street Gang." European Journal of Criminology, Vol. 9, Issue 3, pp. 388-406.

Krackhardt, David. (1987). "QAP Partialling as a Test of Spuriousness." Social Networks 9: 171-186.

Krackhardt, David. (1988). "Predicting with Networks: Nonparametric Multiple Regression Analysis of Dyadic Data." Social Networks 10: 359-381.

## qapspp - double semi-partialling

Plain MR-QAP's own standard permutation test (the default, no `qapspp`) permutes the WHOLE dependent network at once and refits the FULL model on every permuted draw - a valid test that a variable has SOME association with the outcome, but not a valid test that it has an association *net of the other independent variables*, since permuting the whole network scrambles every variable's own relationship to it simultaneously, not just the one being tested. This is exactly the "QAP partialling" problem Krackhardt (1987) originally identified.

`qapspp` instead follows the double semi-partialling (DSP) of Dekker, Krackhardt & Snijders (2007, "Sensitivity of MRQAP Tests to Collinearity and Autocorrelation Conditions", *Psychometrika* 72(4)). For each independent variable *x_k* in turn, *x_k* is regressed by OLS on all the other independent variables, and the rows and columns of the matrix of these residuals are permuted together, so that the permuted *x_k* stays unrelated to the other variables. `nwqap` also residualizes the dependent network on the other independent variables; each permutation draw is the OLS slope of the residualized dependent network on the permuted residuals of *x_k*, and the observed statistic is the same slope on the unpermuted residuals. By the Frisch-Waugh-Lovell theorem the observed statistic equals *x_k*'s coefficient in an OLS regression on all the independent variables, so residualizing the dependent network does not change it. Dekker et al. do not residualize the dependent network: they regress it on the permuted residuals together with the other variables. For a permuted draw the two slopes share the same numerator and differ only in the denominator (the permuted residuals are not exactly uncorrelated with the other variables), so the draws are nearly the same, those of `nwqap` being if anything slightly smaller in absolute value. The statistic is the partial OLS coefficient, not its t-statistic; Dekker et al. found that all MRQAP methods perform better with a pivotal statistic such as t. The p-value is much less sensitive to collinearity among the independent networks than the plain permutation test. It is computed for every independent-variable coefficient (the constant's own p-value is left as the plain single-permutation result, since double semi-partialling is not defined for an intercept). Semi-partialling is always an OLS fit, regardless of which `type()` the main model used, so for a logit or probit model the tested statistic is not the printed coefficient, which is on another scale; the printed coefficients are those of the model.

## Network types

**Directed:** (i,j) and (j,i) both enter, also when undirected. **Valued:** with `type(logit)` (default), `probit`, `cloglog`, `scobit` a nonzero value of the dependent network is a tie (a note says so); `type(regress)` uses the values; independent networks enter with values. **Two-mode:** not supported (error 6088; use [nwproject](nwproject) first). **Signed:** not checked. See [nwnetworktypes](nwnetworktypes).

## Limits

The regression runs on one observation for every dyad, in Stata memory. Measured in Stata/BE, random directed network with 10 ties per node, `type(regress)`, five permutations: 5,000 nodes 10 seconds and 3 GB, 10,000 nodes 40 seconds and 11.6 GB. Memory is about 120 bytes per dyad, so networks above 10,000 nodes need more than 12 GB.

QAP regresses the dyads of the networks, one observation per pair of nodes, and holds about 15 matrices of *n*-by-*n* (10,000 nodes with 5 permutations: 39 seconds and 11.6 GB). Above 10,000 nodes the command stops at once with r(484) and a message with the memory needed (48 GB at 20,000 nodes); option `force` runs it anyway.

## Examples

```stata
. nwwebuse glasgow
. nwqap glasgow2 glasgow1 smoke1 sport1
. nwqap glasgow2 glasgow1 smoke1 sport1, predict(glasgow2_fitted)

        Multiple Regression Quadratic Assignment Procedure

          Estimation    =  QAP
          Regression    =  logit
          Permutations  =  500
          Number of vertices=  50
          Number of arcs=  116

-----------------------+-------------------------
              glasgow2 |      Coef.    P-value
-----------------------+-------------------------
              glasgow1 |   3.652579        0
           same_smoke1 |    .514058     .018
           same_sport1 |    .217359     .394
                 _cons |  -4.125208
-----------------------+-------------------------
```
This example shows that two individuals are more likely to be friends at time2 (glasgow2) when they already were friends at time1 (glasgow1). Furthermore two individuals *i* and *j* are more likely to be friends at time2 when they both scored the same on smoking at time1 (smoke1). There is no effect for both having scored the same on sport1.

## Stored results

`nwqap` is an **eclass** command: results are posted with `ereturn`, so `estimates store`, `estimates table`, and other standard postestimation commands that only need *e(b)*/*e(V)* (e.g. `test`, `lincom`) work as usual. *e(V)* is a diagonal matrix built from each coefficient's own QAP-permutation variance, not a classical OLS/logit covariance matrix - dyadic network data violates the independent- observations assumption those classical formulas require, which is the entire reason QAP permutation testing exists in the first place. The data set holds one row per node, not per dyad, so fitted values cannot be stored in a variable: after `nwqap`, `predict` *newnetname* stores the dyad-level fitted values of the last model as a new valued network (the same as `predict(newnetname)` at estimation time; the values are kept in memory until the next `nwqap`, and `predict` takes no variable name, `if`, `in` or options).

- **Scalars**
- **e(N)** --- number of dyad-level observations
- **e(permutations)** --- number of QAP permutations

- **Macros**
- **e(cmd)** --- **nwqap**
- **e(title)** --- title of estimation
- **e(depvar)** --- name of dependent network
- **e(qap_regcmd)** --- regression command used (**type()**)
- **e(predict)** --- **nwqap_p**, program used by `predict` (only when **type()** has a default prediction)
- **e(fit_directed)** --- **true** or **false**, direction of the network `predict` creates (as **e(predict)**)
- **e(fit_labs)** --- node labels of the network `predict` creates (as **e(predict)**)

- **Matrices**
- **e(b)** --- coefficient vector
- **e(V)** --- diagonal matrix of QAP-permutation coefficient variances
- **e(pvalues)** --- matrix with QAP p-values, in the same column order as **e(b)**

## See also

- `nwergm`, [nwpermute](nwpermute)

---

*nwcommands version 3.24.0, 13 November 2026* ([check your installed version](nwversion))
