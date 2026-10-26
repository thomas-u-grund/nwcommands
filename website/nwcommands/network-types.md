---
title: "Network types"
parent: "nwcommands (core)"
nav_order: 5
description: "Which network types each core command supports: binary, valued, two-mode, directed. One row per command."
permalink: /nwcommands/network-types/
---

# Which network types each command supports
{: .no_toc }

Every network carries a *valued* flag, a *two-mode* flag and a *directed* flag, and the commands treat them differently. This page lists all 144 commands of the core with what each does on a binary, a valued, a two-mode and a directed network, and how it is computed (compiled plug-in or Mata). Each command's help file says the same in its section "Supported network types". The rules are explained on the pages on [valued networks](/nwcommands/valued-networks/) and [two-mode networks](/nwcommands/two-mode/).

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
| Two-mode | `N` | native: uses the two modes as R does (tnet, igraph, bipartite); where there is a one-mode form too, the two-mode form is the default and the option onemode gives the other |
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
| C plug-in | `●` | the command uses the compiled plug-in when it is available; without it, Mata gives the same result |
| C plug-in | `only` | plug-in only: stops with an error message when the plug-in is missing or older |
| C plug-in | blank | no plug-in |
| Mata | `●` | the computation is done in the Mata library (the only engine) |
| Mata | `○` | Mata is only the fallback for the plug-in |
| Mata | blank | no Mata computation (installer, aliases, help pages, plot drawing) |

A command with a two-mode form of the same concept (`nwdegree`, `nwclustering`, `nwmotifs`, `nwcloseness`, `nwbetween`, `nwcommunity`, `nwmodularity`, `nwsimilar`, `nwdissimilar`) uses it automatically on a two-mode network; `onemode` forces the one-mode computation. The names `nw2degree`, `nw2clustering` and `nw2motifs` are aliases.

The commands marked `N` under Valued are exactly those that print the note on a valued network, and the commands marked `R` or `O` under Two-mode are exactly those that stop on a two-mode network with error 6088.

## Where the speed comes from

Most commands are programmed in Mata, Stata's matrix language, and need nothing besides the nwcommands library. For the commands marked in the column "C plug-in", nwcommands also contains a compiled program (a plug-in) that does the heavy computation, in some cases a hundred to a thousand times faster. The plug-in is installed with the package for macOS, Linux and Windows. If it is missing, or older than the commands expect, these commands quietly use the Mata version of the same computation, which gives the same numbers but needs more time and memory on large networks. A few cases have no Mata version and stop with an error message instead; they are marked "only" (weighted Burt measures, closeness and distances of valued networks above 100 nodes, and `nw2motifs`). Plots are drawn by Stata's graphics or written as an HTML page; only the placement of nodes by the Kamada-Kawai method uses the plug-in. Short commands that copy, rename or save networks, and the help pages, do no computation of their own.

The generation of the plug-in matters, but the table does not show a minimum version per command: all compiled kernels of core 3.9.0 are in the plug-in that ships with it for macOS, Linux and Windows, and an older plug-in makes a command fall back to Mata (same results, slower) except where marked "only".

If a command is slow, update to the latest release (`nwinstall`) so that the plug-in is current, and look at the output of `nwversion`, which shows the plug-in that Stata has loaded. If the plug-in is older than the core, update again; the commands then run in the compiled code.

## Creating, importing and exporting networks

