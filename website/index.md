---
title: Home
nav_order: 1
description: "nwcommands: network analysis for Stata. Import, generate, describe, analyze and plot networks; fit statistical network models with the companion packages nwsaom (SAOM), nwergm (ERGM), nwdynam (DyNAM), nwrem (REM), nwalaam (ALAAM), nwlsm (latent space models) and nwsbm (stochastic block models)."
permalink: /
---

<h1><img src="{{ '/assets/images/nwcommands-logo.png' | relative_url }}" alt="nwcommands" width="480"></h1>

Network analysis in Stata: import, generate, describe, analyze and plot networks, and fit statistical
network models, from the Stata command line or from dialog boxes.
{: .fs-6 .fw-300 }

[Install](#install-in-two-steps){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Tutorials](tutorials/){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Command reference](reference/){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Which package do I need?](which-package/){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Teaching and slides](teaching/){: .btn .fs-5 .mb-4 .mb-md-0 }

## The packages
{: #the-packages }

<div class="pkg-grid">
  <a class="pkg-card" href="{{ '/nwcommands/' | relative_url }}">
    <span class="pkg-card-logo"><img src="{{ '/assets/images/packages/nwcommands.png' | relative_url }}" alt="nwcommands" width="228" height="50"></span>
    <span class="pkg-card-text">The core: import, describe, analyze and plot networks</span>
  </a>
  <a class="pkg-card" href="{{ '/nwergm/' | relative_url }}">
    <span class="pkg-card-logo"><img src="{{ '/assets/images/packages/nwergm.png' | relative_url }}" alt="nwergm" width="140" height="50"></span>
    <span class="pkg-card-text">Exponential random graph models (ERGM)</span>
  </a>
  <a class="pkg-card" href="{{ '/nwsaom/' | relative_url }}">
    <span class="pkg-card-logo"><img src="{{ '/assets/images/packages/nwsaom.png' | relative_url }}" alt="nwsaom" width="167" height="50"></span>
    <span class="pkg-card-text">Stochastic actor-oriented models (SAOM)</span>
  </a>
  <a class="pkg-card" href="{{ '/nwdynam/' | relative_url }}">
    <span class="pkg-card-logo"><img src="{{ '/assets/images/packages/nwdynam.png' | relative_url }}" alt="nwdynam" width="203" height="50"></span>
    <span class="pkg-card-text">Dynamic network actor models (DyNAM)</span>
  </a>
  <a class="pkg-card" href="{{ '/nwrem/' | relative_url }}">
    <span class="pkg-card-logo"><img src="{{ '/assets/images/packages/nwrem.png' | relative_url }}" alt="nwrem" width="129" height="50"></span>
    <span class="pkg-card-text">Relational event models (REM)</span>
  </a>
  <a class="pkg-card" href="{{ '/nwalaam/' | relative_url }}">
    <span class="pkg-card-logo"><img src="{{ '/assets/images/packages/nwalaam.png' | relative_url }}" alt="nwalaam" width="168" height="50"></span>
    <span class="pkg-card-text">Autologistic actor attribute models (ALAAM)</span>
  </a>
  <a class="pkg-card" href="{{ '/nwlsm/' | relative_url }}">
    <span class="pkg-card-logo"><img src="{{ '/assets/images/packages/nwlsm.png' | relative_url }}" alt="nwlsm" width="127" height="50"></span>
    <span class="pkg-card-text">Latent space models</span>
  </a>
  <a class="pkg-card" href="{{ '/nwsbm/' | relative_url }}">
    <span class="pkg-card-logo"><img src="{{ '/assets/images/packages/nwsbm.png' | relative_url }}" alt="nwsbm" width="140" height="50"></span>
    <span class="pkg-card-text">Stochastic block models</span>
  </a>
</div>

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
