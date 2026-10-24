---
title: "nwsaom"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "nwsaom: stochastic actor-oriented models (SAOM), in the separate nwsaom package (GPL-3)."
---

# `nwsaom`

`nwsaom` estimates stochastic actor-oriented models for the evolution of one or several networks (and, optionally, of actor behavior) between two or more observed waves, after RSiena. Estimation is by the method of moments (the default), maximum likelihood (`ml`) or Bayesian methods (`nwsaom bayes`).

`nwsaom` is not part of the core `nwcommands`. It is a package of its own, released under the
GNU General Public License, version 3, and it needs the core installed first.

| | |
|---|---|
| Current version | 1.0.1 |
| License | GPL-3 |
| Repository | [github.com/thomas-u-grund/nwsaom](https://github.com/thomas-u-grund/nwsaom) |
| Install | `net install nwsaom, from(https://raw.githubusercontent.com/thomas-u-grund/nwsaom/main/)` |
| Or from the core | `nwinstall, modelpkg(nwsaom)` |
| Specific release | `net install nwsaom, from(https://raw.githubusercontent.com/thomas-u-grund/nwsaom/v1.0.1/) replace` |

`nwsaom version` shows the installed release and `nwversion` lists all model packages. Updating the
core never overwrites the package; to update the package, repeat the `net install` line with
`replace`. Inside Stata, `help nwsaom` gives the complete syntax, options and examples.

Worked tutorials, an installation page and a guide for RSiena users are in the [nwsaom section](../nwsaom/) of this website.

What it offers:

- a rich set of network, covariate and behavior effects, including interactions, endowment and creation effects, and composition change
- several dependent networks with `nwsaom multinet`, and meta-analysis of several fits
- postestimation: `estat gof`, `estat score`, `estat timetest`, `estat importance`, `estat simulate`

A first model:

```stata
. nwsaom, waves(glasgow1 glasgow2 glasgow3) outdegree reciprocity transtrip samex(smoke1) seed(1)
```

Tutorial: [Intro to Longitudinal Network Models](../tutorials/10-intro-longitudinal-models/).
