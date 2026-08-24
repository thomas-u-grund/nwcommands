/***
{smcl}
{* *! version 2.0.0  18may2019 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_cohesion:[NW-2.6.2] Cohesion, Components & Subgroups}

{title:Title}

{p2colset 9 17 23 2}{...}
{p2col :nwsimmelian {hline 2}}Calculate Simmelian ties{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab: nwsimmelian} 
[{it:{help netname}}]
[{cmd:,}
{opth name(newnetname)}
{opt nwreplace}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth name(newnetname)}}Save Simmelian ties as new network; default {it:_simmelian}{p_end}


{title:Description}

{pstd}
Simmelian ties are concerned with more than just the strength of the relationship (see Krackhardt 1998). They look at the number of strong ties within a
group. For a simmelian tie to exist, there must be three (a triad) or more of reciprocal strong ties in a group. A simmelian tie is viewed as even stronger than a regular strong tie.

{pstd}
For example, if Adam has a strong tie to Betty, and both Adam and Betty share a strong tie to Charles, this three-way tie would be a simmelian one.

{pstd}
The concept of a Simmelian tie is related to that of a clique; each pair of nodes (individuals) in a clique has a Simmelian tie between them. Thus a simmelian tie can be defined as a basic tie in a clique, or a co-clique relationship (between individuals who belong to a specific clique).
		

{title:Supported network types}

{pstd}
Binary: yes (only) - uses {cmd:get_matrix_unvalued()} throughout; a weak tie and a strong tie in an otherwise-identical closed triad are both flagged as Simmelian identically, despite this command's own documentation describing the concept in "strong tie" language (a known doc/implementation gap, not yet resolved - see the alpha audit's own finding). Directed: yes - reciprocity is checked directly (a tie must be mutual to participate at all), matching the concept's own directed-advice-network origin (Krackhardt 1999); on an undirected network reciprocity is automatically satisfied by every existing tie. Weighted: not applicable. Signed: not applicable. Two-mode: not checked.

{title:References}

{pstd}
Krackhardt, D. (1999). The ties that torture: Simmelian tie analysis in organizations. {it:Research
in the Sociology of Organizations} (16), 183-210.

{title:Example}

		{cmd:. nwwebuse florentine, nwclear}
		{cmd:. nwsimmelian flomarriage}
		{cmd:. nwplot flomarriage, edgecolor(_simmelian)}

{title:See also}
	{help nwshared}
	
***/
capture program drop nwsimmelian
program nwsimmelian
	syntax [anything(name=netname)] [, name(string) nwreplace]
	unw_defs
	nw_syntax `netname'
	
	if "`name'" == "" {
		local name "_simmelian"
	}
	nwvalidate `name'
	if "`r(exists)'" == "true" & "`nwreplace'" == "" {
		// BUGFIX: was `error 3000' - a bare Stata error code with its
		// own, unrelated built-in meaning ("Mata compile-time error"),
		// so Stata prints ITS OWN generic canned text for that alongside
		// this command's own custom message, confusingly implying an
		// actual crash rather than a deliberate name-collision guard.
		// Error-code coherence pass: this situation ("network already
		// exists") is exactly what `errNWsExists' (483, unw_defs.ado)
		// already names and documents - several sibling commands
		// (nwset/nwfromedge/nwshared/nwtranspose/nwgenerate/nwuse) had
		// independently drifted onto an undocumented ad-hoc `6099'
		// instead of this already-established constant; all now
		// consolidated onto `errNWsExists'.
		noi di "{err}No, network {bf:`name'} already exists; use differentname or option {bf:nwreplace}."
		error `errNWsExists'
	}
	capture nwdrop `name'

	nwduplicate `netname', name(`name')
	nw_syntax
	mata: __nw_mutual = (*`netobj'->get_matrix_unvalued()) :* (*`netobj'->get_matrix_unvalued())'
	mata: _editmissing(__nw_mutual,0)
	mata: __nw_simmel = (__nw_mutual) :* (__nw_mutual * __nw_mutual)
	mata: __nw_simmel = (__nw_simmel :!= 0)
	mata: `netobj'->set_edge(__nw_simmel)
	capture mata: mata drop __nw_simmel __nw_mutual
end
