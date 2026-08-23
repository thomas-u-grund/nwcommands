/***
{smcl}
{* *! version 2.0.0  17may2019 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##information:[NW-2.4] Information}

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
]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt mat}}Display adjacency matrix of the network{p_end}
{synopt:{opt matonly}}Only display adjacency matrix of the network{p_end}
{synopt:{opt detail}}Calculate additional network measures, e.g. centralization, transitivity{p_end}
{synopt:{opth save(filename)}}Save network measures in file{p_end}
{synoptline}
{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwsummarize} calculates and displays a variety of network summary statistics. 
 If no netlist is specified, summary statistics are calculated for 
 the current network.

 
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
	  {bf:r(arcs_sum)}	sum of arc values (directed network)
	  {bf:r(density)}	network density
	  {bf:r(reciprocity)}	network reciprocity
	  {bf:r(transitivity)}	network transitivity
	  
	Macros
	  {bf:r(directed)}	if network is directed or not (undirected)
	  {bf:r(valued)}	if network is declared as valued or not
	  {bf:r(mode2)}		if network two-mode or not
	  {bf:r(name)}		name of the network
	  

{title:See also}

	{help nwname}, {help nwdyads}, {help nwtriads}
***/

capture program drop nwsummarize
program nwsummarize
	version 9
	syntax [anything(name=netname)][, mat matonly detail save(string asis) silent ]
	set more off
	nw_syntax `netname', max(100000)

	
	if "`detail'" != "" {
		local add "indg_central outdg_central dg_central transitivity reciprocity"
	}
	tempname memhold
	if "`save'" != "" {
		postfile `memhold' str20 name str10 directed id nodes minval maxval edges arcs density `add' using `"`save'"', replace
	}
	foreach onenet in `netname' {
		nwinf `onenet', `mat' `matonly' `detail' `silent'
		if "`save'" != "" {
			if "`r(directed)'" == "false" {
				if "`detail'" == "" {
					post `memhold' ("`r(name)'") ("`r(directed)'") (`r(id)') (`r(nodes)') (`r(minval)') (`r(maxval)') (`r(edges)') (.) (`r(density)')
				}
				else {
					post `memhold' ("`r(name)'") ("`r(directed)'") (`r(id)') (`r(nodes)') (`r(minval)') (`r(maxval)') (`r(edges)') (.) (`r(density)') (.) (.) (`r(dg_central)') (`r(transitivity)') (`r(reciprocity)')
				}
			}
			else {
				if "`detail'" == "" {
					post `memhold' ("`r(name)'") ("`r(directed)'") (`r(id)') (`r(nodes)') (`r(minval)') (`r(maxval)') (.) (`r(arcs)') (`r(density)')
				}
				else {
					post `memhold' ("`r(name)'") ("`r(directed)'") (`r(id)') (`r(nodes)') (`r(minval)') (`r(maxval)') (.) (`r(arcs)') (`r(density)') (`r(indg_central)') (`r(outdg_central)') (.) (`r(transitivity)') (`r(reciprocity)')
				}
			}
		}
	}
	
	if "`save'" != "" {
		postclose `memhold'
	}
end
	

capture program drop nwinf
program nwinf
	version 9
	syntax [anything(name=netname)], [id(string) mat matonly detail silent]
	nw_syntax `netname', max(1)
	local localdirected `directed'
	
	if "`detail'" != "" {
		qui nwdyads `thisname'
		local reciprocity = `r(reciprocity)'
		qui nwtriads `thisname'
		local transitivity = `r(transitivity)'
		qui nwdegree `thisname', silent
		if ("`localdirected'"=="false"){
			local central = `r(dg_central)'
		}
		else {
			local incentral = `r(indg_central)'
			local outcentral = `r(outdg_central)'
		}
	}
	
	mata: st_rclear()
	
	nw_name `netname'
	
	mata: st_global("r(name)", "`netname'")
	mata: st_global("r(netname)", "`netname'")
	mata: st_numscalar("r(minval)", `netobj'->get_minimum())
	mata: st_numscalar("r(maxval)", `netobj'->get_maximum())
	mata: st_global("r(mode2)", `netobj'->is_2mode())
	mata: st_global("r(valued)", `netobj'->is_valued())
	
	if (r(directed)=="false"){
		mata: st_numscalar("r(edges)", `netobj'->get_edges_count())
		mata: st_numscalar("r(edges_sum)", `netobj'->get_edges_sum())
		mata: st_numscalar("r(dg_central)", `central')
	}
	else {
		mata: st_numscalar("r(arcs)", `netobj'->get_arcs_count())
		mata: st_numscalar("r(arcs_value)", `netobj'->get_arcs_sum())
		mata: st_numscalar("r(indg_central)", `incentral')
		mata: st_numscalar("r(outdg_central)", `outcentral')
	}
	mata: st_numscalar("r(density)", `netobj'->get_density())
	mata: st_numscalar("r(transitivity)", `transitivity')
	mata: st_numscalar("r(reciprocity)", `reciprocity')
	mata: st_numscalar("r(nodes)", `netobj'->get_nodes())	
		
	if "`r(mode2)'" == "true" {
		mata: st_numscalar("r(nodes1)", `netobj'->get_nodes_mode1())
		mata: st_numscalar("r(nodes2)", `netobj'->get_nodes_mode2())
		mata: st_global("r(mode1_desc)", `netobj'->get_description_mode1())
		mata: st_global("r(mode2_desc)", `netobj'->get_description_mode2())
	}
	mata: st_global("r(provenance)", `netobj'->get_provenance())
	mata: st_global("r(temporal)", `netobj'->is_temporal())
	if "`r(temporal)'" == "true" {
		mata: st_global("r(temporaltype)", `netobj'->get_temporal_type())
	}

	if "`matonly'" == "" & "`silent'" == "" {
		di "{hline 50}"
		di "{txt}   Network name: {res} `r(name)'"
		di "{txt}   Network id: {res} `r(id)'"
		di "{txt}   Directed: {res}`r(directed)'"
		di "{txt}   Valued: {res}`r(valued)'"
		di "{txt}   Two-mode: {res}`r(mode2)'"
		di "{txt}   Nodes: {res}`r(nodes)'"
		if "`r(mode2)'" == "true" {
			di "{txt}      Level 1: {res}`r(nodes1)' {txt}(`r(mode1_desc)')" 
			di "{txt}      Level 2: {res}`r(nodes2)' {txt}(`r(mode2_desc)')"
		}
		di "{txt}   Selfloop: {res}`r(selfloop)'"
		if ("`r(selfloop)'" == "true") {
			di "{txt}    Number of selfloops: {res}`r(selfloops)'"
		}
		if (r(directed) == "false"){
			di "{txt}   Edges: {res}`r(edges)'"
		}
		if (r(directed) == "true"){
			di "{txt}   Arcs: {res}`r(arcs)'"
		}
		di "{txt}   Minimum value: {res} `r(minval)'"
		di "{txt}   Maximum value: {res} `r(maxval)'"	
		di "{txt}   Density: {res} `r(density)'"
		di "{txt}   Temporal: {res}`r(temporal)'"
		if "`r(temporal)'" == "true" {
			di "{txt}      Temporal type: {res}`r(temporaltype)'"
		}
		if `"`r(provenance)'"' != "" {
			di "{txt}   Provenance: {res} `r(provenance)'"
		}

		if "`detail'" != "" {
			di "{txt}   Reciprocity: {res} `r(reciprocity)'"
			di "{txt}   Transitivity: {res} `r(transitivity)'"
			if (r(directed) == "false"){
				di "{txt}   Degree centralization: {res}`r(dg_central)'"
			}
			if (r(directed) == "true"){
				di "{txt}   Indegree centralization:: {res}`r(indg_central)'"
				di "{txt}   Outdegree centralization:: {res}`r(outdg_central)'"
			}
		}
	}
	
	if "`mat'`matonly'" !=""{
		mata: *`netobj'->get_matrix()
	}
end
