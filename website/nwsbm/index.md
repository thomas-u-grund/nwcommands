---
title: "nwsbm (block models)"
nav_order: 8.7
has_children: true
permalink: /nwsbm/
description: "nwsbm: stochastic block models and latent block models for networks in Stata, following the R packages sbm, blockmodels and greed. Installation, two worked tutorials and how to cite."
---

# nwsbm
{: .fs-9 }

Stochastic block models for networks in Stata: which actors play the same role in the network, and how do the roles connect.
{: .fs-6 .fw-300 }

[Install](install/){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[What it is](what-is/){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Start with the tutorial](tutorial-1-first-sbm/){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
[nwsbm on GitHub](https://github.com/thomas-u-grund/nwsbm){: .btn .fs-5 .mb-4 .mb-md-0 }

## What nwsbm is

`nwsbm` fits the stochastic block model (Nowicki and Snijders 2001; Daudin, Picard and Robin 2008) to a network that is observed once. The actors are sorted into blocks, and the probability of a tie (or the
mean of a tie value) depends only on the blocks of the two actors. The result is a partition of the actors into groups with the same pattern of ties, a small matrix that says how likely ties are within and between the blocks,
and, for every actor, the probability of belonging to each block. The number of blocks is chosen by a criterion, the integrated classification likelihood (ICL), instead of being set by hand. `nwsbm` fits the models by variational EM
in a compiled plugin and is part of the nwcommands family of packages.

Blocks are not communities. A community model looks for groups with many ties inside; a block model looks for groups of actors that behave alike, which can be the opposite (a core with many ties and a periphery with few, hubs and leaves, two sides that tie only to each other).

## Who it is for

`nwsbm` is for people who work in Stata, or prefer it to R, and who want to partition a network by the pattern of its ties. It follows the R packages `blockmodels` (Leger) and `sbm` (Chiquet, Donnet, Barbillon and Lacoste) for the objective, the
ICL and the model names, and `greed` (Côme, Jouvin, Latouche and Bouveyron) for the degree-corrected model and the exact ICL. It does not replace them. `nwsbm` is not affiliated with or endorsed by their authors; errors in `nwsbm` are the author's.
Which model suits which question, block model, [latent space model](../nwlsm/) or [ERGM](../nwergm/), is explained on [Which package do I need?](../which-package/#latent-space-block-model-or-ergm).

## Key facts

| | |
|---|---|
| Model | stochastic block model for one-mode networks (undirected, directed); latent block model for two-mode networks |
| Edge models | Bernoulli (binary ties), Poisson (counts), Gaussian (real-valued ties, with one variance, estimated or fixed); missing ties are left out |
| Degree correction | `degreecorrected` (Karrer and Newman 2011) with the Poisson model |
| Selection of the number of blocks | ICL as in `blockmodels` and `sbm`, over `minblocks()` to `maxblocks()`; `icl(exact)`: the exact ICL of `greed` for the Bernoulli and the degree-corrected Poisson model |
| Covariates | dyadic covariates (networks of the session, and absolute, equal or signed differences of node variables) for all three edge models, one-mode and two-mode, with standard errors (conditional on the estimated blocks) |
| Estimation | variational EM in a compiled plugin (macOS, Linux, Windows); spectral, split, merge and random starts evaluated in parallel threads, with the same result for any number of threads |
| After the fit | `estat icl`, `estat blocks`, memberships and posterior probabilities with `generate()`; `nwsbmplot` (blocked adjacency matrix, block graph); dialog boxes |
| Agreement with R | the number of blocks, the memberships (adjusted Rand index 1) and the ICL agree with `sbm` 1.0.0 and `blockmodels` 1.2.1 on the test networks (Bernoulli, Poisson, Gaussian, two-mode, with and without covariates; the ICL to a relative difference of about 5e-8 with covariates), and with `greed` 0.6.2 for the degree-corrected model and the exact ICL |
| Recovery | planted partitions and planted covariate coefficients are recovered on simulated networks |
| Engine | a compiled plugin; there is no slower fallback |
| Version | 1.0.1 (20 November 2026) |
| License | GNU General Public License, version 3 |

## What is not implemented

- Multiplex, dynamic and longitudinal block models, and models with several networks on the same actors.
- The exact ICL for the Poisson and Gaussian models without degree correction, and the zero-inflated models of `blockmodels`.
- Degree correction, `icl(exact)` and `blockvar` cannot be combined with covariates.
- `greed` searches by greedy merge and swap moves on the exact criterion and can find a partition a node or two better than the variational partition at which `icl(exact)` is evaluated.
- Where R's covariate models differ from the true likelihood (missing ties treated as zeros, an approximate Bernoulli estimator by default, a wrong value for the two-mode Bernoulli case), `nwsbm` follows the exact model and says so in its help file.
- A version below 1.0 is a young package: use it alongside the R packages where the result matters, and report what you find.

## In this section

- [Install](install/): core first, then `nwsbm`; releases, updating, the plugin.
- [Tutorial 1: Blocks in the karate club](tutorial-1-first-sbm/): choosing the number of blocks, and what the blocks are.
- [Tutorial 2: Covariates, the exact ICL and two-mode blocks](tutorial-2-covariates-greedy/): covariates with standard errors, the greedy search, the degree-corrected two-mode model, block variances.
- [How to cite](citation/)
- [nwlsm](../nwlsm/): the companion package that places actors in a latent space, where `nwsbm` groups them.
