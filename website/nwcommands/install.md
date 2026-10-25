---
title: "Install"
parent: "nwcommands (core)"
nav_order: 1
description: "Installing the nwcommands core and, optionally, the model packages."
permalink: /nwcommands/install/
---

# Install
{: .no_toc }

Requirements: Stata 17 or later. The packages are tested with Stata 17 and 18; StataBE is enough. The Mata
libraries are built with Stata 17, and older versions are untested.

## Everything: the core and the four model packages

```stata
. net install nwcommands, from("https://raw.githubusercontent.com/thomas-u-grund/nwcommands/main/")
. nwinstall, everything
```

The first line installs `nwinstall` and the landing help topics. `nwinstall, everything` then downloads the
core (every command, all help files and every dialog box) and the four model packages, checks first that every
package can be reached, and prints the version of each package at the end. Add `nwinstall, gui` to also get a
"Network Analysis" menu in Stata.

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

## Updating and releases

To update, repeat the `net install ... replace` line. Updating the core never overwrites a model package.
To install a particular release, put its tag in the URL, for example `.../nwcommands/v3.6.0/`.
The [Installation & Setup tutorial](../../tutorials/01-installation-setup/) covers choosing a release and installing on
computers without internet access or administrator rights.
