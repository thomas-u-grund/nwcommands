{smcl}
{* *! version 1.1.0  02sep2026}{...}
{marker topic}
{helpb nw_topical##utilities:[NW-2.7] Utilities}

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
binary-only default (e.g. {help nwclustering}); some are only meaningful for one-mode data and
redirect automatically to a {cmd:nw2*} counterpart when given a two-mode network (e.g.
{help nwdegree} redirecting to {help nw2degree}); a few are simply not implemented for a
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

{title:Two-mode networks and the nw2* family}

{pstd}
{cmd:nwcommands} detects whether a network is two-mode automatically (set via {help nw2set} or
produced by a two-mode-native generator/import) - ordinary commands do not need a special flag to
tell them a network is bipartite. A handful of commands (the {cmd:nw2*}-prefixed family, e.g.
{help nw2degree}, {help nw2project}, {help nw2clustering}) exist because the underlying
{it:statistic itself} is genuinely different for bipartite data (e.g. two-mode degree only makes
sense counting ties to the opposite mode; a one-mode "clustering coefficient" has no direct
bipartite analogue and needs its own definition), not because the package needs a separate command
just to recognize the network type. Where a one-mode command's statistic degrades gracefully or
redirects cleanly (e.g. {help nwdegree} on a two-mode network), it does so automatically and says so
in its own {bf:Supported network types} section rather than raising an error.

{title:Weighted (valued) networks}

{pstd}
A network is {it:valued} (weighted) when its ties carry a real number, not just presence/absence -
set automatically whenever {help nwset}, {help nwfromedge}, or an import command is given tie
values other than a plain 0/1 indicator, and readable via {help nwsummarize}/{help nwname}'s own
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
redirect to a {cmd:nw2*} counterpart, or not apply). "Not applicable" is used, not silently omitted,
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

{help nwintro}, {help nw_topical}, {help nw2set:introduction to two-mode networks}
