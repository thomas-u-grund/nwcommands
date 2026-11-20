---
title: "nwlsm (latent space)"
nav_order: 8.6
has_children: true
permalink: /nwlsm/
description: "nwlsm: latent space models for networks (Hoff, Raftery and Handcock) for Stata, following the R package latentnet, with a latent space model for social influence. Installation, a worked tutorial and how to cite."
---

# nwlsm
{: .fs-9 }

Latent space models for networks in Stata: every actor has a position in a hidden space, and actors that are close are more likely to be tied.
{: .fs-6 .fw-300 }

[Install](install/){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[What it is](what-is/){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Start with the tutorial](tutorial-1-first-lsm/){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
[nwlsm on GitHub](https://github.com/thomas-u-grund/nwlsm){: .btn .fs-5 .mb-4 .mb-md-0 }

## What nwlsm is

`nwlsm` fits the latent space model of Hoff, Raftery and Handcock (2002) to a network that is observed once. Every actor is given a position in a space of one to ten dimensions.
The log odds of a tie between two actors fall with the distance between their positions, and rise with the covariates of the pair (the Euclidean model), or the tie
depends on the inner product of the positions (the bilinear model). Ties are independent given the positions, so the model reproduces clustering and transitivity without
modelling them as terms: if *i* is close to *j* and *j* is close to *k*, then *i* is close to *k*. The result is a map of the network, with a posterior
distribution for every coefficient, and the means to check the model. The posterior is sampled by Markov chain Monte Carlo in a compiled plugin. `nwlsm` is part of the nwcommands
family of packages.

A second model, added in version 0.6, is the latent space model for social influence of Sweet and Adhikari (2020): the same latent space for the ties, and, jointly with it, a linear model for an
outcome of the actors in which the outcomes of the others, weighted by their distance in the latent space, enter as a regressor.

## Who it is for

`nwlsm` is for people who work in Stata, or prefer it to R, and who want to describe a network by positions and groups rather than by counts of local patterns. It follows the R package
`latentnet` (Krivitsky and Handcock 2008; version 2.12.0 is the reference) and is not a replacement for it: `latentnet` is the more mature and the more widely used program. `nwlsm` is not affiliated with or endorsed by the authors of `latentnet`; errors in `nwlsm` are the author's.
Which model suits which question, latent space, [stochastic block model](../nwsbm/) or [ERGM](../nwergm/), is explained on [Which package do I need?](../which-package/#latent-space-block-model-or-ergm).

A latent space is a summary of the network, not a measurement of anything. The positions are identified only up to rotation, reflection and translation, and their dimensions have no meaning of their own. The model is for one network at one time.

## Key facts

| | |
|---|---|
| Model | latent space model of the ties of a network: Euclidean distance or bilinear inner product, with edge covariates, in one to ten dimensions |
| Networks | undirected and directed, binary; valued networks through `family(poisson)`, `family(binomial)` (with the number of trials) and `family(normal)`; missing ties are left out of the likelihood |
| Random effects | sender, receiver and sociality effects of every actor, with latentnet's priors |
| Clusters | `clusters(#)`: latent clusters (a mixture of spherical normals for the positions), 2 to 6 groups, with memberships and cluster means |
| Social influence | `influence()`: tie model and outcome model fitted jointly, after Sweet and Adhikari (2020), with `estat influence` |
| Estimation | MCMC in a compiled plugin (macOS, Linux, Windows); several chains in parallel threads (`chains()`, `threads()`) with the same results for any number of threads |
| Positions | the minimum Kullback-Leibler positions of latentnet, with posterior mean distances and tie probabilities |
| After the fit | `estat positions`, `estat mcmcdiag` (effective sample size, Geweke, Gelman-Rubin), `estat clusters`, `estat predict`, `estat gof`, `estat ppcheck`, `estat influence`, `estat bic`; `nwlsmplot`, `nwlsmselect` (BIC for several numbers of clusters); dialog boxes |
| Agreement with latentnet | posterior means of the coefficients, log likelihoods, distance matrices and goodness-of-fit statistics agree with `latentnet` 2.12.0 within Monte Carlo error on the test networks (Sampson's monks, random networks, planted clusters, valued networks) |
| Recovery | on simulated networks with planted positions and coefficients, the coefficients and the distances are recovered; for the influence model, 95% posterior intervals of the influence effect covered the true value in 90 to 100 percent of the replications in three simulation scenarios |
| Engine | a compiled plugin for the sampler; there is no slower fallback |
| Version | 0.7.0 (19 November 2026) |
| License | GNU General Public License, version 3 |

## What is not implemented

- Latent space models for several networks at once and hierarchical models (the influence model of Sweet and Adhikari for several networks with random coefficients), a susceptibility indicator, several outcome waves, and binary or count outcomes in the influence model.
- The influence model differs from the paper in a few places: the intercept of the tie model is estimated instead of being fixed, and the outcome coefficients and the error variance are updated by Gibbs steps rather than random-walk steps. The help file lists the deviations.
- Choosing the number of clusters by a BIC-type criterion, as latentnet does: only the log likelihoods of fits with different `clusters()` can be compared by hand.
- Goodness of fit for valued networks beyond the distribution of the values.
- Bipartite (two-mode) and dynamic networks.
- A version below 1.0 is a young package: use it alongside `latentnet` where the result matters, and report what you find.

## In this section

- [Install](install/): core first, then `nwlsm`; releases, updating, the plugin.
- [Tutorial 1: A latent space for the karate club](tutorial-1-first-lsm/): fit, diagnostics, positions and goodness of fit.
- [How to cite](citation/)
- [nwsbm](../nwsbm/): the companion package that finds blocks of actors with similar tie patterns, where `nwlsm` finds positions.
