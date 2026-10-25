---
title: "Install"
parent: "nwrem (REM)"
nav_order: 1
permalink: /nwrem/install/
description: "Install nwrem for Stata: the core nwcommands first, then the nwrem package; specific releases and updating."
---

# Installing nwrem

`nwrem` is a separate package (GPL-3) that needs the core `nwcommands`. Install the core first, then `nwrem`.

## 1. The core

```stata
. net install nwcommands, from("https://raw.githubusercontent.com/thomas-u-grund/nwcommands/main/")
. nwinstall, all
```

See [Installation & Setup](../../tutorials/01-installation-setup/) for details, including computers without
internet access or administrator rights.

## 2. nwrem

```stata
. net install nwrem, from(https://raw.githubusercontent.com/thomas-u-grund/nwrem/main/)
```

This installs the latest release (the state of the main branch). As a shortcut, the core can install it for you:
`nwinstall, modelpkg(nwrem)`, or all model packages with `nwinstall, models`.

### A specific release

Every release is tagged on GitHub and each tag has its own address. For version 1.0.5:

```stata
. net install nwrem, from(https://raw.githubusercontent.com/thomas-u-grund/nwrem/v1.0.5/) replace
```

Use a tagged release when you want an analysis to be reproducible: you can then say exactly which
version produced the results.

## 3. Check the installation

```stata
. nwrem version
nwrem version 1.0.5, 25oct2026
  core package nwcommands : installed (development copy, no distribution date)
  native plugin           : none (Mata only)
  compared with           : R relevent 1.2-1
  license                 : GNU GPL-3
```

The output shows the release of `nwrem`, the core and the version of relevent that the results were compared with.
(The line about the core says "development copy" here because the examples on this website were run from a source
checkout; a normal installation shows the distribution date of the core.) The release is stored in `r(version)`, and
after a fit in `e(version)`; quote it when you report an analysis. `nwversion` lists the core and all installed model
packages. `help nwrem` opens the complete documentation.

## Updating

Repeat the `net install` line with `replace`. Updating the core never overwrites `nwrem`, and updating `nwrem` never
changes the core. `net describe nwrem` shows the installed version and distribution date. If you have an old copy of
`nwrem` in Stata's PLUS folder as well as a new one elsewhere on the ado-path, Stata uses the first one it finds;
`which nwrem` and `nwrem version` show which copy is in use.

## No plugin

Unlike `nwdynam`, `nwrem` has no compiled plugin: it runs entirely in Stata and Mata, so there is nothing platform-specific to
install, and `nwrem version` says "none (Mata only)".

## Requirements

- Stata 17 or later; Stata/BE is enough. Tested with Stata 17 and 18 (the Mata libraries are built with Stata 17, the oldest tested version; Stata 16 and older are untested). The examples on this site used Stata/BE 18.
- The core `nwcommands`, as above. No R and no other software.

## Next

[Tutorial 1](../tutorial-1-first-rem/) fits a first model.
