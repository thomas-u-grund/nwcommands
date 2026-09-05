---
title: "Command reference"
nav_order: 3
has_children: false
---

# Command reference

All nwcommands commands, grouped as in `help nwtopical`.

## Concepts

- [`netexample`](netexample)
- [`netexp`](netexp) --- Network expression and function
- [`netlist`](netlist)
- [`netname`](netname)
- [`newnetname`](newnetname)
- [`nodeid`](nodeid)

## Import/Export

- [`nw2fromedge`](nw2fromedge) --- Import two-mode network data from edgelist
- [`nw2set`](nw2set) --- Declare data to be two-mode network data
- [`nw2toedge`](nw2toedge) --- Convert two-mode network to edgelist
- [`nwappend`](nwappend) --- Append network dataset
- [`nwexport`](nwexport) --- Export network as Pajek or Ucinet file
- [`nwfromedge`](nwfromedge) --- Imports network data from edgelist
- [`nwimport`](nwimport) --- Import network
- [`nwsave`](nwsave) --- Save network data in file
- [`nwset`](nwset) --- Declare data to be network data
- [`nwtoedge`](nwtoedge) --- Convert network to edgelist
- [`nwuse`](nwuse) --- Load Stata network dataset
- [`nwwebuse`](nwwebuse) --- Load network data over the web

## Generators

- [`nwbridges`](nwbridges) --- Calculate bridges
- [`nwdissimilar`](nwdissimilar) --- Generate node dissimilarities
- [`nwduplicate`](nwduplicate) --- Duplicate a network
- [`nwdyadprob`](nwdyadprob) --- Generate a network based on tie probabilities
- [`nwexpand`](nwexpand) --- Expand variable to network
- [`nwgen`](nwgen) --- Network extensions to generate
- [`nwgenerate`](nwgenerate) --- Network extensions to generate
- [`nwgenvar`](nwgenvar) --- Network extensions to generate
- [`nwgeodesic`](nwgeodesic) --- Calculate shortest paths between
- [`nwhomophily`](nwhomophily) --- Generate a homophily network
- [`nwlattice`](nwlattice) --- Generate a lattice network
- [`nwpath`](nwpath) --- Calculate paths between nodes
- [`nwpermute`](nwpermute) --- Generate permutation of a network
- [`nwpref`](nwpref) --- Generate a preferential-attachment network
- [`nwrandom`](nwrandom) --- Generate a random network
- [`nwreach`](nwreach) --- Calculate reachability network
- [`nwring`](nwring) --- Generate a ring-lattice network
- [`nwsimilar`](nwsimilar) --- Generate node similarities
- [`nwsmall`](nwsmall) --- Generate a small-world network
- [`nwsubset`](nwsubset) --- Subset the nodes of a network
- [`nwtranspose`](nwtranspose) --- Transpose a network

## Information

- [`nwcurrent`](nwcurrent) --- Report and set current network
- [`nwdyads`](nwdyads) --- Dyad census
- [`nwissymmetric`](nwissymmetric) --- Check if network is symmetric
- [`nwmotifs`](nwmotifs) --- 4-node undirected motif/graphlet census
- [`nwname`](nwname) --- Obtain and change meta-information of a network
- [`nwsummarize`](nwsummarize) --- Summarize a network
- [`nwtabulate`](nwtabulate) --- One-way table of dyads
- [`nwtriads`](nwtriads) --- Triad census of the network

## Manipulation

- [`nw2project`](nw2project) --- One-mode projection of a two-mode network
- [`nwaddnodes`](nwaddnodes) --- Add nodes to network
- [`nwattime`](nwattime) --- Static graph view of a temporal network at a given time
- [`nwcollapse`](nwcollapse) --- Collapse a network
- [`nwdichotomize`](nwdichotomize) --- Dichotomize a network at a threshold (built on [nwrecode](nwrecode))
- [`nwdrop`](nwdrop) --- Drop networks or network nodes
- [`nwdropnodes`](nwdropnodes) --- Drop nodes from a network
- [`nwkeep`](nwkeep) --- Keep a network (or only certain nodes)
- [`nwkeepnodes`](nwkeepnodes) --- Keep nodes of a network
- [`nwname`](nwname) --- Obtain and change meta-information of a network
- [`nwnoderename`](nwnoderename) --- Rename a single node in a network
- [`nwpreserve`](nwpreserve) --- Preserve and restore network data
- [`nwproject`](nwproject) --- One-mode projection of a two-mode network (alias for [nw2project](nw2project))
- [`nwrecode`](nwrecode) --- Recode network
- [`nwrename`](nwrename) --- Rename a network
- [`nwreplace`](nwreplace) --- Replace network
- [`nwreplacemat`](nwreplacemat) --- Replace network with Stata or Mata matrix
- [`nwrestore`](nwrestore) --- Restore network data previously preserved
- [`nwsubset`](nwsubset) --- Subset the nodes of a network
- [`nwsym`](nwsym) --- Symmetrize network
- [`nwsymmetrize`](nwsymmetrize) --- Symmetrize network (alias for [nwsym](nwsym))
- [`nwtranspose`](nwtranspose) --- Transpose a network

