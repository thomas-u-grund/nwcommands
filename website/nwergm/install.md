---
title: "Install"
parent: "nwergm (ERGM)"
nav_order: 1
permalink: /nwergm/install/
description: "Install nwergm for Stata: the core nwcommands first, then the nwergm package; specific releases, updating, and the native plugin."
---

# Installing nwergm

`nwergm` is a separate package (GPL-3) that needs the core `nwcommands`. Install the core first, then `nwergm`.

## 1. The core

```stata
. net install nwcommands, from("https://raw.githubusercontent.com/thomas-u-grund/nwcommands/main/")
. nwinstall, all
```

See [Installation & Setup](../../tutorials/01-installation-setup/) for details, including computers without
internet access or administrator rights.

## 2. nwergm

```stata
. net install nwergm, from(https://raw.githubusercontent.com/thomas-u-grund/nwergm/main/)
```

This installs the state of the main branch of the repository. As a shortcut, the core can install it for you:
`nwinstall, modelpkg(nwergm)`, or all four model packages with `nwinstall, models`.

### A specific release

Every release is tagged on GitHub and each tag has its own address. For version 1.0.1:

```stata
. net install nwergm, from(https://raw.githubusercontent.com/thomas-u-grund/nwergm/v1.0.1/) replace
```

Use a tagged release when you want an analysis to be reproducible: you can then say exactly which
version produced the results. The operator terms and the other additions described in this section are in the
development version and will be in the next release; with the 1.0.1 tag they are not available. The
tutorials say which of their examples need the development version.

## 3. Check the installation

```stata
. nwergm version
nwergm version 1.0.1, 24oct2026
  core package nwcommands : installed (development copy, no distribution date)
  native plugin           : .../nwergm/lib/plugins/macos/ergm_mcmc_macos.plugin (ships with 
> the package, no separate version number)
  compared with           : R ergm 4.12.0
  license                 : GNU GPL-3
```

The output shows the release of `nwergm`, the core, the native plugin and the version of `ergm`
that the results were compared with. (The core line shows "development copy" because the examples on
this website were run from a source checkout; a normal installation shows the distribution date of the
core.) The release is stored in `r(version)`, and after a fit in `e(version)`; quote it when you
report an analysis. `nwversion` lists the core and all installed model packages. `help nwergm` opens
the complete documentation.

## Updating

Repeat the `net install` line with `replace`:

```stata
. net install nwergm, from(https://raw.githubusercontent.com/thomas-u-grund/nwergm/main/) replace
```

Updating the core never overwrites `nwergm`, and updating `nwergm` never changes the core.
`net describe nwergm` shows the installed version and distribution date.

## The native plugin

The Monte Carlo sampler at the heart of a dyad-dependent fit runs in a compiled plugin that `nwergm` ships for
macOS, Linux and Windows. It is installed together with the package and found automatically; there is
nothing to configure. `nwergm version` shows the path of the plugin in use. The help file
(`help nwergm`, section on performance) says what happens on a platform without a plugin.

## Requirements

Stata 14 or later (Stata BE is enough) and the core `nwcommands` with its Mata library.
