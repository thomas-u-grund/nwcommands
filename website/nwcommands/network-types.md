---
title: "Network types"
parent: "nwcommands (core)"
nav_order: 5
description: "Which network types each core command supports: binary, valued, two-mode, directed. One row per command."
permalink: /nwcommands/network-types/
---

# Which network types each command supports
{: .no_toc }

Every network carries a *valued* flag, a *two-mode* flag and a *directed* flag, and the commands treat them differently. This page lists all 143 commands of the core with what each does on a binary, a valued, a two-mode and a directed network. Each command's help file says the same in its section "Supported network types". The rules are explained on the pages on [valued networks](/nwcommands/valued-networks/) and [two-mode networks](/nwcommands/two-mode/).

1. TOC
{:toc}

## Symbols

| Column | Symbol | Meaning |
|---|---|---|
| Binary | `+` | works on a binary network |
| Binary | `-` | not applicable (the command reads no ties) |
| Valued | `V` | uses the tie values by default; option binary gives the presence-only result |
| Valued | `O` | uses the tie values through its own option (measure(), stat(), type(), weighted) |
| Valued | `N` | ignores the tie values (R has no weighted form) and prints a one-line note on a valued network |
| Valued | `I` | ignores the tie values (binary by definition), no note |
| Valued | `K` | carries the tie values unchanged (data handling) |
| Valued | `-` | not applicable |
| Two-mode | `N` | native: uses the two modes as R does (tnet, igraph, bipartite) |
| Two-mode | `D` | delegates to the nw2 command and says so |
| Two-mode | `G` | valid: the bipartite graph read as a one-mode graph, no mode-specific normalisation |
| Two-mode | `O` | refuses (error 6088); option onemode reads the graph as one-mode |
| Two-mode | `R` | refuses: error 6088 |
| Two-mode | `Q` | requires a two-mode network |
| Two-mode | `K` | carries the declaration, the modes and the labels unchanged (data handling) |
| Two-mode | `-` | not applicable |
| Directed | `D` | uses the direction of the ties |
| Directed | `S` | symmetrizes (by default or automatically) |
| Directed | `P` | requires the option symmetrize (error otherwise) |
| Directed | `U` | undirected networks only, or two-mode (undirected by construction) |
| Directed | `-` | not applicable |

The commands marked `N` under Valued are exactly those that print the note on a valued network, and the commands marked `R` or `O` under Two-mode are exactly those that stop on a two-mode network with error 6088.

## Creating, importing and exporting networks

| Command | Binary | Valued | Two-mode | Directed | Note |
|---|:-:|:-:|:-:|:-:|---|
| `nwset` | + | K | K | D | twomode and bipartite declare a two-mode network; valued/unvalued set the flag; the flag is set only here and in the other creating commands |
| `nw2set` | + | K | K | U | declares a two-mode network from a rectangular matrix |
| `nwfromedge` | + | K | K | D | a value variable makes the network valued; twomode = nw2fromedge |
| `nw2fromedge` | + | K | K | U | ids in two columns; a value variable makes it valued |
| `nwimport` | + | K | K | D | Pajek, UCINET, edge list, GML, matrix; two-mode files come back two-mode; a tie inside a mode is refused |
| `nwexport` | + | K | K | D | Pajek *Vertices n n1, UCINET rectangular, edge list with five columns, GML attribute nwmode |
| `nwtoedge` | + | K | K | D | a two-mode network is written as its ties (allpairs for every pair) |
| `nw2toedge` | + | K | K | U | ties between the modes, mode of both nodes; reads back with nw2fromedge |
| `nwsave` | + | K | K | D | ties, modes, labels and the valued flag are saved |
| `nwuse` | + | K | K | D | restores the flags as saved |
| `nwwebuse` | + | K | K | D | example data sets, e.g. davis and ftdirectors_se (two-mode) |
| `nwload` | + | K | K | D | node data to Stata variables; _nwmode for a two-mode network |
| `nwappend` | + | - | - | - | appends node-level Stata data; reads no ties |
| `nwtomata` | + | K | K | D | square matrix; missing cells between nodes of the same mode in a two-mode network |
| `nwtomatafast` | + | K | K | D | pointer to the matrix |
| `nwtostata` | + | K | K | D | writes a Mata matrix to variables |

