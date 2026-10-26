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
Nine commands (`nwclustering`, `nwtriads`, `nwevcent`, `nwburt`, `nwsimmelian`, `nwconstraint`, `nwpagerank`,
`nwclique` and `nwkcomponents` with `k(2)`) have been made faster since that audit; the table marks them, and
the section [Faster commands](#faster-commands) gives their times before and after.

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
| Clustering, community detection, ego networks, eigenvector centrality, shared neighbors, mixing, motifs, factions, `nwcug` (5 repetitions) | 20,000 nodes: up to 5 s | 100,000 nodes: 0.7 to 26 s in the audit; `nwclustering` (26.1 s then) and `nwevcent` (13.7 s then) now take 0.7 s and 0.5 s; the others were not measured again | Not tried beyond 100,000 nodes | |
| Heavier counting: `nwtriads`, `nwburt`, `nwsimmelian`, `nwclique` (these now run in the compiled plugin) | 5,000 nodes: 0.03 to 0.1 s; 20,000 nodes: `nwclique` 1.0 s | 100,000 nodes: `nwburt` 0.2 s, `nwsimmelian` 0.8 s, `nwtriads` 1.0 s; `nwclique` search 0.6 s, but the result matrix takes longer to store (see below); with `nomatrix` 100,000 nodes take 0.26 s | Not tried beyond 100,000 nodes | Run on a sample or a component first |
| `nwconstraint` | 5,000 nodes: 0.4 s | 100,000 nodes: 10.4 s in the audit; 2.2 s (undirected) and 0.70 s (directed) after the later speed round, with 5 ties drawn per node | Not tried beyond 100,000 nodes; above 2,000 nodes only `name()` and `replace` are accepted | Run on a sample or a component first |
| `nwcloseness`, `nwkatz` | 20,000 nodes: 10 s | About 63,000 nodes inside the 2-minute limit | Above about 63,000 nodes (100,000: estimated 5 minutes; one run with `force` took 302 s) | `nwdegree`, `nwpagerank`, or run on a part of the network (`nwsubset`) |
| `nwbetween` | 10,000 nodes: 8 s | 20,000 nodes: 29 s; about 36,000 inside the limit | Above about 36,000 nodes (100,000: estimated 15 minutes, not measured) | As above |
| Valued networks (tie values used, version 3.7.0 with the new plugin): `nwbetween`, `nwcloseness` | 1,000 nodes: 0.13 s (`nwbetween`), 0.15 s (`nwcloseness`) | 10,000 nodes: 14.5 s (`nwbetween`), 14.3 s (`nwcloseness`), with 3 ties drawn per node | Without the new plugin (or without `force`) a valued network of more than 100 nodes stops with error 198 in `nwcloseness` and `nwgeodesic` | Update the plugin with `nwinstall`; `binary` gives the hop count |
| Two-mode networks with tie values or in a community search: `nwcommunity`, `nwmatching` (valued), `nwpermute, swap` | The 5,092 + 455 directors: `nwcommunity` 0.09 s, `nwmatching` 0.2 s, `nwpermute, swap` with 100,000 attempts 0.02 s | | | |
| `nwkcomponents` with `k(2)` | 5,000 nodes: 0.1 s; 20,000 nodes: 1.0 s | 100,000 nodes: about 60 s with `force` (most of it is Stata storing the result matrix) | Above about 31,000 nodes without `force` (the guard is unchanged, although `k(2)` is now much faster) | `nwcomponents`, `nwkcore`, or a part of the network |
| `nwcohesion` (and `nwkcomponents` with other values of `k`, not measured) | 10,000 nodes: 6 s | 20,000 nodes: 27 s for `nwcohesion`; about 40,000 inside the limit | Above about 40,000 nodes (100,000: estimated 13 minutes, not measured) | `nwcomponents`, `nwkcore`, or a part of the network |
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
   `nwclique` itself, the plain maximal cliques, took 75 s at 100,000 nodes in the audit; the search now takes 0.6 s
   there, and what remains is storing the result). Whether these commands work depends on how clustered the network is, not on its size alone.

## Faster commands

