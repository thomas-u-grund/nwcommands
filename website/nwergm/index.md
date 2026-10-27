---
title: "nwergm (ERGM)"
nav_order: 6
has_children: true
permalink: /nwergm/
description: "nwergm: exponential random graph models (ERGM) for Stata, after R's ergm. Installation, tutorials, a map of the terms, a guide for ergm users and how to cite."
---

# nwergm
{: .fs-9 }

Exponential random graph models (ERGM) for Stata: why a network looks the way it does, and which
local patterns (reciprocity, clustering, homophily) build it.
{: .fs-6 .fw-300 }

[Install](install/){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Start with the intro tutorial](../tutorials/09-intro-ergm/){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Manual](https://doi.org/10.5281/zenodo.23661331){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
[nwergm on GitHub](https://github.com/thomas-u-grund/nwergm){: .btn .fs-5 .mb-4 .mb-md-0 }

## What nwergm is

`nwergm` fits exponential-family random graph models to a network that is observed once. The model
describes the probability of the whole network as a function of a few network statistics (the
number of ties, of reciprocated pairs, of triangles, of ties between people of the same group, ...), each with a
coefficient that is estimated from the data. A coefficient tells you whether the pattern occurs more or less
often than expected by chance, given the other patterns in the model. `nwergm` estimates the models by maximum
pseudolikelihood where this is exact and by Monte Carlo maximum likelihood otherwise, and it provides the tools to check, compare and
simulate from the fitted model. It is a port of the R package `ergm` of the statnet project to Stata and is part
of the nwcommands family of packages.

## Who it is for

`nwergm` is for people who work in Stata, or prefer it to R, and who want to fit ERGMs there. The tutorials
start from a plain-language explanation, then run a real command and read the real output. It does not aim
to replace `ergm`. R's `ergm` is the reference implementation and the more complete program, and the page
[nwergm and R's ergm](rergm/) says exactly what `nwergm` has and what it lacks.

## Key facts

| | |
|---|---|
| Terms | 125 of the 139 terms of R's `ergm` 4.12.0 (89.9%), and 125 of the 126 that apply to binary networks (99%); the missing ones are the 13 terms for valued networks and the operator `B`, see [nwergm and R's ergm](rergm/). |
| Agreement with ergm | for each term, the observed statistics, the maximum pseudolikelihood estimates and the Monte Carlo maximum likelihood estimates were compared with `ergm` 4.12.0 |
| Estimators | maximum pseudolikelihood (also penalized and other variants), Monte Carlo maximum likelihood, contrastive divergence, stochastic approximation |
| Networks | directed, undirected and two-mode (bipartite), binary ties |
| Missing data | missing dyads handled as in R (Handcock and Gile); missing covariate values are refused, as in R |
| Fit statistics | log-likelihood, deviance, AIC, BIC, `estat ic`, `lrtest`, `predict` |
| Constraints | sampling and observation constraints (`constraints()`, `obsconstraints()`) |
| Dialog boxes | `db nwergm` sets every term and option; `db nwergm_simulate` and `db nwergm_estat` cover simulation and postestimation (from version 1.1.1) |
| Postestimation | goodness of fit (`estat gof`), MCMC diagnostics (`estat mcmcdiag`), simulation from a fit (`nwergm simulate`) |
| Engine | a compiled plugin for the Monte Carlo sampler (macOS, Linux, Windows) |
| Speed | Faster than R's `ergm` on all eight of our benchmark models (2.9 to 9.4 times, medians of seven fits); the final Monte Carlo sample at the default target is smaller than ergm's; see [Speed compared with R](../nwcommands/speed/#nwergm-and-ergm) |
| Version | 1.3.2 (27 October 2026) |
| License | GNU General Public License, version 3 |

The operator terms (`operators()`), the term `balance`, the curved two-mode terms and `altkstar` with an estimated decay were added in version 1.1.0; earlier releases do not have them.

## In this section

- [Install](install/): core first, then `nwergm`; releases, updating, the plugin.
- [Tutorial 1: A first ERGM](../tutorials/09-intro-ergm/): a first model, information criteria, a Monte Carlo fit and goodness of fit.
- [Tutorial 2: Terms and model specification](tutorial-2-terms/): covariate, structural and triad terms and how to read them.
- [Tutorial 3: Diagnostics and goodness of fit](tutorial-3-diagnostics/): `estat mcmcdiag`, `estat gof` and what to do when a fit does not converge.
- [Tutorial 4: Missing data and comparing models](tutorial-4-missing-comparing/): missing dyads, `estat ic`, `lrtest`, `predict`.
- [Tutorial 5: Constraints, two-mode networks and operators](tutorial-5-constraints-twomode-operators/).
- [nwergm and R's ergm](rergm/): what is the same, what differs, a translation table.
- [Terms](terms/): a map of the term families.
- [How to cite](citation/)

## Links

- Source code and releases: [github.com/thomas-u-grund/nwergm](https://github.com/thomas-u-grund/nwergm)
- Stata's own documentation: `help nwergm`, `help nwergm_estat` and the other help topics listed on the [Terms](terms/) page;
  or the [`nwergm` reference page](../reference/nwergm)

The core `nwcommands` is introduced in the [tutorials](../tutorials/); the other model
packages are described in [Intro to Longitudinal Network Models](../tutorials/10-intro-longitudinal-models/).
