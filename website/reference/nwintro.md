---
title: "nwintro"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
---

# `nwintro`

## Contents

**SectionDescription**

- hline 46
- [**[NW-1.1]****Introduction**](nwintro)
- [**[NW-1.2]****Required software**](nwintro)
- [**[NW-1.3]****Network concepts similar to Stata**](nwintro)
- [**[NW-1.4]****Network commands similar to Stata**](nwintro)
- [**[NW-1.5]****Statistical network models**](nwintro)
- [**[NW-1.6]****Questions, bugs and getting involved**](nwintro)
- [**[NW-1.7]****Citation**](nwintro)
- [**[NW-1.8]****Network size and speed**](nwintro)

## Introduction

nwcommands brings network analysis to Stata. Tutorials, data sets, manuals and news are at

browse "https://nwcommands.org"

Network analysis studies the relationships (ties) between units, such as friendship, advice or trust between people, or alliances between organizations, and the structure that these relationships form together. It is not limited to social units: any relational data, from genes to words, can be analyzed as a network. Unlike most statistical approaches, network analysis treats the dependence between units as the object of study.

A network G = (V,E) is a set of nodes *V* and a set of ties *E* between pairs (dyads) of nodes *i* and *j*. It can be stored as an adjacency matrix *M* with one row and one column per node: *M_ij* = 0 when there is no tie from *i* to *j*, and *M_ij* = 1 (or, in a valued network, the value of the tie) when there is one.

The core package [nwcommands](nwcommands) has 134 commands. They [import, export, load and save](nwtopical), [generate](nwtopical), [manipulate](nwtopical), [describe](nwtopical), [analyze](nwtopical) and [plot and animate](nwtopical) networks: centrality, cohesion and subgroups, communities, positions and roles, paths and flows, homophily and mixing, and tests such as QAP and conditional uniform graph tests. You can also write your own [network commands](nwprogramming).

A minimal example, which loads a real network and computes degree centrality:

```stata
. nwwebuse florentine, nwclear
. nwdegree flomarriage, generate(deg)
. list _nwnode deg in 1/5
```
See [nwstart](nwstart) for a full, hands-on walkthrough.

Networks are held by nwcommands, not in the Stata dataset: Stata's `clear` does not remove them, [nwclear](nwclear) does.

## Required software

Stata 17 or later. The commands are tested on macOS with Stata 17, 18 and 19 and on Windows with Stata 19. The Mata library is built with Stata 17, because a library built by a newer Stata is ignored by older versions; Stata 16 and older are not supported.

The core commands need nothing beyond Stata and the files of this package: no package from SSC, no internet connection after installation, and nothing is installed into your PLUS directory without your asking. The compiled plugins for macOS, Windows and Linux are installed with the package.

## Network concepts similar to Stata

nwcommands mirrors many concepts of Stata. The most important ones and their Stata counterparts are:

- hline 14c TThline 16c TThline 31
- c | Stata c | nwcommands c | Description c |
- hline 14c +hline 16c +hline 31
- c | `varname` c | [netname](netname) c | Name of existing network c |
- c | `newvarname` c | [newnetname](newnetname) c | Name of new network c |
- c | `varlist` c | [netlist](netlist) c | List of networks c |
- c | `exp` c | [netexp](netexp) c | Network expression c |
- c | `dta_examples` c | [netexample](netexample) c | Example network data c |
- hline 14c BThline 16c BThline 31

For example, many commands accept a [netname](netname) as an argument or option, just as Stata commands accept a `varname`. Network lists can be abbreviated like `variable lists`.

## Network commands similar to Stata

Many commands work like the Stata commands they are named after. The full list of commands is in [the topical list](nwtopical).