| Command | Binary | Valued | Two-mode | Directed | C plug-in | Mata | Note |
|---|:-:|:-:|:-:|:-:|:-:|:-:|---|
| `nwset` | + | K | K | D |  | ● | twomode and bipartite declare a two-mode network; valued/unvalued set the flag; the flag is set only here and in the other creating commands |
| `nw2set` | + | K | K | U |  | ● | declares a two-mode network from a rectangular matrix |
| `nwfromedge` | + | K | K | D |  | ● | a value variable makes the network valued; twomode = nw2fromedge |
| `nw2fromedge` | + | K | K | U |  | ● | ids in two columns; a value variable makes it valued |
| `nwimport` | + | K | K | D |  | ● | Pajek, UCINET, edge list, GML, matrix; two-mode files come back two-mode; a tie inside a mode is refused |
| `nwexport` | + | K | K | D |  | ● | Pajek *Vertices n n1, UCINET rectangular, edge list with five columns, GML attribute nwmode |
| `nwtoedge` | + | K | K | D |  | ● | a two-mode network is written as its ties (allpairs for every pair) |
| `nw2toedge` | + | K | K | U |  | ● | ties between the modes, mode of both nodes; reads back with nw2fromedge |
| `nwsave` | + | K | K | D |  | ● | ties, modes, labels and the valued flag are saved |
| `nwuse` | + | K | K | D |  | ● | restores the flags as saved |
| `nwwebuse` | + | K | K | D |  | ● | example data sets, e.g. davis and ftdirectors_se (two-mode) |
| `nwload` | + | K | K | D |  | ● | node data to Stata variables; _nwmode for a two-mode network |
| `nwappend` | + | - | - | - |  | ● | appends node-level Stata data; reads no ties |
| `nwtomata` | + | K | K | D |  | ● | square matrix; missing cells between nodes of the same mode in a two-mode network |
| `nwtomatafast` | + | K | K | D |  | ● | pointer to the matrix |
| `nwtostata` | - | - | - | - |  | ● | copies a Mata matrix into variables; it reads no network |

## Changing and deriving networks

| Command | Binary | Valued | Two-mode | Directed | C plug-in | Mata | Note |
|---|:-:|:-:|:-:|:-:|:-:|:-:|---|
| `nwdropnodes` | + | K | K | D |  | ● | keeps the flag, the modes and the level labels (as does nwkeepnodes) |
| `nwkeepnodes` | + | K | K | D |  | ● | keeps the flag, the modes and the level labels |
| `nwsubset` | + | K | K | D |  | ● | keeps the flag, the modes and the level labels |
| `nwduplicate` | + | K | K | D |  | ● | copy with all flags and labels |
| `nwaddnodes` | + | K | K | D |  | ● | on a two-mode network mode() is required |
| `nwsym` | + | K | K | D |  | ● | directed to undirected; mode() max, min, sum, mean |
| `nwsymmetrize` | + | K | K | D |  | ● | alias of nwsym |
| `nwtranspose` | + | K | K | D |  | ● | keeps the flags; the matrix of a two-mode network is symmetric |
| `nwrecode` | + | K | K | D |  | ● | keeps the valued flag of the source |
| `nwreplace` | + | K | G | D |  | ● | writes the cell of an (ego, alter) pair |
| `nwreplacemat` | + | K | K | D |  | ● | on a two-mode network a tie inside a mode is refused (error 459) |
| `nwdichotomize` | + | K | K | D |  | ● | valued to binary by a threshold; the result is binary |
| `nwcollapse` | + | K | R | D |  | ● | by a grouping variable; collapse functions act on the values |
| `nwpermute` | + | K | N | D | ● | ○ | two-mode: labels permuted within the modes; swap keeps both degree sequences |
| `nwproject` | + | O | Q | U |  | ● | alias of nw2project |
| `nw2project` | + | O | Q | U |  | ● | stat(): count, binary, jaccard, cosine, min, max, sum, mean, minmax, newman |
| `nwpreserve` | + | K | K | D |  |  | saves the state of all networks |
| `nwrestore` | + | K | K | D |  |  | restores the state |
| `nwattime` | + | K | - | D |  | ● | temporal networks: the slice keeps the tie values and the direction; a temporal network cannot be two-mode (not yet supported as a source) |

## Describing a network and its nodes

