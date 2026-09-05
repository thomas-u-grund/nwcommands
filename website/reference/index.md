---
title: "Command reference"
nav_order: 3
has_children: false
---

# Command reference

All nwcommands commands, grouped as in `help nw_topical`.

## Concepts

- [`netexample`](netexample.md)
- [`netexp`](netexp.md) --- Network expression and function
- [`netlist`](netlist.md)
- [`netname`](netname.md)
- [`newnetname`](newnetname.md)
- [`nodeid`](nodeid.md)

## Import/Export

- [`nw2fromedge`](nw2fromedge.md) --- Import two-mode network data from edgelist
- [`nw2set`](nw2set.md) --- Declare data to be two-mode network data
- [`nw2toedge`](nw2toedge.md) --- Convert two-mode network to edgelist
- [`nwappend`](nwappend.md) --- Append network dataset
- [`nwexport`](nwexport.md) --- Export network as Pajek or Ucinet file
- [`nwfromedge`](nwfromedge.md) --- Imports network data from edgelist
- [`nwimport`](nwimport.md) --- Import network
- [`nwsave`](nwsave.md) --- Save network data in file
- [`nwset`](nwset.md) --- Declare data to be network data
- [`nwtoedge`](nwtoedge.md) --- Convert network to edgelist
- [`nwuse`](nwuse.md) --- Load Stata network dataset
- [`nwwebuse`](nwwebuse.md) --- Load network data over the web

## Generators

- [`nwbridges`](nwbridges.md) --- Calculate bridges
- [`nwdissimilar`](nwdissimilar.md) --- Generate node dissimilarities
- [`nwduplicate`](nwduplicate.md) --- Duplicate a network
- [`nwdyadprob`](nwdyadprob.md) --- Generate a network based on tie probabilities
- [`nwexpand`](nwexpand.md) --- Expand variable to network
- [`nwgen`](nwgen.md) --- Network extensions to generate
- [`nwgenerate`](nwgenerate.md) --- Network extensions to generate
- [`nwgenvar`](nwgenvar.md) --- Network extensions to generate
- [`nwgeodesic`](nwgeodesic.md) --- Calculate shortest paths between
- [`nwhomophily`](nwhomophily.md) --- Generate a homophily network
- [`nwlattice`](nwlattice.md) --- Generate a lattice network
- [`nwpath`](nwpath.md) --- Calculate paths between nodes
- [`nwpermute`](nwpermute.md) --- Generate permutation of a network
- [`nwpref`](nwpref.md) --- Generate a preferential-attachment network
- [`nwrandom`](nwrandom.md) --- Generate a random network
- [`nwreach`](nwreach.md) --- Calculate reachability network
- [`nwring`](nwring.md) --- Generate a ring-lattice network
- [`nwsimilar`](nwsimilar.md) --- Generate node similarities
- [`nwsmall`](nwsmall.md) --- Generate a small-world network
- [`nwsubset`](nwsubset.md) --- Subset the nodes of a network
- [`nwtranspose`](nwtranspose.md) --- Transpose a network

## Information

- [`nwcurrent`](nwcurrent.md) --- Report and set current network
- [`nwdyads`](nwdyads.md) --- Dyad census
- [`nwissymmetric`](nwissymmetric.md) --- Check if network is symmetric
- [`nwmotifs`](nwmotifs.md) --- 4-node undirected motif/graphlet census
- [`nwname`](nwname.md) --- Obtain and change meta-information of a network
- [`nwsummarize`](nwsummarize.md) --- Summarize a network
- [`nwtabulate`](nwtabulate.md) --- One-way table of dyads
- [`nwtriads`](nwtriads.md) --- Triad census of the network

## Manipulation

