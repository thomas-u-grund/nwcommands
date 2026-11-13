{smcl}
{* *! version 2.0.0  18may2019 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_cohesion:[NW-2.6.2] Cohesion, components and subgroups}

{title:Title}

{p2colset 9 17 23 2}{...}
{p2col :nwsimmelian {hline 2}}Simmelian ties{p_end}
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
Simmelian ties are concerned with more than just the strength of the relationship (see Krackhardt 1999). The original concept looks at the number of
strong, reciprocated ties within a group: for a simmelian tie to exist, there must be three (a triad) or more of reciprocal strong ties in a group,
viewed as even stronger than a regular strong tie. {bf:This command implements the reciprocated-triad structure only - it does not apply any tie-strength/value threshold} (see
{bf:Network types} below); a weak reciprocated tie in a closed triad is flagged identically to a strong one.

{pstd}
For example, if Adam has a (reciprocated) tie to Betty, and both Adam and Betty share a (reciprocated) tie to Charles, this three-way tie would be a simmelian one.

{pstd}
The concept of a Simmelian tie is related to that of a clique; each pair of nodes (individuals) in a clique has a Simmelian tie between them. Thus a simmelian tie can be defined as a basic tie in a
clique, or a co-clique relationship (between individuals who belong to a specific clique).


{title:Network types}

{pstd}
{bf:Directed:} only mutual ties count. {bf:Valued:} tie values are ignored (no strength threshold) and a note is
printed. {bf:Two-mode:} same as for the bipartite graph read as a one-mode network. {bf:Signed:} not applicable. See
{help nwnetworktypes}.{p_end}


{title:Limits}

{pstd}
The mutual ties and the mutual neighbours they share are found from the tie lists. Measured in Stata/BE, random undirected
network with 10 ties drawn per node: 20,000 nodes need 1.2 GB.

{pstd}
The mutual ties that have a mutual neighbour in common are found in the compiled graph plugin (the native kernel of {cmd:nwcommands}) when the plugin of your
platform has it, and in Mata otherwise; both give the same network. Measured in Stata/BE, random undirected network with mean degree 10: 5,000 nodes 0.08 seconds,
20,000 nodes 0.2 seconds, 100,000 nodes 0.8 seconds (the Mata route needs 0.5, 2.0 and 11.6 seconds). A network with self-loops takes the Mata route.{p_end}
{pstd}
For all commands at network sizes of 1,000 to 100,000 nodes see the web page {browse "https://nwcommands.org/nwcommands/size-limits/":How large a network can I analyze?}


{title:Examples}

		{cmd:. nwwebuse florentine, nwclear}
		{cmd:. nwsimmelian flomarriage}
		{cmd:. nwplot flomarriage, edgecolor(_simmelian)}


{title:References}

{pstd}
Krackhardt, D. (1999). The ties that torture: Simmelian tie analysis in organizations. {it:Research in the Sociology of Organizations} (16), 183-210.


{title:See also}
	{help nwshared}

{hline}
{pstd}{it:nwcommands version 3.23.0, 13 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
