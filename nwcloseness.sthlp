{smcl}
{* *! version 1.0.0  3sept2014}{...}
{marker topic}
{helpb nwtopical##analysis_centrality:[NW-2.6.1] Centrality}

{title:Title}

{p2colset 9 20 22 2}{...}
{p2col :nwcloseness {hline 2}}Calculate closeness centrality{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwcloseness} 
[{it:{help netlist}}]
[{cmd:,}
{opth unconnected(int)}
{opt generate}({it:{help varname:var1 var2 var3}})
{opt nosym}
{opt replace}
{opt silent}
{opt force}
{opt binary}]


{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth unconnected(int)}}defines the length of the (non-existent) path between two unconnected nodes{p_end}
{synopt:{opt generate}({it:{help varname:var1 var2 var3}})}{bf:Required.} Exactly 3 variable names to save closeness, farness and nearness scores, in that order{p_end}
{synopt:{opt nosym}}do not symmetrize network before calculation of shortest paths{p_end}
{synopt:{opt replace}}overwrite existing {it:var1, var2, var3} (or {it:_closeness, _farness, _nearness}); required if they already exist{p_end}
{synopt:{opt silent}}Do not display the summary of the new variables{p_end}
{synopt:{opt force}}Run the command although its estimated time is more than 2 minutes (it stops with r(484) otherwise){p_end}
{synopt:{opt binary}}Ignore the tie values of a valued network (by default they are used){p_end}
{synopt:{opt twomode}}Two-mode network: closeness is the smallest possible farness of a node of its mode divided by its farness (Borgatti and Everett 1997){p_end}


{title:Description}

{pstd}
Calculates the closeness centrality (and farness and nearness score) for each node {it:i} in a network or network list and 
saves the result as Stata variables. 

{pstd}
The closeness centrality for node {it:i} is defined in the following way:
	
	{it:farness_i = sum(dist_ik), over all k}
	
	{it:nearness_i = 1 / farness_i}
	
	{it:closeness_i = nearness_i * (nodes - 1)}

{pmore}	
with: {it:dist_ik} being the length of the shortest path from node {it:i} to node {it:k} (see {help nwgeodesic})

{pstd}
Closeness centrality is not defined when the network is unconnected. However, scores can still be obtained when
option {bf:unconnected()} is specified. Any integer value can be choosen; {bf:unconnected(max)} assigns non-existent
paths a length based on the longest shortest path length observed in the network (plus one) (see {help nwgeodesic}).	

{pstd}
{opt generate()} is required and must always give exactly 3 names ({it:var1 var2 var3}, for closeness,
farness and nearness respectively). Existing Stata variables {it:var1, var2, var3} require option
{bf:replace} to be overwritten. In case, closeness centrality is calculated
for {it:z} networks at the same time (e.g. {bf: nwcloseness glasgow1 glasgow2, generate(clo far near)}), the command generates the variables
{it:var1_z, var2_z, var3_z} for each network.



{title:Valued networks}

{pstd}
A network is valued when it was created with tie values ({help nwfromedge} with a value variable, an import or a matrix with values, {cmd:nwset, valued}); the flag is shown by {help nwsummarize} and explained in {help nwnetworktypes}. On a valued network the distances are those of {help nwgeodesic} with cost 1/w ({it:igraph::closeness} with weights 1/w; {it:tnet::closeness_w} is the same value multiplied by the mean tie value, the ranking is the same). {opt binary} counts steps. Options of {help nwgeodesic} such as {opt alpha()} can be passed on.
On a network that is not valued the result is the same as in earlier releases and {opt binary} has no effect.

{title:Two-mode networks}

{pstd}
Two-mode: same as for the bipartite graph read as a one-mode network (valid; no mode-specific normalisation); the option {opt twomode} divides the smallest possible farness of a node of its mode by its farness (Borgatti and Everett 1997).

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes - symmetrized by default (the same "no-prefix trap" {opt nosym} convention as {help nwkatz}/{help nwevcent}), {opt nosym} available. Weighted: inherited entirely from whatever {help nwgeodesic} options are passed through (this command has no {opt weighted}/{opt alpha()} of its own). Signed: not checked. Two-mode: same as for the bipartite graph read as a one-mode network (valid; no mode-specific normalisation); the option {opt twomode} divides the smallest possible farness of a node of its mode by its farness (Borgatti and Everett 1997).

{title:Examples}
	
	{cmd:. nwwebuse gang, nwclear}
	{cmd:. nwcloseness gang, generate(_closeness _farness _nearness)}
	{cmd:. sum _closeness _farness _nearness}


{title:Limits}

{pstd}
Without {it:geodesic_options} the sums of the distances come from one breadth-first search per node over the stored ties in
the plugin (no matrix of distances); a platform whose plugin has not been rebuilt, or any {it:geodesic_options}
({opt alpha()}, {opt unconnected()}, ...), takes the route over the matrix of {help nwgeodesic}. Measured in Stata/BE on a
random directed network with 10 ties per node: 10,000 nodes 2.4 seconds, 20,000 nodes 9.9 seconds and 0.35 GB (98 seconds and
6.4 GB through the matrix); the time grows with the number of nodes times the number of ties.

{pstd}
The estimate for a network of 100,000 nodes with 10 ties per node is 5 minutes (measured: 302 seconds, 0.6 GB). When the estimated time is more than 2 minutes (about 63,000 nodes with 10 ties per node) the command stops at once with r(484) and a message; option {opt force} runs it anyway.

{title:See also}

	{help nwgeodesic}, {help nwpath}, {help nwgeodesic}, {help nwbetween}, {help nwdegree}, {help nwevcent}, {help nwkatz}

last certified : 24 Aug 2026

{hline}
{pstd}{it:nwcommands version 3.5.1, 25 October 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
