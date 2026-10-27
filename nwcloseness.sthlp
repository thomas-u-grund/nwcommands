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
{opt binary}
{opt twomode}
{opt onemode}
{opt legacy}]


{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth unconnected(int)}}defines the length of the (non-existent) path between two unconnected nodes{p_end}
{synopt:{opt legacy}}on an unconnected network, use (nodes - 1) / farness as in earlier releases instead of the number of reachable nodes / farness{p_end}
{synopt:{opt generate}({it:{help varname:var1 var2 var3}})}{bf:Required.} Exactly 3 variable names to save closeness, farness and nearness scores, in that order{p_end}
{synopt:{opt nosym}}do not symmetrize network before calculation of shortest paths{p_end}
{synopt:{opt replace}}overwrite existing {it:var1, var2, var3} (or {it:_closeness, _farness, _nearness}); required if they already exist{p_end}
{synopt:{opt silent}}Do not display the summary of the new variables{p_end}
{synopt:{opt force}}Run the command although its estimated time is more than 2 minutes (it stops with r(484) otherwise); also passed on to {help nwgeodesic}{p_end}
{synopt:{opt binary}}Ignore the tie values of a valued network (by default they are used){p_end}
{synopt:{opt twomode}}Two-mode network: the default; accepted as a synonym of the default (closeness is the smallest possible farness of a node of its mode divided by its farness, Borgatti and Everett 1997){p_end}
{synopt:{opt onemode}}Two-mode network: the closeness of the bipartite graph read as a one-mode graph, without the normalisation of Borgatti and Everett (the result of earlier releases){p_end}


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
Closeness as defined above ((nodes - 1) / farness) is only defined for a connected network. When the network is unconnected (or, for a directed network, not strongly connected) the command prints a warning and, as in R's igraph, takes the sum of the distances over the nodes that {it:i} can reach and divides the {it:number of those nodes} by it: {it:closeness_i = reach_i / farness_i}. This equals the formula above for a connected network and never exceeds 1. Farness and nearness are the plain sum of finite distances and its inverse. A node that reaches no other node gets a missing closeness. Option {bf:legacy} returns the (nodes - 1) / farness of releases before this correction, which can exceed 1 on an unconnected network. Scores based on all (nodes - 1) other nodes can also be obtained when
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
Two-mode: two-mode form by default - the smallest possible farness of a node of its mode divided by its farness (Borgatti and Everett 1997; {opt twomode} is accepted as a synonym); {opt onemode} forces the one-mode closeness of the bipartite graph.

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes - symmetrized by default (the same "no-prefix trap" {opt nosym} convention as {help nwkatz}/{help nwevcent}), {opt nosym} available. Weighted: inherited entirely from whatever {help nwgeodesic} options are passed through (this command has no {opt weighted}/{opt alpha()} of its own). Signed: not checked. Two-mode: two-mode form by default - the smallest possible farness of a node of its mode divided by its farness (Borgatti and Everett 1997; {opt twomode} is accepted as a synonym); {opt onemode} forces the one-mode closeness of the bipartite graph.

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

{title:Valued networks of any size}

{pstd}
On a valued network the distances are least-cost distances (cost 1/w^alpha, {opt alpha(#)}, default 1; {opt alpha(-1)} reads the values as lengths as {it:igraph::closeness} with weights does) and closeness is the number of nodes a node can reach divided by the sum of these distances ({it:igraph::closeness} with {it:normalized = TRUE}). A kernel of the native plugin computes them for every node without the n x n distance matrix: 1,000 nodes with 3,000 ties take 0.15 seconds, 10,000 nodes 14 seconds (the Mata routine needs 3 seconds at 300 nodes and grows with the cube of the size). A valued network is never reduced to step counts silently: without the native plugin a network of more than 100 nodes stops with r(198) unless {opt force} or {opt binary} is given.

{title:See also}

	{help nwgeodesic}, {help nwpath}, {help nwgeodesic}, {help nwbetween}, {help nwdegree}, {help nwevcent}, {help nwkatz}

last certified : 24 Aug 2026

{hline}
{pstd}{it:nwcommands version 3.11.0, 27 October 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
