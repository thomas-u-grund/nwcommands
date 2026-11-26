---
title: "nwsaom (SAOM)"
nav_order: 6
has_children: true
permalink: /nwsaom/
description: "nwsaom: stochastic actor-oriented models for Stata, after RSiena. Installation, worked tutorials, a guide for RSiena users, an effect overview and how to cite."
parent: "Packages and reference"
---

<h1 class="pkg-logo"><img src="{{ '/assets/images/packages/nwsaom.png' | relative_url }}" alt="nwsaom" width="253" height="76"></h1>

Stochastic actor-oriented models (SAOM) for Stata: how networks and the behavior of the actors
change over time.
{: .fs-6 .fw-300 }

[Install](install/){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[What it is](what-is/){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Tutorials](../tutorials/nwsaom/){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Manual](https://doi.org/10.5281/zenodo.23623807){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
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

**Speed is a good reason to use it.** On one thread, `nwsaom` was faster than RSiena in all 27 models of our
benchmark: 3.8 times in the median, from 1.9 to 11.5 times (`nwsaom` 1.5.7, RSiena 1.6.14, one Mac laptop). With
several cores the lead can be smaller: on 200 actors, ten threads were 2.0 to 4.2 times as fast as RSiena's best
multi-process setting. The [speed page](speed/) has the times and the method.

## Key facts

| | |
|---|---|
| Effects | 1,058 of the 1,201 effects in the effects table of RSiena 1.6.6 ( effects added in RSiena 1.6.7 to 1.6.14 are implemented too but not counted, and the counts change with RSiena releases); the remaining rows of that table are accounted for in [nwsaom and RSiena](rsiena/) |
| Agreement with RSiena | every implemented effect was compared with `siena07`, by the observed statistic and by the estimates (three by the statistic only) |
| Estimators | method of moments (conditional and unconditional), maximum likelihood, Bayesian |
| Networks | directed, undirected, two-mode, several networks at once, network-behavior co-evolution |
| Data features | covariates, composition change, missing data, structural zeros |
| Engine | a compiled, multithreaded plugin for macOS, Linux and Windows |
| Postestimation | goodness of fit, score tests, time-heterogeneity test (with plot), convergence ratios, relative importance, simulation; plots of the time test and of `nwsaom meta` from version 1.9.0 |
| Dialog boxes | `db nwsaom` (every option and effect), `db nwsaom_multinet`, `db nwsaom_bayes`, `db nwsaom_meta`, `db nwsaom_describe`, `db nwsaom_estat` (from version 1.0.3) |
| Speed | On one thread faster than RSiena in all 27 benchmark models of the article (median 3.8 times); see [Speed compared with RSiena](speed/) |
| Version | 1.9.2 (22 November 2026) |
| License | GNU General Public License, version 3 |

## Tutorials and reference

- [Tutorials](../tutorials/nwsaom/): fourteen worked tutorials. New to `nwsaom`? Start with [Tutorial 1](tutorial-1-first-saom/).
- [Install](install/): core first, then `nwsaom`; releases, updating, the plugin.
- [nwsaom and RSiena](rsiena/): what is the same, what differs, a translation table.
- [Effects](effects/): an overview of the effect families.
- [How to cite](citation/)

## Links

- Source code and releases: [github.com/thomas-u-grund/nwsaom](https://github.com/thomas-u-grund/nwsaom)
- [Manual](manual/): the reference, as a PDF.
- Stata's own documentation: `help nwsaom`, `help nwsaom_estat`, `help nwsaom_remarks`; or the
  [`nwsaom` reference page](../reference/nwsaom)
- The paper on `nwsaom` is under review; the current version is on the [literature page](../literature/).

The core `nwcommands` is introduced in the [tutorials](../tutorials/); the other model
packages are described in [Intro to Longitudinal Network Models](../tutorials/19-intro-longitudinal-models/).