- [`nw2project`](nw2project.md) --- One-mode projection of a two-mode network
- [`nwaddnodes`](nwaddnodes.md) --- Add nodes to network
- [`nwattime`](nwattime.md) --- Static graph view of a temporal network at a given time
- [`nwcollapse`](nwcollapse.md) --- Collapse a network
- [`nwdichotomize`](nwdichotomize.md) --- Dichotomize a network at a threshold (built on [nwrecode](nwrecode.md))
- [`nwdrop`](nwdrop.md) --- Drop networks or network nodes
- [`nwdropnodes`](nwdropnodes.md) --- Drop nodes from a network
- [`nwkeep`](nwkeep.md) --- Keep a network (or only certain nodes)
- [`nwkeepnodes`](nwkeepnodes.md) --- Keep nodes of a network
- [`nwname`](nwname.md) --- Obtain and change meta-information of a network
- [`nwnoderename`](nwnoderename.md) --- Rename a single node in a network
- [`nwpreserve`](nwpreserve.md) --- Preserve and restore network data
- [`nwproject`](nwproject.md) --- One-mode projection of a two-mode network (alias for [nw2project](nw2project.md))
- [`nwrecode`](nwrecode.md) --- Recode network
- [`nwrename`](nwrename.md) --- Rename a network
- [`nwreplace`](nwreplace.md) --- Replace network
- [`nwreplacemat`](nwreplacemat.md) --- Replace network with Stata or Mata matrix
- [`nwrestore`](nwrestore.md) --- Restore network data previously preserved
- [`nwsubset`](nwsubset.md) --- Subset the nodes of a network
- [`nwsym`](nwsym.md) --- Symmetrize network
- [`nwsymmetrize`](nwsymmetrize.md) --- Symmetrize network (alias for [nwsym](nwsym.md))
- [`nwtranspose`](nwtranspose.md) --- Transpose a network

## Analysis

### ] Centrality

- [`nw2degree`](nw2degree.md) --- Two-mode (bipartite) degree centrality
- [`nwbetween`](nwbetween.md) --- Calculate betweenness centrality
- [`nwcentrality`](nwcentrality.md) --- Node centrality measures
- [`nwcloseness`](nwcloseness.md) --- Calculate closeness centrality
- [`nwdegree`](nwdegree.md) --- Degree centrality and distribution
- [`nwevcent`](nwevcent.md) --- Calculate eigenvector centrality
- [`nwinduced`](nwinduced.md) --- Induced, endogenous and exogenous centrality
- [`nwkatz`](nwkatz.md) --- Calculate a Katz-inspired distance-decay centrality
- [`nwpagerank`](nwpagerank.md) --- PageRank centrality

### ] Cohesion, Component

- [`nwbridges`](nwbridges.md) --- Calculate bridges
- [`nwclique`](nwclique.md) --- Maximal clique enumeration
- [`nwcomponents`](nwcomponents.md) --- Calculate network components / largest component
- [`nwkcomponents`](nwkcomponents.md) --- Maximal k-component enumeration
- [`nwkcore`](nwkcore.md) --- k-core decomposition
- [`nwkplex`](nwkplex.md) --- Maximal k-plex enumeration
- [`nwnclan`](nwnclan.md) --- Maximal n-clan enumeration
- [`nwnclique`](nwnclique.md) --- Maximal n-clique enumeration
- [`nwsimmelian`](nwsimmelian.md) --- Calculate Simmelian ties

### ] Community Detection

- [`nwcommunity`](nwcommunity.md) --- Detect communities via the Louvain method or label propagation
- [`nwmodularity`](nwmodularity.md) --- Score an existing node partition using Newman's modularity
- [`nwspectral`](nwspectral.md) --- Graph Laplacian spectral analysis

### ] Positions, Roles &