| Command | Binary | Valued | Two-mode | Directed | C plug-in | Mata | Note |
|---|:-:|:-:|:-:|:-:|:-:|:-:|---|
| `nwsummarize` | + | K | N | D |  | ● | shows both levels and their labels; density over the pairs between the modes |
| `nwname` | + | K | K | D |  |  | reads and sets properties; new2mode(true) is checked (error 459) |
| `nwdyads` | + | N | N | D |  | ● | null dyads over the pairs between the modes; reciprocity n/a |
| `nwtriads` | + | N | G | D | ● | ○ | census of the bipartite graph; transitivity 0 |
| `nwmotifs` | + | N | N | S | ● | ○ | 4-node census of a one-mode network; two-mode form by default: the bipartite motifs of Simmons et al. (bmotif), onemode forces the 4-node census |
| `nwissymmetric` | + | K | G | D |  | ● |  |
| `nwtabulate` | + | N | G | D |  | ● | E-I table over ties |
| `nwmixing` | + | N | G | D |  | ● | mixing table by an attribute |
| `nwnode` | + | - | - | - |  | ● | node lookup |
| `nwvalue` | + | K | G | D |  | ● | one cell |
| `nwego` | + | N | G | D |  | ● | ego network size and density (density among alters is 0) |
| `nwneighbor` | + | N | G | D |  | ● | neighbours of a node, mode(incoming/outgoing/either) |
| `nwaltergen` | + | I | G | D | ● | ○ | node attribute from the alters (out-neighbours) |
| `nwcontext` | + | V | G | D |  | ● | statistic of the neighbours attribute; mode(); the tie values weight the neighbours by default, noweight gives the presence-only result |

## Paths, reachability and flows

| Command | Binary | Valued | Two-mode | Directed | C plug-in | Mata | Note |
|---|:-:|:-:|:-:|:-:|:-:|:-:|---|
| `nwgeodesic` | + | V | G | S | ● | ○ | valued: step cost 1/w^alpha; alpha(-1) reads values as lengths; nosym for directed; Valued network above 100 nodes: plug-in only (no Mata version). |
| `nwpath` | + | V | G | S |  | ● | least cost path; r(path_cost) |
| `nwreach` | + | N | G | S | ● | ○ | reachability network |
| `nwmaxflow` | + | O | G | D |  | ● | weighted: values are capacities |
| `nwrandomwalk` | + | V | O | S |  | ● | hitting times; directed networks treated as undirected |
| `nwmatching` | + | V | Q | U | ● | ○ | maximum matching between the modes; valued: largest total value |

## Centrality, brokerage and structural holes

| Command | Binary | Valued | Two-mode | Directed | C plug-in | Mata | Note |
|---|:-:|:-:|:-:|:-:|:-:|:-:|---|
| `nwdegree` | + | V | N | D |  | ● | valued: strength; alpha(); in- and out-degree for directed; two-mode form (ties / size of the other mode, raw) by default, onemode forces the one-mode degree |
| `nw2degree` | + | V | Q | U |  | ● | alias of nwdegree on a two-mode network: degree / size of the other mode; raw gives the count |
| `nwbetween` | + | V | N | S | ● | ○ | nosym for directed; two-mode form by default: Borgatti-Everett standardisation (twomode is a synonym), onemode forces the one-mode betweenness |
| `nwcloseness` | + | V | N | S | ● | ○ | two-mode form by default: Borgatti-Everett normalisation (twomode is a synonym), onemode forces the one-mode closeness; Valued network above 100 nodes: plug-in only (no Mata version). |
| `nwevcent` | + | V | G | S | ● | ○ | principal eigenvector of the bipartite adjacency matrix |
| `nwpagerank` | + | V | G | D | ● | ○ |  |
| `nwkatz` | + | V | G | D | ● | ○ | walks option weights walks; otherwise steps |
| `nwinduced` | + | V | R | D | ● | ○ | induced centrality; measure(degree) not for directed |
| `nwassortativity` | + | V | G | S |  | ● | valued: attribute is the strength; value negative by construction for a two-mode network |
| `nwbrokerage` | + | N | G | D |  | ● | Gould-Fernandez roles |
| `nwburt` | + | V | G | D | ● | ○ | values are investments; no binary mode; not symmetrized; Valued network: plug-in only (no Mata version). |
| `nwconstraint` | + | V | G | D | ● | ○ | values are investments; not symmetrized |
| `nwutility` | + | I | G | S | ● | ○ | connections model |

## Cohesion, clustering, components and communities

