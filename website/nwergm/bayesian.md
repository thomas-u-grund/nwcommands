---
title: "Bayesian ERGM"
parent: "nwergm (ERGM)"
nav_order: 4
permalink: /nwergm/bayesian/
description: "Bayesian estimation of exponential random graph models with nwergm (estimate(bayes), after R's Bergm): what it does, how to read it, and what is not available."
---

# Bayesian ERGM
{: .no_toc }

Since version 1.10.0, `nwergm` can fit an ERGM by Bayesian inference. Add `estimate(bayes)` to any model, and the result is a sample from the posterior distribution of the coefficients
instead of a point estimate and a standard error. The method follows R's `Bergm` package (`bergm()`; Caimo and Friel 2011, 2014).

## Why Bayesian

- **A distribution, not a number.** The posterior of a coefficient shows how well the data determine it: its mean, median, a credible interval, and the whole density.
- **Priors.** You can state what you knew before (a normal prior for each coefficient, by default with mean 0 and variance 100, which is vague) and see how much the data change it.
- **A different failure mode.** The Bayesian sampler does not search for a maximum, so it does not fail in the way the Monte Carlo maximum likelihood search can. A model that is close to degenerate is still hard: the posterior then has a long, slow-moving tail, which `estat mcmcdiag` shows.
- **Uncertainty in everything you derive.** Predictions and goodness of fit can use the draws, so they reflect the uncertainty of the coefficients (`estat gof` after a Bayesian fit is a posterior predictive check).

## How it is used

```stata
. nwergm flomarriage, edges triangle estimate(bayes) seed(1)
. estat posterior, saving(draws) replace plot(both)
. estat mcmcdiag
. estat gof
```

The posterior mean is in `e(b)` and the posterior covariance in `e(V)`, `estat posterior` gives the posterior summaries, saves the
draws to a data set and plots traces and densities. `estat mcmcdiag` reports the effective sample size, the Monte Carlo standard error, the Gelman-Rubin statistic, the Geweke z-score and the
autocorrelation of the draws, and the acceptance rate of every chain. The options `chains()`, `burnin()`, `iterations()`, `thin()`, `priormean()`, `priorvar()` and `priorcov()` control the sampler and the prior; `help nwergm_bayes` lists all of them. There is a tab for it in the dialog box (`db nwergm`).

## How it works, in plain words

The likelihood of an ERGM contains a sum over all possible networks, which cannot be computed, so a Bayesian analysis cannot use the usual samplers. The *exchange algorithm* gets around this: for every coefficient
vector that the sampler proposes, it draws one network from the model at that vector and compares it with the observed one. Many chains run side by side and propose moves from the differences between each other (adaptive direction sampling). The sampler adapts the step size during burn-in and
uses a cheap approximation to reject poor proposals before the costly network simulation (delayed acceptance). The network simulation is the compiled sampler that `nwergm` uses for Monte Carlo maximum likelihood.

## What to check

- Run it long enough: look at the effective sample size and the Gelman-Rubin statistic of `estat mcmcdiag` before you read the coefficients.
- A vague prior is not neutral for every coefficient; for a model with few ties, a variance of 100 on the log-odds scale still allows absurd values. Try a tighter prior and see whether the posterior moves.
- The chains run one after another in one process, so there is no multi-core speed-up, and a Bayesian fit is slower than a pseudolikelihood fit and often slower than a Monte Carlo maximum likelihood fit.

## What is not available with `estimate(bayes)`

Operators (`operators()`), constraints, `fixdensity`, `logstat()` and `expstat()`, user starting values (`init()`), `mainmethod()`, the fallback without the plugin (`nonative`), `submodel()`, and networks with missing dyads.

## Reference

- Caimo, A. and Friel, N. (2011). Bayesian inference for exponential random graph models. *Social Networks* 33(1), 41-55. [doi:10.1016/j.socnet.2010.09.004](https://doi.org/10.1016/j.socnet.2010.09.004)
- Caimo, A. and Friel, N. (2014). Bergm: Bayesian exponential random graphs in R. *Journal of Statistical Software* 61(2), 1-25. [doi:10.18637/jss.v061.i02](https://doi.org/10.18637/jss.v061.i02)
