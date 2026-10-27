---
title: "Two-mode networks"
parent: "nwcommands (core)"
nav_order: 5
description: "How the core commands treat two-mode (bipartite, affiliation) networks: how a network is declared, which commands use the two modes, which accept the bipartite graph as it is, which stop, and how to get the one-mode version."
permalink: /nwcommands/two-mode/
---

# Two-mode networks
{: .no_toc }

In a two-mode (bipartite, affiliation) network there are two kinds of nodes, such as people and the events they attend, and ties run only between the kinds. This page tells you how the program knows that a network is two-mode, what every command does with it, what the results mean and where they differ from R. The [tutorial on two-mode networks](/tutorials/11-two-mode-networks/) shows the commands on the Southern women and the Swedish directors.

1. TOC
{:toc}

## How a network becomes two-mode

The program keeps a flag, *Two-mode*, with every network, together with the mode (1 or 2) of every node and a label for each mode. The flag is set when the network is created, by declaration, and nowhere else:

| You create the network with | Two-mode? |
|---|---|
| `nwset ..., twomode` (edge list of the ties between the two modes) or `bipartite` (a rectangular matrix) | yes |
| `nw2fromedge` (two id columns), `nwfromedge ..., twomode`, `nw2set` | yes |
| `nwimport` of a Pajek file with `*Vertices n n1`, a rectangular UCINET matrix, a five-column edge list or a GML file with the node attribute `nwmode` (all written by `nwexport`) | yes |
| `nwuse` of a saved two-mode network | yes, with its modes and labels |
| any other command | no |

No command works the flag out from the ties, because the adjacency matrix of a two-mode network looks like that of a one-mode network. The declaration is checked: both modes must hold nodes and no tie may join two nodes of the same mode (`nwname net, new2mode(true)` on a one-mode network, or an import of a file with such a tie, stops with error 459; `nwreplacemat` refuses a matrix with a tie inside a mode).

A two-mode network is stored as one square matrix over the nodes of both modes. The cells between nodes of the same mode hold missing values, not 0. The nodes are ordered by name, not by mode; `_nwmode` (1 or 2) says which mode a row belongs to.

## Commands that make a new network keep the two modes

`nwdropnodes`, `nwkeepnodes`, `nwsubset`, `nwduplicate`, `nwsym`, `nwtranspose`, `nwrecode`, `nwdichotomize`, `nwaddnodes` (the option `mode()` is required) and `nwpermute` return a two-mode network with the modes of the remaining nodes and the level labels. (Before this version, `nwdropnodes` and `nwkeepnodes` returned a one-mode network, and the other commands lost the level labels.) `nwcollapse` refuses a two-mode network. `nw2project` and `nwproject` return an ordinary one-mode network of one mode.

## The rule: a two-mode network gets its two-mode form

A network declares itself two-mode when it is created. A command that has a two-mode form of the same concept uses that form **automatically** on a two-mode network, and the option `onemode` forces the one-mode computation on the bipartite graph, which is what `igraph` does with a bipartite graph. The commands are `nwdegree`, `nwclustering`, `nwmotifs`, `nwcloseness`, `nwbetween`, `nwcommunity`, `nwmodularity`, `nwsimilar` and `nwdissimilar`. The older names `nw2degree`, `nw2clustering` and `nw2motifs` stay as aliases of `nwdegree`, `nwclustering` and `nwmotifs` (same options, same results) and still stop on a one-mode network. `nw2project` and `nw2nested` have no one-mode counterpart and keep their own names.

## What each command does

The help file of every command states in its section "Supported network types" one of four fixed wordings:

| Wording | Meaning | Commands |
|---|---|---|
| **Two-mode: yes** - what changes | The command uses the two modes the way R does. | `nw2project`, `nw2nested`, `nwmatching`, `nwpermute`, `nwdyads`, `nwsummarize`, `nwexport`, `nwimport`, `nwtoedge`, `nw2toedge`, `nwplot`, `nwplotmatrix`, `nwturnover` and the commands that keep the modes above |
| **Two-mode: two-mode form by default ...** | The command has a two-mode form of the same concept and uses it on a two-mode network; `onemode` forces the one-mode computation. | `nwdegree`, `nwclustering`, `nwmotifs`, `nwcloseness`, `nwbetween`, `nwcommunity`, `nwmodularity`, `nwsimilar`, `nwdissimilar` (`nw2degree`, `nw2clustering`, `nw2motifs` are aliases) |
| **Two-mode: same as for the bipartite graph read as a one-mode network** | The measure is defined on any graph and the number is right for the bipartite graph; nothing is printed. | `nwcomponents`, `nwkcore`, `nwgeodesic`, `nwevcent`, `nwpagerank`, `nwburt`, `nwconstraint`, `nwbridges`, `nwcohesion`, `nwtriads`, ... (see the [table](../network-types/)) |
| **Two-mode: not supported - error 6088** | The command would read the blocks between nodes of the same mode, which hold no ties. It stops with one message. | `nwspectral`, `nwrandomwalk`, `nwcorrelate`, `nwhierarchy`, `nwconcor`, `nwfactions`, `nwcoreperiphery`, `nwqap`, `nwinduced`, `nwcollapse` |

The message is the same for all of them: "*command* does not support two-mode networks (*net*): it reads the blocks between nodes of the same mode, which hold no ties. Make a one-mode network of one mode first (nwproject)." `nwspectral` and `nwrandomwalk` add that the option `onemode` reads the bipartite graph as a one-mode graph, which is what `igraph` does (the Laplacian spectrum and the hitting times of a random walk exist for a bipartite graph).

