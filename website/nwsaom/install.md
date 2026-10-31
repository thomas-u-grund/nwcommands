---
title: "Install"
parent: "nwsaom (SAOM)"
nav_order: 1
permalink: /nwsaom/install/
description: "Install nwsaom for Stata: the core nwcommands first, then the nwsaom package; specific releases, updating, and the native plugin."
---

# Installing nwsaom

`nwsaom` is a separate package (GPL-3) that needs the core `nwcommands`. Install the core first, then `nwsaom`.

## 1. The core

```stata
. net install nwcommands, from(https://nwcommands.org/net/) replace
. nwinstall, everything
```

`nwinstall, everything` installs the core and all four model packages in one step; `nwinstall, all` installs the core only.

See [Installation & Setup](../../tutorials/01-installation-setup/) for details, including computers without
internet access or administrator rights.

## 2. nwsaom

```stata
. nwinstall, models
```

If you used `nwinstall, everything` above, the model packages are already installed; after `nwinstall, all` (core only) add them with `nwinstall, models`. Repeating either command updates them. To install nwsaom only, or a specific tagged version, use its own address:

```stata
. net install nwsaom, from(https://raw.githubusercontent.com/thomas-u-grund/nwsaom/main/)
```

(`nwinstall, modelpkg(nwsaom)` does the same from the core.)

### A specific release

Every release is tagged on GitHub and each tag has its own address. For version 1.4.2:

```stata
. net install nwsaom, from(https://raw.githubusercontent.com/thomas-u-grund/nwsaom/v1.4.2/) replace
```

Use a tagged release when you want an analysis to be reproducible: you can then say exactly which
version produced the results.

## 3. Check the installation

```stata
. nwsaom version
nwsaom version 1.4.2, 31oct2026
  core package nwcommands : installed (development copy, no distribution date)
  native plugin           : .../saom_sim_macos.plugin (plugin build 140)
  compared with           : R RSiena 1.6.14
  license                 : GNU GPL-3
```

The output shows the release of `nwsaom`, the core, the native plugin and the version of RSiena
that the results were compared with. (The lines about the core show "development copy" here because the
examples on this website were run from a source checkout; a normal installation shows the
distribution date of the core.) The release is stored in `r(version)`, and after a fit in `e(version)`;
quote it when you report an analysis. `nwversion` lists the core and all installed model packages.
`help nwsaom` opens the complete documentation.

## Updating

Repeat `nwinstall, models` (or `nwinstall, everything`), or, for this package only, its `net install` line with `replace`:

```stata
. net install nwsaom, from(https://raw.githubusercontent.com/thomas-u-grund/nwsaom/main/) replace
```

Updating the core never overwrites `nwsaom`, and updating `nwsaom` never changes the core.
`net describe nwsaom` shows the installed version and distribution date.

## The native plugin

The simulations at the heart of an SAOM run in a compiled plugin that `nwsaom` ships for
macOS, Linux and Windows. It is installed together with the package and found automatically; there is
nothing to configure, and it uses all physical cores of the computer by default (`cores(1)` runs it on a single
thread; the results for a given `seed()` are the same whatever the number of threads).
`nwsaom version` shows the path of the plugin in use.

If no plugin can be found, `nwsaom version` says "missing", and the fit is run by a slower engine written in Mata
wherever that is possible. Not every effect has a Mata implementation: some effects, and the
estimators and tools that need the plugin (for example `nwsaom multinet`, `estat importance` and `nwsaom bayes`), stop with a
message instead. After a fit, `e(engine)` says which engine ran (`native` or `mata`).

### If the plugin does not work on your computer

If the plugin of your platform is missing, older than the `.ado` files (the Linux and Windows files are built by an
automatic process and can lag behind the macOS file for a while), or does not load on your system, compile it on your own computer:

```stata
. nwinstall, buildplugin(nwsaom)
```

The command fetches the C source of the package from its GitHub repository, compiles it with the compiler of your computer and
installs the plugin where `net install` puts it (an existing file is kept with the extension `.prev`). You need a C compiler and
`make`: on a Mac the command line tools of Xcode (`xcode-select --install` in the Terminal), on Linux `gcc` and `make`. Restart Stata
afterwards. A plugin depends on the operating system and the processor, not on the version or the flavour of Stata (BE, SE, MP), so a plugin built
on your computer works in every Stata installed there. The routine was tested on macOS; on Windows it stops with a message and the
build note that comes with the source gives the command for the Visual Studio command line. The source is free software (GPL-3); `net get nwsaom, from(https://raw.githubusercontent.com/thomas-u-grund/nwsaom/main)`
copies it into the current directory, and it is in the folder `native/` of the [repository](https://github.com/thomas-u-grund/nwsaom).

If you have an old copy of `nwsaom` in Stata's PLUS folder as well as a new one elsewhere on the ado-path, Stata
uses the first one it finds; if an update does not seem to take effect, `which nwsaom` and
`nwsaom version` show which copy is in use.

## Requirements

- Stata 17 or later; Stata/BE is enough. Tested with Stata 17 and 18 (the Mata libraries are built with Stata 17, the oldest tested
  version; Stata 16 and older are untested). The plugin exchanges data with Mata through frames. The examples used Stata/BE 18.
- The core `nwcommands`, as above.
- No R and no other software.

## Next

[Tutorial 1](../tutorial-1-first-saom/) fits a first model.
