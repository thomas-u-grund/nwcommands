---
title: Home
nav_order: 1
description: "nwcommands: network analysis for Stata — import, generate, analyze, model, and visualize network data."
permalink: /
---

# nwcommands
{: .fs-9 }

Network analysis for Stata — over 130 commands for importing, generating, describing,
analyzing, visualizing, and statistically modeling networks, alongside Stata's own regular
data commands.
{: .fs-6 .fw-300 }

[Get started](#installation){: .btn .btn-primary .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Command reference](reference/){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
[Tutorials](tutorials/){: .btn .fs-5 .mb-4 .mb-md-0 .mr-2 }
[nwsaom](nwsaom/){: .btn .fs-5 .mb-4 .mb-md-0 }

```stata
. nwwebuse florentine, nwclear
. nwplot flomarriage, label(_nwnode)
. nwbetween flomarriage
. sum _between
```

## What's here

- **Import / export** — edgelists, adjacency matrices, UCINET/Pajek-style formats
  (`nwfromedge`, `nwimport`, `nwset`, `nwexport`, ...)
- **Generators** — random, small-world, preferential-attachment, lattice, and
  expression-based networks (`nwrandom`, `nwsmall`, `nwpref`, `nwlattice`, `nwgenerate`, ...)
- **Structural analysis** — centrality, components, cliques/k-plexes/k-cores, cohesive
  subgroups, community detection, structural equivalence, QAP, and more
- **Statistical network models** — available as separate GPL-3 packages that build on the core:
  `nwergm` (ERGM), `nwsaom` (stochastic actor-oriented models), `nwrem` (relational event
  models), and `nwdynam` (Dynamic Network Actor Models); see the
  [ERGM](tutorials/09-intro-ergm/) and [longitudinal models](tutorials/10-intro-longitudinal-models/) tutorials;
  `nwsaom` has its own section with [worked tutorials](nwsaom/)
- **Visualization** — static plots and network movies (`nwplot`, `nwmovie`)
- **Dialog boxes** — around 120 GUI dialogs covering nearly every command, reachable via
  Stata's own "Network Analysis" menu, for anyone who prefers point-and-click to typing syntax

Every command works alongside ordinary Stata variables — a network can be loaded as Stata
variables when you want to, but this is opt-in, not automatic, so building and analyzing a
network never has to spend Stata's own variable budget unless you ask it to.

## Installation

The core, version 3.0.0:

```stata
. net from "https://raw.githubusercontent.com/thomas-u-grund/nwcommands/master"
. net install nwcommands
. nwinstall, all
```

The first two lines install just `nwinstall` itself and the landing help topics; `nwinstall,
all` then downloads everything else — every command, all help files, and every dialog box —
and installs them permanently. Add `nwinstall, gui` to also add a "Network Analysis"
menu to Stata's own User menu.

The statistical network models are separate GPL-3 packages (each currently at version 1.0.1) that
need the core. Install all four with `nwinstall, models`, or one by one:

```stata
. net install nwsaom,  from(https://raw.githubusercontent.com/thomas-u-grund/nwsaom/main/)
. net install nwergm,  from(https://raw.githubusercontent.com/thomas-u-grund/nwergm/main/)
. net install nwdynam, from(https://raw.githubusercontent.com/thomas-u-grund/nwdynam/main/)
. net install nwrem,   from(https://raw.githubusercontent.com/thomas-u-grund/nwrem/main/)
```

`nwversion` shows the core version and which model packages are installed. To update, repeat the
`net install ... replace` line; updating the core never overwrites a model package. To install a
particular release, use its tag in the URL, for example `.../nwsaom/v1.0.1/`.

See the [Installation & Setup](tutorials/01-installation-setup/) tutorial for a full walkthrough,
including choosing a release and options for computers without internet access or admin rights.

## Learn

- **New to nwcommands?** Start with the [tutorials](tutorials/) — short, worked walkthroughs
  with real Stata output, one topic at a time.
- **Know what command you need?** Jump straight to the [command reference](reference/).
- **Curious how it's built, or what's planned?** See the project's
  [architecture](https://github.com/thomas-u-grund/nwcommands/blob/master/ARCHITECTURE.md) and
  [roadmap](https://github.com/thomas-u-grund/nwcommands/blob/master/ROADMAP.md) on GitHub.

## Performance

Two backends exist for the commands where it matters, chosen automatically and
transparently — there is nothing to configure, and results are identical either way: a
sparse-native Mata graph representation for the core structural commands, proven at 100,000
nodes / 1,000,000 edges, and compiled native (C) kernels for the handful of operations where
Stata's own interpreter, not the algorithm, is the bottleneck.
