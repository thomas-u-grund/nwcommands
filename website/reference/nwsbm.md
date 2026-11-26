---
title: "nwsbm"
parent: "Core command reference"
grand_parent: "Packages and reference"
nav_exclude: true
search_exclude: false
description: "nwsbm: stochastic block models for networks, in the separate nwsbm package (GPL-3)."
---

# `nwsbm`

`nwsbm` fits stochastic block models and latent block models by variational EM and chooses the number of blocks by the ICL.

`nwsbm` is not part of the core `nwcommands`. It is a package of its own, released under the
GNU General Public License, version 3, and it needs the core installed first.

| | |
|---|---|
| License | GPL-3 |
| Repository | [github.com/thomas-u-grund/nwsbm](https://github.com/thomas-u-grund/nwsbm) |
| Install | `nwinstall, modelpkg(nwsbm)` (after the core; `nwinstall, everything` installs the core and the seven model packages) |
| Version | `nwsbm version`; release history on [GitHub](https://github.com/thomas-u-grund/nwsbm/releases) |
| Without `nwinstall` | `net install nwsbm, from(https://raw.githubusercontent.com/thomas-u-grund/nwsbm/main/) replace` |

`nwsbm version` shows the installed release and `nwversion` lists all model packages. Updating the
core never overwrites the package; to update the package, repeat the `nwinstall` line. Inside Stata, `help nwsbm` gives the complete syntax, options and examples.

What it offers:

- Bernoulli, Poisson and Gaussian block models for undirected and directed networks, the degree-corrected Poisson model, and latent block models for two-mode networks
- dyadic covariates, the exact ICL of `greed`, and parallel starts
- `estat icl`, `estat blocks` and plots of the blocked adjacency matrix

A first model:

```stata
. nwsbm zachary_bin, maxblocks(5) generate(block)
```

Section: [nwsbm](../nwsbm/). First tutorial: [Blocks in the karate club](../nwsbm/tutorial-1-first-sbm/). `nwsbm` follows the R packages `sbm`, `blockmodels` and `greed`; it is not a replacement for it.