## Changing and deriving networks

| Command | Binary | Valued | Two-mode | Directed | Note |
|---|:-:|:-:|:-:|:-:|---|
| `nwdropnodes` | + | K | K | D | keeps the flag, the modes and the level labels (as does nwkeepnodes) |
| `nwkeepnodes` | + | K | K | D | keeps the flag, the modes and the level labels |
| `nwsubset` | + | K | K | D | keeps the flag, the modes and the level labels |
| `nwduplicate` | + | K | K | D | copy with all flags and labels |
| `nwaddnodes` | + | K | K | D | on a two-mode network mode() is required |
| `nwsym` | + | K | K | D | directed to undirected; mode() max, min, sum, mean |
| `nwsymmetrize` | + | K | K | D | alias of nwsym |
| `nwtranspose` | + | K | K | D | keeps the flags; the matrix of a two-mode network is symmetric |
| `nwrecode` | + | K | K | D | keeps the valued flag of the source |
| `nwreplace` | + | K | G | D | writes the cell of an (ego, alter) pair |
| `nwreplacemat` | + | K | K | D | on a two-mode network a tie inside a mode is refused (error 459) |
| `nwdichotomize` | + | K | K | D | valued to binary by a threshold; the result is binary |
| `nwcollapse` | + | K | R | D | by a grouping variable; collapse functions act on the values |
| `nwpermute` | + | K | N | D | two-mode: labels permuted within the modes; swap keeps both degree sequences |
| `nwproject` | + | O | Q | U | alias of nw2project |
| `nw2project` | + | O | Q | U | stat(): count, binary, jaccard, cosine, min, max, sum, mean, minmax, newman |
| `nwpreserve` | + | K | K | D | saves the state of all networks |
| `nwrestore` | + | K | K | D | restores the state |
| `nwattime` | + | - | - | D | temporal networks; a temporal network cannot be two-mode |

## Describing a network and its nodes

| Command | Binary | Valued | Two-mode | Directed | Note |
|---|:-:|:-:|:-:|:-:|---|
| `nwsummarize` | + | K | N | D | shows both levels and their labels; density over the pairs between the modes |
| `nwname` | + | K | K | D | reads and sets properties; new2mode(true) is checked (error 459) |
| `nwdyads` | + | N | N | D | null dyads over the pairs between the modes; reciprocity n/a |
| `nwtriads` | + | N | G | D | census of the bipartite graph; transitivity 0 |
| `nwmotifs` | + | N | G | S | 4-node census; bipartite motifs not offered |
| `nwissymmetric` | + | K | G | D |  |
| `nwtabulate` | + | N | G | D | E-I table over ties |
| `nwmixing` | + | N | G | D | mixing table by an attribute |
| `nwnode` | + | - | - | - | node lookup |
| `nwvalue` | + | K | G | D | one cell |
| `nwego` | + | N | G | D | ego network size and density (density among alters is 0) |
| `nwneighbor` | + | N | G | D | neighbours of a node, mode(incoming/outgoing/either) |
| `nwaltergen` | + | I | G | D | node attribute from the alters (out-neighbours) |
| `nwcontext` | + | O | G | D | statistic of the neighbours attribute; mode() |

## Paths, reachability and flows

