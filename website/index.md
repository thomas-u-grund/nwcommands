---
title: Home
nav_order: 1
description: "nwcommands: network analysis for Stata. Import, generate, describe, analyze and plot networks; fit statistical network models with the companion packages nwsaom (SAOM), nwergm (ERGM), nwdynam (DyNAM) and nwrem (REM)."
permalink: /
---

# nwcommands
{: .fs-9 }

Network analysis in Stata: import, generate, describe, analyze and plot networks, and fit statistical
network models, from the Stata command line or from dialog boxes.
{: .fs-6 .fw-300 }

[Install](#install-in-three-steps){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Tutorials](tutorials/){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Command reference](reference/){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Which package do I need?](which-package/){: .btn .fs-5 .mb-4 .mb-md-0 }

```stata
. nwwebuse florentine, nwclear
. nwplot flomarriage, label(_nwnode)
. nwbetween flomarriage
. sum _between
```

## The packages

nwcommands is a family of five packages. The core handles networks (134 commands and 120 dialog boxes).
Four model packages build on it. They are installed separately, and each follows an established R
package without replacing it. The core and all four model packages are free software under the GNU
General Public License, version 3.

| Package | What it does | Follows | Version |
|---|---|---|---|
| [**nwcommands**](nwcommands/) (core) | Import, generate, describe, analyze and plot networks | | 3.8.0 |
| [**nwsaom**](nwsaom/) | Stochastic actor-oriented models (SAOM) for network panels ([manual: doi:10.5281/zenodo.23623807](https://doi.org/10.5281/zenodo.23623807)) | R package RSiena | 1.0.10 |
| [**nwergm**](nwergm/) | Exponential random graph models (ERGM) for one network | R package `ergm` (statnet) | 1.2.3 |
| [**nwdynam**](nwdynam/) | Dynamic network actor models (DyNAM) for event data | R package `goldfish` | 1.1.3 |
| [**nwrem**](nwrem/) | Relational event models (REM) for event data | R package `relevent` | 1.0.8 |

Not sure which one you need? See [Which package do I need?](which-package/).

## Install in three steps
{: #install-in-three-steps }

```stata
. net install nwcommands, from("https://raw.githubusercontent.com/thomas-u-grund/nwcommands/main/")
. nwinstall, everything
```

1. The first line installs `nwinstall` itself and the landing help topics.
2. `nwinstall, everything` downloads everything else: the core (every command, all help files and every dialog
   box) and the four model packages, and prints the version of each at the end.
3. Optional: `nwinstall, gui` installs the "Network Analysis" menu in Stata's User menu (the older
   option name `permanently` still works).

To install the core only, type `nwinstall, all` instead of `nwinstall, everything`; the model packages can be
added later with `nwinstall, models`. To install one model package only, for example nwsaom, type
`net install nwsaom, from(https://raw.githubusercontent.com/thomas-u-grund/nwsaom/main/)`.

Requirements: Stata 17 or later (tested with Stata 17 and 18; StataBE is enough).

`nwversion` shows the installed versions. More on installation, releases and computers without
internet access: [Installation & Setup](tutorials/01-installation-setup/).

## Where to start

- New to networks in Stata: the [tutorials](tutorials/), starting with Installation & Setup and Core Concepts.
- You know the command you want: the [command reference](reference/).
- Coming from R (RSiena, statnet, goldfish, relevent): [nwsaom and RSiena](nwsaom/rsiena/) and the
  "Follows" column above.
- Citing the software, licenses and releases: [Citing and licenses](citing/).
- Problems: issues with the core go to the
  [nwcommands repository](https://github.com/thomas-u-grund/nwcommands/issues); issues with a model
  package go to that package's own repository on GitHub.
