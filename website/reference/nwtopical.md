---
title: "nwtopical"
parent: "Command reference"
grand_parent: "nwcommands (core)"
nav_exclude: true
search_exclude: false
---

# `nwtopical`

## Contents

**SectionDescription**

- hline 50
- [**[NW-2.1]****Concepts**](nwtopical)
- [**[NW-2.2]****Import/Export**](nwtopical)
- [**[NW-2.3]****Generators**](nwtopical)
- [**[NW-2.4]****Information**](nwtopical)
- [**[NW-2.5]****Manipulation**](nwtopical)
- [**[NW-2.6]****Analysis**](nwtopical)
- [[NW-2.6.1]Centrality](nwtopical)
- [[NW-2.6.2]Cohesion, components and subgroups](nwtopical)
- [[NW-2.6.3]Communities](nwtopical)
- [[NW-2.6.4]Positions, roles and similarity](nwtopical)
- [[NW-2.6.5]Clustering, mixing and balance](nwtopical)
- [[NW-2.6.6]Paths, flows and ego networks](nwtopical)
- [[NW-2.6.7]Statistical tests](nwtopical)
- [[NW-2.6.8]Other analysis tools](nwtopical)
- [**[NW-2.7]****Utilities**](nwtopical)
- [**[NW-2.8]****Visualization**](nwtopical)
- [**[NW-2.9]****Programming**](nwtopical)
- [**[NW-2.10]****Statistical models (separate packages)**](nwtopical)

- hline 24
- hline 3 *Concepts*
- hline 24

- **[netexample](netexample)** --- Example network data sets
- **[netexp](netexp)** --- Network expression and function
- **[netlist](netlist)** --- List of existing networks
- **[netname](netname)** --- Name of an existing network
- **[newnetname](newnetname)** --- Name of a new network
- **[nodeid](nodeid)** --- Identification of nodes

- hline 27
- hline 3 *Import/Export*
- hline 27

- **[nw2fromedge](nw2fromedge)** --- Import two-mode network data from an edge list
- **[nw2set](nw2set)** --- Declare data to be two-mode network data
- **[nw2toedge](nw2toedge)** --- Convert a two-mode network to an edge list
- **[nwappend](nwappend)** --- Append a network dataset
- **[nwexport](nwexport)** --- Export a network as a Pajek, UCINET, GML or edge list file
- **[nwfromedge](nwfromedge)** --- Import network data from an edge list
- **[nwimport](nwimport)** --- Import a network from a Pajek, UCINET, GML or edge list file
- **[nwsave](nwsave)** --- Save network data in a file
- **[nwset](nwset)** --- Declare data to be network data
- **[nwtoedge](nwtoedge)** --- Convert a network to an edge list
- **[nwuse](nwuse)** --- Load a Stata network dataset
- **[nwwebuse](nwwebuse)** --- Load network data over the web

- hline 24
- hline 3 *Generators*
- hline 24

- **[nwduplicate](nwduplicate)** --- Duplicate a network
- **[nwdyadprob](nwdyadprob)** --- Generate a network based on tie probabilities
- **[nwexpand](nwexpand)** --- Expand a variable to a network
- **[nwgen](nwgen)** --- Generate variables or networks with network functions (like egen)
- **[nwgenerate](nwgenerate)** --- Generate a network from a function or a network expression
- **[nwgenvar](nwgenvar)** --- Generate variables or networks with network functions (like egen)
- **[nwhomophily](nwhomophily)** --- Generate a homophily network
- **[nwlattice](nwlattice)** --- Generate a lattice network
- **[nwpermute](nwpermute)** --- Generate a permutation of a network
- **[nwpref](nwpref)** --- Generate a preferential-attachment network
- **[nwrandom](nwrandom)** --- Generate a random network
- **[nwring](nwring)** --- Generate a ring-lattice network
- **[nwsmall](nwsmall)** --- Generate a small-world network

- hline 25
- hline 3 *Information*
- hline 25

- **[nwds](nwds)** --- List the networks in memory (like ds)
- **[nwdyads](nwdyads)** --- Dyad census
- **[nwissymmetric](nwissymmetric)** --- Check whether a network is symmetric
- **[nwmotifs](nwmotifs)** --- 4-node undirected motif/graphlet census
- **[nwname](nwname)** --- Obtain and change meta-information of a network
- **[nwsummarize](nwsummarize)** --- Summarize a network
- **[nwtabulate](nwtabulate)** --- One-way table of dyads
- **[nwtriads](nwtriads)** --- Triad census of a network

- hline 26
- hline 3 *Manipulation*
- hline 26

