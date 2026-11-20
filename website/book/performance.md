---
title: "Performance and network size"
parent: "Book companion"
nav_order: 3
description: "Which nwcommands commands are comfortable, workable or refused at which network size, by command family (Appendix A of the book)."
permalink: /book/performance/
---

# Performance and network size
{: .no_toc }

This is the table by command family that goes with Appendix A of the book *Network Analysis with Stata*. The appendix gives the decision table by network size and explains why commands are limited; here every family of commands is listed with the sizes at which it is comfortable, workable or refused.

"Comfortable" means a few seconds; "workable" means seconds to minutes; "refused" means the command stops at once with a message (error code 484) and does nothing. Sizes are numbers of nodes. Measured on random networks with about 10 ties per node, in Stata/BE on a Mac with 64 GB of memory; times marked "estimated" are extrapolated from smaller runs.

| Task | Comfortable | Workable | Refused at / why | Instead |
|---|---|---|---|---|
| Build, import, export, save, load (`nwfromedge`, `nwset`, `nwimport`, `nwexport`, `nwsave`, `nwuse`, `nwappend`, `nwtoedge, compress`) | 20,000: 0.6 to 2 s | 100,000: 3 to 14 s each, 0.6 to 1.4 GB | Not tried above 100,000 |  |
| Degree, dyads, summary, components, k-core, PageRank, random walk, assortativity, bridges, brokerage, paths, neighbors, recode, dichotomize, drop, keep, subset, maximum flow | 100,000: 0.06 to 7 s |  | Not tried above 100,000 |  |
| Clustering, community detection, ego networks, eigenvector centrality, shared neighbors, mixing, motifs, factions, `nwcug` (5 repetitions) | 20,000: up to 5 s | 100,000: 0.7 to 26 s | Not tried above 100,000 |  |
| `nwtriads`, `nwclique`, `nwsimmelian`, `nwconstraint`, `nwburt` | 20,000: 3 to 20 s | 100,000: 46 to 104 s (up to 6.9 GB) | Not tried above 100,000 | A sample or a component first |
| `nwcloseness`, `nwkatz` | 20,000: 10 s | Up to about 63,000 inside the 2-minute limit | Above about 63,000 (100,000: estimated 5 min; one run with `force`: 302 s) | `nwdegree`, `nwpagerank`, `nwsubset` |
| `nwbetween` | 10,000: 8 s | 20,000: 29 s; inside the limit up to about 36,000 | Above about 36,000 (100,000: about 15 min, estimated, not measured) | As above |
| `nwkcomponents`, `nwcohesion` | 10,000: 6 s | 20,000: 39 s and 27 s; inside the limit up to about 31,000 and 40,000 | Above those sizes (100,000: about 43 and 13 min, estimated, not measured) | `nwcomponents`, `nwkcore`, a part of the network |
| One value per pair: `nwgeodesic`, `nwreach`, `nwlambda`, `nwexpand`, `nwcontext`, `nwreplace` | 10,000: 0.5 to 7 s | 20,000: 2 to 30 s | Above about 27,000 (`nwcontext`, `nwreplace`: 22,000): 8 n² bytes per matrix | `nwcloseness`, `nwcomponents`, `nwpath`, `nwaltergen`, a part of the network |
| Pairs compared: `nwsimilar`, `nwdissimilar`, `nwsimindex`, `nwcorrelate`, `nwutility` | 5,000: 1 to 4 s | 10,000: 3 to 16 s | Above about 12,900 (`nwsimilar`, `nwcorrelate`), 13,700 (`nwdissimilar`), 17,300 (`nwsimindex`), 19,400 (`nwutility`): several matrices at once | `nwsubset`, `nwego`, `nwtoedge, compress` |
| `nwqap` | 5,000: 10 s (5 permutations) | 10,000: 65 s (5 permutations) | Above 10,000: 15 matrices at once | A sample of the nodes |
| Cubic (time grows with the cube of the nodes): `nwspectral`, `nwconcor`, `nwhierarchy`, `nwdendrogram` | 1,000: 1.5 to 5 s | 3,000: 45 to 57 s; 5,000: `nwhierarchy` 169 s, `nwspectral` and `nwconcor` not finished in 3 min | Above 6,000 | A sample or a subset |
| One row per pair: `nwtoedge` with `allpairs`, `nw2toedge` with `allpairs`, `nwhomophily`, `nwcollapse` | 1,000: 6 to 9 s | 5,000: 20 s (`nwtoedge`), 62 s (`nwcollapse`), 78 s (`nwhomophily`) | Above about 7,000 (more than 50,000,000 rows) | `nwtoedge, compress` |
| `nwnclique`, `nwnclan`, `nwkplex` | Depends on the network |  | Stop themselves after 100,000 maximal subgroups or 60 s | `countonly`, `maxcliques()` |
| Two-mode (`nw2fromedge`, `nw2set`, `nwdegree`, `nw2project`, `nwproject`, `nwmatching`, `nwclustering`) | 10,000 in the first mode (15,000 in all): 1 to 9 s | About 20,000 in all: 1.6 to 12 s, 3 to 5 GB | Above 20,000 in all | Project from the edge list; a part of the network |
| `nwplot` | Circle layout, 10,000: 38 s (unreadable) | Force-directed, 5,000: 17 s | Circle layout above about 12,000; force-directed not measured above 5,000 | A part of the network; `nwexport` |
| `nwload, xvars`, `nwtostata`, `nwvalidvars` |  |  | Stata's own limits: variables in your Stata (`nwload` refuses above 1,000 nodes without `force`) and macro length | Do not load a large network as variables |
