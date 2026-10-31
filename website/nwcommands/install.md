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

## Updating and releases

To update, repeat the `net install ... replace` line. The short address `https://nwcommands.org/net/` always serves the current release; if it is not reachable, `https://raw.githubusercontent.com/thomas-u-grund/nwcommands/main/` serves the same files. Updating the core never overwrites a model package.
To install a particular release, put its tag in the URL, for example `.../nwcommands/v3.13.0/`.
The [Installation & Setup tutorial](../../tutorials/01-installation-setup/) covers choosing a release and installing on
computers without internet access or administrator rights.
