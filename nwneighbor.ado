/***
{smcl}
{* *! version 1.0.1  17may2012 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_paths:[NW-2.6.5] Paths, Reachability & Ego Networks}

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
{opt replace}]


{synoptset 30 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt mode}({it:{help nwneighbor##context:context}})}Defines the network neighborhood of node {it:ego}; default = {it:outgoing}{p_end}
{synopt:{opth generate(newvarname)}}Save information about network neighbors in variable.{p_end}
{synopt:{opt replace}}Overwrite variable {it:newvarname}.{p_end}
		
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



{title:Supported network types}

{pstd}
Binary: yes. Directed: yes, via {opt mode(incoming|outgoing|either)}. Weighted: not applicable - returns which nodes are neighbors, not tie values. Signed: not applicable. Two-mode: not checked.

{title:Stored results}

	Scalars
	  {bf:r(ego)}		nodeid of ego
	  {bf:r(oneneighbor)}	one randomly selected neighbor
	
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

***/

capture program drop nwneighbor
program nwneighbor
	syntax [anything(name=netname)], ego(string) [ mode(string) generate(string) replace]
	nw_syntax `netname', max(1)
	nw_datasync `netname'
	nwname `netname'

	capture confirm variable `generate'
	if _rc == 0 & "`replace'" == "" {
		di "{err}Variable {bf:`generate'} already exists; use {bf:replace}"
		err 99
	}
	qui nwnode `netname', ego(`ego')
	local egoid `r(nodeid)'
	local ego `r(nodename)'
	if `egoid' == -1 {
		di "{err}Node {bf:`ego'} does not exist in network {bf:`netname'}"
		err 99
	}

	if "`mode'" == "" {
		local mode = "outgoing"
	}

	_opts_oneof "incoming outgoing either" "mode" "`mode'" 6556
	
	// Sparse-accessor rewrite: the prior dense-matrix "incoming" line had a
	// stray unbalanced paren (a genuine, latent syntax-error bug - that
	// mode could never have actually run). neighbors()/neighbors_in() are
	// the same sparse CSR/CSC accessors already used by calculate_kcore()
	// etc.; nzmask's own !=0 & !=. edge convention (build_sparse_index())
	// matches the dense comparison this replaces exactly, so results are
	// identical, not just equivalent.
	if "`mode'" == "outgoing" {
		mata: __nb = `netobj'->neighbors(`egoid')
	}
	if "`mode'" == "incoming" {
		mata: __nb = `netobj'->neighbors_in(`egoid')
	}
	if "`mode'" == "either"{
		mata: __nb = uniqrows(`netobj'->neighbors(`egoid') \ `netobj'->neighbors_in(`egoid'))
	}
	mata: _select = J(1, `nodes', 0)
	mata: _select[__nb'] = J(1, rows(__nb), 1)
	mata: neighbors = select((`netobj'->get_nodenames() \ strofreal(1::`netobj'->get_nodes())'), _select)
	mata: mata drop __nb

	capture confirm variable `generate'
	if (_rc != 0 | "`replace'" != "") & "`generate'" != "" {
		capture drop `generate'
		gen `generate' =.
		mata: st_store((1::`nodes'), "`generate'", _select')
	}
	mata: st_rclear()
	capture mata: neighbor=jumble(neighbors)[1]
	capture mata: st_global("r(ego)", "`ego'")
	capture mata: st_numscalar("r(egoid)", `egoid')
	capture mata: st_global("r(oneneighbor)", jumble(neighbors)[1])
	mata: st_numscalar("r(num_neighbors)", cols(neighbors))

	di ""
	di "{hline 40}"
	di "{txt}  Network: {res}`netname'"
	di "{hline 40}"
	di "{txt}    Ego        :   {res}`ego' (`r(egoid)')"
	di "{txt}    Neighbors  : {res}" _continue
	di ""
	mata: neighbors'
	mata: st_matrix("r(neighbors)", strtoreal(neighbors'[.,2]))
	di ""
	di "{hline 40}"
	capture mata: mata drop neighbors
end