## Measures with a two-mode form in R

| Command | Two-mode result | R |
|---|---|---|
| `nwdegree` (`nw2degree`) | degree divided by the size of the other mode (Borgatti and Everett 1997); `raw` gives the count | `tnet::degree_tm` (the count) |
| `nwclustering` (`nw2clustering`) | Opsahl's (2013) coefficient, the share of four-paths closed by a fifth tie: Southern women .772, directors .0029 | `tnet::clustering_tm` |
| `nwclustering, ra` | Robins and Alexander's (2004) global coefficient 4 C4 / L3: Southern women .468, directors .0228 | (formula; `igraph` has none) |
| `nw2project` | the projection onto one mode; `stat(count)` is the number of shared nodes, `stat(newman)` Newman's weight 1/(k - 1) per shared node | `igraph::bipartite_projection`, `tnet::projecting_tm` |
| `nw2nested` | NODF and the C-score (Southern women NODF 48.6, C-score normalised .449) | `vegan::nestednodf`, `bipartite::nested`, `bipartite::C.score` |
| `nwmotifs` (`nw2motifs`) | the 17 bipartite motifs of two to five nodes (44 with `sixnode`) of Simmons et al. (2019) and the 46 (148) positions of every node; counts ties above zero (Southern women: 89 single ties, 4-cycles motif 6 = 341, as `bmotif`) | `bmotif::mcount`, `bmotif::node_positions` |
| `nwcommunity`, `nwmodularity` | Barber's (2007) bipartite modularity; `onemode` gives Newman's. Southern women: Q .3455 with 4 communities, as `computeModules` | `bipartite::computeModules` |
| `nwsimilar`, `nwdissimilar` | a node is compared with the nodes of its own mode over the nodes of the other mode; pairs of nodes from different modes are missing | `sna::sedist`, `cor`, `dist` on the incidence matrix |
| `nwpermute` | the labels are permuted within the modes; `swap` exchanges the partners of two ties and keeps both degree sequences | `tnet::rg_reshuffling_tm`, `bipartite::swap.web` |
| `nwcloseness`, `nwbetween` | the normalisations of Borgatti and Everett (1997): the smallest possible farness over the farness, the betweenness over the largest possible value of a node of its mode; `onemode` gives the raw numbers of the bipartite graph (`twomode`, the earlier way to ask for the normalisation, is accepted) | (formulas; `igraph::closeness`, `igraph::betweenness` for `onemode`) |
| `nwmatching` | maximum matching between the modes | `igraph::max_bipartite_match` |
| `nwdyads` | null dyads counted over the pairs between the modes (Southern women 163 of 252 pairs); reciprocity is shown as n/a | |

Two things are worth knowing. The density of a two-mode network is the number of ties over the pairs of one node of each mode (Southern women .353 = 89 / 252, the connectance of the `bipartite` package), not over all pairs of nodes. And `nw2degree`, `nw2clustering`, `nw2motifs`, `nw2project` and `nw2nested` need a two-mode network and stop on a one-mode network; `nwdegree`, `nwclustering` and `nwmotifs` work on both.

## Edge lists and files

`nwtoedge` and `nw2toedge` write a two-mode network as its ties, one row per tie, with the mode of both nodes; `allpairs` writes the row of every pair of nodes of different modes as before. Read the list back with `nwfromedge ..., twomode` or `nw2fromedge`: the network has the same nodes (the isolated ones included), the same ties and the level labels.

`nwexport` and `nwimport` keep the modes in all four formats:

| Format | Two-mode form |
|---|---|
| Pajek | `*Vertices n n1`, the nodes of the first mode first, each tie from a first-mode to a second-mode vertex |
| UCINET | a rectangular matrix (`nr`, `nc`) with row and column labels |
| edge list | five columns: ego, alter, value, mode of the ego, mode of the alter; an isolated node has no row |
| GML | the node attribute `nwmode` (1 or 2); in R, `V(g)$type <- V(g)$nwmode == 2` |

Pajek, the edge list and GML do not carry the names of the two levels; they come back as `mode 1` and `mode 2`. `nwsave` and `nwuse` keep them.

## Not done yet

Fast tie swapping for networks with hundreds of thousands of ties and the further indices of `bipartite::networklevel` (H2' and others). Two-mode exponential random graph terms (b1 and b2) belong to `nwergm`; the core only keeps the flag and the modes correct for them.

## References

Almeida-Neto, M., Guimaraes, P., Guimaraes, P. R., Loyola, R. D., and Ulrich, W. (2008). A consistent metric for nestedness analysis in ecological systems. *Oikos* 117, 1227-1239.
Barber, M. J. (2007). Modularity and community detection in bipartite networks. *Physical Review E* 76, 066102.
Borgatti, S. P., and Everett, M. G. (1997). Network analysis of 2-mode data. *Social Networks* 19, 243-269.
Newman, M. E. J. (2001). Scientific collaboration networks. II. Shortest paths, weighted networks, and centrality. *Physical Review E* 64, 016132.
Opsahl, T. (2013). Triadic closure in two-mode networks: Redefining the global and local clustering coefficients. *Social Networks* 35, 159-167.
Robins, G., and Alexander, M. (2004). Small worlds among interlocking directors: Network structure and distance in bipartite graphs. *Computational and Mathematical Organization Theory* 10, 69-94.
Stone, L., and Roberts, A. (1990). The checkerboard score and species distributions. *Oecologia* 85, 74-79.
