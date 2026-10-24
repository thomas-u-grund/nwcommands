---
title: "nwrem"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
description: "nwrem: relational event models (REM), in the separate nwrem package (GPL-3)."
---

# `nwrem`

`nwrem` fits relational event models to a timestamped sequence of events by maximizing the ordinal partial likelihood, after R's `relevent`.

`nwrem` is not part of the core `nwcommands`. It is a package of its own, released under the
GNU General Public License, version 3, and it needs the core installed first.

| | |
|---|---|
| Current version | 1.0.1 |
| License | GPL-3 |
| Repository | [github.com/thomas-u-grund/nwrem](https://github.com/thomas-u-grund/nwrem) |
| Install | `net install nwrem, from(https://raw.githubusercontent.com/thomas-u-grund/nwrem/main/)` |
| Or from the core | `nwinstall, modelpkg(nwrem)` |
| Specific release | `net install nwrem, from(https://raw.githubusercontent.com/thomas-u-grund/nwrem/v1.0.1/) replace` |

`nwrem version` shows the installed release and `nwversion` lists all model packages. Updating the
core never overwrites the package; to update the package, repeat the `net install` line with
`replace`. Inside Stata, `help nwrem` gives the complete syntax, options and examples.

What it offers:

- degree, inertia and other event-history statistics of senders and receivers
- actor-attribute covariate effects
- maximum likelihood estimation

A first model:

```stata
. nwrem chat, nodsnd nidrec
```

Tutorial: [Intro to Longitudinal Network Models](../tutorials/10-intro-longitudinal-models/).
