{smcl}
{* *! version 2.0.0  18may2019 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_cohesion:[NW-2.6.2] Cohesion, Components & Subgroups}

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
{synopt:{opt nwreplace}}Replace the network {it:name()} if it already exists{p_end}


{title:Description}

{pstd}
Simmelian ties are concerned with more than just the strength of the relationship (see Krackhardt 1998). The original concept looks at the number of
strong, reciprocated ties within a group: for a simmelian tie to exist, there must be three (a triad) or more of reciprocal strong ties in a group,
viewed as even stronger than a regular strong tie. {bf:This command implements the reciprocated-triad structure only - it does not apply any tie-strength/value threshold} (see {bf:Supported network types} below); a weak reciprocated tie in a closed triad is flagged identically to a strong one.

{pstd}
For example, if Adam has a (reciprocated) tie to Betty, and both Adam and Betty share a (reciprocated) tie to Charles, this three-way tie would be a simmelian one.

{pstd}
The concept of a Simmelian tie is related to that of a clique; each pair of nodes (individuals) in a clique has a Simmelian tie between them. Thus a simmelian tie can be defined as a basic tie in a clique, or a co-clique relationship (between individuals who belong to a specific clique).
		

{title:Valued networks}

{pstd}
This measure uses the presence of ties only (R has no weighted form of it either). On a valued network ({help nwnetworktypes}) the command prints the line "(note: tie values are ignored; this measure is binary)" once (not with {opt silent} or {cmd:quietly}) and treats every tie as present. To choose which ties count, make a binary copy with {help nwdichotomize} first.

{title:Supported network types}

{pstd}
Binary: yes (only) - uses {cmd:get_matrix_unvalued()} throughout; a weak tie and a strong tie in an otherwise-identical closed triad are both flagged as Simmelian identically, despite this command's own documentation describing the concept in "strong tie" language (the concept is often described in terms of strong ties; this command does not apply a strength threshold). Directed: yes - reciprocity is checked directly (a tie must be mutual to participate at all), matching the concept's own directed-advice-network origin (Krackhardt 1999); on an undirected network reciprocity is automatically satisfied by every existing tie. Weighted: not applicable. Signed: not applicable. Two-mode: same as for the bipartite graph read as a one-mode network (valid; no mode-specific normalisation).

{title:References}

{pstd}
Krackhardt, D. (1999). The ties that torture: Simmelian tie analysis in organizations. {it:Research in the Sociology of Organizations} (16), 183-210.

{title:Examples}

		{cmd:. nwwebuse florentine, nwclear}
		{cmd:. nwsimmelian flomarriage}
		{cmd:. nwplot flomarriage, edgecolor(_simmelian)}

{title:Limits}

{pstd}
The mutual ties and the mutual neighbours they share are found from the tie lists. Measured in Stata/BE, random undirected
network with 10 ties drawn per node: 20,000 nodes need 1.2 GB (12.5 GB before).

{pstd}
The mutual ties that have a mutual neighbour in common are found in the compiled graph plugin (the native kernel of {cmd:nwcommands}) when the plugin of your
platform has it, and in Mata otherwise; both give the same network. Measured in Stata/BE, random undirected network with mean degree 10: 5,000 nodes 0.08 seconds,
20,000 nodes 0.2 seconds, 100,000 nodes 0.8 seconds (the Mata route needs 0.5, 2.0 and 11.6 seconds). A network with self-loops takes the Mata route.
{pstd}
For all commands at network sizes of 1,000 to 100,000 nodes see the web page {browse "https://nwcommands.org/nwcommands/size-limits/":How large a network can I analyze?}

{title:See also}
	{help nwshared}
	
last certified : 24 Aug 2026

{hline}
{pstd}{it:nwcommands version 3.10.0, 26 October 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
