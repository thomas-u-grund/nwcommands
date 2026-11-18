---
title: "nwalaam"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "nwalaam: autologistic actor attribute models (ALAAM), in the separate nwalaam package (GPL-3)."
---

# `nwalaam`

`nwalaam` fits autologistic actor attribute models, a binary outcome on the nodes of a network, by stochastic approximation or by the equilibrium-expectation update of ALAAMEE.

`nwalaam` is not part of the core `nwcommands`. It is a package of its own, released under the
GNU General Public License, version 3, and it needs the core installed first.

| | |
|---|---|
| License | GPL-3 |
| Repository | [github.com/thomas-u-grund/nwalaam](https://github.com/thomas-u-grund/nwalaam) |
| Install | `nwinstall, modelpkg(nwalaam)` (after the core; `nwinstall, everything` installs the core and the five model packages) |
| Version | `nwalaam version`; release history on [GitHub](https://github.com/thomas-u-grund/nwalaam/releases) |
| Without `nwinstall` | `net install nwalaam, from(https://raw.githubusercontent.com/thomas-u-grund/nwalaam/main/) replace` |

`nwalaam version` shows the installed release and `nwversion` lists all model packages. Updating the
core never overwrites the package; to update the package, repeat the `nwinstall` line. Inside Stata, `help nwalaam` gives the complete syntax, options and examples.

What it offers:

- effects for undirected, directed and two-mode networks, with covariates and setting and distance effects
- stochastic approximation (maximum likelihood) and the equilibrium-expectation update of ALAAMEE
- simulation from a fitted model, goodness of fit and convergence diagnostics

A first model:

```stata
. nwalaam faction zachary_bin, effects(density activity contagion)
```

Section: [nwalaam](../nwalaam/). First tutorial: [A first ALAAM on the karate club](../nwalaam/tutorial-1-first-alaam/). `nwalaam` follows ALAAMEE (Python) and MPNet; it is not a replacement for them.