| Command | Binary | Valued | Two-mode | Directed | C plug-in | Mata | Note |
|---|:-:|:-:|:-:|:-:|:-:|:-:|---|
| `nwcomponents` | + | N | G | S |  | ● | weak connectivity |
| `nwbridges` | + | N | G | D |  | ● | type(): local, global, arcs, edges |
| `nwclique` | + | N | G | S | ● | ○ | no clique of three or more nodes in a bipartite graph |
| `nwcohesion` | + | N | G | S | ● | ○ | Moody-White hierarchy |
| `nwkcomponents` | + | N | G | S | ● | ○ |  |
| `nwkcore` | + | N | G | S |  | ● | union of in- and out-neighbours |
| `nwkplex` | + | N | G | S | ● | ○ |  |
| `nwnclan` | + | N | G | S | ● | ○ |  |
| `nwnclique` | + | N | G | S | ● | ○ |  |
| `nwlambda` | + | I | G | S | ● | ○ | edge-disjoint paths; nwmaxflow, weighted for capacities |
| `nwsimmelian` | + | N | G | D | ● | ○ | needs triangles: all 0 in a bipartite graph |
| `nwshared` | + | N | G | P |  | ● | requires the option `undirected` on a directed network (error 198 otherwise) |
| `nwclustering` | + | O | N | D | ● | ○ | measure(); weighted not for directed; two-mode form (Opsahl 2013; ra: Robins-Alexander 2004) by default, onemode forces the one-mode coefficient |
| `nw2clustering` | + | O | Q | U | ● | ○ | alias of nwclustering on a two-mode network: Opsahl 2013; ra: Robins-Alexander 2004 |
| `nw2motifs` | + | N | Q | U | only |  | alias of nwmotifs on a two-mode network: bipartite motifs of Simmons et al. (bmotif): 17 motifs, 44 with sixnode, node positions; counts ties above zero; Bipartite motifs need the plug-in of core 3.9.0. |
| `nw2nested` | + | I | Q | U |  | ● | NODF and C-score |
| `nwbalance` | + | I | G | D | ● | ○ | signed networks; a bipartite graph has no triangle; only the sign of a tie value enters |
| `nwcommunity` | + | O | N | P | ● | ○ | two-mode: Barber modularity; onemode for Newman; algorithm(dirtlpa) (Beckett 2016, two-mode, plug-in only) |
| `nwmodularity` | + | O | N | P |  | ● | two-mode: Barber modularity; onemode for Newman |
| `nwspectral` | + | O | O | S |  | ● | Fiedler vector, algebraic connectivity |

## Positions, similarity and equivalence

| Command | Binary | Valued | Two-mode | Directed | C plug-in | Mata | Note |
|---|:-:|:-:|:-:|:-:|:-:|:-:|---|
| `nwsimilar` | + | O | N | D | ● | ○ | two-mode: nodes compared within their own mode, other mode missing |
| `nwdissimilar` | + | O | N | D | ● | ○ | two-mode: nodes compared within their own mode, other mode missing |
| `nwsimindex` | + | N | G | S |  | ● | Jaccard index of the neighbour sets; between the modes 0 |
| `nwcorrelate` | + | O | R | D | ● | ○ | two networks are correlated as usual; the profiles of one network are refused on a two-mode network |
| `nwhierarchy` | + | O | R | - |  | ● | hierarchical clustering of the profiles |
| `nwdendrogram` | + | - | - | - |  |  | draws the result of nwhierarchy; it reads no network and does not stop on a two-mode network (nwhierarchy does) |
| `nwconcor` | + | O | R | D |  | ● | CONCOR blockmodel |
| `nwcoreperiphery` | + | O | R | S |  | ● | discrete core-periphery model |
| `nwfactions` | + | O | R | S | ● | ○ |  |

## Null models and statistical helpers

| Command | Binary | Valued | Two-mode | Directed | C plug-in | Mata | Note |
|---|:-:|:-:|:-:|:-:|:-:|:-:|---|
| `nwcug` | + | I | N | D | only | ● | conditional uniform graph draws; two-mode: condition(density, mode1degree, mode2degree, degrees) with the native draws (plug-in only for the two-mode form; the one-mode form is Mata) |
| `nwqap` | + | O | R | D |  | ● | QAP regression over the dyads |
| `nwturnover` | + | N | N | D |  | ● | compares two networks of the same nodes; on a two-mode network only the ties between the modes count |

