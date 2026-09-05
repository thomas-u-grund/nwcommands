{smcl}
{* *! version 1.0.0  31aug2026 author: Thomas Grund}{...}
{marker topic}
{helpb nw_topical##analysis_positions:[NW-2.6.4] Positions, Roles & Equivalence}

{title:Title}

{p2colset 9 18 22 2}{...}
{p2col :nwlambda {hline 2}}Edge (line) connectivity matrix between all node pairs{p_end}
{p2colreset}{...}

{title:Syntax}

{p 8 17 2}
{cmdab: nwlambda}
[{it:{help netname}}]
[{cmd:,}
{opth name(newnetname)}
{opt xvars}
{opt replace}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{synopt:{opth name(newnetname)}}Name of the new connectivity network; default = {it:lambda}{p_end}
{synopt:{opt xvars}}Generate Stata variables for the new network{p_end}
{synopt:{opt replace}}Replace an existing network of the same name{p_end}

{p2colreset}{...}

{title:Description}

{pstd}
{cmd:nwlambda} computes the EDGE (or "line") connectivity between every pair of nodes -
{it:lambda_ij}, the maximum number of edge-disjoint paths connecting {it:i} and {it:j}, equivalently
(by Menger's theorem's edge version) the size of the smallest set of ties whose removal would
disconnect them - and stores the result as a new, valued, undirected network {help newnetname}
(default: {it:lambda}). This is Borgatti, Everett & Shirey's (1990) own foundation for
{bf:lambda sets} (also called LS sets): a maximal subset of nodes where every pair inside has HIGHER
edge connectivity with each other than either one has with any node outside the set - a classical
cohesive-subgroup concept, and the edge-connectivity sibling of {help nwkcomponents}'s own
VERTEX-connectivity-based k-components.

{pstd}
Computed via a direct max-flow (Edmonds-Karp) between every pair of nodes on the network's own
symmetrized, binarized adjacency matrix - always undirected and binary, matching every other
classical cohesive-subgroup command in this package ({help nwclique}, {help nwkplex}, {help nwnclique}, {help nwkcomponents} all make the identical choice, since none of these concepts
has a standard directed/valued generalization in the literature). {it:lambda_ii} (self-comparison)
is undefined and stored as missing.

{marker lambdasets}{...}
{title:Extracting lambda sets}

{pstd}
{cmd:nwlambda} itself reports the raw connectivity matrix, not a discrete partition into lambda
sets - deliberately, since the extraction step is already exactly what {help nwhierarchy} does:
lambda sets are recoverable as SINGLE-LINKAGE hierarchical clustering on the lambda matrix (a real
graph-theoretic fact, not a heuristic: the Gomory-Hu tree of a graph represents every pairwise
min-cut/edge-connectivity value as a single tree, and cutting that tree at successive thresholds is
exactly single-linkage clustering on the full pairwise matrix). {help nwhierarchy} already accepts
an arbitrary dissimilarity network via its own {opt disnet()} option, so no new clustering code is
needed - only a similarity-to-dissimilarity flip (lambda is a SIMILARITY: higher means MORE
connected) and restoring a proper zero diagonal (a fresh network defaults to a missing, not zero,
diagonal - {opt set_selfloop(1)} is needed before writing a real 0 there):

{pstd}Worked example - two triangles {bf:A,B,C}/{bf:D,E,F} joined by a single bridge tie {bf:C-D}:

		{cmd:. nwset, mat((0,1,1,0,0,0\1,0,1,0,0,0\1,1,0,1,0,0\0,0,1,0,1,1\0,0,0,1,0,1\0,0,0,1,1,0)) name(bridge) labs(A,B,C,D,E,F)}
		{cmd:. nwlambda bridge, name(lam)}
		{cmd:. _nwsyntax lam}
		{cmd:. mata: __maxlam = max(*`netobj'->get_matrix())}
		{cmd:. mata: __dissim = __maxlam :- *`netobj'->get_matrix()}
		{cmd:. mata: _diag(__dissim, 0)}
		{cmd:. mata: `netobj'->set_selfloop(1)}
		{cmd:. mata: `netobj'->set_edge(__dissim)}
		{cmd:. mata: mata drop __maxlam __dissim}
		{cmd:. nwhierarchy, disnet(lam) linkage(singlelinkage) groups(2) generate(lamgroup)}

{pstd}
recovers exactly the two intuitive lambda sets, {bf:{A,B,C}} and {bf:{D,E,F}} - confirmed directly
in {cmd:cscripts/test_nwlambda.do}, not merely asserted.

{title:Supported network types}

{pstd}
Binary: yes (only) - similarity is computed from binary edge-connectivity; tie values are ignored.
Directed: yes - automatically symmetrized first (edge connectivity has no standard directed
generalization in the classical cohesive-subgroup literature, the same choice {help nwclique}, {help nwkplex}, {help nwnclique}, {help nwkcomponents} already make). Weighted: not
applicable. Signed: not applicable. Two-mode: not checked.

{title:Stored results}

	Scalars
	  {bf:r(nodes)}		number of nodes

	Macros
	  {bf:r(netname)}	name of the new connectivity network

{title:Examples}

	{cmd:. nwwebuse florentine, nwclear}
	{cmd:. nwlambda flomarriage}
	{cmd:. nwsummarize lambda, matonly}

{title:References}

{pstd}
Borgatti, S.P., Everett, M.G., Shirey, P.R. (1990). LS sets, lambda sets and other cohesive subsets.
{it:Social Networks} 12(4), 337-357.

{pstd}
Menger, K. (1927). Zur allgemeinen Kurventheorie. {it:Fundamenta Mathematicae} 10, 96-115.

{title:See also}

	{help nwkcomponents}, {help nwcohesion}, {help nwhierarchy}, {help nwclique}, {help nwkplex}

last certified : 31 Aug 2026
