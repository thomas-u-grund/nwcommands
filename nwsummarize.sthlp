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
{cmd:save(}{it:filename}[{cmd:, replace}]{cmd:)}
{opt silent}
]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt mat}}Display adjacency matrix of the network{p_end}
{synopt:{opt matonly}}Only display adjacency matrix of the network{p_end}
{synopt:{opt detail}}Calculate additional network measures: reciprocity, transitivity and the centralization measures (their {cmd:r()} results are only filled with {opt detail}); reciprocity is
displayed as n/a for an undirected network (the stored {cmd:r(reciprocity)} is unchanged){p_end}
{synopt:{cmd:save(}{it:filename}[{cmd:, replace}]{cmd:)}}Save the network measures in a Stata data set, one observation per network; an existing file is replaced (with or without {cmd:replace}){p_end}
{synopt:{opt silent}}Compute and return results without displaying anything{p_end}
{synoptline}
{p2colreset}{...}


{title:Description}

{pstd}
{cmd:nwsummarize} calculates and displays a variety of network summary statistics. 
 If no netlist is specified, summary statistics are calculated for 
 the current network.


{title:Network types}

{pstd}
{bf:Directed:}, {bf:Valued:} the summaries reflect direction and tie values. {bf:Two-mode:} yes - shows the two levels
with sizes and labels; the density is the ties over the pairs from different modes. {bf:Signed:} negative values are
not treated specially. See {help nwnetworktypes}.{p_end}


{title:Limits}

{pstd}
Counts, minimum, maximum and density of a network held as stored ties are read from the ties: 20,000 nodes 0.02 seconds and 0.2 GB
in Stata/BE.


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
	{txt}   Density: {res} .167
	{txt}   Mean degree: {res} 2.50


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
	{txt}   Mean outdegree: {res} 1.00

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
	
{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{bf:r(id)}}internal ID of the network{p_end}
{synopt:{bf:r(nodes)}}number of nodes in the network{p_end}
{synopt:{bf:r(minval)}}minimum of tie values{p_end}
{synopt:{bf:r(maxval)}}maximum of tie values{p_end}
{synopt:{bf:r(edges)}}number of edges (undirected network){p_end}
{synopt:{bf:r(arcs)}}number of arcs (directed network){p_end}
{synopt:{bf:r(edges_sum)}}sum of edge values (undirected network){p_end}
{synopt:{bf:r(arcs_value)}}sum of arc values (directed network){p_end}
{synopt:{bf:r(density)}}network density (two-mode network: ties over the pairs between the two modes){p_end}
{synopt:{bf:r(meandegree)}}mean degree: twice the edges per node (undirected network) or arcs per node, the mean outdegree, which equals the mean indegree (directed network); not for two-mode
networks{p_end}
{synopt:{bf:r(reciprocity)}}network reciprocity{p_end}
{synopt:{bf:r(transitivity)}}network transitivity{p_end}
{synopt:{bf:r(dg_central)}}degree centralization (undirected network, with {opt detail}){p_end}
{synopt:{bf:r(indg_central)}}indegree centralization (directed network, with {opt detail}){p_end}
{synopt:{bf:r(outdg_central)}}outdegree centralization (directed network, with {opt detail}){p_end}
{synopt:{bf:r(missing_edges)}}number of cells of the adjacency matrix without a value (missing); the diagonal of a network without self-loops and the pairs within a mode of a two-mode network count as missing{p_end}
{synopt:{bf:r(selfloops)}}number of self-loops{p_end}
{synopt:{bf:r(nodes1)}}number of mode-1 nodes (two-mode networks only){p_end}
{synopt:{bf:r(nodes2)}}number of mode-2 nodes (two-mode networks only){p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{bf:r(directed)}}if network is directed or not (undirected){p_end}
{synopt:{bf:r(valued)}}if network is declared as valued or not{p_end}
{synopt:{bf:r(mode2)}}if network two-mode or not{p_end}
{synopt:{bf:r(name)}}name of the network (alias: {bf:r(netname)}){p_end}
{synopt:{bf:r(labs)}}comma-separated node labels{p_end}
{synopt:{bf:r(vars)}}Stata variable names used to represent the network{p_end}
{synopt:{bf:r(selfloop)}}if the network permits self-loops{p_end}
{synopt:{bf:r(provenance)}}provenance/source note, if set (see {help nwname}){p_end}
{synopt:{bf:r(temporal)}}if the network is temporal{p_end}
{synopt:{bf:r(temporaltype)}}temporal storage type, if {bf:r(temporal)} is true{p_end}
{synopt:{bf:r(mode1_desc)}}description of mode 1 (two-mode networks only){p_end}
{synopt:{bf:r(mode2_desc)}}description of mode 2 (two-mode networks only){p_end}

{pstd}
With a {it:netlist}, the results are those of the last network. The other results of {help nwname}
(for example {bf:r(title)}, {bf:r(modes)}, {bf:r(mode1desc)}) are also left in {bf:r()}; see its {bf:Stored results}.


{title:See also}

	{help nwname}, {help nwdyads}, {help nwtriads}

{hline}
{pstd}{it:nwcommands version 3.23.0, 13 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
