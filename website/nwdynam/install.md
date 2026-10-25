---
title: "Install"
parent: "nwdynam (DyNAM)"
nav_order: 1
permalink: /nwdynam/install/
description: "Install nwdynam for Stata: the core nwcommands first, then the nwdynam package; specific releases, updating, and the native plugin."
---

# Installing nwdynam

`nwdynam` is a separate package (GPL-3) that needs the core `nwcommands`. Install the core first, then `nwdynam`.

## 1. The core

```stata
. net install nwcommands, from("https://raw.githubusercontent.com/thomas-u-grund/nwcommands/main/")
. nwinstall, all
```

See [Installation & Setup](../../tutorials/01-installation-setup/) for details, including computers without
internet access or administrator rights.

## 2. nwdynam

```stata
. net install nwdynam, from(https://raw.githubusercontent.com/thomas-u-grund/nwdynam/main/)
```

This installs the latest release (the state of the main branch). As a shortcut, the core can install it
for you: `nwinstall, modelpkg(nwdynam)`, or all model packages with `nwinstall, models`.

### A specific release

Every release is tagged on GitHub and each tag has its own address. For version 1.0.2:

```stata
. net install nwdynam, from(https://raw.githubusercontent.com/thomas-u-grund/nwdynam/v1.0.2/) replace
```

Use a tagged release when you want an analysis to be reproducible: you can then say exactly which
version produced the results.

## 3. Check the installation

```stata
. nwdynam version
nwdynam version 1.0.2, 25oct2026
  core package nwcommands : installed (development copy, no distribution date)
  native plugin           : .../d/dynam_sim_macos.plugin (ships with the package, no separate version number)
  compared with           : R goldfish 1.6.12
  license                 : GNU GPL-3
```

The output shows the release of `nwdynam`, the core, the native plugin and the version of goldfish that the
results were compared with. (The line about the core says "development copy" here because the examples on
this website were run from a source checkout; a normal installation shows the distribution date of the core.)
The release is stored in `r(version)`, and after a fit in `e(version)`; quote it when you report an analysis.
`nwversion` lists the core and all installed model packages. `help nwdynam` opens the complete documentation.

## Updating

Repeat the `net install` line with `replace`. Updating the core never overwrites `nwdynam`, and updating
`nwdynam` never changes the core. `net describe nwdynam` shows the installed version and distribution date.

## The native plugin

The package ships a compiled plugin for macOS, Linux and Windows. It is installed together with the package and
found automatically; nothing needs to be configured. The plugin evaluates the likelihood and its gradient, which
the optimizer in Mata calls many times. It serves the three default structural effects of the choice model;
other effect sets run in the Mata engine of the package (this is documented in `help nwdynam`) and give the same
results, only more slowly. `nwdynam version` shows the path of the plugin in use, or "missing" if none is found,
in which case everything runs in Mata.

If you have an old copy of `nwdynam` in Stata's PLUS folder as well as a new one elsewhere on the ado-path, Stata
uses the first one it finds; `which nwdynam` and `nwdynam version` show which copy is in use.

## Requirements

- Stata 14 or later; Stata/BE is enough. The examples on this site used Stata/BE 18.
- The core `nwcommands`, as above. No R and no other software.

## Next

[Tutorial 1](../tutorial-1-first-dynam/) fits a first model.
