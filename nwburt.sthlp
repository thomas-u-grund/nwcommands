{smcl}
{* *! version 2.1.0  25oct2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_positions:[NW-2.6.4] Positions, Roles & Equivalence}

{title:Title}

{p2colset 9 17 23 2}{...}
{p2col :nwburt {hline 2}}Calculate Burt structural hole measures{p_end}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:nwburt} [{it:{help netname}}] [, {bf:binary dyadredundancy dyadconstraint replace silent}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt binary}}Valued network: ignore the tie values; every positive value is a tie{p_end}
{synopt:{opt dyadredundancy}}Save dyadic redundancy as new network{p_end}
{synopt:{opt dyadconstraint}}Save dyadic constraint as new network{p_end}
{synopt:{opt replace}}Replace existing {it:_effsize}/{it:_efficiency}/{it:_constraint}/{it:_hierarchy} variables{p_end}
{synopt:{opt silent}}Suppress summary output{p_end}

{title:Description}

{pstd}
This command calculates Burt's (1992) effective size, efficiency, constraint and hierarchy. All these
measures are used to identify structural holes. They all build on the idea of redundancy. A network
tie between ego and j is redundant, when ego is also connected to q and q is connected to j, i.e. that means ego can
reach j via q instead of directly connecting to j. The level of redundancy of the tie between ego and j
is based on the total number of ties ego has.

{pstd}
For a {bf:valued} network (a network that was created with tie values, see {help nwnetworktypes}) the measures are Burt's (1992) weighted measures, as in {cmd:igraph::constraint(weights=)} of R (igraph) and
{cmd:effective_size(weight=)} and {cmd:constraint(weight=)} of NetworkX: the strength of the relation between {it:i} and {it:j}
is the sum of both directions, {it:a_ij} = {it:z_ij} + {it:z_ji} (for an undirected network this only doubles every
value and changes no result), and the formulas below are applied to these strengths. With the option {opt binary} the
tie values are ignored: every positive value counts as a tie of value 1. A network that is not valued is computed as before
(the option has no effect).

{pstd}
The dyadic redundancy measure calculates, for each actor in ego's neighborhood, how many of the other actors in the neighborhood are also tied to the other.  The larger the proportion of others in the neighborhood who are tied to a given "alter," the more "redundant" is ego's direct tie.

{pstd}
Dyadic constraint is a measure that indexes the extent to which the relationship between ego and each of the alters in ego's neighborhood "constrains" ego.  A full description is given in Burt's 1992 monograph, and the construction of the measure is somewhat complex.  At the core though, A is constrained by its relationship with B to the extent that A does not have many alternatives (has few other ties except that to B), and A's other alternatives are also tied to B.  If A has few alternatives to exchanging with B, and if those alternative exchange partners are also tied to B, then B is likely to constrain A's behavior.

{bf:{ul:1. Effective size}}

{pstd}
Conceptually the effective size is the number of people ego is connected to, minus the
redundancy in the network, that is, it reduces to the non-redundant elements of the
network. Another definition of effective size of the network is the number of alters that ego has, minus the average
number of ties that each alter has to other alters (see Borgatti 1997). Suppose that A has ties to three other actors.  Suppose that none of these three has ties to any of the others.  The effective size of ego's network is three.  Alternatively, suppose that A has ties to three others, and that all of the others are tied to one another.  A's network size is three, but the ties are "redundant" because A can reach all three neighbors by reaching any one of them.  The average degree of the others in this case is 2 (each alter is tied to two other alters).  So, the effective size of the network is its actual size (3), reduced by its redundancy (2), to yield an effective size of 1. It is
defined as:

{pstd}
EffSize_i = sum_over_j[ 1 - sum_over_q( p_iq * m_jq ) ]

{pstd}
Where j runs over the contacts of i and q over the contacts of i other than j. p_iq = a_iq / sum_over_k[ a_ik ] is the proportion of actor i's relations that are spent with q,
with a_ij = z_ij + z_ji the strength of the relation between i and j (z_ij is the value of the tie from i to j).

{pstd}
Furthermore, m_jq is the marginal strength of contact j's relation with contact q. Which is j's interaction with q divided by j's strongest interaction with anyone,
m_jq = a_jq / max_over_k[ a_jk ].
For a binary network, the strongest link is always 1 and thus m_jq reduces to 0 or 1 (whether j is connected to q or not - that is, the adjacency matrix).
In a valued network ES lies between 1 and the number of contacts for every node with contacts.

{pstd}
The sum of the product p_iq * m_jq measures the portion of i's relation with j that is redundant to i's relation with other primary contacts.


{bf:{ul:2. Efficiency}}

{pstd}
Efficiency is the effective size divided by the number of contacts of ego (the number of nodes with a tie to or from ego), ES_i / k_i. Efficiency norms the effective size of ego's network by its actual size.  That is, what proportion of ego's ties to its neighborhood are "non-redundant."  The effective size of ego's network may tell us something about ego's total impact; efficiency tells us how much impact ego is getting for each unit invested in using ties.  An actor can be effective without being efficient; and an actor can be efficient without being effective.

{bf:{ul:3. Constraint}}

{pstd}
Conceptually, constraint refers to how much room you have to negotiate or exploit potential structural holes in your
network. Constraint is a summary measure that taps the extent to which ego's connections are to others who are connected to one another.  If ego's potential trading partners all have one another as potential trading partners, ego is highly constrained.  If ego's partners do not have other alternatives in the neighborhood, they cannot constrain ego's behavior.  The logic is pretty simple, but the measure itself is not.  It would be good to take a look at Burt's 1992 Structural Holes.  The idea of constraint is an important one because it points out that actors who have many ties to others may actually lose freedom of action rather than gain it -- depending on the relationships among the other actors.

