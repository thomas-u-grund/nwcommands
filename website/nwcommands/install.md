---
title: "Install"
parent: "nwcommands (core)"
nav_order: 20
description: "Installing the nwcommands core and, optionally, the model packages."
permalink: /nwcommands/install/
---

# Install
{: .no_toc }

Requirements: Stata 17 or later. The packages are tested with Stata 17 and 18; StataBE is enough. The Mata
libraries are built with Stata 17, and older versions are untested.

## Everything: the core and the four model packages

```stata
. net install nwcommands, from(https://nwcommands.org/net/) replace
. nwinstall, everything
```

The first line installs `nwinstall` and the landing help topics. `nwinstall, everything` then downloads the
core (every command, all help files and every dialog box) and the four model packages, checks first that every
package can be reached, sets up the "Network Analysis" menu in Stata's User menu (one line in your `profile.do`, written only once, however often you run the command), and prints the version of each package at the end. Add `nogui` (`nwinstall, everything nogui`) to leave the menu out.

## The core only

```stata
. nwinstall, all
```

installs the core and ends with a hint on how to add the model packages.

## Check the version

```stata
. nwversion
```

shows the core version and which model packages are installed.

## How large a network can be

The core builds and describes networks of 100,000 nodes, but not every command scales that far. See
[how large a network can be](../size-limits/) before you start on a big network.

## Model packages

The statistical models are separate packages that need the core: [nwsaom](../../nwsaom/install/),
[nwergm](../../nwergm/install/), [nwdynam](../../nwdynam/install/) and [nwrem](../../nwrem/install/). If you installed the core with `nwinstall, all`, add all four with

```stata
. nwinstall, models
```

or pick one on its own page. `nwinstall, everything` does both steps at once.

## Compiling the plugins on your own computer

The core and the model packages `nwsaom`, `nwergm` and `nwdynam` ship compiled plugins for macOS, Linux and Windows. If the plugin of your platform is
missing, is older than the `.ado` files or does not work on your system, compile it there:

```stata
. nwinstall, buildplugin(all)
```

`buildplugin()` takes `nwcommands`, `nwsaom`, `nwergm`, `nwdynam` or `all`. The command fetches the C source from the GitHub repositories, compiles it with
the compiler of your computer (macOS and Linux; a C compiler and `make` are needed: on a Mac the command line tools of Xcode, `xcode-select --install`; on
Linux `gcc` and `make`) and installs the plugins where `net install` puts them. Restart Stata afterwards. A plugin depends on the operating system and the
processor, not on the version or the flavour of Stata, so one built on your computer works in every Stata installed there. The routine was tested on macOS.
The source of each package is also available with `net get`, for example `net get nwcommands, from(https://nwcommands.org/net/)`, together with a short build note.

## Rebuilding the Mata libraries on your own computer

The Mata libraries of the packages are built with Stata 17. A library built by an older Stata loads in every later Stata, but a library built by a *newer* Stata is
ignored by an older one (Stata says "compiled by Stata 18, is too new to be run by this version of Stata and so was ignored", and every Mata function is then "not found",
r(3499)). If that happens, build the libraries with your own Stata:

```stata
. nwinstall, buildmata(all)
```

The command fetches the Mata source from the GitHub repositories, compiles it with the Stata that is running and installs the libraries where Stata finds the current
ones, keeping an existing file as a `.prev` copy. `buildmata()` takes `nwcommands`, `nwsaom`, `nwergm`, `nwdynam`, `nwrem` or `all` (the core and every installed package).
Three things to know: the build **clears the data and the Mata objects in memory** (it stops with error 4 if data is loaded, so save first); the libraries of nwsaom and
nwergm are compiled against the core library, so rebuilding the core rebuilds the installed nwsaom and nwergm libraries as well; and a build takes a few minutes.
Update the packages first (`nwinstall, all` and `nwinstall, models`), because the source of the current release is used. Restart Stata afterwards. The shipped
libraries are the better choice when they load; a build with your own Stata is the fallback and the repair.

## No internet access or administrator rights?

Download the packages as zip files on a computer that has internet access, carry them over (USB drive, shared drive, email), and install from the unzipped folders. This needs no internet connection and no administrator rights on the target computer; the files go into your personal ado folder.

| Package | Zip file (current release) |
|---|---|
| nwcommands (core, always needed) | [nwcommands.zip](https://github.com/thomas-u-grund/nwcommands/archive/refs/heads/main.zip) |
| nwsaom | [nwsaom.zip](https://github.com/thomas-u-grund/nwsaom/archive/refs/heads/main.zip) |
| nwergm | [nwergm.zip](https://github.com/thomas-u-grund/nwergm/archive/refs/heads/main.zip) |
| nwdynam | [nwdynam.zip](https://github.com/thomas-u-grund/nwdynam/archive/refs/heads/main.zip) |
| nwrem | [nwrem.zip](https://github.com/thomas-u-grund/nwrem/archive/refs/heads/main.zip) |

A particular release has its own zip, for example `https://github.com/thomas-u-grund/nwsaom/archive/refs/tags/v1.5.0.zip`. Take the model packages you need; each needs the core. The core zip is about 10 MB.

1. Unzip the core zip. GitHub names the folder `nwcommands-main`.
2. Make a new folder for the model packages, unzip the model zips into it and rename each unzipped folder to the plain package name: `nwsaom-main` becomes `nwsaom`, `nwergm-main` becomes `nwergm`, and so on. The installer looks for these names.
3. In Stata, go to the core folder, copy the core into your personal ado folder, then install the models from their folder:

```stata
. cd "C:\path\to\nwcommands-main"
. nwinstall, localcopy all
. nwinstall, models modelsfrom("C:\path\to\models")
```

Use `nwinstall, modelpkg(nwsaom nwergm)` in place of `models` to install only some packages. Add `nwinstall, gui` for the *Network Analysis* menu. The compiled plugins for Windows, macOS and Linux are in the zips, so nothing has to be built; if one does not work on your computer, see [Compiling the plugins on your own computer](#compiling-the-plugins-on-your-own-computer): `nwinstall, buildplugin()` can compile it from the same source if a C compiler is installed. `help nwinstall` has the full list of options, including `dest()` for another target folder.

## Updating and releases

To update, repeat the `net install ... replace` line. The short address `https://nwcommands.org/net/` always serves the current release; if it is not reachable, `https://raw.githubusercontent.com/thomas-u-grund/nwcommands/main/` serves the same files. Updating the core never overwrites a model package.
To install a particular release, put its tag in the URL, for example `.../nwcommands/v3.14.0/`.
The [Installation & Setup tutorial](../../tutorials/01-installation-setup/) covers choosing a release.
