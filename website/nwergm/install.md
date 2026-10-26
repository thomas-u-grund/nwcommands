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
. net install nwcommands, from(https://nwcommands.org/net/) replace
. nwinstall, everything
```

`nwinstall, everything` installs the core and all four model packages in one step; `nwinstall, all` installs the core only.

See [Installation & Setup](../../tutorials/01-installation-setup/) for details, including computers without
internet access or administrator rights.

## 2. nwergm

```stata
. nwinstall, models
```

If you used `nwinstall, everything` above, the model packages are already installed; after `nwinstall, all` (core only) add them with `nwinstall, models`. Repeating either command updates them. To install nwergm only, or a specific tagged version, use its own address:

```stata
. net install nwergm, from(https://raw.githubusercontent.com/thomas-u-grund/nwergm/main/)
```

(`nwinstall, modelpkg(nwergm)` does the same from the core.)

### A specific release

Every release is tagged on GitHub and each tag has its own address. For version 1.2.4:

```stata
. net install nwergm, from(https://raw.githubusercontent.com/thomas-u-grund/nwergm/v1.2.4/) replace
```

Use a tagged release when you want an analysis to be reproducible: you can then say exactly which
version produced the results. The operator terms and the other additions described in this section need version 1.1.0 or later.

## 3. Check the installation

```stata
. nwergm version
nwergm version 1.2.4, 26oct2026
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

Repeat `nwinstall, models` (or `nwinstall, everything`), or, for this package only, its `net install` line with `replace`:

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

Stata 17 or later (Stata BE is enough; tested with Stata 17 and 18, the Mata libraries are built with Stata 17, the oldest tested version; Stata 16 and older are untested) and the core `nwcommands` with its Mata library.
