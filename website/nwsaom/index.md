---
title: "nwsaom (SAOM)"
nav_order: 5
has_children: true
permalink: /nwsaom/
description: "nwsaom: stochastic actor-oriented models for Stata, after RSiena. Installation, worked tutorials, a guide for RSiena users, an effect overview and how to cite."
---

# nwsaom
{: .fs-9 }

Stochastic actor-oriented models (SAOM) for Stata: how networks and the behavior of the actors
change over time.
{: .fs-6 .fw-300 }

[Install](install/){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Start with Tutorial 1](tutorial-1-first-saom/){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
[nwsaom on GitHub](https://github.com/thomas-u-grund/nwsaom){: .btn .fs-5 .mb-4 .mb-md-0 }

## What nwsaom is

`nwsaom` fits stochastic actor-oriented models (Snijders 2001) to networks that were observed at two
or more points in time, such as a school class surveyed every year. The model describes how
the network changed between the waves as the result of the choices of the actors, each of whom creates,
keeps or drops its own ties according to a few simple rules (they reciprocate, they close triangles, they
prefer similar others, ...), and it estimates how strong each rule is. The behavior of the actors
(drinking, smoking, opinions) can change together with the network, which lets you separate
**selection** (people choose friends who are like them) from **influence** (friends become alike).
`nwsaom` is a port of the R package RSiena to Stata and is part of the nwcommands family of packages.

## Who it is for

`nwsaom` is for people who work in Stata, or prefer it to R, and who are new to these models. The
tutorials start from a plain-language explanation, then run a real command and read the real output.
`nwsaom` follows the R package RSiena and is not a replacement for it: RSiena is the reference
implementation and the more complete program, and the page [nwsaom and RSiena](rsiena/) says exactly what
`nwsaom` has and what it lacks. `nwsaom` is not affiliated with or endorsed by the authors of RSiena;
errors in `nwsaom` are the author's.

## Key facts

| | |
|---|---|
| Effects | 1,058 of the 1,121 RSiena effects that are planned for `nwsaom` (94%); the remaining rows of RSiena's effects table are accounted for in [nwsaom and RSiena](rsiena/) |
| Agreement with RSiena | every implemented effect was compared with `siena07`, by the observed statistic and by the estimates |
| Estimators | method of moments (conditional and unconditional), maximum likelihood, Bayesian |
| Networks | directed, undirected, two-mode, several networks at once, network-behavior co-evolution |
| Data features | covariates, composition change, missing data, structural zeros |
| Engine | a compiled, multithreaded plugin for macOS, Linux and Windows |
| Postestimation | goodness of fit, score tests, time-heterogeneity test, relative importance, simulation |
| Version | 1.0.1 (24 October 2026) |
| License | GNU General Public License, version 3 |

## In this section

- [Install](install/): core first, then `nwsaom`; releases, updating, the plugin.
- [Tutorial 1: A first SAOM](tutorial-1-first-saom/): a first model for the Glasgow friendship data, and how to read the table.
- [Tutorial 2: Convergence](tutorial-2-convergence/): what the convergence line means and what to do when a model does not converge.
- [Tutorial 3: Goodness of fit](tutorial-3-goodness-of-fit/): `estat gof`, and improving a poor model.
- [Tutorial 4: Selection and influence](tutorial-4-selection-influence/): friendship and drinking together.
- [Tutorial 5: Testing and comparing](tutorial-5-testing-comparing/): `estat score`, `estat timetest`, `estat importance`, `fix()`.
- [Tutorial 6: Beyond the basic model](tutorial-6-beyond/): maximum likelihood, Bayesian estimation, several networks.
- [nwsaom and RSiena](rsiena/): what is the same, what differs, a translation table.
- [Effects](effects/): an overview of the effect families.
- [How to cite](citation/)

## Links

- Source code and releases: [github.com/thomas-u-grund/nwsaom](https://github.com/thomas-u-grund/nwsaom)
- The manual (PDF), archived at Zenodo: [doi:10.5281/zenodo.23623808](https://doi.org/10.5281/zenodo.23623808); also in the [GitHub repository](https://github.com/thomas-u-grund/nwsaom/blob/main/manual/nwsaom_manual.pdf)
- Stata's own documentation: `help nwsaom`, `help nwsaom_estat`, `help nwsaom_remarks`; or the
  [`nwsaom` reference page](../reference/nwsaom)
- A Stata Journal article on `nwsaom` is in preparation.

The core `nwcommands` is introduced in the [tutorials](../tutorials/); the other model
packages are described in [Intro to Longitudinal Network Models](../tutorials/10-intro-longitudinal-models/).
