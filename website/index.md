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

## News

- **Latest release, 22 November 2026.** nwcommands 3.35.1 (documentation only: the Schoch data sets page is rewritten, licence wording of the data set readers). Before it, on the same day: nwcommands 3.35.0, nwlsm 1.0.6, nwalaam 1.4.0 and nwergm 1.13.0; [release notes](releases/).
- **Sunbelt 2027, Montreal (21 to 26 June 2027).** Workshops on network analysis with Stata are planned; [details are on the news page](news/), conference information on the [Sunbelt 2027 website](https://www.insna.org/events/sunbelt-2027-montreal).
- **Teaching.** [Slides for every week and day of the three course outlines](book/teaching/outlines/) (two 12-week courses and a five-day workshop) and [workshop slides](book/teaching/workshop/) for three three-hour sessions, in PowerPoint and PDF with speaker notes, free to use.

All releases: [Release notes](releases/), with the current version of every package. Announcements: [News](news/). nwcommands is a family of eight packages, the core and seven model packages; which one you need is on [Which package do I need?](which-package/), together with the versions.

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
  "Follows" column of [Which package do I need?](which-package/).
- How fast the model packages are compared with R: [Speed compared with R](nwcommands/speed/) (faster in most of our
  benchmark models, not in all).
- Citing the software, licenses and releases: [Citing and licenses](citing/).
- Problems: issues with the core go to the
  [nwcommands repository](https://github.com/thomas-u-grund/nwcommands/issues); issues with a model
  package go to that package's own repository on GitHub.
