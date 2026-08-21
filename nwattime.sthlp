{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##manipulation:[NW-2.5] Manipulation}

{title:Title}

{p2colset 9 20 22 2}{...}
{p2col :nwattime {hline 2} Static graph view of a temporal network at a given time}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwattime}
[{it:{help netname}}]
{cmd:,}
{opt at(#)}
[{opth name(newnetname)}
{opt xvars}
{opt replace}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt at(#)}}The timepoint to slice at{p_end}
{synopt:{opth name(newnetname)}}Name of the new static network; default = {it:atview}{p_end}
{synopt:{opt xvars}}Do not generate Stata variables for the new network{p_end}
{synopt:{opt replace}}Replace an existing network of the same name{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwattime} takes a temporal network (declared via {help nwset}'s {bf:time()}, {bf:interval()}, or
{bf:eventtime()} options) and produces an ordinary, static one-mode network containing only the ties
active at the requested timepoint - the "temporal network -> select edges active at t -> static graph
view -> ordinary nw algorithm" model: the resulting network is a completely normal network, usable with
any existing {bf:nw*} command exactly as if it had never been temporal at all. This is deliberate
groundwork, not a full temporal-network modelling system - see {help nwset##temporal:nwset}'s own
temporal section for what is and is not supported yet.

{pstd}
The slicing rule depends on the source network's own temporal semantics:

{p 8 12 2}{bf:snapshot}{p_end}
{p 12 12 2}a tie is active at {it:t} when its own recorded time equals {it:t} exactly{p_end}
{p 8 12 2}{bf:interval}{p_end}
{p 12 12 2}a tie is active at {it:t} when {it:start} <= {it:t} < {it:end} - the documented convention.
A tie with a missing {it:end} (an ongoing tie with no recorded end date) is treated as open-ended
and stays active for every {it:t} from its {it:start} onward. A missing {it:start} is not specially
handled and excludes the tie{p_end}
{p 8 12 2}{bf:event}{p_end}
{p 12 12 2}an exact-timestamp match: every event recorded at precisely {it:t} becomes a binary tie in
the static view. This is the one place an event network is allowed to become a persistent graph in
this package, and only because {it:t} was explicitly requested - no windowing or aggregation across a
range of timestamps is done (not yet supported){p_end}

{pstd}
For example, a network declared with {cmd:nwset ego alter, time(wave)} can be sliced to the ties that
existed in wave 2:

	{cmd:. nwattime mynet, at(2) name(wave2)}

{title:Stored results}

	Scalars
	  {bf:r(ties)}		number of ties in the static view
	  {bf:r(at)}		the timepoint sliced at


{title:Supported network types}

{pstd}
Binary: yes. Directed: preserved from the source network. Weighted: preserved from the source network's
own tie values (the slice selects which ties are active, it does not change their values). Signed: not
checked. Two-mode: not yet supported as a source (see {help nwset}'s own note that {bf:time()}/
{bf:interval()}/{bf:eventtime()} cannot currently be combined with {bf:twomode}/{bf:bipartite} - tracked
in docs/ROADMAP.md as a composability item for a later pass).


{title:See also}

	{help nwset}, {help nwsummarize}

last certified : 21 Aug 2026
