{smcl}
{* *! version 1.0.0  21aug2026}{...}
{marker topic}
{helpb nw_topical##analysis:[NW-2.6] Analysis}

{title:Title}

{p2colset 9 22 26 2}{...}
{p2col :nwconstraint  {hline 2} Calculate Burt's constraint}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwconstraint}
[{it:{help netname}}]
[{cmd:,}
{it:{help nwset:nwset_options}}]

{pstd}
where {it:nwset_options} are any options accepted by {help nwset}'s {opt mat()} form (e.g.
{opt name()}, {opt undirected}, {opt directed}) - they are forwarded unchanged to the internal
{cmd:nwset, mat()} call that stores the result.


{title:Description}

{pstd}
Calculates Burt's (1992) dyadic constraint for a {help netname:network} and stores the result as a
new {help netname:network} (not a Stata variable) via {cmd:nwset, mat()} - the constraint matrix
becomes the current network afterward. This is a different output shape than most other analysis
commands in this package (which {opt generate()} a per-node Stata variable): {cmd:nwconstraint}
returns the full dyadic {it:c_ij} matrix, from which a node's aggregate constraint can be obtained
with a row sum (e.g. via {help nwtomata} or {help nwvalue}).

{pstd}
Constraint measures the extent to which a node {it:i}'s relationships are concentrated through a
single contact or a tightly interconnected group of contacts, rather than spread across independent,
unconnected contacts (the latter is Burt's "structural holes" - low constraint, high brokerage
potential). Formally, for each pair {it:i,j}:

{pmore}
{it:p_ij = a_ij / sum_k(a_ik)}  (i's tie to j, as a proportion of all of i's outgoing ties)

{pmore}
{it:c_ij = (p_ij + sum_q(p_iq * p_qj))^2}  (direct investment in j, plus indirect investment via
every other contact {it:q})

{pstd}
The diagonal (self-constraint) is not meaningful and is not part of the returned network. A node
{it:i}'s aggregate constraint (the quantity most commonly reported in the literature as "Burt's
constraint") is {it:sum_j(c_ij)}, i.e. the row sum for {it:i} in the returned network - not computed
automatically by this command.


{title:Examples}

	{cmd:. webnwuse gang, nwclear}
	{cmd:. nwconstraint gang, name(gangconstraint)}
	{cmd:. nwtomata gangconstraint, mat(C)}
	{cmd:. mata: rowsum(C)}


{title:Supported network types}

{pstd}
Binary: yes. Directed: yes, but not symmetrized - {it:p_ij} is computed from the raw adjacency matrix
exactly as given, so a directed network's constraint reflects outgoing ties only (a node with no
outgoing ties at all has {it:p} entirely zero, and therefore zero constraint toward everyone,
regardless of its incoming ties). This is a real, asymmetric treatment of directed data - not a
symmetrized "Burt" constraint in the traditional (undirected) sense - and is the command's actual
behavior, not silently assumed. Weighted: {bf:W1}, native - tie weight is used directly as {it:p_ij}'s
investment proportion (exactly Burt's own interpretation of tie strength), not as a distance. Signed:
not supported - {it:p_ij} is a ratio to a sum of outgoing tie weights, which is only mathematically
meaningful when all of a node's tie weights are non-negative; a negative tie included in the same
network as positive ties will distort every {it:p_ij} for that node (values can fall outside [0,1],
and {it:c_ij} can exceed 1) rather than being handled as a distinct signed relation. Two-mode: not
checked.


{title:References}

{pstd}
Ronald S. Burt (1992). {it:Structural Holes: The Social Structure of Competition}. Harvard University
Press.


{title:See also}

	{help nwdegree}, {help nwbetween}, {help nwcloseness}, {help nwevcent}, {help nwclustering}

last certified : 21 Aug 2026