- hline 14c TThline 16c TThline 31
- c | Stata c | nwcommands c | Description c |
- hline 14c +hline 16c +hline 31
- c | `clear` c | [nwclear](nwclear) c | Clear all network data c |
- c | `drop` c | [nwdrop](nwdrop) c | Drop networks from memory c |
- c | `keep` c | [nwkeep](nwkeep) c | Keep networks in memory c |
- c | `use` c | [nwuse](nwuse) c | Use network data c |
- c | `webuse` c | [nwwebuse](nwwebuse) c | Use network data from internetc |
- c | `save` c | [nwsave](nwsave) c | Save network data c |
- c | `generate` c | [nwgenerate](nwgenerate) c | Generate networks c |
- c | `egen` c | [nwgen](nwgen) c | Advanced network generation c |
- c | `replace` c | [nwreplace](nwreplace) c | Replace networks c |
- c | `recode` c | [nwrecode](nwrecode) c | Recode networks c |
- c | `summarize` c | [nwsummarize](nwsummarize) c | Summarize networks c |
- c | `unab` c | [nwunab](nwunab) c | Unabbreviate network lists c |
- c | `ds` c | [nwds](nwds) c | List networks c |
- c | `tabulate` c | [nwtabulate](nwtabulate) c | Tabulate networks c |
- c | `correlate` c | [nwcorrelate](nwcorrelate) c | Correlate networks c |
- c | `expand` c | [nwexpand](nwexpand) c | Expand variable to network c |
- c | `syntax` c | `_nwsyntax` c | Parse network syntax c |
- hline 14c BThline 16c BThline 31

## Statistical network models

The statistical models for networks are separate packages that build on `nwcommands`: `nwsaom` (stochastic actor-oriented models), `nwergm` (exponential random graph models), `nwdynam` (dynamic network actor models) and `nwrem` (relational event models). Install them with `nwinstall, models`; [nwversion](nwversion) shows which are installed. Which package you need is explained at browse "https://nwcommands.org/which-package/".

## Questions, bugs and getting involved

Ask questions in the GitHub Discussions of the package, and report errors, wrong results and feature requests as GitHub issues:

browse "https://github.com/thomas-u-grund/nwcommands/discussions"break browse "https://github.com/thomas-u-grund/nwcommands/issues"

New releases and workshops are announced on the nwcommands mailing list, browse "https://groups.google.com/g/nwcommands". If you want to contribute to the software, start with the repository, browse "https://github.com/thomas-u-grund/nwcommands", or write to [thomas.u.grund@gmail.com](mailto:thomas.u.grund@gmail.com).

## Citation

Please cite the package and the version you used ([nwversion](nwversion) prints it):

Grund, T. U. (2026). *nwcommands: Network Analysis in Stata* (version *x.y.z*) [Computer software]. browse "https://github.com/thomas-u-grund/nwcommands"

How to cite the model packages is explained at browse "https://nwcommands.org/citing/".

## Network size and speed

How large a network you can use depends on what you do with it. nwcommands stores a network in three ways, each with its own limits. This section gives measured numbers, so that you know what to expect before you build a large network.

In total, the software supports up to 9999 networks in memory at once, regardless of their individual size.

