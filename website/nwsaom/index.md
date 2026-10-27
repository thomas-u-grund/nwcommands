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
[Manual](https://doi.org/10.5281/zenodo.23623807){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
[nwsaom on GitHub](https://github.com/thomas-u-grund/nwsaom){: .btn .fs-5 .mb-4 .mb-md-0 }

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.23623807.svg)](https://doi.org/10.5281/zenodo.23623807)

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
| Effects | about 94% of the effects in the effects table of RSiena 1.6.6 that are planned for `nwsaom` (1,058 of 1,121 rows; effects added in RSiena 1.6.7 to 1.6.14 are implemented too but not counted, and the counts change with RSiena releases); the remaining rows of that table are accounted for in [nwsaom and RSiena](rsiena/) |
| Agreement with RSiena | every implemented effect was compared with `siena07`, by the observed statistic and by the estimates |
| Estimators | method of moments (conditional and unconditional), maximum likelihood, Bayesian |
| Networks | directed, undirected, two-mode, several networks at once, network-behavior co-evolution |
| Data features | covariates, composition change, missing data, structural zeros |
| Engine | a compiled, multithreaded plugin for macOS, Linux and Windows |
| Postestimation | goodness of fit, score tests, time-heterogeneity test, relative importance, simulation |
| Dialog boxes | `db nwsaom` (every option and effect), `db nwsaom_multinet`, `db nwsaom_bayes`, `db nwsaom_meta`, `db nwsaom_describe`, `db nwsaom_estat` (from version 1.0.3) |
| Speed | On one thread faster than RSiena in all 28 benchmark models of the article (median 2.1 times); see [Speed compared with R](../nwcommands/speed/#nwsaom-and-rsiena) |
| Version | 1.1.1 (27 October 2026) |
| License | GNU General Public License, version 3 |

## In this section

- [Install](install/): core first, then `nwsaom`; releases, updating, the plugin.
- [Tutorial 1: A first SAOM](tutorial-1-first-saom/): a first model for the Glasgow friendship data, and how to read the table.
- [Tutorial 2: Convergence](tutorial-2-convergence/): what the convergence line means and what to do when a model does not converge.
- [Tutorial 3: Goodness of fit](tutorial-3-goodness-of-fit/): `estat gof`, and improving a poor model.
- [Tutorial 4: Selection and influence](tutorial-4-selection-influence/): friendship and drinking together.
- [Tutorial 5: Testing and comparing](tutorial-5-testing-comparing/): `estat score`, `estat timetest`, `estat importance`, `fix()`.
- [Tutorial 6: Beyond the basic model](tutorial-6-beyond/): maximum likelihood, Bayesian estimation, several networks.
- [Tutorial 7: Changing actor sets and missing data](tutorial-7-composition-missing/): `present()`, `joinat()`/`leaveat()`, `missnet()`, `missbeh()`: actors who join or leave, and missing data.
- [Tutorial 8: Time-varying and dyadic covariates](tutorial-8-covariates/): `tvcov()` and `dyadcov()`: covariates that change over time and covariates of pairs.
- [Tutorial 9: Undirected and two-mode networks](tutorial-9-undirected-twomode/): undirected networks (`symtype()`) and two-mode networks.
- [Tutorial 10: Endowment, creation, interactions and rate effects](tutorial-10-endowment-interaction-rate/): `endow()`/`creation()`, `interact()`, `ratecov()`, `outrate`.
- [Tutorial 11: Simulation and what-if analysis](tutorial-11-simulation/): `estat simulate`, `nwsaom simulate`, `estat mems`.
- [Tutorial 12: Conditional and unconditional estimation, threads and speed](tutorial-12-estimation-speed/): conditional and unconditional estimation, `cores()`, `k0()`/`k3()`.
- [Tutorial 13: Combining several groups with a meta-analysis](tutorial-13-meta-analysis/): `nwsaom meta` for several groups (RSiena's `siena08`).
- [Tutorial 14: Several groups at once](tutorial-14-several-groups/): one model for all groups with `groups()` and `gwaves()` (RSiena's `sienaGroupCreate`).
- [nwsaom and RSiena](rsiena/): what is the same, what differs, a translation table.
- [Effects](effects/): an overview of the effect families.
- [How to cite](citation/)

## Links

- Source code and releases: [github.com/thomas-u-grund/nwsaom](https://github.com/thomas-u-grund/nwsaom)
- The manual (PDF), archived at Zenodo: [doi:10.5281/zenodo.23623807](https://doi.org/10.5281/zenodo.23623807); also in the [GitHub repository](https://github.com/thomas-u-grund/nwsaom/blob/main/manual/nwsaom_manual.pdf)
- Stata's own documentation: `help nwsaom`, `help nwsaom_estat`, `help nwsaom_remarks`; or the
  [`nwsaom` reference page](../reference/nwsaom)
- A Stata Journal article on `nwsaom` is in preparation.

The core `nwcommands` is introduced in the [tutorials](../tutorials/); the other model
packages are described in [Intro to Longitudinal Network Models](../tutorials/10-intro-longitudinal-models/).
