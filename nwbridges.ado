/***
{smcl}
{* *! version 2.0.1  5jun2019 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##generator:[NW-2.3] Generators}
{marker top2}
{helpb nw_topical##analysis_cohesion:[NW-2.6.2] Cohesion, Components & Subgroups}

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


{title:Supported network types}

{pstd}
Binary: yes (only) - bridge status is a structural property, tie values are ignored. Directed: yes - {opt type()} distinguishes local/global bridges and arcs vs. edges. Weighted: not applicable. Signed: not applicable. Two-mode: not checked.

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

{title:See also}

	{help nwburt}, {help nwpath}

***/

capture program drop nwbridges
program nwbridges
	// A bare `distance' flag was declared here alongside `type(string)',
	// but never referenced anywhere in this file's body (confirmed via
	// grep) - `type(distance)' (one of the three real `type()' values,
	// see `_opts_oneof' below) already covers this, making the bare flag
	// a confusing, fully dead duplicate. Removed.
	syntax [anything(name=netname)] [, nwreplace name(string) type(string)]
	nw_syntax `netname'
	local oldname `netname'
	local olddirected `netname'
	local generate "`name'"
	if "`type'" == "" {
		local type "global"
	}
	_opts_oneof "local global distance" "type" "`type'" 6556
	
	if "`generate'" == "" {
		local generate "_bridges"
	}

	capture nw_syntax `generate', other(other)
	if _rc == 0 & "`nwreplace'" == "" {
		di "{err}Network {bf:`generate'} already exists; use {bf:nwreplace}"
		err 99
	}
	capture nwdrop `generate'
	nwduplicate `netname', name(`generate')

	nw_syntax `generate'
	// PERFORMANCE FIX: type(global) only needs to know which ties are
	// bridges (does removing this one tie disconnect its endpoints?),
	// not the actual alternate-path distance calculate_distances_
	// without() computes for every single tie via its own dedicated
	// BFS - O(m*(V+E)) total, confirmed too slow to complete within
	// several minutes at n=10,000/50k edges during a benchmark run.
	// calculate_bridges_global() answers exactly the type(global)
	// question via a single O(V+E) DFS (Tarjan 1974) instead - but
	// only for UNDIRECTED networks; a directed graph's own analogous
	// question is a different, harder problem this fix does not
	// attempt (see that method's own header comment), so directed
	// input keeps using the original, unchanged computation. type(
	// local)/type(distance) both need real distance values (not just
	// a bridge/not-bridge boolean) and also keep the original path
	// unconditionally.
	if "`type'" == "global" & "`directed'" == "false" {
		mata: `netobj'->set_edge(`netobj'->calculate_bridges_global())
	}
	else {
		mata: `netobj'->set_edge(`netobj'->calculate_distances_without())
	}
	if "`type'" == "global" {
		nwreplace `generate' = (`generate' == -1)
		local type "global"
	}
	if "`type'" == "local"{
		nwreplace `generate' = (`generate' == -1 | `generate' > 2)
		local type "local"
	}
	if "`type'" == "distance" {
		local type "distance"
	}
	
	if "`olddirected'" == "false" {
		nwsym `generate', mode(min)
	}
	qui nwsummarize `generate'
	if "`directed'" == "true" {
		local bridges = `r(arcs)'
	}
	else {
		local bridges = `r(edges)'
	}
	mata: st_rclear()
	
	nw_syntax `oldname'
	mata: st_global("r(name)", "`netname'")
	mata: st_global("r(directed)", "`directed'")
	mata: st_global("r(bridges)", "`bridges'")
	mata: st_global("r(bridges_type)", "`type'")
	di ""
	di "{hline 30}"
	di "{txt}    Network      : {res}`netname'"
	di "{txt}    Directed     : {res}`directed'"
	di "{txt}    Bridges      : {res}`r(bridges)'"
	di "{txt}    Type         : {res}`r(bridges_type)'"
	di "{hline 30}"
	
end



