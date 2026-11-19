---
title: "Install"
parent: "nwsbm (block models)"
nav_order: 1
permalink: /nwsbm/install/
description: "Install nwsbm for Stata: the core nwcommands first, then the nwsbm package; specific releases, updating, and the native plugin."
---

# Installing nwsbm

`nwsbm` is a separate package (GPL-3) that needs the core `nwcommands` (3.28.0 or later). Install the core first, then `nwsbm`.

## 1. The core

```stata
. net install nwcommands, from(https://nwcommands.org/net/) replace
. nwinstall, everything
```

`nwinstall, everything` installs the core and all seven model packages in one step; `nwinstall, all` installs the core only.

See [Installation & Setup](../../tutorials/01-installation-setup/) for details, including computers without
internet access or administrator rights.

## 2. nwsbm

```stata
. nwinstall, models
```

If you used `nwinstall, everything` above, the model packages are already installed; after `nwinstall, all` (core only) add them with `nwinstall, models`. Repeating either command updates them. To install nwsbm only, use its own address:

```stata
. net install nwsbm, from(https://raw.githubusercontent.com/thomas-u-grund/nwsbm/main/)
```

(`nwinstall, modelpkg(nwsbm)` does the same from the core.)

### A specific release

Every release is tagged on GitHub and each tag has its own address. For version 0.3.0:

```stata
. net install nwsbm, from(https://raw.githubusercontent.com/thomas-u-grund/nwsbm/v0.3.0/) replace
```

Use a tagged release when you want an analysis to be reproducible: you can then say exactly which
version produced the results.

## 3. Check the installation

```stata
. nwsbm version
nwsbm version 0.3.0, 19nov2026
  native plugin           : .../s/sbm_vem_macos.plugin (ships with the package)
  reference               : R packages blockmodels, sbm and greed
  license                 : GNU GPL-3
```

The output shows the release of `nwsbm` and the native plugin in use. The release is stored in `r(version)`; quote it when you report an analysis.
`nwversion` lists the core and all installed model packages. `help nwsbm` opens the complete documentation.

## Without internet access

On a computer without internet access, install from zip files. Download the [nwsbm zip](https://github.com/thomas-u-grund/nwsbm/archive/refs/heads/main.zip) and the [nwcommands zip](https://github.com/thomas-u-grund/nwcommands/archive/refs/heads/main.zip) elsewhere, unzip them, rename the unzipped `nwsbm-main` folder to `nwsbm`, and run `nwinstall, localcopy all` in the core folder followed by `nwinstall, modelpkg(nwsbm) modelsfrom("<folder that holds nwsbm>")`. The steps, with all the zip files, are on the [installation page of the core](../../nwcommands/install/#no-internet-access-or-administrator-rights).

## Updating

Repeat the `net install` line with `replace`. Updating the core never overwrites `nwsbm`, and updating
`nwsbm` never changes the core. `net describe nwsbm` shows the installed version and distribution date.

## The native plugin

The package ships a compiled plugin for macOS, Linux and Windows. It is installed together with the package and
found automatically; nothing needs to be configured. The variational EM runs in the plugin; the tables and the post-estimation commands are Stata code. There is no slower fallback: without a working plugin
`nwsbm` stops with an error that names the plugin. `threads(#)` sets the number of threads (default one per core); the result does not depend on the number of threads.

### If the plugin does not work on your computer

If the plugin of your platform is missing, older than the `.ado` files, or does not load on your system, compile it on your own computer:

```stata
. nwinstall, buildplugin(nwsbm)
```

The command fetches the C source of the package from its GitHub repository, compiles it with the compiler of your computer and
installs the plugin where `net install` puts it (an existing file is kept with the extension `.prev`). You need a C compiler, installed once:
on a Mac the command line tools of Xcode (`xcode-select --install` in the Terminal), on Linux `gcc` and `make`, on Windows Microsoft's free [Build Tools for Visual Studio](https://visualstudio.microsoft.com/visual-cpp-build-tools/) with the workload *Desktop development with C++*; if the compiler is missing, the command says what to install. Restart Stata
afterwards. A plugin depends on the operating system and the processor, not on the version or the flavour of Stata (BE, SE, MP). The source is free software (GPL-3) and is in the folder `native/` of the [repository](https://github.com/thomas-u-grund/nwsbm).

## Rebuilding the Mata library on your own computer

The Mata libraries of the packages are built with Stata 17. A library built by an older Stata loads in every later Stata, but a library built by a *newer* Stata is
ignored by an older one (every Mata function is then "not found", r(3499)). If that happens, build the library with your own Stata:

```stata
. nwinstall, buildmata(nwsbm)
```

The build **clears the data and the Mata objects in memory** (save first), and it takes a few minutes. Update the packages first, because the source of the current release is used. Restart Stata afterwards.

## Requirements

- Stata 17 or later; Stata/BE is enough. The new tests of this release were run on macOS with Stata 17, 18 and 19 (the Mata libraries are built with Stata 17, the oldest tested version; Stata 16 and older are untested). <!-- UPDATE AT RELEASE -->
- The core `nwcommands`, as above. No R and no other software.

## Next

[The tutorial](../tutorial-1-first-sbm/) fits a first block model.
