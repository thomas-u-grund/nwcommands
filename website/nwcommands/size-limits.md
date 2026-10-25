---
title: "How large a network?"
parent: "nwcommands (core)"
nav_order: 2
description: "Which core commands are comfortable, workable or refused at which network size, from measured run times."
permalink: /nwcommands/size-limits/
---

# How large a network can I analyze?
{: .no_toc }

Short answer: **the core can build, save and describe a network of 100,000 nodes and a million ties.** What you can
*compute* on it depends on the command. Some commands finish in seconds at that size, some need minutes, and some
are stopped at once because their answer cannot fit into memory or would take hours. This page tells you which is
which, so that you do not find out by waiting.

1. TOC
{:toc}

## What "size" means here

All numbers on this page are measured, not promised. They come from running 123 commands (143 recipes) on random
networks of 1,000, 5,000, 10,000, 20,000 and 100,000 nodes, with about **10 ties per node** (1,000,000 ties at
100,000 nodes), in **Stata/BE** on a **Mac with 64 GB of memory** (version 3.3.0 of the core). Seconds are wall-clock
times on a computer that was also doing other work; repeat runs differed by up to about 10 percent.

- **Size is the number of nodes**, but the number of ties matters too. A network with 30 ties per node is
  slower than one with 10, in some commands much slower.
- **Stata/MP** (several cores) or a computer with less memory will give different numbers. The refusal
  thresholds below depend on the memory limit built into the commands (12 GB for an n-by-n result, 2 minutes for
  the estimated run time), not on your computer, so they stay the same; the times do not.
- **Real networks are not random networks.** Hubs, dense cores and heavy tails can make a command slower, and
  produce far more cliques, than a random network of the same size. Treat the "comfortable" column as a lower
  bound on the trouble you may meet, not a guarantee. Nothing here was tested on real networks of this size.

## The table

*Comfortable* means a few seconds; *workable* means seconds to minutes. "Refused" means the command stops at once with
a message (error code 484) and does nothing. Sizes are numbers of nodes.