## Random and structured generators

| Command | Binary | Valued | Two-mode | Directed | C plug-in | Mata | Note |
|---|:-:|:-:|:-:|:-:|:-:|:-:|---|
| `nwrandom` | + | I | - | D |  | ● | always one-mode; undirected option |
| `nwring` | + | I | - | D |  | ● | always one-mode |
| `nwlattice` | + | I | - | D |  | ● | always one-mode |
| `nwsmall` | + | I | - | D |  | ● | always one-mode |
| `nwpref` | + | I | - | D |  | ● | always one-mode |
| `nwgen` | + | I | - | D |  |  | dispatcher of the generators |
| `nwgenerate` | + | I | - | D |  |  | dispatcher of the generators |
| `nwgenvar` | + | I | - | D |  |  | dispatcher of the generators |
| `nwhomophily` | + | I | - | D |  | ● | always one-mode |
| `nwexpand` | + | I | - | - |  | ● | network from an attribute; always one-mode; the direction is not taken from a network |
| `nwdyadprob` | + | I | - | D |  | ● | always one-mode |

## Visualization

| Command | Binary | Valued | Two-mode | Directed | C plug-in | Mata | Note |
|---|:-:|:-:|:-:|:-:|:-:|:-:|---|
| `nwplot` | + | V | N | D | ● | ○ | layout(bipartite) puts the two modes in two rows; values set the widths (binary), signs the colour and dash (nosign), the modes get symbols; legend |
| `nwplotmatrix` | + | K | N | D |  |  | colour legend of the value classes (legend(off) switches off); a two-mode network is sorted by mode with a line between the modes |
| `nwmovie` | + | V | - | D | ● | ○ | temporal networks; widths, sign colours and binary/nosign as nwplot; not two-mode |
| `nwmoviexy` | + | V | - | D | ● | ○ | alias of nwmovie |
| `animate` | - | - | - | - |  |  | help page |

## Bookkeeping, utilities and help pages

| Command | Binary | Valued | Two-mode | Directed | C plug-in | Mata | Note |
|---|:-:|:-:|:-:|:-:|:-:|:-:|---|
| `nwcurrent` | - | - | - | - |  | ● | sets the current network |
| `nwdrop` | - | - | - | - |  | ● | removes networks |
| `nwkeep` | - | - | - | - |  | ● | keeps networks |
| `nwclear` | - | - | - | - |  | ● | removes all networks |
| `nwrename` | - | - | - | - |  | ● |  |
| `nwnoderename` | - | - | - | - |  | ● |  |
| `nworder` | - | - | - | - |  | ● |  |
| `nwsync` | - | - | - | - |  | ● |  |
| `nwunab` | - | - | - | - |  | ● |  |
| `nwds` | - | - | - | - |  | ● |  |
| `nwvalidate` | - | - | - | - |  | ● |  |
| `nwvalidvars` | - | - | - | - |  | ● |  |
| `nwversion` | - | - | - | - |  |  |  |
| `nwinstall` | - | - | - | - |  |  |  |
| `nwcompressobs` | - | - | - | - |  |  |  |
| `nwcentrality` | - | - | - | - |  |  | help page |
| `nwerrorcodes` | - | - | - | - |  |  | help page |
| `nwnetworktypes` | - | - | - | - |  |  | help page |
| `netexample` | - | - | - | - |  |  | help page |
| `netexp` | - | - | - | - |  |  | help page |
| `netlist` | - | - | - | - |  |  | help page |
| `netname` | - | - | - | - |  |  | help page |
| `newnetname` | - | - | - | - |  |  | help page |
| `nodeid` | - | - | - | - |  |  | help page |
| `nw_helpwriter` | - | - | - | - |  | ● | internal |
| `nw_resetrc` | - | - | - | - |  |  | internal |
| `schemeinfo` | - | - | - | - |  |  | internal |
| `unw_defs` | - | - | - | - |  |  | internal |

