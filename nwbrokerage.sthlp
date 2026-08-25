{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_positions:[NW-2.6.4] Positions, Roles & Equivalence}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwbrokerage {hline 2}}Gould-Fernandez brokerage roles{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwbrokerage}
[{it:{help netlist}}]
{cmd:,}
{opth group(varname)}
[{opth generate(newvarname)}
{opt replace}
{opt silent}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth group(varname)}}Existing Stata variable holding each node's group membership (required){p_end}
{synopt:{opth generate(newvarname)}}Stem for the 5 new Stata variables that store role counts; default = {it:_broker}{p_end}
{synopt:{opt replace}}Replace existing variables{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwbrokerage} counts, for every node {it:b}, how often it plays each of the five brokerage
roles defined by Gould and Fernandez (1989). For every directed two-path {it:a -> b -> c} (with
{it:a} != {it:c}) through {it:b}, the role is determined by comparing the group membership of
{it:a}, {it:b} and {it:c} (from {opt group()}):

	{col 4}{bf:coordinator}{col 20}{it:a}, {it:b} and {it:c} all in the same group
	{col 4}{bf:gatekeeper}{col 20}{it:a} in a different group from {it:b}; {it:c} in the same group as {it:b}
	{col 4}{bf:representative}{col 20}{it:a} in the same group as {it:b}; {it:c} in a different group
	{col 4}{bf:consultant}{col 20}{it:a} and {it:c} in the same group, different from {it:b}'s
	{col 4}{bf:liaison}{col 20}{it:a}, {it:b} and {it:c} all in different groups

{pstd}
Five new Stata variables are generated, one per role, each holding node {it:b}'s count of that
role (e.g. the default {opt generate(_broker)} produces {it:_broker_coordinator},
{it:_broker_gatekeeper}, {it:_broker_representative}, {it:_broker_consultant} and
{it:_broker_liaison}).

{pstd}
For a directed network, {it:a} ranges over {it:b}'s incoming ties and {it:c} over its outgoing
ties - brokerage is fundamentally about {it:a} reaching {it:c} {it:through} {it:b}. For an
undirected network, incoming and outgoing ties are identical, so {it:a} and {it:c} both range over
{it:b}'s (undirected) neighbors - the same five-role classification still applies, just without the
directional distinction a directed network provides.

{title:Stored results}

	Scalars
	  {bf:r(pairs)}		total number of a-b-c two-paths counted, summed across all nodes and all five roles

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. gen faction = mod(_n, 2)}
	{cmd:. nwbrokerage flomarriage, group(faction)}


{title:References}

{pstd}
Gould, R.V., Fernandez, R.M. (1989). Structures of mediation: A formal approach to brokerage in
transaction networks. {it:Sociological Methodology} 19, 89-126.


{title:Supported network types}

{pstd}
Binary: yes. Directed: yes, and directionality is used directly (see Description) - this is the
network type the model was originally defined for. Undirected networks are supported too, with the
directional distinction collapsing away as described above. Weighted: not used - only the
presence/absence of a tie determines whether a two-path exists; tie strength does not affect role
counts. Signed: not checked. Two-mode: not checked - operates on the network's own square adjacency
matrix. {opt group()} must be an existing Stata variable already aligned with the network's nodes
(the same convention {help nwmodularity}'s own {opt group()} option uses) - {cmd:nwbrokerage} does
not detect groups itself; pair it with {help nwconcor}, {help nwcoreperiphery}, {help nwcommunity},
or a substantive attribute for the grouping.

{title:See also}

	{help nwconcor}, {help nwcoreperiphery}, {help nwcommunity}, {help nwmodularity}

last certified : 21 Aug 2026