| Command | Binary | Valued | Two-mode | Directed | Note |
|---|:-:|:-:|:-:|:-:|---|
| `nwgeodesic` | + | V | G | S | valued: step cost 1/w^alpha; alpha(-1) reads values as lengths; nosym for directed |
| `nwpath` | + | V | G | S | least cost path; r(path_cost) |
| `nwreach` | + | N | G | S | reachability network |
| `nwmaxflow` | + | O | G | D | weighted: values are capacities |
| `nwrandomwalk` | + | V | O | S | hitting times; directed networks treated as undirected |
| `nwmatching` | + | V | Q | U | maximum matching between the modes; valued: largest total value |

## Centrality, brokerage and structural holes

| Command | Binary | Valued | Two-mode | Directed | Note |
|---|:-:|:-:|:-:|:-:|---|
| `nwdegree` | + | V | D | D | valued: strength; alpha(); in- and out-degree for directed |
| `nw2degree` | + | V | Q | U | degree / size of the other mode; raw gives the count |
| `nwbetween` | + | V | G | S | twomode: Borgatti-Everett standardisation; nosym for directed |
| `nwcloseness` | + | V | G | S | twomode: Borgatti-Everett normalisation |
| `nwevcent` | + | V | G | S | principal eigenvector of the bipartite adjacency matrix |
| `nwpagerank` | + | V | G | D |  |
| `nwkatz` | + | V | G | D | walks option weights walks; otherwise steps |
| `nwinduced` | + | V | R | D | induced centrality; measure(degree) not for directed |
| `nwassortativity` | + | V | G | S | valued: attribute is the strength; value negative by construction for a two-mode network |
| `nwbrokerage` | + | N | G | D | Gould-Fernandez roles |
| `nwburt` | + | V | G | D | values are investments; no binary mode; not symmetrized |
| `nwconstraint` | + | V | G | D | values are investments; not symmetrized |
| `nwutility` | + | I | G | S | connections model |

## Cohesion, clustering, components and communities

| Command | Binary | Valued | Two-mode | Directed | Note |
|---|:-:|:-:|:-:|:-:|---|
| `nwcomponents` | + | N | G | S | weak connectivity |
| `nwbridges` | + | N | G | D | type(): local, global, arcs, edges |
| `nwclique` | + | N | G | S | no clique of three or more nodes in a bipartite graph |
| `nwcohesion` | + | N | G | S | Moody-White hierarchy |
| `nwkcomponents` | + | N | G | S |  |
| `nwkcore` | + | N | G | S | union of in- and out-neighbours |
| `nwkplex` | + | N | G | S |  |
| `nwnclan` | + | N | G | S |  |
| `nwnclique` | + | N | G | S |  |
| `nwlambda` | + | I | G | S | edge-disjoint paths; nwmaxflow, weighted for capacities |
| `nwsimmelian` | + | N | G | D | needs triangles: all 0 in a bipartite graph |
| `nwshared` | + | N | G | P | needs undirected to symmetrize first |
| `nwclustering` | + | O | D | D | measure(); weighted not for directed |
| `nw2clustering` | + | O | Q | U | Opsahl 2013; ra: Robins-Alexander 2004 |
| `nw2nested` | + | I | Q | U | NODF and C-score |
| `nwbalance` | + | I | G | D | signed networks; a bipartite graph has no triangle |
| `nwcommunity` | + | O | N | P | two-mode: Barber modularity; onemode for Newman |
| `nwmodularity` | + | O | N | P | two-mode: Barber modularity; onemode for Newman |
| `nwspectral` | + | O | O | S | Fiedler vector, algebraic connectivity |

## Positions, similarity and equivalence

| Command | Binary | Valued | Two-mode | Directed | Note |
|---|:-:|:-:|:-:|:-:|---|
| `nwsimilar` | + | O | N | D | two-mode: nodes compared within their own mode, other mode missing |
| `nwdissimilar` | + | O | N | D | two-mode: nodes compared within their own mode, other mode missing |
| `nwsimindex` | + | N | G | S | Jaccard index of the neighbour sets; between the modes 0 |
| `nwcorrelate` | + | O | R | D | two networks are correlated as usual; the profiles of one network are refused on a two-mode network |
| `nwhierarchy` | + | O | R | - | hierarchical clustering of the profiles |
| `nwdendrogram` | + | - | R | - | draws the result of nwhierarchy |
| `nwconcor` | + | O | R | D | CONCOR blockmodel |
| `nwcoreperiphery` | + | O | R | S | discrete core-periphery model |
| `nwfactions` | + | O | R | S |  |

