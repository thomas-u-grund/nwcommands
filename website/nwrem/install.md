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
. net install nwcommands, from(https://nwcommands.org/net/) replace
. nwinstall, everything
```

`nwinstall, everything` installs the core and all four model packages in one step; `nwinstall, all` installs the core only.

See [Installation & Setup](../../tutorials/01-installation-setup/) for details, including computers without
internet access or administrator rights.

## 2. nwrem

```stata
. nwinstall, models
```

If you used `nwinstall, everything` above, the model packages are already installed; after `nwinstall, all` (core only) add them with `nwinstall, models`. Repeating either command updates them. To install nwrem only, or a specific tagged version, use its own address:

```stata
. net install nwrem, from(https://raw.githubusercontent.com/thomas-u-grund/nwrem/main/)
```

(`nwinstall, modelpkg(nwrem)` does the same from the core.)

### A specific release

Every release is tagged on GitHub and each tag has its own address. For version 1.0.10:

```stata
. net install nwrem, from(https://raw.githubusercontent.com/thomas-u-grund/nwrem/v1.0.10/) replace
```

Use a tagged release when you want an analysis to be reproducible: you can then say exactly which
version produced the results.

## 3. Check the installation

```stata
. nwrem version
nwrem version 1.0.10, 26oct2026
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

## Without internet access

On a computer without internet access, install from zip files. Download the [nwrem zip](https://github.com/thomas-u-grund/nwrem/archive/refs/heads/main.zip) and the [nwcommands zip](https://github.com/thomas-u-grund/nwcommands/archive/refs/heads/main.zip) elsewhere, unzip them, rename the unzipped `nwrem-main` folder to `nwrem`, and run `nwinstall, localcopy all` in the core folder followed by `nwinstall, modelpkg(nwrem) modelsfrom("<folder that holds nwrem>")`. The steps, with all five zip files, are on the [installation page of the core](../../nwcommands/install/#no-internet-access-or-administrator-rights).

## Updating

Repeat the `net install` line with `replace`. Updating the core never overwrites `nwrem`, and updating `nwrem` never
changes the core. `net describe nwrem` shows the installed version and distribution date. If you have an old copy of
`nwrem` in Stata's PLUS folder as well as a new one elsewhere on the ado-path, Stata uses the first one it finds;
`which nwrem` and `nwrem version` show which copy is in use.

## No plugin

Unlike `nwdynam`, `nwrem` has no compiled plugin: it runs entirely in Stata and Mata, so there is nothing platform-specific to
install, and `nwrem version` says "none (Mata only)".

## Rebuilding the Mata libraries on your own computer

The Mata libraries of the packages are built with Stata 17. A library built by an older Stata loads in every later Stata, but a library built by a *newer* Stata is
ignored by an older one (Stata says "compiled by Stata 18, is too new to be run by this version of Stata and so was ignored", and every Mata function is then "not found",
r(3499)). If that happens, build the libraries with your own Stata:

```stata
. nwinstall, buildmata(nwrem)
```

The command fetches the Mata source from the GitHub repositories, compiles it with the Stata that is running and installs the libraries where Stata finds the current
ones, keeping an existing file as a `.prev` copy. `buildmata()` takes `nwcommands`, `nwsaom`, `nwergm`, `nwdynam`, `nwrem` or `all` (the core and every installed package).
Three things to know: the build **clears the data and the Mata objects in memory** (it stops with error 4 if data is loaded, so save first); the libraries of nwsaom and
nwergm are compiled against the core library, so rebuilding the core rebuilds the installed nwsaom and nwergm libraries as well; and a build takes a few minutes.
Update the packages first (`nwinstall, all` and `nwinstall, models`), because the source of the current release is used. Restart Stata afterwards. The shipped
libraries are the better choice when they load; a build with your own Stata is the fallback and the repair.

## Requirements

- Stata 17 or later; Stata/BE is enough. Tested with Stata 17 and 18 (the Mata libraries are built with Stata 17, the oldest tested version; Stata 16 and older are untested). The examples on this site used Stata/BE 18.
- The core `nwcommands`, as above. No R and no other software.

## Next

[Tutorial 1](../tutorial-1-first-rem/) fits a first model.