Nine commands now run their main loop in the compiled graph plugin that `nwinstall` fetches for your platform.
Their results are the same as before (counts exactly; centralities to the last digits; the differences measured
were 1e-15 relative or smaller). Where the plugin of your platform is older or missing, the commands use the Mata code,
and the times of the earlier audit apply. The Mata code is also used in a few cases (`nwclustering` for the weighted
measures, `nwtriads` and `nwsimmelian` and `nwclique` for networks with self-loops, `nwburt` with `dyadredundancy` and
`dyadconstraint`, `nwconstraint` for two-mode networks).

Seconds, before / after, in Stata/BE on a Mac, random networks with 10 ties per node (directed for `nwpagerank`,
undirected for `nwclique`, `nwburt`, `nwsimmelian` and `nwconstraint`; `nwclustering`, `nwtriads` and `nwevcent` on random networks of the same density):

| Command | 5,000 nodes | 20,000 nodes | 100,000 nodes |
|---|---|---|---|
| `nwclustering` (binary) | 1.15 / 0.06 | | 26.1 / 0.7 |
| `nwtriads` | 3.4 / 0.08 | | 73 / 1.0 |
| `nwevcent` | 0.69 / 0.05 | | 13.7 / 0.5 |
| `nwburt` | 1.18 / 0.03 | | 25.6 / 0.17 |
| `nwsimmelian` | 0.51 / 0.08 | | 11.6 / 0.75 |
| `nwconstraint` | 0.58 / 0.44 | | 13.3 / 10.4; later 9.7 / 2.2 (5 ties drawn per node) |
| `nwpagerank` | 0.12 / 0.03 | | 1.9 / 0.3 |
| `nwclique` (minsize 3) | 0.35 / 0.10 | 3.3 / 1.0 | search alone 45 / 0.6 |
| `nwkcomponents` (`k(2)`) | 1.8 / 0.1 | 67 / 1.0 | over 120 / about 60 |

Two limits remain, and they are Stata's, not the kernels':

- **`nwclique` and `nwkcomponents`:** from about 40,000 nodes on, most of the time is Stata's `st_matrix()` storing
  `r(clique_matrix)` or `r(kcomp_matrix)`; the time grows with the square of the number of columns, whatever the number
  of rows. This is why `nwkcomponents` still takes about a minute at 100,000 nodes.
- **`nwclique` with `nomatrix`:** the matrix is not built or stored, and the variable and `r(cliques)` stay the same: 100,000 nodes take 0.26 s instead of 36.7 s (random network with 5 ties drawn per node; `nwkcomponents` has the same option).
- **`nwconstraint`:** after the speed round of the Mata library, 100,000 nodes take 2.2 s for an undirected and 0.70 s for a directed network (5 ties drawn per node; 9.7 and 2.9 s before).

### Valued and two-mode networks (version 3.7.0)

Version 3.7.0 adds compiled kernels for commands that work with tie values or on two-mode networks. Seconds of the complete command,
Stata/BE 18 on an Apple-silicon Mac, random sparse valued undirected networks with 3 ties per node (values 1 to 9); "Mata" is the code of
version 3.6.0, which is still used where the plugin of your platform is older. Results are equal to the Mata code (PageRank and betweenness to 1e-9)
and to R's igraph.

| Command | Input | Mata | Plugin |
|---|---|---|---|
| `nwbetween` (valued) | 300 nodes | 3.28 | 0.020 |
| | 1,000 nodes | 110.6 | 0.13 |
| | 5,000 nodes | not run (n-by-n work space per source) | 3.4 |
| | 10,000 nodes | not run | 14.5 |
| `nwcloseness` (valued) | 300 nodes | 3.18 (with `force`) | 0.024 |
| | 1,000 / 5,000 / 10,000 nodes | not run | 0.15 / 3.4 / 14.3 |
| `nwgeodesic` (valued), distance matrix | 1,000 nodes | not run | 0.14 |
| `nwcommunity` (two-mode, 30 starts) | Southern women (32 nodes) | 0.026 | 0.007 |
| | 5,092 + 455 directors, 5,669 ties | 2.38 | 0.088 |
| `nwmatching` (valued, two-mode) | 100 + 100 nodes | 0.025 | 0.008 |
| | 300 + 300 nodes | 0.33 | 0.013 |
| | 455 + 5,092 nodes | not possible (dense matrix) | 0.21 |
| `nwpermute, swap` (100,000 attempts) | 5,092 + 455 directors | 0.138 | 0.020 |
| `nwpagerank` (valued) | 1,000 / 5,000 / 10,000 nodes | 0.026 / 0.046 / 0.087 | 0.013 / 0.029 / 0.049 |

