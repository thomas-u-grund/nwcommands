---
title: "nwcommands tutorials"
description: "Nineteen worked, step-by-step tutorials for nwcommands, in a logical order, with real Stata output."
nav_exclude: true
---

# nwcommands tutorials

Short, worked walkthroughs — plain-language explanation first, then a real Stata command,
then the actual console output that command produces. The tutorials are numbered in the order in
which they build on each other, so you can read them from the top; each one also stands alone. If you'd
rather look up a specific command directly, see the [command reference](../reference/).

## Getting started

- [Tutorial 1: Installation & Setup](01-installation-setup/) — installing nwcommands, the "Network
   Analysis" menu, updating vs. pinning a version
- [Tutorial 2: Core Concepts](02-core-concepts/) — what a "network" is in nwcommands, the current-network
   model, working alongside ordinary Stata variables
- [Tutorial 3: Importing & Exporting](03-importing-exporting/) — edgelists, UCINET/Pajek formats, and
   built-in example datasets
- [Tutorial 4: Reproducible Workflow](04-reproducible-workflow/) — a complete do-file: ties and people from CSV
   files, node attributes, results as variables, saving the project, handing the ties to other programs

## Working with networks

- [Tutorial 5: Visualization](05-visualization/) — plot styling, interactive views and the bring-back of a layout, network movies
- [Tutorial 6: Generating Networks](06-generating-networks/) — random, small-world,
   preferential-attachment, and lattice networks, useful for teaching and simulation
- [Tutorial 7: Manipulating Networks](07-manipulating-networks/) — subsetting, collapsing, symmetrizing,
   recoding, dichotomizing

## Describing networks

- [Tutorial 8: Centrality](08-centrality/) — degree, betweenness, closeness, eigenvector, PageRank, Katz
- [Tutorial 9: Paths & Ego Networks](09-paths-ego-networks/) — geodesics, reachability, ego-network
   extraction
- [Tutorial 10: Cohesion & Subgroups](10-cohesion-subgroups/) — components, k-cores, cliques, k-plexes,
   communities, a fixed number of groups, core and periphery: what each notion means and which command to use
- [Tutorial 11: Brokerage & Structural Holes](11-brokerage/) — Burt's measures, bridges, Gould-Fernandez roles,
   Simmelian ties
- [Tutorial 12: Triads, Dyads & Motifs](12-triads-motifs/) — the dyad and triad census, clustering and
   transitivity, four-node motifs, structural balance
- [Tutorial 13: Positions & Equivalence](13-positions-equivalence/) — similarity of tie profiles, hierarchical
   clustering and dendrogram, CONCOR, spectral partition
- [Tutorial 14: Homophily, Assortativity & Mixing](14-homophily-mixing/) — do similar nodes connect?
   assortativity, mixing tables and the E-I index, correlation of two networks

## Other kinds of networks

- [Tutorial 15: Two-Mode Networks](15-two-mode-networks/) — affiliation data (people and events or companies):
   degree, projection to one mode, components, communities (bipartite modularity), nestedness, null models, saving and
   exchanging, what stops on a two-mode network, plotting; the data sets `davis` and `ftdirectors_se`
- [Tutorial 16: Valued Networks](16-valued-networks/) — ties with numbers: strength, weighted distances and
   clustering, the `binary` option, dichotomizing
- [Tutorial 17: Networks over Time](17-networks-over-time/) — turnover between waves, correlation between waves,
   slicing a temporal edge list into snapshots

## Testing and models

- [Tutorial 18: Testing Hypotheses about Networks](18-testing/) — conditional uniform graph tests (`nwcug`), QAP
   correlation and QAP regression
- [Tutorial 19: Longitudinal Models: An Overview](19-intro-longitudinal-models/) — a first look at
   stochastic actor-oriented models (`nwsaom`), relational event models (`nwrem`) and dynamic network
   actor models (`nwdynam`), with their install steps

The statistical models are separate packages with their own sections, each with installation notes,
a comparison with the R package it follows and worked tutorials: [nwsaom](../nwsaom/) (SAOM),
[nwergm](../nwergm/) (ERGM; its first tutorial, "A first ERGM", is the first tutorial of that section),
[nwdynam](../nwdynam/) (DyNAM) and [nwrem](../nwrem/) (REM).

## Reference pages

Three reference pages go with these tutorials: [valued networks](/nwcommands/valued-networks/) (when a
network counts as valued and which commands then use the tie values), [two-mode networks](/nwcommands/two-mode/)
and [network types](/nwcommands/network-types/) (what every command does with binary, valued, two-mode and directed networks).
