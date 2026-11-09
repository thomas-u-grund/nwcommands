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

Every release is tagged on GitHub and each tag has its own address. For version 1.5.7:

```stata
. net install nwergm, from(https://raw.githubusercontent.com/thomas-u-grund/nwergm/v1.5.7/) replace
```

Use a tagged release when you want an analysis to be reproducible: you can then say exactly which
version produced the results. The operator terms and the other additions described in this section need version 1.1.0 or later.

## 3. Check the installation

```stata
. nwergm version
nwergm version 1.5.7, 09nov2026
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

## Without internet access

On a computer without internet access, install from zip files. Download the [nwergm zip](https://github.com/thomas-u-grund/nwergm/archive/refs/heads/main.zip) and the [nwcommands zip](https://github.com/thomas-u-grund/nwcommands/archive/refs/heads/main.zip) elsewhere, unzip them, rename the unzipped `nwergm-main` folder to `nwergm`, and run `nwinstall, localcopy all` in the core folder followed by `nwinstall, modelpkg(nwergm) modelsfrom("<folder that holds nwergm>")`. The steps, with all five zip files, are on the [installation page of the core](../../nwcommands/install/#no-internet-access-or-administrator-rights).

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
nothing to configure. The Windows plugin passes the full test suite of `nwergm` (Stata 19 MP,
9 November 2026); the Linux plugin is built the same way but has not been tested on a Linux machine.
`nwergm version` shows the path of the plugin in use. The help file
(`help nwergm`, section on performance) says what happens on a platform without a plugin.

### If the plugin does not work on your computer

If the plugin of your platform is missing, older than the `.ado` files (the Linux and Windows files are built by an
automatic process and can lag behind the macOS file for a while), or does not load on your system, compile it on your own computer:

```stata
. nwinstall, buildplugin(nwergm)
```

The command fetches the C source of the package from its GitHub repository, compiles it with the compiler of your computer and
installs the plugin where `net install` puts it (an existing file is kept with the extension `.prev`). You need a C compiler, installed once:
on a Mac the command line tools of Xcode (`xcode-select --install` in the Terminal), on Linux `gcc` and `make`, on Windows Microsoft's free [Build Tools for Visual Studio](https://visualstudio.microsoft.com/visual-cpp-build-tools/) with the workload *Desktop development with C++*, which the command finds by itself; if the compiler is missing, the command says what to install. Restart Stata
afterwards. A plugin depends on the operating system and the processor, not on the version or the flavour of Stata (BE, SE, MP), so a plugin built
on your computer works in every Stata installed there. The build was tested on macOS; on Windows the search for the compiler and the message were tested. The source is free software (GPL-3); `net get nwergm, from(https://raw.githubusercontent.com/thomas-u-grund/nwergm/main)`
copies it into the current directory, and it is in the folder `native/` of the [repository](https://github.com/thomas-u-grund/nwergm).

## Rebuilding the Mata libraries on your own computer

The Mata libraries of the packages are built with Stata 17. A library built by an older Stata loads in every later Stata, but a library built by a *newer* Stata is
ignored by an older one (Stata says "compiled by Stata 18, is too new to be run by this version of Stata and so was ignored", and every Mata function is then "not found",
r(3499)). If that happens, build the libraries with your own Stata:

```stata
. nwinstall, buildmata(nwergm)
```

The command fetches the Mata source from the GitHub repositories, compiles it with the Stata that is running and installs the libraries where Stata finds the current
ones, keeping an existing file as a `.prev` copy. `buildmata()` takes `nwcommands`, `nwsaom`, `nwergm`, `nwdynam`, `nwrem` or `all` (the core and every installed package).
Three things to know: the build **clears the data and the Mata objects in memory** (it stops with error 4 if data is loaded, so save first); the libraries of nwsaom and
nwergm are compiled against the core library, so rebuilding the core rebuilds the installed nwsaom and nwergm libraries as well; and a build takes a few minutes.
Update the packages first (`nwinstall, all` and `nwinstall, models`), because the source of the current release is used. Restart Stata afterwards. The shipped
libraries are the better choice when they load; a build with your own Stata is the fallback and the repair.

## Requirements

Stata 17 or later (Stata BE is enough; tested with Stata 17 and 18, the Mata libraries are built with Stata 17, the oldest tested version; Stata 16 and older are untested) and the core `nwcommands` with its Mata library.
