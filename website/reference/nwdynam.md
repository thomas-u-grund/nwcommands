---
title: "nwdynam"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "nwdynam: Dynamic Network Actor Models (DyNAM), in the separate nwdynam package (GPL-3)."
---

# `nwdynam`

`nwdynam` fits dynamic network actor models to a timestamped sequence of events, after R's `goldfish`: a rate sub-model for who acts next and a choice sub-model for whom the actor chooses (plus a coordination variant for undirected events).

`nwdynam` is not part of the core `nwcommands`. It is a package of its own, released under the
GNU General Public License, version 3, and it needs the core installed first.

| | |
|---|---|
| Current version | 1.0.1 |
| License | GPL-3 |
| Repository | [github.com/thomas-u-grund/nwdynam](https://github.com/thomas-u-grund/nwdynam) |
| Install | `net install nwdynam, from(https://raw.githubusercontent.com/thomas-u-grund/nwdynam/main/)` |
| Or from the core | `nwinstall, modelpkg(nwdynam)` |
| Specific release | `net install nwdynam, from(https://raw.githubusercontent.com/thomas-u-grund/nwdynam/v1.0.1/) replace` |

`nwdynam version` shows the installed release and `nwversion` lists all model packages. Updating the
core never overwrites the package; to update the package, repeat the `net install` line with
`replace`. Inside Stata, `help nwdynam` gives the complete syntax, options and examples.

What it offers:

- structural effects such as inertia, reciprocity and degrees, with optional recency windows
- node and dyadic covariates
- maximum likelihood estimation

A first model:

```stata
. nwdynam chat, submodel(rate)
```

Section: [nwdynam](../nwdynam/). First tutorial: [A first DyNAM](../nwdynam/tutorial-1-first-dynam/). `nwdynam` follows the R package `goldfish` and is not a replacement for it.