- **[nw2project](nw2project)** --- One-mode projection of a two-mode network
- **[nwaddnodes](nwaddnodes)** --- Add nodes to network
- **[nwattime](nwattime)** --- Static graph view of a temporal network at a given time
- **[nwcollapse](nwcollapse)** --- Collapse a network
- **[nwdichotomize](nwdichotomize)** --- Dichotomize a network at a threshold
- **[nwdrop](nwdrop)** --- Drop networks or nodes
- **[nwdropnodes](nwdropnodes)** --- Drop nodes from a network
- **[nwkeep](nwkeep)** --- Keep networks or nodes
- **[nwkeepnodes](nwkeepnodes)** --- Keep nodes of a network
- **[nwnoderename](nwnoderename)** --- Rename a single node in a network
- **[nwpreserve](nwpreserve)** --- Preserve and restore network data
- **[nwproject](nwproject)** --- One-mode projection of a two-mode network (alias for nw2project)
- **[nwrecode](nwrecode)** --- Recode a network
- **[nwrename](nwrename)** --- Rename a network
- **[nwreplace](nwreplace)** --- Replace a network
- **[nwreplacemat](nwreplacemat)** --- Replace network with Stata or Mata matrix
- **[nwrestore](nwrestore)** --- Restore network data previously preserved
- **[nwstack](nwstack)** --- Stack several networks into one block-diagonal network
- **[nwsubset](nwsubset)** --- Subset the nodes of a network
- **[nwsym](nwsym)** --- Symmetrize a network
- **[nwsymmetrize](nwsymmetrize)** --- Symmetrize a network (alias for nwsym)
- **[nwtranspose](nwtranspose)** --- Transpose a network

- hline 24
- hline 3 *Analysis*
- hline 24

- ***Centrality***

- **[nw2degree](nw2degree)** --- Two-mode (bipartite) degree centrality
- **[nwbetween](nwbetween)** --- Betweenness centrality
- **[nwcentrality](nwcentrality)** --- Node centrality measures
- **[nwcloseness](nwcloseness)** --- Closeness centrality
- **[nwdegree](nwdegree)** --- Degree centrality and distribution
- **[nwevcent](nwevcent)** --- Eigenvector centrality
- **[nwinduced](nwinduced)** --- Induced, endogenous and exogenous centrality
- **[nwkatz](nwkatz)** --- Katz-style distance-decay centrality
- **[nwpagerank](nwpagerank)** --- PageRank centrality

- ***Cohesion, components and subgroups***

- **[nwbridges](nwbridges)** --- Find bridges (ties whose removal disconnects the network)
- **[nwclique](nwclique)** --- Maximal clique enumeration
- **[nwcohesion](nwcohesion)** --- Moody-White structural cohesion hierarchy
- **[nwcomponents](nwcomponents)** --- Network components and the largest component
- **[nwkcomponents](nwkcomponents)** --- Maximal k-component enumeration
- **[nwkcore](nwkcore)** --- k-core decomposition
- **[nwkplex](nwkplex)** --- Maximal k-plex enumeration
- **[nwnclan](nwnclan)** --- Maximal n-clan enumeration
- **[nwnclique](nwnclique)** --- Maximal n-clique enumeration
- **[nwsimmelian](nwsimmelian)** --- Simmelian ties

- ***Communities***

- **[nwcommunity](nwcommunity)** --- Detect communities via the Louvain method or label propagation
- **[nwmodularity](nwmodularity)** --- Score an existing node partition using Newman's modularity
- **[nwspectral](nwspectral)** --- Graph Laplacian spectral analysis

- ***Positions, roles and similarity***

- **[nwbrokerage](nwbrokerage)** --- Gould-Fernandez brokerage roles
- **[nwburt](nwburt)** --- Burt's structural-hole measures
- **[nwconcor](nwconcor)** --- CONCOR structural-equivalence blockmodel
- **[nwconstraint](nwconstraint)** --- Burt's constraint
- **[nwcoreperiphery](nwcoreperiphery)** --- Discrete core-periphery detection
- **[nwdissimilar](nwdissimilar)** --- Generate node dissimilarities
- **[nwfactions](nwfactions)** --- Partition nodes into a specified number of cohesive factions
- **[nwhierarchy](nwhierarchy)** --- Hierarchical clustering of nodes (role/position analysis)
- **[nwregular](nwregular)** --- Classes of regularly equivalent nodes
- **[nwshared](nwshared)** --- Number of shared neighbors of all pairs of nodes, as a network
- **[nwsimilar](nwsimilar)** --- Generate node similarities
- **[nwsimindex](nwsimindex)** --- Common-neighbor similarity indices between all node pairs

- ***Clustering, mixing and balance***

- **[nw2clustering](nw2clustering)** --- Clustering coefficient (transitivity) of a two-mode network
- **[nw2motifs](nw2motifs)** --- Bipartite motifs of a two-mode network
- **[nw2nested](nw2nested)** --- Nestedness of a two-mode network: NODF and C-score
- **[nwassortativity](nwassortativity)** --- Newman's assortativity coefficient
- **[nwbalance](nwbalance)** --- Structural balance of a signed network
- **[nwclustering](nwclustering)** --- Clustering coefficient (transitivity) of a network
- **[nwmixing](nwmixing)** --- E-I index and mixing table for a categorical node attribute