## Analysis

### [NW-2.6.1] Centrality

- [`nw2degree`](nw2degree) --- Two-mode (bipartite) degree centrality
- [`nwbetween`](nwbetween) --- Calculate betweenness centrality
- [`nwcentrality`](nwcentrality) --- Node centrality measures
- [`nwcloseness`](nwcloseness) --- Calculate closeness centrality
- [`nwdegree`](nwdegree) --- Degree centrality and distribution
- [`nwevcent`](nwevcent) --- Calculate eigenvector centrality
- [`nwinduced`](nwinduced) --- Induced, endogenous and exogenous centrality
- [`nwkatz`](nwkatz) --- Calculate a Katz-inspired distance-decay centrality
- [`nwpagerank`](nwpagerank) --- PageRank centrality

### [NW-2.6.2] Cohesion, Components & Subgroups

- [`nwbridges`](nwbridges) --- Calculate bridges
- [`nwclique`](nwclique) --- Maximal clique enumeration
- [`nwcomponents`](nwcomponents) --- Calculate network components / largest component
- [`nwkcomponents`](nwkcomponents) --- Maximal k-component enumeration
- [`nwkcore`](nwkcore) --- k-core decomposition
- [`nwkplex`](nwkplex) --- Maximal k-plex enumeration
- [`nwnclan`](nwnclan) --- Maximal n-clan enumeration
- [`nwnclique`](nwnclique) --- Maximal n-clique enumeration
- [`nwsimmelian`](nwsimmelian) --- Calculate Simmelian ties

### [NW-2.6.3] Community Detection

- [`nwcommunity`](nwcommunity) --- Detect communities via the Louvain method or label propagation
- [`nwmodularity`](nwmodularity) --- Score an existing node partition using Newman's modularity
- [`nwspectral`](nwspectral) --- Graph Laplacian spectral analysis

### [NW-2.6.4] Positions, Roles & Equivalence

- [`nw2clustering`](nw2clustering) --- Clustering coefficient (transitivity) of a two-mode network
- [`nwassortativity`](nwassortativity) --- Newman's assortativity coefficient
- [`nwbalance`](nwbalance) --- Structural balance of a signed network
- [`nwbrokerage`](nwbrokerage) --- Gould-Fernandez brokerage roles
- [`nwburt`](nwburt) --- Calculate Burt structural hole measures
- [`nwclustering`](nwclustering) --- Clustering coefficient (transitivity) of a network
- [`nwconcor`](nwconcor) --- CONCOR structural-equivalence blockmodel
- [`nwconstraint`](nwconstraint) --- Calculate Burt's constraint
- [`nwcoreperiphery`](nwcoreperiphery) --- Discrete core-periphery detection
- [`nwdissimilar`](nwdissimilar) --- Generate node dissimilarities
- [`nwfactions`](nwfactions) --- Partition nodes into a specified number of cohesive factions
- [`nwhierarchy`](nwhierarchy) --- Hierarchical clustering of nodes (role/position analysis)
- [`nwlambda`](nwlambda) --- Edge (line) connectivity matrix between all node pairs
- [`nwmatching`](nwmatching) --- Maximum-cardinality bipartite matching
- [`nwmixing`](nwmixing) --- E-I index and mixing table for a categorical node attribute
- [`nwshared`](nwshared) --- Calculate number of shared neighbors between nodes and saves information in network
- [`nwsimilar`](nwsimilar) --- Generate node similarities
- [`nwsimindex`](nwsimindex) --- Common-neighbor similarity indices between all node pairs

### [NW-2.6.5] Paths, Reachability & Ego Networks

- [`nwaltergen`](nwaltergen) --- Generate a variable from alter/neighbor attributes
- [`nwego`](nwego) --- Ego-network size and density
- [`nwgeodesic`](nwgeodesic) --- Calculate shortest paths between
- [`nwmaxflow`](nwmaxflow) --- Maximum flow and minimum cut between two nodes
- [`nwneighbor`](nwneighbor) --- Extract the network neighbors of a node
- [`nwpath`](nwpath) --- Calculate paths between nodes
- [`nwrandomwalk`](nwrandomwalk) --- Mean random-walk hitting time to a target node
- [`nwreach`](nwreach) --- Calculate reachability network

