---
title: "Install"
parent: "nwcommands (core)"
nav_order: 1
description: "Installing the nwcommands core and, optionally, the model packages."
permalink: /nwcommands/install/
---

# Install the core
{: .no_toc }

```stata
. net install nwcommands, from("https://raw.githubusercontent.com/thomas-u-grund/nwcommands/main/")
. nwinstall, all
```

Requirements: Stata 17 or later (Stata/BE is enough). Tested with Stata 17 and 18. The Mata library is built with Stata 17, the oldest tested version, because a library built by a newer Stata is ignored by older ones; Stata 16 and older are untested and not expected to work.

The first line installs `nwinstall` and the landing help topics. `nwinstall, all` then downloads every
command, all help files and every dialog box. Add `nwinstall, gui` to also get a "Network Analysis" menu in Stata.

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
[nwergm](../../nwergm/install/), [nwdynam](../../nwdynam/install/) and [nwrem](../../nwrem/install/). Install all four with

```stata
. nwinstall, models
```

or pick one on its own page.

## Updating and releases

To update, repeat the `net install ... replace` line. Updating the core never overwrites a model package.
To install a particular release, put its tag in the URL, for example `.../nwcommands/v3.5.0/`.
The [Installation & Setup tutorial](../../tutorials/01-installation-setup/) covers choosing a release and installing on
computers without internet access or administrator rights.
