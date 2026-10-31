{smcl}
{* *! version 1.1.0  02sep2026}{...}
{marker topic}
{helpb nwtopical##utilities:[NW-2.7] Utilities}

{title:Title}

{p2colset 9 22 24 2}{...}
{p2col :nwnetworktypes {hline 2}}How commands classify binary/directed/weighted/signed/two-mode networks{p_end}
{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwcommands} networks can be binary or valued (weighted), undirected or directed, and one-mode
or two-mode (bipartite) - see {help nwintro} for the underlying data model. No single command
supports every combination equally: some are inherently structural and apply unchanged to any
network (e.g. {help nwdrop}); some have a well-defined weighted generalization but a separate
binary-only default (e.g. {help nwclustering}); some have a two-mode form of the same concept that they use
automatically on a two-mode network (e.g. {help nwdegree}; the option {opt onemode} forces the one-mode computation); a few are simply not implemented for a
combination yet.

{pstd}
Rather than guess, every {cmd:nw*} command's own help file has a {bf:Supported network types}
section (immediately after its {bf:Description}) stating explicitly what it does with a directed,
weighted, signed, or two-mode network - whether that is full native support, an explicit
binary-only/one-mode-only restriction with a clear error, silent-but-documented dichotomization, or
simply "not applicable" for a command with no network-type-dependent behavior at all. That
per-command section is always the authoritative answer for a specific command; this page explains
the vocabulary those sections use and points to the small set of commands that have been read
closely enough to also carry a fuller, source-verified classification.

{title:Valued networks}

{pstd}
Every network carries a {it:Valued} flag (shown by {help nwsummarize}). It is set when the network is created, by the
way it is created, and it is not worked out from the values again later: a network created with tie values
({help nwfromedge} with a value variable, an import of a file with tie values, {cmd:nwset, valued}, a matrix with a
value other than 0 and 1) is valued, also if every value is 1; a network created without values is binary. Commands
that transform a network keep its flag; {help nwdichotomize} gives a binary network. A network that was saved by an
earlier release keeps the flag it was saved with ({cmd:nwname} {it:net}{cmd:, newvalued(true)} changes it).

{pstd}
Measures that have a weighted form in R use the tie values of a valued network by default
({help nwdegree}, {help nw2degree}, {help nwgeodesic}, {help nwcloseness}, {help nwbetween}, {help nwevcent},
{help nwpagerank}, {help nwrandomwalk}, {help nwpath}, {help nwmatching}, {help nwassortativity}, {help nwkatz} with
{opt walks}); the option {opt binary} ignores the values. Measures without a weighted form in R are binary by
definition and print the line "(note: tie values are ignored; this measure is binary)" on a valued network. The
website page on valued networks lists all commands.

{title:Two-mode networks and the nw2* names}

{pstd}
Every network carries a {it:Two-mode} flag (shown by {help nwsummarize}). It is set when the network is created, by
declaration, and nowhere else: {cmd:nwset, twomode} or {cmd:bipartite}, {help nw2fromedge}, {help nw2set},
{cmd:nwfromedge, twomode}, {help nwimport} of a file that declares the modes and {help nwuse} of a saved two-mode
network. No measure works the flag out from the ties, because the adjacency matrix of a two-mode network looks like
that of a one-mode network. The declaration is checked: both modes must hold nodes and no tie may join two nodes of
the same mode ({cmd:nwname, new2mode(true)} on a one-mode network is an error). Every command that derives a network
from a two-mode network ({help nwdropnodes}, {help nwkeepnodes}, {help nwsubset}, {help nwduplicate}, {help nwsym},
{help nwtranspose}, {help nwrecode}, {help nwdichotomize}, {help nwaddnodes}, {help nwpermute}) keeps the flag, the
modes and the level labels. {help nwexport} and {help nwimport} keep the flag and the modes in all four formats and the level labels in Pajek, GML and edge list files (UCINET DL has no place for them); an edge list written
by {help nwtoedge} or {help nw2toedge} holds the ties between the modes and reads back as the same network.

{pstd}
Every command's help file says in its {bf:Supported network types} section, in one of four fixed wordings, what the
command does with a two-mode network:

{phang2}
{bf:Two-mode: yes - ...} The command uses the two modes the way R does ({cmd:tnet}, {cmd:igraph},
{cmd:bipartite}); the rest of the sentence says what changes.

{phang2}
{bf:Two-mode: two-mode form by default ...} The command has a two-mode form of the same statistic and uses it on a
two-mode network without being asked; the option {opt onemode} forces the one-mode computation on the bipartite graph.
{help nwdegree}, {help nwclustering}, {help nwmotifs}, {help nwcloseness} and {help nwbetween} are of this kind.

{phang2}
{bf:Two-mode: same as for the bipartite graph read as a one-mode network (valid; no mode-specific normalisation)}
The measure is defined on any graph and the number is right for the bipartite graph: components, k-cores, geodesics,
betweenness, closeness, PageRank, eigenvector centrality, Burt's constraint and so on. Nothing is printed.

{phang2}
{bf:Two-mode: not supported - error 6088} The command would read the blocks between nodes of the same mode, which hold
no ties, and give missing or meaningless numbers. It stops with one message (the same for every such command) and
the error 6088. Make a one-mode network of one mode with {help nwproject} first. {help nwspectral} and
{help nwrandomwalk} have the option {opt onemode}, which reads the bipartite graph as a one-mode graph, as {cmd:igraph}
does.

{pstd}
{bf:The rule.} A network declares itself two-mode when it is created. A command that has a two-mode form of the same
concept uses that form automatically on a two-mode network, and the option {opt onemode} forces the one-mode
computation on the bipartite graph (what {cmd:igraph} does with a bipartite graph). {help nwdegree}
(number of ties over the size of the other mode, {cmd:raw} for the count), {help nwclustering} (Opsahl 2013; {opt ra}:
Robins and Alexander 2004), {help nwmotifs} (the bipartite motifs of Simmons et al. 2019), {help nwcloseness} and
{help nwbetween} (the normalisations of Borgatti and Everett 1997; {opt twomode} is accepted as a synonym of the default),
{help nwcommunity} and {help nwmodularity} (the bipartite modularity of Barber) and {help nwsimilar} and
{help nwdissimilar} (nodes are compared with nodes of their own mode) follow it. The names {help nw2degree},
{help nw2clustering} and {help nw2motifs} remain as aliases of the main commands with the options they always had.
{help nw2project} and {help nw2nested} have no one-mode counterpart and keep their own names. The website page on
two-mode networks and the table of network types list all commands.

{title:Weighted (valued) networks}

{pstd}
A network is {it:valued} (weighted) when its ties carry a real number, not just presence/absence -
set automatically whenever {help nwset}, {help nwfromedge}, or an import command is given tie
values other than a plain 0/1 indicator (at least one tie value other than 0 and 1; a network whose ties are all 1 is binary), and readable via {help nwsummarize}/{help nwname}'s own
{cmd:valued} field. As with two-mode status, ordinary commands do not need a special flag to tell
them a network is valued; each command's own {bf:Supported network types} section states what it
actually does with the tie values.

{pstd}
Three patterns cover almost every command in this package:

{phang2}
{bf:1. Native (W1)} - the tie value enters the calculation directly, with one well-defined
formula for the whole [0,1] weighted-to-binary spectrum. Most centrality/cohesion commands with a
weighted variant follow Opsahl, Agneessens and Skvoretz (2010)'s own generalized-degree convention:
{it:k_i * (s_i/k_i)^alpha}, where {it:k_i} is the plain tie count and {it:s_i} is the tie-value sum
("strength"). {opt alpha(0)} always reduces this back to plain unweighted degree exactly - not
approximately - so a command gaining this option never changes an existing unweighted result;
{opt alpha(1)} gives pure strength; values in between blend the two. {help nwdegree} and
{help nw2degree} (one-mode and two-mode degree respectively) both use this exact formula;
{help nwbetween}'s {opt weighted} option uses the same {opt alpha()} convention to turn tie
strength into a Dijkstra path cost instead ({help nwgeodesic}/{help nwkatz} do too, for distance);
{help nwconstraint}/{help nwburt} use tie weight directly as Burt's own investment-proportion
formula, with no separate binary mode at all.

{phang2}
{bf:2. Optional, explicit toggle (W2)} - a command supports both a binary and a weighted
formulation, selected by an option rather than assumed from the network's own valued/unvalued
status. {help nwclustering}/{help nwcommunity}/{help nwconcor}/{help nw2clustering}'s own
{opt measure(binary|valued)} is the recurring convention here (usually defaulting to whichever
matches the loaded network, documented explicitly in each command's own help file, never silently
picked).

{phang2}
{bf:3. Binary-only, documented (W3)} - the command has a single, dichotomized formulation and
says so plainly (e.g. {help nwtriads}' triad census, {help nwclique}'s clique membership,
{help nwcomponents}' weak-connectivity components) - not a gap, since no standard weighted
generalization of the underlying concept exists in the literature, but worth checking a command's
own help file before assuming tie strength is being used.

{pstd}
A tie value of exactly 0 and "no tie at all" are treated identically almost everywhere in this
package (both mean "not connected") - a network with meaningful zero-valued ties distinct from
missing ones needs a workaround (e.g. a small constant offset) rather than being handled natively.
{bf:Negative (signed) tie values} are a separate, much less consistently supported dimension - most
commands' own "Signed" field in their {bf:Supported network types} section reads "not checked" or
"not supported", meaning a negative weight is not distinguished from an unusually low positive one
in most formulas (an explicit exception: {help nwbalance}, which exists specifically to classify
triads by tie sign). Checking a specific command's own {bf:Signed} field before relying on negative
ties is worth doing explicitly - do not assume support carries over from a command's own weighted
(W1/W2) status.

{pstd}
{help nwsummarize} reports whether a loaded network is valued directly:

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwsummarize flomarriage}

{title:Reading a "Supported network types" section}

{pstd}
Each section answers five questions for that command, in this fixed order: {bf:Binary} (does an
unweighted 0/1 network work), {bf:Directed} (does an asymmetric network work, and if so is
symmetrization required or automatic), {bf:Weighted} (does tie strength enter the calculation, or
is it ignored/dichotomized), {bf:Signed} (are negative tie values handled distinctly from "no tie",
or silently treated the same), and {bf:Two-mode} (does the command work on bipartite data directly,
use its two-mode form by default, or not apply). "Not applicable" is used, not silently omitted,
for commands with no network-type-dependent behavior at all (e.g. purely structural commands like
{help nwrename}).

{title:Examples}

{pstd}
{help nwsummarize} reports a loaded network's own classification along these same dimensions:

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwsummarize flomarriage}

{title:Source-verified classifications}

{pstd}
A small set of commands - the ones most central to network analysis, where getting the weighted/
directed/signed handling exactly right matters most - have been independently re-derived from
source code (not just summarized from their own help text), each backed by a quoted line of code
and, where relevant, a documented bug found and fixed along the way, using a classification key
of {bf:W1}-{bf:W5} for weighted support and {bf:T1}-{bf:T5} for two-mode support.

{title:See also}

{help nwintro}, {help nwtopical}, {help nw2set:introduction to two-mode networks}

{hline}
{pstd}{it:nwcommands version 3.12.2, 31 October 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
