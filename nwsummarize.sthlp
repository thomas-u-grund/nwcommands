{smcl}
{* *! version 2.0.0  17may2019 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##information:[NW-2.4] Information}

{title:Title}

{p2colset 9 20 22 2}{...}
{p2col :nwsummarize {hline 2}}Summarize a network{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwsummarize} 
[{it:{help netlist}}]
[,
{opt mat}
{opt matonly}
{opt detail}
{opth save(filename)}
{opt silent}
]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt mat}}Display adjacency matrix of the network{p_end}
{synopt:{opt matonly}}Only display adjacency matrix of the network{p_end}
{synopt:{opt detail}}Calculate additional network measures, e.g. centralization, transitivity{p_end}
{synopt:{opth save(filename)}}Save network measures in file{p_end}
{synopt:{opt silent}}Compute and return results without displaying anything{p_end}
{synoptline}
{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwsummarize} calculates and displays a variety of network summary statistics. 
 If no netlist is specified, summary statistics are calculated for 
 the current network.

 

{title:Supported network types}

{pstd}
Binary: yes. Directed: yes. Weighted: yes, dyad/triad/degree summaries reflect tie values where applicable. Signed: not checked. Two-mode: not checked.

{title:Examples}

	{cmd:. nwwebuse florentine}
	{cmd}. nwsummarize flomarriage
	{res}{hline 50}
	{txt}   Network name: {res} flomarriage
	{txt}   Network id: {res} 2
	{txt}   Nodes: {res}16
	{txt}   Directed: {res}false
	{txt}   Valued: {res} false
	{txt}   Two-mode: {res}false
	{txt}   Selfloop: {res}false
	{txt}   Edges: {res}20
	{txt}   Minimum value: {res} 0
	{txt}   Maximum value: {res} 1
	{txt}   Density: {res} .1666666666666667


	{com}. nwclear
	. nwrandom 5, prob(.2) name(mynet)
	. nwsummarize mynet, mat
	{res}{hline 50}
	{txt}   Network name: {res} mynet
	{txt}   Network id: {res} 1
	{txt}   Nodes: {res}5
	{txt}   Directed: {res}true
	{txt}   Valued: {res} false
	{txt}   Two-mode: {res}false
	{txt}   Selfloop: {res}false
	{txt}   Arcs: {res}5
	{txt}   Minimum value: {res} 0
	{txt}   Maximum value: {res} 1
	{txt}   Density: {res} .25

             {txt}1   2   3   4   5
          {c TLC}{hline 21}{c TRC}
	1 {c |}  {res}0   0   0   0   1{txt}  {c |}
	2 {c |}  {res}0   0   0   0   0{txt}  {c |}
	3 {c |}  {res}0   0   0   0   1{txt}  {c |}
	4 {c |}  {res}0   0   0   0   0{txt}  {c |}
	5 {c |}  {res}1   1   0   1   0{txt}  {c |}
          {c BLC}{hline 21}{c BRC}

	
{title:Stored results}

	{bf:nwsummarize} stores the following in {bf:r()}:
	
	Scalars
	  {bf:r(id)}		internal ID of the network
	  {bf:r(nodes)}		number of nodes in the network
	  {bf:r(minval)}	minimum of tie values
	  {bf:r(maxval)}	maximum of tie values
	  {bf:r(edges)}		number of edges (undirected network)
	  {bf:r(arcs)}		number of arcs (directed network)
	  {bf:r(edges_sum)}	sum of edge values (undirected network)
	  {bf:r(arcs_value)}	sum of arc values (directed network)
	  {bf:r(density)}	network density
	  {bf:r(reciprocity)}	network reciprocity
	  {bf:r(transitivity)}	network transitivity
	  {bf:r(missing_edges)}	number of missing (undefined) dyads
	  {bf:r(selfloops)}	number of self-loops
	  {bf:r(nodes1)}	number of mode-1 nodes (two-mode networks only)
	  {bf:r(nodes2)}	number of mode-2 nodes (two-mode networks only)

	Macros
	  {bf:r(directed)}	if network is directed or not (undirected)
	  {bf:r(valued)}	if network is declared as valued or not
	  {bf:r(mode2)}		if network two-mode or not
	  {bf:r(name)}		name of the network (alias: {bf:r(netname)})
	  {bf:r(labs)}		comma-separated node labels
	  {bf:r(vars)}		Stata variable names used to represent the network
	  {bf:r(selfloop)}	if the network permits self-loops
	  {bf:r(provenance)}	provenance/source note, if set (see {help nwname})
	  {bf:r(temporal)}	if the network is temporal
	  {bf:r(temporaltype)}	temporal storage type, if {bf:r(temporal)} is true
	  {bf:r(mode1_desc)}	description of mode 1 (two-mode networks only)
	  {bf:r(mode2_desc)}	description of mode 2 (two-mode networks only)

	{pstd}
	The full set above is inherited unchanged from the internal {help nwname} call this command
	makes on your behalf - see {help nwname}'s own {bf:Stored results} section for the authoritative,
	complete list (this command does not add or remove any of it).

{title:See also}

	{help nwname}, {help nwdyads}, {help nwtriads}
last certified : 24 Aug 2026