## Null models and statistical helpers

| Command | Binary | Valued | Two-mode | Directed | Note |
|---|:-:|:-:|:-:|:-:|---|
| `nwcug` | + | I | R | D | conditional uniform graph draws; nwpermute, swap is the two-mode null model |
| `nwqap` | + | O | R | D | QAP regression over the dyads |
| `nwturnover` | + | N | G | D | compares two networks of the same nodes |

## Random and structured generators

| Command | Binary | Valued | Two-mode | Directed | Note |
|---|:-:|:-:|:-:|:-:|---|
| `nwrandom` | + | I | - | D | always one-mode; undirected option |
| `nwring` | + | I | - | D | always one-mode |
| `nwlattice` | + | I | - | D | always one-mode |
| `nwsmall` | + | I | - | D | always one-mode |
| `nwpref` | + | I | - | D | always one-mode |
| `nwgen` | + | I | - | D | dispatcher of the generators |
| `nwgenerate` | + | I | - | D | dispatcher of the generators |
| `nwgenvar` | + | I | - | D | dispatcher of the generators |
| `nwhomophily` | + | I | - | D | always one-mode |
| `nwexpand` | + | I | - | D | network from an attribute; always one-mode |
| `nwdyadprob` | + | I | - | D | always one-mode |

## Visualization

| Command | Binary | Valued | Two-mode | Directed | Note |
|---|:-:|:-:|:-:|:-:|---|
| `nwplot` | + | O | N | D | layout(bipartite) puts the two modes in two rows; edgesize() uses the values |
| `nwplotmatrix` | + | K | G | D | the matrix includes the empty blocks of a two-mode network |
| `nwmovie` | + | - | - | D | temporal networks; not two-mode |
| `nwmoviexy` | + | - | - | D | alias of nwmovie |
| `animate` | - | - | - | - | help page |

## Bookkeeping, utilities and help pages

| Command | Binary | Valued | Two-mode | Directed | Note |
|---|:-:|:-:|:-:|:-:|---|
| `nwcurrent` | - | - | - | - | sets the current network |
| `nwdrop` | - | - | - | - | removes networks |
| `nwkeep` | - | - | - | - | keeps networks |
| `nwclear` | - | - | - | - | removes all networks |
| `nwrename` | - | - | - | - |  |
| `nwnoderename` | - | - | - | - |  |
| `nworder` | - | - | - | - |  |
| `nwsync` | - | - | - | - |  |
| `nwunab` | - | - | - | - |  |
| `nwds` | - | - | - | - |  |
| `nwvalidate` | - | - | - | - |  |
| `nwvalidvars` | - | - | - | - |  |
| `nwversion` | - | - | - | - |  |
| `nwinstall` | - | - | - | - |  |
| `nwcompressobs` | - | - | - | - |  |
| `nwcentrality` | - | - | - | - | help page |
| `nwerrorcodes` | - | - | - | - | help page |
| `nwnetworktypes` | - | - | - | - | help page |
| `netexample` | - | - | - | - | help page |
| `netexp` | - | - | - | - | help page |
| `netlist` | - | - | - | - | help page |
| `netname` | - | - | - | - | help page |
| `newnetname` | - | - | - | - | help page |
| `nodeid` | - | - | - | - | help page |
| `nw_helpwriter` | - | - | - | - | internal |
| `nw_resetrc` | - | - | - | - | internal |
| `schemeinfo` | - | - | - | - | internal |
| `unw_defs` | - | - | - | - | internal |

