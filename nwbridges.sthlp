{smcl}
{* *! version 2.0.1  5jun2019 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##generator:[NW-2.3] Generators}
{marker top2}
{helpb nw_topical##analysis:[NW-2.6] Analysis}

{title:Title}

{p2colset 9 17 23 2}{...}
{p2col :nwbridges {hline 2} Calculate bridges}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab: nwbridges} 
[{it:{help netname}}]
[{cmd:,}
{opth generate(newnetname)}
{opt type}({it:{help nwbridges##bridge_type:type}})
{opt nwreplace}

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth name(newnetname)}}Save bridges as network; default = {it:_bridges}.{p_end}
{synopt:{opt type}({it:{help nwbriges##bridge_type:type}})}Type of bridge; default = {it:global}{p_end}
{synopt:{opt nwreplace}}Overwrite network {it:newnetname}.{p_end}

{synoptset 20 tabbed}{...}
{marker bridge_type}{...}
{p2col:{it:type}}{p_end}
{p2line}
{p2col:{cmd: global}}Removing (i,j) makes the network fall apart.{p_end}
{p2col:{cmd: local}}Removing (i,j) increases the distance between i and j by at least 2.{p_end}
{p2col:{cmd: distance}}Removing (i,j) leads to the following distance between i and j.{p_end}

{title:Description}

{pstd}
A global bridge is a tie from node i to j if deleting the tie would 
make it impossible to reach node j from node i. A bridge is therefore essential to connect two nodes (or different parts of the network)
with each other.

{pstd} 
In contrast, a tie between nodes i and j is a local bridge if deleting the tie would increase the distance between i and j to a value strictly
more than two. 

{pstd}
The command saves all bridges as a new network {it:newnetname}.

{title:References}

{pstd}
Burt, R. S. 1992. Structural Holes: The social structure of competition. Cambridge: Harvard University Press.

{title:See also}

	{help nwburt}, {help nwpath}

last certified : 21 Aug 2026
