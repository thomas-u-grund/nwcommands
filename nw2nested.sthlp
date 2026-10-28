{smcl}
{* *! version 1.0.0  25oct2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_cohesion:[NW-2.6.2] Cohesion, Components & Subgroups}

{viewerjumpto "Syntax" "nw2nested##syntax"}{...}
{viewerjumpto "Description" "nw2nested##description"}{...}
{viewerjumpto "Options" "nw2nested##options"}{...}
{viewerjumpto "Stored results" "nw2nested##results"}{...}
{viewerjumpto "Supported network types" "nw2nested##types"}{...}
{viewerjumpto "References" "nw2nested##references"}{...}
{title:Title}

{p2colset 5 18 20 2}{...}
{p2col:{bf:nw2nested} {hline 2}}Nestedness of a two-mode network: NODF and C-score{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:nw2nested} [{it:netname}] [{cmd:,} {opt lev:el(#)} {opt silent}]

{synoptset 12 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt lev:el(#)}}the mode whose pairs of nodes enter the C-score, 1 or 2; default {cmd:level(2)} (the columns of the matrix, as in {cmd:bipartite::C.score}){p_end}
{synopt:{opt silent}}suppress the output{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:nw2nested} measures how nested a two-mode network is, the question asked of the species-by-site and plant-pollinator matrices of ecology and of any membership matrix in which the small groups are subsets of the large ones. {bf:NODF} is the nestedness metric based on overlap and decreasing fill of Almeida-Neto et al. (2008): for every pair of nodes of one mode with different degrees it takes the percentage of the ties of the node with the smaller degree that the other node has too (0 for equal degrees), and averages over all pairs of both modes (NODF) or over the pairs of one mode. The {bf:C-score} of Stone and Roberts (1990) counts the checkerboard units, the pairs of nodes that each have a partner the other lacks, and averages over all pairs of nodes of one mode; the normalised form divides each count by its largest possible value for the two degrees (the form of {cmd:bipartite::C.score(normalise = TRUE)}). The result does not depend on the order of the nodes.

{pstd}
Ties are read as present or absent; tie values are ignored. A pair with an empty or full node has no normalised C-score and is left out of its mean.


{marker options}{...}
{title:Options}

{phang}
{opt level(#)} chooses the mode whose pairs of nodes enter the C-score. The default 2 uses the nodes of the second mode (the columns of the matrix with the first mode as rows). NODF always uses both modes.


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:nw2nested} stores in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(nodf)}}NODF, percent{p_end}
{synopt:{cmd:r(nodf_mode1)}}NODF among the nodes of mode 1, percent{p_end}
{synopt:{cmd:r(nodf_mode2)}}NODF among the nodes of mode 2, percent{p_end}
{synopt:{cmd:r(cscore)}}mean number of checkerboard units per pair{p_end}
{synopt:{cmd:r(cscore_norm)}}mean normalised C-score, 0 to 1 ({cmd:bipartite} reports it times 100){p_end}
{synopt:{cmd:r(cscore_pairs)}}number of pairs in the normalised mean{p_end}
{synopt:{cmd:r(level)}}mode of the C-score pairs{p_end}
{p2colreset}{...}


{marker types}{...}
{title:Supported network types}

{pstd}
Binary: yes. Directed: not applicable (a two-mode network is undirected). Valued: tie values are ignored (presence of a tie). Two-mode: yes - the command needs a two-mode network and uses the biadjacency matrix of the two modes ({cmd:bipartite::nested}, {cmd:vegan::nestednodf}, {cmd:bipartite::C.score}).


{marker references}{...}
{title:References}

{phang}
Almeida-Neto, M., P. Guimaraes, P. R. Guimaraes, R. D. Loyola, and W. Ulrich. 2008. A consistent metric for nestedness analysis in ecological systems. {it:Oikos} 117: 1227-1239.

{phang}
Stone, L., and A. Roberts. 1990. The checkerboard score and species distributions. {it:Oecologia} 85: 74-79.


{title:Also see}

{psee}
{help nw2set}, {help nw2degree}, {help nw2clustering}, {help nw2project}, {help nwnetworktypes}

{hline}
{pstd}{it:nwcommands version 3.12.0, 28 October 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