- [`nw2clustering`](nw2clustering.md) --- Clustering coefficient (transitivity) of a two-mode network
- [`nwassortativity`](nwassortativity.md) --- Newman's assortativity coefficient
- [`nwbalance`](nwbalance.md) --- Structural balance of a signed network
- [`nwbrokerage`](nwbrokerage.md) --- Gould-Fernandez brokerage roles
- [`nwburt`](nwburt.md) --- Calculate Burt structural hole measures
- [`nwclustering`](nwclustering.md) --- Clustering coefficient (transitivity) of a network
- [`nwconcor`](nwconcor.md) --- CONCOR structural-equivalence blockmodel
- [`nwconstraint`](nwconstraint.md) --- Calculate Burt's constraint
- [`nwcoreperiphery`](nwcoreperiphery.md) --- Discrete core-periphery detection
- [`nwdissimilar`](nwdissimilar.md) --- Generate node dissimilarities
- [`nwfactions`](nwfactions.md) --- Partition nodes into a specified number of cohesive factions
- [`nwhierarchy`](nwhierarchy.md) --- Hierarchical clustering of nodes (role/position analysis)
- [`nwlambda`](nwlambda.md) --- Edge (line) connectivity matrix between all node pairs
- [`nwmatching`](nwmatching.md) --- Maximum-cardinality bipartite matching
- [`nwmixing`](nwmixing.md) --- E-I index and mixing table for a categorical node attribute
- [`nwshared`](nwshared.md) --- Calculate number of shared neighbors between nodes and saves information in network
- [`nwsimilar`](nwsimilar.md) --- Generate node similarities
- [`nwsimindex`](nwsimindex.md) --- Common-neighbor similarity indices between all node pairs

### ] Paths, Reachability

- [`nwaltergen`](nwaltergen.md) --- Generate a variable from alter/neighbor attributes
- [`nwego`](nwego.md) --- Ego-network size and density
- [`nwgeodesic`](nwgeodesic.md) --- Calculate shortest paths between
- [`nwmaxflow`](nwmaxflow.md) --- Maximum flow and minimum cut between two nodes
- [`nwneighbor`](nwneighbor.md) --- Extract the network neighbors of a node
- [`nwpath`](nwpath.md) --- Calculate paths between nodes
- [`nwrandomwalk`](nwrandomwalk.md) --- Mean random-walk hitting time to a target node
- [`nwreach`](nwreach.md) --- Calculate reachability network

### ] Statistical Estimat

- [`nwdynam`](nwdynam.md) --- Dynamic Network Actor Model - choice, rate, and choice_coordination sub-models (MLE)
- [`nwrem`](nwrem.md) --- Relational event model (ordinal partial likelihood, MLE)

### ] Other Analysis Util

- [`nwcontext`](nwcontext.md) --- Create a context variable
- [`nwgen`](nwgen.md) --- Network extensions to generate
- [`nwgenerate`](nwgenerate.md) --- Network extensions to generate
- [`nwgenvar`](nwgenvar.md) --- Network extensions to generate
- [`nwnode`](nwnode.md) --- Checks if node exists in a network
- [`nwturnover`](nwturnover.md) --- Tie turnover/stability between two waves of the same network
- [`nwvalue`](nwvalue.md) --- Returns a tie value

### Utility Commands

- [`nwds`](nwds.md) --- List loaded networks, in the style of Stata's own `ds`

## Utilities

- [`nw_datasync`](nw_datasync.md) --- Utility to sync current network with dataset
- [`nw_errorcodes`](nw_errorcodes.md) --- What this package's own custom return codes mean
- [`nw_networktypes`](nw_networktypes.md) --- How commands classify binary/directed/weighted/signed/two-mode networks
- [`nw_tomata`](nw_tomata.md) --- Return adjacency matrix of network
- [`nw_unab`](nw_unab.md) --- Unabbreviate network list
- [`nwclear`](nwclear.md) --- Clear all networks and variables from memory
- [`nwcurrent`](nwcurrent.md) --- Report and set current network
- [`nwinstall`](nwinstall.md) --- Install Stata menu/dialogs
- [`nwload`](nwload.md) --- Load a network as Stata variables
- [`nworder`](nworder.md) --- Reorder networks in dataset
- [`nwsync`](nwsync.md) --- Sync network with Stata variables
- [`nwtomata`](nwtomata.md) --- Return adjacency matrix of network
- [`nwtomatafast`](nwtomatafast.md) --- Return link to adjacency matrix of network
- [`nwtostata`](nwtostata.md) --- Copy a Mata matrix into Stata variables
- [`nwunab`](nwunab.md) --- Unabbreviate network list
- [`nwvalidate`](nwvalidate.md) --- Validate network name
- [`nwvalidvars`](nwvalidvars.md) --- Validate Stata variables for network

