---
title: Tutorials
nav_order: 2
has_children: true
description: "Worked, step-by-step tutorials for nwcommands, with real Stata output."
---

# Tutorials

Short, worked walkthroughs — plain-language explanation first, then a real Stata command,
then the actual console output that command produces. If you'd rather look up a specific
command directly, see the [command reference](../reference/).

## Foundations

1. [Installation & Setup](01-installation-setup/) — installing nwcommands, the "Network
   Analysis" menu, updating vs. pinning a version
2. [Core Concepts](02-core-concepts/) — what a "network" is in nwcommands, the current-network
   model, working alongside ordinary Stata variables
3. [Importing & Exporting](03-importing-exporting/) — edgelists, UCINET/Pajek formats, and
   built-in example datasets

## Working with networks

4. [Visualization](04-visualization/) — plot styling, network movies
5. [Generating Networks](05-generating-networks/) — random, small-world,
   preferential-attachment, and lattice networks, useful for teaching and simulation
6. [Manipulating Networks](06-manipulating-networks/) — subsetting, collapsing, symmetrizing,
   recoding, dichotomizing

## Analysis

7. [Centrality](07-centrality/) — degree, betweenness, closeness, eigenvector, PageRank, Katz
8. [Paths & Ego Networks](08-paths-ego-networks/) — geodesics, reachability, ego-network
   extraction

## Statistical modeling

9. [Intro to ERGM in Stata](09-intro-ergm/) — what an exponential-family random graph model is,
   and a minimal `nwergm` example
10. [Intro to Longitudinal Network Models](10-intro-longitudinal-models/) — a conceptual
    orientation to stochastic actor-oriented models (`nwsaom`) and relational event models
    (`nwrem`)
