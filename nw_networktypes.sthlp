{smcl}
{* *! version 1.0.0  24aug2026}{...}
{marker topic}
{helpb nw_topical##utilities:[NW-2.7] Utilities}

{title:Title}

{p2colset 9 22 24 2}{...}
{p2col :nw_networktypes {hline 2}}How commands classify binary/directed/weighted/signed/two-mode networks{p_end}
{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwcommands} networks can be binary or valued (weighted), undirected or directed, and one-mode
or two-mode (bipartite) - see {help nw_intro} for the underlying data model. No single command
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

{title:Source-verified classifications}

{pstd}
A small set of commands - the ones most central to network analysis, where getting the weighted/
directed/signed handling exactly right matters most - have been independently re-derived from
source code (not just summarized from their own help text), each backed by a quoted line of code
and, where relevant, a documented bug found and fixed along the way, using a classification key
of {bf:W1}-{bf:W5} for weighted support and {bf:T1}-{bf:T5} for two-mode support.

{title:See also}

{help nw_intro}, {help nw_topical}, {help nw2set:introduction to two-mode networks}
