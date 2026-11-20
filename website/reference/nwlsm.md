---
title: "nwlsm"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "nwlsm: latent space models for networks, in the separate nwlsm package (GPL-3)."
---

# `nwlsm`

`nwlsm` fits latent space models for the ties of a network by MCMC, and a latent space model for social influence.

`nwlsm` is not part of the core `nwcommands`. It is a package of its own, released under the
GNU General Public License, version 3, and it needs the core installed first.

| | |
|---|---|
| License | GPL-3 |
| Repository | [github.com/thomas-u-grund/nwlsm](https://github.com/thomas-u-grund/nwlsm) |
| Install | `nwinstall, modelpkg(nwlsm)` (after the core; `nwinstall, everything` installs the core and the seven model packages) |
| Version | `nwlsm version`; release history on [GitHub](https://github.com/thomas-u-grund/nwlsm/releases) |
| Without `nwinstall` | `net install nwlsm, from(https://raw.githubusercontent.com/thomas-u-grund/nwlsm/main/) replace` |

`nwlsm version` shows the installed release and `nwversion` lists all model packages. Updating the
core never overwrites the package; to update the package, repeat the `nwinstall` line. Inside Stata, `help nwlsm` gives the complete syntax, options and examples.

What it offers:

- Euclidean and bilinear latent space models for undirected and directed, binary and valued networks, with covariates, random sender, receiver and sociality effects and latent clusters
- the social influence model of Sweet and Adhikari (2020)
- minimum Kullback-Leibler positions, convergence diagnostics, goodness of fit and plots

A first model:

```stata
. nwlsm zachary_bin, dim(2) seed(20261120)
```

Section: [nwlsm](../nwlsm/). Tutorials: [A latent space for the karate club](../nwlsm/tutorial-1-first-lsm/) and [How many latent clusters?](../nwlsm/tutorial-2-bic-clusters/). `nwlsm` follows the R package `latentnet`; it is not a replacement for it.
