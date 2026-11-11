{smcl}
{* *! version 3.18.0  11nov2026}{...}
{phang}
{help nwcommands:NW-2 topical} {hline 2} Topical list of network commands

{title:Contents}

{col 14}Section{col 33}Description
{col 14}{hline 50}
{help nwtopical##concept:{col 14}{bf:[NW-2.1]}{col 33}{bf:Concepts}}
{help nwtopical##import:{col 14}{bf:[NW-2.2]}{col 33}{bf:Import/Export}}
{help nwtopical##generator:{col 14}{bf:[NW-2.3]}{col 33}{bf:Generators}}
{help nwtopical##information:{col 14}{bf:[NW-2.4]}{col 33}{bf:Information}}
{help nwtopical##manipulation:{col 14}{bf:[NW-2.5]}{col 33}{bf:Manipulation}}
{help nwtopical##analysis:{col 14}{bf:[NW-2.6]}{col 33}{bf:Analysis}}
{help nwtopical##analysis_centrality:{col 16}[NW-2.6.1]{col 35}Centrality}
{help nwtopical##analysis_cohesion:{col 16}[NW-2.6.2]{col 35}Cohesion, components and subgroups}
{help nwtopical##analysis_community:{col 16}[NW-2.6.3]{col 35}Communities}
{help nwtopical##analysis_positions:{col 16}[NW-2.6.4]{col 35}Positions, roles and similarity}
{help nwtopical##analysis_clustering:{col 16}[NW-2.6.5]{col 35}Clustering, mixing and balance}
{help nwtopical##analysis_paths:{col 16}[NW-2.6.6]{col 35}Paths, flows and ego networks}
{help nwtopical##analysis_statmodels:{col 16}[NW-2.6.7]{col 35}Statistical tests}
{help nwtopical##analysis_other:{col 16}[NW-2.6.8]{col 35}Other analysis tools}
{help nwtopical##utilities:{col 14}{bf:[NW-2.7]}{col 33}{bf:Utilities}}
{help nwtopical##visualization:{col 14}{bf:[NW-2.8]}{col 33}{bf:Visualization}}
{help nwtopical##programming:{col 14}{bf:[NW-2.9]}{col 33}{bf:Programming}}
{help nwtopical##models:{col 14}{bf:[NW-2.10]}{col 33}{bf:Statistical models (separate packages)}}


{marker concept}{...}
{col 8}   {c TLC}{hline 24}{c TRC}
{col 8}{hline 3}{c RT}       {it:Concepts}{col 36}{c LT}{hline}
{col 8}   {c BLC}{hline 24}{c BRC}
{p2colset 12 35 36 2}
{p2col:    {bf:{help netexample }}}Example network data sets{p_end}
{p2col:    {bf:{help netexp }}}Network expression and function{p_end}
{p2col:    {bf:{help netlist }}}List of existing networks{p_end}
{p2col:    {bf:{help netname }}}Name of an existing network{p_end}
{p2col:    {bf:{help newnetname }}}Name of a new network{p_end}
{p2col:    {bf:{help nodeid }}}Identification of nodes{p_end}

{marker import}{...}
{col 8}   {c TLC}{hline 27}{c TRC}
{col 8}{hline 3}{c RT}       {it:Import/Export}{col 39}{c LT}{hline}
{col 8}   {c BLC}{hline 27}{c BRC}
{p2colset 12 35 36 2}
{p2col:    {bf:{help nw2fromedge }}}Import two-mode network data from an edge list{p_end}
{p2col:    {bf:{help nw2set }}}Declare data to be two-mode network data{p_end}
{p2col:    {bf:{help nw2toedge }}}Convert a two-mode network to an edge list{p_end}
{p2col:    {bf:{help nwappend }}}Append a network dataset{p_end}
{p2col:    {bf:{help nwexport }}}Export a network as a Pajek, UCINET, GML or edge list file{p_end}
{p2col:    {bf:{help nwfromedge }}}Import network data from an edge list{p_end}
{p2col:    {bf:{help nwimport }}}Import a network from a Pajek, UCINET, GML or edge list file{p_end}
{p2col:    {bf:{help nwsave }}}Save network data in a file{p_end}
{p2col:    {bf:{help nwset }}}Declare data to be network data{p_end}
{p2col:    {bf:{help nwtoedge }}}Convert a network to an edge list{p_end}
{p2col:    {bf:{help nwuse }}}Load a Stata network dataset{p_end}
{p2col:    {bf:{help nwwebuse }}}Load network data over the web{p_end}

{marker generator}{...}
{col 8}   {c TLC}{hline 24}{c TRC}
{col 8}{hline 3}{c RT}       {it:Generators}{col 36}{c LT}{hline}
{col 8}   {c BLC}{hline 24}{c BRC}
{p2colset 12 35 36 2}
{p2col:    {bf:{help nwduplicate }}}Duplicate a network{p_end}
{p2col:    {bf:{help nwdyadprob }}}Generate a network based on tie probabilities{p_end}
{p2col:    {bf:{help nwexpand }}}Expand a variable to a network{p_end}
{p2col:    {bf:{help nwgen }}}Generate variables or networks with network functions (like egen){p_end}
{p2col:    {bf:{help nwgenerate }}}Generate a network from a function or a network expression{p_end}
{p2col:    {bf:{help nwgenvar }}}Generate variables or networks with network functions (like egen){p_end}
{p2col:    {bf:{help nwhomophily }}}Generate a homophily network{p_end}
{p2col:    {bf:{help nwlattice }}}Generate a lattice network{p_end}
{p2col:    {bf:{help nwpermute }}}Generate a permutation of a network{p_end}
{p2col:    {bf:{help nwpref }}}Generate a preferential-attachment network{p_end}
{p2col:    {bf:{help nwrandom }}}Generate a random network{p_end}
{p2col:    {bf:{help nwring }}}Generate a ring-lattice network{p_end}
{p2col:    {bf:{help nwsmall }}}Generate a small-world network{p_end}

{marker information}{...}
{col 8}   {c TLC}{hline 25}{c TRC}
{col 8}{hline 3}{c RT}       {it:Information}{col 37}{c LT}{hline}
{col 8}   {c BLC}{hline 25}{c BRC}
{p2colset 12 35 36 2}
{p2col:    {bf:{help nwds }}}List the networks in memory (like ds){p_end}
{p2col:    {bf:{help nwdyads }}}Dyad census{p_end}
{p2col:    {bf:{help nwissymmetric }}}Check whether a network is symmetric{p_end}
{p2col:    {bf:{help nwmotifs }}}4-node undirected motif/graphlet census{p_end}
{p2col:    {bf:{help nwname }}}Obtain and change meta-information of a network{p_end}
{p2col:    {bf:{help nwsummarize }}}Summarize a network{p_end}
{p2col:    {bf:{help nwtabulate }}}One-way table of dyads{p_end}
{p2col:    {bf:{help nwtriads }}}Triad census of a network{p_end}

{marker manipulation}{...}
{col 8}   {c TLC}{hline 26}{c TRC}
{col 8}{hline 3}{c RT}       {it:Manipulation}{col 38}{c LT}{hline}
{col 8}   {c BLC}{hline 26}{c BRC}
{p2colset 12 35 36 2}
{p2col:    {bf:{help nw2project }}}One-mode projection of a two-mode network{p_end}
{p2col:    {bf:{help nwaddnodes }}}Add nodes to network{p_end}
{p2col:    {bf:{help nwattime }}}Static graph view of a temporal network at a given time{p_end}
{p2col:    {bf:{help nwcollapse }}}Collapse a network{p_end}
{p2col:    {bf:{help nwdichotomize }}}Dichotomize a network at a threshold{p_end}
{p2col:    {bf:{help nwdrop }}}Drop networks or nodes{p_end}
{p2col:    {bf:{help nwdropnodes }}}Drop nodes from a network{p_end}
{p2col:    {bf:{help nwkeep }}}Keep networks or nodes{p_end}
{p2col:    {bf:{help nwkeepnodes }}}Keep nodes of a network{p_end}
{p2col:    {bf:{help nwnoderename }}}Rename a single node in a network{p_end}
{p2col:    {bf:{help nwpreserve }}}Preserve and restore network data{p_end}
{p2col:    {bf:{help nwproject }}}One-mode projection of a two-mode network (alias for nw2project){p_end}
{p2col:    {bf:{help nwrecode }}}Recode a network{p_end}
{p2col:    {bf:{help nwrename }}}Rename a network{p_end}
{p2col:    {bf:{help nwreplace }}}Replace a network{p_end}
{p2col:    {bf:{help nwreplacemat }}}Replace network with Stata or Mata matrix{p_end}
{p2col:    {bf:{help nwrestore }}}Restore network data previously preserved{p_end}
{p2col:    {bf:{help nwstack }}}Stack several networks into one block-diagonal network{p_end}
{p2col:    {bf:{help nwsubset }}}Subset the nodes of a network{p_end}
{p2col:    {bf:{help nwsym }}}Symmetrize a network{p_end}
{p2col:    {bf:{help nwsymmetrize }}}Symmetrize a network (alias for nwsym){p_end}
{p2col:    {bf:{help nwtranspose }}}Transpose a network{p_end}

{marker analysis}{...}
{col 8}   {c TLC}{hline 24}{c TRC}
{col 8}{hline 3}{c RT}       {it:Analysis}{col 36}{c LT}{hline}
{col 8}   {c BLC}{hline 24}{c BRC}

{marker analysis_centrality}{...}
{p 11 11 2}{bf:{it:Centrality}}{p_end}
{p2colset 12 35 36 2}
{p2col:    {bf:{help nw2degree }}}Two-mode (bipartite) degree centrality{p_end}
{p2col:    {bf:{help nwbetween }}}Betweenness centrality{p_end}
{p2col:    {bf:{help nwcentrality }}}Node centrality measures{p_end}
{p2col:    {bf:{help nwcloseness }}}Closeness centrality{p_end}
{p2col:    {bf:{help nwdegree }}}Degree centrality and distribution{p_end}
{p2col:    {bf:{help nwevcent }}}Eigenvector centrality{p_end}
{p2col:    {bf:{help nwinduced }}}Induced, endogenous and exogenous centrality{p_end}
{p2col:    {bf:{help nwkatz }}}Katz-style distance-decay centrality{p_end}
{p2col:    {bf:{help nwpagerank }}}PageRank centrality{p_end}

{marker analysis_cohesion}{...}
{p 11 11 2}{bf:{it:Cohesion, components and subgroups}}{p_end}
{p2colset 12 35 36 2}
{p2col:    {bf:{help nwbridges }}}Find bridges (ties whose removal disconnects the network){p_end}
{p2col:    {bf:{help nwclique }}}Maximal clique enumeration{p_end}
{p2col:    {bf:{help nwcohesion }}}Moody-White structural cohesion hierarchy{p_end}
{p2col:    {bf:{help nwcomponents }}}Network components and the largest component{p_end}
{p2col:    {bf:{help nwkcomponents }}}Maximal k-component enumeration{p_end}
{p2col:    {bf:{help nwkcore }}}k-core decomposition{p_end}
{p2col:    {bf:{help nwkplex }}}Maximal k-plex enumeration{p_end}
{p2col:    {bf:{help nwnclan }}}Maximal n-clan enumeration{p_end}
{p2col:    {bf:{help nwnclique }}}Maximal n-clique enumeration{p_end}
{p2col:    {bf:{help nwsimmelian }}}Simmelian ties{p_end}

{marker analysis_community}{...}
{p 11 11 2}{bf:{it:Communities}}{p_end}
{p2colset 12 35 36 2}
{p2col:    {bf:{help nwcommunity }}}Detect communities via the Louvain method or label propagation{p_end}
{p2col:    {bf:{help nwmodularity }}}Score an existing node partition using Newman's modularity{p_end}
{p2col:    {bf:{help nwspectral }}}Graph Laplacian spectral analysis{p_end}

{marker analysis_positions}{...}
{p 11 11 2}{bf:{it:Positions, roles and similarity}}{p_end}
{p2colset 12 35 36 2}
{p2col:    {bf:{help nwbrokerage }}}Gould-Fernandez brokerage roles{p_end}
{p2col:    {bf:{help nwburt }}}Burt's structural-hole measures{p_end}
{p2col:    {bf:{help nwconcor }}}CONCOR structural-equivalence blockmodel{p_end}
{p2col:    {bf:{help nwconstraint }}}Burt's constraint{p_end}
{p2col:    {bf:{help nwcoreperiphery }}}Discrete core-periphery detection{p_end}
{p2col:    {bf:{help nwdissimilar }}}Generate node dissimilarities{p_end}
{p2col:    {bf:{help nwfactions }}}Partition nodes into a specified number of cohesive factions{p_end}
{p2col:    {bf:{help nwhierarchy }}}Hierarchical clustering of nodes (role/position analysis){p_end}
{p2col:    {bf:{help nwshared }}}Number of shared neighbors of all pairs of nodes, as a network{p_end}
{p2col:    {bf:{help nwsimilar }}}Generate node similarities{p_end}
{p2col:    {bf:{help nwsimindex }}}Common-neighbor similarity indices between all node pairs{p_end}

{marker analysis_clustering}{...}
{p 11 11 2}{bf:{it:Clustering, mixing and balance}}{p_end}
{p2colset 12 35 36 2}
{p2col:    {bf:{help nw2clustering }}}Clustering coefficient (transitivity) of a two-mode network{p_end}
{p2col:    {bf:{help nw2motifs }}}Bipartite motifs of a two-mode network{p_end}
{p2col:    {bf:{help nw2nested }}}Nestedness of a two-mode network: NODF and C-score{p_end}
{p2col:    {bf:{help nwassortativity }}}Newman's assortativity coefficient{p_end}
{p2col:    {bf:{help nwbalance }}}Structural balance of a signed network{p_end}
{p2col:    {bf:{help nwclustering }}}Clustering coefficient (transitivity) of a network{p_end}
{p2col:    {bf:{help nwmixing }}}E-I index and mixing table for a categorical node attribute{p_end}

{marker analysis_paths}{...}
{p 11 11 2}{bf:{it:Paths, flows and ego networks}}{p_end}
{p2colset 12 35 36 2}
{p2col:    {bf:{help nwaltergen }}}Generate a variable from alter/neighbor attributes{p_end}
{p2col:    {bf:{help nwego }}}Ego-network size and density{p_end}
{p2col:    {bf:{help nwgeodesic }}}Calculate shortest paths between nodes{p_end}
{p2col:    {bf:{help nwlambda }}}Edge (line) connectivity matrix between all node pairs{p_end}
{p2col:    {bf:{help nwmatching }}}Maximum-cardinality bipartite matching{p_end}
{p2col:    {bf:{help nwmaxflow }}}Maximum flow and minimum cut between two nodes{p_end}
{p2col:    {bf:{help nwneighbor }}}Extract the network neighbors of a node{p_end}
{p2col:    {bf:{help nwpath }}}Paths between nodes{p_end}
{p2col:    {bf:{help nwrandomwalk }}}Mean random-walk hitting time to a target node{p_end}
{p2col:    {bf:{help nwreach }}}Reachability network{p_end}

{marker analysis_statmodels}{...}
{p 11 11 2}{bf:{it:Statistical tests}}{p_end}
{p2colset 12 35 36 2}
{p2col:    {bf:{help nwcorrelate }}}Correlate networks and variables{p_end}
{p2col:    {bf:{help nwcug }}}Conditional Uniform Graph (CUG) test{p_end}
{p2col:    {bf:{help nwqap }}}Multivariate QAP regression{p_end}
{p2col:    {bf:{help nwutility }}}Utility scores of Jackson and Wolinsky (1996){p_end}

{marker analysis_other}{...}
{p 11 11 2}{bf:{it:Other analysis tools}}{p_end}
{p2colset 12 35 36 2}
{p2col:    {bf:{help nwcontext }}}Create a context variable{p_end}
{p2col:    {bf:{help nwnode }}}Check whether a node exists in a network{p_end}
{p2col:    {bf:{help nwturnover }}}Tie turnover/stability between two waves of the same network{p_end}
{p2col:    {bf:{help nwvalue }}}Return a tie value{p_end}

{marker utilities}{...}
{col 8}   {c TLC}{hline 24}{c TRC}
{col 8}{hline 3}{c RT}       {it:Utilities}{col 36}{c LT}{hline}
{col 8}   {c BLC}{hline 24}{c BRC}
{p2colset 12 35 36 2}
{p2col:    {bf:{help nwclear }}}Clear all networks and variables from memory{p_end}
{p2col:    {bf:{help nwcurrent }}}Report and set current network{p_end}
{p2col:    {bf:{help nwerrorcodes }}}Return codes of nwcommands{p_end}
{p2col:    {bf:{help nwinstall }}}Install the dialogs, menus and the model packages{p_end}
{p2col:    {bf:{help nwload }}}Load a network as Stata variables{p_end}
{p2col:    {bf:{help nwnetworktypes }}}How commands classify binary/directed/weighted/signed/two-mode networks{p_end}
{p2col:    {bf:{help nworder }}}Reorder the networks in memory{p_end}
{p2col:    {bf:{help nwversion }}}Version of nwcommands and of the installed model packages{p_end}

{marker visualization}{...}
{col 8}   {c TLC}{hline 27}{c TRC}
{col 8}{hline 3}{c RT}       {it:Visualization}{col 39}{c LT}{hline}
{col 8}   {c BLC}{hline 27}{c BRC}
{p2colset 12 35 36 2}
{p2col:    {bf:{help animate }}}Animate graphs{p_end}
{p2col:    {bf:{help nwdendrogram }}}Plot a wheel dendrogram{p_end}
{p2col:    {bf:{help nwmovie }}}Interactive, animated network movie (panel waves or a relational-event timeline){p_end}
{p2col:    {bf:{help nwmoviexy }}}Animate a sequence of networks (alias for nwmovie){p_end}
{p2col:    {bf:{help nwplot }}}Plot a network{p_end}
{p2col:    {bf:{help nwplotmatrix }}}Plot a network as sociomatrix{p_end}

{marker programming}{...}
{col 8}   {c TLC}{hline 25}{c TRC}
{col 8}{hline 3}{c RT}       {it:Programming}{col 37}{c LT}{hline}
{col 8}   {c BLC}{hline 25}{c BRC}
{p2colset 12 35 36 2}
{p2col:    {bf:{help nwcompressobs }}}Drop observations that no network needs{p_end}
{p2col:    {bf:{help nwsync }}}Synchronize a network with Stata variables{p_end}
{p2col:    {bf:{help nwtomata }}}Return the adjacency matrix of a network{p_end}
{p2col:    {bf:{help nwtomatafast }}}Return a link to the adjacency matrix of a network{p_end}
{p2col:    {bf:{help nwtostata }}}Copy a Mata matrix into Stata variables{p_end}
{p2col:    {bf:{help nwunab }}}Unabbreviate network list{p_end}
{p2col:    {bf:{help nwvalidate }}}Validate a network name{p_end}
{p2col:    {bf:{help nwvalidvars }}}Validate Stata variables for a network{p_end}

{marker models}{...}
{col 8}   {c TLC}{hline 52}{c TRC}
{col 8}{hline 3}{c RT}       {it:Statistical models (separate packages)}{col 64}{c LT}{hline}
{col 8}   {c BLC}{hline 52}{c BRC}

{pstd}
The statistical network models are separate packages that need the core. Install them with
{stata "nwinstall, models":nwinstall, models} (see {help nwinstall}; {help nwversion} shows which are installed).
Which package do you need? See {browse "https://nwcommands.org/which-package/"}.
{p_end}

{p2colset 12 35 36 2}
{p2col:    {bf:{browse "https://nwcommands.org/nwsaom/":nwsaom}}}Stochastic actor-oriented models (SAOM): network and behavior dynamics between observed waves{p_end}
{p2col:    {bf:{browse "https://nwcommands.org/nwergm/":nwergm}}}Exponential random graph models (ERGM) for cross-sectional networks{p_end}
{p2col:    {bf:{browse "https://nwcommands.org/nwdynam/":nwdynam}}}Dynamic network actor models (DyNAM): choice and rate models for event sequences{p_end}
{p2col:    {bf:{browse "https://nwcommands.org/nwrem/":nwrem}}}Relational event models (REM) for timed interaction events{p_end}
{p2colreset}{...}

{hline}
{pstd}{it:nwcommands version 3.18.0, 11 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
