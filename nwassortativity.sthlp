{smcl}
{* *! version 1.1.0  02sep2026 author: Thomas Grund}{...}
{marker topic}
{helpb nwtopical##analysis_positions:[NW-2.6.4] Positions, Roles & Equivalence}

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
{opt silent}]


{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opt attribute(varname)}}Numeric node attribute to correlate across ties; default = each node's own degree{p_end}
{synopt:{opt weighted}}Weight the correlation by each tie's own strength (Leung and Chau 2007), instead of every tie counting equally{p_end}
{synopt:{opt silent}}Suppress display of results{p_end}

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
{it:j}; the coefficient is the ordinary Pearson correlation of {it:x} and {it:y} across every tie,
counted in both directions (so the result does not depend on which end of a tie is labeled {it:i} vs
{it:j}). This is exactly Newman's (2002) own {it:r} for the undirected case, and is computed here the
same symmetrized way for directed input too - a tie assortativity measure has no natural directed
generalization the same way ordinary clustering/clique measures do not (see {help nwclustering}'s
own identical reasoning), so a directed network's ties are treated as connections in either
direction, matching this package's own established convention elsewhere (e.g. {help nwtriads},
{help nwclique}).

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


{title:Examples}

	{cmd:. nwwebuse glasgow, nwclear}
	{cmd:. nwassortativity glasgow1}

	{cmd:. nwassortativity glasgow1, attribute(sport1)}

	{cmd:. nwassortativity glasgow1, weighted}


{title:Stored results}

	Scalars:
	  {bf:r(assortativity)}  the coefficient itself, in {it:[-1,1]}
	  {bf:r(ties)}           number of ties the coefficient was computed over (undirected count)

	Macros:
	  {bf:r(name)}           name of the network
	  {bf:r(attribute)}      attribute used (or "degree" for the default)
	  {bf:r(weighted)}       {bf:"true"} if {opt weighted} was specified, {bf:"false"} otherwise


{title:Supported network types}

{pstd}
Binary: yes. Directed: yes, symmetrized (treated as connected in either direction - see above, same
reasoning as {help nwclustering}/{help nwclique}). Weighted: {bf:W2} (added 2026-09-02, closing a
self-flagged "not used" gap) - the default correlates presence/absence pairs only, matching Newman's
own original definition; {opt weighted} (Leung and Chau 2007) is an explicit opt-in that weights the
same pairs by tie strength instead. Signed: not checked - a negative tie weight would distort the
weighted correlation's own denominators, not handled distinctly. Two-mode: not checked - operates
on the network's own stored ties directly.

{pstd}
A network with fewer than 2 ties, or one where the attribute (degree, by default) is constant across
every tied pair, has an undefined (zero-variance) correlation and returns {bf:r(assortativity)} as
missing rather than a spurious value - the same convention this package uses elsewhere for
degree-undefined cases (e.g. {help nwclustering}).


{title:References}

{pstd}
Newman, M. E. J. (2002). Assortative mixing in networks. {it:Physical Review Letters}, 89(20), 208701.

{pstd}
Leung, C.C., Chau, H.F. (2007). Weighted assortative and disassortative networks model. {it:Physica
A} 378(2), 591-602. ({opt weighted}'s own extension)


{title:See also}

	{help nwdegree}, {help nwclustering}, {help nwmixing}, {help nwcorrelate}

