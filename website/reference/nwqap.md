---
title: "nwqap"
parent: "Command reference"
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
, 
permutations(int)
mode(mode)
type(regcmd)
typeoptions(regoptions)
detail
save(filename)
predict(newnetname)
plot
name(string)
```

| | |
|---|---|
| `permutations(int)` | number of QAP permutations; default = 500 |
| `mode`(*[mode](nwexpand)*) | modes for expanding variables to networks |
| `type`(*[regcmd](nwqap)*) | regression command to be used for dyad dataset; default = *logit* |
| `typeoptions(regoptions)` | options to be passed on to the regression command |
| `detail` | display details of regression results |
| `save`(*`filename`*) | save coefficients from permutations in file |
| `predict(newnetname)` | store the fitted dyad-level values (from **type()**'s own default prediction, e.g. Pr(y=1) for **logit**/**probit**, the fitted mean for **regress**) as a new valued network |
| `plot` | Draw one histogram panel per coefficient (including the constant), each with a dashed reference line at the observed coefficient against its own `permutations()` null draws - the same comparison R's **sna::plot.qaptest()** draws, generalized to every coefficient in the regression |
| `name(string)` | Name for the combined graph created by `plot`; default = **qap** |
| `qapspp` | Use double semi-partialling (Dekker, Krackhardt & Snijders 2007) instead of the plain permutation p-value for every independent variable's own coefficient - see [qapspp](nwqap) below |

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

## Examples

```stata
. nwwebuse glasgow
. nwqap glasgow2 glasgow1 smoke1 sport1
. nwqap glasgow2 glasgow1 smoke1 sport1, predict(glasgow2_fitted)
```
- Multiple Regression Quadratic Assignment Procedure

- Estimation= QAP
- Regression= logit
- Permutations= 500
- Number of vertices= 50
- Number of arcs= 116

- hline 23c TThline 25
- glasgow2c |Coef.P-value
- hline 23c +hline 25
- glasgow1c |3.6525790
- same_smoke1c |.514058.018
- same_sport1c |.217359.394
- _consc |-4.125208
- hline 23c BThline 25

This example shows that two individuals are more likely to be friends at time2 (glasgow2) when they already were friends at time1 (glasgow1). Furthermore two individuals *i* and *j* are more likely to be friends at time2 when they both scored the same on smoking at time1 (smoke1). There is no effect for both having scored the same on sport1.

## Supported network types

Binary: yes. Directed: yes, and undirected networks are not collapsed to unique dyads - both *(i,j)* and *(j,i)* appear as separate observations in the dyad-level dataset (for an undirected network they carry the same value, so this does not bias point estimates, but it does mean the reported "Number of obs" and any raw regression standard errors reflect double-counted dyads; QAP's own permutation-based p-values, not these raw standard errors, are what `nwqap` actually reports). Weighted: **W3**, explicit binary-only for the dependent network under the default (and any other binary-outcome) `type()` - `logit`, `probit`, `cloglog`, and `scobit` all treat any nonzero value as a positive outcome (this is those commands' own documented behavior, not something `nwqap` does intentionally) - so a valued/weighted dependent network's tie strength is silently discarded by the chosen regression command unless a continuous-outcome `type()` (e.g. `type(regress)`) is used instead; `nwqap` now warns explicitly when this combination is detected, rather than leaving it silent. Independent networks and variables are not affected - their values enter the regression directly, weighted or not. Signed: not checked. Two-mode: not checked. A full weighted-QAP alternative (rather than a warning) remains on the roadmap as a larger follow-on.

## Stored results

`nwqap` is an **eclass** command: results are posted with `ereturn`, so `estimates store`, `estimates table`, and other standard postestimation commands that only need *e(b)*/*e(V)* (e.g. `test`, `lincom`) work as usual. *e(V)* is a diagonal matrix built from each coefficient's own QAP-permutation variance, not a classical OLS/logit covariance matrix - dyadic network data violates the independent- observations assumption those classical formulas require, which is the entire reason QAP permutation testing exists in the first place. A native postestimation `predict` does not work after `nwqap` returns (see [Description](nwqap) above for why - the dyad-level dataset **type()** actually fits is a transient internal detail, not the current dataset once `nwqap` exits); use `predict(newnetname)` instead to capture fitted dyad-level values directly, at the one point internally where they are genuinely meaningful.

**Scalars**

- **e(N)** number of dyad-level observations
- **e(permutations)** number of QAP permutations

**Macros**

- **e(cmd)** **nwqap**
- **e(title)** title of estimation
- **e(depvar)** name of dependent network
- **e(qap_regcmd)** regression command used (**type()**)

**Matrices**

- **e(b)** coefficient vector
- **e(V)** diagonal matrix of QAP-permutation coefficient variances
- **e(pvalues)** matrix with QAP p-values, in the same column order as **e(b)**

## See also

- [nwergm](nwergm), [nwpermute](nwpermute)
