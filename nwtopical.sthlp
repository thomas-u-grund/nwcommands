{smcl}
{* *! version 2.0 5sep2026}{...}
{phang}
{help nwcommands:NW-2 topical} {hline 2} 
{hline 2} Topical list of network commands

{title:Contents}

{col 14}Section{col 31}Description
{col 14}{hline 46}
{help nwtopical##concept:{col 14}{bf:[NW-2.1]}{...}{col 31}{bf:Concepts}}

{help nwtopical##import:{col 14}{bf:[NW-2.2]}{...}{col 31}{bf:Import/Export}}

{help nwtopical##generator:{col 14}{bf:[NW-2.3]}{...}{col 31}{bf:Generators}}

{help nwtopical##information:{col 14}{bf:[NW-2.4]}{...}{col 31}{bf:Information}}

{help nwtopical##manipulation:{col 14}{bf:[NW-2.5]}{...}{col 31}{bf:Manipulation}}

{help nwtopical##analysis:{col 14}{bf:[NW-2.6]}{...}{col 31}{bf:Analysis}}

{help nwtopical##utilities:{col 14}{bf:[NW-2.7]}{...}{col 31}{bf:Utilities}}

{help nwtopical##visualization:{col 14}{bf:[NW-2.8]}{...}{col 31}{bf:Visualization}}

{help nwtopical##programming:{col 14}{bf:[NW-2.9]}{...}{col 31}{bf:Programming}}

{marker concept}{...}

{col 8}   {c TLC}{hline 24}{c TRC}
{col 8}{hline 3}{c RT}       {it:Concepts}{col 36}{c LT}{hline}
{col 8}   {c BLC}{hline 24}{c BRC}
{p2colset 12 35 36 2}
{p2col:    {bf:{help netexample }}}{p_end}
{p2col:    {bf:{help netexp }}}Network expression and function{p_end}
{p2col:    {bf:{help netlist }}}{p_end}
{p2col:    {bf:{help netname }}}{p_end}
{p2col:    {bf:{help newnetname }}}{p_end}
{p2col:    {bf:{help nodeid }}}{p_end}
{marker import}{...}

{col 8}   {c TLC}{hline 24}{c TRC}
{col 8}{hline 3}{c RT}       {it:Import/Export}{col 36}{c LT}{hline}
{col 8}   {c BLC}{hline 24}{c BRC}
{p2colset 12 35 36 2}
{p2col:    {bf:{help nw2fromedge }}}Import two-mode network data from edgelist{p_end}
{p2col:    {bf:{help nw2set }}}Declare data to be two-mode network data{p_end}
{p2col:    {bf:{help nw2toedge }}}Convert two-mode network to edgelist{p_end}
{p2col:    {bf:{help nwappend }}}Append network dataset{p_end}
{p2col:    {bf:{help nwexport }}}Export network as Pajek or Ucinet file{p_end}
{p2col:    {bf:{help nwfromedge }}}Imports network data from edgelist{p_end}
{p2col:    {bf:{help nwimport }}}Import network{p_end}
{p2col:    {bf:{help nwsave }}}Save network data in file{p_end}
{p2col:    {bf:{help nwset }}}Declare data to be network data{p_end}
{p2col:    {bf:{help nwtoedge }}}Convert network to edgelist{p_end}
{p2col:    {bf:{help nwuse }}}Load Stata network dataset{p_end}
{p2col:    {bf:{help nwwebuse }}}Load network data over the web{p_end}
{marker generator}{...}

{col 8}   {c TLC}{hline 24}{c TRC}
{col 8}{hline 3}{c RT}       {it:Generators}{col 36}{c LT}{hline}
{col 8}   {c BLC}{hline 24}{c BRC}
{p2colset 12 35 36 2}
{p2col:    {bf:{help nwbridges }}}Calculate bridges{p_end}
{p2col:    {bf:{help nwdissimilar }}}Generate node dissimilarities{p_end}
{p2col:    {bf:{help nwduplicate }}}Duplicate a network{p_end}
{p2col:    {bf:{help nwdyadprob }}}Generate a network based on tie probabilities{p_end}
{p2col:    {bf:{help nwexpand }}}Expand variable to network{p_end}
{p2col:    {bf:{help nwgen }}}Network extensions to generate{p_end}
{p2col:    {bf:{help nwgenerate }}}Network extensions to generate{p_end}
{p2col:    {bf:{help nwgenvar }}}Network extensions to generate{p_end}
{p2col:    {bf:{help nwgeodesic }}}Calculate shortest paths between{p_end}
{p2col:    {bf:{help nwhomophily }}}Generate a homophily network{p_end}
{p2col:    {bf:{help nwlattice }}}Generate a lattice network{p_end}
{p2col:    {bf:{help nwpath }}}Calculate paths between nodes{p_end}
{p2col:    {bf:{help nwpermute }}}Generate permutation of a network{p_end}
{p2col:    {bf:{help nwpref }}}Generate a preferential-attachment network{p_end}
{p2col:    {bf:{help nwrandom }}}Generate a random network{p_end}
{p2col:    {bf:{help nwreach }}}Calculate reachability network{p_end}
{p2col:    {bf:{help nwring }}}Generate a ring-lattice network{p_end}
{p2col:    {bf:{help nwsimilar }}}Generate node similarities{p_end}
{p2col:    {bf:{help nwsmall }}}Generate a small-world network{p_end}
{p2col:    {bf:{help nwsubset }}}Subset the nodes of a network{p_end}
{p2col:    {bf:{help nwtranspose }}}Transpose a network{p_end}
{marker information}{...}

{col 8}   {c TLC}{hline 24}{c TRC}
{col 8}{hline 3}{c RT}       {it:Information}{col 36}{c LT}{hline}
{col 8}   {c BLC}{hline 24}{c BRC}
{p2colset 12 35 36 2}
{p2col:    {bf:{help nwcurrent }}}Report and set current network{p_end}
{p2col:    {bf:{help nwdyads }}}Dyad census{p_end}
{p2col:    {bf:{help nwissymmetric }}}Check if network is symmetric{p_end}
{p2col:    {bf:{help nwmotifs }}}4-node undirected motif/graphlet census{p_end}
{p2col:    {bf:{help nwname }}}Obtain and change meta-information of a network{p_end}
{p2col:    {bf:{help nwsummarize }}}Summarize a network{p_end}
{p2col:    {bf:{help nwtabulate }}}One-way table of dyads{p_end}
{p2col:    {bf:{help nwtriads }}}Triad census of the network{p_end}
{marker manipulation}{...}

{col 8}   {c TLC}{hline 24}{c TRC}
{col 8}{hline 3}{c RT}       {it:Manipulation}{col 36}{c LT}{hline}
{col 8}   {c BLC}{hline 24}{c BRC}
{p2colset 12 35 36 2}
{p2col:    {bf:{help nw2project }}}One-mode projection of a two-mode network{p_end}
{p2col:    {bf:{help nwaddnodes }}}Add nodes to network{p_end}
{p2col:    {bf:{help nwattime }}}Static graph view of a temporal network at a given time{p_end}
{p2col:    {bf:{help nwcollapse }}}Collapse a network{p_end}
{p2col:    {bf:{help nwdichotomize }}}Dichotomize a network at a threshold (built on {help nwrecode}){p_end}
{p2col:    {bf:{help nwdrop }}}Drop networks or network nodes{p_end}
{p2col:    {bf:{help nwdropnodes }}}Drop nodes from a network{p_end}
{p2col:    {bf:{help nwkeep }}}Keep a network (or only certain nodes){p_end}
{p2col:    {bf:{help nwkeepnodes }}}Keep nodes of a network{p_end}
{p2col:    {bf:{help nwname }}}Obtain and change meta-information of a network{p_end}
{p2col:    {bf:{help nwnoderename }}}Rename a single node in a network{p_end}
{p2col:    {bf:{help nwpreserve }}}Preserve and restore network data{p_end}
{p2col:    {bf:{help nwproject }}}One-mode projection of a two-mode network (alias for {help nw2project}){p_end}
{p2col:    {bf:{help nwrecode }}}Recode network{p_end}
{p2col:    {bf:{help nwrename }}}Rename a network{p_end}
{p2col:    {bf:{help nwreplace }}}Replace network{p_end}
{p2col:    {bf:{help nwreplacemat }}}Replace network with Stata or Mata matrix{p_end}
{p2col:    {bf:{help nwrestore }}}Restore network data previously preserved{p_end}
{p2col:    {bf:{help nwsubset }}}Subset the nodes of a network{p_end}
{p2col:    {bf:{help nwsym }}}Symmetrize network{p_end}
{p2col:    {bf:{help nwsymmetrize }}}Symmetrize network (alias for {help nwsym}){p_end}
{p2col:    {bf:{help nwtranspose }}}Transpose a network{p_end}
{marker analysis}{...}
{marker analysis_centrality}{...}

{col 8}   {c TLC}{hline 24}{c TRC}
{col 8}{hline 3}{c RT}       {it:Centrality}{col 36}{c LT}{hline}
{col 8}   {c BLC}{hline 24}{c BRC}
{p2colset 12 35 36 2}
{p2col:    {bf:{help nw2degree }}}Two-mode (bipartite) degree centrality{p_end}
{p2col:    {bf:{help nwbetween }}}Calculate betweenness centrality{p_end}
{p2col:    {bf:{help nwcentrality }}}Node centrality measures{p_end}
{p2col:    {bf:{help nwcloseness }}}Calculate closeness centrality{p_end}
{p2col:    {bf:{help nwdegree }}}Degree centrality and distribution{p_end}
{p2col:    {bf:{help nwevcent }}}Calculate eigenvector centrality{p_end}
{p2col:    {bf:{help nwinduced }}}Induced, endogenous and exogenous centrality{p_end}
{p2col:    {bf:{help nwkatz }}}Calculate a Katz-inspired distance-decay centrality{p_end}
{p2col:    {bf:{help nwpagerank }}}PageRank centrality{p_end}
{marker analysis_cohesion}{...}

{col 8}   {c TLC}{hline 24}{c TRC}
{col 8}{hline 3}{c RT}       {it:Cohesion, Components & Subgroups}{col 36}{c LT}{hline}
{col 8}   {c BLC}{hline 24}{c BRC}
{p2colset 12 35 36 2}
{p2col:    {bf:{help nwbridges }}}Calculate bridges{p_end}
{p2col:    {bf:{help nwclique }}}Maximal clique enumeration{p_end}
{p2col:    {bf:{help nwcomponents }}}Calculate network components / largest component{p_end}
{p2col:    {bf:{help nwkcomponents }}}Maximal k-component enumeration{p_end}
{p2col:    {bf:{help nwkcore }}}k-core decomposition{p_end}
{p2col:    {bf:{help nwkplex }}}Maximal k-plex enumeration{p_end}
{p2col:    {bf:{help nwnclan }}}Maximal n-clan enumeration{p_end}
{p2col:    {bf:{help nwnclique }}}Maximal n-clique enumeration{p_end}
{p2col:    {bf:{help nwsimmelian }}}Calculate Simmelian ties{p_end}
{marker analysis_community}{...}

{col 8}   {c TLC}{hline 24}{c TRC}
{col 8}{hline 3}{c RT}       {it:Community Detection}{col 36}{c LT}{hline}
{col 8}   {c BLC}{hline 24}{c BRC}
{p2colset 12 35 36 2}
{p2col:    {bf:{help nwcommunity }}}Detect communities via the Louvain method or label propagation{p_end}
{p2col:    {bf:{help nwmodularity }}}Score an existing node partition using Newman's modularity{p_end}
{p2col:    {bf:{help nwspectral }}}Graph Laplacian spectral analysis{p_end}
{marker analysis_positions}{...}

{col 8}   {c TLC}{hline 24}{c TRC}
{col 8}{hline 3}{c RT}       {it:Positions, Roles & Equivalence}{col 36}{c LT}{hline}
{col 8}   {c BLC}{hline 24}{c BRC}
{p2colset 12 35 36 2}
{p2col:    {bf:{help nw2clustering }}}Clustering coefficient (transitivity) of a two-mode network{p_end}
{p2col:    {bf:{help nwassortativity }}}Newman's assortativity coefficient{p_end}
{p2col:    {bf:{help nwbalance }}}Structural balance of a signed network{p_end}
{p2col:    {bf:{help nwbrokerage }}}Gould-Fernandez brokerage roles{p_end}
{p2col:    {bf:{help nwburt }}}Calculate Burt structural hole measures{p_end}
{p2col:    {bf:{help nwclustering }}}Clustering coefficient (transitivity) of a network{p_end}
{p2col:    {bf:{help nwconcor }}}CONCOR structural-equivalence blockmodel{p_end}
{p2col:    {bf:{help nwconstraint }}}Calculate Burt's constraint{p_end}
{p2col:    {bf:{help nwcoreperiphery }}}Discrete core-periphery detection{p_end}
{p2col:    {bf:{help nwdissimilar }}}Generate node dissimilarities{p_end}
{p2col:    {bf:{help nwfactions }}}Partition nodes into a specified number of cohesive factions{p_end}
{p2col:    {bf:{help nwhierarchy }}}Hierarchical clustering of nodes (role/position analysis){p_end}
{p2col:    {bf:{help nwlambda }}}Edge (line) connectivity matrix between all node pairs{p_end}
{p2col:    {bf:{help nwmatching }}}Maximum-cardinality bipartite matching{p_end}
{p2col:    {bf:{help nwmixing }}}E-I index and mixing table for a categorical node attribute{p_end}
{p2col:    {bf:{help nwshared }}}Calculate number of shared neighbors between nodes and saves information in network{p_end}
{p2col:    {bf:{help nwsimilar }}}Generate node similarities{p_end}
{p2col:    {bf:{help nwsimindex }}}Common-neighbor similarity indices between all node pairs{p_end}
{marker analysis_paths}{...}

{col 8}   {c TLC}{hline 24}{c TRC}
{col 8}{hline 3}{c RT}       {it:Paths, Reachability & Ego Networks}{col 36}{c LT}{hline}
{col 8}   {c BLC}{hline 24}{c BRC}
{p2colset 12 35 36 2}
{p2col:    {bf:{help nwaltergen }}}Generate a variable from alter/neighbor attributes{p_end}
{p2col:    {bf:{help nwego }}}Ego-network size and density{p_end}
{p2col:    {bf:{help nwgeodesic }}}Calculate shortest paths between{p_end}
{p2col:    {bf:{help nwmaxflow }}}Maximum flow and minimum cut between two nodes{p_end}
{p2col:    {bf:{help nwneighbor }}}Extract the network neighbors of a node{p_end}
{p2col:    {bf:{help nwpath }}}Calculate paths between nodes{p_end}
{p2col:    {bf:{help nwrandomwalk }}}Mean random-walk hitting time to a target node{p_end}
{p2col:    {bf:{help nwreach }}}Calculate reachability network{p_end}
{marker analysis_statmodels}{...}

{col 8}   {c TLC}{hline 24}{c TRC}
{col 8}{hline 3}{c RT}       {it:Statistical Estimation of Networks}{col 36}{c LT}{hline}
{col 8}   {c BLC}{hline 24}{c BRC}
{p2colset 12 35 36 2}
{p2col:    {bf:{help nwcorrelate }}}Correlate networks and variables{p_end}
{p2col:    {bf:{help nwcug }}}Conditional Uniform Graph (CUG) test{p_end}
{p2col:    {bf:{help nwergm }}}Exponential-family random graph model (ERGM) estimation{p_end}
{p2col:    {bf:{help nwqap }}}Multivariate QAP regression{p_end}
{p2col:    {bf:{help nwsaom }}}Stochastic actor-oriented model (SAOM) estimation between observed network waves{p_end}
{p2col:    {bf:{help nwutility }}}Calculate utility scores according to Jackson and Wollinsky (1996){p_end}
{marker analysis_other}{...}

{col 8}   {c TLC}{hline 24}{c TRC}
{col 8}{hline 3}{c RT}       {it:Other Analysis Utilities}{col 36}{c LT}{hline}
{col 8}   {c BLC}{hline 24}{c BRC}
{p2colset 12 35 36 2}
{p2col:    {bf:{help nwcontext }}}Create a context variable{p_end}
{p2col:    {bf:{help nwgen }}}Network extensions to generate{p_end}
{p2col:    {bf:{help nwgenerate }}}Network extensions to generate{p_end}
{p2col:    {bf:{help nwgenvar }}}Network extensions to generate{p_end}
{p2col:    {bf:{help nwnode }}}Checks if node exists in a network{p_end}
{p2col:    {bf:{help nwturnover }}}Tie turnover/stability between two waves of the same network{p_end}
{p2col:    {bf:{help nwvalue }}}Returns a tie value{p_end}
{marker analysis_dynamicmodels}{...}

{col 8}   {c TLC}{hline 24}{c TRC}
{col 8}{hline 3}{c RT}       {it:Dynamic & Event-Based Models}{col 36}{c LT}{hline}
{col 8}   {c BLC}{hline 24}{c BRC}
{p2colset 12 35 36 2}
{p2col:    {bf:{help nwdynam }}}Dynamic Network Actor Model - choice, rate, and choice_coordination sub-models (MLE){p_end}
{p2col:    {bf:{help nwrem }}}Relational event model (ordinal partial likelihood, MLE){p_end}
{marker utilities}{...}

{col 8}   {c TLC}{hline 24}{c TRC}
{col 8}{hline 3}{c RT}       {it:Utilities}{col 36}{c LT}{hline}
{col 8}   {c BLC}{hline 24}{c BRC}
{p2colset 12 35 36 2}
{p2col:    {bf:{help nwclear }}}Clear all networks and variables from memory{p_end}
{p2col:    {bf:{help nwcurrent }}}Report and set current network{p_end}
{p2col:    {bf:{help nwerrorcodes }}}What this package's own custom return codes mean{p_end}
{p2col:    {bf:{help nwinstall }}}Install Stata menu/dialogs{p_end}
{p2col:    {bf:{help nwload }}}Load a network as Stata variables{p_end}
{p2col:    {bf:{help nwnetworktypes }}}How commands classify binary/directed/weighted/signed/two-mode networks{p_end}
{p2col:    {bf:{help nworder }}}Reorder networks in dataset{p_end}
{p2col:    {bf:{help nwsync }}}Sync network with Stata variables{p_end}
{p2col:    {bf:{help nwtomata }}}Return adjacency matrix of network{p_end}
{p2col:    {bf:{help nwtomatafast }}}Return link to adjacency matrix of network{p_end}
{p2col:    {bf:{help nwtostata }}}Copy a Mata matrix into Stata variables{p_end}
{p2col:    {bf:{help nwunab }}}Unabbreviate network list{p_end}
{p2col:    {bf:{help nwvalidate }}}Validate network name{p_end}
{p2col:    {bf:{help nwvalidvars }}}Validate Stata variables for network{p_end}
{marker analysis_utility}{...}

{col 8}   {c TLC}{hline 24}{c TRC}
{col 8}{hline 3}{c RT}       {it:Utility Commands}{col 36}{c LT}{hline}
{col 8}   {c BLC}{hline 24}{c BRC}
{p2colset 12 35 36 2}
{p2col:    {bf:{help nwds }}}List loaded networks, in the style of Stata's own {help ds}{p_end}
{marker visualization}{...}

{col 8}   {c TLC}{hline 24}{c TRC}
{col 8}{hline 3}{c RT}       {it:Visualization}{col 36}{c LT}{hline}
{col 8}   {c BLC}{hline 24}{c BRC}
{p2colset 12 35 36 2}
{p2col:    {bf:{help nwdendrogram }}}Plot a wheel dendrogram{p_end}
{p2col:    {bf:{help nwmovie }}}Interactive, animated network movie (panel waves or a relational-event timeline){p_end}
{p2col:    {bf:{help nwmoviexy }}}Animate a sequence of networks (alias for {bf:nwmovie}){p_end}
{p2col:    {bf:{help nwplot }}}Plot a network{p_end}
{p2col:    {bf:{help nwplotmatrix }}}Plot a network as sociomatrix{p_end}
{marker programming}{...}

{col 8}   {c TLC}{hline 24}{c TRC}
{col 8}{hline 3}{c RT}       {it:Programming}{col 36}{c LT}{hline}
{col 8}   {c BLC}{hline 24}{c BRC}
{p2colset 12 35 36 2}
{p2col:    {bf:{help nwcompressobs }}}Compresses observations in Stata{p_end}
{marker uncategorized}{...}

{col 8}   {c TLC}{hline 24}{c TRC}
{col 8}{hline 3}{c RT}       {it:Uncategorized}{col 36}{c LT}{hline}
{col 8}   {c BLC}{hline 24}{c BRC}
{p2colset 12 35 36 2}
{p2col:{bf:{help nw_helpwriter }}}{err}no help file yet{txt}{p_end}
{p2col:{bf:{help nw_resetrc }}}{err}no help file yet{txt}{p_end}
{p2col:{bf:{help schemeinfo }}}{err}no help file yet{txt}{p_end}
{p2col:{bf:{help unw_defs }}}{err}no help file yet{txt}{p_end}