- ***Paths, flows and ego networks***

- **[nwaltergen](nwaltergen)** --- Generate a variable from alter/neighbor attributes
- **[nwego](nwego)** --- Ego-network size and density
- **[nwgeodesic](nwgeodesic)** --- Calculate shortest paths between nodes
- **[nwlambda](nwlambda)** --- Edge (line) connectivity matrix between all node pairs
- **[nwmatching](nwmatching)** --- Maximum-cardinality bipartite matching
- **[nwmaxflow](nwmaxflow)** --- Maximum flow and minimum cut between two nodes
- **[nwneighbor](nwneighbor)** --- Extract the network neighbors of a node
- **[nwpath](nwpath)** --- Paths between nodes
- **[nwrandomwalk](nwrandomwalk)** --- Mean random-walk hitting time to a target node
- **[nwreach](nwreach)** --- Reachability network

- ***Statistical tests***

- **[nwcorrelate](nwcorrelate)** --- Correlate networks and variables
- **[nwcug](nwcug)** --- Conditional Uniform Graph (CUG) test
- **[nwqap](nwqap)** --- Multivariate QAP regression
- **[nwutility](nwutility)** --- Utility scores of Jackson and Wolinsky (1996)

- ***Other analysis tools***

- **[nwcontext](nwcontext)** --- Create a context variable
- **[nwnode](nwnode)** --- Check whether a node exists in a network
- **[nwturnover](nwturnover)** --- Tie turnover/stability between two waves of the same network
- **[nwvalue](nwvalue)** --- Return a tie value

- hline 24
- hline 3 *Utilities*
- hline 24

- **[nwclear](nwclear)** --- Clear all networks and variables from memory
- **[nwcurrent](nwcurrent)** --- Report and set current network
- **[nwerrorcodes](nwerrorcodes)** --- Return codes of nwcommands
- **[nwinstall](nwinstall)** --- Install the dialogs, menus and the model packages
- **[nwload](nwload)** --- Load a network as Stata variables
- **[nwnetworktypes](nwnetworktypes)** --- How commands classify binary/directed/weighted/signed/two-mode networks
- **[nworder](nworder)** --- Reorder the networks in memory
- **[nwversion](nwversion)** --- Version of nwcommands and of the installed model packages

- hline 27
- hline 3 *Visualization*
- hline 27

- **[animate](animate)** --- Animate graphs
- **[nwdendrogram](nwdendrogram)** --- Plot a wheel dendrogram
- **[nwegoplot](nwegoplot)** --- Draw the ego network of one node, ego in the center
- **[nwmovie](nwmovie)** --- Interactive, animated network movie (panel waves or a relational-event timeline)
- **[nwmoviexy](nwmoviexy)** --- Animate a sequence of networks (alias for nwmovie)
- **[nwplot](nwplot)** --- Plot a network
- **[nwplotmatrix](nwplotmatrix)** --- Plot a network as sociomatrix

- hline 25
- hline 3 *Programming*
- hline 25

- **[nwcompressobs](nwcompressobs)** --- Drop observations that no network needs
- **[nwsync](nwsync)** --- Synchronize a network with Stata variables
- **[nwtomata](nwtomata)** --- Return the adjacency matrix of a network
- **[nwtomatafast](nwtomatafast)** --- Return a link to the adjacency matrix of a network
- **[nwtostata](nwtostata)** --- Copy a Mata matrix into Stata variables
- **[nwunab](nwunab)** --- Unabbreviate network list
- **[nwvalidate](nwvalidate)** --- Validate a network name
- **[nwvalidvars](nwvalidvars)** --- Validate Stata variables for a network

- hline 52
- hline 3 *Statistical models (separate packages)*
- hline 52

The statistical network models are separate packages that need the core. Install them with `nwinstall, models` (see [nwinstall](nwinstall); [nwversion](nwversion) shows which are installed). Which package do you need? See browse "https://nwcommands.org/which-package/".

- **[nwsaom](https://nwcommands.org/nwsaom/)** --- Stochastic actor-oriented models (SAOM): network and behavior dynamics between observed waves
- **[nwergm](https://nwcommands.org/nwergm/)** --- Exponential random graph models (ERGM) for cross-sectional networks
- **[nwdynam](https://nwcommands.org/nwdynam/)** --- Dynamic network actor models (DyNAM): choice and rate models for event sequences
- **[nwrem](https://nwcommands.org/nwrem/)** --- Relational event models (REM) for timed interaction events

---

*nwcommands version 3.22.0, 13 November 2026* ([check your installed version](nwversion))
