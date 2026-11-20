---
title: "Install"
parent: "nwalaam (ALAAM)"
nav_order: 1
permalink: /nwalaam/install/
description: "Install nwalaam for Stata: the core nwcommands first, then the nwalaam package; specific releases, updating, and the native plugin."
---

# Installing nwalaam

`nwalaam` is a separate package (GPL-3) that needs the core `nwcommands`. Install the core first, then `nwalaam`.

## 1. The core

```stata
. net install nwcommands, from(https://nwcommands.org/net/) replace
. nwinstall, everything
```

`nwinstall, everything` installs the core and all seven model packages in one step; `nwinstall, all` installs the core only.

See [Installation & Setup](../../tutorials/01-installation-setup/) for details, including computers without
internet access or administrator rights.

## 2. nwalaam

```stata
. nwinstall, models
```

If you used `nwinstall, everything` above, the model packages are already installed; after `nwinstall, all` (core only) add them with `nwinstall, models`. Repeating either command updates them. To install nwalaam only, or a specific tagged version, use its own address:

```stata
. net install nwalaam, from(https://raw.githubusercontent.com/thomas-u-grund/nwalaam/main/)
```

(`nwinstall, modelpkg(nwalaam)` does the same from the core.)

### A specific release

Every release is tagged on GitHub and each tag has its own address. For version 1.3.1:

```stata
. net install nwalaam, from(https://raw.githubusercontent.com/thomas-u-grund/nwalaam/v1.3.1/) replace
```

Use a tagged release when you want an analysis to be reproducible: you can then say exactly which
version produced the results.

## 3. Check the installation

```stata
. nwalaam version
nwalaam version 1.3.1, 20nov2026
  native plugin           : .../a/alaam_sim_macos.plugin (ships with the package)
  reference               : ALAAMEE (Stivala, Wang and Lomi) and MPNet
  license                 : GNU GPL-3
```

The output shows the release of `nwalaam`, the native plugin in use and the programs the results were compared with.
The release is stored in `r(version)`, and after a fit in `e(version)`; quote it when you report an analysis.
`nwversion` lists the core and all installed model packages. `help nwalaam` opens the complete documentation.

## Without internet access

On a computer without internet access, install from zip files. Download the [nwalaam zip](https://github.com/thomas-u-grund/nwalaam/archive/refs/heads/main.zip) and the [nwcommands zip](https://github.com/thomas-u-grund/nwcommands/archive/refs/heads/main.zip) elsewhere, unzip them, rename the unzipped `nwalaam-main` folder to `nwalaam`, and run `nwinstall, localcopy all` in the core folder followed by `nwinstall, modelpkg(nwalaam) modelsfrom("<folder that holds nwalaam>")`. The steps, with all the zip files, are on the [installation page of the core](../../nwcommands/install/#no-internet-access-or-administrator-rights).

## Updating

Repeat the `net install` line with `replace`. Updating the core never overwrites `nwalaam`, and updating
`nwalaam` never changes the core. `net describe nwalaam` shows the installed version and distribution date.

## The native plugin

The package ships a compiled plugin for macOS, Linux and Windows. It is installed together with the package and
found automatically; nothing needs to be configured. The sampler that every fit, every simulation and every goodness-of-fit
check needs runs in the plugin; the optimization and the tables are Stata code. There is no slower fallback: without a working plugin
`nwalaam` stops with return code 601 (plugin file missing) or 3495 (plugin older than the package or not loadable).
`nwalaam version` shows the path of the plugin in use, or "missing" if none is found. The plugin has been tested on macOS, Linux and Windows.

The independent runs of `method(ee)` run in parallel threads, one per core by default; `threads(#)` sets the number, and the results are identical for any number of threads.

### If the plugin does not work on your computer

If the plugin of your platform is missing, older than the `.ado` files, or does not load on your system, compile it on your own computer:

```stata
. nwinstall, buildplugin(nwalaam)
```

The command fetches the C source of the package from its GitHub repository, compiles it with the compiler of your computer and
installs the plugin where `net install` puts it (an existing file is kept with the extension `.prev`). You need a C compiler, installed once:
on a Mac the command line tools of Xcode (`xcode-select --install` in the Terminal), on Linux `gcc` and `make`, on Windows Microsoft's free [Build Tools for Visual Studio](https://visualstudio.microsoft.com/visual-cpp-build-tools/) with the workload *Desktop development with C++*, which the command finds by itself; if the compiler is missing, the command says what to install. Restart Stata
afterwards. A plugin depends on the operating system and the processor, not on the version or the flavour of Stata (BE, SE, MP), so a plugin built
on your computer works in every Stata installed there. The source is free software (GPL-3); `net get nwalaam, from(https://raw.githubusercontent.com/thomas-u-grund/nwalaam/main)`
copies it into the current directory, and it is in the folder `native/` of the [repository](https://github.com/thomas-u-grund/nwalaam).

If you have an old copy of `nwalaam` in Stata's PLUS folder as well as a new one elsewhere on the ado-path, Stata
uses the first one it finds; `which nwalaam` and `nwalaam version` show which copy is in use.

## Rebuilding the Mata libraries on your own computer

The Mata libraries of the packages are built with Stata 17. A library built by an older Stata loads in every later Stata, but a library built by a *newer* Stata is
ignored by an older one (Stata says "compiled by Stata 18, is too new to be run by this version of Stata and so was ignored", and every Mata function is then "not found",
r(3499)). If that happens, build the libraries with your own Stata:

```stata
. nwinstall, buildmata(nwalaam)
```

The command fetches the Mata source from the GitHub repositories, compiles it with the Stata that is running and installs the libraries where Stata finds the current
ones, keeping an existing file as a `.prev` copy. `buildmata()` takes `nwcommands`, `nwsaom`, `nwergm`, `nwdynam`, `nwrem`, `nwalaam` or `all` (the core and every installed package).
The build **clears the data and the Mata objects in memory** (it stops with error 4 if data is loaded, so save first), and it takes a few minutes.
Update the packages first (`nwinstall, all` and `nwinstall, models`), because the source of the current release is used. Restart Stata afterwards. The shipped
libraries are the better choice when they load; a build with your own Stata is the fallback and the repair.

## Requirements

- Stata 17 or later; Stata/BE is enough. Tested on macOS with Stata 17, 18 and 19 and on Linux and Windows with Stata 19 (the Mata libraries are built with Stata 17, the oldest tested version; Stata 16 and older are untested). The examples on this site used Stata/BE 17.
- The core `nwcommands`, as above. No Python and no other software.

## Next

[Tutorial 1](../tutorial-1-first-alaam/) fits a first model.
