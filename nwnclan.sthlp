{smcl}
{* *! version 1.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_cohesion:[NW-2.6.2] Cohesion, Components & Subgroups}

{title:Title}

{p2colset 9 21 22 2}{...}
{p2col :nwnclan {hline 2}}Maximal n-clan enumeration{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwnclan}
[{it:{help netlist}}]
[{cmd:,}
{opth n(int)}
{opth generate(newvarname)}
{opt replace}
{opth minsize(int)}
{opt maxcliques(#)}
{opt maxtime(#)}
{opt countonly}
{opt nomatrix}
{opt silent}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth n(int)}}Maximum geodesic distance allowed between any two members; default = 2{p_end}
{synopt:{opth generate(newvarname)}}{bf:Required.} Name of the Stata variable that stores each node's largest maximal-n-clan membership size{p_end}
{synopt:{opt replace}}Replace existing variable{p_end}
{synopt:{opth minsize(int)}}Smallest n-clan size to report; default = 3{p_end}
{synopt:{opt maxcliques(#)}}Stop with an error when more than this many maximal n-cliques have to be examined while looking for n-clans; default = 1,000,000{p_end}
{synopt:{opt maxtime(#)}}Stop with an error when the search has run for this many seconds without finishing; default = 60{p_end}
{synopt:{opt countonly}}Only count the sets (and tabulate them by size) - nothing is stored, so the count is not limited by memory; {opth generate(newvarname)} is then not needed{p_end}
{synopt:{opt nomatrix}}Do not build the sets-by-nodes matrix; the {opth generate(newvarname)} variable and the count are still returned{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwnclan} enumerates every maximal n-clan (Mokken 1979) in the network(s) in {help netlist} - an
{help nwnclique:n-clique} (see that command for the base concept and {opth n(int)}) that additionally
requires every pair of its own members to be reachable from one another {it:while staying inside the group}, within {opth n(int)} steps. An ordinary n-clique only guarantees each pair's shortest path in
the {it:whole} network is within {opth n(int)} - that path may run through a node that is not itself
one of the n-clique's own members, a known limitation of the plain n-clique concept (Alba 1973).
n-clans fix exactly that: every member must be able to reach every other member using only paths that
never leave the group.

{pstd}
{cmd:nwnclan} works by first enumerating every maximal n-clique (the same computation
{help nwnclique} itself performs) and then keeping only the ones whose own induced subgraph - built
from the {it:original} network, restricted to just that n-clique's members - has every pair of
members within {opth n(int)} steps of {it:each other, using only ties between members}. This matches
the standard treatment of n-clans in the literature: a maximal n-clique that fails this check is
simply not reported as a clan at all, rather than being replaced with some smaller, clan-qualifying
subset of itself - a genuine, deliberate limitation of the concept, not a shortcut taken here. Every
n-clan is therefore also an n-clique, but not every n-clique is an n-clan; on a network with no
"shortcut" structure (e.g. a network where every node's shortest paths to everyone else already stay
within whatever locally-dense region it belongs to) the two coincide exactly.

{pstd}
Like n-cliques, n-clans genuinely overlap, so {cmd:nwnclan} follows {help nwnclique}'s own output
shape: a single per-node "largest maximal n-clan membership size" summary variable
({opth generate(newvarname)}, required), plus the complete overlapping structure in
{bf:r(nclan_matrix)} and {bf:r(nclans)}. {opth minsize(int)} defaults to 3, matching
{help nwclique}/{help nwnclique}.

{title:Stored results}

	Scalars
	  {bf:r(nclans)}		number of maximal n-clans found meeting {opth minsize(int)}
	  {bf:r(maxsize)}	size of the largest set (with {opt countonly} or {opt nomatrix})

	Matrices
	  {bf:r(size_table)}	(with {opt countonly} or {opt nomatrix}) sizes and the number of sets of each size
	  {bf:r(nclan_matrix)}	n-clans-by-nodes 0/1 membership matrix, one row per maximal n-clan (not with {opt countonly} or {opt nomatrix})

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwnclan flomarriage, generate(_nclannum)}
	{cmd:. nwnclan flomarriage, n(3) generate(_nclannum) replace}


{title:References}

{pstd}
Mokken, R.J. (1979). Cliques, clubs and clans. {it:Quality and Quantity} 13(2), 161-173.

{pstd}
Alba, R.D. (1973). A graph-theoretic definition of a sociometric clique. {it:Journal of Mathematical Sociology} 3(1), 113-126.

{pstd}
Wasserman, S., Faust, K. (1994). {it:Social Network Analysis: Methods and Applications}. Cambridge
University Press. (cliques and cohesive subgroups)


{title:Supported network types}

{pstd}
Binary: yes. Directed: yes, automatically symmetrized (same reasoning {help nwnclique} already
applies). Weighted: not used for membership. Signed: not checked. Two-mode: not checked. Inherits
{help nwnclique}'s own worst-case exponential enumeration cost, plus an additional per-candidate
induced-subgraph diameter check.

{title:Limits}

{pstd}
{bf:Feasible sizes.} The n-clans are the maximal n-cliques whose members are also within {it:n} steps of each other
inside the group. The search does not list all maximal n-cliques first: it drops a branch as soon as a member
already in the group is more than {it:n} steps from the newest member inside the group plus its remaining
candidates (distances only grow in the subsets a clan below the branch can be), which leaves the clans found, and
their order, unchanged. Measured in Stata/BE on a random network with 10 ties drawn per node and {opt n(2)}: 100 /
300 / 1,000 nodes take 0.006 / 2.0 / 1.8 seconds (no / 114 / 5,777 clans); at 5,000 nodes there are 165,097
clans, found in 2.5 seconds with {opt nomatrix}, but the clans-by-nodes matrix (165,097 x 5,000) is too large to build, which the
default says. The previous Mata version did not finish in 60 seconds at 100 nodes (6.6 GB) and was stopped at 20 GB at 1,000
nodes. Larger {opt n()} makes the "distance at most {it:n}" graph denser and the search much longer: at 1,000 nodes
and {opt n(3)} the search took 197 seconds (and found no clan), so the default limit of 60 seconds stops it.

{pstd}
{bf:Guards.} The command stops with r(484) and a message that names the option to raise when more than
{opt maxcliques()} maximal n-cliques (default 1,000,000) had to be examined, when the result matrix would be too
large to build (more than 50 million numbers; use {opt nomatrix}), or when the search has run for {opt maxtime()}
seconds (default 60). {opt countonly} counts and tabulates the clans by size without storing them.

{pstd}
For all commands at network sizes of 1,000 to 100,000 nodes see the web page {browse "https://nwcommands.org/nwcommands/size-limits/":How large a network can I analyze?}

{title:See also}

	{help nwnclique}, {help nwclique}, {help nwkplex}, {help nwkcomponents}, {help nwgeodesic}, {help nwkcore}

last certified : 24 Aug 2026

{hline}
{pstd}{it:nwcommands version 3.4.0, 25 October 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
