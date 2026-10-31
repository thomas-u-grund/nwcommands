---
title: "nwergm"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "nwergm: exponential-family random graph models (ERGM), in the separate nwergm package (GPL-3)."
---

# `nwergm`

`nwergm` fits exponential-family random graph models to a network, after the R package `ergm` (statnet): maximum pseudolikelihood where the model is dyad-independent and Monte Carlo maximum likelihood otherwise.

`nwergm` is not part of the core `nwcommands`. It is a package of its own, released under the
GNU General Public License, version 3, and it needs the core installed first.

| | |
|---|---|
| License | GPL-3 |
| Repository | [github.com/thomas-u-grund/nwergm](https://github.com/thomas-u-grund/nwergm) |
| Install | `nwinstall, modelpkg(nwergm)` (after the core; `nwinstall, everything` installs the core and the four model packages) |
| Version | `nwergm version`; release history on [GitHub](https://github.com/thomas-u-grund/nwergm/releases) |
| Without `nwinstall` | `net install nwergm, from(https://raw.githubusercontent.com/thomas-u-grund/nwergm/main/) replace` |

`nwergm version` shows the installed release and `nwversion` lists all model packages. Updating the
core never overwrites the package; to update the package, repeat the `nwinstall` line. Inside Stata, `help nwergm` gives the complete syntax, options and examples.

What it offers:

- a large set of terms: covariate, homophily and mixing terms, degree and star terms, geometrically weighted terms (fixed and curved), directed and two-mode (bipartite) terms
- missing dyads are handled as in R, constraints, offsets, `predict`, and simulation from a fit
- postestimation: `estat gof`, `estat mcmcdiag`, `estat ic`

A first model:

```stata
. nwergm flomarriage, edges nodecov(wealth)
```

Section: [nwergm](../nwergm/). First tutorial: [Tutorial 1: A first ERGM](/nwergm/tutorial-1-first-ergm/). `nwergm` follows the R package `ergm` (statnet) and is not a replacement for it.
