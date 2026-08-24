/***
{smcl}
{* *! version 2.0.0  18may2019 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_positions:[NW-2.6.4] Positions, Roles & Equivalence}

{title:Title}

{p2colset 9 17 23 2}{...}
{p2col :nwshared {hline 2}}Calculate number of shared neighbors between nodes and saves information in network{p_end}
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
	// BUGFIX: `undirected' is documented (syntax diagram + synoptset)
	// and referenced in this program's own body below, but was never
	// declared here - Stata rejected it outright as an unrecognized
	// option, so the documented option could never actually be used.
	syntax [anything(name=netname)] [, name(string) nwreplace undirected]
	nw_syntax `netname'
	
	if "`name'" == "" {
		local name "_shared"
	}
	nwvalidate `name'
	if "`r(exists)'" == "true" & "`nwreplace'" == "" {
		// BUGFIX: was `error 3000' - a bare Stata error code with its
		// own, unrelated built-in meaning ("Mata compile-time error"),
		// so Stata prints ITS OWN generic canned text for that alongside
		// this command's own custom message, confusingly implying an
		// actual crash rather than a deliberate name-collision guard.
		// r(6099) is this package's own established convention for
		// exactly this situation (see nwset.ado's/nwfromedge.ado's own
		// identical guard, harmonisation unit 116) - reused here instead.
		noi di "{err}No, network {bf:`name'} already exists; use differentname or option {bf:nwreplace}."
		error 6099
	}
	capture nwdrop `name'
	
	tempname symmetrized
	if "`undirected'" != "" {
		// BUGFIX: was `name(`symmetrized')' - nwsym.ado's own real
		// option for its output network name is `generate()', not
		// `name()' (confirmed against its own syntax line). This was
		// unreachable until the `undirected' option itself was fixed
		// above (previously rejected before ever getting this far), so
		// it never actually ran until now.
		nwsym `netname', generate(`symmetrized')
		local netname `symmetrized'
	}
	
	nwduplicate `netname', name(`name')
	nw_syntax
	
	mata: `netobj'->set_edge((`netobj'->get_matrix_unvalued_copy()):* ((`netobj'->get_matrix_unvalued_copy()) * (`netobj'->get_matrix_unvalued_copy())))
	capture nwdrop `symmetrized'
end
