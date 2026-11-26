---
title: "nwcommands: more topics"
parent: "Tutorials"
has_children: true
has_toc: false
nav_order: 3
permalink: /tutorials/nwcommands-more/
description: "Two-mode and valued networks, networks over time, testing hypotheses, a first look at models, and programming in Mata."
---

# nwcommands: more topics
{: .no_toc }

Two-mode and valued networks, networks over time, testing hypotheses, a first look at models, and programming in Mata. These tutorials use the core package, [nwcommands](/nwcommands/).

- [Tutorial 15: Two-Mode Networks](../15-two-mode-networks/) — affiliation data (people and events or companies):
   degree, projection to one mode, components, communities (bipartite modularity), nestedness, null models, saving and
   exchanging, what stops on a two-mode network, plotting; the data sets `davis` and `ftdirectors_se`
- [Tutorial 16: Valued Networks](../16-valued-networks/) — ties with numbers: strength, weighted distances and
   clustering, the `binary` option, dichotomizing
- [Tutorial 17: Networks over Time](../17-networks-over-time/) — turnover between waves, correlation between waves,
   slicing a temporal edge list into snapshots
- [Tutorial 18: Testing Hypotheses about Networks](../18-testing/) — conditional uniform graph tests (`nwcug`), QAP
   correlation and QAP regression
- [Tutorial 19: Longitudinal Models: An Overview](../19-intro-longitudinal-models/) — a first look at
   stochastic actor-oriented models (`nwsaom`), relational event models (`nwrem`) and dynamic network
   actor models (`nwdynam`), with their install steps
- [Tutorial 20: Programming with Mata](../20-programming-mata-bridge/) — moving a network into Mata, computing a
   measure of your own and returning it as variables and networks (`nwtomata`, `nwset, mat()`)
- [Tutorial 21: Reading Networks in Mata with the nwapi Functions](../21-programming-mata-internals/) — reading
   the networks in memory from your own Mata code: properties, the adjacency matrix, the edge list, degrees
   and neighbors (`nwapi_*()`)
