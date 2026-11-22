{smcl}
{* *! version 1.1.0  02sep2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_clustering:[NW-2.6.5] Clustering, mixing and balance}

{title:Title}

{p2colset 9 24 26 2}{...}
{p2col :nwassortativity {hline 2}}Newman's assortativity coefficient{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2}
{cmdab: nwassortativity}
[{it:{help netname}}]
[{cmd:,}
{opt attribute(varname)}
{opt weighted}
{opt silent}
{opt binary}
{opt sym}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt attribute(varname)}}Numeric node attribute to correlate across ties; default = each node's own degree (its strength on a valued network unless {opt binary} is given){p_end}
{synopt:{opt weighted}}Weight the correlation by each tie's own strength (Leung and Chau 2007), instead of every tie counting equally{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}
{synopt:{opt binary}}Ignore the tie values of a valued network (by default they are used){p_end}
{synopt:{opt sym}}On a directed network, symmetrize first (the larger of the two directions of a tie) and compute the undirected coefficient{p_end}

{p2colreset}{...}


{title:Description}

{pstd}
{cmd:nwassortativity} computes Newman's (2002) assortativity coefficient: the Pearson correlation,
across every tie in the network, between the value of some quantity at one end of the tie and its
value at the other end. By default that quantity is each node's own degree ("degree assortativity"),
the most commonly reported form and the one Newman's own paper introduces the measure with; passing
{opt attribute()} instead correlates any other numeric node attribute across ties ("attribute
assortativity" - e.g. wealth, age, a status score).

{pstd}
A positive coefficient means nodes tend to be tied to others with a similar value (e.g. high-degree
nodes tend to connect to other high-degree nodes) - the network is "assortative". A negative
coefficient means the opposite: nodes tend to be tied to others with a dissimilar value (e.g.
high-degree "hubs" connecting mostly to low-degree nodes) - the network is "disassortative". A
coefficient near zero means no such pattern.

{pstd}
Formally, for every tie {it:(i,j)}, {it:x} is the attribute value at {it:i} and {it:y} the value at
{it:j}; the coefficient is the ordinary Pearson correlation of {it:x} and {it:y} across the ties. On an
undirected network every tie is counted in both directions (so the result does not depend on which end of
a tie is labeled {it:i} vs {it:j}), which is Newman's (2002) {it:r}. On a directed network every tie is
one pair, {it:x} taken at the sender and {it:y} at the receiver (Newman 2003, the directed {it:r} of
{cmd:igraph::assortativity(directed = TRUE)}): by default the degree of the sender is its out-degree
and the degree of the receiver is its in-degree (out-strength and in-strength on a valued network), and
with {opt attribute()} the same attribute is read at both ends. Option {opt sym} gives the undirected
coefficient of the symmetrized network instead (a tie counts in both directions with the larger of its
two values). The output says whether the network was analysed as directed, undirected or symmetrized.

{pstd}
Social networks are frequently found to be assortative by degree (popular people know other popular
people); many biological and technological networks (e.g. the internet's own router-level topology)
are disassortative instead (a few high-degree hubs connect to many low-degree peripheral nodes).

{pstd}
{opt weighted} computes Leung and Chau's (2007) weighted extension instead: the same {it:(x,y)} pairs
above, but correlated with each pair {it:weighted by its own tie's strength}, so a strong tie
contributes more to the coefficient than a weak one - not a different pair construction, only a
different (weighted Pearson) correlation of the identical pairs the unweighted case already builds.
On a binary (unweighted) network every present tie has weight 1, so {opt weighted} gives exactly the
same coefficient as omitting it - not an approximation.

{pstd}
A network with fewer than 2 ties, or one where the attribute (degree, by default) is constant across
every tied pair, has an undefined (zero-variance) correlation and returns {bf:r(assortativity)} as
missing rather than a spurious value.


{title:Network types}

{pstd}
{bf:Directed:} analysed as it is (sender against receiver); {opt sym} symmetrizes first, and the output says which. {bf:Valued:} without {opt attribute()} the node attribute is the strength instead of the
degree ({opt binary} uses the degree); {opt weighted} also weights each tie by its value (Leung and Chau 2007).
{bf:Two-mode:} same as for the bipartite graph read as a one-mode network (the degree assortativity is negative by
construction). {bf:Signed:} negative values would distort the weighted correlation. See {help nwnetworktypes}.{p_end}


{title:Examples}

	{cmd:. nwwebuse glasgow, nwclear}
	{cmd:. nwassortativity glasgow1}

	{cmd:. nwassortativity glasgow1, attribute(sport1)}

	{cmd:. nwassortativity glasgow1, weighted}


{title:Stored results}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{bf:r(assortativity)}}the coefficient itself, in {it:[-1,1]}{p_end}
{synopt:{bf:r(ties)}}number of ties the coefficient was computed over (arcs of a directed network, unordered pairs of an undirected or symmetrized network){p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{bf:r(name)}}name of the network{p_end}
{synopt:{bf:r(attribute)}}attribute used (or "degree" or "strength" for the default){p_end}
{synopt:{bf:r(directed)}}{bf:"true"} for a directed network analysed as it is, {bf:"symmetrized"} with {opt sym}, {bf:"false"} for an undirected network{p_end}
{synopt:{bf:r(weighted)}}{bf:"true"} if {opt weighted} was specified, {bf:"false"} otherwise{p_end}


{title:References}

{pstd}
Newman, M. E. J. (2002). Assortative mixing in networks. {it:Physical Review Letters}, 89(20), 208701.

{pstd}
Leung, C.C., Chau, H.F. (2007). Weighted assortative and disassortative networks model. {it:Physica}
{it:A} 378(2), 591-602. ({opt weighted}'s own extension)


{title:See also}

	{help nwdegree}, {help nwclustering}, {help nwmixing}, {help nwcorrelate}

{hline}
{pstd}{it:nwcommands version 3.34.0, 21 November 2026} ({help nwversion:check your installed version}){p_end}{* nwversion}