The web page [How large a network can I analyze?](https://nwcommands.org/nwcommands/size-limits/) lists, command by command, which commands are comfortable, workable or refused at 1,000 to 100,000 nodes.

## Structural analysis (components, degree, clustering, neighbors, unweighted distances)

Most of the package's own graph-traversal commands - [nwcomponents](nwcomponents), [nwdegree](nwdegree), [nwclustering](nwclustering), [nwneighbor](nwneighbor), [nwgeodesic](nwgeodesic)'s unweighted mode, [nwevcent](nwevcent) (eigenvector centrality, by sparse power iteration), [nwpagerank](nwpagerank) (also sparse power iteration), [nwrandomwalk](nwrandomwalk) (exact hitting time via a sparse linear solve, not simulation), [nwmaxflow](nwmaxflow) and [nwmatching](nwmatching) (Edmonds-Karp max-flow on a sparse vertex-split representation), [nwlambda](nwlambda) (edge connectivity, the same sparse max-flow primitive), and anything built on them - operate on a genuinely sparse internal representation. They do **not** allocate memory proportional to the square of the node count, only to the number of actual ties. Measured end to end in Stata/BE (not MP), on a shared computer, for a random directed network with 10 ties per node: [nwfromedge](nwfromedge) builds 10,000 / 25,000 / 40,000 / 100,000 nodes in 0.3 / 0.8 / 1.2 / 3.7 seconds (with automatic directed/undirected detection, i.e. without `directed`: 0.3 / 0.9 / 1.5 / 8.8 seconds; `forceundirected` at 100,000 nodes: 14 seconds). At 100,000 nodes / 1,000,000 ties, [nwdegree](nwdegree) takes 0.5, [nwcomponents](nwcomponents) 0.5, [nwneighbor](nwneighbor) (one node) 0.4 and [nwclustering](nwclustering) 0.7 seconds (at 25,000 nodes: 0.13, 0.12 and 0.13 seconds for the first three). Building the network from an edge list ([nwfromedge](nwfromedge), `nwset, edgelist`, [nwimport](nwimport) type(edgelist)) never allocates the dense matrix. With 5 ties drawn per node (a mean degree of 10 when undirected) and 100,000 nodes, in seconds: [nwfromedge](nwfromedge) 0.51 for a directed network and 1.07 for an undirected one; [nwdegree](nwdegree) 0.032 (undirected) and 0.19 (directed); [nwconstraint](nwconstraint) 2.2 (undirected) and 0.70 (directed); [nwclique](nwclique) with option `nomatrix` 0.26. [nwtoedge](nwtoedge) with `compress`, [nwsave](nwsave), [nwuse](nwuse) and [nwappend](nwappend) of a single network work at this size too (100,000 nodes / 1,000,000 ties: `nwtoedge, compress` 15, `nwsave` 15 seconds and a 124 MB file, `nwuse` 28, `nwappend` 36 seconds on a busy computer; 25,000 nodes: 2.0, 2.7, 4.4 and 4.0 seconds). [nwgeodesic](nwgeodesic) is **not** in this group at the command level: it returns the full matrix of distances between all pairs, which is dense (10,000 nodes: 19 seconds; refused above 20,000 nodes). ([nwfactions](nwfactions) and [nwmotifs](nwmotifs) are combinatorial rather than sparse-traversal in nature - see their own help files for their own, different scaling characteristics.)

Other general-purpose commands work on the ties as well (Stata/BE, random directed network with 10 ties per node; 1,000 / 5,000 / 20,000 nodes): [nwtoedge](nwtoedge) with `compress`, [nwexport](nwexport) (edge list, Pajek, UCINET, GML), [nwrecode](nwrecode) and [nwdichotomize](nwdichotomize) take 0.1-0.3 / 0.2-0.4 / 0.3-1.4 seconds; [nwtabulate](nwtabulate) of one network 0.01 / 0.01 / 0.03 seconds; [nwkcomponents](nwkcomponents) (undirected, about 20 ties per node) 0.05 / 2 / 31 seconds. Still quadratic by nature: [nwtoedge](nwtoedge) and [nw2toedge](nw2toedge) without `compress` (one row per dyad: 5,000 nodes 20 / 24 seconds, refused above 50,000,000 rows), [nwplotmatrix](nwplotmatrix) (one box per dyad: 1,000 nodes 5 seconds, refused above 2,500 nodes) and `nwplot, layout(kk)` (5,000 nodes 21 seconds and 2.2 GB).

## Commands that need the full adjacency matrix

A number of commands, most weighted-distance calculations among them, need the network's complete N-by-N adjacency matrix in memory at once. This matrix is guarded at 20,000 nodes: attempting to build it above that size raises a clear, immediate error rather than silently exhausting memory (at 20,000 nodes the matrix alone is already several gigabytes of numbers). In practice, comfortable, responsive use of these specific commands is closer to a few thousand nodes than to the 20,000-node hard ceiling - memory and running time both grow with the SQUARE of the node count for anything that touches this matrix directly. Among the commands people reach for with big data, [nwgeodesic](nwgeodesic), [nwsummarize](nwsummarize), the uncompressed [nwtoedge](nwtoedge) (it lists every dyad), `nwtoedge` and `nwsave` of several networks at once, and [nw2toedge](nw2toedge) are in this group; so are two-mode networks in `nwtoedge, compress`. ([nwspectral](nwspectral) needs the full eigenspectrum of the Laplacian, not just a dominant pair, so it has no sparse equivalent as [nwevcent](nwevcent) has.)

Measured at 5,000 nodes (Stata/BE, random network with 10 ties per node, one command each): [nwspectral](nwspectral), [nwconcor](nwconcor) and [nwhierarchy](nwhierarchy) work on dense matrices with a running time that grows with the cube (or, for the clustering, about the 2.4th power) of the number of nodes: 1,000 / 2,000 / 3,000 / 5,000 nodes take 1.5 / 14 / 50 / more than 180 seconds (`nwspectral`), 4 / 16 / 57 / more than 180 seconds (`nwconcor`) and 3 / 16 / 45 / 170 seconds (`nwhierarchy`); [nwhomophily](nwhomophily) 78 seconds and 5.3 GB, [nwcollapse](nwcollapse) 61 seconds, [nwbalance](nwbalance), [nwmatching](nwmatching), [nwmixing](nwmixing), [nwevcent](nwevcent), [nwdissimilar](nwdissimilar), [nwsimilar](nwsimilar), [nwsimindex](nwsimindex) and [nwlambda](nwlambda) take under 2 seconds at 5,000 nodes. [nwtostata](nwtostata) needs one Stata variable per node and is limited by the number of variables of your Stata flavour (2,048 in Stata/BE).

Measured at 10,000 nodes (Stata/BE, random network with 10 ties per node): the cubic commands [nwspectral](nwspectral), [nwconcor](nwconcor) and [nwhierarchy](nwhierarchy) (and [nwdendrogram](nwdendrogram) of its result) need more than 5 minutes and stop with r(484) above 6,000 nodes unless the option `force` is given; [nwcorrelate](nwcorrelate) of the nodes of one network needs about 25 dense matrices and stops with r(484) above 7,000 nodes; [nwqap](nwqap) 40 seconds and 11.6 GB; [nwhomophily](nwhomophily), [nwcollapse](nwcollapse) and the uncompressed [nwtoedge](nwtoedge) stop above 7,071 nodes; the generators draw the ties as a list ([nwrandom](nwrandom) 0.1 seconds, [nwcug](nwcug) with 5 draws 1.5 seconds). Two-mode networks cost the square of both modes together: 10,000 + 5,000 nodes need 7 GB. [nwcommunity](nwcommunity) 0.24 seconds, [nwrandomwalk](nwrandomwalk) 0.15 seconds, [nwcomponents](nwcomponents) 0.04 seconds. Most other commands finish in under 30 seconds (the slowest: [nwplot](nwplot) with the circle layout 39 seconds, [nwutility](nwutility) 26 seconds, [nwkatz](nwkatz) 24 seconds).

Measured at 20,000 nodes (Stata/BE, random directed network with 10 ties per node, 200,000 ties; the sparse cutoff of the dense matrix). Most commands work on the stored ties and finish in seconds: [nwcomponents](nwcomponents) 0.07, [nwdegree](nwdegree) 0.08, [nwcommunity](nwcommunity) 0.6, [nwcoreperiphery](nwcoreperiphery) 0.6, [nwclique](nwclique) 1.0, [nwcloseness](nwcloseness) and [nwkatz](nwkatz) 9.9 and 10 seconds (one breadth-first search per node in the plugin), [nwbetween](nwbetween) 29, [nwkcomponents](nwkcomponents) (k = 2) 1.0, [nwcohesion](nwcohesion) 27 seconds. [nwtranspose](nwtranspose), [nwpermute](nwpermute), [nwaddnodes](nwaddnodes), [nwdropnodes](nwdropnodes), [nwkeepnodes](nwkeepnodes), [nwturnover](nwturnover), [nwshared](nwshared), [nwsimmelian](nwsimmelian), [nwbridges](nwbridges), [nwpath](nwpath), [nwdyads](nwdyads), [nwsummarize](nwsummarize) and [nwvalue](nwvalue) do not build an *n*-by-*n* matrix. The generators [nwring](nwring), [nwrandom](nwrandom), [nwsmall](nwsmall) and [nwpref](nwpref) draw the ties as a list above 2,000 nodes (0.2 to 2.8 seconds at 20,000 nodes), so [nwcug](nwcug) with 5 draws takes 2 seconds. Networks whose result is a dense *n*-by-*n* network take their memory, which is why the following stop at once with r(484) when it would not fit in 12 GB (`force` runs them): [nwsimilar](nwsimilar) (9 matrices, 28.8 GB), [nwdissimilar](nwdissimilar), [nwsimindex](nwsimindex), [nwcorrelate](nwcorrelate) of two networks, [nwqap](nwqap) (48 GB), [nwutility](nwutility) and [nwplot](nwplot); still working at 20,000 nodes: [nwgeodesic](nwgeodesic) (10 seconds, 6.4 GB), [nwreach](nwreach) (11 seconds, 6.4 GB), [nwlambda](nwlambda) (30 seconds, 6.5 GB), [nwconstraint](nwconstraint), [nwexpand](nwexpand). Two-mode networks are one matrix over both modes: 20,000 nodes in total (13,333 + 6,667) work in every two-mode command (1.7 to 12 seconds, 3.4 GB), above 20,000 nodes [nw2fromedge](nw2fromedge) refuses at once. Refused by design: [nwtoedge](nwtoedge) and [nw2toedge](nw2toedge) without `compress` (one row per dyad, refused above 50,000,000 rows), [nwhomophily](nwhomophily) and [nwcollapse](nwcollapse) (the same list of dyads, refused at once), [nwspectral](nwspectral), [nwconcor](nwconcor), [nwhierarchy](nwhierarchy) and [nwdendrogram](nwdendrogram) (cubic, refused above 6,000 nodes), [nwnclique](nwnclique), [nwkplex](nwkplex) and [nwnclan](nwnclan) (more than 100,000 maximal subgroups), [nwplotmatrix](nwplotmatrix) and [nwtostata](nwtostata).

Measured at 100,000 nodes (Stata/BE, random directed network with 10 ties per node, 1.0 million ties, 0.6 to 1.5 GB for most commands). Seconds: [nwfromedge](nwfromedge) 3, [nwset](nwset) 3, [nwsave](nwsave) 6, [nwuse](nwuse) 14, [nwdegree](nwdegree) 0.3, [nwdyads](nwdyads) 0.5, [nwsummarize](nwsummarize) 0.06, [nwcomponents](nwcomponents) 0.3, [nwkcore](nwkcore) 0.5, [nwpagerank](nwpagerank) 0.3, [nwcommunity](nwcommunity) 7 (label propagation 15), [nwevcent](nwevcent) 0.5, [nwclustering](nwclustering) 0.7, [nwshared](nwshared) 10, [nwtriads](nwtriads) 1.0, [nwburt](nwburt) 0.17, [nwsimmelian](nwsimmelian) 0.75, [nwconstraint](nwconstraint) 10 (undirected; the compiled search takes 0.9 seconds of that, the rest is storing the result as a network), [nwclique](nwclique) (the search takes 0.6 seconds; from about 40,000 nodes the time is Stata storing the clique matrix, which grows with the square of the number of columns), [nwmaxflow](nwmaxflow) 1.7, [nwrecode](nwrecode) and [nwdichotomize](nwdichotomize) 2, [nwdropnodes](nwdropnodes), [nwkeepnodes](nwkeepnodes) and [nwsubset](nwsubset) 1 to 3, [nwattime](nwattime) 2, the generators [nwring](nwring), [nwrandom](nwrandom), [nwpref](nwpref) 1 to 2 and [nwsmall](nwsmall) 6 (but [nwrandom](nwrandom) with `prob()` 64 seconds). These commands stop at once with r(484), a message and an alternative (`force` runs them anyway): the commands with an *n*-by-*n* result or matrix ([nwgeodesic](nwgeodesic), [nwreach](nwreach), [nwlambda](nwlambda), [nwexpand](nwexpand), [nwcontext](nwcontext), [nwreplace](nwreplace), [nwsimilar](nwsimilar), [nwdissimilar](nwdissimilar), [nwsimindex](nwsimindex), [nwcorrelate](nwcorrelate), [nwqap](nwqap), [nwutility](nwutility), [nwspectral](nwspectral), [nwconcor](nwconcor), [nwhierarchy](nwhierarchy), [nwplotmatrix](nwplotmatrix), [nwtomata](nwtomata), [nwtostata](nwtostata)), and the ones that would run for more than 2 minutes: [nwbetween](nwbetween) (about 15 minutes), [nwcloseness](nwcloseness) and [nwkatz](nwkatz) (5 minutes; measured 302 seconds), [nwkcomponents](nwkcomponents) (refused without `force` above about 31,000 nodes, although k = 2 takes about a minute at 100,000 nodes) and [nwcohesion](nwcohesion) (about 13 minutes). Two-mode networks are one matrix over both modes and are refused above 20,000 nodes in total ([nw2fromedge](nw2fromedge)).

## Cohesion, factions, motifs, connectivity and exhaustive subgroup searches

[nwcohesion](nwcohesion), [nwfactions](nwfactions), [nwlambda](nwlambda), [nwmotifs](nwmotifs), [nwclustering](nwclustering) (on a two-mode network) and [nwinduced](nwinduced) with `measure(degree)` run in compiled code on the list of ties and do not build N-by-N matrices (except that [nwlambda](nwlambda)'s result is itself a dense N-by-N network). Measured in Stata/BE on a random network with 10 ties drawn per node, seconds at 300 / 1,000 / 5,000 nodes: `nwcohesion` 0.02 / 0.10 / 1.4, `nwfactions` 0.02 / 0.02 / 0.05, `nwlambda` 0.02 / 0.09 / 1.9 (1.4 GB at 5,000 nodes), `nwmotifs` 0.006 / 0.014 / 0.05, `nwclustering` on a two-mode network (N and N/2 nodes) 0.09 / 0.24 / 1.4, `nwinduced, measure(degree)` 0.02 / 0.03 / 0.09. `nwinduced` with betweenness, closeness or eigenvector centrality still recomputes the measure for every node left out and takes minutes at a few hundred nodes.

[nwkplex](nwkplex), [nwnclique](nwnclique) and [nwnclan](nwnclan) list *all* maximal subgroups, and the number of those, not the number of nodes, decides what is feasible: a random network with 10 ties per node and 100 nodes already has 46,580,136 maximal 2-cliques of at least 3 nodes (100 nodes, 10,141 maximal 2-plexes; 1,000 nodes, 148,070; 300 nodes, 3,968,148 maximal 3-plexes). The search itself is fast (maximal 2-plexes of 5,000 nodes are counted in 2 seconds; the n-clans of 5,000 nodes in 2.5 seconds), but the result is a sets-by-nodes matrix. These commands therefore stop with a clear message (r(484)) when they find more than `maxplexes()` / `maxcliques()` sets (default 100,000), when the matrix would be too large, or after `maxtime()` seconds (default 60); `countonly` counts the sets without storing them and `nomatrix` keeps only the per-node variable and the counts. See the help file of each command for its measured sizes.

## Loading a network as Stata variables

[nwload](nwload) (and the `xvars` option many [network generators](nwtopical) accept) represents a network as ordinary Stata variables, one per node, in a wide adjacency-matrix layout. This is bounded by Stata's own variable-count ceiling (**c(max_k_theory)** - varies by your Stata flavor: for example, a few thousand in Small Stata, far more in Stata/IC, BE, or MP), not by anything this package imposes. `nwload` itself will not materialize a network above 1000 nodes this way unless `force` is specified, since doing so routinely for large networks is rarely what you want.

Crucially, loading a network as Stata variables is **not** required to analyze it - every [netname](netname)-based command works directly against the network's own internal representation, with or without any Stata variables present. By default, network generators do **not** load their result as Stata variables at all (only `xvars` does this on request) - so building and analyzing a 50,000-node network's own structure never has to touch Stata's variable budget in the first place, as long as you never ask a command to also load it. [nwload](nwload) is still there for the cases that genuinely call for it - inspecting individual tie values directly, or feeding a network's data into ordinary Stata commands.

None of the figures on this page are promises for every possible network shape or every command - a command's own help file is the authority on anything specific to it. When in doubt for a genuinely large network, try the structural commands first (they are the ones proven at real scale), and treat the figures for the dense-matrix commands as realistic planning numbers rather than hard guarantees.

---

*nwcommands version 3.23.0, 13 November 2026* ([check your installed version](nwversion))