| What you want to do | Comfortable | Workable | Refused at / why | What to do instead |
|---|---|---|---|---|
| Build, import, export, save and load a network (`nwfromedge`, `nwset`, `nwimport`, `nwexport`, `nwsave`, `nwuse`, `nwappend`, `nwtoedge, compress`) | 20,000 nodes: 0.6 to 2 s | 100,000 nodes: 3 to 14 s each, 0.6 to 1.4 GB | Not tried beyond 100,000 nodes | |
| Degrees, dyads, summary, components, k-core, PageRank, random walk, assortativity, bridges, brokerage, paths and neighbors, recode, dichotomize, drop, keep, subset, maximum flow, networks at a point in time | 100,000 nodes: 0.06 to 7 s | | Not tried beyond 100,000 nodes | |
| Clustering, community detection, ego networks, eigenvector centrality, shared neighbors, mixing, motifs, factions, `nwcug` (5 repetitions) | 20,000 nodes: up to 5 s | 100,000 nodes: 0.7 to 26 s | Not tried beyond 100,000 nodes | |
| Heavier counting: `nwtriads`, `nwclique`, `nwsimmelian`, `nwconstraint`, `nwburt` | 20,000 nodes: 2 to 20 s | 100,000 nodes: 46 to 104 s (`nwclique` 3.6 GB, `nwsimmelian` 5.7 GB, `nwconstraint` up to 6.9 GB) | Not tried beyond 100,000 nodes | Run on a sample or a component first |
| `nwcloseness`, `nwkatz` | 20,000 nodes: 10 s | About 63,000 nodes inside the 2-minute limit | Above about 63,000 nodes (100,000: estimated 5 minutes; one run with `force` took 302 s) | `nwdegree`, `nwpagerank`, or run on a part of the network (`nwsubset`) |
| `nwbetween` | 10,000 nodes: 8 s | 20,000 nodes: 29 s; about 36,000 inside the limit | Above about 36,000 nodes (100,000: estimated 15 minutes, not measured) | As above |
| `nwkcomponents`, `nwcohesion` | 10,000 nodes: 6 s | 20,000 nodes: 39 s and 27 s; about 31,000 and 40,000 inside the limit | Above about 31,000 / 40,000 nodes (100,000: estimated 43 and 13 minutes, not measured) | `nwcomponents`, `nwkcore`, or a part of the network |
| Results with one value per pair of nodes: `nwgeodesic`, `nwreach`, `nwlambda`, `nwexpand`, `nwcontext`, `nwreplace` | 10,000 nodes: 0.5 to 7 s | 20,000 nodes: 2 to 30 s | Above about 27,000 nodes (`nwcontext`, `nwreplace`: 22,000) because the result needs 8 bytes times n times n per matrix | `nwcloseness`, `nwcomponents`, `nwpath`, `nwaltergen`, or a part of the network |
| Similarity and correlation of pairs: `nwsimilar`, `nwdissimilar`, `nwsimindex`, `nwcorrelate`, `nwutility` | 5,000 nodes: 1 to 4 s | 10,000 nodes: 3 to 16 s | Above about 12,900 (`nwsimilar`, `nwcorrelate`), 13,700 (`nwdissimilar`), 17,300 (`nwsimindex`) or 19,400 (`nwutility`) nodes: several n-by-n matrices at once | `nwsubset`, `nwego`, or `nwtoedge, compress` |
| `nwqap` | 5,000 nodes: 10 s (5 permutations) | 10,000 nodes: 65 s (5 permutations) | Above 10,000 nodes: 15 matrices at once | A sample of the nodes; fewer permutations do not lift the memory limit |
| Cubic methods: `nwspectral`, `nwconcor`, `nwhierarchy` (and so `nwdendrogram`) | 1,000 nodes: 1.5 to 5 s | 3,000 nodes: 45 to 57 s; 5,000 nodes: `nwhierarchy` 169 s, `nwspectral` and `nwconcor` did not finish in 3 minutes | Above 6,000 nodes (cost grows with the cube) | A sample, or a subset of nodes |
| One row per pair: `nwtoedge` and `nw2toedge` without `compress`, `nwhomophily`, `nwcollapse` | 1,000 nodes: 6 to 9 s | 5,000 nodes: 20 s (`nwtoedge`), 62 s (`nwcollapse`), 78 s (`nwhomophily`) | Above about 7,000 nodes (more than 50,000,000 rows) | `nwtoedge, compress` lists only the existing ties |
| Maximal subgroups: `nwnclique`, `nwnclan`, `nwkplex` | Depends on the network, not only its size (see below) | | Stop themselves after 100,000 maximal subgroups or 60 seconds | `countonly`, `maxcliques()`; see below |
| Two-mode networks (`nw2fromedge`, `nw2set`, `nw2degree`, `nw2project`, `nwproject`, `nwmatching`, `nw2clustering`) | 10,000 nodes in the first mode (15,000 in total): 1 to 9 s | About 20,000 in total: 1.6 to 12 s, 3 to 5 GB | Above 20,000 nodes in total | Project onto one mode from the edge list, or analyze a part |
| Plots: `nwplot` | Circle layout, 10,000 nodes: 38 s (but unreadable) | Force-directed (`layout(kk)`), 5,000 nodes: 17 s | Circle layout above about 12,000 nodes; `kk` not measured above 5,000 | Plot a part (`nwsubset`, `nwego`, `nwkcore`) or export with `nwexport` |
| `nwload, xvars`, `nwtostata`, `nwvalidvars` | | | Stata's own limits: number of variables in your Stata (`nwload` refuses above 1,000 nodes without `force`), and the length of a macro | Do not load a large network as variables; the commands work without |

## Why a command is limited: three reasons

1. **The answer is a table with one cell per pair of nodes.** Distances between all pairs, reachability, similarity of
   all pairs, a QAP regression on all pairs: the result alone has n times n numbers. At 8 bytes each, 20,000
   nodes already mean 3.2 GB for *one* such matrix, and 100,000 nodes mean 80 GB. No clever programming changes
   that; only a smaller network does.
