{smcl}
{* *! version 1.0.0  20aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis:[NW-2.6] Analysis}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwcommunity {hline 2} Detect communities via the Louvain method{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwcommunity}
[{it:{help netlist}}]
[{cmd:,}
{opth generate(newvarname)}
{opt replace}
{opt measure(string)}
{opt SYMmetrize}
{opth resolution(real)}
{opt silent}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth generate(newvarname)}}Name of the Stata variable that stores community membership; default = {it:_community}{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opt measure(binary|valued)}}Whether to use tie values ({it:valued}) or only presence/absence of ties ({it:binary}); default = {it:valued} for valued networks, {it:binary} otherwise{p_end}
{synopt:{opt symmetrize}}Symmetrize a directed network before detecting communities (required for directed networks){p_end}
{synopt:{opth resolution(real)}}Resolution parameter (Reichardt-Bornholdt); default = 1{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwcommunity} detects communities in the network(s) in {help netlist} using the Louvain method (Blondel et al 2008),
a greedy algorithm that repeatedly moves nodes between communities and aggregates communities into a coarser
network, in order to maximize Newman's modularity {it:Q}. All calculations are performed on the undirected
network; directed networks require {bf:symmetrize}.

{pstd}
By default, {cmd:nwcommunity} generates a new variable {it:_community} which stores, for each node, the
id of the community it was assigned to.

{title:Stored results}

	Scalars
	  {bf:r(communities)}		number of communities
	  {bf:r(modularity)}		modularity Q of the detected partition

	Matrices
	  {bf:r(comm_sizeid)}		distribution over communities


{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwcommunity flomarriage}


{title:References}

{pstd}
Blondel, V.D., Guillaume, J.-L., Lambiotte, R., Lefebvre, E. (2008). Fast unfolding of communities in
large networks. {it:Journal of Statistical Mechanics: Theory and Experiment}, 2008(10), P10008.

{pstd}
Newman, M.E.J. (2006). Modularity and community structure in networks. {it:PNAS} 103(23), 8577-8582.


{title:See also}

	{help nwmodularity}, {help nwcomponents}, {help nwclustering}

last certified : 20 Aug 2026
