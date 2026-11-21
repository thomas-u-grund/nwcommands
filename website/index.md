---
title: Home
nav_order: 1
description: "nwcommands: network analysis for Stata. Import, generate, describe, analyze and plot networks; fit statistical network models with the companion packages nwsaom (SAOM), nwergm (ERGM), nwdynam (DyNAM), nwrem (REM), nwalaam (ALAAM), nwlsm (latent space models) and nwsbm (stochastic block models)."
permalink: /
---

# nwcommands
{: .fs-9 }

Network analysis in Stata: import, generate, describe, analyze and plot networks, and fit statistical
network models, from the Stata command line or from dialog boxes.
{: .fs-6 .fw-300 }

[Install](#install-in-two-steps){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Tutorials](tutorials/){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Command reference](reference/){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Which package do I need?](which-package/){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Teaching and slides](teaching/){: .btn .fs-5 .mb-4 .mb-md-0 }

New: [slides for every week and day of the three course outlines](book/teaching/outlines/) (two 12-week courses and a five-day workshop), and [workshop slides](book/teaching/workshop/) for three three-hour sessions, including relational events with `nwrem` and `nwdynam`, and an optional block on autologistic actor attribute models with `nwalaam`. PowerPoint and PDF, with speaker notes, free to use.

## The packages

nwcommands is a family of eight packages. The core handles networks (138 commands and 130 dialog boxes).
Seven model packages build on it. They are installed separately, and each follows an established program
(an R package, or for nwalaam the Python program ALAAMEE) without replacing it. The core and all seven model packages are free software under the GNU
General Public License, version 3.

| Package | What it does | Follows | Version |
|---|---|---|---|
| [**nwcommands**](nwcommands/) (core) | Import, generate, describe, analyze and plot networks | | 3.34.0 |
| [**nwsaom**](nwsaom/) | Stochastic actor-oriented models (SAOM) for network panels ([Manual](https://doi.org/10.5281/zenodo.23623807)) | R package RSiena | 1.9.1 |
| [**nwergm**](nwergm/) | Exponential random graph models (ERGM) for one network ([Manual](https://doi.org/10.5281/zenodo.23661331)) | R package `ergm` (statnet) | 1.12.0 |
| [**nwdynam**](nwdynam/) | Dynamic network actor models (DyNAM) for event data ([Manual](https://doi.org/10.5281/zenodo.24398099)) | R package `goldfish` | 1.11.0 |
| [**nwrem**](nwrem/) | Relational event models (REM) for event data ([Manual](https://doi.org/10.5281/zenodo.24398012)) | R package `relevent` | 1.7.0 |
| [**nwalaam**](nwalaam/) | Autologistic actor attribute models (ALAAM) for a binary outcome on the actors of one network ([Manual](https://doi.org/10.5281/zenodo.24397901)) | ALAAMEE (Python) and MPNet |1.3.1 |
| [**nwlsm**](nwlsm/) | Latent space models for the ties of a network, and for social influence ([Manual](https://doi.org/10.5281/zenodo.24398243)) | R package `latentnet` |1.0.5 |
| [**nwsbm**](nwsbm/) | Stochastic block models and latent block models: which actors play the same role ([Manual](https://doi.org/10.5281/zenodo.24398296)) | R packages `sbm`, `blockmodels` and `greed` |1.0.2 |

Not sure which one you need? See [Which package do I need?](which-package/).

## Install in two steps
{: #install-in-two-steps }

```stata
. net install nwcommands, from(https://nwcommands.org/net/) replace
. nwinstall, everything
```

1. The first line installs `nwinstall` itself and the landing help topics.
2. `nwinstall, everything` downloads everything else: the core (every command, all help files and every dialog
   box) and the seven model packages, sets up the "Network Analysis" menu in Stata's User menu (one line in your
   `profile.do`, never written twice), and prints the version of each package at the end. Add `nogui` to leave
   the menu out; `nwinstall, gui` adds it later (the older option name `permanently` still works).

To install the core only, type `nwinstall, all` instead of `nwinstall, everything`; the model packages can be
added later with `nwinstall, models` (repeating `nwinstall, everything` or `nwinstall, models` also updates them). To install one model package only, for example nwsaom, type
`net install nwsaom, from(https://raw.githubusercontent.com/thomas-u-grund/nwsaom/main/)`.

Requirements: Stata 17 or later (tested on macOS with Stata 17, 18 and 19 and on Windows with Stata 19; StataBE is enough).

If Stata answers `option everything not allowed`, an older `nwinstall` is being used. Type `which nwinstall`: the
path should point into Stata's `ado/plus` folder. If it says `./nwinstall.ado`, an old copy lies in the folder
Stata was started from (the current folder is searched first): change to another folder with `cd`. If an older
copy is loaded in memory (for example by your `profile.do`), type `program drop nwinstall` (or restart Stata).
Then run `nwinstall, everything` again.

`nwversion` shows the installed versions. More on installation, releases and computers without
internet access: [Installation & Setup](tutorials/01-installation-setup/).

After installing, try this: it loads the Florentine marriage network, plots it, and computes each family's betweenness centrality.

```stata
. nwwebuse florentine, nwclear
. nwplot flomarriage, label(_nwnode)
. nwbetween flomarriage
. sum _between
```

## Where to start

- New to networks in Stata: the [tutorials](tutorials/), starting with Installation & Setup and Core Concepts.
- You know the command you want: the [command reference](reference/).
- Coming from R (RSiena, statnet, goldfish, relevent): [nwsaom and RSiena](nwsaom/rsiena/) and the
  "Follows" column above.
- How fast the model packages are compared with R: [Speed compared with R](nwcommands/speed/) (faster in most of our
  benchmark models, not in all).
- Citing the software, licenses and releases: [Citing and licenses](citing/).
- Problems: issues with the core go to the
  [nwcommands repository](https://github.com/thomas-u-grund/nwcommands/issues); issues with a model
  package go to that package's own repository on GitHub.
