---
title: "nwcommands tutorials"
description: "Worked, step-by-step tutorials for nwcommands, with real Stata output."
nav_exclude: true
---

# nwcommands tutorials

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

4. [Visualization](04-visualization/) — plot styling, interactive views and the bring-back of a layout, network movies
5. [Generating Networks](05-generating-networks/) — random, small-world,
   preferential-attachment, and lattice networks, useful for teaching and simulation
6. [Manipulating Networks](06-manipulating-networks/) — subsetting, collapsing, symmetrizing,
   recoding, dichotomizing

## Analysis

7. [Centrality](07-centrality/) — degree, betweenness, closeness, eigenvector, PageRank, Katz
8. [Paths & Ego Networks](08-paths-ego-networks/) — geodesics, reachability, ego-network
   extraction
9. [Two-mode Networks](11-two-mode-networks/) — affiliation data (people and events or companies):
   degree, projection to one mode, components, communities (bipartite modularity), nestedness, null models, saving and
   exchanging, what stops on a two-mode network, plotting; the data sets `davis` and `ftdirectors_se`

## Longitudinal models

10. [Intro to Longitudinal Network Models](10-intro-longitudinal-models/) — a first look at
   stochastic actor-oriented models (`nwsaom`), relational event models (`nwrem`) and dynamic network
   actor models (`nwdynam`), with their install steps

## Statistical models

The statistical models are separate packages with their own sections, each with installation notes,
a comparison with the R package it follows and worked tutorials: [nwsaom](../nwsaom/) (SAOM),
[nwergm](../nwergm/) (ERGM; the introduction to ERGM that used to be Tutorial 9 is now the first
tutorial of that section), [nwdynam](../nwdynam/) (DyNAM) and [nwrem](../nwrem/) (REM).