{pstd}
C_i = sum_over_j[ ( p_ij + sum_over_q( p_iq * p_qj ) )^2 ], with j over the contacts of i and q over the contacts of i other than j.
Contacts of i that are not tied to i do not enter the sum (the sum of {help nwconstraint} over a row differs for this reason).

{pstd}
"..opportunities are constrained to the extent that (a) another of your contacts q, in whom you have invested a large portion of your network time and energy, has (b) invested heavily in a relationship with contact j." (Burt 1992, p.54)

{bf:{ul:4. Hierarchy}}

{pstd}
Hierarchy is another quite complex measure that describes the nature of the constraint on ego.  If the total constraint on ego is concentrated in a single other actor, the hierarchy measure will have a higher value.  If the constraint results more equally from multiple actors in ego's neighborhood, hierarchy will be less.  With c_ij the term of contact j in C_i and k_i the number of contacts, H_i = sum_over_j[ (c_ij / (C_i/k_i)) * ln(c_ij / (C_i/k_i)) ] / (k_i * ln k_i). The command returns 1 for a node with one contact (where the formula is 0/0) and missing for a node without contacts. The hierarchy measure, in itself, does not assess the degree of constraint.  But, among whatever constraint there is on ego, it measures the important property of dependency -- inequality in the distribution of constraints on ego across the alters in its neighborhood.

{pstd}
The four per-node measures are computed from the stored ties (the sum of the squared degrees of the nodes decides the
work), so the command also runs on large networks (see {bf:Limits}). The weighted measures of a valued network are computed in the compiled plugin only (plugin generation 9, {cmd:nwcommands} 3.6.0 or later); without it the command stops with an error and the option {opt binary}
needs the plugin for a valued network too. The options {opt dyadredundancy} and
{opt dyadconstraint} (defined for ties that are present or absent: they need the option {opt binary} for a valued network) build the full {it:n}-by-{it:n} dyadic networks from the adjacency matrix (via {help nwtomata}), as
{help nwsimilar}, {help nwdissimilar} and {help nwqap} do, and are practical only for moderate network sizes.

{title:Stored results}

	Scalars
	  {bf:r(nodes)}		number of nodes
	  {bf:r(weighted)}	1 if the weighted measures of a valued network were computed, 0 otherwise


{title:Supported network types}

{pstd}
Binary: yes. Valued: yes, weighted (Burt 1992, see above); the option {opt binary} ignores the values. Directed: a directed {it:valued} network is
symmetrized as in Burt, igraph and NetworkX (the strength of a relation is {it:z_ij} + {it:z_ji}). A directed network that is not valued is
{it:not} symmetrized: {it:p_ij} (the proportion of {it:i}'s outgoing investment in {it:j}) is computed from the outgoing ties exactly as given, the
convention of {help nwconstraint} (igraph and NetworkX use both directions, so their values differ for such networks; symmetrize first with
{help nwsym} to compare, or use {opt binary} on a valued network). Signed (negative values) and missing values: not supported, the command stops with an error. Two-mode: same as for the bipartite graph read as a one-mode network (valid; no mode-specific normalisation).

{pstd}
Before version 3.6.0 the values of a valued network were inserted into the formulas of a binary network without
the normalisations above; effective size could be negative and efficiency below 0. Results for valued networks differ from
those of earlier versions; use {opt binary} for the unvalued measures.


{title:Limits}

{pstd}
The four measures are computed from the stored ties, in the compiled graph plugin (the native kernel of {cmd:nwcommands}) when the plugin of your
platform has it and in Mata otherwise; both give the same values (to the last digits). The work grows with the sum of the squared degrees,
not with {it:n}^3. Measured in Stata/BE, random undirected network with mean degree 10: 5,000 nodes 0.03 seconds, 20,000 nodes 0.05 seconds,
100,000 nodes 0.2 seconds (the Mata route needs 1.2, 4.4 and 26 seconds). The options {opt dyadredundancy} and {opt dyadconstraint} build
{it:n}-by-{it:n} networks and take the dense route.
{pstd}
For all commands at network sizes of 1,000 to 100,000 nodes see the web page {browse "https://nwcommands.org/nwcommands/size-limits/":How large a network can I analyze?}

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwburt flobusiness}

{pstd}
A valued network (weighted measures), and the same network with the values ignored:

	{cmd:. nwwebuse gang, nwclear}
	{cmd:. nwburt gang_valued, replace}
	{cmd:. nwburt gang_valued, binary replace}

{title:References}

{pstd}
The weighted measures agree to 1e-10 with {cmd:igraph::constraint(graph, weights=)} of the R package igraph (constraint) and with
{cmd:networkx.effective_size}/{cmd:networkx.constraint} of NetworkX (effective size, constraint), and for unvalued undirected networks with
{cmd:influenceR::ens} of the R package influenceR. {cmd:influenceR::constraint} also sums over nodes that are reached
only through a contact and are not themselves contacts of ego, and differs from Burt's definition and from {cmd:nwburt} for that reason; the R packages igraph and
influenceR give a missing value (NaN) for a node without ties where {cmd:nwburt} gives 0.

{pstd}
Borgatti, S. (1997). Structural holes: Unpacking Burt's redundancy measures. {it:Connections} 20(1),
35-38.

{pstd}
Burt, R. S. (1992). {it:Structural Holes: The Social Structure of Competition}. Cambridge: Harvard
University Press.

{title:See also}

	{help nwconstraint}, {help nwbridges}

last certified : 24 Aug 2026

{hline}
{pstd}{it:nwcommands version 3.12.1, 28 October 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
