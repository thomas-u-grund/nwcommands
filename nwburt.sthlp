{smcl}
{* *! version 2.0.0  21aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis:[NW-2.6] Analysis}

{title:Title}

{p2colset 9 17 23 2}{...}
{p2col :nwburt {hline 2} Calculate Burt structural hole measures}
{p2colreset}{...}

{marker syntax}{...}
{title:Syntax}

{p 8 15 2}
{cmd:nwburt} [{it:{help netname}}] [, {bf:dyadredundancy dyadconstraint replace silent}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
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
Where, p_iq = y_iq / sum_over_j[ y_ij ] is the proportion of actor i's relations that are spent with q.

{pstd}
Furthermore, m_jq is the marginal strength of contact j's relation with contact q. Which is j's interaction with q divided by j's strongest interaction with anyone.
For a binary network, the strongest link is always 1 and thus m_jq reduces to 0 or 1 (whether j is connected to q or not - that is, the adjacency matrix).

{pstd}
The sum of the product p_iq * m_jq measures the portion of i's relation with j that is redundant to i's relation with other primary contacts.


{bf:{ul:2. Efficiency}}

{pstd}
Efficiency norms the effective size of ego's network by its actual size.  That is, what proportion of ego's ties to its neighborhood are "non-redundant."  The effective size of ego's network may tell us something about ego's total impact; efficiency tells us how much impact ego is getting for each unit invested in using ties.  An actor can be effective without being efficient; and an actor can be efficient without being effective.

{bf:{ul:3. Constraint}}

{pstd}
Conceptually, constraint refers to how much room you have to negotiate or exploit potential structural holes in your
network. Constraint is a summary measure that taps the extent to which ego's connections are to others who are connected to one another.  If ego's potential trading partners all have one another as potential trading partners, ego is highly constrained.  If ego's partners do not have other alternatives in the neighborhood, they cannot constrain ego's behavior.  The logic is pretty simple, but the measure itself is not.  It would be good to take a look at Burt's 1992 Structural Holes.  The idea of constraint is an important one because it points out that actors who have many ties to others may actually lose freedom of action rather than gain it -- depending on the relationships among the other actors.

{pstd}
"..opportunities are constrained to the extent that (a) another of your contacts q, in whom you have invested a large portion of your network time and energy, has (b) invested heavily in a relationship with contact j." (Burt 1992, p.54)

{bf:{ul:4. Hierarchy}}

{pstd}
Hierarchy is another quite complex measure that describes the nature of the constraint on ego.  If the total constraint on ego is concentrated in a single other actor, the hierarchy measure will have a higher value.  If the constraint results more equally from multiple actors in ego's neighborhood, hierarchy will be less.  The hierarchy measure, in itself, does not assess the degree of constraint.  But, among whatever constraint there is on ego, it measures the important property of dependency -- inequality in the distribution of constraints on ego across the alters in its neighborhood.

{pstd}
This command operates on the full adjacency matrix (via {help nwtomata}) rather than the sparse
network index, because the underlying formulas require genuine matrix products (two-step reach via
every intermediary) rather than single-neighbor lookups - the same reason {help nwsimilar},
{help nwdissimilar}, and {help nwqap} are also matrix-based. This is not expected to be practical on
very large networks; see the sparse-backend documentation for detail on which nwcommands are, and are
not yet, sparse-scalable.

{title:Stored results}

	Scalars
	  {bf:r(nodes)}		number of nodes


{title:References}

{pstd}
Borgatti, S. 1997. Structural Holes: Unpacking Burt's Redundancy Measures. Connections 20(1): 35-38.

{pstd}
Burt, R. S. 1992. Structural Holes: The social structure of competition. Cambridge: Harvard University Press.

{title:See also}

	{help nwconstraint}, {help nwbridges}

last certified : 21 Aug 2026
