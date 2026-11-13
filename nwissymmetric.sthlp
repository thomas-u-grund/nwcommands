{smcl}
{* *! version 1.0.4  23aug2014 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##information:[NW-2.4] Information}

{title:Title}

{p2colset 9 20 22 2}{...}
{p2col :nwissymmetric {hline 2}}Check whether a network is symmetric{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwissymmetric} 
[{it:{help netname}}]


{title:Description}

{pstd}
{cmd:nwissymmetric} simply checks if the underlying adjacency matrix of network {help netname} is symmetric, regardless
of whether the network is assigned to be directed or undirected (see {help nwname}). An adjacency matrix
{it:M} is symmetric when {it:M_ij == M_ji}. Returns
{it:r(issymmetric)} in the return vector. 

{pstd}
This command can be useful for programming, when one wants to detect if a network should be undirected.

{pstd}
For example, {help nwimport} automatically checks if a network (e.g. Ucinet fullmatrix) is symmetric and if yes, 
imports the network as undirected.
 
 

{title:Network types}

{pstd}
{bf:Directed:} the command checks whether the matrix of a directed network is symmetric. {bf:Valued:} the tie values are
compared, not only the presence of ties. {bf:Two-mode:} same as for the bipartite graph read as a one-mode network.
{bf:Signed:} negative values are compared like any value. See {help nwnetworktypes}.{p_end}

{title:Examples}

	{cmd:. nwwebuse florentine}
	{cmd:. nwissymmetric flomarriage}
	{cmd:. return list}

	{txt}scalars:
{synoptset 20 tabbed}{...}
{synopt:r(issymmetric) = {res}1{txt}}{p_end}

{pstd}
Note: {bf:r(issymmetric)} is a plain numeric 0/1 scalar - unlike the {bf:true}/{bf:false} string
macros most other boolean-flag results in this group use (e.g. {help nwname}'s {bf:r(directed)}),
since it is a computed test result rather than a stored network property.


{title:See also}

	{help nwsym}, {help nwname}

{hline}
{pstd}{it:nwcommands version 3.23.0, 13 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
