---
title: "nwalaam (ALAAM)"
nav_order: 8.5
has_children: true
permalink: /nwalaam/
description: "nwalaam: autologistic actor attribute models (ALAAM) for Stata, following ALAAMEE and MPNet. Installation, worked tutorials and how to cite."
---

# nwalaam
{: .fs-9 }

Autologistic actor attribute models (ALAAM) for Stata: why do these actors, and not the others, have the outcome, given the network around them.
{: .fs-6 .fw-300 }

[Install](install/){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Start with Tutorial 1](tutorial-1-first-alaam/){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
[nwalaam on GitHub](https://github.com/thomas-u-grund/nwalaam){: .btn .fs-5 .mb-4 .mb-md-0 }

## What nwalaam is

`nwalaam` fits the autologistic actor attribute model (Robins, Pattison and Elliott 2001; Daraganova and Robins 2013) to a binary
outcome on the nodes of a network that is taken as given: who smokes, who adopts, who is on which side of a split. Where an ERGM models the
ties of a network, an ALAAM models the *outcome* of the actors, with statistics that count the outcome on the network: how many actors have it
(`density`), how many ties join two actors who both have it (`contagion`), whether the actors with it have many ties (`activity`), and
many more, for undirected, directed and two-mode networks, with actor covariates and, for several networks on the same actors, setting and distance
effects. The likelihood cannot be computed for any realistic network, so the model is estimated by simulation. `nwalaam` is part of the nwcommands family of packages.

## Who it is for

`nwalaam` is for people who work in Stata, or prefer it to Python, and who have an outcome on the actors of one observed network.
It follows ALAAMEE (Stivala, Wang and Lomi; Python, MIT licence), the reference implementation, and MPNet, and is not a replacement
for them. ALAAMEE is the more complete and the more widely used program; `nwalaam` offers its effects, its samplers and its estimator, with a
second, default, estimator (see below). `nwalaam` is not affiliated with or endorsed by the authors of ALAAMEE or MPNet; errors in `nwalaam` are the author's.

A cross-sectional ALAAM describes how an outcome is distributed over a given network. It does not by itself say that friends influence each other:
the same pattern arises when actors choose friends who are like them, or share a setting. To separate influence and selection over time, use a
longitudinal model such as [nwsaom](../nwsaom/). For how the models of the nwcommands family differ, see
[Intro to Longitudinal Network Models](../tutorials/19-intro-longitudinal-models/).

## Two estimators

The default, `method(sa)`, is stochastic approximation as in MPNet: it moves the coefficients until the expected statistics of the model equal the
observed ones, which is the maximum likelihood condition. `method(ee)` is the equilibrium-expectation update that ALAAMEE uses. On the karate club
(34 actors, outcome faction, effects density, activity and contagion) the exact maximum likelihood estimate can be computed by enumerating all
2^34 outcome vectors, and stochastic approximation reproduces it, while the equilibrium-expectation update stops at slightly different values; on a
random network of 16 actors, where every outcome vector can also be enumerated, the same holds, and the standard errors of stochastic
approximation agree with the exact ones within a few percent. On a larger simulated network (500 actors) the standard errors of the
equilibrium-expectation update were too small for density and activity compared with a parametric bootstrap, those of stochastic approximation
close to it. [Tutorial 1](tutorial-1-first-alaam/) shows the numbers; `method(ee)` is the choice when results are to be compared with ALAAMEE.

## Key facts

| | |
|---|---|
| Model | autologistic actor attribute model: a binary outcome on the nodes of a fixed network |
| Effects | for undirected, directed and two-mode networks: density, activity, contagion, two- and three-stars, triangles, geometrically weighted effects, four-cycles, covariate effects (binary, categorical, continuous), and setting, geographic and distance effects; the list is in `help nwalaam` |
| Estimation | stochastic approximation (default, maximum likelihood) or the equilibrium-expectation update of ALAAMEE (`method(ee)`); maximum pseudo-likelihood (`mple`) for a first look |
| Samplers | toggle sampler, zero-or-one sampler for rare outcomes, snowball-conditional sampler with zones |
| After the fit | `nwalaam simulate` (outcome vectors from the model), `estat gof` (goodness of fit), `estat mcmcdiag` (convergence) |
| Agreement with ALAAMEE | every change statistic agrees with ALAAMEE's to rounding error on random undirected, directed and two-mode networks with missing values |
| Agreement with exact maximum likelihood | karate club (2^34 outcome vectors) and a network of 16 actors (2^16): stochastic approximation reproduces the exact estimates |
| Engine | a compiled plugin for the sampler (macOS, Linux, Windows); there is no slower fallback |
| Version | 1.0.0 (18 November 2026) |
| License | GNU General Public License, version 3 |

## In this section

- [Install](install/): core first, then `nwalaam`; releases, updating.
- [Tutorial 1: A first ALAAM on the karate club](tutorial-1-first-alaam/): the estimators side by side, and the exact answer.
- [Tutorial 2: Smoking in the Glasgow friendship network](tutorial-2-glasgow/): contagion and covariates, goodness of fit, simulation, and what contagion does not say.
- [How to cite](citation/)
