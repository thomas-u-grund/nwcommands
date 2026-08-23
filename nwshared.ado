/***
{smcl}
{* *! version 2.0.0  18may2019 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis:[NW-2.6] Analysis}

{title:Title}

{p2colset 9 17 23 2}{...}
{p2col :nwshared {hline 2} Calculate number of shared neighbors between nodes and saves information in network}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab: nwshared} 
[{it:{help netname}}]
[{cmd:,}
{opth name(newnetname)}
{opt undirected}
{opt nwreplace}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth name(newnetname)}}Save as new network; default {it:_shared}{p_end}
{synopt:{opt undirected}}Treat all ties as undirected for calculation{it:_shared}{p_end}

{title:Description}

{pstd}
This command calculates for each connected pair of nodes (i,j) the number of nodes k that both i and j
have as shared neighbors.  

{title:Example}

		{cmd:. nwwebuse florentine, nwclear}
		{cmd:. nwshared flomarriage, name(shared)}
		{cmd:. nwplot flomarriage, edgecolor(shared) edgesize(shared) edgefactor(3)}

{title:See also}
	{help nwsimmelian}
	
***/
capture program drop nwshared
program nwshared
	syntax [anything(name=netname)] [, name(string) nwreplace]
	nw_syntax `netname'
	
	if "`name'" == "" {
		local name "_shared"
	}
	nwvalidate `name'
	if "`r(exists)'" == "true" & "`nwreplace'" == "" {
		noi di "{err}No, network {bf:`name'} already exists; use differentname or option {bf:nwreplace}."
		error 3000
	}
	capture nwdrop `name'
	
	tempname symmetrized
	if "`undirected'" != "" {
		nwsym `netname', name(`symmetrized')
		local netname `symmetrized'
	}
	
	nwduplicate `netname', name(`name')
	nw_syntax
	
	mata: `netobj'->set_edge((`netobj'->get_matrix_unvalued_copy()):* ((`netobj'->get_matrix_unvalued_copy()) * (`netobj'->get_matrix_unvalued_copy())))
	capture nwdrop `symmetrized'
end
