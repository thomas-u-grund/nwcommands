---
title: "nwergm and R's ergm"
parent: "nwergm (ERGM)"
nav_order: 7
permalink: /nwergm/rergm/
description: "What nwergm shares with R's ergm, what it lacks, how it was compared, and a translation table from ergm functions to nwergm commands."
---

# nwergm and R's ergm

`nwergm` follows the statnet project closely and exists because of it. The ERGM framework and R's `ergm` are
due to Mark Handcock, David Hunter, Carter Butts, Steven Goodreau, Pavel Krivitsky, Martina Morris and many
contributors, and `nwergm` re-implements their terms, estimators and diagnostics in Stata. `nwergm` is not
affiliated with or endorsed by the statnet project, and errors in `nwergm` are the author's. If you can use R,
`ergm` remains the reference and the more complete program.

The software was developed with Claude Code (Anthropic), an AI coding assistant, working under the author's
direction; its correctness rests on numerical comparison with R's `ergm`.

## What is the same

- **The model.** The terms are those of `ergm`, with the same definitions and the same coefficient names
  (with `.` written as `_`). Version 1.1.0 implements 125 of the 139 terms of `ergm` 4.12.0
  (89.9%), and 125 of the 126 that apply to binary networks; version 1.0.1 has about 110.
- **The estimators.** Maximum pseudolikelihood and Monte Carlo maximum likelihood with the same
  defaults as R (the TNT proposal, bridge-sampling log-likelihood), plus the variants of the pseudolikelihood,
  contrastive divergence and the stochastic approximation.
- **Missing data.** Missing dyads are left out of the likelihood and handled by the method of Handcock and Gile,
  as in R; missing covariate values are refused, as in R.
- **Fit statistics, constraints, simulation and checks.** Log-likelihood, deviance, AIC and BIC as `logLik()`;
  `constraints=` and `obs.constraints=`; simulation from a fit; goodness of fit and MCMC diagnostics.

## How it was compared

For each term, the observed statistic of test networks was compared with the one that `ergm` computes, and the
maximum pseudolikelihood estimates and the Monte Carlo maximum likelihood estimates were compared with
`ergm` 4.12.0 on the statnet example networks and on simulated networks. Because the Monte Carlo
estimates are random, results agree within simulation noise, not to the last digit; `nwergm version` prints the
version of `ergm` that was used.

## What differs, and what is missing

Not in `nwergm`:

- the 13 terms for **valued** networks (`atleast`, `atmost`, `cdf`, `cyclicalweights`, `equalto`,
  `greaterthan`, `ininterval`, `nodecovar`, `nodeicovar`, `nodeocovar`, `smallerthan`, `sum`, `transitiveweights`)
  and the operator `B`. `nwergm` models binary ties; the values of a valued network are not used as an outcome;
- `Curve()` (and `Parametrise()`) beyond **linear maps** of the coefficients: `map(rep)` and
  `map(matrix(name))` work, `minpar()`, `maxpar()` and `cov()` do not;
- `altkstar` with an estimated decay by Monte Carlo maximum likelihood: it is available for
  `method(mple)` with starting values from `init()`. R cannot fit it by Monte Carlo maximum likelihood either;
- in the operators, the two-sided form of `attrs` in `S()`, dyadic covariates inside `S()` and `Project()`, and curved terms inside
  an operator; the constraints `hamming`, `ChangeStats()`, `Dyads()` and `I()`;
- the packages built on `ergm`: dynamic models (tergm), count data (ergm.count) and multiple networks (ergm.multi).

Differences in usage: attributes must be numeric variables in the current dataset; an option name cannot have
a digit followed by a letter, so R's `b1degree` is `bdegree1()`; the operators and `structural()` take
R-style terms inside Stata options; a fit is stored in `e()` like any Stata estimation command, so
`estimates store`, `lrtest`, `test` and `predict` work as usual.

## Translation table

| R (`ergm`, `statnet`) | `nwergm` |
|---|---|
| `net <- network(...)`, `ergm.getnetwork` (the network of the formula) | the network is declared with `nwset` (or loaded with `nwuse` / `nwwebuse`) and named in the command: `nwergm net, ...`; nodal attributes are variables of the current dataset |
| `ergm(net ~ edges + nodematch("sex"))` | `nwergm net, edges nodematch(sex)` |
| `nodematch("sex", diff=TRUE)` | `nodematchdiff(sex)` |
| `b1degree(0:2)`, `gwb2degree(0.5, fixed=TRUE)` | `bdegree1(0 1 2)`, `bgwdegree2(0.5)` |
| `gwesp(0.5, fixed=TRUE)`, `gwesp(fixed=FALSE)` | `gwesp(0.5)`, `gwespfree(0.5)` |
| `Symmetrize(~triangle, rule="strong")` | `operators(Symmetrize(triangle, rule(strong)))` (version 1.1.0) |
| `ergm(..., estimate="MPLE")`, `main.method=` | `estimate(mple)`, `mainmethod(mcmle)` or `mainmethod(sa)` |
| `control.ergm(MCMC.burnin=, MCMC.interval=, MCMC.samplesize=, MCMLE.maxit=)` | `mcmcburnin()`, `mcmcinterval()`, `mcmcsamplesize()`, `mcmleiterations()` |
| `control.ergm(MCMLE.effectiveSize=)` | `mcmleeffectivesize()` (version 1.3.0; default 64 as in R, `0` for fixed-size samples) |
| `constraints = ~edges`, `obs.constraints = ~...` | `constraints(edges)`, `obsconstraints(...)` |
| `offset(edges)` with `offset.coef` | `offset(edges #)` |
| `coef(fit)`, `vcov(fit)` | `e(b)`, `e(V)`; `matrix list e(b)` |
| `summary(fit)` | the table printed by `nwergm` |
| `summary(net ~ terms)` (observed statistics) | the column `obs` of `estat gof`; `nwergm simulate, output(stats)` for simulated statistics |
| `simulate(fit, nsim = 100)` | `nwergm simulate, nsim(100)` |
| `gof(fit)` | `estat gof` |
| `mcmc.diagnostics(fit)` | `estat mcmcdiag` (with `plot` for trace plots) |
| `logLik(fit)`, `AIC(fit)`, `BIC(fit)` | `estat ic`, `e(ll)`, `e(aic)`, `e(bic)`; `estimates stats` |
| `anova(fit1, fit2)` | `lrtest` |
| `predict(fit)` | `predict, frame(name) pr` or `predict, matrix(name) pr` |
| `packageVersion("ergm")` | `nwergm version` |

## Where next

[Terms](../terms/) is a map of the term families, and the tutorials ([ERGM 2](../tutorial-2-terms/) onward) use the
commands above on real data. The complete syntax is in Stata's `help nwergm`.
