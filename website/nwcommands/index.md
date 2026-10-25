---
title: "nwcommands (core)"
nav_order: 3
has_children: true
description: "The nwcommands core package: network import, generation, description, analysis and visualization in Stata."
permalink: /nwcommands/
---

# nwcommands (core)
{: .no_toc }

The core package, version 3.5.1, handles networks in Stata: it imports and exports them, generates
them, describes and analyzes them, and plots them. It is the base for the model packages
([nwsaom](../nwsaom/), [nwergm](../nwergm/), [nwdynam](../nwdynam/), [nwrem](../nwrem/)), which need
it but are installed separately.

## Install

```stata
. net install nwcommands, from("https://raw.githubusercontent.com/thomas-u-grund/nwcommands/main/")
. nwinstall, all
```

`nwinstall, all` downloads every command, all help files and every dialog box. Add `nwinstall, gui`
for a "Network Analysis" menu in Stata. `nwinstall, models` installs the four model packages.
`nwversion` shows the core version and which model packages are installed. See the
[Installation & Setup](../tutorials/01-installation-setup/) tutorial for details.

## Where to go

- **Tutorials** ([all tutorials](../tutorials/)): installation, core concepts, importing and exporting,
  visualization, generating and manipulating networks, centrality, paths and ego networks.
- **Command reference** ([all commands](../reference/)): every command with its syntax and options.
- **Size limits** ([how large a network can be](size-limits/)): which commands finish in seconds, which need
  minutes and which are refused at which number of nodes.
- **Model packages**: the statistical models have their own sections in the menu: [nwsaom](../nwsaom/)
  (stochastic actor-oriented models), [nwergm](../nwergm/) (exponential random graph models),
  [nwdynam](../nwdynam/) (dynamic network actor models) and [nwrem](../nwrem/) (relational event models).

## What the core contains

- **Import / export**: edgelists, adjacency matrices, UCINET/Pajek-style formats.
- **Generators**: random, small-world, preferential-attachment, lattice and expression-based networks.
- **Structural analysis**: centrality, components, cliques, k-cores, cohesive subgroups, community
  detection, structural equivalence, QAP and more.
- **Visualization**: static plots and network movies.
- **Dialog boxes**: 120 dialogs for nearly every command.

Every command works alongside ordinary Stata variables. Two backends, a sparse native Mata
representation and compiled C kernels, are chosen automatically.

## Version and license

The core is version 3.5.1 (25 October 2026). It is free software under the GNU General Public License,
version 3; the source is on [GitHub](https://github.com/thomas-u-grund/nwcommands). The model packages
are separate packages under the same license.