`nwbetween` on a valued network was the bottleneck: the Mata routine allocates an n-by-n work matrix for every source node. Weighted PageRank and tie
swapping were already fast in Mata; the plugin adds a small factor and avoids the n-by-n matrix. The random starting orders of the two-mode search and of
the tie swapping come from a generator of their own, so the same `set seed` gives the same result on every platform with the new plugin, but not the
draws of the Mata code; Barber's Q is equal on the Southern women (0.3455) and the same within the run-to-run variation on the directors.

Nothing else on this page was measured again. In particular, `nwbetween` and `nwcloseness` on binary networks, `nwkatz` and the commands with
an n-by-n result are as limited as before.

### Bipartite motifs (version 3.8.0)

`nwmotifs` on a two-mode network (the command `nw2motifs`) counts the 17 bipartite motifs of two to five nodes and the positions of every node in them in the compiled plugin, without matrices of the size of the network. Seconds of the complete command, Stata/BE 18 on an Apple-silicon Mac, the Swedish directors (5,092 + 455 nodes, 5,669 ties); `bmotif` 2.0.2 in R needs 54 s for `mcount` and `node_positions` of the five-node set together and cannot do the six-node set on this network. The counts are equal to `bmotif`.

| Input | `nwmotifs` (motif table) | with the node positions (`generate()`) | R `bmotif` (table and positions) |
|---|---|---|---|
| Swedish directors, motifs up to five nodes | 0.015 | 0.04 | 54 |
| Swedish directors, with `sixnode` | | 0.05 | not possible (memory) |

The node positions are stored in up to 46 (148 with `sixnode`) variables, one per position, so the output of the directors needs 5,547 observations times 46 variables; `matrix()` is refused above the matrix limit of your Stata flavor (`c(max_matdim)`).

## Compared with R's igraph

R's igraph is the usual yardstick for network software, so this section compares the two. It is based on one
benchmark run, so read it as what that run shows and no more.

**Setup.** Random directed networks of 1,000, 5,000, 20,000 and 100,000 nodes, every node drawing 10 distinct targets
(10,000 to 1,000,000 ties), the same edge list read by both programs; the undirected variant is the same list with
reciprocal pairs merged. nwcommands 3.3.1 (that is, **before** the speed-ups above) in Stata 18 BE; R 4.6.0 with
igraph 2.3.2; Apple M5 Pro, 64 GB. Medians of 3 repetitions up to 20,000 nodes, one run at 100,000. The computer was not
idle (two other long R jobs were running on separate cores), so timings carry noise: the same command varied from
12.5 to 36 seconds in three repetitions at 20,000 nodes. The nwcommands times include the command's own overhead and
writing the result into the data set; the igraph times are the R function call and nothing else, so the comparison
favors igraph by a few milliseconds and by the cost of writing results.

**Same numbers.** On the measures compared, nwcommands gives the same numbers as igraph (checked per node at all sizes
unless noted):

- degree, number of components and coreness (k-core): identical;
- local clustering: equal to 1e-9 or better; global transitivity: identical to 14 digits;
- betweenness (undirected, and directed with `nosym`) and closeness: the same values up to about 1e-7 relative error,
  because nwcommands stores betweenness in single precision; the closeness is igraph's normalized closeness. Note that
  `nwcloseness` and `nwbetween` symmetrize a directed network by default;
- PageRank (damping .85): largest difference 1e-11;
- triad census: all 16 counts identical, checked at 1,000 and 5,000 nodes only;
- mean distance and diameter of all-pairs geodesics: identical at 1,000 and 20,000 nodes. When some pairs are not
  connected, igraph returns `Inf` and `nwgeodesic` reports `-1` and the number of unconnected pairs, a different
  convention;
