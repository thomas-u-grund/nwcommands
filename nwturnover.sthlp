{smcl}
{* *! version 1.0.0  22aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_other:[NW-2.6.8] Other analysis tools}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwturnover {hline 2}}Tie turnover/stability between two waves of the same network{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwturnover}
{it:net1} {it:net2}
{cmd:,}
{opth gen:erate(newvarname)}
[{opt rep:lace}
{opt silent}
{opt formation}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth gen:erate(newvarname)}}{bf:Required.} Name of the Stata variable that stores each node's own local stability{p_end}
{synopt:{opt rep:lace}}Replace existing variable{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}
{synopt:{opt formation}}Compare the formed ties with all pairs without a tie in {it:net1}: the shares that return a tie and that close a two-path{p_end}

{p2colreset}{...}


{title:Description}

{pstd}
{cmd:nwturnover} compares two networks on the SAME node set representing two waves of
observation of the same relationship (e.g. a panel/longitudinal network study, {it:net1} at time
{it:t} and {it:net2} at time {it:t+1}) and reports how much the tie structure changed between
them: how many ties were {bf:stable} (present at both waves), {bf:formed} (absent at {it:net1},
present at {it:net2}), or {bf:dissolved} (present at {it:net1}, absent at {it:net2}). Only tie
presence/absence is compared (not tie weight) - {help nwcorrelate}, which correlates tie
{it:values} between two networks, answers a related but different question.

{pstd}
{bf:r(jaccard)} is the standard "Jaccard index of network change" used in longitudinal SNA (e.g.
Snijders et al.'s SIENA methodology) to gauge whether enough change occurred between waves to be
worth modeling at all: {bf:stable / (stable + formed + dissolved)} - 1 when the two networks are
identical, 0 when they share no tie in common whatsoever. {bf:r(persistence)} is a related but
distinct question - of the ties that existed at {it:net1}, what fraction survived to {it:net2}:
{bf:stable / (stable + dissolved)}, undefined (missing) if {it:net1} has no ties at all.

{pstd}
{opt generate()} is required and names the per-node variable that gives each
node's OWN local Jaccard stability - computed the same way as {bf:r(jaccard)}, but restricted to
that one node's own ties across the two waves, rather than the whole network's.

{pstd}
{it:net1} and {it:net2} must have the same number of nodes and the same directedness (both
directed or both undirected) - comparing a directed network to an undirected one, or two networks
of different size, is rejected explicitly rather than silently doing something arithmetically
possible but conceptually meaningless.

{pstd}
For an {bf:undirected} pair of networks, {bf:r(stable)}, {bf:r(formed)}, and {bf:r(dissolved)}
each count both {it:(i,j)} and {it:(j,i)} for the same tie, so all three are exactly double the
number of actual undirected ties involved (the same convention {help nwmixing} uses for its own
mixing table). {bf:r(jaccard)} and {bf:r(persistence)} are unaffected, since the doubling cancels
in both ratios.

{pstd}
{opt formation} asks which of the ties formed between the two waves continue a pattern of {it:net1}.
A formed tie from {it:i} to {it:j} {bf:returns a tie} if {it:j} named {it:i} in {it:net1}, and it {bf:closes a two-path} if
{it:i} named some {it:k} who named {it:j} in {it:net1}. The command shows both shares among the formed ties and
among all pairs without a tie in {it:net1} (the pairs from which every formed tie comes; the diagonal is
not a pair, and a missing value counts as no tie). These are the descriptive precursors of the reciprocity and
transitivity effects of an actor-oriented model. For an undirected pair of networks only the two-path share is
shown, and the pairs are counted once. Two-mode networks are not allowed with {opt formation}. The option
builds the adjacency matrices of both networks, so its memory use grows with the square of the number of nodes.

{title:Network types}

{pstd}
{bf:Directed:} each ordered pair is compared; both networks must have the same directedness. {bf:Valued:} tie values
are ignored (the command prints a note on a valued network). {bf:Two-mode:} yes - only the ties between the modes are
counted; both networks should have the same modes. {bf:Signed:} negative values are not treated specially. See
{help nwnetworktypes}.{p_end}


{title:Limits}

{pstd}
The ties kept, formed and dissolved are counted from the lists of ties of the two networks (sorted keys) when both are held as
stored ties. Measured in Stata/BE, random directed network with 10 ties per node: 20,000 nodes 0.2 seconds.


{title:Examples}

	{cmd:. nwset, mat((0,1,1\1,0,0\1,0,0)) name(wave1)}
	{cmd:. nwset, mat((0,1,0\1,0,1\0,1,0)) name(wave2)}
	{cmd:. nwturnover wave1 wave2, generate(_turnover)}

	{cmd:. nwwebuse glasgow, nwclear}
	{cmd:. nwturnover glasgow1 glasgow2, generate(_turnover) formation}


{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{bf:r(stable)}}number of ties present in both networks{p_end}
{synopt:{bf:r(formed)}}number of ties present only in {it:net2}{p_end}
{synopt:{bf:r(dissolved)}}number of ties present only in {it:net1}{p_end}
{synopt:{bf:r(jaccard)}}stable / (stable + formed + dissolved){p_end}
{synopt:{bf:r(persistence)}}stable / (stable + dissolved); missing if {it:net1} has no ties{p_end}
{p2col 5 20 24 2: With {opt formation}}{p_end}
{synopt:{bf:r(absent)}}number of pairs without a tie in {it:net1}{p_end}
{synopt:{bf:r(formed_recip)}}share of formed ties that return a tie (directed networks){p_end}
{synopt:{bf:r(absent_recip)}}the same share among the pairs without a tie (directed networks){p_end}
{synopt:{bf:r(formed_closure)}}share of formed ties that close a two-path{p_end}
{synopt:{bf:r(absent_closure)}}the same share among the pairs without a tie{p_end}


{title:References}

{pstd}
Snijders, T.A.B., van de Bunt, G.G., Steglich, C.E.G. (2010). Introduction to stochastic actor-based
models for network dynamics. {it:Social Networks} 32(1), 44-60. (the Jaccard index of network
change, used as a standard diagnostic for whether panel-wave data is suitable for dynamic modeling)


{title:See also}

	{help nwcorrelate}, {help nwcomponents}, {help nwqap}

{hline}
{pstd}{it:nwcommands version 3.24.0, 13 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
