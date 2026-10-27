{smcl}
{* *! version 2.0.1  5jun2019 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##generator:[NW-2.3] Generators}
{marker top2}
{helpb nwtopical##analysis_cohesion:[NW-2.6.2] Cohesion, Components & Subgroups}

{title:Title}

{p2colset 9 17 23 2}{...}
{p2col :nwbridges {hline 2}}Calculate bridges{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab: nwbridges}
[{it:{help netname}}]
[{cmd:,}
{opth name(newnetname)}
{opt type}({it:{help nwbridges##bridge_type:type}})
{opt nwreplace}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth name(newnetname)}}Save bridges as network; default = {it:_bridges}.{p_end}
{synopt:{opt type}({it:{help nwbridges##bridge_type:type}})}Type of bridge; default = {it:global}{p_end}
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


{title:Valued networks}

{pstd}
This measure uses the presence of ties only (R has no weighted form of it either). On a valued network ({help nwnetworktypes}) the command prints the line "(note: tie values are ignored; this measure is binary)" once (not with {opt silent} or {cmd:quietly}) and treats every tie as present. To choose which ties count, make a binary copy with {help nwdichotomize} first.

{title:Supported network types}

{pstd}
Binary: yes (only) - bridge status is a structural property, tie values are ignored. Directed: yes - {opt type()} distinguishes local/global bridges and arcs vs. edges. Weighted: not applicable. Signed: not applicable. Two-mode: same as for the bipartite graph read as a one-mode network (valid; no mode-specific normalisation).

{title:Stored results}

	Macros
	  {bf:r(name)}		name of the source network
	  {bf:r(directed)}	whether the source network is directed ({bf:true}/{bf:false})
	  {bf:r(bridges)}	number of bridges found
	  {bf:r(bridges_type)}	the {opt type()} used ({bf:global}/{bf:local}/{bf:distance})

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwbridges flobusiness}
	{cmd:. nwbridges flobusiness, type(local) nwreplace}

{title:References}

{pstd}
Burt, R. S. (1992). {it:Structural Holes: The Social Structure of Competition}. Cambridge: Harvard
University Press.

{title:Limits}

{pstd}
{cmd:type(global)} of an undirected network writes the bridges as ties (one depth-first search, no matrix): 20,000 nodes 0.4 seconds
and 0.3 GB in Stata/BE (9.5 seconds and 9.4 GB before). {cmd:type(local)} and {cmd:type(distance)} still work on the matrix.

{title:See also}

	{help nwburt}, {help nwpath}

last certified : 24 Aug 2026

{hline}
{pstd}{it:nwcommands version 3.11.1, 27 October 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