- eigenvector centrality: the same ranking (correlation 1) on a different scale, so compare ranks or rescale;
- Louvain communities cannot be compared value for value (the method is randomized). Scored by the same modularity
  function, the partitions were of the same quality within the run-to-run variation (for example 0.1767 against 0.1831 at
  20,000 nodes, 0.1604 against 0.1595 at 100,000), on random networks that have no real community structure.

**Speed, seconds (nwcommands 3.3.1 / igraph).**

| Measure | 5,000 nodes | 20,000 nodes | 100,000 nodes |
|---|---|---|---|
| Betweenness (undirected) | 1.74 / 2.00 | 28.7 / 33.4 | refused by the guard / over 120 s |
| Betweenness (directed, `nosym`) | 0.90 / 1.19 | 18.5 / 23.5 | refused / over 120 s |
| Closeness (undirected) | 0.66 / 0.61 | 10.2 / 12.0 | refused / over 120 s |
| All-pairs geodesics (directed) | 0.60 / 0.64 | 10.7 / 12.0 | refused / not run (an 80 GB matrix) |
| Louvain communities | 0.13 / 0.095 | 0.56 / 0.46 | 6.98 / 23.6 (one run each) |
| Build the network from an edge list | 0.12 / 0.013 | 0.47 / 0.056 | 2.77 / 0.38 |
| Degree | 0.022 / 0.001 | 0.073 / 0.001 | 0.30 / 0.005 |
| Components | 0.019 / 0.001 | 0.066 / 0.001 | 0.27 / 0.019 |
| Coreness (k-core) | 0.026 / 0.001 | 0.10 / 0.004 | 0.48 / 0.023 |
| PageRank | 0.11 / 0.005 | 0.40 / 0.020 | 1.80 / 0.11 |
| Clustering | 1.12 / 0.003 | 4.77 / 0.013 | 29.3 / 0.083 |
| Eigenvector centrality | 0.64 / 0.007 | 2.63 / 0.025 | 12.9 / 0.16 |
| Triad census | 3.11 / 0.034 | 12.5 / 0.14 | over 120 / 0.88 |

**What this shows.**

- For the measures that start a search from every node (betweenness, closeness, all-pairs distances), nwcommands ran at
  about igraph's speed from 5,000 to 20,000 nodes (ratios 0.8 to 1.1). At 1,000 nodes igraph was faster by a factor of
  1.4 to 2.8, where the fixed cost of a Stata command shows. At 100,000 nodes neither program finished betweenness or
  closeness within 120 seconds; nwcommands refuses at once, as designed.
- On many other measures nwcommands was slower, by factors from about 6 to about 370 in this run: building the network,
  degree, components, coreness, PageRank, clustering, eigenvector centrality and the triad census, and Louvain by 1.2 to
  1.6 up to 20,000 nodes. In absolute terms the linear-time measures are still a few seconds at a million ties. Part of the
  gap is Stata overhead and writing results, which R's functions do not do here.
- **These ratios are from before the speed-ups of this release.** Clustering, the triad census and eigenvector
  centrality are the largest ratios in the table; with the compiled kernels `nwclustering` takes 0.7 s, `nwtriads` 1.0 s and
  `nwevcent` 0.5 s at 100,000 nodes (the [table above](#faster-commands), measured on a different random network and not
  in the same run as igraph). The comparison with igraph has not been repeated with the new code, so no new ratios are
  given here.
- igraph can compute distances from a sample of source nodes (0.4 s for 100 sources at 100,000 nodes in this run);
  nwcommands has no such option.

**What we claim, and what we do not.** We claim that the commands above give the same results as igraph on these measures
and that, for betweenness, closeness and all-pairs distances at 5,000 to 20,000 nodes, the run times in this benchmark
were close to igraph's. We do not claim that nwcommands is as fast as R in general: it was slower than igraph on most
of the measures compared, as the table shows. Not tested: weighted networks, undirected networks for most measures,
other computers, Windows and Linux, Stata/MP, R packages that use several cores, memory use, other software
(NetworkX, graph-tool and so on) and anything beyond the measures listed.

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
