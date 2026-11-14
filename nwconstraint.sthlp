{smcl}
{* *! version 1.0.0  21aug2026}{...}
{marker topic}
{helpb nwtopical##analysis_positions:[NW-2.6.4] Positions, roles and similarity}

{title:Title}

{p2colset 9 22 26 2}{...}
{p2col :nwconstraint  {hline 2}}Burt's constraint{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwconstraint}
[{it:{help netname}}]
[{cmd:,}
{opth name(newnetname)}
{opt replace}
{it:{help nwset:nwset_options}}]

{pstd}
{opt name()} names the new network and {opt replace} overwrites an existing network of that name. The
other {it:nwset_options} are any options accepted by {help nwset}'s {opt mat()} form (e.g.
{opt undirected}, {opt directed}); they are forwarded unchanged to the internal
{cmd:nwset, mat()} call that stores the result.


{title:Description}

{pstd}
Calculates Burt's (1992) dyadic constraint for a {help netname:network} and stores the result as a
new {help netname:network} (not a Stata variable) via {cmd:nwset, mat()} - the constraint matrix
becomes the current network afterward. This is a different output shape than most other analysis
commands in this package (which {opt generate()} a per-node Stata variable): {cmd:nwconstraint}
returns the full dyadic {it:c_ij} matrix. {help nwburt} computes the standard per-node aggregate
constraint (and Burt's related effective size/efficiency/hierarchy measures) directly as Stata
variables - use it instead of this command if the dyadic matrix itself isn't what you need; see the
"Aggregating to the node level" note below for why a plain row sum of this command's own output is
{bf:not} equivalent to {help nwburt}'s aggregate.

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
The diagonal (self-constraint) is not meaningful and is not part of the returned network.

{pstd}
{bf:Aggregating to the node level}: the quantity most commonly reported in the literature as "Burt's
constraint" is node {it:i}'s aggregate constraint, {it:C_i = sum_j(c_ij)} for {it:j} in {it:i}'s
direct contacts only - {bf:not} summed over every {it:j}. This distinction matters
because {it:c_ij} can be nonzero even when {it:i} and {it:j} are not directly tied at all (the
{it:sum_q(p_iq*p_qj)} indirect term alone can make it positive), so naively summing an entire row of
this command's output - {it:sum_j(c_ij)} over {bf:all} {it:j} - silently over-counts and gives a
different, larger number than the standard aggregate for any node with such indirect-only
contributions. {help nwburt} computes the correctly-restricted aggregate directly (as {it:_constraint});
this command intentionally does not, since restricting the sum to {it:N(i)} requires already knowing
which entries of the raw network matrix are direct ties, which is exactly the extra step {help nwburt}
takes care of.


{title:Network types}

{pstd}
{bf:Directed:} not symmetrized - p_ij uses outgoing ties only, so a node without outgoing ties has zero constraint.
{bf:Valued:} tie values are used as Burt's investment proportions. {bf:Two-mode:} same as for the bipartite graph read
as a one-mode network. {bf:Signed:} not supported - negative values distort p_ij (values outside [0,1]). See
{help nwnetworktypes}.{p_end}


{title:Limits}

{pstd}
The result is a dense {it:n}-by-{it:n} network. 20,000 nodes: 9 seconds in Stata/BE.

{pstd}
Above 2,000 nodes a network held as stored ties gets its constraint network from the list of its cells that are not zero (the direct ties and the two-step paths, about the sum of the squared degrees),
without an {it:n}-by-{it:n} matrix; only {opt name()} and {opt replace} are accepted then. Measured in Stata/BE with 5 ties drawn per node (mean degree 10 when undirected) and 100,000 nodes: 0.7
seconds for a directed network and 2.2 seconds for an undirected one (11 million cells).{p_end}
{pstd}
For all commands at network sizes of 1,000 to 100,000 nodes see the web page {browse "https://nwcommands.org/nwcommands/size-limits/":How large a network can I analyze?}

{pstd}
The cells are computed in the compiled graph plugin (the native kernel of {cmd:nwcommands}) when the plugin of your platform has it, and in Mata otherwise;
both give the same values (to the last digits). The kernel itself takes about one second at 100,000 nodes with mean degree 10; the rest of the time of a large network
(1 second in Stata/BE for an undirected network) goes into storing the result as a network.


{title:Examples}

	{cmd:. nwwebuse gang, nwclear}
	{cmd:. nwconstraint gang, name(gangconstraint)}
	{cmd:. nwtomata gangconstraint, mat(C)}
	{cmd:. nwtomata gang, mat(A)}
	{cmd:. mata: rowsum(C :* (A :!= 0 :& A :< .))}


{title:References}

{pstd}
Ronald S. Burt (1992). {it:Structural Holes: The Social Structure of Competition}. Harvard University
Press.


{title:See also}

	{help nwburt}, {help nwdegree}, {help nwbetween}, {help nwcloseness}, {help nwevcent}, {help nwclustering}

{hline}
{pstd}{it:nwcommands version 3.25.0, 14 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
