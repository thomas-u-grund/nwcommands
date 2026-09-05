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
[Tutorials](tutorials/){: .btn .fs-5 .mb-4 .mb-md-0 }

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
- **Statistical network models** — exponential-family random graph models (`nwergm`),
  stochastic actor-oriented models (`nwsaom`), relational event models (`nwrem`), and
  Dynamic Network Actor Models (`nwdynam`)
- **Visualization** — static plots and network movies (`nwplot`, `nwmovie`)
- **Dialog boxes** — around 120 GUI dialogs covering nearly every command, reachable via
  Stata's own "Network Analysis" menu, for anyone who prefers point-and-click to typing syntax

Every command works alongside ordinary Stata variables — a network can be loaded as Stata
variables when you want to, but this is opt-in, not automatic, so building and analyzing a
network never has to spend Stata's own variable budget unless you ask it to.

## Installation

```stata
. net from "https://raw.githubusercontent.com/thomas-u-grund/nwcommands/master"
. net install nwcommands
. nwinstall, all
```

The first two lines install just `nwinstall` itself and the landing help topics; `nwinstall,
all` then downloads everything else — every command, all help files, and every dialog box —
and installs them permanently. Add `nwinstall, permanently` to also add a "Network Analysis"
menu to Stata's own User menu.

See the [Installation & Setup](tutorials/01-installation-setup/) tutorial for a full walkthrough,
including options for computers without internet access or admin rights.

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