2. **The work grows with the square or the cube of the nodes.** Betweenness, closeness and the k-component and cohesion
   searches start a search from every node. Doubling the nodes makes them about four times slower (k-components:
   about six times). Spectral decomposition, CONCOR and hierarchical clustering grow with the cube: doubling the nodes
   makes them eight times slower.
3. **The number of results explodes.** Counting every maximal clique, n-clique, n-clan or k-plex produces more sets
   than there is memory for, even in modest networks. In a random network with 10 ties per node, `nwnclique` with `n(2)`
   was already stopped at 300 nodes, `nwkplex` with `k(2)` at 1,000 nodes, and `nwnclan` with `n(2)` at 5,000 nodes (and
   `nwclique` itself, the plain maximal cliques, took 75 s at 100,000 nodes). Whether these commands work depends on how clustered the network is, not on its size alone.

## What the refusal means

A refusal looks like this: the command says what it would have to hold in memory or how long it would run, gives an
alternative, and stops with error **r(484)**, usually in a fraction of a second. Nothing has been changed.

Many of these commands have an option **`force`** that runs the command anyway. Use it with care. For the commands with
a time guard (`nwbetween`, `nwcloseness`, `nwkatz`, `nwkcomponents`, `nwcohesion`), `force` means waiting for
minutes, or hours (and `nwcohesion` needed 2.9 GB at 20,000 nodes, so far more at 100,000). For the commands with a memory guard, **`force` can exhaust your computer's
memory**: Stata may be killed by the operating system and everything unsaved in the session is lost. Save your work first,
and do not use `force` on a computer you share.

## What to do when a command is refused

- **Work on a sample or on a part.** `nwsubset`, `nwego`, `nwkeepnodes` and `nwdropnodes` cut a large network down (at
  100,000 nodes in 1 to 3 seconds), and often the largest component is what you want to measure anyway (`nwcomponents`
  finds it).
- **Use a cheaper measure for the same idea.** Degree, PageRank, components and k-cores are linear in the number of ties
  and finish within seconds at 100,000 nodes.
- **For subgroups, count first.** `countonly` counts the sets without storing them; `maxcliques()` and `maxtime()` set
  your own stopping point. In a random network of 5,000 nodes, maximal 2-plexes can be counted in 2 seconds, but the
  matrix of the sets cannot be built.
- **Keep ties as a list, not as a table.** `nwtoedge, compress` lists only the existing ties; the dense forms (one row
  per pair of nodes) do not work above about 7,000 nodes.
- **Two-mode networks:** the whole network is stored as one matrix over both modes, so the limit is on the number of
  nodes of both modes together (20,000). For larger data, project onto one mode before importing.

## What was tested, and what was not

- **Networks:** random directed networks with about 10 ties per node (undirected ones: 10 ties drawn per node;
  two-mode: N and N/2 nodes). No real networks of this size.
- **Procedure:** each command was run on networks of 1,000, 5,000, 10,000, 20,000 and 100,000 nodes with a limit of
  180 to 300 seconds per run and a memory cap of 12 GB. Results of the commands that finished were
  compared with the known structure of the generated network (number of nodes and ties, degrees, components, distances
  and similar); no wrong result was found.
- **Not measured:** networks above 100,000 nodes; commands marked "not tried"; denser networks than 10 ties per node;
  Stata/MP; Windows and Linux (the measurements are from macOS). Where this page gives an estimated time (for
  example, 15 minutes for `nwbetween` at 100,000 nodes), it is an estimate from smaller runs, not a measurement.
- **Small timings are noisy.** Differences of a few seconds between neighboring sizes should not be read as a trend (some
  1,000-node runs were slower than the same command at 5,000 nodes).

The limits of each command are also in its help file, and `help nwintro` has the same numbers in the section on
network size.

## The model packages

The model packages have their own limits, which depend on the number of nodes, waves and effects and not only
on size. They are not covered here; see [nwsaom](../../nwsaom/), [nwergm](../../nwergm/),
[nwdynam](../../nwdynam/) and [nwrem](../../nwrem/) for what each says about size.
