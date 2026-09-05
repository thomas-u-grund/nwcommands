{smcl}
{* *! version 1.0.1  17may2012 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_paths:[NW-2.6.5] Paths, Reachability & Ego Networks}

{title:Title}

{p2colset 9 20 22 2}{...}
{p2col :nwneighbor {hline 2}}Extract the network neighbors of a node{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwneighbor} 
[{it:{help netname}}],
{opt ego(nodename)}
[{opt mode}({it:{help nwneighbor##context:context}})
{opth generate(newvarname)}
{opt replace}
{opth subnet(newnetname)}
{opt subreplace}]


{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt mode}({it:{help nwneighbor##context:context}})}Defines the network neighborhood of node {it:ego}; default = {it:outgoing}{p_end}
{synopt:{opth generate(newvarname)}}Save information about network neighbors in variable.{p_end}
{synopt:{opt replace}}Overwrite variable {it:newvarname}.{p_end}
{synopt:{opth subnet(newnetname)}}Save the induced subgraph on {it:ego} plus its own neighbors (and every tie among them) as a new network{p_end}
{synopt:{opt subreplace}}Overwrite network {it:newnetname} if it already exists{p_end}
		
{synoptset 15 tabbed}{...}
{marker context}{...}
{p2col:{it:context}}{p_end}
{p2line}
{p2col:{cmd: outgoing}}network neighbors of node {it:ego} are all nodes {it:j} who receive a tie from {it:ego}; default
		{p_end}
{p2col:{cmd: incoming}}network neighbors of node {it:ego} are all nodes {it:j} who send a tie to {it:ego}
		{p_end}
{p2col:{cmd: either}}network neighbors of node {it:ego} are all nodes {it:j} who either send a tie to {it:ego} or receive a tie from {it:ego}
		{p_end}

		
{title:Description}

{pstd}
{cmd: nwneighbor} returns the network neighbors of {it:nodename} specified in {bf:ego()}. The network neighborhood of a node is defined in {opt mode()}. By default,
the neighborhood of a node {it:ego} consists of all nodes {it:j}, who receive a tie from node {it:ego}. Tie values are ignored.

{pstd}
{opth subnet(newnetname)} additionally saves the INDUCED SUBGRAPH on {it:ego} plus its own neighbors - a genuine new network containing exactly those nodes and every tie the original network has among them (not just ego's own ties) - as {it:newnetname}. Useful as a starting point for any ego-network-level analysis that needs an actual standalone network object (as opposed to a per-node attribute aggregate, which {help nwaltergen}/{help nwego} already compute directly without needing one). The original network is left untouched; {it:newnetname} inherits its directedness/valued/self-loop/two-mode status.



{title:Supported network types}

{pstd}
Binary: yes. Directed: yes, via {opt mode(incoming|outgoing|either)}. Weighted: not applicable - returns which nodes are neighbors, not tie values. Signed: not applicable. Two-mode: not checked.

{title:Stored results}

	Macros
	  {bf:r(ego)}		name of ego (a string, not a nodeid)
	  {bf:r(oneneighbor)}	one randomly selected neighbor's name; empty if ego has no neighbors

	Scalars
	  {bf:r(egoid)}		nodeid of ego
	  {bf:r(num_neighbors)}	number of neighbors ego has

	Matrices
	  {bf:r(neighbors)} 	reshuffled list of all neighbors


{title:Examples}

	{com}. nwwebuse florentine, nwclear
	{com}. nwneighbor flobusiness, ego(ginori)

	{hline 40}
	{txt}  Network: {res}flobusiness
	{hline 40}
	{txt}    Ego        : {res}ginori	
	{txt}    Neighbors  : {res}{res}barbadori{txt} , {res}medici{txt}
	{hline 40}

{pstd}
This shows that the "ginori" family has business relationships with the "barbadori" and the "medici". 
	   

{title:Also see}

   {help nwcontext}, {help nwgeodesic}, {help nwpath}

last certified : 24 Aug 2026