### [NW-2.6.6] Statistical Estimation

- [`nwcorrelate`](nwcorrelate) --- Correlate networks and variables
- [`nwcug`](nwcug) --- Conditional Uniform Graph (CUG) test
- [`nwergm`](nwergm) --- Exponential-family random graph model (ERGM) estimation
- [`nwqap`](nwqap) --- Multivariate QAP regression
- [`nwsaom`](nwsaom) --- Stochastic actor-oriented model (SAOM) estimation between observed network waves
- [`nwutility`](nwutility) --- Calculate utility scores according to Jackson and Wollinsky (1996)

### [NW-2.6.7] Other Analysis Utilities

- [`nwcontext`](nwcontext) --- Create a context variable
- [`nwgen`](nwgen) --- Network extensions to generate
- [`nwgenerate`](nwgenerate) --- Network extensions to generate
- [`nwgenvar`](nwgenvar) --- Network extensions to generate
- [`nwnode`](nwnode) --- Checks if node exists in a network
- [`nwturnover`](nwturnover) --- Tie turnover/stability between two waves of the same network
- [`nwvalue`](nwvalue) --- Returns a tie value

### [NW-2.6.8] Dynamic & Event-Based Models

- [`nwdynam`](nwdynam) --- Dynamic Network Actor Model - choice, rate, and choice_coordination sub-models (MLE)
- [`nwrem`](nwrem) --- Relational event model (ordinal partial likelihood, MLE)

### Utility Commands

- [`nwds`](nwds) --- List loaded networks, in the style of Stata's own `ds`

## Utilities

- [`nwclear`](nwclear) --- Clear all networks and variables from memory
- [`nwcurrent`](nwcurrent) --- Report and set current network
- [`nwerrorcodes`](nwerrorcodes) --- What this package's own custom return codes mean
- [`nwinstall`](nwinstall) --- Install Stata menu/dialogs
- [`nwload`](nwload) --- Load a network as Stata variables
- [`nwnetworktypes`](nwnetworktypes) --- How commands classify binary/directed/weighted/signed/two-mode networks
- [`nworder`](nworder) --- Reorder networks in dataset
- [`nwsync`](nwsync) --- Sync network with Stata variables
- [`nwtomata`](nwtomata) --- Return adjacency matrix of network
- [`nwtomatafast`](nwtomatafast) --- Return link to adjacency matrix of network
- [`nwtostata`](nwtostata) --- Copy a Mata matrix into Stata variables
- [`nwunab`](nwunab) --- Unabbreviate network list
- [`nwvalidate`](nwvalidate) --- Validate network name
- [`nwvalidvars`](nwvalidvars) --- Validate Stata variables for network

## Visualization

- [`nwdendrogram`](nwdendrogram) --- Plot a wheel dendrogram
- [`nwmovie`](nwmovie) --- Interactive, animated network movie (panel waves or a relational-event timeline)
- [`nwmoviexy`](nwmoviexy) --- Animate a sequence of networks (alias for **nwmovie**)
- [`nwplot`](nwplot) --- Plot a network
- [`nwplotmatrix`](nwplotmatrix) --- Plot a network as sociomatrix

## Programming

- [`nwcompressobs`](nwcompressobs) --- Compresses observations in Stata

## Uncategorized

- [`nw_helpwriter`](nw_helpwriter) --- errno help file yet
- [`nw_resetrc`](nw_resetrc) --- errno help file yet
- [`schemeinfo`](schemeinfo) --- errno help file yet
- [`unw_defs`](unw_defs) --- errno help file yet

- [`_nwdatasync`](_nwdatasync)
- [`_nwnodeid`](_nwnodeid)
- [`_nwnodelab`](_nwnodelab)
- [`_nwtomata`](_nwtomata)
- [`animate`](animate)
- [`nwalphabetical`](nwalphabetical)
- [`nwcohesion`](nwcohesion)
- [`nwcommands`](nwcommands)
- [`nwergm_estat`](nwergm_estat)
- [`nwinternals`](nwinternals)
- [`nwintro`](nwintro)
- [`nwprogramming`](nwprogramming)
- [`nwsaom_estat`](nwsaom_estat)
- [`nwsaom_remarks`](nwsaom_remarks)
- [`nwstart`](nwstart)
- [`nwtab1`](nwtab1)
- [`nwtab2`](nwtab2)
- [`nwtab3`](nwtab3)
- [`nwtopical`](nwtopical)