## Visualization

- [`nwdendrogram`](nwdendrogram.md) --- Plot a wheel dendrogram
- [`nwmovie`](nwmovie.md) --- Interactive, animated network movie (panel waves or a relational-event timeline)
- [`nwmoviexy`](nwmoviexy.md) --- Animate a sequence of networks (alias for **nwmovie**)
- [`nwplot`](nwplot.md) --- Plot a network
- [`nwplotmatrix`](nwplotmatrix.md) --- Plot a network as sociomatrix

## Programming

- [`_nwnodeid`](_nwnodeid.md) --- Returns the nodeid of a node given its node label
- [`_nwnodelab`](_nwnodelab.md) --- Returns the nodelab of a node given its nodeid
- [`nwcompressobs`](nwcompressobs.md) --- Compresses observations in Stata

## Uncategorized

- [`_extract_valuelabels`](_extract_valuelabels.md) --- errno help file yet
- [`_gnwdegree`](_gnwdegree.md) --- errno help file yet
- [`_growmedian2`](_growmedian2.md) --- errno help file yet
- [`_nwdeploy`](_nwdeploy.md) --- errno help file yet
- [`_nwdialog`](_nwdialog.md) --- errno help file yet
- [`_nwdialog_append`](_nwdialog_append.md) --- errno help file yet
- [`_nwdialog_clusters`](_nwdialog_clusters.md) --- errno help file yet
- [`_nwdialog_lablist`](_nwdialog_lablist.md) --- errno help file yet
- [`_nwevalnetexp`](_nwevalnetexp.md) --- errno help file yet
- [`_nwsetobs`](_nwsetobs.md) --- errno help file yet
- [`_opts_oneof`](_opts_oneof.md) --- errno help file yet
- [`nw_clear`](nw_clear.md) --- errno help file yet
- [`nw_edgelabs`](nw_edgelabs.md) --- errno help file yet
- [`nw_evalnetexp`](nw_evalnetexp.md) --- errno help file yet
- [`nw_expnetexp`](nw_expnetexp.md) --- errno help file yet
- [`nw_helpwriter`](nw_helpwriter.md) --- errno help file yet
- [`nw_name`](nw_name.md) --- errno help file yet
- [`nw_openviewer`](nw_openviewer.md) --- errno help file yet
- [`nw_optsoneof`](nw_optsoneof.md) --- errno help file yet
- [`nw_resetrc`](nw_resetrc.md) --- errno help file yet
- [`nw_syntax`](nw_syntax.md) --- errno help file yet
- [`nw_validate`](nw_validate.md) --- errno help file yet
- [`schemeinfo`](schemeinfo.md) --- errno help file yet
- [`unw_defs`](unw_defs.md) --- errno help file yet

## Uncategorized

- [`animate`](animate.md)
- [`nw_alphabetical`](nw_alphabetical.md)
- [`nw_intro`](nw_intro.md)
- [`nw_programming`](nw_programming.md)
- [`nw_start`](nw_start.md)
- [`nw_topical`](nw_topical.md)
- [`nwcohesion`](nwcohesion.md)
- [`nwcommands`](nwcommands.md)
- [`nwcorrelate`](nwcorrelate.md)
- [`nwcug`](nwcug.md)
- [`nwergm`](nwergm.md)
- [`nwergm_estat`](nwergm_estat.md)
- [`nwqap`](nwqap.md)
- [`nwsaom`](nwsaom.md)
- [`nwsaom_estat`](nwsaom_estat.md)
- [`nwtab1`](nwtab1.md)
- [`nwtab2`](nwtab2.md)
- [`nwtab3`](nwtab3.md)
- [`nwutility`](nwutility.md)
